# UnityRemote Command Reference

One command per line in `UnityRemote.txt`. Output lines land in `UnityRemote.result.txt` in input order. `ERROR <line>: <exception>` marks a failed line; remaining lines still run.

## Liveness / Build

| Command | Result | Notes |
|---|---|---|
| `ping` | `pong HH:mm:ss gen=<n>` | `gen` resets on every domain reload. gen changed → new code live; gen unchanged + `error CS` → compile failed (old assembly answering). |
| `refresh` | `refreshed` | `AssetDatabase.Refresh(ForceSynchronousImport)`. Returns before recompile starts — see [caveats.md](caveats.md) for compile gate details. |
| `busy` | `compiling` / `updating` / `idle` | The reliable compile gate. Poll until `idle`, then read `errors`. |
| `state` | `playing\|stopped t=<s> objs=<names>` | `objs` lists live MonoBehaviour type names — confirms objects exist in scene. |
| `errors [n]` | last n console entries or `console empty` | Default 30. Scan for `error CS…` and `Exception`. |
| `save` | `saved` | Save open scenes. |

## Play Mode

| Command | Result | Notes |
|---|---|---|
| `play` | `playing` | Domain reload follows. |
| `stop` | `stopped` | Exit Play mode. |

## Visual Capture

| Command | Result | Notes |
|---|---|---|
| `screenshot [relpath]` | `saved <relpath>` | Synchronous main-camera render (1280×720, no MSAA) → PNG at `<project>/<relpath>`. Captures Game camera, not editor UI. See [caveats.md](caveats.md) for occlusion issues. |
| `record [sec] [fps]` | `recording … -> Recordings/shot` | Enters Play; `UnityRemoteRecorder.cs` captures frames → `frame_####.png` + `done.txt`. Assemble: `ffmpeg -framerate <fps> -i frame_%04d.png out.gif`. Requires `assets/UnityRemoteRecorder.cs` deployed. |

## Scene / Selection

| Command | Result | Notes |
|---|---|---|
| `select <path-or-name>` | `selected <name>` | Asset path first, then hierarchy lookup (incl. inactive); frames it in Scene view. |
| `deselect` | `deselected` | |
| `focus <name> <yaw> <pitch> <dist>` | `focus <name> at <x,y,z>` | Scene camera orbits object's renderer-bounds center. |
| `scenecam <x y z yaw pitch dist>` | `scenecam set` | LookAt a world point. |
| `tool move\|rotate\|scale\|view` | `tool <Tool>` | Active handle tool. |

## Windows / Layout

| Command | Result | Notes |
|---|---|---|
| `window <title>` | `focused <title>` | Case-insensitive match on `titleContent.text`: `Scene`, `Game`, `Inspector`, `Hierarchy`, `Project`, `Console`. |
| `layout` | `pixelsPerPoint p` / `main x y w h` / `win <Title> x y w h docked=bool` rows | Screen-space rects for screenshot cropping. Titles use spaces→underscores. |
| `repaint` | `repainted` | Force all editor windows to redraw. |

## Error Patterns

| Symptom | Cause | Action |
|---|---|---|
| `ERROR unknown command: <cmd>` | Typo or project-local bridge variant | Check spelling against this reference. |
| `ERROR not found: <arg>` | `select`/`focus` matched nothing | Verify asset path or object name. |
| `ERROR no Scene view` | No Scene window open | Send `window Scene` first. |
| Command file lingers, no result | Editor compiling/updating | Wait; see [caveats.md](caveats.md). |
| Command file gone, no result | Domain reload consumed it mid-run | Resend after editor settles. |
