#!/usr/bin/env python3
"""Standalone fantasy character-name roller over the bundled CC BY 4.0 corpus.

This is a dependency-free port of the MUD project's two-layer name generator
(``world/lore/names.py`` registry + ``world/rules/namegen.py`` rollers). The
project versions import Django/Evennia through their validation invariants;
this one imports nothing outside the standard library so the skill stays
copyable into any repository.

Behaviour deliberately kept identical to the project rollers:

- a display name is 「given.zh + SEPARATOR + surname.zh」, Chinese renderings
  only -- the original spelling never leaks into the player-visible string;
- ``sex`` maps female->f, male->m, other->u, and anything else (empty, None,
  unknown) picks a given pool at random rather than raising;
- an empty sex-filtered pool falls back to the pack's merged pool so the
  generator never dies on thin corpus data.

Every random decision goes through one ``random.Random`` instance so
``--seed`` reproduces a run exactly.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping, Sequence

# 「名‧姓」, U+2027 HYPHENATION POINT. The one composition constant.
NAME_SEPARATOR = "‧"

CORPUS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "corpus"

PACK_KEYS = (
    "fantasy-human",
    "fantasy-elf",
    "fantasy-dwarf",
    "fantasy-orc",
    "fantasy-halfling",
)

GIVEN_POOLS = ("m", "f", "u")

# Short aliases callers actually type -> pack key. ``beastfolk`` is the MUD
# project's playable race bound to the orc pack; it is kept so a prompt phrased
# in the project's own vocabulary still resolves.
RACE_ALIASES = {
    "human": "fantasy-human",
    "elf": "fantasy-elf",
    "dwarf": "fantasy-dwarf",
    "orc": "fantasy-orc",
    "half-orc": "fantasy-orc",
    "beastfolk": "fantasy-orc",
    "halfling": "fantasy-halfling",
    "hobbit": "fantasy-halfling",
}

# Accepted ``--sex`` spellings -> given-pool key. Anything absent here means
# "unspecified" and rolls a pool at random.
SEX_POOL = {
    "female": "f",
    "f": "f",
    "male": "m",
    "m": "m",
    "other": "u",
    "neutral": "u",
    "unisex": "u",
    "u": "u",
}

POOL_LABEL = {"m": "男性", "f": "女性", "u": "中性"}


class NameCorpusError(Exception):
    """The bundled corpus violates an invariant; the roller must not guess."""


@dataclass(frozen=True)
class NamePart:
    """One corpus component: original spelling, Chinese rendering, etymology."""

    text: str
    zh: str
    meaning_zh: str
    note_zh: str = ""


@dataclass(frozen=True)
class NamePack:
    """One race pack: its pools plus the lore that explains how it names."""

    key: str
    label: str
    surnames: tuple[NamePart, ...]
    given: Mapping[str, tuple[NamePart, ...]]
    naming_note_zh: str
    pack_note_zh: str


@dataclass(frozen=True)
class RolledName:
    """One rolled name, carrying the parts so callers can explain the choice."""

    pack_key: str
    pack_label: str
    pool_key: str
    given: NamePart
    surname: NamePart

    @property
    def display(self) -> str:
        return f"{self.given.zh}{NAME_SEPARATOR}{self.surname.zh}"

    @property
    def original(self) -> str:
        return f"{self.given.text} {self.surname.text}"


# ---------------------------------------------------------------------------
# Corpus loading
# ---------------------------------------------------------------------------


def _parse_parts(
    raw_parts: Sequence[Mapping[str, object]],
    source_field: str,
    translit: Mapping[str, str],
    pack_key: str,
) -> tuple[NamePart, ...]:
    parts = []
    for raw in raw_parts:
        text = str(raw[source_field])
        if text not in translit:
            raise NameCorpusError(
                f"pack {pack_key!r}: corpus word {text!r} has no translit entry"
            )
        parts.append(
            NamePart(
                text=text,
                zh=translit[text],
                meaning_zh=str(raw.get("meaning") or ""),
                note_zh=str(raw.get("note") or ""),
            )
        )
    return tuple(parts)


def load_registry(corpus_root: Path = CORPUS_ROOT) -> dict[str, NamePack]:
    """Parse and validate every bundled pack into a keyed registry.

    Validation is fail-fast rather than best-effort: a pack with a missing
    translit entry or an empty pool would otherwise ship a broken name straight
    into someone's character sheet, which is far harder to notice than a crash.
    """

    translit_path = corpus_root / "translit" / "fantasy.json"
    if not translit_path.is_file():
        raise NameCorpusError(
            f"corpus not found at {corpus_root} -- is assets/corpus/ intact?"
        )
    translit = json.loads(translit_path.read_text(encoding="utf-8"))

    registry: dict[str, NamePack] = {}
    for key in PACK_KEYS:
        payload = json.loads(
            (corpus_root / "packs" / f"{key}.json").read_text(encoding="utf-8")
        )
        if not payload.get("surnames"):
            raise NameCorpusError(f"pack {key!r} has no surnames")
        given_payload = payload["given"]
        if sorted(given_payload) != sorted(GIVEN_POOLS):
            raise NameCorpusError(
                f"pack {key!r} given pools must be exactly {list(GIVEN_POOLS)}, "
                f"got {sorted(given_payload)}"
            )
        for pool_key in GIVEN_POOLS:
            if not given_payload[pool_key]:
                raise NameCorpusError(f"pack {key!r} given pool {pool_key!r} is empty")
        registry[key] = NamePack(
            key=key,
            label=str(payload.get("label") or key),
            surnames=_parse_parts(payload["surnames"], "s", translit, key),
            given={
                pool_key: _parse_parts(given_payload[pool_key], "g", translit, key)
                for pool_key in GIVEN_POOLS
            },
            naming_note_zh=str(payload.get("rules", {}).get("naming", {}).get("note") or ""),
            pack_note_zh=str(payload.get("note") or ""),
        )
    return registry


# ---------------------------------------------------------------------------
# Rolling
# ---------------------------------------------------------------------------


def resolve_pack_key(race: str | None, rng: random.Random) -> str:
    """Map a race word to a pack key; None/``random`` picks one at random.

    An unknown non-empty race raises instead of silently falling back: a caller
    who typed ``--race elvf`` wants to hear about the typo, not receive human
    names that quietly contradict the character they described.
    """

    if race is None or race.strip().lower() in ("", "random", "any"):
        return rng.choice(PACK_KEYS)
    key = race.strip().lower()
    if key in RACE_ALIASES:
        return RACE_ALIASES[key]
    if key in PACK_KEYS:
        return key
    raise NameCorpusError(
        f"unknown race {race!r}; expected one of "
        + ", ".join(sorted(RACE_ALIASES)) + ", or 'random'"
    )


def resolve_pool_key(sex: str | None, rng: random.Random) -> str:
    """Map a sex word to a given pool; unknown/unspecified rolls a pool."""

    key = SEX_POOL.get(sex.strip().lower()) if isinstance(sex, str) else None
    return key if key is not None else rng.choice(GIVEN_POOLS)


def roll_one(pack: NamePack, sex: str | None, rng: random.Random) -> RolledName:
    """Roll a single name from one pack."""

    pool_key = resolve_pool_key(sex, rng)
    parts = pack.given[pool_key]
    if not parts:  # defensive: a thinned pack must degrade, not crash
        parts = tuple(part for pool in pack.given.values() for part in pool)
    return RolledName(
        pack_key=pack.key,
        pack_label=pack.label,
        pool_key=pool_key,
        given=rng.choice(parts),
        surname=rng.choice(pack.surnames),
    )


def roll_names(
    registry: Mapping[str, NamePack],
    race: str | None,
    sex: str | None,
    count: int,
    rng: random.Random,
    unique: bool = True,
) -> list[RolledName]:
    """Roll ``count`` names, re-rolling collisions when ``unique``.

    The race is resolved once per call rather than per name: asking for five
    names without naming a race means "five names for one unnamed character",
    not "one name each from five random races".
    """

    pack = registry[resolve_pack_key(race, rng)]
    rolled: list[RolledName] = []
    seen: set[str] = set()
    # Bounded retries: with a small pack and a large count, exhausting the
    # distinct combinations is possible, and looping forever is worse than
    # returning a few duplicates.
    attempts = 0
    budget = max(count * 20, 200)
    while len(rolled) < count and attempts < budget:
        attempts += 1
        candidate = roll_one(pack, sex, rng)
        if unique and candidate.display in seen:
            continue
        seen.add(candidate.display)
        rolled.append(candidate)
    while len(rolled) < count:  # collision budget spent; fill without the filter
        rolled.append(roll_one(pack, sex, rng))
    return rolled


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


def render_full(names: Sequence[RolledName], pack: NamePack) -> str:
    lines = [f"{pack.label}（{pack.key}）"]
    if pack.naming_note_zh:
        lines.append(f"命名慣例：{pack.naming_note_zh}")
    lines.append("")
    for index, name in enumerate(names, start=1):
        lines.append(
            f"{index}. {name.display}  ({name.original})"
            f"  〔{POOL_LABEL.get(name.pool_key, name.pool_key)}〕"
        )
        given_note = f" — {name.given.note_zh}" if name.given.note_zh else ""
        lines.append(f"   名：{name.given.text} — {name.given.meaning_zh}{given_note}")
        lines.append(f"   姓：{name.surname.text} — {name.surname.meaning_zh}")
    return "\n".join(lines)


def render_plain(names: Sequence[RolledName]) -> str:
    return "\n".join(name.display for name in names)


def render_json(names: Sequence[RolledName], pack: NamePack) -> str:
    payload = {
        "pack": {
            "key": pack.key,
            "label": pack.label,
            "naming_note_zh": pack.naming_note_zh,
        },
        "names": [
            {
                "display": name.display,
                "original": name.original,
                "pool": name.pool_key,
                "given": {
                    "text": name.given.text,
                    "zh": name.given.zh,
                    "meaning_zh": name.given.meaning_zh,
                    "note_zh": name.given.note_zh,
                },
                "surname": {
                    "text": name.surname.text,
                    "zh": name.surname.zh,
                    "meaning_zh": name.surname.meaning_zh,
                },
            }
            for name in names
        ],
    }
    return json.dumps(payload, ensure_ascii=False, indent=2)


def render_pack_list(registry: Mapping[str, NamePack]) -> str:
    alias_by_pack: dict[str, list[str]] = {}
    for alias, pack_key in RACE_ALIASES.items():
        alias_by_pack.setdefault(pack_key, []).append(alias)
    lines = []
    for key in PACK_KEYS:
        pack = registry[key]
        pools = "／".join(
            f"{POOL_LABEL[pool]} {len(pack.given[pool])}" for pool in GIVEN_POOLS
        )
        lines.append(f"{pack.label}（{key}）")
        lines.append(f"  --race 可用值：{', '.join(sorted(alias_by_pack.get(key, [])))}")
        lines.append(f"  語料：姓氏 {len(pack.surnames)}／給名 {pools}")
        if pack.naming_note_zh:
            lines.append(f"  命名慣例：{pack.naming_note_zh}")
        if pack.pack_note_zh:
            lines.append(f"  風格：{pack.pack_note_zh}")
        lines.append("")
    return "\n".join(lines).rstrip()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="namegen.py",
        description="Roll fantasy character names from the bundled CC BY 4.0 corpus.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "examples:\n"
            "  namegen.py --race elf --sex female -n 8\n"
            "  namegen.py --race dwarf -n 5 --format plain\n"
            "  namegen.py --race human --seed 1234 --format json\n"
            "  namegen.py --list-packs\n"
        ),
    )
    parser.add_argument(
        "-r",
        "--race",
        default=None,
        help="human / elf / dwarf / orc(beastfolk) / halfling, or 'random' (default: random)",
    )
    parser.add_argument(
        "-s",
        "--sex",
        default=None,
        help="female / male / neutral; omitted or unrecognised rolls a pool per name",
    )
    parser.add_argument("-n", "--count", type=int, default=5, help="how many names (default: 5)")
    parser.add_argument("--seed", default=None, help="seed for a reproducible run")
    parser.add_argument(
        "-f",
        "--format",
        choices=("full", "plain", "json"),
        default="full",
        help="full = names + spelling + etymology (default); plain = display names only",
    )
    parser.add_argument(
        "--allow-duplicates",
        action="store_true",
        help="keep repeated rolls instead of re-rolling collisions",
    )
    parser.add_argument(
        "--list-packs",
        action="store_true",
        help="print every pack with its pools and naming conventions, then exit",
    )
    parser.add_argument(
        "--corpus-root",
        type=Path,
        default=CORPUS_ROOT,
        help=argparse.SUPPRESS,
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(list(argv) if argv is not None else None)

    try:
        registry = load_registry(args.corpus_root)
    except (NameCorpusError, OSError, json.JSONDecodeError) as exc:
        print(f"corpus error: {exc}", file=sys.stderr)
        return 2

    if args.list_packs:
        print(render_pack_list(registry))
        return 0

    if args.count < 1:
        print("count must be at least 1", file=sys.stderr)
        return 2

    rng = random.Random(args.seed) if args.seed is not None else random.Random()

    try:
        names = roll_names(
            registry,
            args.race,
            args.sex,
            args.count,
            rng,
            unique=not args.allow_duplicates,
        )
    except NameCorpusError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    pack = registry[names[0].pack_key]
    if args.format == "plain":
        print(render_plain(names))
    elif args.format == "json":
        print(render_json(names, pack))
    else:
        print(render_full(names, pack))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
