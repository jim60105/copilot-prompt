# UnityRemote Command Reference

One command per line in `UnityRemote.txt`. Output lines land in `UnityRemote.result.txt` in input order; `ERROR <line>: <exception>` marks a failed line, remaining lines still run.

## Liveness / build

|Command|Result|Notes|
|---|---|---|
|`ping`|`pong HH:mm:ss gen=<n>`|Poller alive. `gen` resets on every domain reload: gen changed ⇒ recompile succeeded and NEW code is live; gen unchanged + `error CS` in `errors` ⇒ compile failed (old assembly still answering)|
|`refresh`|`refreshed`|`AssetDatabase.Refresh(ForceSynchronousImport)` — imports new/changed assets and triggers recompile|
|`busy`|`compiling` / `updating` / `idle`|The ONLY reliable compile gate: `refresh` returns before its triggered recompile starts, so same-batch `ping`/`errors` run on the OLD assembly. Poll `busy` until `idle`, then read `errors`.|
|`state`|`playing\|stopped t=<s> objs=<names>`|Play-mode probe. `objs` lists live MonoBehaviour type names — confirms your objects actually exist in the scene (your game-manager type present ⇒ your boot code ran).|
|`screenshot [relpath]`|`saved <relpath>` (synchronous), file at `<project>/<relpath>`, console logs `SHOT saved`|Synchronously renders the main camera (1280×720 RenderTexture, no MSAA — ReadPixels from an unresolved multisampled RT returns noise) into a PNG. Captures the GAME camera, not the editor UI, so no window-geometry cropping. See the occlusion caveat in SKILL.md: foreground sprites stay clean, but the background may be noise while the editor window is fully covered.|
|`record [sec] [fps]`|`recording … -> Recordings/shot (poll for Recordings/shot/done.txt)`; then frames + done.txt|Enters Play mode; after the domain reload, `UnityRemoteRecorder.cs` (deploy alongside the bridge) self-installs and grabs the Game-view backbuffer each frame: `Recordings/shot/frame_####.png` + `done.txt` (`frames=N fps=measured`), then stops Play. Assemble: `ffmpeg -framerate <fps> -i frame_%04d.png out.gif`. Requires assets/UnityRemoteRecorder.cs deployed or logs `RECERROR`.|
|`errors [n]`|last n console entries, first line each, or `console empty`|Internal `LogEntries` reflection; scan for `error CS…` and `Exception` text|
|`save`|`saved`|Save open scenes|

## Play mode

|Command|Result|Notes|
|---|---|---|
|`play`|`playing`|`EditorApplication.isPlaying = true`; domain reload follows|
|`stop`|`stopped`|Exit Play mode|

## Scene / selection

|Command|Result|Notes|
|---|---|---|
|`select <path-or-name>`|`selected <name>`|Asset path first, then hierarchy lookup (incl. inactive); frames it in Scene view|
|`deselect`|`deselected`||
|`focus <name> <yaw> <pitch> <dist>`|`focus <name> at <x,y,z>`|Scene camera orbits the object's renderer-bounds center|
|`scenecam <x y z yaw pitch dist>`|`scenecam set`|LookAt a world point|
|`tool move\|rotate\|scale\|view`|`tool <Tool>`|Active handle tool|

## Windows / visual

|Command|Result|Notes|
|---|---|---|
|`window <title>`|`focused <title>`|Match `titleContent.text`, case-insensitive: `Scene`, `Game`, `Inspector`, `Hierarchy`, `Project`, `Console`|
|`layout`|`pixelsPerPoint p` / `main x y w h` / `win <Title> x y w h docked=bool` rows|Screen-space rects for screenshot cropping; titles have spaces→underscores|
|`repaint`|`repainted`|Force all editor windows to redraw|

## Failure modes

- `ERROR unknown command: <cmd>` — typo or a command from a project-local bridge that this generic one lacks.
- `ERROR not found: <arg>` — `select`/`focus` matched neither asset path nor object name.
- `ERROR no Scene view` — no Scene window open; `window Scene` first.
- Command file lingers, no result — editor compiling/updating; wait.
- Command file gone, no result — domain reload consumed it mid-run; resend.
