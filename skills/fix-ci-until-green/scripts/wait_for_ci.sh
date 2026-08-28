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
# Wait for every workflow run attached to a commit to finish, then report the
# verdict and the run IDs worth triaging.
#
# Usage: wait_for_ci.sh [options]
#
# Run this in the background if your harness blocks long-running foreground
# commands.
#
# Reads only: every gh call is a GET. Authentication comes from the gh CLI's own
# credential store, never from arguments or hardcoded values. The default commit
# and any abbreviated SHA are resolved against the repository in $(pwd), so the
# script works from any checkout without knowing its own location.

set -euo pipefail

# ------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------

# Diagnostics go to stderr in colour; the verdict goes to stdout in plain text,
# because it is normally piped into a log, a file, or an agent's context where
# escape sequences are noise.
if [[ -t 2 ]]; then
    RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; GRAY=$'\033[0;90m'; RESET=$'\033[0m'
else
    RED=''; YELLOW=''; GRAY=''; RESET=''
fi
readonly RED YELLOW GRAY RESET

readonly EXIT_GREEN=0 EXIT_RED=1 EXIT_TIMEOUT=2 EXIT_USAGE=3

# The API is polled in a loop, so refuse an interval that would hammer it.
readonly MIN_INTERVAL=5

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
Usage: wait_for_ci.sh [options]

Options:
  -s, --sha SHA         Commit to watch (default: git rev-parse HEAD)
  -R, --repo OWNER/REPO Target repository (default: the cwd repo)
  -t, --timeout SEC     Give up after this long (default: 1800)
  -i, --interval SEC    Poll interval (default: 20, minimum 5)
  -g, --grace SEC       How long to wait for runs to be registered at all (default: 120)
  -h, --help            Show this help

Exit codes:
  0  every run for the commit concluded success (or was skipped)
  1  at least one run failed, was cancelled, or timed out
  2  the wait timed out while runs were still in progress
  3  no run was ever registered for the commit, or a usage error
USAGE
}

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
    for cmd in gh jq; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    [[ ${#missing[@]} -eq 0 ]] \
        || die "$EXIT_USAGE" "required command(s) not installed: ${missing[*]}" \
               "Install them and re-run."
    gh auth status >/dev/null 2>&1 \
        || die "$EXIT_USAGE" "gh is not authenticated." \
               "Run: gh auth login"
}

# Report where the wait stopped rather than dying silently mid-poll.
on_interrupt() {
    trap - INT TERM
    warn "interrupted after $((SECONDS - START))s while watching ${SHA:0:12}."
    hint "Re-check with: gh run list ${REPO:+-R $REPO} --commit $SHA"
    exit "$EXIT_TIMEOUT"
}

# ------------------------------------------------------------------
# Core logic
# ------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--sha)      require_value "$1" "${2:-}"; SHA="$2"; shift 2 ;;
            -R|--repo)     require_value "$1" "${2:-}"; REPO="$2"; shift 2 ;;
            -t|--timeout)  require_value "$1" "${2:-}"; require_int "$1" "$2"; TIMEOUT="$2"; shift 2 ;;
            -i|--interval) require_value "$1" "${2:-}"; require_int "$1" "$2"; INTERVAL="$2"; shift 2 ;;
            -g|--grace)    require_value "$1" "${2:-}"; require_int "$1" "$2"; GRACE="$2"; shift 2 ;;
            -h|--help)     usage; exit "$EXIT_GREEN" ;;
            *)             err "unknown argument: $1"; usage >&2; exit "$EXIT_USAGE" ;;
        esac
    done

    if [[ "$INTERVAL" -lt "$MIN_INTERVAL" ]]; then
        warn "poll interval raised from ${INTERVAL}s to ${MIN_INTERVAL}s to avoid hammering the API."
        INTERVAL="$MIN_INTERVAL"
    fi
}

