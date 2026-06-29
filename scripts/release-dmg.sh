#!/usr/bin/env bash
#
# release-dmg.sh — one shot: build → sign (Developer ID) → notarize → staple →
# package a notarized .dmg ready for distribution.
#
# The resulting DMG opens with no Gatekeeper warnings: the app is signed with a
# Developer ID Application cert, hardened runtime + secure timestamp, notarized by
# Apple, and the ticket is stapled into both the app and the DMG (so it also works
# offline on first launch).
#
# Prerequisites (one-time):
#   - A "Developer ID Application" certificate in your keychain.
#   - Notarization credentials stored in a keychain profile, e.g.:
#       xcrun notarytool store-credentials "MarkDown4W-shtool" \
#         --apple-id <id> --team-id <team> --password <app-specific-password>
#
# Usage:
#   scripts/release-dmg.sh [universal|intel|apple-silicon]
#     (default: universal)
#
# Each variant produces dist/MarkDown4W-<version>-<variant>.dmg and does NOT wipe
# other variants' DMGs, so you can build all three in a row.
#
# Override via env vars if your identity / profile differ:
#   SIGN_IDENTITY="Developer ID Application: ... (TEAMID)" \
#   NOTARY_PROFILE="MarkDown4W-shtool" \
#   scripts/release-dmg.sh universal

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="MarkDown4W"
SCHEME="MarkDown4W"
ENTITLEMENTS="MarkDown4W/MarkDown4W.entitlements"
PROJECT="MarkDown4W.xcodeproj"

SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Nguyen Song Ha (RCVQDZ42VU)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-MarkDown4W-shtool}"

# Architecture variant → ARCHS + filename suffix.
VARIANT="${1:-universal}"
case "$VARIANT" in
  universal)            ARCHS="arm64 x86_64"; SUFFIX="universal" ;;
  intel|x86_64)         ARCHS="x86_64";       SUFFIX="intel" ;;
  apple-silicon|arm64)  ARCHS="arm64";        SUFFIX="apple-silicon" ;;
  *) echo "error: unknown variant '$VARIANT' (use universal|intel|apple-silicon)" >&2; exit 1 ;;
esac

read_value() { grep -E "^[[:space:]]*$1:" project.yml | head -1 | sed -E 's/.*"([^"]*)".*/\1/'; }
MARKETING="$(read_value MARKETING_VERSION)"
BUILD="$(read_value CURRENT_PROJECT_VERSION)"

DMG="dist/${APP_NAME}-${MARKETING}-${SUFFIX}.dmg"

echo "▸ Releasing ${APP_NAME} ${MARKETING} (${BUILD}) — ${SUFFIX} [${ARCHS}]"
echo "  identity: ${SIGN_IDENTITY}"
echo "  notary:   ${NOTARY_PROFILE}"

# Fail early with a clear message if the signing identity isn't present.
if ! security find-identity -v -p codesigning | grep -qF "$SIGN_IDENTITY"; then
  echo "error: signing identity not found in keychain:" >&2
  echo "       $SIGN_IDENTITY" >&2
  exit 1
fi

# 1. Generate the project and build an unsigned Release (we sign manually next).
#    Only the build/ dir is wiped — dist/ keeps DMGs from other variants.
echo "▸ [1/6] Building (unsigned)…"
command -v xcodegen >/dev/null && xcodegen generate >/dev/null
rm -rf build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO \
  ARCHS="$ARCHS" ONLY_ACTIVE_ARCH=NO clean build >/dev/null
APP="build/Build/Products/Release/${APP_NAME}.app"

echo "  archs in binary: $(lipo -archs "$APP/Contents/MacOS/${APP_NAME}")"

# 2. Sign with Developer ID + hardened runtime + secure timestamp.
echo "▸ [2/6] Signing with Developer ID…"
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# 3. Notarize the app, then staple the ticket into it.
echo "▸ [3/6] Notarizing app…"
ditto -c -k --keepParent "$APP" build/app-notarize.zip
xcrun notarytool submit build/app-notarize.zip --keychain-profile "$NOTARY_PROFILE" --wait
echo "▸ [4/6] Stapling app…"
xcrun stapler staple "$APP"

# 4. Build the DMG (app + drag-to-Applications symlink).
echo "▸ [5/6] Building DMG…"
mkdir -p dist
STAGE="$(mktemp -d)"
ditto "$APP" "$STAGE/${APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

# 5. Notarize the DMG too, then staple it (so the DMG passes Gatekeeper offline).
echo "▸ [6/6] Notarizing + stapling DMG…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo
echo "✓ Done: $DMG"
spctl -a -vvv -t exec "$APP" 2>&1 | sed 's/^/  /'
