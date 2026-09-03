#!/usr/bin/env python3
# Copyright (C) 2026 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
# ==================================================================
#
# Regenerate the character tables in assets/ from the Unicode Unihan database.
#
# Maintenance-only. It needs network access (or a local Unihan.zip) and is never
# invoked by the conversion workflow -- convert.py only reads the JSON this
# writes, which is what keeps the shipped skill self-contained.
#
#     build_tables.py                          rebuild both tables (downloads Unihan)
#     build_tables.py --unihan-zip PATH        rebuild from a local archive
#     build_tables.py --list-todo              print entries still awaiting a decision
#     build_tables.py --list-todo --basic-cjk  ... limited to the basic CJK block
#     build_tables.py --lint-terms             check term_map.json for chain hazards
#     build_tables.py --naer                   rebuild assets/naer_terms.json from data.gov.tw
#     build_tables.py --naer --naer-rescan     re-discover the dataset list first
#
#     build_tables.py --list-auto              print machine-derived decisions
#
# Decisions recorded by a human (decision `safe` or `ambiguous`) are preserved
# verbatim across rebuilds. Entries left at `todo` are re-derived every time, and
# the ones the Big5 heuristic can settle become `auto` -- machine-derived, always
# overridable by editing the decision to `safe` or `ambiguous`.

from __future__ import annotations

import argparse
import collections
import csv
import hashlib
import json
import os
import re
import time
import sys
import zipfile
from pathlib import Path

EXIT_OK = 0
EXIT_FINDINGS = 1
EXIT_USAGE = 3

UNIHAN_URL = "https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip"
VARIANTS_MEMBER = "Unihan_Variants.txt"
UNIHAN_LICENSE = "Unicode-3.0"
UNIHAN_LICENSE_NAME = "UNICODE LICENSE V3 (https://www.unicode.org/license.txt)"
UNIHAN_NOTICE = "© 1991-2026 Unicode, Inc. All rights reserved."

ASSETS = Path(__file__).resolve().parent.parent / "assets"
CHAR_MAP = ASSETS / "char_map.json"
AMBIGUOUS = ASSETS / "ambiguous_chars.json"
TERM_MAP = ASSETS / "term_map.json"
NAER_TERMS = ASSETS / "naer_terms.json"

# 國家教育研究院 publishes its cross-strait terminology on data.gov.tw under the
# Open Government Data License v1 (`license: "1"`), which permits redistribution and
# derivative works provided the source agency is credited. The scan verifies that
# licence per dataset rather than trusting the URL.
NAER_API = "https://data.gov.tw/api/v2/rest/dataset/{}"
NAER_ID_RANGE = range(14800, 15520)
NAER_TITLE_MARKERS = ("國家教育研究院", "兩岸")
NAER_LICENCE = "1"
NAER_ATTRIBUTION = "資料來源：國家教育研究院，依政府資料開放授權條款第1版釋出。"

# Upstream is public infrastructure paid for by someone else. Keep concurrency low,
# back off instead of hammering, and never re-download what has not changed.
USER_AGENT = "chinese-traditional-conversion (skill build script)"
SCAN_WORKERS = 4
RETRY_BACKOFF = (2, 8)  # seconds before the 2nd and 3rd attempt
CACHE_DIR = (
    Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    / "chinese-traditional-conversion"
)

BASIC_CJK = ("一", "鿿")

# Characters the Big5 heuristic gets wrong, kept at `todo` for a human to judge.
#   涂  the surname stays 涂 in traditional text; only the verb becomes 塗
#   种  the surname 种 (Chong) stays 种; only the noun becomes 種
#   恶  噁心 uses 噁, which sits in the less-used Big5 zone and loses to 惡
AUTO_EXCLUDE = {"涂", "种", "恶"}

# Candidates Unihan offers that no one would ever write, kept out of the report so
# the reader is not asked to weigh a character the rule itself dismisses.
NOISE_CANDIDATES = {"只": {"戠"}}

