#!/usr/bin/env bash
# Emit a compact failure report for a GitHub Actions run.
# Designed to keep a whole CI failure inside a few hundred lines of context
# instead of the tens of thousands of lines a raw job log contains.
set -euo pipefail

CONTEXT=40
MAX_LINES=200
SIGNATURE_LINES=40
BLOCK_LINES=30
MAX_BLOCKS=20
# Lines worth surfacing on their own, across ecosystems.
# Lines that begin a distinct failure report, across ecosystems.
HEADLINE_PATTERN='^(FAIL|FAILED|ERROR)[:[:space:]]|^--- FAIL:|^[[:space:]]*● |^_{4,}.*_{4,}$|^error(\\[E[0-9]+\\])?:|^error TS[0-9]+|^[0-9]+\\)[[:space:]]|^[[:space:]]*panic:'
SIG_PATTERN='##\[error\]|##\[warning\]|^E +[A-Za-z]|\bFAILED\b|\bFAIL\b|\bERROR\b|error\[E[0-9]+\]|error TS[0-9]+|AssertionError|Traceback \(most recent|^ *panic:|npm ERR!|Segmentation fault|exit code [1-9]'
REPO=""
ATTEMPT=""
REF=""

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

while [[ $# -gt 0 ]]; do
    case "$1" in
        -R|--repo)      REPO="$2"; shift 2 ;;
        -a|--attempt)   ATTEMPT="$2"; shift 2 ;;
        -c|--context)   CONTEXT="$2"; shift 2 ;;
        -m|--max-lines) MAX_LINES="$2"; shift 2 ;;
        -b|--block-lines) BLOCK_LINES="$2"; shift 2 ;;
        -B|--max-blocks)  MAX_BLOCKS="$2"; shift 2 ;;
        -s|--signature-lines) SIGNATURE_LINES="$2"; shift 2 ;;
        -h|--help)      usage; exit 0 ;;
        -*)             echo "Unknown option: $1" >&2; usage >&2; exit 3 ;;
        *)              REF="$1"; shift ;;
    esac
done

[[ -n "$REF" ]] || { echo "Error: a run URL or run ID is required." >&2; usage >&2; exit 3; }
command -v gh >/dev/null || { echo "Error: gh CLI is not installed." >&2; exit 3; }
command -v jq >/dev/null || { echo "Error: jq is not installed." >&2; exit 3; }

