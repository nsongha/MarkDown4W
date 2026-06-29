# Third-Party Licenses

MarkDown4W bundles the open-source JavaScript libraries listed below (vendored
under `MarkDown4W/Renderer/vendor/` and shipped inside the app). Each is
distributed under a permissive license and remains the property of its
respective authors. The full license text for each is reproduced in this file,
satisfying the attribution clauses of the MIT and BSD-3-Clause licenses.

| Library | Version | License | Project |
|---------|---------|---------|---------|
| markdown-it | 14.2.0 | MIT | https://github.com/markdown-it/markdown-it |
| highlight.js (`@highlightjs/cdn-assets`) | 11.11.1 | BSD-3-Clause | https://github.com/highlightjs/highlight.js |
| highlight.js GitHub themes (light/dark CSS) | 11.11.1 | BSD-3-Clause | https://github.com/highlightjs/highlight.js |
| KaTeX (incl. `auto-render`) | 0.16.47 | MIT | https://github.com/KaTeX/KaTeX |
| KaTeX fonts (`KaTeX_*`) | 0.16.47 | MIT | https://github.com/KaTeX/KaTeX |
| Mermaid | 11.16.0 | MIT | https://github.com/mermaid-js/mermaid |

> **Note on Mermaid:** the vendored `mermaid.min.js` is a self-contained UMD
> bundle produced by the Mermaid build. It statically embeds a number of
> transitive dependencies (e.g. d3, dagre, cytoscape, dompurify, marked,
> stylis, and others), each distributed under its own permissive license
> (MIT / ISC / BSD / Apache-2.0). Their copyright notices are retained inside
> the bundle. See Mermaid's dependency tree for the authoritative list:
> https://github.com/mermaid-js/mermaid/blob/develop/package.json

The build tooling ([XcodeGen](https://github.com/yonyz/XcodeGen)) is used only at
development time and is **not** bundled in the app, so its license does not apply
to the distributed binary.

To regenerate the vendored files (and update versions), run
`renderer-src/build-vendor.sh`. The exact versions are pinned in
`renderer-src/package.json`.

---

## markdown-it — MIT License

```
Copyright (c) 2014 Vitaly Puzrin, Alex Kocharin.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

---

## highlight.js — BSD 3-Clause License

The highlight.js engine (`highlight.min.js`) and the bundled GitHub light/dark
theme stylesheets (`hljs-github.css`, `hljs-github-dark.css`) are both part of
the highlight.js project.

```
BSD 3-Clause License

Copyright (c) 2006, Ivan Sagalaev.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its contributors
  may be used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

The GitHub themes were authored by github.com and are maintained within
highlight.js by @Hirse, under the same BSD-3-Clause license.

---

## KaTeX — MIT License

Covers the KaTeX engine (`katex.min.js`), the `auto-render` extension
(`auto-render.min.js`), the stylesheet (`katex.min.css`), and the bundled
`KaTeX_*` web fonts under `vendor/fonts/`.

```
Copyright (c) 2013-2020 Khan Academy and other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Mermaid — MIT License

The vendored `mermaid.min.js` is the self-contained UMD bundle. In addition to
Mermaid's own code (below), it statically includes transitive dependencies that
retain their individual permissive licenses (see the note at the top of this
file).

```
Copyright (c) 2014 - 2022 Knut Sveidqvist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
