---
name: writing-style-guideline
description: >-
  Language-agnostic writing style guidelines covering structure, tone, rhetorical constraints, banned phrases, and review checks.
  Use when writing any kind of content in any language. Including blog posts, notes, technical articles, technical writing, chitchat, social media posts, etc., even when you are just sending a text message.
  Also use when reviewing or editing existing content for tone and style compliance.
  For Traditional Chinese (zh-TW) content, apply `chinese-content-writing-guideline` alongside this skill.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Writing Style Guidelines

This skill defines the writing style for all content regardless of language: structure, tone, rhetorical constraints, banned phrases, and the review checklist. Language-specific rules (script, punctuation width, spacing, grammar particles, and terminology) live in separate skills. For Traditional Chinese (zh-TW), apply `chinese-content-writing-guideline` together with this skill.

Most rules here target the patterns that make text read as machine-generated or padded: templated rhetoric, stock phrases, and vague authority. Readers spot these quickly and stop trusting the content, so each rule states what to avoid and why. When a sentence breaks the letter of a rule for a good reason, keep the reason in mind; when a sentence avoids the letter but keeps the pattern, it still violates the rule.

Some rules below quote zh-TW literals because they were first written for Chinese content. When writing in another language, apply the same rule to the direct equivalent expressions in that language.

## Voice

A single named author with a direct line to the reader reads as accountable; a corporate 「我們」 or "we" hides who is making the claim.

- Refer to the author in the first-person singular (「我」, "I"), never the first-person plural (「我們」, "we").
- Address readers directly and informally (「你」, "you"); avoid overly formal or distant forms of address.

## Structure

Readers decide within the first paragraph whether to keep reading, so the conclusion goes first and the evidence follows.

- Use inverted pyramid structure: core conclusion and scope first, supporting evidence second
- Opening paragraph states the core conclusion and scope directly
- Subsequent paragraphs provide evidence and limitations
- Closing paragraph must not use slogan-style endings
- Use natural paragraphs with `##` and `###` subheadings
- Avoid bullet lists unless explicitly requested or justified; prefer prose
- Use markdown reference-style links for external sources only, not for internal links. Each reference link should appear only once in the article.
- Format all reference-style links using markdown so they display as "links." Use the webpage title (curl fetch it!) as the link text for each reference-style link.

## Tone and Style

- Friendly yet professional; approachable expert, not academic
- Neutral, restrained, verifiable
- Prioritize reader comprehension over ornate rhetoric
- Factual presentation with clear argumentation

## Output Principles

These principles keep every claim checkable by the reader.

1. **Facts First**: All judgments must rest on verifiable data, case studies, or explicit logic. No vague attributions like 「研究指出」 or 「資料顯示」 ("studies show", "data suggests")
2. **Direct Statement**: Prefer neutral, verifiable declarative and conditional sentences
3. **De-templated Rhythm**: Avoid mechanical three-point structures and symmetrical parallelism
4. **Clear Communication**: One point per sentence. Break long sentences with commas or semicolons

## Hard Constraints

### Rhetorical Device Quotas

These devices are the most recognisable fingerprints of templated writing. A contrastive construction invents a wrong view only to knock it down; a tricolon pads one point into three; a chain of rhetorical questions delays the answer; an em-dash bolts an afterthought onto a sentence instead of giving it its own. Each one adds rhythm without adding information.

- **Contrastive Construction** (「不是…是」「不是…而是」「這不是…，是」「差別不在於…而在於…」; in English "not X, but Y", "It's not X, it's Y", "The difference isn't X, it's Y"): never use. Zero instances allowed; grep the literal strings 不是…而是 / 這不是…是 / 差別不在 (or `not .*, but`, `isn't .*, it's` in English) to verify. Rewrite each as a direct statement of the fact.
- **Parallelism/Tricolons**: never use
- **Rhetorical Questions**: max once per post, must not chain >2, concrete answer must follow
- **Em-dash** (—— in Chinese, — in English): never use. Zero instances allowed; grep the literal glyph to verify. Rewrite with a comma, a semicolon, or a standalone sentence instead.

### Punctuation Constraint

A mid-sentence colon splits one thought into a label and a payoff, which is the same staged-reveal rhythm as the devices above.

Avoid using colons in the middle of sentences: Use commas instead to revise them into smooth sentences. This does not apply to bulleted or listed items.

### Banned Phrases

These phrases are stock filler: they announce importance (「至關重要」), certainty (「很清楚」), or a reveal (「一個事實」) instead of demonstrating it. Delete the phrase and state the fact; if nothing is left, the sentence had nothing to say.

Never use the following expressions. When writing in another language, the ban extends to their direct equivalents (for example "in summary", "not only… but also…", "effectively", "often", "crucial", "meticulously crafted", "ensure", "reminds us", "it's not… it's…", "the key difference", "the core issue", "an uncomfortable truth", "systematically", "precisely", "only… can…", "honestly face", "very clear", "structural").