resolve_sha() {
    if [[ -z "$SHA" ]]; then
        SHA="$(git rev-parse HEAD 2>/dev/null)" \
            || die "$EXIT_USAGE" "not a git repository, so HEAD cannot be resolved." \
                   "Pass the commit explicitly: --sha <40-char-sha>"
    fi

    # `gh run list --commit` matches on the full 40-char SHA and returns an empty list for an
    # abbreviation, which would otherwise look identical to "no run was ever created".
    if [[ ! "$SHA" =~ ^[0-9a-fA-F]{40}$ ]]; then
        local full
        if full="$(git rev-parse "$SHA^{commit}" 2>/dev/null)"; then
            echo "Expanded ${SHA} to ${full}."
            SHA="$full"
        else
            die "$EXIT_USAGE" "--sha must be a full 40-character SHA, or resolvable in this repository." \
                "'gh run list --commit' does not match abbreviated SHAs." \
                "Expand it first: git rev-parse $SHA"
        fi
    fi

    GH_ARGS=()
    [[ -n "$REPO" ]] && GH_ARGS+=(-R "$REPO")
    return 0
}

fetch_runs() {
    gh run list "${GH_ARGS[@]}" --commit "$SHA" --limit 50 \
        --json databaseId,workflowName,status,conclusion,url 2>/dev/null || echo '[]'
}

report_no_runs() {
    echo "No workflow run was registered for ${SHA:0:12} within ${GRACE}s."
    echo "Either no workflow matches this event/branch, the workflow needs approval,"
    echo "or the run is attached to a different SHA (merge_group / pull_request_target)."
    echo "Cross-check with: gh run list ${REPO:+-R $REPO} --limit 10"
}

# Poll until every run for the commit is completed. Sets LAST_JSON on the way out.
await_completion() {
    local elapsed total pending
    while :; do
        elapsed=$((SECONDS - START))

        LAST_JSON="$(fetch_runs)"
        total="$(jq -r 'length' <<<"$LAST_JSON")"

        if [[ "$total" -eq 0 ]]; then
            if [[ "$elapsed" -ge "$GRACE" ]]; then
                report_no_runs
                return "$EXIT_USAGE"
            fi
        else
            pending="$(jq -r '[.[] | select(.status != "completed")] | length' <<<"$LAST_JSON")"
            [[ "$pending" -eq 0 ]] && return "$EXIT_GREEN"
            echo "  [${elapsed}s] ${pending}/${total} run(s) still going..."
        fi

        if [[ "$elapsed" -ge "$TIMEOUT" ]]; then
            echo
            echo "Timed out after ${elapsed}s with runs still in progress:"
            jq -r '.[] | select(.status != "completed") | "- [\(.status)] \(.workflowName)  \(.url)"' <<<"$LAST_JSON"
            return "$EXIT_TIMEOUT"
        fi

        sleep "$INTERVAL"
    done
}

emit_verdict() {
    local bad
    echo
    echo "## Runs for ${SHA:0:12}"
    echo
    jq -r '.[] | "- [\(.conclusion)] \(.workflowName)  (run \(.databaseId))  \(.url)"' <<<"$LAST_JSON"
    echo

    bad="$(jq -r '[.[] | select(.conclusion != "success" and .conclusion != "skipped" and .conclusion != "neutral")] | length' <<<"$LAST_JSON")"
    if [[ "$bad" -eq 0 ]]; then
        echo "GREEN — every run for this commit passed."
        return "$EXIT_GREEN"
    fi

    echo "RED — triage these run IDs with ci_failure_report.sh:"
    jq -r '.[] | select(.conclusion != "success" and .conclusion != "skipped" and .conclusion != "neutral") | "  \(.databaseId)  # \(.workflowName) [\(.conclusion)]"' <<<"$LAST_JSON"
    return "$EXIT_RED"
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

main() {
    parse_args "$@"
    require_deps
    resolve_sha

    trap on_interrupt INT TERM

    echo "Watching runs for commit ${SHA:0:12} (timeout ${TIMEOUT}s, poll ${INTERVAL}s)..."
    START=$SECONDS

    local status=0
    await_completion || status=$?
    trap - INT TERM
    [[ "$status" -eq 0 ]] || return "$status"

    emit_verdict
}

# Defaults, overridable by the options above.
SHA=""
REPO=""
TIMEOUT=1800
INTERVAL=20
GRACE=120
START=$SECONDS
LAST_JSON="[]"
GH_ARGS=()

main "$@"
