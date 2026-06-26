#!/usr/bin/env bash
#
# build-vendor.sh — install JS libs and copy the prebuilt browser files into
# ../MarkDown4W/Renderer/vendor/ so the macOS app builds & runs fully OFFLINE
# (no remote URLs, no npm at app build time — vendored files are committed).
#
# Mermaid bundle choice:
#   mermaid ships a self-contained UMD bundle at dist/mermaid.min.js, which
#   exposes a global `mermaid` when loaded via a plain <script> tag.
#   We use that (preferred path in the spec). We do NOT use the .mjs ESM
#   variants because the UMD bundle is the single self-contained file and the
#   simplest to load in a WKWebView without module resolution.
#
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SRC_DIR"

NM="$SRC_DIR/node_modules"
VENDOR="$SRC_DIR/../MarkDown4W/Renderer/vendor"

echo "==> npm install"
npm install

echo "==> preparing vendor dir: $VENDOR"
mkdir -p "$VENDOR"
mkdir -p "$VENDOR/fonts"

copy() {
  # copy SRC DST, failing loudly if SRC is missing
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    echo "ERROR: expected file not found: $src" >&2
    exit 1
  fi
  cp -f "$src" "$dst"
  echo "    $src -> $dst"
}

echo "==> copying markdown-it"
copy "$NM/markdown-it/dist/markdown-it.min.js" "$VENDOR/markdown-it.min.js"

echo "==> copying highlight.js"
copy "$NM/@highlightjs/cdn-assets/highlight.min.js"            "$VENDOR/highlight.min.js"
copy "$NM/@highlightjs/cdn-assets/styles/github.min.css"      "$VENDOR/hljs-github.css"
copy "$NM/@highlightjs/cdn-assets/styles/github-dark.min.css" "$VENDOR/hljs-github-dark.css"

echo "==> copying KaTeX"
copy "$NM/katex/dist/katex.min.js"                  "$VENDOR/katex.min.js"
copy "$NM/katex/dist/katex.min.css"                 "$VENDOR/katex.min.css"
copy "$NM/katex/dist/contrib/auto-render.min.js"    "$VENDOR/auto-render.min.js"

echo "==> copying KaTeX fonts (katex.min.css references fonts/ relatively)"
rm -rf "$VENDOR/fonts"
cp -R "$NM/katex/dist/fonts" "$VENDOR/fonts"
echo "    $NM/katex/dist/fonts -> $VENDOR/fonts ($(ls "$VENDOR/fonts" | wc -l | tr -d ' ') files)"

echo "==> copying mermaid (self-contained UMD bundle)"
if [ -f "$NM/mermaid/dist/mermaid.min.js" ]; then
  copy "$NM/mermaid/dist/mermaid.min.js" "$VENDOR/mermaid.min.js"
  echo "    using UMD bundle mermaid.min.js (global <script>)"
else
  # Fallback for newer mermaid that ships ESM-only.
  copy "$NM/mermaid/dist/mermaid.esm.min.mjs" "$VENDOR/mermaid.min.mjs"
  echo "    WARNING: UMD bundle missing; copied ESM mermaid.min.mjs."
  echo "    index.html must load it as <script type=\"module\">."
fi

echo "==> done. vendor contents:"
ls -la "$VENDOR"
