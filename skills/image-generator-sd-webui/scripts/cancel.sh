#!/usr/bin/env bash
# Cancel the current sd-webui job.
#
# Usage:
#   cancel.sh         — POST /sdapi/v1/interrupt (stop current job at next sampler step)
#   cancel.sh --skip  — POST /sdapi/v1/skip (skip current job in a batch, continue with next)
#
# Note: interrupt is cooperative. The in-flight txt2img HTTP call will return
# normally with whatever partial result the sampler produced — it does NOT raise
# an HTTP error.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

SD_WEBUI_TIMEOUT=10

action=interrupt
case "${1:-}" in
    "") ;;
    --skip) action=skip ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
esac

sd_curl "/sdapi/v1/${action}" -X POST -d '{}' >/dev/null
echo "OK ${action}"
