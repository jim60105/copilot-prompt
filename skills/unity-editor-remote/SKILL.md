---
name: unity-editor-remote
description: >-
  Drive running Unity Editor from shell to verify compiles, playmode, scenes,
  screenshots. Use when editing C# scripts, scenes, or assets in a Unity project
  and needing to: (1) check compilation succeeds, (2) read console errors,
  (3) enter/exit Play mode, (4) capture screenshots or frame recordings,
  (5) select objects or aim the Scene camera, (6) query editor window layout.
  Injects a file-polling command bridge (UnityRemote.cs) — prefer this over
  batchmode (fights the Library lock) or GUI automation.
---

# Unity Editor Remote

Control a running Unity Editor via a file-polling command bridge. No window clicking, no second editor process.

## Protocol

Agent writes `<project>/UnityRemote.txt` (one command per line, `#` comments allowed). Editor polls every 0.5 s, executes lines, writes `<project>/UnityRemote.result.txt`, deletes the command file. Commands are skipped while compiling/updating — wait, never resend.

Full command list with argument formats: [references/commands.md](references/commands.md).

## Setup

1. **Detect bridge**: check `<project>/Assets/UnityRemote.cs`. Some projects ship their own variant — grep `Assets/**/Editor/*.cs` for a command-file poller before deploying.
2. **Deploy if missing**: copy `assets/UnityRemote.cs` (and `assets/UnityRemoteRecorder.cs` for `record`) into `Assets/`, then run `refresh` to import + compile. An unfocused editor defers asset import — if `refresh` times out, focus the editor window, then retry. Confirm with `ping`.
3. **Send commands**:

```sh
scripts/unity_cmd.sh <project-root> "ping"                  # single command
scripts/unity_cmd.sh <project-root> -t 600 "refresh" "ping" # batch with timeout
```

## Verification Loop (after code change)

```sh
U=<skill-dir>/scripts/unity_cmd.sh
$U "$P" --compile            # refresh → busy-poll until idle → console tail
                             # 'error CS' = fail; 'console empty' = clean
$U "$P" "play"               # enter Play mode
sleep 8                      # let systems tick
$U "$P" "state"              # playing? MonoBehaviours present? (objs=...)
$U "$P" "errors 50"          # runtime exceptions
$U "$P" "stop"
```

**Critical**: never trust `refresh`+`ping` as a compile gate. `refresh` returns before recompile starts — same-batch `ping`/`errors` answer from the OLD assembly. Use `--compile` (busy-poll + gen-change check).

## Visual Verification

`screenshot [relpath]` renders the main camera synchronously → PNG at `<project>/<relpath>`. Captures the Game camera, not editor chrome.

`record [sec] [fps]` enters Play mode, captures frames → `Recordings/shot/frame_####.png` + `done.txt`. Requires `assets/UnityRemoteRecorder.cs` deployed.

Use `layout` for window rects + `pixelsPerPoint` if cropping is needed. OS-level screen capture is unreliable — only use it for editor chrome itself.

**Telemetry pattern**: `errors` is the only data channel out of Play mode. Make runtime code log structured single-line events (e.g., `Debug.Log($"GAME round={r} score={s}")`), then grep `errors` output. Pass large `n` (50+) to avoid early entries scrolling out.

## Key Rules

- **One editor per project** — the running editor owns the Library lock. Never launch `-batchmode` on the same project.
- **Play mode = domain reload** — assemblies reload; bridge re-inits. Always `--compile` green first.
- **Bridge is editor-only** — never shipped in builds. Commit it or `.gitignore` per user preference.

For occlusion caveats, timeout behavior, domain-reload edge cases, and troubleshooting: see [references/caveats.md](references/caveats.md).
