# Caveats & Troubleshooting

## Occlusion (Wayland/KWin)

When the editor window is FULLY covered, the compositor stops feeding it frames. Unity skips full-frame composition and every in-editor pixel grab (`screenshot`, `record`, `ScreenCapture`) captures uninitialized memory: foreground sprites render fine, background = noise/snow.

Telemetry commands (`state`, `errors`, `ping`) are unaffected.

**Fix**: make the window at least partially visible — unminimize, don't leave it on another virtual desktop, or set keep-above. Verify with one `screenshot` before a long `record`.

A KWin focus script exists at `scripts/kwin_focus_unity.js` but KWin5/6 script APIs differ enough that WM-specific focus code is unreliable. Prefer asking the user to surface the window.

## Compile Gate Timing

`AssetDatabase.Refresh` returns before the recompile it triggers even starts. A same-batch `ping` answers from the OLD assembly — `console empty` on broken code is the classic trap.

The reliable gate is `--compile` in `unity_cmd.sh`, which:
1. Records the current `gen` value from `ping`
2. Sends `refresh`
3. Polls `busy` until two consecutive `idle` results (covers the gap between refresh returning and compilation actually starting)
4. Checks whether `gen` changed (domain reload = new code live)
5. Reads `errors` for `error CS` lines

**No-change refresh**: `idle` + gen unchanged + no `error CS` = still clean (no recompile needed).

## Domain Reloads

- Entering Play mode reloads assemblies. The bridge re-inits and answers, but scene state resets.
- Entering Play with a compile error silently keeps the old game running — always `--compile` green first.
- Domain reloads kill the poller mid-command. Long operations (`build`, lighting bake) return immediately and keep running — poll the console or output artifacts for completion instead of blocking.

## Timeouts

Timeouts are normal during import/bake. The script prints:

```
TIMEOUT after Ns; command file: pending|consumed, result: none
```

- **pending** — editor still busy (compiling/updating/baking)
- **consumed without result** — a domain reload clobbered execution mid-run

Resend the command after the editor settles. Default timeout is 180 s; override with `-t <seconds>`.

## Behavior Verification

The bridge only provides play/stop/console/screenshot. Whether the project has recording tools, test assemblies, or headless logic hooks varies. Inspect `Assets/**/Editor/` and `Packages/manifest.json` first.

## Bridge Deployment

- Bridge code is editor-only (`UnityEditor` namespace), never shipped in builds.
- It sits in version control — commit it or `.gitignore` per user preference.
- The chicken-and-egg problem on first deploy: the poller doesn't exist until the editor imports the script, and an unfocused editor defers asset import indefinitely. If `refresh` times out with `pending`, focus the editor window (or trigger any UI interaction); import fires on focus.
