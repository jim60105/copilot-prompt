---
name: docsify
description: Comprehensive guide for building, configuring, customizing, and deploying Docsify documentation sites. Use when the user wants to (1) initialize a new Docsify site, (2) add or organize Markdown pages, sidebars, navbars, or cover pages, (3) configure `window.$docsify` options, (4) customize themes / CSS variables / fonts, (5) install built-in or third-party Docsify plugins (search, GA, emoji, zoom, copy-code, comments, pagination, tabs, etc.), (6) write a custom Docsify plugin using lifecycle hooks, (7) use Docsify Markdown helpers (callouts, link attributes, image attributes, heading IDs, task lists, embed files with `:include`), (8) deploy to GitHub Pages, GitLab Pages, Netlify, Vercel, Firebase, Docker, Nginx, etc., (9) enable PWA / offline mode, virtual routes, or Vue compatibility, or (10) upgrade a Docsify site from v4 to v5. Triggers on mentions of "docsify", "_sidebar.md", "_navbar.md", "_coverpage.md", "$docsify", or `docsify-cli`.
---

# Docsify

Docsify turns Markdown files into a documentation website **at runtime** — there is no static build step. A single `index.html` boots `docsify.js`, which fetches and renders `.md` files dynamically.

Targets Docsify **v5** by default. v5 is currently published only as a release candidate (`5.0.0-rc.4`) — all CDN URLs in this skill pin to that exact version. Use `docsify@rc` (dist-tag) to track the latest 5.x RC, and switch to `docsify@5` only after v5 stable is published. If the user needs the long-stable line, use `docsify@4` (CDN path `/lib/` instead of `/dist/`). For v4 migration guidance, load `references/advanced.md`.

## When to load which reference

Load **only** the references needed for the current task — do not preload everything.

| Task | Load |
| --- | --- |
| Bootstrap a brand-new site / write `index.html` / `docsify-cli` usage | `references/getting-started.md` (+ `assets/index.html`) |
| Add pages, build `_sidebar.md` / `_navbar.md` / `_coverpage.md`, multi-language layout, TOC | `references/pages-and-navigation.md` |
| Set or look up any `window.$docsify` option | `references/configuration.md` |
| Docsify-specific Markdown syntax (callouts, link/image attrs, heading IDs, embed `:include`, code highlight) | `references/markdown-helpers.md` |
| Theme switching, CSS variables, custom fonts, body classes, dark mode | `references/themes-and-styling.md` |
| Install / configure built-in or community plugins | `references/plugins.md` |
| Write a custom Docsify plugin (lifecycle hooks) | `references/writing-plugins.md` |
| Deploy to GitHub Pages, GitLab, Netlify, Vercel, Firebase, Docker, Nginx, AWS Amplify, etc. | `references/deployment.md` |
| PWA / offline, virtual routes, Vue components, v4 → v5 upgrade | `references/advanced.md` |

## Core mental model

A Docsify site needs only three things:

1. **`index.html`** — single boot file that loads `docsify.js`, a theme CSS, optional plugins, and defines `window.$docsify` config.
2. **Markdown files** — `README.md` is the homepage; any other `*.md` is a route (e.g. `guide.md` → `/#/guide`).
3. **Special underscore files** (optional but common):
   - `_sidebar.md` — sidebar menu (requires `loadSidebar: true`)
   - `_navbar.md` — top navbar (requires `loadNavbar: true`)
   - `_coverpage.md` — landing cover (requires `coverpage: true`)
   - `_404.md` — custom 404 (requires `notFoundPage: true`)
   - `_media/` — images and other assets
   - **`.nojekyll`** — required on GitHub Pages so underscore files are served

Subfolders define nested routes; nested `_sidebar.md` / `_navbar.md` override parent ones (used for multi-language sites).

## Quick start workflow

For "set up a new Docsify site" requests:

1. Read `references/getting-started.md` for the canonical `index.html` and CLI commands.
2. Copy `assets/index.html` into the site folder and adjust the `name`, `repo`, theme add-ons, and plugin `<script>` tags.
3. Create `README.md` (homepage) and `.nojekyll` (empty file).
4. If the user wants a sidebar/navbar/cover, also load `references/pages-and-navigation.md`.
5. Verify locally with `docsify serve <folder>` (or `python3 -m http.server`).

## Key conventions to preserve

- **Always pin an exact CDN version**. v5 is in RC: use `docsify@5.0.0-rc.4` (or the `@rc` tag) until v5 stable releases — the shorthand `docsify@5` does **not** resolve today. For the long-stable line, use `docsify@4` with CDN path `/lib/` instead of `/dist/`. See `assets/index.html`.
- **Theme CSS must come before** Docsify JS; **theme add-ons must come after** the core theme; **Prism language/theme files and plugin scripts must come after** `docsify.min.js`.
- **`.nojekyll`** is mandatory whenever the site is on GitHub Pages and uses any `_*.md` file.
- **Hash routing is the default** (`/#/page`). Only switch to `routerMode: 'history'` if the host can rewrite URLs to `index.html`, and add `alias` entries for `_sidebar.md` / `_navbar.md` (see `references/configuration.md`).
- **Underscore files fall back up the directory tree** — `/guide/_sidebar.md` is used if present, otherwise `/_sidebar.md`.
- Docsify renders Markdown via **marked** and syntax-highlights via **Prism** (load extra Prism language components after `docsify.min.js`).

## Common gotchas

- Forgetting `.nojekyll` → GitHub Pages 404s on `_sidebar.md`.
- Putting plugin `<script>` tags **before** `docsify.min.js` → plugin never registers.
- Setting `coverpage: true` without creating `_coverpage.md` → blank landing.
- Using `routerMode: 'history'` on a static host without rewrite rules → deep links 404 on refresh.
- Mermaid: Docsify only supports synchronous Mermaid (≤ v9.3.0). See `references/markdown-helpers.md`.
- The legacy `!>` / `?>` callouts and the `themeColor` / `topMargin` options are deprecated in v5 — prefer GitHub-style `> [!NOTE]` callouts and CSS variables.

## Assets

- `assets/index.html` — production-ready `index.html` template with comments showing where to enable theme add-ons and plugins. Copy and edit; do not load into the conversation context unless modifying the template itself.
