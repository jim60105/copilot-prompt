---
name: convert-to-traditional-chinese
description: Convert simplified Chinese to Traditional Chinese (zh-TW), covering characters, Taiwan vocabulary, and phrasing. Use when the user asks to convert 簡體 to 正體/繁體, localise mainland Chinese text for Taiwan, fix simplified characters left in a document or repository, check whether content is written in proper zh-TW, or normalise variant forms such as 着/裏/爲 to the Taiwan standard. Handles both files edited in place and text pasted into the conversation. Runs on Python 3 standard library alone, with no OpenCC and no installed packages.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Convert to Traditional Chinese

Convert simplified Chinese into Traditional Chinese as written in Taiwan. The script settles
what is deterministic and reports what is not; deciding the reported items is your job.

**Never let the script guess and never guess yourself.** A character like `发` is `發` or `髮`
depending on the sentence around it. Tools that pick one silently are why this skill exists.

## Division of labour

`scripts/convert.py` owns the mechanical half: 6300+ deterministic character mappings, Taiwan
variant folding (`着`→`著`, `裏`→`裡`, `爲`→`為`), unambiguous vocabulary, and exhaustive
detection. It is exhaustive where you are not — it will not miss the one stray `发` on line 400.

You own the contextual half: every ambiguous character, every vocabulary item with more than one
Taiwan reading, and the phrasing that no dictionary encodes. You have the whole document; the
script has a table.

## Workflow

### 1. Establish the input

Files or directories go through the path form. Text pasted into the conversation goes through
`--stdin`. Convert files in place so the user reviews a `git diff`; never paste a converted copy
of a file back into the chat.

### 2. Run the mechanical pass

```bash
scripts/convert.py PATH...          # convert in place, print the review report
scripts/convert.py --check PATH...  # report only, write nothing
scripts/convert.py --diff PATH...   # unified diff, write nothing
echo "文字" | scripts/convert.py --stdin   # result on stdout, report on stderr
```

Add `--markdown` to apply markdown protection rules to `--stdin` input. Add `--include-code` to
convert protected regions too, which is almost never right.

Add `--no-naer` to suppress the terminology advisories described below.

Exit codes: `0` clean, `1` review items only, `2` must-fix items present, `3` usage error.
NAER advisories never change the exit code.
The script checks its own prerequisites and explains failures on stderr, so do not pre-verify
anything.

### 3. Resolve the report

Three sections, three different obligations.

**MUST FIX** — a simplified character no substitution resolves on its own. The document is not
zh-TW until every one is decided. Read the rule the report prints, look at the sentence, edit
the file.

**REVIEW** — the script applied a form that is valid zh-TW, which may still be the wrong one
here. `面` stays `面` unless it is `麵條`. Confirm or correct each one.

**PROTECTED** — simplified text inside code blocks, inline code, or URLs. Left untouched on
purpose. A simplified string literal is often deliberate. Change these only when the user asks.

**NAER** — 國家教育研究院 has ruled on this term and its Taiwan rendering differs from what the
text uses. The advisory prints the official rendering, the English headword, and the subject
domain. Nothing was substituted, and nothing has to be: this corpus records the *preferred*
academic rendering, not a correction. 除臭 is not wrong because a glossary prefers 去臭. Apply
one when the domain matches the document and the rendering is clearly better — `服务器` really
should be `伺服器`, `纳米` really should be `奈米` — and ignore it otherwise.

An entry with no rule printed is one the character table has not been curated for yet. Decide it
from context as usual, and prefer the form used elsewhere in the same document.

**樂詞網 settles what the report cannot.** For a terminology question the tables do not answer,
query <https://terms.naer.edu.tw/search/?q=TERM> with WebFetch — it is the authority for Taiwan
academic and technical vocabulary. It is HTML with no API, so read the page rather than
expecting JSON. It does not rule on character-level ambiguity: whether `发` is `發` or `髮` is a
question for 教育部《重編國語辭典修訂本》, not for a terminology database.

### 4. Localise the phrasing

Character and vocabulary conversion produces correct but foreign-sounding Chinese. Read
`references/taiwan-vocabulary.md` and apply the sentence-level adjustments: `通过` as a
preposition becomes `透過` or `藉由`, `对…进行…` constructions unwind into direct verbs.

### 5. Verify

Re-run `--check`. Zero must-fix items is the gate. Review items may legitimately remain when you
have consciously judged each one, so exit `1` is an acceptable end state and exit `2` is not.

### 6. Report to the user

Say what was converted, which items you judged and why, and what you deliberately left alone.
Name any proper noun you were unsure about.

## Rules

- **Conversion is not rewriting.** Preserve the author's voice, structure, and argument. Do not
  apply writing-style guidance. When the user wants the prose improved as well, that is
  `chinese-content-writing-guideline`, invoked separately and said out loud.
- **Proper nouns are reported, never converted.** `沈` is the surname 沈 or the city 瀋陽; `姜`
  is the surname 姜 or the spice 薑. The report flags these with a proper-noun warning. If the
  text does not settle it, ask the user.
- **Code, URLs, filenames, and identifiers stay simplified.** Converting a dictionary key or a
  path breaks the program.
- **Quoted material gets characters only.** Statutes, judgments, and other people's words take
  the character conversion and nothing else. Tell the user you limited it.
- **Every decision needs a reason you can state.** If you cannot state one, leave it and flag it
  for the user rather than guessing.

## Data tables

`assets/` holds three tables the script reads. They are data, not reading material — do not load
them into context.

| File | Contents |
| --- | --- |
| `char_map.json` | Deterministic character mappings, derived from Unihan plus the Taiwan folding layer |
| `ambiguous_chars.json` | Characters needing context, with the rule for each |
| `term_map.json` | Mainland-to-Taiwan vocabulary, split into unconditional and context-dependent |
| `naer_terms.json` | 29k 兩岸對照名詞 from 國家教育研究院. Advisory only — reported, never substituted |

`scripts/build_tables.py` regenerates the character tables from the Unicode Unihan database. It
is maintenance tooling, needs network access, and is never part of a conversion. Run it only to
refresh the tables against a new Unicode release; it preserves every human decision already
recorded. `--lint-terms` checks `term_map.json` for entries that contradict each other.

`--naer` rebuilds `naer_terms.json` from 國家教育研究院's cross-strait terminology on
data.gov.tw. It verifies each dataset carries licence `1` (政府資料開放授權條款第1版) before
using it, and drops any mainland form that is also a Taiwan rendering elsewhere in the corpus,
because no table can tell `訪問` the noun from `訪問` the verb. Add `--naer-rescan` to
re-discover the dataset list. A download that fails aborts the rebuild and leaves the existing
table in place, so a flaky connection cannot quietly ship a shrunken one; `--naer-allow-partial`
overrides that and records `partial: true` in the file.

資料來源：國家教育研究院，依政府資料開放授權條款第1版釋出。
