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
# Emit a compact failure report for a GitHub Actions run, keeping a whole CI
# failure inside a few hundred lines instead of the tens of thousands of lines a
# raw job log contains. Every failure in every failed job is reported.
#
# Usage: ci_failure_report.sh <run-url-or-id> [options]
#
# Reads only: every gh call is a GET. Authentication comes from the gh CLI's own
# credential store, never from arguments or hardcoded values. When no --repo is
# given, gh resolves the repository from $(pwd), so the script works from any
# checkout without knowing its own location.

set -euo pipefail

# ------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------

# Diagnostics go to stderr in colour; the report itself goes to stdout in plain
# text, because it is normally piped into a log, a file, or an agent's context
# where escape sequences are noise.
if [[ -t 2 ]]; then
    RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; GRAY=$'\033[0;90m'; RESET=$'\033[0m'
else
    RED=''; YELLOW=''; GRAY=''; RESET=''
fi
readonly RED YELLOW GRAY RESET

readonly EXIT_GREEN=0 EXIT_RED=1 EXIT_PENDING=2 EXIT_USAGE=3

err()  { printf '%sERROR: %s%s\n' "$RED" "$*" "$RESET" >&2; }
warn() { printf '%sWARNING: %s%s\n' "$YELLOW" "$*" "$RESET" >&2; }
hint() { printf '%s  %s%s\n' "$GRAY" "$*" "$RESET" >&2; }

# die <exit-code> <message> [suggested-solution ...]
die() {
    local code="$1" message="$2"
    shift 2
    err "$message"
    local suggestion
    for suggestion in "$@"; do
        hint "$suggestion"
    done
    exit "$code"
}

usage() {
    cat <<'USAGE'
Usage: ci_failure_report.sh <run-url-or-id> [options]

Arguments:
  <run-url-or-id>       https://github.com/OWNER/REPO/actions/runs/ID  or  a bare run ID

Options:
  -R, --repo OWNER/REPO Target repository (default: parsed from the URL, else the cwd repo)
  -a, --attempt N       Run attempt number (default: latest; also parsed from /attempts/N URLs)
  -c, --context N       Log lines kept before each error marker (default: 40)
  -m, --max-lines N     Hard cap on log lines printed per failed job (default: 200)
  -b, --block-lines N   Hard cap on lines printed per failure block (default: 30)
  -B, --max-blocks N    Distinct failure blocks printed per job (default: 20)
  -s, --signature-lines N
                        Distinct error lines printed per job (default: 40)
  -h, --help            Show this help

Every failure in every failed job is reported. Repeats of the same failure collapse to one
representative plus the full list of its variants, and every cap announces what it hid.

Exit codes:
  0  run completed successfully
  1  run completed with failures (report printed)
  2  run is still queued or in progress
  3  usage or lookup error
USAGE
}

# Fail fast on a value that will later be used in arithmetic or as a line count.
require_int() {
    local flag="$1" value="$2"
    [[ "$value" =~ ^[0-9]+$ ]] \
        || die "$EXIT_USAGE" "$flag expects a non-negative integer, got '$value'."
}

