#!/usr/bin/env bash
# Shared helpers for sd-webui API scripts.
# Source this file; do not execute directly.

set -euo pipefail

SD_WEBUI_URL="${SD_WEBUI_URL:-http://localhost:7860}"
SD_WEBUI_URL="${SD_WEBUI_URL%/}"
SD_WEBUI_USER="${SD_WEBUI_USER:-}"
SD_WEBUI_PASS="${SD_WEBUI_PASS:-}"
SD_WEBUI_TIMEOUT="${SD_WEBUI_TIMEOUT:-600}"

# sd_curl <path> [extra curl args...]
# Echoes response body to stdout. Exits non-zero on HTTP error or transport error,
# printing a diagnostic to stderr including HTTP status and the first 500 chars of
# the response body.
sd_curl() {
    local path="$1"
    shift
    local url="${SD_WEBUI_URL}${path}"
    local auth_args=()
    if [[ -n "$SD_WEBUI_USER" ]]; then
        auth_args=(-u "${SD_WEBUI_USER}:${SD_WEBUI_PASS}")
    fi

    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN

    local http_code
    http_code="$(curl -sS \
        --max-time "$SD_WEBUI_TIMEOUT" \
        -o "$tmp" \
        -w '%{http_code}' \
        -H 'Content-Type: application/json' \
        "${auth_args[@]}" \
        "$@" \
        "$url")" || {
            echo "sd-webui request failed (transport error) at $path" >&2
            return 1
        }

    if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
        local body
        body="$(head -c 500 "$tmp" || true)"
        echo "sd-webui API error: HTTP $http_code at $path — $body" >&2
        return 1
    fi

    cat "$tmp"
}

# Require jq for JSON parsing helpers.
require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq is required but not installed. Install with: apt install jq" >&2
        return 1
    fi
}
