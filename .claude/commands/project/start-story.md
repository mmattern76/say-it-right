---
description: Begin work on a story. Pass a story ID (e.g. SIR-007) or "next" to pull the next story from the Todo column.
argument-hint: <story-id or next>
---

## Load session memory

If `.claude/MEMORY.md` exists, read it first. This contains cumulative context
from previous stories: established patterns, API surfaces, gotchas, and
cross-story decisions. Treat this as working knowledge — do not summarize it
back to the user, just use it.

## Resolve which story to work on

If $ARGUMENTS is "next" or empty:
1. Find the next story in the **Todo** column on the project board.
   Only stories explicitly moved to Todo are ready to build.
   ```bash
   REPO_OWNER=$(gh repo view --json owner -q '.owner.login')
   REPO_NAME=$(gh repo view --json name -q '.name')
   PROJECT_ID=$(gh api graphql -f query='
     query($owner: String!, $repo: String!) {
       repository(owner: $owner, name: $repo) {
         projectsV2(first: 10) {
           nodes { id title closed }
         }
       }
     }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" \
     --jq '[.data.repository.projectsV2.nodes[] | select(.closed == false)] | first | .id')

   gh api graphql -f query='
     query($projectId: ID!) {
       node(id: $projectId) {
         ... on ProjectV2 {
           items(first: 100) {
             nodes {
               fieldValueByName(name: "Status") {
                 ... on ProjectV2ItemFieldSingleSelectValue { name }
               }
               content {
                 ... on Issue { number title body labels(first:10) { nodes { name } } }
               }
             }
           }
         }
       }
     }' -f projectId="$PROJECT_ID" \
     --jq '[.data.node.items.nodes[]
       | select(.fieldValueByName.name == "Todo")
       | select(.content.labels.nodes | map(.name) | index("story"))
       | .content
     ] | sort_by(.number) | first'
   ```
   Pick the lowest SIR-number in Todo. If Todo is empty, stop.

If $ARGUMENTS is a story ID (e.g. SIR-007):
1. Search for it:
   ```bash
   gh issue list --search "$ARGUMENTS in:title" --state open --json number,title,body --jq '.[0]'
   ```

Store the story ID and issue number:
```bash
echo '{"story_id": "<SIR-NNN>", "issue_number": <N>}' > .claude/current-story.json
```

## Move issue to "In Progress"

```bash
./scripts/gh-move-issue.sh <issue_number> in-progress
```

## Load context and start implementing

1. Read `docs/product-spec.md` for overall product design
2. Read the relevant epic file from `docs/epics/`
3. Read `prompts/barbara-system-prompt.md` if the story touches the intelligence layer
4. Parse the issue body for acceptance criteria
5. Create a task list from the acceptance criteria
6. Identify which source files this story will touch
7. Read those files to understand current state
8. Briefly state the plan (one paragraph, no confirmation needed) and begin immediately
