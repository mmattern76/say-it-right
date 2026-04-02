#!/bin/bash
set -euo pipefail
FAILED=0

check() {
    if [ ! -e "$1" ]; then
        echo "❌ Missing: $1 — $2"
        FAILED=1
    else
        echo "✅ Found: $1"
    fi
}

echo "=== Portfolio Structure Check ==="

# Required files
check "CLAUDE.md" "Project instructions for Claude Code"
check "README.md" "Project readme"
check ".gitignore" "Git ignore rules"
check ".swiftlint.yml" "SwiftLint configuration"
check ".swiftformat" "SwiftFormat configuration"
check "scripts/lint.sh" "Linting entry point"

# Required directories
check "docs/" "Documentation directory"
check "docs/product-spec.md" "Product concept spec (markdown)"

# Epic files should follow naming pattern
if [ -d "docs/epics" ]; then
    EPIC_COUNT=$(find docs/epics -name "*.md" ! -name "TEMPLATE.md" | wc -l | tr -d ' ')
    echo "✅ Found $EPIC_COUNT epic files in docs/epics/"
fi

# Claude Code commands (directory-based)
check ".claude/commands/project/" "Project slash commands"
check ".claude/commands/qa/" "QA slash commands"

# Sprint state
if [ -f "sprint-state.json" ]; then
    if ! python3 -c "import json; json.load(open('sprint-state.json'))" 2>/dev/null; then
        echo "❌ sprint-state.json is not valid JSON"
        FAILED=1
    else
        echo "✅ sprint-state.json is valid JSON"
    fi
fi

echo ""
if [ "$FAILED" = "1" ]; then
    echo "❌ Structure check failed."
    exit 1
else
    echo "✅ All structure checks passed."
fi
