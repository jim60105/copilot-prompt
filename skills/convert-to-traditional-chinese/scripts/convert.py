#!/usr/bin/env python3
# Copyright (C) 2026 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
# ==================================================================
#
# Convert simplified Chinese to Traditional Chinese (zh-TW), and report every
# decision the script is not entitled to make on its own.
#
#     convert.py PATH...           convert in place, print the review report
#     convert.py --stdin           stdin -> stdout, report on stderr
#     convert.py --check PATH...   report only, write nothing
#     convert.py --diff PATH...    print a unified diff, write nothing
#
# Exit codes:
#     0  clean: nothing converted needs a second look (NAER advisories do not count)
#     1  review items only: every one defaulted to a form valid in zh-TW
#     2  must-fix items: simplified characters no substitution can resolve alone
#     3  usage error
#
# The script never guesses a context-dependent character. It converts what is
# deterministic, leaves the rest untouched, and reports it with the rule needed
# to decide. Resolving those reports is the caller's job.

from __future__ import annotations

import argparse
import bisect
import difflib
import json
import re
import sys
from pathlib import Path

EXIT_CLEAN = 0
EXIT_REVIEW = 1
EXIT_MUST_FIX = 2
EXIT_USAGE = 3

ASSETS = Path(__file__).resolve().parent.parent / "assets"

MARKDOWN_SUFFIXES = {".md", ".markdown", ".mdx"}
SKIP_DIRS = {".git", ".svn", ".hg", "node_modules", "__pycache__", ".venv", "venv", "dist", "build"}

FENCE_RE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")
INLINE_CODE_RE = re.compile(r"(`+)(?:.|\n)*?\1")
URL_RE = re.compile(r"(?:https?|ftp)://\S+|www\.[^\s<>\"]+")
LINK_TARGET_RE = re.compile(r"\]\([^)]*\)")
HTML_TAG_RE = re.compile(r"</?[A-Za-z][^>]*>")
REF_DEF_RE = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*\S+", re.MULTILINE)
INDENTED_CODE_RE = re.compile(r"(?:^(?: {4}|\t).*$\n?)+", re.MULTILINE)


def die(message: str) -> None:
    print(f"convert.py: {message}", file=sys.stderr)
    raise SystemExit(EXIT_USAGE)


class Tables:
    """The three data tables, indexed for a single left-to-right scan."""

    def __init__(self, assets: Path):
        char_map = self._load(assets / "char_map.json")
        ambiguous = self._load(assets / "ambiguous_chars.json")
        terms = self._load(assets / "term_map.json")
        # Advisory only, and optional: the skill works without it.
        naer = self._load_optional(assets / "naer_terms.json")

        self.chars: dict[str, str] = char_map["map"]

        # Entries already promoted to `safe` live in char_map; only the ones
        # still needing context belong in the runtime lookup.
        self.ambiguous: dict[str, dict] = {
            char: entry
            for char, entry in ambiguous["chars"].items()
            if entry.get("decision") in ("ambiguous", "todo")
        }

        self.terms_safe = {self.fold(k): v for k, v in terms.get("safe", {}).items()}
        self.terms_review = {self.fold(k): v for k, v in terms.get("review", {}).items()}
        self.max_term = max(
            [len(k) for k in self.terms_safe] + [len(k) for k in self.terms_review] + [0]
        )

        self.naer: dict[str, dict] = (naer or {}).get("terms", {})
        self.naer_attribution = (naer or {}).get("_meta", {}).get("attribution", "")
        self.max_naer = max([len(k) for k in self.naer] + [0])

    @staticmethod
    def _load_optional(path: Path):
        if not path.exists():
            return None
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"convert.py: ignoring unreadable {path}: {exc}", file=sys.stderr)
            return None

    @staticmethod
    def _load(path: Path):
        if not path.exists():
            die(f"missing data table {path}; run scripts/build_tables.py")
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            die(f"{path} is not valid JSON: {exc}")

    def fold(self, text: str) -> str:
        """Apply the deterministic character layer, preserving length and offsets.

        Vocabulary is matched against the folded form so one table entry covers every
        way the term can be written. Mainland vocabulary survives a naive character
        conversion -- a document can read 軟件 or 內存 while containing no simplified
        character at all -- and folding both sides catches those too.
        """
        return "".join(self.chars.get(c, c) for c in text)


def is_markdown(path: Path | None) -> bool:
    return path is not None and path.suffix.lower() in MARKDOWN_SUFFIXES


def fenced_spans(text: str) -> list[tuple[int, int]]:
    """Absolute offsets of fenced code blocks, including their fence lines."""
    spans: list[tuple[int, int]] = []
    offset = 0
    open_at: int | None = None
    open_fence = ""
    for line in text.splitlines(keepends=True):
        match = FENCE_RE.match(line)
        if open_at is None:
            if match:
                open_at, open_fence = offset, match.group(1)[0] * len(match.group(1))
        elif match and match.group(1)[0] == open_fence[0] and len(match.group(1)) >= len(open_fence):
            spans.append((open_at, offset + len(line)))
            open_at = None
        offset += len(line)
    if open_at is not None:  # unterminated fence: protect to end of file
        spans.append((open_at, len(text)))
    return spans


