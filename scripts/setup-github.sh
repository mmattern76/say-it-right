#!/usr/bin/env bash
# setup-github.sh
# One-time setup: create labels, milestones, and project board for Say it right!
#
# Usage: ./scripts/setup-github.sh
#
# Prerequisites: gh CLI authenticated, repo exists on GitHub

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Setting up GitHub project infrastructure for $REPO"

# ─── Labels ───────────────────────────────────────────────────────────

echo "Creating labels..."

declare -A LABELS=(
  ["epic"]="d73a4a"
  ["story"]="0075ca"
  ["spike"]="e4e669"
  ["presentation"]="c5def5"
  ["intelligence"]="f9d0c4"
  ["state"]="bfdadc"
  ["content"]="d4c5f9"
  ["infra"]="ededed"
  ["epic:e1"]="d73a4a"
  ["epic:e2"]="d73a4a"
  ["epic:e3"]="d73a4a"
  ["epic:e4"]="d73a4a"
  ["epic:e5"]="d73a4a"
  ["epic:e6"]="d73a4a"
)

LABEL_DESCRIPTIONS=(
  ["epic"]="Epic-level tracking issue"
  ["story"]="Implementable user story"
  ["spike"]="Research / timeboxed investigation"
  ["presentation"]="Layer 4: SwiftUI views"
  ["intelligence"]="Layer 3: LLM integration, evaluation"
  ["state"]="Layer 2: Persistence, profiles"
  ["content"]="Layer 1: Curriculum, rubrics, texts"
  ["infra"]="Tooling, scripts, CI"
  ["epic:e1"]="Epic 1: Barbara's Brain"
  ["epic:e2"]="Epic 2: iOS Shell & Chat"
  ["epic:e3"]="Epic 3: Build Mode"
  ["epic:e4"]="Epic 4: Break Mode"
  ["epic:e5"]="Epic 5: Voice Interaction"
  ["epic:e6"]="Epic 6: Pyramid Builder"
)

for label in "${!LABELS[@]}"; do
  gh label create "$label" \
    --color "${LABELS[$label]}" \
    --description "${LABEL_DESCRIPTIONS[$label]:-}" \
    --force 2>/dev/null || true
  echo "  $label"
done

# ─── Milestones ───────────────────────────────────────────────────────

echo "Creating milestones..."

MILESTONES=(
  "E1: Barbara's Brain"
  "E2: iOS Shell & Chat"
  "E3: Build Mode"
  "E4: Break Mode"
  "E5: Voice Interaction"
  "E6: Pyramid Builder"
)

for ms in "${MILESTONES[@]}"; do
  gh api repos/"$REPO"/milestones \
    -f title="$ms" \
    -f state="open" 2>/dev/null || true
  echo "  $ms"
done

# ─── Project Board ────────────────────────────────────────────────────

echo "Creating project board..."
echo "(Create manually via GitHub UI: Settings > Projects > New project)"
echo "Columns: Backlog | Todo | In Progress | Ready for QA | Done"

echo ""
echo "Setup complete for $REPO"
echo "Next: /analyst:analyze-epic E1"
