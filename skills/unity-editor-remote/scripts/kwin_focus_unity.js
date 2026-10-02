// Make the Unity editor window VISIBLE on the current virtual desktop.
// Wayland/KWin occlusion-suspends fully covered windows: Unity then skips
// rendering and every in-editor capture (RT ReadPixels, ScreenCapture) reads
// uninitialized memory = snow. keepAbove + same-desktop is what unblocks it.
var wins = workspace.windowList();
var hit = null;
for (var i = 0; i < wins.length; i++) {
    var w = wins[i];
    if (w.caption && w.caption.indexOf("Unity") >= 0 && w.caption.indexOf("project") >= 0) {
        try { w.minimized = false; } catch (e) {}
        try { w.keepAbove = true; } catch (e) {}
        hit = w;
    }
}
if (hit) {
    // KWin5 scripting: activation via workspace.activeWindow setter.
    try { workspace.currentDesktop = hit.desktop; } catch (e) {}
    try { workspace.activeWindow = hit; print("activated unity on desktop " + hit.desktop); } catch (e) { print("activate failed: " + e); }
} else {
    print("unity window not found");
}