# Traditional-to-traditional folding onto the form standardised in Taiwan. This
# layer also applies to text that is already traditional, which is intentional:
# a document written with 着 or 裏 is not zh-TW conformant.
TW_NORMALISE = {
    "着": "著", "裏": "裡", "爲": "為", "衆": "眾", "啓": "啟",
    "産": "產", "麽": "麼", "綫": "線", "幷": "並", "竝": "並",
    "嫺": "嫻", "卽": "即", "眞": "真", "靑": "青", "敎": "教",
    "揷": "插", "硏": "研", "塡": "填", "麪": "麵", "羣": "群",
    "槪": "概", "敍": "敘",
}


def big5_level(char: str) -> int:
    """0 if absent from Big5, 1 in the frequently-used zone, 2 in the less-used zone.

    Big5 is the de facto character set of Taiwan and its two zones encode exactly the
    judgement needed here. Whether a form is the orthodox Taiwanese one is otherwise a
    question no field in Unihan answers: 說 and 説 are both traditional, both listed,
    and only one is written in Taiwan. Zone 1 membership settles both that question
    and whether a character survives in modern use at all -- 從 is zone 1 while its
    archaic twin 从 is absent, which is why 从 can be resolved without human judgement.
    """
    try:
        encoded = char.encode("big5")
    except UnicodeEncodeError:
        return 0
    if len(encoded) != 2:
        return 0
    if 0xA4 <= encoded[0] <= 0xC6:
        return 1
    if 0xC9 <= encoded[0] <= 0xF9:
        return 2
    return 0


def auto_resolve(char: str, candidates: list[str]) -> str | None:
    """Settle an entry mechanically, or return None when context is genuinely needed.

    Two cases resolve without judgement. A character common in Taiwan (zone 1) is a
    legitimate outcome in its own right, so it always needs context. Otherwise the
    entry is settled exactly when one single candidate is in zone 1.
    """
    if char in AUTO_EXCLUDE or big5_level(char) == 1:
        return None
    common = [c for c in candidates if c != char and big5_level(c) == 1]
    return common[0] if len(common) == 1 else None


def die(message: str) -> None:
    print(f"build_tables.py: {message}", file=sys.stderr)
    raise SystemExit(EXIT_USAGE)


