#!/usr/bin/env bash
# Probe the sd-webui server. Prints "OK <url>" on success, error to stderr on failure.
# Uses /sdapi/v1/samplers as a lightweight reachability check.

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$DIR/_common.sh"

# Override timeout to a short value for probing (don't wait 10 minutes to find out
# the server is down).
SD_WEBUI_TIMEOUT="${SD_WEBUI_PROBE_TIMEOUT:-10}"

if sd_curl /sdapi/v1/samplers >/dev/null; then
    echo "OK ${SD_WEBUI_URL}"
else
    exit 1
fi