require_value() {
    local flag="$1"
    shift
    [[ $# -ge 1 && -n "$1" ]] || die "$EXIT_USAGE" "$flag requires a value."
}

require_deps() {
    local cmd missing=()
    for cmd in gh jq awk; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    [[ ${#missing[@]} -eq 0 ]] \
        || die "$EXIT_USAGE" "required command(s) not installed: ${missing[*]}" \
               "Install them and re-run."
    gh auth status >/dev/null 2>&1 \
        || die "$EXIT_USAGE" "gh is not authenticated." \
               "Run: gh auth login"
}

# ------------------------------------------------------------------
# Log processing
# ------------------------------------------------------------------

# Strip the "job<TAB>step<TAB>" columns gh prepends, the ISO timestamp, the BOM,
# ANSI colour codes (real ESC and GitHub's literal "^[" caret notation alike),
# and the collapsible-group markers that carry no diagnostic value.
normalize_log() {
    cut -f3- \
        | sed -E $'s/^\xef\xbb\xbf//; s/\r$//; s/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z //; s/(\x1b|\\^\\[)\\[[0-9;]*[a-zA-Z]//g' \
        | grep -vE '^##\[(group|endgroup)\]' || true
}

# Lines that begin a distinct failure report, across ecosystems. Backslashes are
# doubled because awk -v assignments consume one level of escaping.
readonly HEADLINE_PATTERN='^(FAIL|FAILED|ERROR)[:[:space:]]|^--- FAIL:|^[[:space:]]*● |^_{4,}.*_{4,}$|^error(\\[E[0-9]+\\])?:|^error TS[0-9]+|^[0-9]+\\)[[:space:]]|^[[:space:]]*panic:'

# Lines worth surfacing on their own, wherever they appear in the log.
readonly SIG_PATTERN='##\[error\]|##\[warning\]|^E +[A-Za-z]|\bFAILED\b|\bFAIL\b|\bERROR\b|error\[E[0-9]+\]|error TS[0-9]+|AssertionError|Traceback \(most recent|^ *panic:|npm ERR!|Segmentation fault|exit code [1-9]'

# Extract every distinct failure block, collapsing repeats into one representative
# plus the full list of its variants. Held in a variable so the awk source can use
# quotes freely.
read -r -d '' AWK_BLOCKS <<'AWK' || true
function fingerprint(s,   t) {
    t = s
    gsub(/'[^']*'/, "@", t)
    gsub(/"[^"]*"/, "@", t)
    gsub(/[0-9]+/, "#", t)
    return t
}
{ line[NR] = $0 }
END {
    total = NR
    n = 0
    for (i = 1; i <= total; i++)
        if (line[i] ~ headline_re) head[++n] = i
    if (n == 0) exit 0

    for (k = 1; k <= n; k++) {
        fp = fingerprint(line[head[k]])
        count[fp]++
        variant[fp, count[fp]] = line[head[k]]
        if (!(fp in first)) { first[fp] = k; order[++distinct] = fp }
    }

    printf "%d failure block(s), %d distinct.\n\n", n, distinct

    hidden = 0
    shown = 0
    for (d = 1; d <= distinct; d++) {
        if (shown >= max_blocks) { hidden = distinct - shown; break }
        fp = order[d]
        k = first[fp]
        start = head[k]
        end = (k < n ? head[k + 1] - 1 : total)
        trunc = 0
        if (end - start + 1 > block_lines) { end = start + block_lines - 1; trunc = 1 }

        printf "#### %d/%d  (log line %d", d, distinct, start
        if (count[fp] > 1) printf ", %d occurrences", count[fp]
        printf ")\n"
        print "```"
        for (i = start; i <= end; i++) print line[i]
        if (trunc) printf "... block truncated at %d lines (raise --block-lines)\n", block_lines
        print "```"
        if (count[fp] > 1) {
            uniq = 0
            delete seen_variant
            for (v = 1; v <= count[fp]; v++)
                if (!(variant[fp, v] in seen_variant)) { seen_variant[variant[fp, v]] = 1; uniq++ }
            if (uniq > 1) {
                printf "All %d occurrences:\n", count[fp]
                print "```"
                for (v = 1; v <= count[fp] && v <= 30; v++) print variant[fp, v]
                if (count[fp] > 30) printf "... %d more occurrences hidden\n", count[fp] - 30
                print "```"
            }
        }
        print ""
        shown++
    }
    if (hidden > 0)
        printf "... %d more distinct failure block(s) hidden (raise --max-blocks)\n", hidden
}
AWK

# ------------------------------------------------------------------
# Core logic
# ------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -R|--repo)
                require_value "$1" "${2:-}"; REPO="$2"; shift 2 ;;
            -a|--attempt)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; ATTEMPT="$2"; shift 2 ;;
            -c|--context)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; CONTEXT="$2"; shift 2 ;;
            -m|--max-lines)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; MAX_LINES="$2"; shift 2 ;;
            -b|--block-lines)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; BLOCK_LINES="$2"; shift 2 ;;
            -B|--max-blocks)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; MAX_BLOCKS="$2"; shift 2 ;;
            -s|--signature-lines)
                require_value "$1" "${2:-}"; require_int "$1" "$2"; SIGNATURE_LINES="$2"; shift 2 ;;
            -h|--help)
                usage; exit "$EXIT_GREEN" ;;
            -*)
                err "unknown option: $1"; usage >&2; exit "$EXIT_USAGE" ;;
            *)
                [[ -z "$REF" ]] \
                    || die "$EXIT_USAGE" "unexpected extra argument: $1" \
                           "Pass exactly one run URL or run ID."
                REF="$1"; shift ;;
        esac
    done

    [[ -n "$REF" ]] \
        || die "$EXIT_USAGE" "a run URL or run ID is required." \
               "Example: ci_failure_report.sh https://github.com/OWNER/REPO/actions/runs/123"
}

