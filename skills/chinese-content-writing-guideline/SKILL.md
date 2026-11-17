---
name: chinese-content-writing-guideline
description: >-
  Language-specific guidelines for producing high-quality Traditional Chinese (zh-TW) content: script, full-width punctuation, spacing, forms of address, grammar constraints, and Taiwan terminology.
  Includes collocation checks for verb–object, verb–noun part of speech, and classifier–noun mismatches, and the no-calque rule against literal translations of English phrasal verbs such as 折入 for fold in.
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

## Collocation

A grammatical sentence can still pair words that never occur together in natural Chinese. The reader has to decode the phrase, and the result reads as translated. The subsections below check verb–object, verb–noun, and classifier–noun pairings separately.

### Verb and Object

The verb must name what actually happens to the object. Test: if the verb's everyday object is concrete (hands, paper, a tabletop, food, feet) but the sentence's object is abstract, the pairing is wrong. A verb that takes the wrong argument, or a clause whose noun phrase has no verb, fails the same test.

- 來去村子 → 進出村子（村子的動作是進出，不是來去）
- 架上從不鎖 → 架上從不上鎖（鎖需要對象，架上不是被鎖的東西）
- 發表會都在這裡 → 發表會都在這裡舉行（發表會是名詞，句子缺動詞）
- 板材都在這裡做 → 弓、箭在這裡做，木板在這裡備好（板材是材料，被做的是成品）
- 信按收件的地方分堆 → 信按寄往的地方分堆（分堆的依據是寄往，不是收件）
- 甜味留在木頭上 → 甜味滲進木頭裡（留在表面與滲進材料是兩件事）
- 攤開缺口 → 列出缺口
- 吃記憶體 → 佔用記憶體
- 塞進 JSON → 寫進 JSON
- 餵給 block → 傳給 block

The same test catches calques of English verb–object pairs. 打開一張工單 → 建立工單, 舉起一個問題 → 提出問題, 遞送價值 → 帶來價值.

### Verb and Noun

A noun in a verb slot, or a verb in a noun slot, makes the sentence claim an action that the chosen word cannot carry. Chinese verbs and nouns share many forms, so spell check passes; the near-homographs below are the common failures.

- 數據反應了延遲 → 數據反映了延遲（反映是動詞，反應是名詞）
- 這會障礙進度 → 這會阻礙進度（障礙是名詞，阻礙是動詞）
- 優先這個任務 → 優先處理這個任務
- 重點這個問題 → 聚焦這個問題
- 做一個確認 → 確認
- 全族的碰面處 → 族人碰面的地方

### Classifier and Noun

個 works as a fallback, but most nouns have their own classifier. Pair each noun with the dedicated one; using 個 for everything marks the text as translated.

| 名詞 | 量詞 | 例 |
| --- | --- | --- |
| 建議、功能、需求、風險 | 項 | 一項建議 |
| 系統、流程、工具、方案 | 套 | 一套系統 |
| 文件、報告、合約 | 份 | 一份報告 |
| 訊息、公告、指令 | 則 | 一則訊息 |
| 程式、手機 | 支 | 一支程式 |
| 產品、App | 款 | 一款 App |
| 汽車 | 輛 | 一輛汽車 |
| 會議、演講、比賽 | 場 | 一場會議 |
| 資料、紀錄、款項 | 筆 | 一筆資料 |
| 缺口 | 道 | 一道缺口 |
| 香草、花 | 束 | 一束香草 |
| 池、湖 | 座、池 | 一池淺水、幾座池子 |

一個 stays correct for nouns without a dedicated classifier, such as 錯誤, 問題, and 想法.

## Compression

AI-drafted Chinese deletes what the reader needs: the subject, the connective, and the concrete content of an event. The line stays grammatical and short, and the reader has to reconstruct the missing relation. A human writing the same fact unfolds it.

- Keep one subject per predicate chain. 「讓旅人有地方歇息、睡覺，也能安靜地練劍」 changes subject from the inn to the guest mid-clause.
- Unfold stacked modifiers：一個靠黑水潭淬火的鐵匠村 → 一座鐵匠村，村裡的鐵都用黑水潭的水淬火。
- Do not date a state change with an event adverbial：黑髮在一場火之後剪短 → 有回爐火燒到她的頭髮，索性剪短。
- Name the content instead of a placeholder（發生的事、各種、瑣事）：say what was observed, listed, or reported.
- Use the everyday verb, not the report noun：當熱源 → 借她的窯火加熱；一併零售 → 也擺在牆上一起賣。
- Commas do not state relations. Write the connective, or split the sentence, whenever two clauses are joined only by 「，」 and the reader must supply 因為、但、所以、之後。
- Every clause needs a predicate it can attach to. A bare adjective or noun between commas（句子短、熱心又務實）is a list item; it belongs only beside a clause that carries the verb.

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

It reports 「您」, sentence-final 「的，」「的。」, missing CJK–alphanumeric spacing, half-width punctuation next to Chinese characters, and high-confidence calques such as 折入 as `ERROR`; reduplicated words, mainland terminology (with the Taiwan replacement in the rule name), ambiguous calques, collocation mismatches such as 一條訊息 and 吃記憶體, and lowercase English terms that appear more than once as `WARN`. Code blocks, inline code, URLs, and link definitions are skipped. Legitimate reduplication such as 謝謝, terms in other senses (對象 as a partner, 落地 as a physical landing, 回填 in earthworks), and classifiers in other senses are expected warnings. The script needs GNU grep with PCRE support; on macOS set `GREP=ggrep`.

Then verify every item below:

1. Is all text in Traditional Chinese with full-width punctuation?
2. Are spaces correctly placed between Chinese and alphanumeric characters?
3. Does any clause end with 「的」 right before 「，」 or 「。」? Rewrite if yes.
4. Is there English term appears multiple times?
5. Are Taiwan terminology mappings applied?
6. Any calque of an English phrase, such as 折入? Check the No Calques table.
7. Does every verb fit its object, every noun sit in the right part of speech, and every classifier fit its noun? Check the Collocation section.
8. Does any line compress by dropping a subject, a connective, or the content of an event? Read it aloud and repair every place where you had to infer the relation.

## Reference: Terminology Mappings

When writing content, apply these Traditional Chinese mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, invocation = 呼叫, code = 程式碼, running = 執行, library = 函式庫, schematics = 原理圖, building = 建構, Setting up = 設定, package = 套件, video = 影片, for loop = for 迴圈, class = 類別, Concurrency = 平行處理, Transaction = 交易, Transactional = 交易式, Code Snippet = 程式碼片段, Code Generation = 程式碼產生器, Any Class = 任意類別, Scalability = 延展性, Dependency Package = 相依套件, Dependency Injection = 相依性注入, Reserved Keywords = 保留字, Metadata =  Metadata, Clone = 複製, Memory = 記憶體, Built-in = 內建, Global = 全域, Compatibility = 相容性, Function = 函式, Refresh = 重新整理, document = 文件, example = 範例, demo = 展示, quality = 品質, tutorial = 指南, recipes = 秘訣, byte = 位元組, bit = 位元, context = 脈絡, tech stack = 技術堆疊, equation = 方程式, activate = 啟動、觸發, feedback = 回饋
