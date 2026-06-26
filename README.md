# MarkDown4W

A native macOS app for viewing Markdown (`.md`) files — beautiful, smooth, and
fast. Switch fonts and text size, toggle Light/Dark/Auto, and get complete
Markdown rendering (GFM tables, task lists, syntax-highlighted code, math, and
diagrams).

> View-only by design. Editing is intentionally out of scope.

## Features

- **Native macOS, document-based.** One window per file (like Preview/TextEdit).
  Double-click a `.md` in Finder, or `File ▸ Open`. Recent files supported.
- **Complete Markdown rendering**
  - GitHub Flavored Markdown: headings, lists, **bold**/*italic*, links, images,
    blockquotes, tables, ~~strikethrough~~, and task lists
  - Code blocks with syntax highlighting ([highlight.js](https://highlightjs.org))
  - Math: inline `$…$` and block `$$…$$` ([KaTeX](https://katex.org))
  - Diagrams via [Mermaid](https://mermaid.js.org) (` ```mermaid ` fenced blocks)
- **Readable by default.** Comfortable reading column, generous line height.
- **Customizable**
  - Body font: System (SF Pro), New York, Georgia, Helvetica Neue
    (code always uses SF Mono)
  - Text size: `A−` / `A+`
  - Theme: Light / Dark / Auto (follows the system appearance)
  - Settings persist across launches and apply instantly.
- **Private & offline.** All rendering happens locally in a bundled `WKWebView`;
  no Markdown content ever leaves your machine. External links open in your
  default browser.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ to build
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`)
- [Node.js](https://nodejs.org) + npm (only to re-vendor the JS libraries)

## Build & run

```sh
git clone <your-fork-url> MarkDown4W
cd MarkDown4W

# Generate the Xcode project from project.yml
xcodegen generate

# Build & run from Xcode
open MarkDown4W.xcodeproj      # then press ⌘R

# …or build from the command line
xcodebuild -project MarkDown4W.xcodeproj -scheme MarkDown4W -configuration Debug \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
open build/Build/Products/Debug/MarkDown4W.app
```

The rendered web assets are committed under `MarkDown4W/Renderer/vendor/`, so a normal
build needs **no** npm step. To refresh them to newer library versions:

```sh
cd renderer-src
./build-vendor.sh        # npm install + copy dist files into MarkDown4W/Renderer/vendor/
```

## How it works

The app shell (window, toolbar, menus, Settings) is native SwiftUI +
`DocumentGroup`. The Markdown content is rendered inside a single `WKWebView`
that loads a bundled, fully-offline page:

```
.md file ─▶ MarkdownDocument (UTF-8) ─▶ WKWebView
                                         ├─ markdown-it   (Markdown → HTML)
                                         ├─ highlight.js  (code)
                                         ├─ KaTeX         (math)
                                         └─ Mermaid       (diagrams)
```

Swift passes the Markdown text (base64-encoded) into the page and calls
`renderMarkdownB64(...)`. Font/size/theme changes call `applySettings(...)`,
which only updates CSS variables — the Markdown is never re-parsed, so changes
are instant.

Source layout:

| Path | Purpose |
|------|---------|
| `MarkDown4W/MarkDown4WApp.swift` | App entry, `DocumentGroup`, Settings scene |
| `MarkDown4W/MarkdownDocument.swift` | Read-only `FileDocument` (UTF-8 `.md`) |
| `MarkDown4W/AppSettings.swift` | Persisted font / size / theme |
| `MarkDown4W/MarkdownWebView.swift` | `WKWebView` wrapper + link handling |
| `MarkDown4W/ContentView.swift`, `MarkdownToolbar.swift` | UI |
| `MarkDown4W/Renderer/` | Bundled web layer (`index.html`, `theme.css`, `vendor/`) |
| `renderer-src/` | npm project + script that vendors the JS libs |

## Author

**SongHa** · [songha.net](https://songha.net) · songha@me.com

## License

[MIT](LICENSE) © 2026 SongHa. Bundled JavaScript libraries keep their own
(permissive) licenses — see [THIRD_PARTY.md](THIRD_PARTY.md).
