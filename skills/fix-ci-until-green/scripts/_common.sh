#!/usr/bin/env bash
# Copyright (C) 2026 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
# ==================================================================
#
# Shared utilities for the fix-ci-until-green scripts. Sourced, never executed:
#     source "$(dirname -- "${BASH_SOURCE[0]}")/_common.sh"
#
# Exit-code slots every script shares: EXIT_GREEN, EXIT_RED, EXIT_USAGE. A script
# needing a distinct middle code (PENDING, TIMEOUT) defines it itself.

# Sourcing this file twice in one shell must not re-assign readonly variables.
if [[ -n "${_FIXCI_COMMON_LOADED:-}" ]]; then return 0; fi
readonly _FIXCI_COMMON_LOADED=1

readonly EXIT_GREEN=0 EXIT_RED=1 EXIT_USAGE=3

# Diagnostics go to stderr in colour; the report itself goes to stdout in plain
# text, because it is normally piped into a log, a file, or an agent's context
# where escape sequences are noise.
if [[ -t 2 ]]; then
    RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; GRAY=$'\033[0;90m'; RESET=$'\033[0m'
else
    RED=''; YELLOW=''; GRAY=''; RESET=''
fi
readonly RED YELLOW GRAY RESET

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

# Fail fast on a value that will later be used in arithmetic or as a line count.
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

# require_deps <command...>: every command must be installed and gh must be able
# to authenticate. gh auth status ignores token auth from the environment even
# though gh works with it, so a set token variable also counts as authenticated.
require_deps() {
    local cmd missing=()
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    [[ ${#missing[@]} -eq 0 ]] \
        || die "$EXIT_USAGE" "required command(s) not installed: ${missing[*]}" \
               "Install them and re-run."
    if ! gh auth status >/dev/null 2>&1 && [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]]; then
        die "$EXIT_USAGE" "gh is not authenticated." \
            "Run: gh auth login, or export GH_TOKEN / GITHUB_TOKEN."
    fi
}

# OWNER/REPO slugs derived from this checkout's git remotes; empty outside a repository.
# The `|| true` matters: git fails there, and callers run under set -euo pipefail.
local_repo_slugs() {
    git remote -v 2>/dev/null | awk '{print $2}' \
        | sed -E 's#/$##; s#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#' | sort -u || true
}