def fetch(url: str, timeout: int) -> tuple[bytes, bool]:
    """Fetch a URL through a revalidating disk cache. Returns (body, unchanged).

    Both upstreams send ETag and Last-Modified, so a rebuild that changes nothing
    costs a few hundred bytes of 304 responses instead of 15 MB of redundant
    transfer. Retries back off rather than hammering a host that is already
    struggling.
    """
    import urllib.error
    import urllib.request

    key = hashlib.sha256(url.encode("utf-8")).hexdigest()[:32]
    body_path, meta_path = CACHE_DIR / key, CACHE_DIR / f"{key}.json"
    validators = {}
    if body_path.exists() and meta_path.exists():
        try:
            validators = json.loads(meta_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            validators = {}

    headers = {"User-Agent": USER_AGENT}
    if validators.get("etag"):
        headers["If-None-Match"] = validators["etag"]
    if validators.get("last_modified"):
        headers["If-Modified-Since"] = validators["last_modified"]
    request = urllib.request.Request(_encode_url(url), headers=headers)

    last_error: Exception | None = None
    for attempt in range(3):
        if attempt:
            time.sleep(RETRY_BACKOFF[attempt - 1])
        try:
            with urllib.request.urlopen(request, timeout=timeout, context=_tls_context()) as r:
                data = r.read()
                CACHE_DIR.mkdir(parents=True, exist_ok=True)
                body_path.write_bytes(data)
                meta_path.write_text(
                    json.dumps(
                        {
                            "url": url,
                            "etag": r.headers.get("ETag"),
                            "last_modified": r.headers.get("Last-Modified"),
                        }
                    ),
                    encoding="utf-8",
                )
                return data, False
        except urllib.error.HTTPError as exc:
            if exc.code == 304 and body_path.exists():
                return body_path.read_bytes(), True
            if exc.code in (400, 401, 403, 404, 410):
                raise  # a permanent answer; retrying only adds load
            last_error = exc
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            last_error = exc
    raise last_error if last_error else OSError(f"could not fetch {url}")


def fetch_unihan(dest: Path) -> Path:
    """Download Unihan.zip next to the given path. Only used without --unihan-zip."""
    try:
        data, unchanged = fetch(UNIHAN_URL, timeout=120)
    except OSError as exc:
        die(f"cannot download Unihan.zip ({exc}); pass --unihan-zip PATH instead")
    print(
        f"Unihan.zip {'unchanged (served from cache)' if unchanged else 'downloaded'}",
        file=sys.stderr,
    )
    dest.write_bytes(data)
    return dest


def parse_variants(zip_path: Path):
    """Return (kTraditionalVariant, kSimplifiedVariant, unicode_version)."""
    try:
        with zipfile.ZipFile(zip_path) as archive:
            raw = archive.read(VARIANTS_MEMBER).decode("utf-8")
    except (OSError, KeyError, zipfile.BadZipFile) as exc:
        die(f"cannot read {VARIANTS_MEMBER} from {zip_path}: {exc}")

    version = ""
    traditional: dict[str, list[str]] = {}
    simplified: dict[str, list[str]] = {}
    for line in raw.splitlines():
        if not line or line.startswith("#"):
            match = re.match(r"#\s*Unicode Version\s+(\S+)", line)
            if match:
                version = match.group(1)
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        code, field, value = parts[0], parts[1], parts[2]
        if field not in ("kTraditionalVariant", "kSimplifiedVariant"):
            continue
        char = chr(int(code[2:], 16))
        # Values look like "U+9762 U+9EB5<kMatchedSource"; drop the annotation.
        targets = [chr(int(item.split("<")[0][2:], 16)) for item in value.split()]
        if field == "kTraditionalVariant":
            traditional[char] = targets
        else:
            simplified[char] = targets
    return traditional, simplified, version


def partition(traditional, simplified):
    """Split Unihan mappings into deterministic ones and context-dependent ones.

    A simplified character is deterministic when it has exactly one traditional
    counterpart AND is not itself valid in traditional text. Unihan marks the
    latter by listing the character as its own kSimplifiedVariant -- 面 is the
    canonical case: it maps to 麵 but is also a perfectly good traditional 面.
    """
    safe: dict[str, str] = {}
    ambiguous: dict[str, list[str]] = {}
    for char, targets in traditional.items():
        others = sorted(set(targets) - {char})
        if not others:
            continue
        self_valid = char in simplified.get(char, [])
        if len(others) == 1 and not self_valid:
            safe[char] = others[0]
        else:
            candidates = sorted(set(targets) | ({char} if self_valid else set()))
            ambiguous[char] = candidates
    return safe, ambiguous


def load_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die(f"{path} is not valid JSON: {exc}")


def merge_decisions(ambiguous: dict[str, list[str]], existing) -> dict[str, dict]:
    """Refresh candidates from Unihan, keep human calls, re-derive everything else."""
    previous = (existing or {}).get("chars", {})
    merged: dict[str, dict] = {}
    for char in sorted(ambiguous):
        # Unihan lists forms no one writes; Big5 membership drops most of them and
        # NOISE_CANDIDATES handles the few that slip through the encoding test.
        noise = NOISE_CANDIDATES.get(char, set())
        candidates = [
            c for c in ambiguous[char] if big5_level(c) and c not in noise
        ] or ambiguous[char]
        old = previous.get(char, {})
        if old.get("decision") in ("safe", "ambiguous"):
            entry = dict(old)
            entry["candidates"] = candidates
            if sorted(old.get("candidates", [])) != sorted(candidates):
                entry["candidates_changed_since_decision"] = True
            merged[char] = entry
            continue

        resolved = auto_resolve(char, candidates)
        merged[char] = {
            "candidates": candidates,
            "decision": "auto" if resolved else "todo",
            "resolved": resolved,
            "note": None,
            "proper_noun_risk": old.get("proper_noun_risk", False),
        }

    dropped = sorted(set(previous) - set(ambiguous))
    if dropped:
        print(
            f"warning: {len(dropped)} decided characters no longer ambiguous in Unihan: "
            + "".join(dropped),
            file=sys.stderr,
        )
    return merged


def build_char_map(safe: dict[str, str], decisions: dict[str, dict]) -> dict[str, str]:
    """Merge the Unihan layer, the promoted layer, and the Taiwan folding layer."""
    table = dict(safe)

    promoted = 0
    for char, entry in decisions.items():
        if entry.get("decision") not in ("safe", "auto"):
            continue
        resolved = entry.get("resolved")
        if not resolved:
            print(
                f"warning: {char} is marked {entry['decision']} but has no `resolved`; skipped",
                file=sys.stderr,
            )
            continue
        table[char] = resolved
        promoted += 1

    conflicts = [c for c in TW_NORMALISE if c in table and table[c] != TW_NORMALISE[c]]
    for char in conflicts:
        print(
            f"warning: {char} maps to {table[char]} but is folded to "
            f"{TW_NORMALISE[char]}; folding wins",
            file=sys.stderr,
        )

    # Compose: a simplified character whose traditional form is itself a
    # non-Taiwan variant must land on the Taiwan form in one step.
    for char, target in list(table.items()):
        if target in TW_NORMALISE:
            table[char] = TW_NORMALISE[target]
    table.update(TW_NORMALISE)

    # A character must never map to itself; that would be a silent no-op entry.
    table = {k: v for k, v in table.items() if k != v}
    print(
        f"char_map: {len(safe)} from Unihan + {promoted} resolved + "
        f"{len(TW_NORMALISE)} folded = {len(table)} entries",
        file=sys.stderr,
    )
    return dict(sorted(table.items()))


def write_tables(char_map: dict[str, str], decisions: dict[str, dict], version: str) -> None:
    meta = {
        "source": "Unicode Unihan_Variants.txt (kTraditionalVariant, kSimplifiedVariant)",
        "source_url": UNIHAN_URL,
        "unicode_version": version,
        "license": UNIHAN_LICENSE,
        "license_name": UNIHAN_LICENSE_NAME,
        "notice": UNIHAN_NOTICE,
        "generated_by": "scripts/build_tables.py",
    }
    CHAR_MAP.write_text(
        json.dumps({"_meta": meta, "map": char_map}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    AMBIGUOUS.write_text(
        json.dumps({"_meta": meta, "chars": decisions}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    tally = collections.Counter(e["decision"] for e in decisions.values())
    print(
        f"ambiguous_chars: {len(decisions)} entries — "
        + ", ".join(f"{count} {name}" for name, count in sorted(tally.items())),
        file=sys.stderr,
    )


def list_decisions(wanted: str, basic_cjk_only: bool) -> int:
    data = load_json(AMBIGUOUS)
    if data is None:
        die(f"{AMBIGUOUS} does not exist yet; run without a --list flag first")
    rows = [
        (char, entry)
        for char, entry in data["chars"].items()
        if entry["decision"] == wanted
        and (not basic_cjk_only or BASIC_CJK[0] <= char <= BASIC_CJK[1])
    ]
    for char, entry in rows:
        resolved = entry.get("resolved") or "-"
        print(f"{char}\t{''.join(entry['candidates'])}\t{resolved}")
    print(f"# {len(rows)} {wanted} entries", file=sys.stderr)
    return EXIT_FINDINGS if rows else EXIT_OK


def lint_terms() -> int:
    """Reject vocabulary entries that would chain if anyone replaced naively.

    convert.py scans once and never re-reads its own output, so chaining cannot
    happen at runtime. A chain still signals a real modelling error: 文档 -> 文件
    and 文件 -> 檔案 cannot both be unconditional, because the second rule
    contradicts the output of the first.
    """
    data = load_json(TERM_MAP)
    if data is None:
        die(f"{TERM_MAP} does not exist")
    safe = data.get("safe", {})
    findings = 0

    # convert.py folds a key through char_map before matching, so a key whose folded
    # form is an ordinary Taiwanese word hijacks that word: 覆盖 folds to 覆蓋 and
    # turned 測試覆蓋率 into 測試覆寫率. The NAER corpus doubles as a zh-TW lexicon
    # for detecting this; it is a proxy, not a dictionary, so it will not catch every
    # case (重載 is a real word absent from it).
    char_map = (load_json(CHAR_MAP) or {}).get("map", {})
    naer = (load_json(NAER_TERMS) or {}).get("terms", {})
    lexicon: set[str] = set()
    for entry in naer.values():
        lexicon.update(entry["tw"])
    for source in safe:
        folded = "".join(char_map.get(c, c) for c in source)
        if folded == source:
            continue
        if safe[source].get("hijack_reviewed"):
            continue  # a human weighed this one; the reason is recorded in the entry
        # A substring match is weak evidence on its own -- 鏈接 appears inside four
        # terms without being a word anyone writes. Being a rendering in its own
        # right, or a component of many, is what matters.
        containing = sum(1 for term in lexicon if folded in term)
        if folded in lexicon or containing >= 10:
            where = (
                "a Taiwan rendering"
                if folded in lexicon
                else f"a component of {containing} Taiwan terms"
            )
            print(f"error: {source} folds to {folded}, which is {where}; move it to `review`")
            findings += 1
    for source, entry in safe.items():
        target = entry["to"] if isinstance(entry, dict) else entry
        for other in safe:
            if other == source:
                continue
            if target == other:
                print(f"error: {source} -> {target}, but {other} is also a safe key")
                findings += 1
            elif other in target:
                print(f"warning: {source} -> {target} contains the safe key {other}")
                findings += 1
    overlap = set(safe) & set(data.get("review", {}))
    for term in sorted(overlap):
        print(f"error: {term} appears in both `safe` and `review`")
        findings += 1
    exempt = sum(1 for e in safe.values() if e.get("hijack_reviewed"))
    print(
        f"# {len(safe)} safe terms, {findings} findings, {exempt} hijack exemptions",
        file=sys.stderr,
    )
    return EXIT_FINDINGS if findings else EXIT_OK


# --------------------------------------------------------------------------
# 兩岸對照名詞 import (data.gov.tw / 國家教育研究院)
# --------------------------------------------------------------------------

CJK_ONLY = re.compile(r"^[㐀-鿿]+$")
POS_MARKER = re.compile(r"【[^】]*】")
GLOSS = re.compile(r"\([^)]*\)|（[^）]*）")
READING_SPLIT = re.compile(r"[；;、,]")
OPTIONAL_PART = re.compile(r"\[[^\]]*\]")


def _tls_context():
    """Verify the chain and the hostname, but not RFC 5280 structural strictness.

    opendata.naer.edu.tw serves a certificate without a Subject Key Identifier, which
    Python 3.13+ rejects under VERIFY_X509_STRICT. Clearing that one flag keeps full
    chain verification and hostname checking in place; it is not a blanket opt-out.
    """
    import ssl

    context = ssl.create_default_context()
    context.verify_flags &= ~ssl.VERIFY_X509_STRICT
    return context


def _encode_url(url: str) -> str:
    """data.gov.tw hands back URLs with raw CJK in the path; urllib needs ASCII."""
    from urllib.parse import quote, urlsplit, urlunsplit

    parts = urlsplit(url)
    return urlunsplit(parts._replace(path=quote(parts.path)))


def _fetch_json(url: str):
    import urllib.error
    import urllib.request

    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=20, context=_tls_context()) as response:
            return json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None



def discover_naer_datasets() -> list[dict]:
    """Find every cross-strait dataset and keep only the openly licensed ones.

    data.gov.tw exposes one dataset per id and no working search endpoint, so the
    range is scanned. Each hit is checked for licence "1" -- the Open Government
    Data License -- which is what makes redistributing the derived table lawful.
    """
    import concurrent.futures

    def probe(dataset_id: int):
        payload = _fetch_json(NAER_API.format(dataset_id))
        if not payload or not payload.get("success"):
            return None
        result = payload["result"]
        title = result.get("title", "")
        if not all(marker in title for marker in NAER_TITLE_MARKERS):
            return None
        if result.get("license") != NAER_LICENCE:
            print(f"warning: skipping {title}; licence is {result.get('license')!r}", file=sys.stderr)
            return None
        urls = [
            item.get("resourceDownloadUrl", "")
            for item in result.get("distribution", [])
            if item.get("resourceDownloadUrl", "").endswith(".csv")
        ]
        return {"id": dataset_id, "title": title, "urls": urls} if urls else None

    print(
        f"scanning {len(NAER_ID_RANGE)} dataset ids on data.gov.tw "
        f"at {SCAN_WORKERS} concurrent requests; the result is cached, so this "
        "should rarely need re-running",
        file=sys.stderr,
    )
    with concurrent.futures.ThreadPoolExecutor(max_workers=SCAN_WORKERS) as pool:
        found = [row for row in pool.map(probe, NAER_ID_RANGE) if row]
    print(f"found {len(found)} openly licensed cross-strait datasets", file=sys.stderr)
    return found


def _readings(value: str) -> list[str]:
    """Split one cell into its individual renderings, dropping editorial marks."""
    out = []
    for part in READING_SPLIT.split(GLOSS.sub("", POS_MARKER.sub("", value))):
        part = part.strip()
        if part:
            out.append(part)
    return out


def _mainland_variants(reading: str) -> set[str]:
    """`解压[缩]` records an optional character, so both readings are real."""
    return {reading, reading.replace("[", "").replace("]", ""), OPTIONAL_PART.sub("", reading)}


def build_naer_table(datasets: list[dict], char_map: dict[str, str], allow_partial: bool) -> dict:
    """Fold every mainland rendering onto its Taiwan counterpart, minus the traps.

    Two guards decide what is safe to surface. A mainland form that is itself a
    Taiwan rendering somewhere in the corpus is dropped outright -- 訪問 means
    `access` in computing and `visit` everywhere else, and no table can tell the
    two apart. What survives is still only ever reported, never substituted: this
    corpus records the preferred academic rendering, not a correction, and 除臭 is
    not wrong merely because a glossary prefers 去臭.
    """
    fold = lambda text: "".join(char_map.get(c, c) for c in text)
    pairs: dict[str, set[str]] = {}
    english: dict[str, str] = {}
    domains: dict[str, set[str]] = {}
    taiwan_forms: set[str] = set()
    failed: list[str] = []
    revalidated = 0
    transferred = 0
    rows = 0

    for dataset in datasets:
        domain = dataset["title"].split("-")[-1].replace("學術名詞", "").replace("名詞", "") or "通用"
        for url in dataset["urls"]:
            try:
                data, unchanged = fetch(url, timeout=90)
                text = data.decode("utf-8-sig")
            except (OSError, UnicodeDecodeError) as exc:
                print(f"error: cannot read {dataset['title']}: {exc}", file=sys.stderr)
                failed.append(dataset["title"])
                continue
            revalidated += unchanged
            transferred += 0 if unchanged else len(data)
            for row in csv.DictReader(text.splitlines()):
                rows += 1
                taiwan = [t for t in _readings(row.get("中文名稱", "")) if CJK_ONLY.match(t)]
                taiwan_forms.update(taiwan)
                if not taiwan:
                    continue
                for reading in _readings(row.get("中國大陸譯名", "")):
                    for variant in _mainland_variants(reading):
                        if len(variant) < 2 or not CJK_ONLY.match(variant):
                            continue
                        key = fold(variant)
                        targets = {t for t in taiwan if t != key}
                        if not targets:
                            continue
                        pairs.setdefault(key, set()).update(targets)
                        domains.setdefault(key, set()).add(domain)
                        english.setdefault(key, row.get("英文名稱", "").strip())

    dropped = [key for key in pairs if key in taiwan_forms]
    for key in dropped:
        del pairs[key]

    # A dataset that failed to download would silently shrink the table and rewrite
    # the whole 3 MB asset. Refuse rather than commit a quietly degraded build.
    if failed and not allow_partial:
        die(
            f"{len(failed)} dataset(s) could not be read: {', '.join(failed)}. "
            "Re-run, or pass --naer-allow-partial to accept an incomplete table."
        )

    terms = {
        key: {
            "tw": sorted(targets),
            "en": english.get(key, ""),
            "domains": sorted(domains[key]),
        }
        for key, targets in sorted(pairs.items())
    }
    print(
        f"naer_terms: {rows} rows -> {len(terms)} entries "
        f"({len(dropped)} dropped as also-Taiwanese)",
        file=sys.stderr,
    )
    print(
        f"upstream: {revalidated} file(s) unchanged, "
        f"{transferred // 1024} KB transferred",
        file=sys.stderr,
    )
    return {
        "_meta": {
            "source": "國家教育研究院 兩岸對照名詞 (data.gov.tw)",
            "license": "OGDL-Taiwan-1.0",
            "license_name": "政府資料開放授權條款-第1版 (https://data.gov.tw/license)",
            "attribution": NAER_ATTRIBUTION,
            "generated_by": "scripts/build_tables.py --naer",
            "usage": "Advisory only. convert.py reports these, never substitutes them.",
            "partial": bool(failed),
            "datasets": [
                {"id": d["id"], "title": d["title"], "urls": d["urls"]} for d in datasets
            ],
        },
        "terms": terms,
    }


def import_naer(rescan: bool, allow_partial: bool) -> int:
    existing = load_json(NAER_TERMS)
    datasets = None if rescan else (existing or {}).get("_meta", {}).get("datasets")
    if datasets:
        print(f"reusing {len(datasets)} known datasets; pass --naer-rescan to refresh", file=sys.stderr)
        datasets = [d for d in datasets if d.get("urls")]
        if not datasets:
            print("cached list has no URLs; rescanning", file=sys.stderr)
            datasets = discover_naer_datasets()
    else:
        datasets = discover_naer_datasets()
    if not datasets:
        die("no openly licensed cross-strait datasets found")

    char_map = load_json(CHAR_MAP)
    if not char_map:
        die(f"{CHAR_MAP} is missing; rebuild the character tables first")
    table = build_naer_table(datasets, char_map["map"], allow_partial)
    NAER_TERMS.write_text(
        json.dumps(table, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8"
    )
    print(f"wrote {NAER_TERMS} ({NAER_TERMS.stat().st_size // 1024} KB)", file=sys.stderr)
    return EXIT_OK


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--unihan-zip", type=Path, help="local Unihan.zip instead of downloading")
    parser.add_argument("--list-todo", action="store_true", help="print undecided entries and exit")
    parser.add_argument("--list-auto", action="store_true", help="print machine-derived entries")
    parser.add_argument("--basic-cjk", action="store_true", help="with a --list flag, basic CJK only")
    parser.add_argument("--lint-terms", action="store_true", help="check term_map.json and exit")
    parser.add_argument("--naer", action="store_true", help="rebuild assets/naer_terms.json")
    parser.add_argument("--naer-rescan", action="store_true", help="re-discover the dataset list")
    parser.add_argument(
        "--naer-allow-partial",
        action="store_true",
        help="write the table even if some datasets failed to download",
    )
    args = parser.parse_args()

    if args.lint_terms:
        return lint_terms()
    if args.naer or args.naer_rescan:
        return import_naer(args.naer_rescan, args.naer_allow_partial)
    if args.list_todo or args.list_auto:
        return list_decisions("todo" if args.list_todo else "auto", args.basic_cjk)

    if args.unihan_zip:
        if not args.unihan_zip.is_file():
            die(f"{args.unihan_zip} does not exist")
        zip_path = args.unihan_zip
    else:
        ASSETS.mkdir(parents=True, exist_ok=True)
        zip_path = fetch_unihan(ASSETS / ".Unihan.zip")

    traditional, simplified, version = parse_variants(zip_path)
    safe, ambiguous = partition(traditional, simplified)
    decisions = merge_decisions(ambiguous, load_json(AMBIGUOUS))
    write_tables(build_char_map(safe, decisions), decisions, version)

    if not args.unihan_zip and zip_path.exists():
        zip_path.unlink()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
