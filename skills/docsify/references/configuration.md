# Configuration (`window.$docsify`)

Configure Docsify by setting `window.$docsify` **before** loading `docsify.min.js`:

```html
<script>
  window.$docsify = {
    name: 'My Docs',
    repo: 'owner/repo',
    loadSidebar: true,
    subMaxLevel: 2,
    coverpage: true,
  };
</script>
<script src="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4"></script>
```

It can also be a **function** that receives the Docsify `vm` and returns a config object (useful when configuring a `markdown.renderer` that needs `vm`):

```js
window.$docsify = function (vm) {
  return { markdown: { renderer: { code(code, lang) { /* use vm */ } } } };
};
```

## Quick index

- Site identity: [`name`](#name), [`nameLink`](#namelink), [`logo`](#logo), [`repo`](#repo)
- Navigation: [`loadSidebar`](#loadsidebar), [`loadNavbar`](#loadnavbar), [`coverpage`](#coverpage), [`onlyCover`](#onlycover), [`hideSidebar`](#hidesidebar), [`autoHeader`](#autoheader), [`subMaxLevel`](#submaxlevel), [`maxLevel`](#maxlevel), [`mergeNavbar`](#mergenavbar), [`auto2top`](#auto2top), [`homepage`](#homepage), [`notFoundPage`](#notfoundpage)
- Routing: [`routerMode`](#routermode), [`alias`](#alias), [`basePath`](#basepath), [`relativePath`](#relativepath), [`routes`](#routes), [`noCompileLinks`](#nocompilelinks)
- Localization: [`fallbackLanguages`](#fallbacklanguages), [`fallbackDefaultLanguage`](#fallbackdefaultlanguage), [`skipLink`](#skiplink)
- Content rendering: [`markdown`](#markdown), [`ext`](#ext), [`executeScript`](#executescript), [`requestHeaders`](#requestheaders), [`pageTitleFormatter`](#pagetitleformatter), [`formatUpdated`](#formatupdated)
- Links: [`externalLinkTarget`](#externallinktarget), [`externalLinkRel`](#externallinkrel), [`cornerExternalLinkTarget`](#cornerexternallinktarget)
- Emoji: [`nativeEmoji`](#nativeemoji), [`noEmoji`](#noemoji)
- Vue: [`vueComponents`](#vuecomponents), [`vueGlobalOptions`](#vueglobaloptions), [`vueMounts`](#vuemounts)
- Misc: [`el`](#el), [`keyBindings`](#keybindings), [`plugins`](#plugins), [`catchPluginErrors`](#catchpluginerrors)

---

## alias

`Object`. Route aliases. Order matters; regex supported.

```js
alias: {
  '/foo/(.*)': '/bar/$1',
  '/changelog': 'https://raw.githubusercontent.com/owner/repo/main/CHANGELOG',
  '/.*/_sidebar.md': '/_sidebar.md', // recommended with routerMode: 'history'
}
```

## auto2top

`Boolean`, default `false`. Scroll to top on route change.

## autoHeader

`Boolean`, default `false`. With `loadSidebar`, prepends an H1 header (matching the sidebar link text) to each page that has no H1.

## basePath

`String`. Base path; can point to another directory or even another origin (e.g. load Markdown from a different repo).

```js
basePath: 'https://raw.githubusercontent.com/owner/repo/main/';
```

## catchPluginErrors

`Boolean`, default `true`. Catches uncaught synchronous plugin errors so one bad plugin doesn't break rendering. Set to `false` while debugging to let your debugger pause on exceptions.

## cornerExternalLinkTarget

`String`, default `'_blank'`. Target for the top-right GitHub corner link.

## coverpage

`Boolean | String | String[] | Object`, default `false`. See `pages-and-navigation.md` for full syntax. `true` loads `_coverpage.md`.

## el

`String`, default `'#app'`. Mount selector (or pass an HTMLElement).

## executeScript

`Boolean`, default `null`. Execute the first `<script>` tag on each page. Auto-true if Vue is detected. For external scripts (`src=…`), also load the [external-script](plugins.md) plugin.

## ext

`String`, default `'.md'`. File extension requested for routes.

## externalLinkTarget

`String`, default `'_blank'`.

## externalLinkRel

`String`, default `'noopener'`. Only applied when `externalLinkTarget` is `'_blank'`.

## fallbackLanguages

`string[]`. Languages whose missing pages fall back to the default-language equivalent.

## fallbackDefaultLanguage

`String`, default `''`. When set, missing-page lookups try this locale instead of the root.

## formatUpdated

`String | Function`. Formatter for `{docsify-updated}` placeholder. Patterns follow [tinydate](https://github.com/lukeed/tinydate#patterns).

```js
formatUpdated: '{MM}/{DD} {HH}:{mm}';
```

## hideSidebar

`Boolean`. Hides the sidebar entirely (no markup rendered).

## homepage

`String`, default `'README.md'`. Use a different homepage file:

```js
homepage: 'home.md';
homepage: 'https://raw.githubusercontent.com/owner/repo/main/README.md';
```

## keyBindings

`Boolean | Object`. Defaults: `\` toggles sidebar, `/` (or `alt`/`ctrl`+`k`) focuses search.

```js
keyBindings: {
  myCustomBinding: { bindings: ['alt+a'], callback(e) { alert('hi'); } },
  focusSearch: false,   // disable an individual default binding
}
keyBindings: false      // disable all
```

## loadNavbar / loadSidebar

`Boolean | String`. `true` loads `_navbar.md` / `_sidebar.md`; a string loads a custom file name.

## logo

`String`. Sidebar logo image URL. Only renders when [`name`](#name) is also set.

## markdown

`Object | Function`. Customize the [marked](https://marked.js.org/) parser/renderer. See `markdown-helpers.md` for examples (incl. Mermaid).

```js
markdown: {
  smartypants: true,
  renderer: { link() { /* … */ } },
}
// or full override:
markdown(marked, renderer) { /* … */ return marked; }
```

## maxLevel

`Number`, default `6`. Max heading level included in the auto-TOC.

## mergeNavbar

`Boolean`, default `false`. Merge navbar into sidebar on small screens.

## name

`Boolean | String`. Site name in the sidebar. Accepts HTML. `true` infers from the document `<title>`.

## nameLink

`String | Object`, default `window.location.pathname`. URL the `name` links to; can be a per-route map.

## nativeEmoji

`Boolean`, default `false`. Render `:smile:` as native Unicode instead of GitHub PNGs.

## noCompileLinks

`string[]`. Regex strings; matching link `href`s are left unprocessed by Docsify.

```js
noCompileLinks: ['/foo', '/bar/.*'];
```

## noEmoji

`Boolean`, default `false`. Disable emoji shorthand parsing entirely. To disable a single occurrence use `&colon;100&colon;`.

## notFoundPage

`Boolean | String | Object`. See `pages-and-navigation.md`.

## onlyCover

`Boolean`, default `false`. Show only the cover page on `/` (no homepage flash underneath).

## pageTitleFormatter

`Function`. Customize how `name` is converted into the document title (HTML in `name` is preserved as-is unless this strips it).

## plugins

`Function[]`. Array of plugin functions. See `writing-plugins.md` and `plugins.md`.

## relativePath

`Boolean`, default `false`. When `true`, in-page links resolve relative to the current page (so `./guide.md` and `../README.md` work as expected).

## repo

`String`. `owner/repo` or full GitHub URL. Renders a GitHub corner badge.

## requestHeaders

`Object`. Headers to attach to every Markdown fetch.

```js
requestHeaders: { 'cache-control': 'max-age=600' }
```

## routerMode

`'hash' | 'history'`, default `'hash'`. Use `'history'` only when the host can rewrite all paths to `index.html`. Also add aliases:

```js
routerMode: 'history',
alias: {
  '/.*/_sidebar.md': '/_sidebar.md',
  '/.*/_navbar.md': '/_navbar.md',
},
```

## routes

`Object`. **Virtual routes** — map a path (regex supported) to a string or a function returning Markdown. Order matters.

```js
routes: {
  '/foo': '# Custom',
  '/bar/(.*)'(route, matched) { return `# ${matched[0]}`; },
  '/baz/(.*)'(route, matched, next) {
    fetch('/api').then(r => r.text()).then(md => next(md));
  },
  '/pets/cats'(route) { return false; },  // false → let the real file handle it
  '/pets/(.+)'(route, matched) {
    return matched[0] === 'dogs' ? null : 'fallback md';
  },
}
```

Return values: a **string** → rendered as Markdown; `false` → defer to real file; `null` / `undefined` → ignore this match and continue.

## skipLink

`Boolean | String | Object`, default `'Skip to main content'`. Configures the [skip-nav link](https://webaim.org/techniques/skipnav/). Pass an object for per-route localization, or `false` to disable.

## subMaxLevel

`Number`, default `0`. Auto-TOC depth in the sidebar (typical: `2` or `3`). Range 1–6.

## vueComponents / vueGlobalOptions / vueMounts

See `advanced.md` for Vue integration.

## Deprecated in v5

| Option | Replacement |
| --- | --- |
| `themeColor` | CSS variable `--theme-color` (see `themes-and-styling.md`) |
| `topMargin` | CSS variable `--scroll-padding-top` |
| Legacy `!>` / `?>` callouts | GitHub-style `> [!IMPORTANT]` / `> [!TIP]` |
