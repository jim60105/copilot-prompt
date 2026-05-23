#!/usr/bin/env bash
# Submit a txt2img request to the sd-webui server.
#
# Usage:
#   generate.sh <request.json>     # read request from file
#   generate.sh -                  # read request from stdin
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
#   2. Forces override_settings.samples_format=png and override_settings_restore_afterwards=true
#      on the request body to keep the server's persistent options unchanged.
#   3. POSTs to /sdapi/v1/txt2img and prints the full JSON response to stdout.
#
# The response shape is:
#   { "images": ["<base64 PNG>", ...], "parameters": {...}, "info": "<JSON string with seed, etc.>" }
#
# To extract the image:
#   generate.sh req.json | jq -r '.images[0]' | base64 -d > out.png
#
# Override the curl timeout (default 600s):
#   SD_WEBUI_TIMEOUT=900 generate.sh req.json

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

if [[ $# -ne 1 ]]; then
    sed -n '2,30p' "$0" >&2
    exit 2
fi

require_jq

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
')"

# Step 1: pre-pin samples_format=png. Tolerate failure (legacy AUTOMATIC1111
# without this option, or auth restrictions) — the override_settings in the
# request body is a redundant safeguard.
if ! sd_curl /sdapi/v1/options -X POST -d '{"samples_format":"png"}' >/dev/null 2>&1; then
    echo "generate.sh: warning — failed to pin samples_format via /sdapi/v1/options; relying on override_settings" >&2
fi

# Step 2: submit txt2img.
sd_curl /sdapi/v1/txt2img -X POST -d "$request_body"
