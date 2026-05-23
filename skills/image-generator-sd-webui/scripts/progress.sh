#!/usr/bin/env bash
# Get the progress of the current sd-webui job.
#
# Usage:
#   progress.sh                        — one-shot, prints JSON
#   progress.sh --watch [--interval N] — poll every N seconds (default 1) until idle
#   progress.sh --field <key>          — print just one field (progress, eta_relative, state.job, etc.)
#
# Endpoint: GET /sdapi/v1/progress?skip_current_image=true
#
# Key fields in response:
#   progress         — 0..1 (fraction of current job)
#   eta_relative     — estimated seconds remaining
#   state.job        — current job name; empty string when idle
#   state.job_count  — total jobs in current batch
#   state.job_no     — index of current job in batch
#   state.sampling_step / state.sampling_steps — current step / total
#   textinfo         — human-readable status

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

watch=0
interval=1
field=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --watch) watch=1; shift ;;
        --interval) interval="$2"; shift 2 ;;
        --field) field="$2"; shift 2 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

# Use a short timeout for progress polling.
SD_WEBUI_TIMEOUT=10

fetch_and_print() {
    local response
    response="$(sd_curl '/sdapi/v1/progress?skip_current_image=true')"
    if [[ -n "$field" ]]; then
        require_jq
        # Allow dotted paths like "state.job". Split on '.' and use getpath()
        # so the user input never becomes part of the jq program text.
        echo "$response" | jq -r --arg path "$field" '
            ($path | split(".")) as $p
            | getpath($p)
            | if . == null then "" else . end
        '
    else
        echo "$response"
    fi
}

if [[ $watch -eq 0 ]]; then
    fetch_and_print
    exit 0
fi

require_jq
while :; do
    response="$(sd_curl '/sdapi/v1/progress?skip_current_image=true')"
    progress="$(echo "$response" | jq -r '.progress // 0')"
    eta="$(echo "$response" | jq -r '.eta_relative // 0')"
    job="$(echo "$response" | jq -r '.state.job // ""')"
    step="$(echo "$response" | jq -r '.state.sampling_step // 0')"
    total="$(echo "$response" | jq -r '.state.sampling_steps // 0')"
    interrupted="$(echo "$response" | jq -r '.state.interrupted // false')"
    printf 'progress=%.3f  step=%s/%s  eta=%.1fs  job=%s\n' "$progress" "$step" "$total" "$eta" "$job"
    # Terminate when the server reports it's idle (job empty) or interrupted.
    # NOTE: do NOT exit on progress>=1.0 alone — sd-webui/Forge may still be
    # running post-processing (VAE decode, face restore, file save) while
    # progress already reads 1.0.
    if [[ -z "$job" || "$interrupted" == "true" ]]; then
        break
    fi
    sleep "$interval"
done
