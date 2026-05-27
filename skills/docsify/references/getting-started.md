# Getting started

How to bootstrap a new Docsify v5 site.

## Install the CLI (optional but recommended)

```bash
npm i docsify-cli -g
```

## Initialize a site

```bash
docsify init ./docs
```

`init` creates:

- `index.html` — the entry file (boots Docsify)
- `README.md` — the homepage
- `.nojekyll` — empty file; tells GitHub Pages to serve underscore files

Edit `README.md` to update the homepage. Add additional `*.md` files for more pages — each becomes a route (e.g. `guide.md` → `/#/guide`). See `pages-and-navigation.md` for sidebars, navbars, and cover pages.

## Preview locally

```bash
docsify serve docs
# → http://localhost:3000
```

No CLI? Use any static server:

```bash
cd docs && python3 -m http.server 3000
```

## Manual initialization

If `docsify-cli` is unavailable, create `index.html` from the template in `assets/index.html`. The minimum required content is:

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/core.min.css" />
  </head>
  <body class="loading">
    <div id="app"></div>
    <script>
      window.$docsify = {
        // ...config...
      };
    </script>
    <script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4"></script>
  </body>
</html>
```

Then add a `README.md` and an empty `.nojekyll` next to `index.html`.

## CDN version pinning

Recommended (auto-updates within v5):

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/core.min.css" />
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/docsify.min.js"></script>
```

Locked to an exact release (no updates):

```html
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/docsify.min.js"></script>
```

jsDelivr also accepts semver ranges and dist-tags: `@rc`, `@5.0.x`, `@5.x`, etc. Use `@rc` to track the latest 5.x release candidate.

> **v5 status:** Docsify v5 is currently published only as a release candidate (`5.0.0-rc.4`). The shorthand `docsify@5` does not yet resolve on npm/jsDelivr — always specify `@5.0.0-rc.4` (or the `@rc` tag) until v5 stable ships, then switch to `docsify@5`. If you need a stable, long-tested release instead, use the v4 line: `docsify@4` with CDN path `/lib/` (e.g. `//cdn.jsdelivr.net/npm/docsify@4/lib/docsify.min.js`).

Alternate CDNs: cdnjs, unpkg, BootCDN — all mirror the npm `docsify` package.

## Folder layout (typical)

```text
.
└── docs/
    ├── index.html
    ├── .nojekyll
    ├── README.md           # homepage
    ├── _sidebar.md         # optional, requires loadSidebar: true
    ├── _navbar.md          # optional, requires loadNavbar: true
    ├── _coverpage.md       # optional, requires coverpage: true
    ├── _404.md             # optional, requires notFoundPage: true
    ├── _media/             # images / video / audio
    │   └── icon.svg
    ├── guide.md
    └── zh-cn/              # subfolder = nested route
        ├── README.md
        └── _sidebar.md     # falls back to parent if missing
```

Route mapping:

```text
docs/README.md       → http://example.com/
docs/guide.md        → http://example.com/#/guide
docs/zh-cn/README.md → http://example.com/#/zh-cn/
docs/zh-cn/guide.md  → http://example.com/#/zh-cn/guide
```
