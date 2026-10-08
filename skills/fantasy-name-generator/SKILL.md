---
name: fantasy-name-generator
description: Generate fantasy character names in zh-TW with original spelling and etymology, across human, elf, dwarf, orc/beastfolk, and halfling naming traditions. Use when the user needs a name for a character, NPC, party member, villain, shopkeeper, or monster, asks to think of, suggest, or rename such a character, names entities for a MUD/TRPG/game world or worldbuilding document, or writes lore, quests, presets, or seed data that require in-world personal names.
license: GFDL-1.3-or-later
compatibility: Requires Python 3.8 or newer. Standard library only, with no installed packages and no network access; the name corpus is bundled and must never be re-fetched.
allowed-tools: Bash(python3:*) Read
disable-model-invocation: true
metadata:
  author: Jim@ChenJ.im
  code-license: GPL-3.0-or-later
  code-license-covers: scripts/
  data-sources:
    - name: 角色姓名產生器 — 奇幻名字產生器
      license: CC-BY-4.0
      license-name: Creative Commons Attribution 4.0 International
      license-url: https://creativecommons.org/licenses/by/4.0/
      source-url: https://inknomu.com/namegen/fantasy
      creator-url: https://inknomu.com/
      retrieved: 2026-09-03
      covers: assets/corpus/
      notice: "語料、涵義標注和時代分包由弄墨 Inknomu 製作，依 CC BY 4.0 授權；引用請註明出處。上游 isBasedOn 來源清單見 assets/corpus/regions/fantasy.json。"
---

# Fantasy Name Generator

Roll character names from a curated corpus of 174 surnames and 1,100 given
names across five fantasy races. Every entry ships with its original spelling,
a zh-TW rendering, and an etymology note, so a chosen name can be *justified*
rather than merely produced.

This skill is self-contained: `scripts/namegen.py` is pure standard-library
Python and reads only `assets/corpus/`. Copy the whole directory anywhere and
it keeps working.

## Generate

```bash
python3 scripts/namegen.py --race elf --sex female -n 8
```

Paths are relative to this skill's directory — use the skill's absolute path
when your working directory is elsewhere.

Default output gives the display name, the original spelling, which pool it
came from, and the etymology of both halves:

```
奇幻‧精靈（fantasy-elf）
命名慣例：精靈壽命長、氏族觀念淡薄，正式場合常用「本名、家族／棲居地複合詞」…

1. 戴莉爾‧威爾德布瑞亞爾  (Daeliel Wildbriar)  〔女性〕
   名：Daeliel — 霞光＋…之女 — 詞根 Dael（霞光）接陰性後綴 -iel
   姓：Wildbriar — 野薔薇
```

### Options

| Flag | Values | Notes |
| --- | --- | --- |
| `-r`, `--race` | `human`, `elf`, `dwarf`, `orc` (`beastfolk`, `half-orc`), `halfling` (`hobbit`), `random` | Default `random`. Resolved **once per run**, so `-n 8` gives eight names for one character, not one name each from eight races. An unknown race is an error, never a silent fallback. |
| `-s`, `--sex` | `female`, `male`, `neutral` | Omit it and each name rolls its own pool — useful when the character's gender is still open. |
| `-n`, `--count` | integer | Default 5. Ask for more than you need; picking is the cheap part. |
| `--seed` | any string | Reproduces a run exactly. Use it when a name must be re-derivable later. |
| `-f`, `--format` | `full` (default), `plain`, `json` | `plain` is one display name per line; `json` carries every part and is what you want when feeding another script or writing data files. |
| `--allow-duplicates` | flag | Collisions are re-rolled by default. |
| `--list-packs` | flag | Prints each pack's pool sizes, naming conventions, and style notes. |

Run `--list-packs` first when you are unsure which race fits, or when you need
the in-world naming conventions to write surrounding lore consistently.

## Pick

Generating is one command; the value you add is the choice. Roll roughly three
times as many candidates as you need, then narrow using what you know about
the character:

**Match the etymology to the character, not just the sound.** The corpus
annotates what each part means. A stoic frontier guard reads better as
`寒水` (Coldwater, 冷冽水源的地景取姓) than as a name that merely sounds harsh.
When you present a name, say *why* it fits — that is the part a person cannot
get from the raw roller.

**Honour the pack's naming conventions.** They differ in kind, not just in
sound, and a name that ignores them reads as a worldbuilding mistake:

- **Human** — hereditary surnames; bastards take landscape surnames (Snow,
  Rivers, Stone) that mark them apart from trueborn siblings. If the character
  is a bastard, choose deliberately from those.
- **Elf** — no fixed hereditary surname; the second element is a
  clan-or-dwelling compound that can change with relocation or a coming-of-age
  rite. Useful when a character's backstory involves exile or migration.
- **Dwarf** — patronymic and clan name run in parallel; clan names carry
  forge/mining imagery passed down for craft lineage rather than blood title.
- **Orc / beastfolk** — the clan name is a tribal totem or war honour that must
  be *earned*. An unproven character should carry the given name alone; drop
  the surname rather than award it for free.
- **Halfling** — hereditary surnames reflecting family trade or an inherited
  physical or temperament nickname; neighbours tease each other with them.

**Read the `note` field when it appears.** Some given names carry a note that
they are gender-open, or that they derive from a particular morphological
pattern. That is exactly the detail that makes a name choice defensible.

**Watch the rendering, not only the spelling.** Only the human pack renders
surnames *semantically* (`Snow` → `雪原`, `Coldwater` → `寒水`), averaging just
2 characters. The other four packs transliterate phonetically and run around
5 characters, up to 8 (`Duskwalker` → `杜斯克瓦爾克爾`,
`Skullcrusher` → `斯庫爾克魯斯赫爾`). So an elf or orc display name is
routinely twice the length of a human one. If it has to fit somewhere narrow —
a UI label, a combat log line, a name field with a length cap — check the
rendered length before committing, and re-roll for a shorter surname rather
than truncating.

Present the shortlist with reasoning, then let the person choose. Offering a
single name without alternatives wastes the corpus's breadth.

## Inside the MUD project

This skill is an **authoring** tool: use it while writing lore, presets, quest
text, or seed data. The runtime path is separate and already exists —
`world/rules/namegen.py` rolls over `world/lore/names.py`, which parses the
same corpus from `third_party/fantasy-namegen/`. Never wire game code to this
skill's copy, and never edit one copy expecting the other to follow.

The project binds three playable races to packs: `human` → `fantasy-human`,
`elf` → `fantasy-elf`, `beastfolk` → `fantasy-orc`. `dwarf` and `halfling` are
registry-only spares with no playable race bound to them, so a name rolled
from either belongs to background lore, not a player character — unless the
person says otherwise.

## Attribution

The corpus is CC BY 4.0 by 弄墨 Inknomu
(<https://inknomu.com/namegen/fantasy>). Published or derived content must
credit the source; see `assets/corpus/THIRD_PARTY_NOTICES.md` for the full
notice and the upstream source list. Do not re-fetch the corpus in CI or
builds — it is a deliberate one-time static vendoring.