「總的來說」 「不只...更...」 「不僅...也...」 「...能有效...」 「往往」 「至關重要」 「精心打造」 「確保」 「直接講」 「先講」 「提醒我們」 「差別不在於...而在於...」 「一個...另一個」 「就像...」 「表面上...，...時，可能截然不同」 「這不是...是...」 「...問題也值得關注」 「一個事實」 「關鍵差異」 「最可怕的不是...」 「核心問題」 「不是...而是...」 「令人不安的事實」 「坐不住」 「系統性地」 「很精準」 「只有...才能...」 「誠實面對」 「不舒服」 「不太舒服」 「很清楚」 「講清楚」 「非常清楚」 「清晰」 「精準地」 「把這件事算得很死」 「認出了自己」 「結構性的」 「守得住」 「守不住」 「收在這裡」

### Additional Prohibitions

Hedges, staged pondering, mirror metaphors, and claims of discomfort perform an emotion or a thought process instead of reporting the result. Physical-action verbs on abstract objects create a vivid picture that misstates the actual mechanism.

- Avoid hedging phrases like 「可以說」「某種程度上」「在多數情況下」 ("arguably", "to some extent", "in most cases"); replace with conditional qualifications
- Avoid saying things like 「我想了很久」 「我停下來想了一下」 「停下來很久」 ("I thought about this for a long time", "I paused to think"), or "being dissected" / "reading an autopsy report."
- Avoid using 「鏡子」 ("mirror") or related concepts to describe feelings or things. Only use it when referring to an actual mirror.
- **Never use physical-action verbs with abstract objects.** Test: if the verb's everyday object is a concrete thing (hands, a tabletop, paper, food, feet) but the sentence's object is abstract, it violates this rule; rewrite with a verb that states the mechanism. Examples: 攤開缺口→列出缺口；接住錯誤→捕捉錯誤；抹平速度→速度算出接近 0；吃記憶體→佔用記憶體；塞進 JSON→寫進 JSON；餵給 block→傳給 block；踩過的坑→發生過的問題；假裝有→宣稱有。
- Avoid saying that this topic makes you feel uncomfortable, uneasy, or slightly offended, especially when discussing subjects such as cybersecurity, attacks, AI, ethics, philosophy, and psychology.
- Avoid using 「先講結論」 「先說清楚」 「先說背景」 「先說結論」 ("let me start with the conclusion", "first, some background") or similar phrases that indicate a "start with..." structured explanation.
- Utilize fewer metaphors and focus more on describing the facts.

## Alternative Patterns

When tempted to use restricted devices, use instead:

- **Direct Conclusion + Evidence**: State judgment first, then provide support
- **Conditional Sentence**: 「在 X 條件下，Y 成立；超出範圍不保證」 ("Under condition X, Y holds; beyond that scope it is not guaranteed")
- **Subheading + Short Paragraph**: 2-4 lines addressing one aspect
- **Definition-Scope-Example**: Define concept, specify scope, give one example

## Automatic Rewrite Rules

Apply these transformations when a restricted pattern appears:

- Contrastive Construction (any variant) → direct statement. e.g. 「這不是建議，是正確性要求」→「這是正確性要求」；「預測不是 X，而是 Y」→「預測直接以 Y 承載」
- Tricolon parallelism → consolidate into one prose paragraph
- Rhetorical question → declarative problem-and-answer format
- Em-dash → extract into independent sentence or conditional qualification

## Review Checklist

Before finalizing, run the linter on the draft. It catches the literal patterns (em-dash, contrastive constructions in zh-TW and English, banned phrases, hedging, 「先說…」 openers, staged pondering, first-person plural, mirror metaphors, mid-sentence colons, and the question-mark count) so the manual pass can focus on judgment:

```bash
# Path is relative to this skill's directory; call it by absolute path from the project.
<skill-dir>/scripts/lint.sh draft.md
some-command | <skill-dir>/scripts/lint.sh -
```

`ERROR` lines are hard-constraint violations; rewrite each one. `WARN` lines need a judgment call in context (a literal mirror, a quoted "we", a colon inside a label). Exit status 1 means at least one error remains. The script needs GNU grep with PCRE support; on macOS set `GREP=ggrep`. A clean run does not prove compliance: paraphrased banned phrases, tricolons, and metaphors are not machine-detectable.

Then verify every item:

1. Do consecutive paragraph openings use the same rhetorical device? Rewrite if yes.
2. Do any restricted devices exceed their quota? Retain only the most necessary instance.
3. Does each key claim have evidence? Downgrade unsupported claims to hypotheses.
4. Are there unsourced strong assertions? Rewrite to conditional qualifications.
5. Are sentences overlong? Split into short sentences with clear subject-verb-object structure.
6. For every verb, is its object concrete or abstract? A physical-action verb with an abstract object must be rewritten as a literal statement.
7. Does any paragraph pad one point into three parallel items, or lean on a metaphor where the fact would do? The linter cannot see these.
8. Did you also run the review checklist and linter of the language-specific skill (e.g. `chinese-content-writing-guideline`)?
