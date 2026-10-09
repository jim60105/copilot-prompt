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
# Lint zh-TW prose against the mechanically checkable rules of the
# chinese-content-writing-guideline skill. Language-agnostic style
# rules are checked by writing-style-guideline/scripts/lint.sh.
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
    echo '中' | "$GREP" -qP '\p{Han}' 2>/dev/null \
        || die "$GREP lacks PCRE (-P) support; install GNU grep and set GREP=ggrep"
}

# Blank out fenced code blocks, inline code, link definitions, and URLs
# while keeping line numbers intact.
strip_code() {
    awk '
        /^[[:space:]]*(```|~~~)/ { in_fence = !in_fence; print ""; next }
        in_fence { print ""; next }
        /^[[:space:]]*\[[^]]+\]:[[:space:]]/ { print ""; next }
        { gsub(/`[^`]*`/, ""); gsub(/\]\([^)]*\)/, "]"); gsub(/https?:\/\/[^[:space:]]+/, ""); print }
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

# Mainland or non-Taiwan wording for terms in the skill's terminology
# table, mapped to the Taiwan form. Matches are warnings because some
# words are valid in other senses (對象 can mean a partner).
TERMS=(
    '對象=物件' '隊列=佇列' '信息=資訊' '調用=呼叫' '代碼=程式碼'
    '運行=執行' '構建=建構' '視頻=影片' '函數=函式' '內存=記憶體'
    '全局=全域' '兼容性=相容性' '刷新=重新整理' '文檔=文件' '示例=範例'
    '質量=品質' '教程=指南' '字節=位元組' '比特=位元' '上下文=脈絡'
    '技術棧=技術堆疊' '激活=啟動' '反饋=回饋' '依賴注入=相依性注入'
    '依賴包=相依套件' '可擴展性=延展性' '並發=平行處理' '事務=交易'
    '代碼片段=程式碼片段' '關鍵字=保留字' '克隆=複製' '創建=建立'
)

# Word-for-word calques of English phrases (see the No Calques section of
# the skill). High-confidence coinages that no Taiwan reader uses are hard
# errors; words that also exist in legitimate senses (落地 as a physical
# landing, 回填 in earthworks, 深潛 for scuba diving) are warnings.
CALQUES=(
    'ERROR 折入=納入、併入、融入'
    'ERROR 可行動的=具體可行'
    'ERROR 槓桿化=善用'
    'WARN 賦能=賦權'
    'WARN 拉齊=對齊'
    'WARN 落地=完成、上路、實現'
    'WARN 回填=補填'
    'WARN 深潛=深入研究'
)

lint_file() {
    local label="$1" src="$2"
    local work
    work=$(mktemp) || die "cannot create temp file"
    strip_code "$src" > "$work"

    # Forms of address.
    report ERROR address-nin "$label" "$work" '您'

    # Sentence-final 的 right before a clause boundary.
    report ERROR final-de "$label" "$work" '的[，。]'

    # Missing space between Han and alphanumerics.
    report ERROR cjk-spacing "$label" "$work" '\p{Han}[A-Za-z0-9]|[A-Za-z0-9]\p{Han}'

    # Half-width punctuation touching Han characters.
    report ERROR halfwidth-punct "$label" "$work" '\p{Han}[,.;:!?()]|[,;:!?(]\p{Han}|\)\p{Han}'

    # Reduplicated words (疊字). Some are legitimate (謝謝, 爸爸).
    report WARN reduplication "$label" "$work" '(\p{Han})\1'

    # Non-Taiwan terminology.
    local entry
    for entry in "${TERMS[@]}"; do
        report WARN "terminology→${entry#*=}" "$label" "$work" "${entry%%=*}"
    done

    # Calques of English phrases.
    local level
    for entry in "${CALQUES[@]}"; do
        level=${entry%% *}; entry=${entry#* }
        report "$level" "calque→${entry#*=}" "$label" "$work" "${entry%%=*}"
    done

    # English terms repeated in prose. Capitalised words are skipped as
    # likely proper nouns; review the rest for a zh-TW translation.
    local term count
    while read -r count term; do
        FINDINGS+="${label}:0: ${YELLOW}WARN${RESET} [english-term] ${GRAY}${term} appears ${count} times${RESET}"$'\n'
        WARNINGS=$((WARNINGS + 1))
    done < <("$GREP" -oP '(?<![A-Za-z])[a-z][a-z-]{2,}(?![A-Za-z])' "$work" \
                | sort | uniq -c | awk '$1 >= 2 { print $1, $2 }')

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

    echo -e "${GRAY}chinese-content lint: ${ERRORS} error(s), ${WARNINGS} warning(s)${RESET}" >&2
    (( ERRORS == 0 ))
}

main "$@"
