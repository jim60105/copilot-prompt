# Advanced topics

PWA / offline, virtual routes, Vue.js compatibility, and the v4 → v5 upgrade.

## Contents

- [Offline support (PWA)](#offline-support-pwa)
- [Virtual routes (`routes`)](#virtual-routes-routes)
- [Vue.js compatibility](#vuejs-compatibility)
- [Upgrading v4 → v5](#upgrading-v4--v5)

---

## Offline support (PWA)

Add a service worker so the site works offline / on flaky networks.

### 1. Create `sw.js` next to `index.html`

```js
const RUNTIME = 'docsify';
const HOSTNAME_WHITELIST = [
  self.location.hostname,
  'fonts.gstatic.com',
  'fonts.googleapis.com',
  'cdn.jsdelivr.net',
];

const getFixedUrl = req => {
  const now = Date.now();
  const url = new URL(req.url);
  url.protocol = self.location.protocol;
  if (url.hostname === self.location.hostname) {
    url.search += (url.search ? '&' : '?') + 'cache-bust=' + now;
  }
  return url.href;
};

self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));

self.addEventListener('fetch', event => {
  if (HOSTNAME_WHITELIST.indexOf(new URL(event.request.url).hostname) > -1) {
    const cached = caches.match(event.request);
    const fetched = fetch(getFixedUrl(event.request), { cache: 'no-store' });
    const fetchedCopy = fetched.then(r => r.clone());

    event.respondWith(
      Promise.race([fetched.catch(() => cached), cached])
        .then(r => r || fetched)
        .catch(() => {}),
    );
    event.waitUntil(
      Promise.all([fetchedCopy, caches.open(RUNTIME)])
        .then(([resp, cache]) => resp.ok && cache.put(event.request, resp))
        .catch(() => {}),
    );
  }
});
```

This implements stale-while-revalidate caching for same-origin requests and the CDN/font hosts.

### 2. Register in `index.html`

```html
<script>
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js');
  }
</script>
```

## Virtual routes (`routes`)

Generate page content programmatically — no Markdown file required. See `configuration.md#routes` for the full spec.

Quick recap:

```js
window.$docsify = {
  routes: {
    '/foo': '# Custom Markdown',
    '/bar/(.*)'(route, matched) { return '# ' + matched[0]; },
    '/baz/(.+)'(route, matched, next) {
      fetch('/api/post/' + matched[0]).then(r => r.text()).then(next);
    },
    '/pets/cats'() { return false; },          // defer to real file
    '/pets/(.+)'() { return null; },           // ignore, continue matching
  },
};
```

Return values:

- **string** → rendered as Markdown.
- **`false`** → skip routes; let Docsify load the real file at that path.
- **`null` / `undefined`** → this matcher ignores the request; try the next route.

Order matters; declare specific routes before catch-alls.

## Vue.js compatibility

Docsify can render Vue 3 directly inside Markdown. Add Vue to `index.html`:

```html
<script src="//cdn.jsdelivr.net/npm/vue@3/dist/vue.global.prod.js"></script>
```

Then you can use template syntax (`{{ … }}`, `v-for`, `v-if`, etc.) anywhere in Markdown. Code blocks are ignored by default; wrap with `<div v-template>…</div>` to opt back in.

### Global options

```js
window.$docsify = {
  vueGlobalOptions: {
    data() { return { count: 0 }; },
  },
};
```

Global `data` **persists across page navigations**.

### Mounts

Mount a specific DOM node with its own data (reset on each navigation):

```js
window.$docsify = {
  vueMounts: {
    '#counter': { data() { return { count: 0 }; } },
  },
};
```

```markdown
<div id="counter">
  <button @click="count += 1">+</button> {{ count }}
</div>
```

### Components

Register global components with per-instance state:

```js
window.$docsify = {
  vueComponents: {
    'button-counter': {
      template: `<button @click="count++">Clicked {{ count }} times</button>`,
      data() { return { count: 0 }; },
    },
  },
};
```

```markdown
<button-counter></button-counter>
```

### Inline `<script>` in Markdown

```html
<script>
  Vue.createApp({ /* options */ }).mount('#example');
</script>
```

> Only the **first** `<script>` tag in a Markdown file executes. Mount all instances inside it.

### Render order on each page load

1. Run the page's inline `<script>`.
2. Register `vueComponents`.
3. Mount `vueMounts`.
4. Auto-mount unmounted `vueComponents`.
5. Auto-mount template syntax using `vueGlobalOptions`.

Docsify auto-destroys all Vue instances it created before each page change.

## Upgrading v4 → v5

Mostly URL changes. Config keys stay the same; Markdown content unchanged.

### 1. Theme

```html
<!-- v4 -->
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css" />

<!-- v5 -->
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/core.min.css" />
<!-- optional dark mode -->
<link rel="stylesheet"
      href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/addons/core-dark.min.css"
      media="(prefers-color-scheme: dark)" />
```

The legacy v4 `buble` / `dark` / `pure` / `vue` themes are replaced by the new core theme (with Vue and dark add-ons).

### 2. Docsify core

```html
<!-- v4 -->
<script src="//cdn.jsdelivr.net/npm/docsify@4/lib/docsify.min.js"></script>
<!-- v5 -->
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/docsify.min.js"></script>
```

### 3. Plugins

The path changes from `/lib/plugins/…` to `/dist/plugins/…`. Examples:

```html
<!-- search -->
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/search.min.js"></script>

<!-- zoom (renamed from zoom-image) -->
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/plugins/zoom-image.min.js"></script>

<!-- emoji, external-script, front-matter, etc. follow the same rename -->
```

### 4. Optional body class

```html
<body class="sidebar-chevron-right">
```

Adds chevron indicators to sidebar links.

### Key differences

| Area | v4 | v5 |
| --- | --- | --- |
| CDN path | `/lib/` | `/dist/` |
| Version tag | `@4` | `@5` |
| Default theme | `vue.css` (one of four) | core theme + optional add-ons |
| Zoom plugin name | `zoom-image` | `zoom-image` (rc.4 still); rename to `zoom` planned for stable v5 |
| `themeColor` config | supported | deprecated → CSS var `--theme-color` |
| `topMargin` config | supported | deprecated → CSS var `--scroll-padding-top` |
| `!>` / `?>` callouts | supported | deprecated → `> [!IMPORTANT]` / `> [!TIP]` |
| IE11 support | yes | no |

Custom CSS rules targeting v4 internal class names may need updating. Switching to CSS variables (`themes-and-styling.md`) makes future upgrades safer.
