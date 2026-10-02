#!/bin/sh
# Drive a running Unity Editor via the UnityRemote command-file protocol.
#
# Usage: unity_cmd.sh <project-root> [-t timeout] "cmd line 1" ["cmd line 2" ...]
#        echo -e 'ping\nsave' | unity_cmd.sh <project-root>
#        unity_cmd.sh <project-root> --compile      # refresh, wait until the
#            # recompile it triggers finishes, then print console tail (errors)
#
# Writes <project-root>/UnityRemote.txt, waits for UnityRemote.result.txt,
# prints the result, removes it. The editor skips commands while compiling or
# updating, so the command file may linger; keep waiting until timeout.
set -eu

ROOT=${1:?usage: unity_cmd.sh <project-root> [-t timeout] cmd...}; shift
TIMEOUT=180
if [ "${1:-}" = "-t" ]; then TIMEOUT=$2; shift 2; fi

CMD="$ROOT/UnityRemote.txt"
RES="$ROOT/UnityRemote.result.txt"
[ -d "$ROOT" ] || { echo "no such project root: $ROOT" >&2; exit 2; }
[ -f "$ROOT/Assets/UnityRemote.cs" ] || echo "warn: UnityRemote.cs not deployed in $ROOT/Assets" >&2

# Compile gate. Signals combined:
#   gen (from ping) changes  => domain reloaded => NEW code is live
#   busy goes idle           => editor settled
#   errors shows 'error CS'  => compile FAILED (gen unchanged, code is old)
# No-change refresh: idle + gen unchanged + no 'error CS' => still clean.
if [ "${1:-}" = "--compile" ]; then
    base=$("$0" "$ROOT" -t 60 "ping" | head -1 | grep -o 'gen=[0-9-]*' | cut -d= -f2) || exit 1
    "$0" "$ROOT" -t "$TIMEOUT" "refresh" >/dev/null
    cend=$(( $(date +%s) + TIMEOUT ))
    settled=0
    while :; do
        sleep 1
        b=$("$0" "$ROOT" -t 60 "busy" 2>/dev/null | head -1) || exit 1
        if [ "$b" = "idle" ]; then
            # require two consecutive idles spaced 2s apart: covers the gap
            # between refresh returning and compilation actually starting
            [ "$settled" = 1 ] && break
            settled=1; sleep 2
        else
            settled=0
        fi
        [ "$(date +%s)" -ge "$cend" ] && { echo "TIMEOUT waiting for compile (last: $b)" >&2; exit 1; }
    done
    after=$("$0" "$ROOT" -t 60 "ping" | head -1 | grep -o 'gen=[0-9-]*' | cut -d= -f2)
    [ "$after" = "$base" ] && echo "note: no domain reload (gen=$base) — no changes compiled, or compile failed" || echo "reloaded gen=$base->$after: new code live"
    errs=$("$0" "$ROOT" -t 60 "errors 30")
    echo "$errs"
    echo "$errs" | grep -qi "error CS" && { echo "COMPILE FAILED" >&2; exit 3; }
    exit 0
fi

if [ $# -gt 0 ]; then printf '%s\n' "$@" >"$CMD".tmp
else cat >"$CMD".tmp; fi
mv -f "$CMD".tmp "$CMD"   # atomic: editor never reads a partial file

end=$(( $(date +%s) + TIMEOUT ))
while [ ! -f "$RES" ]; do
    if [ "$(date +%s)" -ge "$end" ]; then
        echo "TIMEOUT after ${TIMEOUT}s; command file: $([ -f "$CMD" ] && echo pending || echo consumed), result: none" >&2
        echo "editor likely busy (compiling/bake/domain reload) or not running with this project" >&2
        exit 1
    fi
    sleep 0.5
done

cat "$RES"; rm -f "$RES"
