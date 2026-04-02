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
check "docs/project-spec.md" "Product concept spec (markdown)"

# Epic files should follow E{N}.md pattern
if [ -d "docs/epics" ]; then
    for f in docs/epics/*.md; do
        if [[ ! $(basename "$f") =~ ^E[0-9]+\.md$ ]]; then
            echo "❌ Non-standard epic filename: $f (expected E{N}.md)"
            FAILED=1
        fi
    done
    echo "✅ Epic filenames follow E{N}.md pattern"
fi

# Claude Code commands
check ".claude/commands/project.md" "Project slash command"
check ".claude/commands/qa.md" "QA slash command"

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
