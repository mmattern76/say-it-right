#!/usr/bin/env bash
# gh-move-issue.sh
# Move a GitHub issue to a specific column on the project board
#
# Usage: ./scripts/gh-move-issue.sh <issue_number> <status>
# Status: backlog | todo | in-progress | ready-for-qa | done
#
# Example: ./scripts/gh-move-issue.sh 5 in-progress

set -euo pipefail

ISSUE_NUM="${1:?Usage: gh-move-issue.sh <issue_number> <status>}"
STATUS="${2:?Usage: gh-move-issue.sh <issue_number> <status>}"

# Map friendly names to board column names
case "$STATUS" in
  backlog)       COLUMN="Backlog" ;;
  todo)          COLUMN="Todo" ;;
  in-progress)   COLUMN="In Progress" ;;
  ready-for-qa)  COLUMN="Ready for QA" ;;
  done)          COLUMN="Done" ;;
  *)             echo "Unknown status: $STATUS"; echo "Valid: backlog, todo, in-progress, ready-for-qa, done"; exit 1 ;;
esac

REPO_OWNER=$(gh repo view --json owner -q '.owner.login')
REPO_NAME=$(gh repo view --json name -q '.name')

# Find the project
PROJECT_ID=$(gh api graphql -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      projectsV2(first: 10) {
        nodes { id title closed }
      }
    }
  }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" \
  --jq '[.data.repository.projectsV2.nodes[] | select(.closed == false)] | first | .id')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  echo "No open project found for $REPO_OWNER/$REPO_NAME"
  exit 1
fi

# Find the item ID for this issue in the project
ITEM_ID=$(gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue { number }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" \
  --jq ".data.node.items.nodes[] | select(.content.number == $ISSUE_NUM) | .id")

if [ -z "$ITEM_ID" ] || [ "$ITEM_ID" = "null" ]; then
  echo "Issue #$ISSUE_NUM not found on project board"
  exit 1
fi

# Find the Status field ID and the option ID for the target column
FIELD_DATA=$(gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options { id name }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" \
  --jq '.data.node.fields.nodes[] | select(.name == "Status")')

FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.id')
OPTION_ID=$(echo "$FIELD_DATA" | jq -r ".options[] | select(.name == \"$COLUMN\") | .id")

if [ -z "$OPTION_ID" ] || [ "$OPTION_ID" = "null" ]; then
  echo "Column '$COLUMN' not found on project board"
  echo "Available columns:"
  echo "$FIELD_DATA" | jq -r '.options[].name'
  exit 1
fi

# Move the item
gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $optionId }
    }) {
      projectV2Item { id }
    }
  }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$FIELD_ID" -f optionId="$OPTION_ID" \
  --silent

echo "Issue #$ISSUE_NUM -> $COLUMN"
