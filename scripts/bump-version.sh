#!/usr/bin/env bash
#
# bump-version.sh — bump MarkDown4W's version, the single source of truth being
# project.yml (CFBundleShortVersionString = MARKETING_VERSION, CFBundleVersion =
# CURRENT_PROJECT_VERSION flow from there into Info.plist at build time).
#
# The build number (CURRENT_PROJECT_VERSION) ALWAYS increments by one, so every
# release is uniquely identifiable in the About box — handy for confirming which
# binary you're actually running.
#
# Usage:
#   scripts/bump-version.sh                 # just bump the build number
#   scripts/bump-version.sh patch           # 0.1.0 -> 0.1.1  (+ build number)
#   scripts/bump-version.sh minor           # 0.1.0 -> 0.2.0  (+ build number)
#   scripts/bump-version.sh major           # 0.1.0 -> 1.0.0  (+ build number)
#   scripts/bump-version.sh 1.2.3           # set marketing version explicitly
#
# Flags:
#   --tag      after bumping, create a git commit + annotated tag v<version>
#
# It regenerates the Xcode project so the new values take effect immediately.

set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_YML="project.yml"

read_value() {
  # $1 = key; prints the quoted value on that key's line in project.yml
  grep -E "^[[:space:]]*$1:" "$PROJECT_YML" | head -1 | sed -E 's/.*"([^"]*)".*/\1/'
}

set_value() {
  # $1 = key, $2 = new value
  sed -i '' -E "s/^([[:space:]]*$1:[[:space:]]*\")[^\"]*(\".*)$/\1$2\2/" "$PROJECT_YML"
}

marketing="$(read_value MARKETING_VERSION)"
build="$(read_value CURRENT_PROJECT_VERSION)"

IFS='.' read -r major minor patch <<< "$marketing"

make_tag=false
arg="${1:-}"
[ "${2:-}" = "--tag" ] && make_tag=true
[ "$arg" = "--tag" ] && { make_tag=true; arg=""; }

case "$arg" in
  "")        new_marketing="$marketing" ;;                       # build-only bump
  major)     new_marketing="$((major + 1)).0.0" ;;
  minor)     new_marketing="${major}.$((minor + 1)).0" ;;
  patch)     new_marketing="${major}.${minor}.$((patch + 1))" ;;
  *.*.*)     new_marketing="$arg" ;;                             # explicit x.y.z
  *) echo "error: unknown version arg '$arg' (use major|minor|patch|x.y.z)" >&2; exit 1 ;;
esac

new_build="$((build + 1))"

set_value MARKETING_VERSION "$new_marketing"
set_value CURRENT_PROJECT_VERSION "$new_build"

echo "version: $marketing ($build)  ->  $new_marketing ($new_build)"

# Regenerate so the new values land in the project / Info.plist.
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
  echo "xcodegen: project regenerated"
else
  echo "warn: xcodegen not found — run 'xcodegen generate' manually" >&2
fi

if $make_tag; then
  git add "$PROJECT_YML"
  git commit -m "Bump version to $new_marketing ($new_build)"
  git tag -a "v$new_marketing" -m "MarkDown4W $new_marketing ($new_build)"
  echo "git: committed and tagged v$new_marketing"
fi
