# Third-Party Licenses

MarkDown4W bundles the following open-source JavaScript libraries (vendored under
`MarkDown4W/Renderer/vendor/`). Each is distributed under a permissive license and
remains the property of its respective authors.

| Library | Version | License | Project |
|---------|---------|---------|---------|
| markdown-it | 14.2.0 | MIT | https://github.com/markdown-it/markdown-it |
| highlight.js (`@highlightjs/cdn-assets`) | 11.11.1 | BSD-3-Clause | https://github.com/highlightjs/highlight.js |
| KaTeX | 0.16.47 | MIT | https://github.com/KaTeX/KaTeX |
| Mermaid | 11.16.0 | MIT | https://github.com/mermaid-js/mermaid |

The build tooling ([XcodeGen](https://github.com/yonyz/XcodeGen)) is used only at
development time and is not bundled in the app.

To regenerate the vendored files (and update versions), run
`renderer-src/build-vendor.sh`. The exact versions are pinned in
`renderer-src/package.json`.
