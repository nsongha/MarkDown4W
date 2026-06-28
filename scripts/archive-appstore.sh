#!/usr/bin/env bash
#
# Build & export a Mac App Store package (.pkg) for MarkDown4W, using Xcode
# automatic signing. No fastlane required.
#
# Prerequisites:
#   • Apple Developer Program membership (Team ID RCVQDZ42VU)
#   • You are signed into your Apple account in Xcode (Settings → Accounts),
#     so -allowProvisioningUpdates can create the distribution cert + profile.
#
# Usage:
#   scripts/archive-appstore.sh            # archive + export the .pkg
#   ASC_KEY_ID=... ASC_ISSUER_ID=... scripts/archive-appstore.sh --upload
#
# To upload, also place your App Store Connect API key at:
#   ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
OUT="$ROOT/build_appstore"
ARCHIVE="$OUT/MarkDown4W.xcarchive"
EXPORT="$OUT/export"

echo "▸ Regenerating Xcode project…"
xcodegen generate

echo "▸ Archiving (Release)…"
xcodebuild \
  -project MarkDown4W.xcodeproj \
  -scheme MarkDown4W \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  archive

echo "▸ Exporting App Store .pkg…"
rm -rf "$EXPORT"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist appstore/ExportOptions.plist \
  -allowProvisioningUpdates

PKG="$(ls "$EXPORT"/*.pkg 2>/dev/null | head -1 || true)"
echo "✓ Exported: ${PKG:-<none found>}"

if [[ "${1:-}" == "--upload" ]]; then
  : "${ASC_KEY_ID:?set ASC_KEY_ID to your App Store Connect API Key ID}"
  : "${ASC_ISSUER_ID:?set ASC_ISSUER_ID to your App Store Connect Issuer ID}"
  [[ -n "$PKG" ]] || { echo "No .pkg to upload"; exit 1; }
  echo "▸ Uploading to App Store Connect…"
  xcrun altool --upload-app -t macos -f "$PKG" \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
  echo "✓ Uploaded. Check App Store Connect → your app → TestFlight/Build."
fi
