# Plugins

How to install and configure Docsify plugins. To write your own, see `writing-plugins.md`.

## Contents

- [Installing a plugin](#installing-a-plugin)
- [Official plugins](#official-plugins-shipped-under-docsify500-rc4distplugins)
- [Popular community plugins](#popular-community-plugins)
- [Inline plugins](#inline-plugins)

---

## Installing a plugin

1. Add a `<script>` tag **after** `docsify.min.js` in `index.html`.
2. (Optional) Add the plugin's settings inside `window.$docsify`.

```html
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/docsify.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/search.min.js"></script>
```

> Plugin scripts must come **after** `docsify.min.js`, otherwise they won't register.

## Official plugins (shipped under `docsify@5.0.0-rc.4/dist/plugins/…`)

### Full-text search (`search.min.js`)

```html
<script>
  window.$docsify = {
    search: 'auto', // default — index pages found via sidebar links
  };
</script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/search.min.js"></script>
```

Explicit paths or full config:

```js
search: ['/', '/guide', '/zh-cn/'];

search: {
  paths: [],             // [] = use links from page, 'auto' = sidebar-based
  maxAge: 86400000,      // index TTL, ms (default 1 day)
  placeholder: 'Type to search',
  noData: 'No Results!',
  depth: 2,              // index heading depth 1–6
  namespace: 'website-1',// avoid index collisions on shared domains
  pathNamespaces: ['/zh-cn', '/ru-ru'], // separate indexes per locale (auto mode only)
  // or a regex:
  // pathNamespaces: /^(\/(zh-cn|ru-ru))?(\/(v1|v2))?/,
  insertAfter: '.app-name',   // sidebar position (or insertBefore)
  placeholder: { '/zh-cn/': '搜索', '/': 'Type to search' },
  noData: { '/zh-cn/': '找不到结果', '/': 'No Results' },
}
```

Diacritics are ignored (e.g. "cafe" matches "café").

### Google Analytics 4 / gtag (`gtag.min.js`)

```html
<script>
  window.$docsify = { gtag: 'G-XXXXXXXX' };
  // multiple IDs supported:
  // gtag: ['G-XXXXXXXX', 'AW-XXXXXXXX']
</script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/gtag.min.js"></script>
```

### Legacy Google Analytics (`ga.min.js`)

```html
<script>window.$docsify = { ga: 'UA-XXXXX-Y' };</script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/ga.min.js"></script>
```

Or as a `data-ga` attribute on the docsify script tag.

### Emoji (`emoji.min.js`)

Deprecated as of v4.13 — Docsify v5 renders the common emoji shorthand list natively. Only needed for the extended emoji catalog.

### External script (`external-script.min.js`)

Required when `executeScript` is on and a Markdown `<script>` tag uses `src="…"`:

```html
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/external-script.min.js"></script>
```

### Front matter (`front-matter.min.js`)

Parses YAML front matter at the top of each Markdown file and exposes it on the page-data object (`vm.frontmatter`). Without this plugin, Docsify treats front matter as raw text. Load it whenever pages start with a `---` block:

```html
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/front-matter.min.js"></script>
```

Example page:

```markdown
---
title: My page
tags: [docs, intro]
---

# {{ title }}
```

Combine with `executeScript: true` or a small inline plugin to render front-matter fields into the page (Docsify does **not** automatically interpolate front matter into Markdown).

### Zoom image (`zoom-image.min.js`)

Medium-style image zoom (based on `medium-zoom`). The v5 upgrade notes mention a rename to `zoom`, but the v5 release candidate (`5.0.0-rc.4`) still ships the file as `zoom-image.min.js`; use that path until v5 stable is published.

```html
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/zoom-image.min.js"></script>
```

Skip specific images: `![](photo.jpg ':no-zoom')`.

### Disqus comments (`disqus.min.js`)

```html
<script>window.$docsify = { disqus: 'your-shortname' };</script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/disqus.min.js"></script>
```

### Gitalk comments (`gitalk.min.js`)

GitHub-Issue-backed comments. Requires the gitalk runtime + a `Gitalk` instance:

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/gitalk/dist/gitalk.css" />
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/gitalk.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/gitalk/dist/gitalk.min.js"></script>
<script>
  const gitalk = new Gitalk({
    clientID: '...', clientSecret: '...',
    repo: '...', owner: '...', admin: ['...'],
    distractionFreeMode: false,
  });
</script>
```

## Popular community plugins

### Copy-to-clipboard (`docsify-copy-code`)

Adds a "copy" button to every code block.

```html
<script src="//cdn.jsdelivr.net/npm/docsify-copy-code"></script>
```

<https://github.com/jperasmus/docsify-copy-code>

### Pagination (`docsify-pagination`)

Prev/next links at the bottom of each page.

```html
<script src="//cdn.jsdelivr.net/npm/docsify-pagination/dist/docsify-pagination.min.js"></script>
```

<https://github.com/imyelo/docsify-pagination>

### Tabs (`docsify-tabs`)

Render tabbed content from Markdown blocks.

<https://jhildenbiddle.github.io/docsify-tabs>

### Edit on GitHub

<https://github.com/njleonzhang/docsify-edit-on-github>. Or implement it yourself in 10 lines using a `beforeEach` hook — see `writing-plugins.md`.

### Demo box (Vue / React)

Render runnable code samples with a JSFiddle link.

- <https://njleonzhang.github.io/docsify-demo-box-vue/>
- <https://njleonzhang.github.io/docsify-demo-box-react/>

### Awesome Docsify

For more plugins: <https://github.com/docsifyjs/awesome-docsify#plugins>.

## Inline plugins

You can also add plugins directly to `$docsify.plugins` without a separate `<script>`:

```js
window.$docsify = {
  plugins: [
    function (hook, vm) {
      hook.afterEach(html => html + '<footer>© 2025</footer>');
    },
  ],
};
```

See `writing-plugins.md` for the full lifecycle API.
