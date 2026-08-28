#!/usr/bin/env bash
# Wait for every workflow run attached to a commit to finish, then report the verdict.
# Run this in the background if your harness blocks long-running foreground commands.
set -euo pipefail

SHA=""
REPO=""
TIMEOUT=1800
INTERVAL=20
GRACE=120

usage() {
    cat <<'USAGE'
Usage: wait_for_ci.sh [options]

Options:
  -s, --sha SHA         Commit to watch (default: git rev-parse HEAD)
  -R, --repo OWNER/REPO Target repository (default: the cwd repo)
  -t, --timeout SEC     Give up after this long (default: 1800)
  -i, --interval SEC    Poll interval (default: 20)
  -g, --grace SEC       How long to wait for runs to be registered at all (default: 120)
  -h, --help            Show this help

Exit codes:
  0  every run for the commit concluded success (or was skipped)
  1  at least one run failed, was cancelled, or timed out
  2  the wait timed out while runs were still in progress
  3  no run was ever registered for the commit, or a usage error
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--sha)      SHA="$2"; shift 2 ;;
        -R|--repo)     REPO="$2"; shift 2 ;;
        -t|--timeout)  TIMEOUT="$2"; shift 2 ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        -g|--grace)    GRACE="$2"; shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        *)             echo "Unknown argument: $1" >&2; usage >&2; exit 3 ;;
    esac
done

command -v gh >/dev/null || { echo "Error: gh CLI is not installed." >&2; exit 3; }
command -v jq >/dev/null || { echo "Error: jq is not installed." >&2; exit 3; }

if [[ -z "$SHA" ]]; then
    SHA="$(git rev-parse HEAD)" || { echo "Error: not a git repository; pass --sha." >&2; exit 3; }
fi

# `gh run list --commit` matches on the full 40-char SHA and returns an empty list for an
# abbreviation, which would otherwise look identical to "no run was ever created".
if [[ ! "$SHA" =~ ^[0-9a-fA-F]{40}$ ]]; then
    if FULL="$(git rev-parse "$SHA^{commit}" 2>/dev/null)"; then
        echo "Expanded ${SHA} to ${FULL}."
        SHA="$FULL"
    else
        echo "Error: --sha must be a full 40-character SHA (or resolvable in this repository)." >&2
        echo "       'gh run list --commit' does not match abbreviated SHAs." >&2
        exit 3
    fi
fi

gh_args=()
[[ -n "$REPO" ]] && gh_args+=(-R "$REPO")

echo "Watching runs for commit ${SHA:0:12} (timeout ${TIMEOUT}s, poll ${INTERVAL}s)..."

START=$SECONDS
LAST_JSON="[]"

while :; do
    ELAPSED=$((SECONDS - START))

    RUNS="$(gh run list "${gh_args[@]}" --commit "$SHA" --limit 50 \
        --json databaseId,workflowName,status,conclusion,url 2>/dev/null || echo '[]')"
    LAST_JSON="$RUNS"
    TOTAL="$(jq -r 'length' <<<"$RUNS")"

    if [[ "$TOTAL" -eq 0 ]]; then
        if [[ "$ELAPSED" -ge "$GRACE" ]]; then
            echo "No workflow run was registered for ${SHA:0:12} within ${GRACE}s."
            echo "Either no workflow matches this event/branch, the workflow needs approval,"
            echo "or the run is attached to a different SHA (merge_group / pull_request_target)."
            echo "Cross-check with: gh run list ${REPO:+-R $REPO} --limit 10"
            exit 3
        fi
    else
        PENDING="$(jq -r '[.[] | select(.status != "completed")] | length' <<<"$RUNS")"
        if [[ "$PENDING" -eq 0 ]]; then
            break
        fi
        echo "  [${ELAPSED}s] ${PENDING}/${TOTAL} run(s) still going..."
    fi

    if [[ "$ELAPSED" -ge "$TIMEOUT" ]]; then
        echo
        echo "Timed out after ${ELAPSED}s with runs still in progress:"
        jq -r '.[] | select(.status != "completed") | "- [\(.status)] \(.workflowName)  \(.url)"' <<<"$LAST_JSON"
        exit 2
    fi

    sleep "$INTERVAL"
done

echo
echo "## Runs for ${SHA:0:12}"
echo
jq -r '.[] | "- [\(.conclusion)] \(.workflowName)  (run \(.databaseId))  \(.url)"' <<<"$LAST_JSON"
echo

BAD="$(jq -r '[.[] | select(.conclusion != "success" and .conclusion != "skipped" and .conclusion != "neutral")] | length' <<<"$LAST_JSON")"

if [[ "$BAD" -eq 0 ]]; then
    echo "GREEN — every run for this commit passed."
    exit 0
fi

echo "RED — triage these run IDs with ci_failure_report.sh:"
jq -r '.[] | select(.conclusion != "success" and .conclusion != "skipped" and .conclusion != "neutral") | "  \(.databaseId)  # \(.workflowName) [\(.conclusion)]"' <<<"$LAST_JSON"
exit 1
