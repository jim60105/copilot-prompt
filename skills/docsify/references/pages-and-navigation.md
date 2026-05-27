# Pages and navigation

How to add pages and wire up the sidebar, navbar, cover page, and 404 page.

## Contents

- [Adding pages](#adding-pages)
- [Sidebar (`_sidebar.md`)](#sidebar-_sidebarmd)
- [Navbar (`_navbar.md`)](#navbar-_navbarmd)
- [Cover page (`_coverpage.md`)](#cover-page-_coverpagemd)
- [404 page](#404-page)
- [Multi-language sites](#multi-language-sites)
- [Reminders](#reminders)

---

## Adding pages

Each `*.md` becomes a hash route. Folders create nested routes.

```text
docs/README.md        →  /
docs/guide.md         →  /#/guide
docs/api/users.md     →  /#/api/users
```

`README.md` in any folder is the index for that folder.

## Sidebar (`_sidebar.md`)

Enable in config:

```js
window.$docsify = { loadSidebar: true };
```

Create `_sidebar.md`:

```markdown
- [Home](/)
- [Page 1](page-1.md)
```

Section headers (group links under a heading):

```markdown
- Getting started

  - [Quick start](quickstart.md)
  - [Adding pages](adding-pages.md)

- Customization

  - [Configuration](configuration.md)
  - [Themes](themes.md)
```

**Custom per-link title** (better SEO — the `<title>` tag uses the selected sidebar item):

```markdown
- [Guide](guide.md 'The greatest guide in the world')
```

**Custom file name** (not `_sidebar.md`):

```js
window.$docsify = { loadSidebar: 'summary.md' };
```

### Nested sidebars (per-directory)

Add a `_sidebar.md` inside any subfolder; it overrides the parent. Missing ones fall back up the tree. To force a single sidebar everywhere even in `history` mode, set an alias:

```js
window.$docsify = {
  loadSidebar: true,
  alias: { '/.*/_sidebar.md': '/_sidebar.md' },
};
```

The same alias trick applies to `_navbar.md` — in `history` mode you almost always want both aliases together:

```js
window.$docsify = {
  loadSidebar: true,
  loadNavbar: true,
  alias: {
    '/.*/_sidebar.md': '/_sidebar.md',
    '/.*/_navbar.md': '/_navbar.md',
  },
};
```

### Auto Table of Contents

With `_sidebar.md` enabled, headings inside each Markdown page can be auto-listed under that page's sidebar entry by setting:

```js
window.$docsify = { loadSidebar: true, subMaxLevel: 2 };
```

`subMaxLevel: 2` includes `h1`–`h2`. Range is 1–6.

Exclude individual headings from the auto-TOC:

```markdown
## Internal note <!-- {docsify-ignore} -->
```

Exclude **all** headings on a page (place on the first heading):

```markdown
# Reference <!-- {docsify-ignore-all} -->
```

(The `<!-- … -->` wrapper is optional — bare `{docsify-ignore}` also works.)

## Navbar (`_navbar.md`)

Enable in config:

```js
window.$docsify = { loadNavbar: true };
```

```markdown
- [En](/)
- [中文](/zh-cn/)
```

Drop-down menus via nested lists:

```markdown
- Languages

  - [En](/)
  - [中文](/zh-cn/)
```

Per-directory `_navbar.md` falls back up the tree, same as the sidebar. Use `mergeNavbar: true` to fold the navbar into the sidebar on small screens.

For an HTML-based custom navbar instead, place the markup directly in `index.html` above `#app` and link to `#/route` paths.

## Cover page (`_coverpage.md`)

```js
window.$docsify = { coverpage: true };
```

```markdown
![logo](_media/icon.svg)

# My Project <small>1.0</small>

> A short tagline.

- Bullet feature 1
- Bullet feature 2

[GitHub](https://github.com/owner/repo)
[Get Started](#/quickstart)
```

Background color:

```markdown
![color](#f0f0f0)
```

Background image:

```markdown
![](_media/bg.png)
```

Make the cover the **only** landing (no homepage flash beneath it):

```js
window.$docsify = { coverpage: true, onlyCover: true };
```

Multiple covers for multi-language sites:

```js
window.$docsify = { coverpage: ['/', '/zh-cn/'] };
// or with custom file names per route:
window.$docsify = {
  coverpage: { '/': 'cover.md', '/zh-cn/': 'cover.md' },
};
```

Customize via CSS variables (in a `<style>` block in `index.html`):

```css
:root {
  --cover-bg: url('path/to/image.png');
  --cover-bg-overlay: rgba(0, 0, 0, 0.5);
  --cover-color: #fff;
  --cover-title-color: var(--theme-color);
}
```

## 404 page

```js
window.$docsify = { notFoundPage: true };       // loads _404.md
window.$docsify = { notFoundPage: 'my404.md' }; // custom file
window.$docsify = {
  notFoundPage: { '/': '_404.md', '/de/': 'de/_404.md' },
};
```

> `fallbackLanguages` does **not** apply to `notFoundPage`.

## Multi-language sites

```text
docs/
├── README.md
├── _sidebar.md
├── _coverpage.md
├── _navbar.md
└── zh-cn/
    ├── README.md
    ├── _sidebar.md
    ├── _coverpage.md
    └── _navbar.md
```

Optionally configure fallback when a translated page is missing:

```js
window.$docsify = {
  fallbackLanguages: ['fr', 'de'],
  fallbackDefaultLanguage: 'zh-cn', // load from /zh-cn/... when missing
};
```

## Reminders

- Always create `.nojekyll` in the deploy folder for GitHub Pages (otherwise `_sidebar.md`, `_navbar.md`, etc. are 404).
- Sidebar/navbar/cover all require their respective `load*` / `coverpage` flag — the file alone is not enough.
