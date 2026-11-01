#!/bin/bash
set -euo pipefail

# Compile the app the way TestFlight will.
#
# Everything else the project verifies — swift build, the test suite, Geppetto
# runs — happens in Debug. Anything behind `#if DEBUG` therefore compiles there
# and can still break the Release archive: SwiftUI previews are compiled in
# every configuration, so a preview that builds a Debug-only type fails only
# here. That is exactly how build 20 broke, and the upload was the first thing
# to notice.
#
# Code signing is off: this checks that the code compiles for Release, not that
# it can be distributed. scripts/testflight-upload.sh does the signed archive.
#
# Usage: ./scripts/release-check.sh

cd "$(dirname "$0")/.."
APP_DIR="app/SayItRight"
PROJECT="${APP_DIR}/SayItRight.xcodeproj"

echo "=== Regenerating Xcode project ==="
(cd "${APP_DIR}" && xcodegen generate >/dev/null)

for scheme in SayItRight_iOS SayItRight_macOS; do
    echo ""
    echo "=== Release build: ${scheme} ==="

    destination="generic/platform=iOS"
    if [ "$scheme" = "SayItRight_macOS" ]; then
        destination="generic/platform=macOS"
    fi

    # Keyed off xcodebuild's own exit status: piping it straight into grep
    # hides the failure, because pipefail reports xcodebuild's non-zero status
    # rather than grep's match.
    log=$(mktemp)
    if xcodebuild build \
        -project "$PROJECT" \
        -scheme "$scheme" \
        -configuration Release \
        -destination "$destination" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet >"$log" 2>&1
    then
        echo "✅ ${scheme}"
    else
        grep -E "error:" "$log" | sort -u | head -20
        echo "❌ ${scheme} does not compile for Release."
        FAILED=1
    fi
    rm -f "$log"
done

if [ "${FAILED:-0}" = "1" ]; then
    echo ""
    echo "❌ Release build failed. Fix it before pushing — the TestFlight"
    echo "   upload will hit the same error, and Debug builds will not."
    exit 1
fi

echo ""
echo "✅ Compiles for Release on both platforms."
