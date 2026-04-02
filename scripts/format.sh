#!/bin/bash
set -euo pipefail

echo "=== SwiftFormat (auto-fix) ==="
swiftformat .

echo "=== SwiftLint autocorrect ==="
swiftlint lint --fix --quiet

echo "✅ Auto-formatting complete. Run scripts/lint.sh to verify."
