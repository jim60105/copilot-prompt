---
name: unity-editor-remote
description: Drive and verify a RUNNING Unity Editor from the shell without touching the GUI. Use when editing C# scripts, scenes, or assets in a Unity project and needing to verify changes — compile checks, console errors, Play-mode runs, scene camera control, object selection, window layout, screenshots. Injects the UnityRemote.cs command-file bridge into the project, then sends commands via unity_cmd.sh. Prefer this over batchmode (which fights the Library lock) or GUI automation.
---

# Unity Editor Remote

Control a running Unity Editor via a file-polling command bridge. No window clicking, no second editor process.

## Protocol

Bridge file `assets/UnityRemote.cs` (deploy to `<project>/Assets/UnityRemote.cs`, any Editor-accessible folder):

- Agent writes `<project>/UnityRemote.txt` — one command per line, `#` comments allowed.
- Editor polls every 0.5 s (`[InitializeOnLoad]` + `EditorApplication.update`), executes lines, writes `<project>/UnityRemote.result.txt`, deletes the command file.
- Commands are skipped (file left pending) while the editor is compiling/updating. Callers wait — never resend.

## Workflow

1. **Detect bridge**: `ls <project>/Assets/UnityRemote.cs` (or grep for a project-local equivalent — some projects ship their own variant, check `Assets/**/Editor/*.cs` for a command-file poller before deploying).
2. **Deploy if missing**: copy `assets/UnityRemote.cs` (and `assets/UnityRemoteRecorder.cs` if you'll use `record`) into `Assets/`, then `unity_cmd.sh <project> refresh` to import + compile it. Chicken-and-egg: the poller doesn't exist until the editor imports the script, and **an unfocused editor defers asset import indefinitely** — if `refresh` times out `pending`, focus the editor window (e.g. `hyprctl activewindow`/wm tools) or trigger any UI interaction; import fires on focus. Then `ping`.
3. **Send commands** with the bundled script (handles atomic write, result polling, timeout):

```sh
scripts/unity_cmd.sh <project-root> "ping"                  # single command
scripts/unity_cmd.sh <project-root> -t 600 "refresh" "ping" # batch: refresh then ping
```

**Never use `refresh`+`ping` as the compile gate**: `AssetDatabase.Refresh` returns
before the recompile it triggers even starts, so a same-batch `ping` answers from the
OLD assembly. The gate is `busy` — poll until `idle`, then read `errors`. The script
bakes this into `--compile`.

## Verification loop after a code change

```sh
U=<skill-dir>/scripts/unity_cmd.sh
$U "$P" --compile            # refresh → poll busy until idle → console tail
                             # look for 'error CS' lines; 'console empty' = clean
$U "$P" "play"               # behavior check (project scripts run live)
sleep 8                      # let systems tick
$U "$P" "state"              # playing? your MonoBehaviours present? (objs=...)
$U "$P" "errors 50"          # runtime exceptions + telemetry show up here
$U "$P" "stop"
```

**Telemetry pattern**: `errors` is the only data channel out of play mode, so make
runtime code log structured single-line events, e.g. `Debug.Log($"GAME round={r} score={s}")`,
then `grep` the `errors` output. Console keeps a bounded entry list — pass a large
`n` (50+) or exceptions that fired early scroll out of the tail window.

Visual checks: use `screenshot [relpath]` — the bridge renders the main camera synchronously and answers `saved <relpath>` with the PNG at `<project>/<relpath>`. It captures the Game camera, so no window-geometry cropping. OS-level screen capture (`grim`, KWin scripting) proved flaky in practice; only reach for it when you must see the editor chrome itself (`layout` gives window rects + `pixelsPerPoint` for cropping).

**Occlusion caveat (Wayland/KWin, likely other compositors)**: when the editor window is FULLY covered, the compositor stops feeding it frames — Unity skips full-frame composition and every in-editor pixel grab (`screenshot`, `record`, and `ScreenCapture`) captures uninitialized memory: foreground sprites render fine, background = TV snow. Telemetry commands (`state`, `errors`, `ping`) are unaffected. Fix: make the window at least partially visible (unminimize, don't leave it on another virtual desktop, or set keep-above). KWin scripting exists in `scripts/kwin_focus_unity.js` but KWin5/6 script APIs differ enough that WM-specific focus code is unreliable — prefer asking the user to surface the window, and verify with one `screenshot` before a long `record`.

Full command list with argument formats: see `references/commands.md`.

## Caveats

- **One editor per project**: the running editor owns the Library lock. Never launch `-batchmode` on the same project meanwhile.
- **`refresh` triggers an async recompile**: the gate is `--compile` (busy-poll + `gen=` change proving a domain reload landed). Never trust same-batch `ping`/`errors` right after `refresh` — they answer from the OLD assembly (`console empty` on broken code is the trap).
- **Play mode = domain reload**: entering play reloads assemblies; the bridge re-inits and answers, but scene state resets. Entering play with a compile error silently keeps the old game running — always `--compile` green first.
- **Domain reloads kill the poller mid-command**: long operations (scene `build`, lighting bake) return immediately and keep running; poll the console or output artifacts for completion instead of blocking.
- **Timeouts are normal during import/bake** — the script prints `TIMEOUT ... command file: pending|consumed`; pending means still busy, consumed-without-result means a reload clobbered execution. Resend after it settles.
- **Behavior verification is project-dependent**: the bridge only gives play/stop/console/screenshot. Whether the project has recording tools, test assemblies, or headless logic hooks varies — inspect `Assets/**/Editor/` and `Packages/manifest.json` first.
- Bridge code is editor-only (`UnityEditor`), never shipped in builds, but it does sit in version control — commit it or `.gitignore` it per user preference.
