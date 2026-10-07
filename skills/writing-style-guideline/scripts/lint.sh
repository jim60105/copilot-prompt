#!/usr/bin/env bash
# Copyright (C) 2026 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==================================================================
#
# Lint prose against the mechanically checkable rules of the
# writing-style-guideline skill. Works on any language; zh-TW and
# English patterns are both checked.
#
# Usage: lint.sh FILE...
#        lint.sh -          (read from stdin)
#
# Fenced code blocks, inline code, and markdown link definitions are
# ignored. Each finding prints as `file:line: LEVEL [rule] matched-text`.
#   ERROR - violates a hard constraint; rewrite it
#   WARN  - likely violation; judge in context
#
# Exit status: 0 = no ERROR, 1 = at least one ERROR, 2 = usage/dependency error.
#
# Environment: GREP overrides the grep binary (needs PCRE support, e.g.
# GREP=ggrep on macOS with Homebrew GNU grep).

set -uo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; RESET='\033[0m'
[[ -t 1 ]] || { RED=''; YELLOW=''; GRAY=''; RESET=''; }

GREP="${GREP:-grep}"
export LC_ALL=C.UTF-8

ERRORS=0
WARNINGS=0
FINDINGS=''
STDIN_TMP=''

# ------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------

die() {
    echo -e "${RED}ERROR: $*${RESET}" >&2
    exit 2
}

usage() {
    sed -n '/^# Usage:/,/^# Exit status/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
}

check_dependencies() {
    command -v "$GREP" >/dev/null 2>&1 || die "$GREP is required but not installed"
    command -v awk >/dev/null 2>&1 || die "awk is required but not installed"
    echo 'é' | "$GREP" -qP '\p{L}' 2>/dev/null \
        || die "$GREP lacks PCRE (-P) support; install GNU grep and set GREP=ggrep"
}

# Blank out fenced code blocks, inline code, and link definitions while
# keeping line numbers intact.
strip_code() {
    awk '
        /^[[:space:]]*(```|~~~)/ { in_fence = !in_fence; print ""; next }
        in_fence { print ""; next }
        /^[[:space:]]*\[[^]]+\]:[[:space:]]/ { print ""; next }
        { gsub(/`[^`]*`/, ""); print }
    ' "$1"
}

# report LEVEL RULE LABEL FILE PCRE
report() {
    local level="$1" rule="$2" label="$3" file="$4" pattern="$5"
    local color line text
    [[ "$level" == ERROR ]] && color="$RED" || color="$YELLOW"
    while IFS=: read -r line text; do
        [[ -z "$line" ]] && continue
        FINDINGS+="${label}:${line}: ${color}${level}${RESET} [${rule}] ${GRAY}${text}${RESET}"$'\n'
        if [[ "$level" == ERROR ]]; then
            ERRORS=$((ERRORS + 1))
        else
            WARNINGS=$((WARNINGS + 1))
        fi
    done < <("$GREP" -noP -- "$pattern" "$file")
}

# ------------------------------------------------------------------
# Content processing functions
# ------------------------------------------------------------------

# Banned zh-TW phrases from the skill, as PCRE. `...` in the skill
# becomes a bounded gap so the two halves must sit in one clause.
# Contrastive phrases (不是…而是, 這不是…是, 差別不在於…而在於) are
# checked by the contrastive rule instead, to avoid double reports.
BANNED_ZH=(
    '總的來說' '不只.{0,30}?更' '不僅.{0,30}?也' '能有效' '往往' '至關重要'
    '精心打造' '確保' '直接講' '先講' '提醒我們'
    '一個.{0,20}?另一個' '就像' '表面上.{0,40}?截然不同'
    '問題也值得關注' '一個事實' '關鍵差異' '最可怕的不是' '核心問題'
    '令人不安的事實' '坐不住' '系統性地' '很精準'
    '只有.{0,30}?才能' '誠實面對' '不太舒服' '不舒服' '很清楚' '講清楚'
    '非常清楚' '清晰' '精準地' '把這件事算得很死' '認出了自己' '結構性的'
    '守得住' '守不住' '收在這裡'
)

