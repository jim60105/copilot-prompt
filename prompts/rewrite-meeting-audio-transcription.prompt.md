---
mode: edit
model: Claude Sonnet 4
---
${input:meeting-audio-transcription-text-file} 是一個未經處理的轉錄會議錄音，其中有非常非常多的聽寫錯誤和轉錄辨識錯誤。我需要請你:

1. 完整閱讀整份轉錄檔
2. ultrathink what's correct and what's wrong
3. 產出一份新會議記錄
4. Review 新記錄，確認可以在轉錄檔中找到依據
5. 若是發現任何錯誤，修正這份會議記錄

我需要你完全基於 ${input:meeting-audio-transcription-text-file} ，不要產生任何你想像的建議和未來發展，會議記錄必須基於參考資料。會議記錄請保持一定程度由前到後的時序因果關聯。 Consider writing in paragraphs. Only use bullet point lists when necessary.

# Wording Instructions
When outputting any text, use the following translation mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, invocation = 呼叫, code = 程式碼, running = 執行, library = 函式庫, schematics = 原理圖, building = 建構, Setting up = 設定, package = 套件, video = 影片, for loop = for 迴圈, class = 類別, Concurrency = 平行處理, Transaction = 交易, Transactional = 交易式, Code Snippet = 程式碼片段, Code Generation = 程式碼產生器, Any Class = 任意類別, Scalability = 延展性, Dependency Package = 相依套件, Dependency Injection = 相依性注入, Reserved Keywords = 保留字, Metadata =  Metadata, Clone = 複製, Memory = 記憶體, Built-in = 內建, Global = 全域, Compatibility = 相容性, Function = 函式, Refresh = 重新整理, document = 文件, example = 範例, demo = 展示, quality = 品質, tutorial = 指南, recipes = 秘訣, byte = 位元組, bit = 位元

# Language Instructions
Write documentation in 正體中文 zh-tw unless the user asks you to use another language.
Always talk to user in 正體中文 zh-tw. Think of users as someone who can speak English but cannot read English.
Use full-width punctuation marks and always add a space between Chinese characters and alphanumeric characters.

Let's do this step by step.
