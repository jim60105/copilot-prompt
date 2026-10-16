#!/usr/bin/env bash
# Submit a txt2img request to the sd-webui server.
#
# Usage:
#   generate.sh <request.json>     # read request from file
#   generate.sh -                  # read request from stdin
#   generate.sh <request.json> --output-dir /absolute/session/generated
#
# The request must be a JSON object matching the sd-webui txt2img schema:
#   {
#     "prompt": "...",
#     "negative_prompt": "...",
#     "steps": 28,
#     "cfg_scale": 7.0,
#     "width": 832,
#     "height": 1216,
#     "sampler_name": "Euler a",
#     "scheduler": "Automatic",
#     "styles": ["my style"],
#     "override_settings": {
#       "sd_model_checkpoint": "model.safetensors [hash]",
#       "forge_additional_modules": ["vae.safetensors"]
#     }
#   }
#
# This script:
#   1. Pre-pins samples_format=png via /sdapi/v1/options (Forge validates this
#      BEFORE applying override_settings; a persistent unsupported value like
#      "avif" would otherwise reject the request).
#   2. Forces override_settings.samples_format=png, override_settings_restore_afterwards=true,
#      save_images=true, and send_images=true on the request body.
#   3. POSTs to /sdapi/v1/txt2img; file mode prints only a path manifest.
#      Without --output-dir, prints the full JSON response for legacy callers.
#
# The response shape is:
#   { "images": ["<base64 PNG>", ...], "parameters": {...}, "info": "<JSON string with seed, etc.>" }
#
# File mode saves all images and metadata in a unique batch subdirectory.
#
# Override the curl timeout (default 600s):
#   SD_WEBUI_TIMEOUT=900 generate.sh req.json

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

if [[ $# -ne 1 && ! ( $# -eq 3 && "$2" == "--output-dir" && "$3" == /* ) ]]; then
    printf 'Usage: generate.sh <request.json|-> [--output-dir <absolute-directory>]\n' >&2
    exit 2
fi

require_jq

batch=""
complete=false
cleanup() {
    local status=$?
    if [[ -n "$batch" && "$complete" != true ]]; then
        if rm -rf -- "$batch"; then
            printf 'generate.sh: batch failed; no partial output retained\n' >&2
        else
            printf 'generate.sh: cleanup failed; partial output retained at %s\n' "$batch" >&2
        fi
        [[ "$status" -ne 0 ]] || status=1
    fi
    exit "$status"
}
if [[ $# -eq 3 ]]; then
    command -v python3 >/dev/null || {
        printf 'generate.sh: python3 is required for --output-dir\n' >&2
        exit 2
    }
    mkdir -p -- "$3"
    output_dir="$(cd -- "$3" && pwd -P)"
    batch="$(mktemp -d "$output_dir/generation.XXXXXXXXXX")"
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
fi

src="$1"
if [[ "$src" == "-" ]]; then
    request_raw="$(cat)"
else
    request_raw="$(cat "$src")"
fi

# Validate JSON.
if ! echo "$request_raw" | jq -e . >/dev/null 2>&1; then
    echo "generate.sh: request is not valid JSON" >&2
    exit 2
fi

# Merge safety overrides into the request.
request_body="$(echo "$request_raw" | jq '
    .override_settings = ((.override_settings // {}) + {samples_format: "png"})
    | .override_settings_restore_afterwards = true
    | .save_images = true
    | .send_images = true
')"

# Step 1: pre-pin samples_format=png. Tolerate failure (legacy AUTOMATIC1111
# without this option, or auth restrictions) — the override_settings in the
# request body is a redundant safeguard.
if ! sd_curl /sdapi/v1/options -X POST -d '{"samples_format":"png"}' >/dev/null 2>&1; then
    echo "generate.sh: warning — failed to pin samples_format via /sdapi/v1/options; relying on override_settings" >&2
fi

# Step 2: submit txt2img.
if [[ -z "$batch" ]]; then
    sd_curl /sdapi/v1/txt2img -X POST -d "$request_body"
else
    sd_curl /sdapi/v1/txt2img -X POST -d "$request_body" > "$batch/response.json"
    manifest="$(python3 "$DIR/save-images.py" "$batch")"
    rm -- "$batch/response.json"
    printf '%s\n' "$manifest"
    complete=true
fi
