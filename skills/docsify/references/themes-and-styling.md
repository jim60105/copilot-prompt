# Themes and styling

Docsify v5 ships a single **core theme** and optional **add-ons**, all customizable via CSS variables.

## Contents

- [Loading the theme](#loading-the-theme)
- [Body classes](#body-classes)
- [Customization via CSS variables](#customization-via-css-variables)
- [Common variables](#common-variables)
- [Custom CSS declarations](#custom-css-declarations)
- [v4 themes](#v4-themes)
- [Community themes](#community-themes)

---

## Loading the theme

The core theme is required:

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/core.min.css" />
```

Add-ons must be loaded **after** the core theme.

### Dark mode add-on

Always-on dark:

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/addons/core-dark.min.css" />
```

OS-preference dark mode only:

```html
<link rel="stylesheet"
      href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/addons/core-dark.min.css"
      media="(prefers-color-scheme: dark)" />
```

### Classic Vue look (v4 theme as an add-on)

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/addons/vue.min.css" />
```

## Body classes

Apply on the `<body>` tag in `index.html`:

| Class | Effect |
| --- | --- |
| `loading` | Show a loading spinner while Docsify boots (recommended) |
| `sidebar-chevron-right` / `sidebar-chevron-left` | Show expand/collapse chevrons on sidebar links |
| `sidebar-group-box` / `sidebar-group-underline` | Visual separation between sidebar sections |
| `sidebar-link-clamp` | Truncate long sidebar links to one line |
| `sidebar-toggle-hamburger` / `sidebar-toggle-chevron` | Change the toggle icon |

```html
<body class="loading sidebar-chevron-right sidebar-group-box">
```

Per-link override to hide the chevron:

```markdown
[My Page](page.md ':class=no-chevron')
```

## Customization via CSS variables

Place a `<style>` block **after** the theme stylesheet:

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@5.0.0-rc.4/dist/themes/core.min.css" />
<style>
  :root {
    --theme-color: #42b983;
    --font-size: 15px;
    --line-height: 1.5;
  }
</style>
```

Light/dark conditional values:

```css
:root { --theme-color: pink; }

@media (prefers-color-scheme: light) {
  :root { --color-bg: #eee; --color-text: #444; }
}
@media (prefers-color-scheme: dark) {
  :root { --color-bg: #222; --color-text: #ddd; }
}
```

Per-page overrides: include a `<style>` block inside the Markdown file.

### Custom fonts

```css
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;700&display=swap');

:root {
  --font-family: 'Noto Sans', sans-serif;
  --font-family-emoji: 'Noto Color Emoji', sans-serif;
  --font-family-mono: 'Noto Sans Mono', monospace;
}
```

## Common variables

The authoritative list lives in the Docsify source:

- Common: <https://raw.githubusercontent.com/docsifyjs/docsify/refs/heads/develop/src/themes/shared/_vars.css>
- Advanced: <https://raw.githubusercontent.com/docsifyjs/docsify/refs/heads/develop/src/themes/shared/_vars-advanced.css>

Frequently used:

```css
:root {
  --theme-color: #42b983;
  --color-bg: #fff;
  --color-text: #34495e;
  --font-family: system-ui, sans-serif;
  --font-size: 16px;
  --line-height: 1.6;
  --border-radius: 4px;
  --scroll-padding-top: 64px;   /* replaces deprecated topMargin option */

  --sidebar-width: 17rem;
  --sidebar-bg: var(--color-bg);
  --sidebar-nav-link-color--active: var(--theme-color);

  --content-max-width: 65rem;

  --cover-bg: linear-gradient(to bottom, #42b983, #2c8d6e);
  --cover-color: #fff;
  --cover-title-color: var(--theme-color);

  --sidebar-chevron-collapsed-color: var(--color-mono-3);
  --sidebar-chevron-expanded-color: var(--theme-color);
}
```

## Custom CSS declarations

Variables don't cover everything. Custom selectors work but can break across Docsify updates — pin your CDN URL to a specific version when relying on them.

```css
.sidebar li.active > a {
  border-right: 3px solid var(--theme-color);
}
```

## v4 themes

The v4 `vue`, `buble`, `dark`, and `pure` themes were replaced by the v5 core theme. Only the Vue look has an official add-on. See `advanced.md` for the full v4→v5 migration.

## Community themes

See <https://github.com/docsifyjs/awesome-docsify#themes> for additional themes contributed by the community.
