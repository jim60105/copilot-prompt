# Writing Guidelines for 聆.tw Blog Posts

This reference contains the full editorial guidelines for writing blog posts. Read this when composing content.

## Language and Formatting

- Write in **Traditional Chinese 正體中文** (zh-TW) with full-width punctuation（，。、；：「」『』（）！？）
- Always insert a single space between Chinese characters and alphanumeric characters (e.g., `使用 Docker 建立`)
- Use standard Taiwan Traditional Chinese terminology for technical terms
- Address readers as 「讀者」「大家」「各位」 or 「你」, never 「您」
- Refer to the author as 「我」, never 「我們」

## Structure

- Use inverted pyramid structure: core conclusion and scope first, supporting evidence second
- Opening paragraph states the core conclusion and scope directly
- Subsequent paragraphs provide evidence and limitations
- Closing paragraph must not use slogan-style endings
- Use natural paragraphs with `##` and `###` subheadings
- Avoid bullet lists unless explicitly requested or justified; prefer prose
- Use markdown reference-style links when citing sources. But only for external sources, not for internal links. Each reference link must not be used more than once in the article.

## Tone and Style

- Friendly yet professional; approachable expert, not academic
- Neutral, restrained, verifiable
- Prioritize reader comprehension over ornate rhetoric
- Factual presentation with clear argumentation

## Output Principles

1. **Facts First**: All judgments must rest on verifiable data, case studies, or explicit logic. No vague attributions like 「研究指出」 or 「資料顯示」
2. **Direct Statement**: Prefer neutral, verifiable declarative and conditional sentences
3. **De-templated Rhythm**: Avoid mechanical three-point structures and symmetrical parallelism
4. **Clear Communication**: One point per sentence. Break long sentences with commas or semicolons

## Hard Constraints

- Contrastive Construction (「不是…是」): max once per post
- Parallelism/Tricolons: max once per post, max 3 sub-items, no semantic redundancy
- Rhetorical Questions: max once per post, must not chain >2, concrete answer must follow
- Em-dash (——): max twice per post, only for essential qualification
- Never use 「總的來說」
- Avoid 「不只...更...」 「不僅...也...」 「...能有效...」 「往往」 「至關重要」 「精心打造」 「確保」
- Avoid reduplicated words
- Avoid hedging phrases like 「可以說」「某種程度上」「在多數情況下」; replace with conditional qualifications

## Alternative Patterns

When tempted to use restricted devices, use instead:

- **Direct Conclusion + Evidence**: State judgment first, then provide support
- **Conditional Sentence**: 「在 X 條件下，Y 成立；超出範圍不保證」
- **Subheading + Short Paragraph**: 2-4 lines addressing one aspect
- **Definition-Scope-Example**: Define concept, specify scope, give one example

## Automatic Rewrite Rules

- 「不是…是」 → 「核心重點在於…；次要面向為…」
- Tricolon parallelism with redundant items → consolidate into one prose paragraph
- Rhetorical question → declarative problem-and-answer format
- Consecutive em-dashes → extract into independent sentence or conditional qualification

## Shortcodes

### Images

Use `<figure>` with `{{ image() }}` shortcode instead of `![]()`：

```markdown
<figure>
{{ image(url="preview.jpg", alt="Describe the image") }}
<figcaption>Caption text.</figcaption>
</figure>
```

Parameters: `url`, `alt`, `href`, `full`, `full_bleed`, `start`, `end`, `pixels`, `transparent`, `no_hover`, `spoiler`, `no_srcset`. Always use `no_srcset=true` on GIF images.

### Chat Conversations

```markdown
{% chat(speaker="yuna") %}
Yuna's message content
{% end %}

{% chat(speaker="jim") %}
Author's response (displays as 琳, aligned right)
{% end %}
```

Available speakers: `chatgpt`, `claude`, `gemini`, `copilot`, `felo`, `jim` (author), `yoruka`, or any custom name.

### Color Highlights

For pros (green): `{{ cg(body="positive text") }}` or block form `{% cg() %}text{% end %}`

For cons (red): `{{ cr(body="negative text") }}` or block form `{% cr() %}text{% end %}`

### Alerts

```markdown
{% alert(edit=true) %}
Alert content
{% end %}
```

### Mermaid Diagrams

```html
<pre class="mermaid">
  flowchart LR
      A[Step 1] --> B[Step 2]
</pre>
```

### Comments (Author-Only Notes)

Use `{# comment text #}` for notes visible only during writing.

Use `{# image placement: describe the image #}` to indicate where to insert an image later.

## SEO Best Practices for Title and Description

### Title

- Include the primary keyword near the front
- Keep concise but descriptive (typically 30-60 characters in Chinese)
- Use Traditional Chinese
- Make it compelling for click-through

### Description

- Include all important keywords from the article
- ~150-160 characters ideal (for search result snippets)
- Compelling and informative — this text appears in Google search results
- Summarize the article's value proposition to the reader

## Review Checklist

Before finalizing:

1. Do consecutive paragraph openings use the same rhetorical device? Rewrite if yes.
2. Do any restricted devices exceed their quota? Retain only the most necessary instance.
3. Does each key claim have evidence? Downgrade unsupported claims to hypotheses.
4. Are there unsourced strong assertions? Rewrite to conditional qualifications.
5. Are sentences overlong? Split into short sentences with clear subject-verb-object structure.
6. Are spaces correctly placed between Chinese and alphanumeric characters?
7. Is bold/italic/color formatting applied to appropriate emphasis points?
