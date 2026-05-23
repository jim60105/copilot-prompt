#!/usr/bin/env bash
# Get / set global sd-webui options.
#
# Usage:
#   options.sh get                      — print all options (large JSON)
#   options.sh get <key>                — print one option value
#   options.sh set <key> <value>        — set one option (value passed as JSON; strings must be quoted)
#   options.sh set-json '<json-object>' — set multiple options at once
#   options.sh refresh-checkpoints      — POST /sdapi/v1/refresh-checkpoints (rescans the models folder)
#
# WARNING: `set` and `set-json` mutate the server's PERSISTENT options. Prefer
# `override_settings` inside a txt2img request body — that is request-scoped and
# reverts after the call. Use this script only when you genuinely need to change
# a global option (e.g. swap the active checkpoint for all clients).
#
# Common keys:
#   sd_model_checkpoint    — active checkpoint, must match a `title` from list.sh models
#   samples_format         — "png" / "jpg" / "webp" (Forge accepts subset; keep "png")
#   CLIP_stop_at_last_layers — integer
#   sd_vae                 — active VAE name or "Automatic"

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

SD_WEBUI_TIMEOUT=30

cmd="${1:-}"
shift || true

case "$cmd" in
    get)
        require_jq
        response="$(sd_curl /sdapi/v1/options)"
        if [[ $# -eq 0 ]]; then
            echo "$response"
        else
            echo "$response" | jq -r --arg k "$1" '.[$k]'
        fi
        ;;
    set)
        if [[ $# -ne 2 ]]; then
            echo "Usage: options.sh set <key> <value-as-json>" >&2
            exit 2
        fi
        require_jq
        body="$(jq -nc --arg k "$1" --argjson v "$2" '{($k): $v}')"
        sd_curl /sdapi/v1/options -X POST -d "$body" >/dev/null
        echo "OK set $1"
        ;;
    set-json)
        if [[ $# -ne 1 ]]; then
            echo "Usage: options.sh set-json '<json-object>'" >&2
            exit 2
        fi
        sd_curl /sdapi/v1/options -X POST -d "$1" >/dev/null
        echo "OK set-json"
        ;;
    refresh-checkpoints)
        sd_curl /sdapi/v1/refresh-checkpoints -X POST -d '{}' >/dev/null
        echo "OK refresh-checkpoints"
        ;;
    -h|--help|"")
        sed -n '2,25p' "$0"
        ;;
    *)
        echo "Unknown subcommand: $cmd" >&2
        sed -n '2,25p' "$0" >&2
        exit 2
        ;;
esac
