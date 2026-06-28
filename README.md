# MarkDown4W

A native macOS app for viewing Markdown (`.md`) files — beautiful, smooth, and
fast. Complete Markdown rendering, four reading themes, switchable fonts and
text size, native window tabs, find-in-page, and customizable keyboard
shortcuts.

> View-only by design. Editing is intentionally out of scope.

## Features

- **Native macOS, document-based.** Open `.md` files from Finder (double-click)
  or `File ▸ Open`. Multiple files open as **native window tabs**, like
  Safari/TextEdit. Recent files supported.
- **Complete Markdown rendering**
  - GitHub Flavored Markdown: headings, lists, **bold**/*italic*, links, images,
    blockquotes, tables, ~~strikethrough~~, and task lists
  - Code blocks with syntax highlighting ([highlight.js](https://highlightjs.org))
  - Math: inline `$…$` and block `$$…$$` ([KaTeX](https://katex.org))
  - Diagrams via [Mermaid](https://mermaid.js.org) (` ```mermaid ` fenced blocks)
- **Four reading themes**, chosen from the gear popover and applied with a smooth
  cross-fade — the title bar matches each theme:
  - **Light** — soft off-white (easier on the eyes than pure white)
  - **Sepia** — warm cream paper with soft-black ink, low contrast
  - **Dark** — deep gray
  - **Auto** — follows the macOS appearance
- **Find in page** (`⌘F`): highlights and boxes **every** match, marks the
  current one in bright yellow, shows a live `N of M` count, and navigates with
  `⌘G` / `⌘⇧G` (or the field's Return / arrows).
- **Display controls in one place.** A single gear button opens a popover with
  the theme picker, a **font picker that previews each face in its own font**,
  and a **5-stop text-size slider** (14–22 px).
  - Body fonts: System (SF Pro), New York, Georgia, Helvetica Neue
    (code always uses SF Mono)
- **Customizable keyboard shortcuts.** Edit them inline in a dedicated window
  (menu bar ▸ *Keyboard Shortcuts…*, `⌥⌘K`).
- **Polished reading experience.** ~76-character reading column with clear side
  margins, a comfortable default window size, and a native-style overlay
  scrollbar that auto-hides when idle.
- **Private & offline.** All rendering happens locally in a bundled `WKWebView`;
  no Markdown content ever leaves your machine. External links open in your
  default browser. Settings persist across launches.

## Keyboard shortcuts

All but the editor opener are customizable in *Keyboard Shortcuts…* (`⌥⌘K`):

| Action | Default |
|--------|---------|
| Find | `⌘F` |
| Find Next | `⌘G` |
| Find Previous | `⌘⇧G` |
| Increase Text Size | `⌘=` |
| Decrease Text Size | `⌘-` |
| New Tab (open a file) | `⌘T` |
| Customize Shortcuts… | `⌥⌘K` |

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ to build
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`)
- [Node.js](https://nodejs.org) + npm (only to re-vendor the JS libraries)

## Build & run

```sh
git clone https://github.com/nsongha/MarkDown4W.git
cd MarkDown4W

# Generate the Xcode project from project.yml
xcodegen generate

# Build & run from Xcode
open MarkDown4W.xcodeproj      # then press ⌘R

# …or build from the command line (ad-hoc signed so the App Sandbox applies)
xcodebuild -project MarkDown4W.xcodeproj -scheme MarkDown4W -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO build
open build/Build/Products/Release/MarkDown4W.app
```

The app runs in the macOS **App Sandbox**. The bundled web renderer is served to
the `WKWebView` through a custom URL scheme (`BundleResourceSchemeHandler`) so it
loads correctly inside the sandbox, and the `com.apple.security.network.client`
entitlement is required for the web-content process to run.

### Versioning

The version is defined once in `project.yml` (`MARKETING_VERSION` →
`CFBundleShortVersionString`, `CURRENT_PROJECT_VERSION` → `CFBundleVersion`) and
flows into the bundle at build time. Bump it with the helper script, which always
increments the build number so each build is uniquely identifiable in
**MarkDown4W ▸ About** — handy for confirming which binary is actually running:

```sh
scripts/bump-version.sh               # just bump the build number
scripts/bump-version.sh patch         # 0.1.0 -> 0.1.1 (+ build number)
scripts/bump-version.sh minor         # 0.1.0 -> 0.2.0 (+ build number)
scripts/bump-version.sh 1.2.3         # set the marketing version explicitly
scripts/bump-version.sh patch --tag   # also git-commit + tag v0.1.1
```

The script regenerates the Xcode project, so the new version takes effect on the
next build.

### Releasing a notarized DMG

`scripts/release-dmg.sh` does the whole distribution build in one shot: build →
sign with Developer ID → notarize with Apple → staple → package a `.dmg` (with a
drag-to-Applications symlink) under `dist/`. The result opens with no Gatekeeper
warnings.

```sh
scripts/release-dmg.sh
# then publish, e.g.:
gh release create v0.1.0 dist/MarkDown4W-0.1.0.dmg \
  -R nsongha/MarkDown4W --title "MarkDown4W 0.1.0" --notes-file notes.md
```

It needs a *Developer ID Application* certificate in your keychain and a
notarization keychain profile (see the script header for the one-time setup). The
identity and profile name can be overridden via the `SIGN_IDENTITY` and
`NOTARY_PROFILE` environment variables.

The rendered web assets are committed under `MarkDown4W/Renderer/vendor/`, so a
normal build needs **no** npm step. To refresh them to newer library versions:

```sh
cd renderer-src
./build-vendor.sh        # npm install + copy dist files into MarkDown4W/Renderer/vendor/
```

## How it works

The app shell (window, tabs, toolbar, menus, popover, Settings) is native
SwiftUI + `DocumentGroup`. The Markdown content is rendered inside a single
`WKWebView` that loads a bundled, fully-offline page:

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
are instant. Find is an in-page engine (`mdFind` / `mdFindStep`) that highlights
all matches and reports a count.

Customizable shortcuts can't use SwiftUI's static `.keyboardShortcut`, so a
single app-wide key-down monitor (`ShortcutMonitor`) dispatches them — adjusting
text size, opening a file as a tab, or driving the find bar.

Source layout:

| Path | Purpose |
|------|---------|
| `MarkDown4W/MarkDown4WApp.swift` | App entry, `DocumentGroup`, Settings + Shortcuts windows, commands |
| `MarkDown4W/MarkdownDocument.swift` | Read-only `FileDocument` (UTF-8 `.md`) |
| `MarkDown4W/AppSettings.swift` | Persisted font / size / theme + shortcut bindings |
| `MarkDown4W/MarkdownWebView.swift` | `WKWebView` wrapper, find bridge, link handling |
| `MarkDown4W/BundleResourceSchemeHandler.swift` | Serves the bundled renderer under the sandbox |
| `MarkDown4W/WindowConfigurator.swift` | Default window size, native tabbing, themed title bar |
| `MarkDown4W/ContentView.swift` | Hosts the web view, find bar, toolbar |
| `MarkDown4W/MarkdownToolbar.swift` | The single gear button |
| `MarkDown4W/DisplaySettingsView.swift` | Theme / font / size controls (popover + Settings) |
| `MarkDown4W/FindBar.swift` | Find-in-page bar |
| `MarkDown4W/KeyboardShortcuts.swift` | Shortcut model (actions + key combos) |
| `MarkDown4W/ShortcutMonitor.swift` | App-wide key-down dispatch for shortcuts |
| `MarkDown4W/ShortcutRecorderView.swift`, `ShortcutsEditorView.swift` | Inline shortcut editor |
| `MarkDown4W/Renderer/` | Bundled web layer (`index.html`, `theme.css`, `vendor/`) |
| `renderer-src/` | npm project + script that vendors the JS libs |
| `scripts/bump-version.sh` | Bump the marketing / build version (see [Versioning](#versioning)) |

## Author

**SongHa** · [songha.net](https://songha.net) · songha@me.com

## License

[MIT](LICENSE) © 2026 SongHa. Bundled JavaScript libraries keep their own
(permissive) licenses — see [THIRD_PARTY.md](THIRD_PARTY.md).