def protected_spans(text: str, markdown: bool) -> list[tuple[int, int]]:
    """Regions conversion must not touch. Merged and sorted."""
    spans = [(m.start(), m.end()) for m in URL_RE.finditer(text)]
    if markdown:
        fences = fenced_spans(text)
        spans += fences

        def outside(start: int) -> bool:
            return not any(a <= start < b for a, b in fences)

        for pattern in (INLINE_CODE_RE, LINK_TARGET_RE, HTML_TAG_RE, REF_DEF_RE, INDENTED_CODE_RE):
            spans += [(m.start(), m.end()) for m in pattern.finditer(text) if outside(m.start())]

    spans.sort()
    merged: list[tuple[int, int]] = []
    for start, end in spans:
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))
    return merged


class Finding:
    __slots__ = ("severity", "line", "col", "source", "candidates", "note", "context")

    def __init__(self, severity, line, col, source, candidates, note, context):
        self.severity = severity
        self.line = line
        self.col = col
        self.source = source
        self.candidates = candidates
        self.note = note
        self.context = context


def convert_text(text: str, tables: Tables, markdown: bool) -> tuple[str, list[Finding], int]:
    """Single left-to-right pass. Output is never rescanned, so rules cannot chain.

    Longest vocabulary match wins over single-character mapping, which is what
    keeps 文档 -> 文件 from being dragged on to 檔案 by the 文件 rule.
    """
    spans = protected_spans(text, markdown)
    span_starts = [s for s, _ in spans]
    # char_map is strictly one character to one character, so offsets line up.
    folded = tables.fold(text)
    line_starts = [0] + [m.end() for m in re.finditer(r"\n", text)]
    lines = text.split("\n")

    def position(index: int) -> tuple[int, int, str]:
        line = bisect.bisect_right(line_starts, index) - 1
        return line + 1, index - line_starts[line] + 1, lines[line].strip()

    out: list[str] = []
    findings: list[Finding] = []
    consumed: list[tuple[int, int]] = []
    converted = 0
    i, n = 0, len(text)

    while i < n:
        span_index = bisect.bisect_right(span_starts, i) - 1
        if span_index >= 0 and spans[span_index][0] <= i < spans[span_index][1]:
            start, end = spans[span_index]
            chunk = text[start:end]
            out.append(chunk)
            for offset, char in enumerate(chunk):
                if char in tables.chars or char in tables.ambiguous:
                    line, col, context = position(start + offset)
                    findings.append(Finding("protected", line, col, char, [], None, context))
            i = end
            continue

        limit = n
        if span_index + 1 < len(spans):
            limit = min(limit, spans[span_index + 1][0])

        matched = False
        for length in range(min(tables.max_term, limit - i), 1, -1):
            candidate = folded[i : i + length]
            entry = tables.terms_safe.get(candidate)
            if entry:
                out.append(entry["to"])
                converted += 1
                consumed.append((i, i + length))
                i += length
                matched = True
                break
            entry = tables.terms_review.get(candidate)
            if entry:
                out.append(text[i : i + length])
                line, col, context = position(i)
                findings.append(
                    Finding("review", line, col, candidate, entry["candidates"], entry.get("note"), context)
                )
                consumed.append((i, i + length))
                i += length
                matched = True
                break
        if matched:
            continue

        char = text[i]
        if char in tables.chars:
            out.append(tables.chars[char])
            converted += 1
        elif char in tables.ambiguous:
            entry = tables.ambiguous[char]
            candidates = entry["candidates"]
            note = entry.get("note")
            if entry.get("proper_noun_risk"):
                note = (note or "") + " [專有名詞風險：確認是否為人名或地名]"
            # A character absent from its own candidate list is not valid zh-TW
            # on its own, so leaving it as-is is not an acceptable outcome.
            severity = "review" if char in candidates else "must-fix"
            line, col, context = position(i)
            findings.append(Finding(severity, line, col, char, candidates, note, context))
            out.append(char)
        else:
            out.append(char)
        i += 1

    findings += scan_naer(text, folded, spans, consumed, tables, position)
    return "".join(out), findings, converted