# Direct English equivalents listed in the skill.
BANNED_EN=(
    'in summary' 'not only\b.{0,60}?\bbut also' 'meticulously crafted'
    'crucial' 'ensures?\b' 'reminds us' 'the key difference' 'the core issue'
    'an uncomfortable truth' 'systematically' 'precisely' 'honestly face'
    'very clear'
)

lint_file() {
    local label="$1" src="$2"
    local work
    work=$(mktemp) || die "cannot create temp file"
    strip_code "$src" > "$work"

    # Em-dash in any language.
    report ERROR em-dash "$label" "$work" '—+'

    # Contrastive construction.
    report ERROR contrastive "$label" "$work" '不是[^。！？\n]{0,40}?而是|這不是[^。！？\n]{0,40}?是|差別不在'
    report ERROR contrastive "$label" "$work" "(?i)\b(it|this|that)(?:'s| is) not\b[^.!?\n]{0,60}?[,;]\s*(it|this|that)(?:'s| is)\b|(?i)\bisn't\b[^.!?\n]{0,60}?[,;]\s*it's\b|(?i)\bnot\b[^.!?\n]{1,60}?,\s*but\b"

    # Banned phrases.
    local p
    for p in "${BANNED_ZH[@]}"; do
        report ERROR banned-phrase "$label" "$work" "$p"
    done
    for p in "${BANNED_EN[@]}"; do
        report ERROR banned-phrase "$label" "$work" "(?i)\\b$p"
    done

    # Hedging.
    report ERROR hedging "$label" "$work" '可以說|某種程度上|在多數情況下|(?i)\b(arguably|to some extent|in most cases)\b'

    # "Start with the conclusion" style openers (先講… is a banned phrase).
    report ERROR start-with "$label" "$work" '先說清楚|先說背景|先說結論|(?i)\blet me start with\b|(?i)\bfirst, some background\b'

    # Pondering narration.
    report ERROR pondering "$label" "$work" '我想了很久|停下來想了一下|停下來很久|(?i)\bI (?:thought about this|paused to think)\b|(?i)\bautopsy report\b|(?i)\bbeing dissected\b'

    # Voice: first-person plural for the author.
    report ERROR voice-we "$label" "$work" '我們'
    report WARN voice-we "$label" "$work" "\\b(?:[Ww]e|[Oo]ur|[Uu]s|[Ww]e're|[Ww]e've)\\b"

    # Mirror metaphors (allowed only for a literal mirror).
    report WARN mirror "$label" "$work" '鏡子|(?i)\bmirrors?\b'

    # Mid-sentence colon. List items, headings, and table rows are exempt.
    report WARN mid-colon "$label" "$work" '^(?!\s*(?:[-*+]|\d+[.)]|#|\|)).*?\K\S{0,12}(?:：|:\s)\S{0,12}'

    # Rhetorical questions: at most one per document.
    local questions
    questions=$("$GREP" -oP '？|\?(?=\s|$)' "$work" | wc -l)
    if (( questions > 1 )); then
        echo -e "${label}: ${YELLOW}WARN${RESET} [rhetorical-question] ${questions} question marks found; at most one rhetorical question is allowed"
        WARNINGS=$((WARNINGS + 1))
    fi

    rm -f "$work"

    # Print findings in line order.
    [[ -n "$FINDINGS" ]] && printf '%s' "$FINDINGS" | sort -t: -k2,2n -s
    FINDINGS=''
}

# ------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------

main() {
    (( $# > 0 )) || usage
    check_dependencies

    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage ;;
            -)
                STDIN_TMP=$(mktemp) || die "cannot create temp file"
                trap 'rm -f "$STDIN_TMP"' EXIT INT TERM
                cat > "$STDIN_TMP"
                lint_file "<stdin>" "$STDIN_TMP"
                ;;
            *)
                [[ -f "$arg" && -r "$arg" ]] || die "cannot read file: $arg"
                lint_file "$arg" "$arg"
                ;;
        esac
    done

    echo -e "${GRAY}writing-style lint: ${ERRORS} error(s), ${WARNINGS} warning(s)${RESET}" >&2
    (( ERRORS == 0 ))
}

main "$@"
