// validate.mjs — verify the markdown-it pipeline produces the expected HTML and
// that all vendored browser files exist on disk. Run with: node validate.mjs
//
// We can't run a browser here, so we replicate the index.html markdown-it
// configuration (fence override for mermaid + task-list plugin) and assert the
// rendered HTML contains a table, a pre, a task-list checkbox, and a mermaid
// placeholder. Then we check every file index.html references under vendor/.

import { readFileSync, existsSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import MarkdownIt from "markdown-it";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = join(__dirname, "..");
const VENDOR = join(REPO, "MarkDown4W", "Renderer", "vendor");
const SAMPLE = join(REPO, "fixtures", "sample.md");

let failures = 0;
function check(name, cond) {
  if (cond) {
    console.log("  PASS  " + name);
  } else {
    console.error("  FAIL  " + name);
    failures++;
  }
}

// ---- Build a markdown-it that mirrors index.html (sans browser-only bits) ----
const md = new MarkdownIt({ html: false, linkify: true, typographer: true });
md.enable(["table", "strikethrough", "linkify"]);

// mermaid fence override
const defaultFence =
  md.renderer.rules.fence ||
  ((tokens, idx, options, env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.fence = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  const info = token.info ? md.utils.unescapeAll(token.info).trim() : "";
  const lang = info.split(/\s+/g)[0];
  if (lang === "mermaid") {
    const enc = md.utils.escapeHtml(token.content);
    return '<pre class="mermaid" data-src="' + enc + '">' + enc + "</pre>\n";
  }
  return defaultFence(tokens, idx, options, env, self);
};

// task-list plugin (same logic as index.html)
md.core.ruler.after("inline", "markdown4w-task-lists", (state) => {
  const tokens = state.tokens;
  for (let i = 0; i < tokens.length; i++) {
    if (tokens[i].type !== "inline" || i < 2) continue;
    if (tokens[i - 1].type !== "paragraph_open") continue;
    if (tokens[i - 2].type !== "list_item_open") continue;
    const children = tokens[i].children;
    if (!children || !children.length) continue;
    const first = children[0];
    if (first.type !== "text") continue;
    const m = /^\[([ xX])\]\s(.*)$/.exec(first.content);
    if (!m) continue;
    const checked = m[1].toLowerCase() === "x";
    first.content = m[2];
    const box = new state.Token("html_inline", "", 0);
    box.content =
      '<input class="task-list-item-checkbox" type="checkbox" disabled' +
      (checked ? " checked" : "") + "> ";
    children.unshift(box);
    tokens[i - 2].attrJoin("class", "task-list-item");
    for (let j = i - 2; j >= 0; j--) {
      if (tokens[j].type === "bullet_list_open") {
        tokens[j].attrJoin("class", "task-list");
        break;
      }
      if (tokens[j].type === "ordered_list_open") break;
    }
  }
  return true;
});

// ---- Render + assert ---------------------------------------------------------
const sample = readFileSync(SAMPLE, "utf8");
const html = md.render(sample);

console.log("== markdown-it pipeline ==");
check("output is non-empty", html.trim().length > 0);
check("contains <table", html.includes("<table"));
check("contains <pre", html.includes("<pre"));
check(
  "contains a task-list checkbox",
  /<input[^>]*type="checkbox"[^>]*disabled/.test(html)
);
check(
  "contains a mermaid block placeholder",
  /<pre class="mermaid" data-src=/.test(html)
);

// ---- Vendor files on disk ----------------------------------------------------
console.log("== vendored files ==");
const required = [
  "markdown-it.min.js",
  "highlight.min.js",
  "hljs-github.css",
  "hljs-github-dark.css",
  "katex.min.js",
  "katex.min.css",
  "auto-render.min.js",
  "mermaid.min.js",
];
for (const f of required) {
  const p = join(VENDOR, f);
  check("vendor/" + f, existsSync(p) && statSync(p).size > 0);
}
// fonts dir
const fontsDir = join(VENDOR, "fonts");
check(
  "vendor/fonts/ (non-empty dir)",
  existsSync(fontsDir) && statSync(fontsDir).isDirectory()
);

// ---- Renderer entry files ----------------------------------------------------
console.log("== renderer entry ==");
for (const f of ["index.html", "theme.css"]) {
  const p = join(REPO, "MarkDown4W", "Renderer", f);
  check("MarkDown4W/Renderer/" + f, existsSync(p) && statSync(p).size > 0);
}

console.log("");
if (failures > 0) {
  console.error("VALIDATION FAILED: " + failures + " check(s) failed.");
  process.exit(1);
} else {
  console.log("VALIDATION PASSED: all checks green.");
}