def scan_naer(text, folded, spans, consumed, tables, position) -> list[Finding]:
    """Cite the official Taiwan rendering for terminology, without touching the text.

    這批資料記錄的是學術偏好譯名，不是對錯：除臭 並沒有錯，只是名詞審定取 去臭。所以一律只
    回報、不替換，由模型看著上下文決定。
    """
    if not tables.naer:
        return []
    blocked = sorted(spans + consumed)
    findings: list[Finding] = []
    i, n = 0, len(text)
    while i < n:
        skip = next((end for start, end in blocked if start <= i < end), None)
        if skip is not None:
            i = skip
            continue
        for length in range(min(tables.max_naer, n - i), 1, -1):
            entry = tables.naer.get(folded[i : i + length])
            if not entry:
                continue
            line, col, context = position(i)
            english = entry["en"]
            note = f"國教院審定：{english}" if english else "國教院審定名詞"
            if entry.get("domains"):
                note += "（" + "、".join(entry["domains"][:3]) + "）"
            findings.append(
                Finding("naer", line, col, text[i : i + length], entry["tw"], note, context)
            )
            i += length
            break
        else:
            i += 1
    return findings


SEVERITY_LABEL = {
    "must-fix": "MUST FIX  — 殘留簡體字，必須依語境選定",
    "review": "REVIEW    — 已套用預設寫法，請確認語境",
    "protected": "PROTECTED — 保護區內的簡體字，未轉換",
    "naer": "NAER      — 國教院兩岸對照名詞，僅供審查，未替換",
}


def report(label: str, findings: list[Finding], converted: int, stream=sys.stdout) -> None:
    if not findings and not converted:
        return
    def emit(line: str) -> None:
        print(line, file=stream)

    emit(f"=== {label} ===")
    emit(f"  {converted} 處已自動轉換")
    for severity in ("must-fix", "review", "protected", "naer"):
        group = [f for f in findings if f.severity == severity]
        if not group:
            continue
        emit(f"  {SEVERITY_LABEL[severity]} ({len(group)})")
        for finding in group:
            candidates = "｜".join(finding.candidates) if finding.candidates else "-"
            emit(f"    L{finding.line}:{finding.col}  {finding.source}  →  {candidates}")
            if finding.note:
                emit(f"           規則：{finding.note}")
            emit(f"           內文：{finding.context}")
    emit("")


def iter_files(paths: list[Path]):
    for path in paths:
        if path.is_dir():
            for child in sorted(path.rglob("*")):
                if child.is_file() and not any(part in SKIP_DIRS for part in child.parts):
                    yield child
        elif path.is_file():
            yield path
        else:
            die(f"{path} does not exist")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--stdin", action="store_true", help="read stdin, write result to stdout")
    parser.add_argument("--check", action="store_true", help="report only, write nothing")
    parser.add_argument("--diff", action="store_true", help="print a unified diff, write nothing")
    parser.add_argument("--markdown", action="store_true", help="force markdown rules on --stdin")
    parser.add_argument(
        "--include-code", action="store_true", help="convert protected regions too"
    )
    parser.add_argument("--no-naer", action="store_true", help="skip the NAER advisories")
    args = parser.parse_args()

    if args.stdin and args.paths:
        die("--stdin takes no paths")
    if not args.stdin and not args.paths:
        die("nothing to do; pass a path or --stdin")

    tables = Tables(ASSETS)
    if args.no_naer:
        tables.naer = {}
    all_findings: list[Finding] = []
    total_converted = 0
    files_touched = 0

    if args.stdin:
        text = sys.stdin.read()
        markdown = args.markdown and not args.include_code
        result, findings, converted = convert_text(text, tables, markdown)
        report("<stdin>", findings, converted, stream=sys.stderr)
        sys.stdout.write(result)
        sys.stdout.flush()
        all_findings, total_converted = findings, converted
    else:
        for path in iter_files(args.paths):
            try:
                text = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            markdown = is_markdown(path) and not args.include_code
            result, findings, converted = convert_text(text, tables, markdown)
            if not findings and not converted:
                continue
            files_touched += 1
            all_findings += findings
            total_converted += converted
            if args.diff:
                sys.stdout.writelines(
                    difflib.unified_diff(
                        text.splitlines(keepends=True),
                        result.splitlines(keepends=True),
                        fromfile=str(path),
                        tofile=f"{path} (converted)",
                    )
                )
            elif not args.check and result != text:
                path.write_text(result, encoding="utf-8")
            report(str(path), findings, converted)

    must_fix = sum(1 for f in all_findings if f.severity == "must-fix")
    review = sum(1 for f in all_findings if f.severity == "review")
    protected = sum(1 for f in all_findings if f.severity == "protected")
    advisory = sum(1 for f in all_findings if f.severity == "naer")
    scope = "<stdin>" if args.stdin else f"{files_touched} files"
    print(
        f"summary: {scope}, {total_converted} converted, {must_fix} must-fix, "
        f"{review} review, {protected} in protected regions, {advisory} NAER advisories",
        file=sys.stderr,
    )

    if must_fix:
        return EXIT_MUST_FIX
    if review or protected:
        return EXIT_REVIEW
    return EXIT_CLEAN


if __name__ == "__main__":
    sys.exit(main())
