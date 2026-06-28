// Generate Mac App Store screenshots for MarkDown4W.
//
// Each screenshot wraps the app's REAL renderer (MarkDown4W/Renderer/index.html,
// loaded in an iframe) inside a faithful macOS window frame, then captures it
// with headless Google Chrome at a valid App Store size (2560x1600 = 1280x800 @2x).
//
// The rendered content is therefore pixel-identical to what the app shows
// (same markdown-it / highlight.js / KaTeX / mermaid pipeline).
//
// Usage:  node appstore/screenshots/generate.mjs
import { execFileSync } from "node:child_process";
import { writeFileSync, rmSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dir = dirname(fileURLToPath(import.meta.url));
const repo = resolve(__dir, "..", "..");
const rendererDir = resolve(repo, "MarkDown4W", "Renderer");
// Output into a locale folder so `fastlane deliver` picks them up directly.
const outDir = resolve(__dir, "en-US");

const CHROME =
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

// CSS logical size; device-scale 2 -> 2560x1600 output (a valid App Store size).
const W = 1280;
const H = 800;

const b64 = (s) => Buffer.from(s, "utf8").toString("base64");

// ---- macOS window chrome around the real renderer iframe -------------------
function pageHTML({ title, theme, bodyFont, fontSizePx, markdown }) {
  const isDark = theme === "dark";
  const barBg = isDark ? "#2c2c2e" : "#ECECEC";
  const barBorder = isDark ? "#000000" : "#d3d3d3";
  const titleColor = isDark ? "#bdbdbd" : "#5a5a5a";
  const btnColor = isDark ? "#cfcfcf" : "#4a4a4a";
  const pageBg = isDark ? "#1e1e1e" : "#ffffff";
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;padding:0;width:${W}px;height:${H}px;overflow:hidden;
    background:${pageBg};font-family:-apple-system,system-ui,sans-serif;}
  .titlebar{height:52px;display:flex;align-items:center;background:${barBg};
    border-bottom:1px solid ${barBorder};padding:0 16px;gap:8px;}
  .lights{display:flex;gap:8px;align-items:center;}
  .dot{width:12px;height:12px;border-radius:50%;}
  .r{background:#ff5f57;} .y{background:#febc2e;} .g{background:#28c840;}
  .title{position:absolute;left:0;right:0;text-align:center;font-size:13px;
    font-weight:600;color:${titleColor};pointer-events:none;}
  .tools{margin-left:auto;display:flex;gap:14px;align-items:center;z-index:2;
    color:${btnColor};font-size:15px;}
  .tools .b{display:flex;align-items:center;justify-content:center;min-width:22px;
    height:22px;font-weight:600;}
  .tools svg{width:18px;height:18px;fill:none;stroke:${btnColor};stroke-width:1.7;}
  iframe{width:${W}px;height:${H - 52}px;border:0;display:block;background:${pageBg};}
  </style></head><body>
  <div class="titlebar">
    <div class="lights"><span class="dot r"></span><span class="dot y"></span><span class="dot g"></span></div>
    <div class="title">${title}</div>
    <div class="tools">
      <span class="b" style="font-size:12px;">A</span>
      <span class="b" style="font-size:18px;">A</span>
      <span class="b"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 3 A9 9 0 0 1 12 21 Z" fill="${btnColor}" stroke="none"/></svg></span>
      <span class="b"><svg viewBox="0 0 24 24"><path d="M5 7 h14 M5 12 h10 M5 17 h7"/></svg></span>
    </div>
  </div>
  <iframe id="f" src="./index.html"></iframe>
  <script>
    var md = "${b64(markdown)}";
    var f = document.getElementById("f");
    f.addEventListener("load", function () {
      try {
        f.contentWindow.applySettings({bodyFont:"${bodyFont}",codeFont:"sfmono",fontSizePx:${fontSizePx},theme:"${theme}"});
        f.contentWindow.renderMarkdownB64(md);
      } catch (e) { document.title = "ERR:" + e; }
    });
  </script>
  </body></html>`;
}

// ---- screenshot specs ------------------------------------------------------
const shots = [
  {
    name: "01-overview",
    title: "welcome.md",
    theme: "light",
    bodyFont: "newyork",
    fontSizePx: 18,
    markdown: `# Read Markdown, beautifully

**MarkDown4W** is a native macOS reader for Markdown files. It opens like
Preview — one window per file — and renders everything *instantly*, fully
**offline**.

> View-only by design. No clutter, no editing mode, no distractions —
> just your document, looking its best.

## Why you'll like it

- Comfortable reading column and generous line height
- Switchable fonts, text size, and Light / Dark / Auto themes
- Complete GitHub Flavored Markdown
- 100% private: nothing ever leaves your Mac
`,
  },
  {
    name: "02-tables-tasks",
    title: "project.md",
    theme: "light",
    bodyFont: "system",
    fontSizePx: 17,
    markdown: `## Tables & task lists

Full GitHub Flavored Markdown — aligned tables, zebra striping, and read-only
task checkboxes.

| Feature          | Status | Notes              |
|------------------|:------:|--------------------|
| GFM tables       |   ✅   | Aligned columns    |
| Code highlight   |   ✅   | highlight.js       |
| Math typesetting |   ✅   | KaTeX              |
| Diagrams         |   ✅   | Mermaid            |

### Launch checklist

- [x] Native document-based app
- [x] Offline rendering in a WKWebView
- [x] Light / Dark / Auto themes
- [ ] Anything that breaks your focus
`,
  },
  {
    name: "03-code",
    title: "snippet.md",
    theme: "light",
    bodyFont: "system",
    fontSizePx: 16,
    markdown: `## Syntax-highlighted code

Code blocks are highlighted with **highlight.js**, in a crisp \`SF Mono\` face.

\`\`\`swift
struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    var body: some View {
        Text("Hello, MarkDown4W!")
            .font(.title)
            .padding()
    }
}
\`\`\`

\`\`\`python
def fib(n: int) -> int:
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
\`\`\`
`,
  },
  {
    name: "04-math",
    title: "math.md",
    theme: "dark",
    bodyFont: "newyork",
    fontSizePx: 18,
    markdown: `## Math, set with KaTeX

Inline math sits naturally in a sentence — the mass–energy relation
$E = mc^2$ and Euler's identity $e^{i\\pi} + 1 = 0$.

Display equations are centered and beautifully spaced:

$$
\\int_{-\\infty}^{\\infty} e^{-x^2}\\,dx = \\sqrt{\\pi}
$$

$$
i\\hbar\\frac{\\partial}{\\partial t}\\Psi = \\hat{H}\\Psi
$$

Dark mode keeps everything legible, day or night.
`,
  },
  {
    name: "05-mermaid",
    title: "diagram.md",
    theme: "dark",
    bodyFont: "system",
    fontSizePx: 17,
    markdown: `## Diagrams with Mermaid

Fenced \`mermaid\` blocks become live diagrams, themed to match.

\`\`\`mermaid
flowchart LR
    A[Open .md file] --> B[MarkdownDocument]
    B --> C[WKWebView]
    C --> D{Render}
    D --> E[markdown-it]
    D --> F[highlight.js]
    D --> G[KaTeX]
    D --> H[mermaid]
\`\`\`
`,
  },
];

// ---- run -------------------------------------------------------------------
mkdirSync(outDir, { recursive: true });
const tmpName = "__shot.html";
const tmpPath = resolve(rendererDir, tmpName);

for (const s of shots) {
  writeFileSync(tmpPath, pageHTML(s));
  const out = resolve(outDir, `${s.name}.png`);
  execFileSync(
    CHROME,
    [
      "--headless",
      "--disable-gpu",
      "--hide-scrollbars",
      "--allow-file-access-from-files",
      "--disable-web-security",
      "--force-device-scale-factor=2",
      `--window-size=${W},${H}`,
      "--default-background-color=00000000",
      "--virtual-time-budget=6000",
      `--screenshot=${out}`,
      `file://${tmpPath}`,
    ],
    { stdio: "ignore" }
  );
  console.log("wrote", out);
}
rmSync(tmpPath, { force: true });
console.log("done");
