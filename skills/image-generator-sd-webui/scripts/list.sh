#!/usr/bin/env bash
# List resources from the sd-webui server.
#
# Usage:
#   list.sh <kind> [--json]
#
# Kinds:
#   models       — checkpoints (GET /sdapi/v1/sd-models)
#   modules      — Forge extra modules / TE / VAE (GET /sdapi/v1/sd-modules)
#   samplers     — (GET /sdapi/v1/samplers)
#   schedulers   — (GET /sdapi/v1/schedulers)
#   styles       — prompt style presets (GET /sdapi/v1/prompt-styles)
#   upscalers    — (GET /sdapi/v1/upscalers)
#   loras        — (GET /sdapi/v1/loras)
#   embeddings   — (GET /sdapi/v1/embeddings)
#
# By default prints the canonical English identifier, one per line.
# With --json, prints the raw API response.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

if [[ $# -lt 1 ]]; then
    sed -n '2,20p' "$0" >&2
    exit 2
fi

kind="$1"
shift
raw_json=0
for arg in "$@"; do
    case "$arg" in
        --json) raw_json=1 ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

case "$kind" in
    models)      path=/sdapi/v1/sd-models;     filter='.[] | .title // .model_name // empty' ;;
    modules)     path=/sdapi/v1/sd-modules;    filter='.[] | .model_name // .name // empty' ;;
    samplers)    path=/sdapi/v1/samplers;      filter='.[] | .name // empty' ;;
    schedulers)  path=/sdapi/v1/schedulers;    filter='.[] | .label // .name // empty' ;;
    styles)      path=/sdapi/v1/prompt-styles; filter='.[] | .name // empty' ;;
    upscalers)   path=/sdapi/v1/upscalers;     filter='.[] | .name // empty' ;;
    loras)       path=/sdapi/v1/loras;         filter='.[] | .name // .alias // empty' ;;
    embeddings)  path=/sdapi/v1/embeddings;    filter='(.loaded // {}) | keys[]' ;;
    *) echo "Unknown kind: $kind" >&2; exit 2 ;;
esac

response="$(sd_curl "$path")"
if [[ $raw_json -eq 1 ]]; then
    echo "$response"
else
    require_jq
    echo "$response" | jq -r "$filter"
fi
