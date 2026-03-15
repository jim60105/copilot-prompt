---
name: chinese-content-writing-guideline
description: >-
  Writing guidelines for producing high-quality Traditional Chinese (zh-TW) content
  following Taiwan conventions. Use when writing blog posts, notes, technical articles,
  technical writing, or any task producing content with 正體中文. Also use when reviewing
  or editing existing Chinese content for tone, style, and terminology compliance.
---

# Chinese Content Writing Guidelines

This skill provides comprehensive writing guidelines for producing high-quality 正體中文 Traditional Chinese (zh-TW) content. Apply these rules to ensure consistent language, structure, tone, and terminology aligned with Taiwan conventions.

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
- Use markdown reference-style links for external sources only, not for internal links. Each reference link should appear only once in the article.
- Format all reference-style links using markdown so they display as "links." Use the webpage title (curl fetch it!) as the link text for each reference-style link.

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

### Rhetorical Device Quotas

- **Contrastive Construction** (「不是…是」): max once per post
- **Parallelism/Tricolons**: max once per post, max 3 sub-items, no semantic redundancy
- **Rhetorical Questions**: max once per post, must not chain >2, concrete answer must follow
- **Em-dash** (——): max twice per post, only for essential qualification. Never use it twice per section. Must not be used to stack adjectives or emotional content.

### Punctuation Constraint

Avoid using colons in the middle of sentences: Use commas instead to revise them into smooth sentences. This does not apply to bulleted or listed items.

### Banned Phrases

Never use the following expressions:

「總的來說」 「不只...更...」 「不僅...也...」 「...能有效...」 「往往」 「至關重要」 「精心打造」 「確保」 「直接講」 「先講」 「提醒我們」 「差別不在於...而在於...」 「一個...另一個」 「就像...」 「表面上...，...時，可能截然不同」 「這不是...是...」 「...問題也值得關注」 「一個事實」 「關鍵差異」 「最可怕的不是...」 「核心問題」 「不是...而是...」 「令人不安的事實」 「坐不住」 「系統性地」 「很精準」 「只有...才能...」 「誠實面對」 「不舒服」 「不太舒服」 「很清楚」 「講清楚」 「非常清楚」 「清晰」 「精準地」

### Additional Prohibitions

- Avoid reduplicated words
- Avoid hedging phrases like 「可以說」「某種程度上」「在多數情況下」; replace with conditional qualifications
- Avoid using "mirror" to describe feelings or things.
- Avoid saying that this topic makes you feel uncomfortable, uneasy, or slightly offended, especially when discussing subjects such as cybersecurity, attacks, AI, ethics, philosophy, and psychology.
- Utilize fewer metaphors and focus more on describing the facts.

## Alternative Patterns

When tempted to use restricted devices, use instead:

- **Direct Conclusion + Evidence**: State judgment first, then provide support
- **Conditional Sentence**: 「在 X 條件下，Y 成立；超出範圍不保證」
- **Subheading + Short Paragraph**: 2-4 lines addressing one aspect
- **Definition-Scope-Example**: Define concept, specify scope, give one example

## Automatic Rewrite Rules

Apply these transformations when a restricted pattern appears:

- 「不是…是」 → 「核心重點在於…；次要面向為…」
- Tricolon parallelism with redundant items → consolidate into one prose paragraph
- Rhetorical question → declarative problem-and-answer format
- Consecutive em-dashes → extract into independent sentence or conditional qualification
- When an English term appears multiple times, check for a common zh-TW translation or abbreviation. If found, present the original term with its Chinese equivalent the first time, then use only the Chinese version thereafter. This rule does not apply to proper nouns, including personal names.

## Review Checklist

Before finalizing, verify every item:

1. Do consecutive paragraph openings use the same rhetorical device? Rewrite if yes.
2. Do any restricted devices exceed their quota? Retain only the most necessary instance.
3. Does each key claim have evidence? Downgrade unsupported claims to hypotheses.
4. Are there unsourced strong assertions? Rewrite to conditional qualifications.
5. Are sentences overlong? Split into short sentences with clear subject-verb-object structure.
6. Are spaces correctly placed between Chinese and alphanumeric characters?
7. Is there English term appears multiple times?

## Reference: Terminology Mappings

When writing content, apply these Traditional Chinese mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, invocation = 呼叫, code = 程式碼, running = 執行, library = 函式庫, schematics = 原理圖, building = 建構, Setting up = 設定, package = 套件, video = 影片, for loop = for 迴圈, class = 類別, Concurrency = 平行處理, Transaction = 交易, Transactional = 交易式, Code Snippet = 程式碼片段, Code Generation = 程式碼產生器, Any Class = 任意類別, Scalability = 延展性, Dependency Package = 相依套件, Dependency Injection = 相依性注入, Reserved Keywords = 保留字, Metadata =  Metadata, Clone = 複製, Memory = 記憶體, Built-in = 內建, Global = 全域, Compatibility = 相容性, Function = 函式, Refresh = 重新整理, document = 文件, example = 範例, demo = 展示, quality = 品質, tutorial = 指南, recipes = 秘訣, byte = 位元組, bit = 位元, context = 脈絡, tech stack = 技術堆疊, equation = 方程式, activate = 啟動、觸發, feedback = 回饋
