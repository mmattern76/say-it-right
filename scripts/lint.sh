#!/bin/bash
set -euo pipefail

echo "=== SwiftFormat (check mode) ==="
if ! swiftformat --lint . 2>&1; then
    echo "❌ SwiftFormat violations found. Run 'swiftformat .' to fix."
    FAILED=1
fi

echo ""
echo "=== SwiftLint ==="
if ! swiftlint lint --strict --quiet 2>&1; then
    echo "❌ SwiftLint violations found."
    FAILED=1
fi

if [ "${FAILED:-0}" = "1" ]; then
    echo ""
    echo "❌ Linting failed. Fix violations before completing this story."
    exit 1
else
    echo ""
    echo "✅ All linting checks passed."
fi