# Resolve the reference into a run ID (and a repo, when the URL carries one).
if [[ "$REF" =~ ^https?://[^/]+/([^/]+)/([^/]+)/actions/runs/([0-9]+) ]]; then
    [[ -n "$REPO" ]] || REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    RUN_ID="${BASH_REMATCH[3]}"
    [[ "$REF" =~ /attempts/([0-9]+) ]] && [[ -z "$ATTEMPT" ]] && ATTEMPT="${BASH_REMATCH[1]}"
elif [[ "$REF" =~ ^[0-9]+$ ]]; then
    RUN_ID="$REF"
else
    echo "Error: '$REF' is neither a run URL nor a numeric run ID." >&2
    exit 3
fi

gh_args=()
[[ -n "$REPO" ]] && gh_args+=(-R "$REPO")
attempt_args=()
[[ -n "$ATTEMPT" ]] && attempt_args+=(--attempt "$ATTEMPT")

RUN_JSON="$(gh run view "$RUN_ID" "${gh_args[@]}" "${attempt_args[@]}" \
    --json databaseId,workflowName,displayTitle,status,conclusion,headBranch,headSha,event,url,attempt,createdAt,updatedAt,jobs)" || {
    echo "Error: could not read run $RUN_ID. Check the ID, the repo, and \`gh auth status\`." >&2
    exit 3
}

STATUS="$(jq -r '.status' <<<"$RUN_JSON")"
CONCLUSION="$(jq -r 'if (.conclusion // "") == "" then "(none)" else .conclusion end' <<<"$RUN_JSON")"

jq -r '
  "# Run \(.databaseId) — \(.workflowName) [\(.status)/\(if (.conclusion // "") == "" then "pending" else .conclusion end)]",
  "",
  "- title:    \(.displayTitle)",
  "- branch:   \(.headBranch)   head: \(.headSha[0:12])   event: \(.event)   attempt: \(.attempt)",
  "- created:  \(.createdAt)   updated: \(.updatedAt)",
  "- url:      \(.url)",
  ""
' <<<"$RUN_JSON"

if [[ "$STATUS" != "completed" ]]; then
    echo "Run is still **$STATUS** — no final result yet. Wait for it to finish before triaging."
    exit 2
fi

# Job overview. Large matrices are collapsed to a tally so the report stays readable.
echo "## Jobs"
echo
JOB_COUNT="$(jq -r '.jobs | length' <<<"$RUN_JSON")"
if [[ "$JOB_COUNT" -gt 15 ]]; then
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

FAILED_IDS="$(jq -r '.jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled" or .conclusion == "startup_failure") | .databaseId' <<<"$RUN_JSON")"

if [[ -z "$FAILED_IDS" ]]; then
    if [[ "$CONCLUSION" == "success" ]]; then
        echo "Run concluded **success** — CI is green for this run."
        exit 0
    fi
    echo "Run concluded **$CONCLUSION** but no job reported a failure."
    echo "The cause is usually workflow-level: a bad \`if:\` expression, a missing required check,"
    echo "an invalid workflow file, or a cancelled/skipped dependency. Inspect the workflow YAML."
    exit 1
fi

# Strip the "job<TAB>step<TAB>" columns gh prepends, the ISO timestamp, the BOM,
# ANSI colour codes, and the collapsible-group markers that carry no diagnostic value.
normalize() {
    cut -f3- \
        | sed -E $'s/^\xef\xbb\xbf//; s/\r$//; s/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z //; s/(\x1b|\\^\\[)\\[[0-9;]*[a-zA-Z]//g' \
        | grep -vE '^##\[(group|endgroup)\]' || true
}

# Extract every distinct failure block, collapsing repeats into one representative plus a
# count. Held in a variable so the awk source can use quotes freely.
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

while read -r job_id; do
    [[ -n "$job_id" ]] || continue

    jq -r --argjson id "$job_id" '
      .jobs[] | select(.databaseId == $id) |
      "## Job: \(.name)  [\(.conclusion)]",
      "",
      "- job url: \(.url)",
      "- failed steps: " + ([.steps[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | .name] | join(" | ") | if . == "" then "(none reported — the job itself failed to start)" else . end),
      ""
    ' <<<"$RUN_JSON"

    LOG="$(gh run view "${gh_args[@]}" "${attempt_args[@]}" --job "$job_id" --log-failed 2>/dev/null | normalize || true)"
    if [[ -z "${LOG//[[:space:]]/}" ]]; then
        LOG="$(gh run view "${gh_args[@]}" "${attempt_args[@]}" --job "$job_id" --log 2>/dev/null | normalize || true)"
    fi

    if [[ -z "${LOG//[[:space:]]/}" ]]; then
        echo "_No log available (logs expire after 90 days, or the job never started). Open the job url above._"
        echo
        continue
    fi

    # Every failure gets a body, not just the first and the last. Repeats of the same failure
    # collapse to one representative plus the full list of its variants, so 200 near-identical
    # assertions stay readable without losing the identifier of any single one.
    BLOCKS="$(awk -v headline_re="$HEADLINE_PATTERN" \
                  -v block_lines="$BLOCK_LINES" \
                  -v max_blocks="$MAX_BLOCKS" "$AWK_BLOCKS" <<<"$LOG" || true)"
    if [[ -n "${BLOCKS//[[:space:]]/}" ]]; then
        echo "### Failure blocks"
        echo
        printf '%s\n' "$BLOCKS"
        echo
        HAVE_BLOCKS=1
    else
        HAVE_BLOCKS=0
    fi

    # Whatever the blocks did not already show: annotations and failure keywords scattered
    # elsewhere in the log. Filtered against the block output so nothing is printed twice.
    SIG_ALL="$(grep -aiE "$SIG_PATTERN" <<<"$LOG" | awk '!seen[$0]++' \
        | grep -vxF -f <(printf '%s\n' "$BLOCKS") || true)"
    SIG_TOTAL="$(grep -c . <<<"$SIG_ALL" || true)"
    if [[ -n "${SIG_ALL//[[:space:]]/}" ]]; then
        [[ "$HAVE_BLOCKS" -eq 1 ]] && SIG_TITLE="Other error lines" || SIG_TITLE="Error signatures"
        echo "### $SIG_TITLE ($SIG_TOTAL distinct)"
        echo '```'
        head -n "$SIGNATURE_LINES" <<<"$SIG_ALL"
        if [[ "$SIG_TOTAL" -gt "$SIGNATURE_LINES" ]]; then
            echo "... $(( SIG_TOTAL - SIGNATURE_LINES )) more distinct lines hidden (raise --signature-lines)"
        fi
        echo '```'
        echo
    fi

    # Then the surrounding narrative: what the job was doing right before it died. When the
    # blocks above already carry the failures, this only needs the ending summary.
    echo "### Log excerpt"
    echo '```'
    if grep -qa '##\[error\]' <<<"$LOG"; then
        [[ "$HAVE_BLOCKS" -eq 1 ]] && EXCERPT_CONTEXT=12 || EXCERPT_CONTEXT="$CONTEXT"
        grep -a -B "$EXCERPT_CONTEXT" -A 5 '##\[error\]' <<<"$LOG" | tail -n "$MAX_LINES"
    else
        echo "(no ##[error] annotation found — showing the tail of the log)"
        tail -n "$MAX_LINES" <<<"$LOG"
    fi
    echo '```'
    echo
done <<<"$FAILED_IDS"

exit 1
