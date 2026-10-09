---
name: chinese-content-writing-guideline
description: >-
  Language-specific guidelines for producing high-quality Traditional Chinese (zh-TW) content: script, full-width punctuation, spacing, forms of address, grammar constraints, and Taiwan terminology.
  Includes the no-calque rule against literal translations of English phrasal verbs such as 折入 for fold in.
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

## No Calques of English Phrases

Translating an English phrase word-for-word produces a Chinese coinage that no Taiwan reader uses: readers must decode the English source phrase to understand the word, and most such coinages are simply wrong. NEVER calque an English phrasal verb or idiom; translate the meaning with a natural Chinese verb.

- fold in ≠ 折入. Write 納入, 併入, or 融入 by context: 將使用者回饋納入計畫, not 將回饋折入計畫. In recipes, fold in = 拌入. In mathematics, fold (folding-based validation) = 摺疊. Note 折 ≠ fold in Traditional Chinese — folding paper is 摺 — so even the literal calque reads wrong.
- backfill ≠ 回填. Write 補填.
- align ≠ 拉齊. Write 對齊.
- empower ≠ 賦能. Write 賦權 or rephrase with 讓…能夠.
- land (a project) ≠ 落地. Write 成真, 執行落地 → 完成, 上路, or 實現.
- actionable ≠ 可行動的. Write 具體可行 or 可立即執行.
- leverage ≠ 槓桿化. Write 善用.
- deep dive ≠ 深潛. Write 深入研究 or 深入探討.
- touch base ≠ 碰基地. Write 聯繫.

When an English phrase has no standard Chinese term, translate the meaning in a short clause or keep the English term; NEVER coin a character-by-character translation.

## Review Checklist

Run the review checklist and linter of `writing-style-guideline` first. Then run this skill's linter:

```bash
# Path is relative to this skill's directory; call it by absolute path from the project.
<skill-dir>/scripts/lint.sh draft.md
some-command | <skill-dir>/scripts/lint.sh -
```

It reports 「您」, sentence-final 「的，」「的。」, missing CJK–alphanumeric spacing, half-width punctuation next to Chinese characters, and high-confidence calques such as 折入 as `ERROR`; reduplicated words, mainland terminology (with the Taiwan replacement in the rule name), ambiguous calques, and lowercase English terms that appear more than once as `WARN`. Code blocks, inline code, URLs, and link definitions are skipped. Legitimate reduplication such as 謝謝 and terms in other senses (對象 as a partner, 落地 as a physical landing, 回填 in earthworks) are expected warnings. The script needs GNU grep with PCRE support; on macOS set `GREP=ggrep`.

Then verify every item below:

1. Is all text in Traditional Chinese with full-width punctuation?
2. Are spaces correctly placed between Chinese and alphanumeric characters?
3. Does any clause end with 「的」 right before 「，」 or 「。」? Rewrite if yes.
4. Is there English term appears multiple times?
5. Are Taiwan terminology mappings applied?
6. Any calque of an English phrase, such as 折入? Check the No Calques table.

## Reference: Terminology Mappings

When writing content, apply these Traditional Chinese mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, invocation = 呼叫, code = 程式碼, running = 執行, library = 函式庫, schematics = 原理圖, building = 建構, Setting up = 設定, package = 套件, video = 影片, for loop = for 迴圈, class = 類別, Concurrency = 平行處理, Transaction = 交易, Transactional = 交易式, Code Snippet = 程式碼片段, Code Generation = 程式碼產生器, Any Class = 任意類別, Scalability = 延展性, Dependency Package = 相依套件, Dependency Injection = 相依性注入, Reserved Keywords = 保留字, Metadata =  Metadata, Clone = 複製, Memory = 記憶體, Built-in = 內建, Global = 全域, Compatibility = 相容性, Function = 函式, Refresh = 重新整理, document = 文件, example = 範例, demo = 展示, quality = 品質, tutorial = 指南, recipes = 秘訣, byte = 位元組, bit = 位元, context = 脈絡, tech stack = 技術堆疊, equation = 方程式, activate = 啟動、觸發, feedback = 回饋
