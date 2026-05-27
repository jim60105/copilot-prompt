# Markdown helpers

Docsify-specific Markdown extensions, on top of standard CommonMark/marked.

> For tricky cases, wrap the special syntax in code backticks to avoid conflicts with emoji or config-driven transforms.

## Contents

- [Callouts (GitHub-style)](#callouts-github-style)
- [Link attributes](#link-attributes)
- [Heading IDs](#heading-ids)
- [Task lists](#task-lists)
- [Images](#images)
- [Mixing Markdown with HTML](#mixing-markdown-with-html)
- [Embedding files (`:include`)](#embedding-files-include)
- [Code highlighting (Prism)](#code-highlighting-prism)
- [Mermaid diagrams](#mermaid-diagrams)

---

## Callouts (GitHub-style)

```markdown
> [!CAUTION]
> Negative potential consequences of an action.

> [!IMPORTANT]
> Information necessary for users to succeed.

> [!NOTE]
> Information users should take into account.

> [!TIP]
> Optional information to help users be more successful.

> [!WARNING]
> Potential risks users should be aware of.
```

### Legacy (deprecated in v5, will be removed)

```markdown
!> Important
?> Tip
```

Prefer the bracketed style above.

## Link attributes

### `:disabled`

```markdown
[link](/demo ':disabled')
```

### `:ignore` — don't compile this link

By default `[link](/demo/)` becomes `<a href="#/demo/">` and loads `demo/README.md`. To link to a literal path (e.g. `/demo/index.html`):

```markdown
[link](/demo/ ':ignore')
[link](/demo/ ':ignore title')
```

### `:target`

```markdown
[link](/demo ':target=_blank')
[link](/demo2 ':target=_self')
```

## Heading IDs

Override the auto-generated anchor:

```markdown
### Hello, world! :id=hello-world
```

## Task lists

```markdown
- [ ] foo
- [x] baz
  - [ ] nested
```

Note: `- []` (no space) does **not** render as a task list — must be `- [ ]`.

## Images

Class / ID / size attributes via alt-suffix syntax:

```markdown
![logo](icon.svg ':class=someCssClass')
![logo](icon.svg ':class=cls1 :class=cls2')
![logo](icon.svg ':id=someId')
![logo](icon.svg ':size=WIDTHxHEIGHT')
![logo](icon.svg ':size=50x100')
![logo](icon.svg ':size=100')
![logo](icon.svg ':size=10%')
![logo](photo.jpg ':no-zoom')          /* skip the zoom-image plugin */
```

## Mixing Markdown with HTML

Leave a blank line between the HTML tag and Markdown content:

```markdown
<details>
<summary>Click to expand</summary>

- Item A
- Item B

</details>
```

This is what makes `<details>` blocks render their inner Markdown.

## Embedding files (`:include`)

```markdown
[label](_media/example.md ':include')
[label](_media/example.md ':include :type=code')
[label](_media/example.js ':include :type=code :fragment=demo')
[label](_media/sample.mp4 ':include :type=video controls width=100%')
[label](https://cinwell.com ':include :type=iframe width=100% height=400px')
```

### Auto-detected types

| Extension | Renders as |
| --- | --- |
| `.html`, `.htm` | iframe |
| `.md`, `.markdown` | inlined Markdown |
| `.mp3` | audio |
| `.mp4`, `.ogg` | video |
| anything else | code block |

Force a type with `:type=…` (e.g. `:type=code` to show a Markdown file as a syntax-highlighted block).

### Fragments

Embed only a labelled snippet from a file. In the source file (e.g. `example.js`), wrap the snippet with `/// [demo]` markers (or `### [demo]` in shells):

```javascript
/// [demo]
console.log('hello');
/// [demo]
```

Then:

```markdown
[snippet](_media/example.js ':include :type=code :fragment=demo')
```

Add `:omitFragmentLine` to also hide the marker lines themselves (useful when the markers are embedded in HTML comments).

### Front matter

Markdown files with YAML front matter have it stripped on embed; the front-matter values are not exposed to the embedding page.

### Embedding gists

Use the raw gist URL with `:include`. Strip any revision hash so updates flow through:

```markdown
[gist](https://gist.githubusercontent.com/USER/GIST_ID/raw/FILENAME ':include')
[gist](https://gist.githubusercontent.com/USER/GIST_ID/raw/script.js ':include :type=code')
```

## Code highlighting (Prism)

Default languages: HTML/XML, CSS, C-like, JavaScript.

Code fences with a language tag are highlighted automatically:

````markdown
```python
def add(a, b):
    return a + b
```
````

Add more languages by loading Prism grammar files **after** `docsify.min.js`:

```html
<script src="//cdn.jsdelivr.net/npm/prismjs@1/components/prism-bash.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/prismjs@1/components/prism-python.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/prismjs@1/components/prism-typescript.min.js"></script>
<script src="//cdn.jsdelivr.net/npm/prismjs@1/components/prism-yaml.min.js"></script>
```

Apply a Prism theme (load **after** the Docsify theme):

```html
<link rel="stylesheet"
      href="//cdn.jsdelivr.net/npm/prism-themes@1/themes/prism-one-light.min.css" />
<link rel="stylesheet" media="(prefers-color-scheme: dark)"
      href="//cdn.jsdelivr.net/npm/prism-themes@1/themes/prism-one-dark.min.css" />
```

Docsify overrides three Prism style properties by default (`--border-radius`, `--font-family-mono`, `--font-size-mono`). To let Prism's own values win, set them to `unset` in your `:root`.

For dynamically generated code blocks, call `Prism.highlightElement(el)`.

## Mermaid diagrams

> Docsify supports only **synchronous** Mermaid (≤ v9.3.0).

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.css" />
<script src="//cdn.jsdelivr.net/npm/mermaid@9.3.0/dist/mermaid.min.js"></script>
<script>
  let num = 0;
  mermaid.initialize({ startOnLoad: false });
  window.$docsify = {
    markdown: {
      renderer: {
        code({ text, lang }) {
          if (lang === 'mermaid') {
            return `<div class="mermaid">${mermaid.render('m-' + num++, text)}</div>`;
          }
          return this.origin.code.apply(this, arguments);
        },
      },
    },
  };
</script>
```