# Resolve the reference into a run ID, and a repo when the URL carries one.
resolve_ref() {
    if [[ "$REF" =~ ^https?://[^/]+/([^/]+)/([^/]+)/actions/runs/([0-9]+) ]]; then
        [[ -n "$REPO" ]] || REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        RUN_ID="${BASH_REMATCH[3]}"
        if [[ "$REF" =~ /attempts/([0-9]+) ]] && [[ -z "$ATTEMPT" ]]; then
            ATTEMPT="${BASH_REMATCH[1]}"
        fi
    elif [[ "$REF" =~ ^[0-9]+$ ]]; then
        RUN_ID="$REF"
    else
        die "$EXIT_USAGE" "'$REF' is neither a run URL nor a numeric run ID." \
            "Pass a full https://github.com/OWNER/REPO/actions/runs/ID URL, or a bare numeric ID with -R OWNER/REPO."
    fi

    GH_ARGS=()
    [[ -n "$REPO" ]] && GH_ARGS+=(-R "$REPO")
    ATTEMPT_ARGS=()
    [[ -n "$ATTEMPT" ]] && ATTEMPT_ARGS+=(--attempt "$ATTEMPT")
    return 0
}

# `</dev/null` on every gh call: gh consumes whatever is on its stdin, and these
# calls run while a herestring owns fd 0 — without the redirect gh swallows the
# remaining input and the caller silently loses data.
fetch_run() {
    RUN_JSON="$(gh run view "$RUN_ID" "${GH_ARGS[@]}" "${ATTEMPT_ARGS[@]}" \
        --json databaseId,workflowName,displayTitle,status,conclusion,headBranch,headSha,event,url,attempt,createdAt,updatedAt,jobs 2>/dev/null </dev/null)" \
        || die "$EXIT_USAGE" "could not read run $RUN_ID${REPO:+ in $REPO}." \
               "Check the run ID and repository, then verify access with: gh auth status"
}

emit_run_header() {
    jq -r '
      "# Run \(.databaseId) — \(.workflowName) [\(.status)/\(if (.conclusion // "") == "" then "pending" else .conclusion end)]",
      "",
      "- title:    \(.displayTitle)",
      "- branch:   \(.headBranch)   head: \(.headSha[0:12])   event: \(.event)   attempt: \(.attempt)",
      "- created:  \(.createdAt)   updated: \(.updatedAt)",
      "- url:      \(.url)",
      ""
    ' <<<"$RUN_JSON"
}

# Job overview. Large matrices are collapsed to a tally so the report stays readable.
emit_job_overview() {
    local job_count
    echo "## Jobs"
    echo
    job_count="$(jq -r '.jobs | length' <<<"$RUN_JSON")"
    if [[ "$job_count" -gt 15 ]]; then
        jq -r '
          "- " + ([.jobs[] | select(.conclusion == "success")] | length | tostring) + " succeeded, "
               + ([.jobs[] | select(.conclusion == "skipped")] | length | tostring) + " skipped (collapsed)",
          (.jobs[] | select(.conclusion != "success" and .conclusion != "skipped")
            | "- [\(.conclusion)] \(.name)  (job \(.databaseId))")
        ' <<<"$RUN_JSON"
    else
        jq -r '.jobs[] | "- [\(.conclusion)] \(.name)  (job \(.databaseId))"' <<<"$RUN_JSON"
    fi
    echo
}

emit_job_header() {
    local job_id="$1"
    jq -r --argjson id "$job_id" '
      .jobs[] | select(.databaseId == $id) |
      "## Job: \(.name)  [\(.conclusion)]",
      "",
      "- job url: \(.url)",
      "- failed steps: " + ([.steps[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | .name] | join(" | ") | if . == "" then "(none reported — the job itself failed to start)" else . end),
      ""
    ' <<<"$RUN_JSON"
}

fetch_job_log() {
    local job_id="$1" log
    log="$(gh run view "${GH_ARGS[@]}" "${ATTEMPT_ARGS[@]}" --job "$job_id" --log-failed 2>/dev/null </dev/null | normalize_log || true)"
    if [[ -z "${log//[[:space:]]/}" ]]; then
        log="$(gh run view "${GH_ARGS[@]}" "${ATTEMPT_ARGS[@]}" --job "$job_id" --log 2>/dev/null </dev/null | normalize_log || true)"
    fi
    printf '%s' "$log"
}

report_job() {
    local job_id="$1" log blocks sig_all sig_total sig_title excerpt_context have_blocks

    emit_job_header "$job_id"

    log="$(fetch_job_log "$job_id")"
    if [[ -z "${log//[[:space:]]/}" ]]; then
        echo "_No log available (logs expire after 90 days, or the job never started). Open the job url above._"
        echo
        return 0
    fi

    # Every failure gets a body, not just the first and the last. Repeats of the same failure
    # collapse to one representative plus the full list of its variants, so 200 near-identical
    # assertions stay readable without losing the identifier of any single one.
    blocks="$(awk -v headline_re="$HEADLINE_PATTERN" \
                  -v block_lines="$BLOCK_LINES" \
                  -v max_blocks="$MAX_BLOCKS" "$AWK_BLOCKS" <<<"$log" || true)"
    if [[ -n "${blocks//[[:space:]]/}" ]]; then
        have_blocks=1
        echo "### Failure blocks"
        echo
        printf '%s\n' "$blocks"
        echo
    else
        have_blocks=0
    fi

    # Whatever the blocks did not already show: annotations and failure keywords scattered
    # elsewhere in the log. Filtered against the block output so nothing is printed twice.
    sig_all="$(grep -aiE "$SIG_PATTERN" <<<"$log" | awk '!seen[$0]++' \
        | grep -vxF -f <(printf '%s\n' "$blocks") || true)"
    sig_total="$(grep -c . <<<"$sig_all" || true)"
    if [[ -n "${sig_all//[[:space:]]/}" ]]; then
        if [[ "$have_blocks" -eq 1 ]]; then sig_title="Other error lines"; else sig_title="Error signatures"; fi
        echo "### $sig_title ($sig_total distinct)"
        echo '```'
        head -n "$SIGNATURE_LINES" <<<"$sig_all"
        if [[ "$sig_total" -gt "$SIGNATURE_LINES" ]]; then
            echo "... $(( sig_total - SIGNATURE_LINES )) more distinct lines hidden (raise --signature-lines)"
        fi
        echo '```'
        echo
    fi

    # Then the surrounding narrative: what the job was doing right before it died. When the
    # blocks above already carry the failures, this only needs the ending summary.
    echo "### Log excerpt"
    echo '```'
    if grep -qa '##\[error\]' <<<"$log"; then
        if [[ "$have_blocks" -eq 1 ]]; then excerpt_context=12; else excerpt_context="$CONTEXT"; fi
        grep -a -B "$excerpt_context" -A 5 '##\[error\]' <<<"$log" | tail -n "$MAX_LINES"
    else
        echo "(no ##[error] annotation found — showing the tail of the log)"
        tail -n "$MAX_LINES" <<<"$log"
    fi
    echo '```'
    echo
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

main() {
    parse_args "$@"
    require_deps
    resolve_ref
    fetch_run

    local status conclusion failed_ids job_id
    status="$(jq -r '.status' <<<"$RUN_JSON")"
    conclusion="$(jq -r 'if (.conclusion // "") == "" then "(none)" else .conclusion end' <<<"$RUN_JSON")"

    emit_run_header

    if [[ "$status" != "completed" ]]; then
        echo "Run is still **$status** — no final result yet. Wait for it to finish before triaging."
        return "$EXIT_PENDING"
    fi

    emit_job_overview

    failed_ids="$(jq -r '.jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled" or .conclusion == "startup_failure") | .databaseId' <<<"$RUN_JSON")"

    if [[ -z "$failed_ids" ]]; then
        if [[ "$conclusion" == "success" ]]; then
            echo "Run concluded **success** — CI is green for this run."
            return "$EXIT_GREEN"
        fi
        echo "Run concluded **$conclusion** but no job reported a failure."
        echo "The cause is usually workflow-level: a bad \`if:\` expression, a missing required check,"
        echo "an invalid workflow file, or a cancelled/skipped dependency. Inspect the workflow YAML."
        return "$EXIT_RED"
    fi

    # The job list is read on a dedicated descriptor (fd 3), not stdin, so that
    # nothing inside report_job can ever steal the remaining IDs. With the plain
    # `while read ... done <<<"$failed_ids"` form, the first `gh` call consumed
    # the herestring and only the first failed job was ever reported — every
    # matrix leg after it vanished from the report without a trace.
    while read -r -u 3 job_id; do
        [[ -n "$job_id" ]] || continue
        report_job "$job_id"
    done 3<<< "$failed_ids"

    return "$EXIT_RED"
}

# Defaults, overridable by the options above.
CONTEXT=40
MAX_LINES=200
SIGNATURE_LINES=40
BLOCK_LINES=30
MAX_BLOCKS=20
REPO=""
ATTEMPT=""
REF=""
RUN_ID=""
RUN_JSON=""
GH_ARGS=()
ATTEMPT_ARGS=()

main "$@"
