---
name: chinese-content-writing-guideline
description: >-
  Language-specific guidelines for producing high-quality Traditional Chinese (zh-TW) content: script, full-width punctuation, spacing, forms of address, grammar constraints, and Taiwan terminology.
  Use when writing any kind of Chinese content. Including blog posts, notes, technical articles, technical writing, chitchat, social media posts, etc., even when you are just sending a text message.
  Also use when reviewing or editing existing Chinese content for language and terminology compliance.
  Always apply `writing-style-guideline` alongside this skill for structure, tone, rhetorical constraints, and banned phrases.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Chinese Content Writing Guidelines

This skill provides the language-specific rules for producing high-quality 正體中文 Traditional Chinese (zh-TW) content aligned with Taiwan conventions.

> **Prerequisite**: Always apply `writing-style-guideline` skill alongside this skill. That skill owns structure, tone, output principles, rhetorical device quotas, banned phrases, alternative patterns, and the general review checklist. This skill only covers what is specific to the Chinese language.

## Language and Formatting

Taiwan readers parse full-width punctuation, CJK–Latin spacing, and Taiwan terminology as native; half-width commas, cramped `使用Docker`, or mainland terms such as 代碼 and 函數 mark the text as converted or careless.

- Write in **Traditional Chinese 正體中文** (zh-TW) with full-width punctuation（，。、；：「」『』（）！？）
- Always insert a single space between Chinese characters and alphanumeric characters (e.g., `使用 Docker 建立`)
- Use standard Taiwan Traditional Chinese terminology for technical terms
- Address readers as 「讀者」「大家」「各位」 or 「你」, never 「您」
- Refer to the author as 「我」, never 「我們」

## Grammar Constraints

The 「是…的」 tail and reduplicated words soften a statement into speech-like filler; a plain declarative carries the same fact with less noise.

- **Sentence-final 的**: never end a clause with 「的」 immediately before 「，」 or 「。」 (the 「是…的」 emphatic tail). Rewrite as a plain declarative, drop the 的, or fold the 的-phrase into the clause so it no longer lands on the boundary.
- Avoid reduplicated words (疊字)

## English Terms

Switching between an English term and its translation makes readers wonder whether they are two different things; introducing the pairing once and then sticking to the Chinese keeps one name per concept.

When an English term appears multiple times, check for a common zh-TW translation or abbreviation. If found, present the original term with its Chinese equivalent the first time, then use only the Chinese version thereafter. This rule does not apply to proper nouns, including personal names.

## Review Checklist

Run the review checklist and linter of `writing-style-guideline` first. Then run this skill's linter:

```bash
# Path is relative to this skill's directory; call it by absolute path from the project.
<skill-dir>/scripts/lint.sh draft.md
some-command | <skill-dir>/scripts/lint.sh -
```

It reports 「您」, sentence-final 「的，」「的。」, missing CJK–alphanumeric spacing, half-width punctuation next to Chinese characters as `ERROR`; reduplicated words, mainland terminology (with the Taiwan replacement in the rule name), and lowercase English terms that appear more than once as `WARN`. Code blocks, inline code, URLs, and link definitions are skipped. Legitimate reduplication such as 謝謝 and terms in other senses (對象 as a partner) are expected warnings. The script needs GNU grep with PCRE support; on macOS set `GREP=ggrep`.

Then verify every item below:

1. Is all text in Traditional Chinese with full-width punctuation?
2. Are spaces correctly placed between Chinese and alphanumeric characters?
3. Does any clause end with 「的」 right before 「，」 or 「。」? Rewrite if yes.
4. Is there English term appears multiple times?
5. Are Taiwan terminology mappings applied?

## Reference: Terminology Mappings

When writing content, apply these Traditional Chinese mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, invocation = 呼叫, code = 程式碼, running = 執行, library = 函式庫, schematics = 原理圖, building = 建構, Setting up = 設定, package = 套件, video = 影片, for loop = for 迴圈, class = 類別, Concurrency = 平行處理, Transaction = 交易, Transactional = 交易式, Code Snippet = 程式碼片段, Code Generation = 程式碼產生器, Any Class = 任意類別, Scalability = 延展性, Dependency Package = 相依套件, Dependency Injection = 相依性注入, Reserved Keywords = 保留字, Metadata =  Metadata, Clone = 複製, Memory = 記憶體, Built-in = 內建, Global = 全域, Compatibility = 相容性, Function = 函式, Refresh = 重新整理, document = 文件, example = 範例, demo = 展示, quality = 品質, tutorial = 指南, recipes = 秘訣, byte = 位元組, bit = 位元, context = 脈絡, tech stack = 技術堆疊, equation = 方程式, activate = 啟動、觸發, feedback = 回饋
