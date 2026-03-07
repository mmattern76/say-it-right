#!/usr/bin/env bash
set -euo pipefail

# Upload Say it right! to TestFlight
#
# Prerequisites:
#   1. Apple Developer account with App ID io.mattern.say-it-right
#   2. Xcode signed in to App Store Connect (Xcode > Settings > Accounts)
#   3. App record created in App Store Connect
#   4. xcodegen installed: brew install xcodegen
#
# Usage:
#   ./scripts/testflight-upload.sh              # build, archive, upload
#   ./scripts/testflight-upload.sh --skip-upload # archive only (no upload)

cd "$(dirname "$0")/.."
APP_DIR="app/SayItRight"
PROJECT="${APP_DIR}/SayItRight.xcodeproj"
SCHEME="SayItRight_iOS"
BUILD_DIR="/tmp/say-it-right-build"
ARCHIVE_PATH="${BUILD_DIR}/SayItRight.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
EXPORT_OPTIONS="${APP_DIR}/ExportOptions.plist"
SKIP_UPLOAD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-upload)  SKIP_UPLOAD=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--skip-upload]"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Step 1: Bump build number ---
echo "==> Bumping build number..."
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION:' "${APP_DIR}/project.yml" | head -1 | awk '{print $2}')
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION: ${CURRENT_BUILD}/CURRENT_PROJECT_VERSION: ${NEW_BUILD}/g" "${APP_DIR}/project.yml"
echo "    Build number: ${CURRENT_BUILD} → ${NEW_BUILD}"

# --- Step 2: Regenerate Xcode project ---
echo "==> Regenerating Xcode project..."
cd "${APP_DIR}" && xcodegen generate && cd ../..

# --- Step 3: Clean and archive ---
echo "==> Archiving (Release)..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
xcodebuild clean archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -quiet

echo "    Archive: $ARCHIVE_PATH"

# --- Step 4: Export + Upload to TestFlight ---
if [ "$SKIP_UPLOAD" = true ]; then
    echo "==> Exporting IPA (skip upload)..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates \
        -quiet
    echo "    Archive exported to $EXPORT_PATH (not uploaded)"
else
    echo "==> Exporting and uploading to TestFlight..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates \
        -quiet
    echo "    Upload complete! Build ${NEW_BUILD} submitted to TestFlight."
fi

echo ""
echo "==> Done. Build ${NEW_BUILD} (v$(grep 'MARKETING_VERSION:' "${APP_DIR}/project.yml" | head -1 | awk '{gsub(/"/, ""); print $2}'))"
