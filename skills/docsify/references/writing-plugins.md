# Writing a Docsify plugin

A Docsify plugin is a function `(hook, vm) => void` that registers lifecycle callbacks. Use plugins to inject custom JavaScript at well-defined points in Docsify's render cycle.

## Contents

- [Two ways to register](#two-ways-to-register)
- [Lifecycle hooks](#lifecycle-hooks)
- [What's on `vm`](#whats-on-vm)
- [Tips](#tips)
- [Examples](#examples)

---

## Two ways to register

### Inline in config

```js
window.$docsify = {
  plugins: [
    function myPlugin(hook, vm) {
      // ...
    },
  ],
};
```

### As a separate file (recommended for reuse)

`docsify-plugin-myplugin.js`:

```js
{
  function myPlugin(hook, vm) {
    // ...
  }

  window.$docsify = window.$docsify || {};
  $docsify.plugins = [...($docsify.plugins || []), myPlugin];
}
```

Load with:

```html
<script src="docsify-plugin-myplugin.js"></script>
```

> The script tag **must come after** `docsify.min.js`.

## Lifecycle hooks

| Hook | Frequency | Receives | Returns / async? |
| --- | --- | --- | --- |
| `init` | once, on script init | — | sync |
| `mounted` | once, after Docsify mounts to DOM | — | sync |
| `beforeEach` | each page, **before** Markdown→HTML | raw `markdown` string | return new markdown (sync) or call `next(markdown)` (async) |
| `afterEach` | each page, **after** Markdown→HTML | rendered `html` string | return new html (sync) or call `next(html)` (async) |
| `doneEach` | each page, after HTML appended to DOM | — | sync |
| `ready` | once, after the initial page is rendered | — | sync |

### Template

```js
function myPlugin(hook, vm) {
  hook.init(() => {});
  hook.mounted(() => {});

  hook.beforeEach(markdown => {
    return markdown;
  });

  hook.afterEach(html => {
    return html;
  });

  hook.doneEach(() => {});
  hook.ready(() => {});
}
```

### Async variants

Both `beforeEach` and `afterEach` accept a `next` callback as the second argument. Wrap async work in `try/catch/finally` so a failure here doesn't break the rest of the render pipeline (see also the `catchPluginErrors` config option):

```js
hook.beforeEach((markdown, next) => {
  try {
    fetch('/api').then(/* … */).then(extra => next(markdown + extra));
  } catch (err) {
    next(markdown);
  }
});
```

## What's on `vm`

Useful properties available on the Docsify instance:

- `vm.route` — current route info (`vm.route.file`, `vm.route.path`, `vm.route.query`).
- `vm.config` — the merged `$docsify` config.
- `vm.compiler` — the Markdown compiler.
- `window.Docsify` — global helpers (`Docsify.dom.find`, `Docsify.dom.findAll`, `Docsify.get`, `Docsify.slugify`, etc.).

## Tips

- Set `$docsify.catchPluginErrors = false` while developing — your debugger can then pause on uncaught errors instead of Docsify swallowing them.
- Test your plugin on every config combination it touches (with/without sidebar, navbar, cover, search, etc.).
- For plugins that modify links, remember Docsify also processes link attributes (`:disabled`, `:ignore`, `:target=…`).

## Examples

### Page footer (append HTML after each page)

```js
window.$docsify = {
  plugins: [
    function pageFooter(hook) {
      const footer = `
        <hr/>
        <footer>
          <span>Proudly published with
            <a href="https://docsify.js.org" target="_blank">Docsify</a>.</span>
        </footer>`;
      hook.afterEach(html => html + footer);
    },
  ],
};
```

### "Edit on GitHub" button (prepend before each page)

```js
window.$docsify = {
  formatUpdated: '{YYYY}/{MM}/{DD} {HH}:{mm}',
  plugins: [
    function editButton(hook, vm) {
      hook.beforeEach(md => {
        const url = `https://github.com/owner/repo/blob/main/docs/${vm.route.file}`;
        const edit = `[📝 EDIT](${url})\n`;
        return `${edit}\n${md}\n\n----\nLast modified {docsify-updated}\n${edit}`;
      });
    },
  ],
};
```

### Inject a CSS class on `<body>` per route

```js
hook.doneEach(() => {
  document.body.dataset.route = vm.route.path;
});
```
