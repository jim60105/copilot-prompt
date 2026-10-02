using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

/// <summary>
/// File-polling remote control so an external agent can drive a RUNNING editor
/// without batchmode (which would fight the Library lock) or GUI clicking.
///
/// Protocol: agent writes <project root>/UnityRemote.txt (one command per
/// line, '#' comments allowed). This polls every 0.5 s, executes each line,
/// writes <project root>/UnityRemote.result.txt and deletes the command file.
/// Commands are skipped while compiling/updating, so the command file may
/// linger briefly — the caller must keep polling, not resend.
///
/// Commands:
///   ping                          -> pong <time>   (also: compile finished)
///   refresh                       synchronous asset import + recompile
///   busy                          "compiling"/"updating" while editor is busy, else "idle"
///   state                         "playing time=..s" / "stopped" (+compile/update flags)
///   screenshot [relpath]          render main camera -> PNG (sync), returns path
///   record [sec] [fps]            fixed-framerate frame capture in Play mode -> Recordings/
///   errors [n]                    last n console entries (default 30), empty = clean
///   save                          save open scenes
///   play / stop                   enter / leave Play mode
///   select <path|name>            select hierarchy object or asset, frame it in Scene
///   deselect
///   focus <name> <yaw> <pitch> <dist>   aim Scene camera at object bounds
///   scenecam <x y z yaw pitch dist>     aim Scene camera at a point
///   tool move|rotate|scale|view
///   window <title>                focus editor window (Scene, Game, Inspector, Console...)
///   layout                        editor window rects + pixelsPerPoint (for screenshot cropping)
///   repaint
/// </summary>
[InitializeOnLoad]
public static class UnityRemote
{
    const string CommandFile = "UnityRemote.txt";
    const string ResultFile = "UnityRemote.result.txt";
    static double nextCheck;
    // Survives nothing: re-inits to 0 on every domain reload, so ping's gen
    // increasing proves a reload (successful recompile) happened.
    static readonly int Gen = Environment.TickCount;

    // Pending 'record': play mode reloads assemblies, so the recorder object
    // must be spawned AFTER the reload, from playModeStateChanged.
    const string RecKey = "UnityRemote_Record";

    static UnityRemote()
    {
        EditorApplication.update -= Poll;
        EditorApplication.update += Poll;
        EditorApplication.playModeStateChanged -= OnPlayModeChange;
        EditorApplication.playModeStateChanged += OnPlayModeChange;
    }

    static void OnPlayModeChange(PlayModeStateChange change)
    {
        if (change != PlayModeStateChange.EnteredPlayMode) return;
        var spec = SessionState.GetString(RecKey, "");
        if (spec == "") return;
        SessionState.EraseString(RecKey);
        var t = System.Type.GetType("UnityRemoteRecorder, Assembly-CSharp");
        if (t == null) { Debug.LogError("RECERROR deploy assets/UnityRemoteRecorder.cs into Assets/ first"); return; }
        var go = new GameObject("__UnityRemoteRecorder");
        var rec = go.AddComponent(t);
        var a = spec.Split(' ');
        if (a.Length > 0) t.GetField("seconds").SetValue(rec, float.Parse(a[0], System.Globalization.CultureInfo.InvariantCulture));
        if (a.Length > 1) t.GetField("fps").SetValue(rec, int.Parse(a[1]));
        t.GetField("dir").SetValue(rec, "Recordings/shot");
    }

    static void Poll()
    {
        if (EditorApplication.timeSinceStartup < nextCheck) return;
        nextCheck = EditorApplication.timeSinceStartup + 0.5;
        if (!File.Exists(CommandFile)) return;
        if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;

        string[] lines;
        try { lines = File.ReadAllLines(CommandFile); File.Delete(CommandFile); }
        catch { return; }   // partial write or lock: retry next tick

        var result = new StringBuilder();
        foreach (var raw in lines)
        {
            var line = raw.Trim();
            if (line.Length == 0 || line.StartsWith("#")) continue;
            try { result.AppendLine(Run(line)); }
            catch (Exception e) { result.AppendLine($"ERROR {line}: {e.Message}"); Debug.LogException(e); }
        }
        File.WriteAllText(ResultFile, result.ToString());
    }

    static string Run(string line)
    {
        var parts = line.Split(new[] { ' ' }, 2);
        string cmd = parts[0].ToLowerInvariant();
        string arg = parts.Length > 1 ? parts[1].Trim() : "";

        switch (cmd)
        {
            case "ping": return $"pong {DateTime.Now:HH:mm:ss} gen={Gen}";

            case "refresh":
                AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
                return "refreshed";

            // Refresh returns before the compile it triggers starts; poll this until "idle".
            case "busy":
                if (EditorApplication.isCompiling) return "compiling";
                if (EditorApplication.isUpdating) return "updating";
                return "idle";

            case "state":
                return (EditorApplication.isPlaying ? "playing" : "stopped")
                    + $" t={Time.time:0}s"
                    + $" objs={string.Join(",", UnityEngine.Object.FindObjectsByType<MonoBehaviour>(FindObjectsSortMode.None).Select(m => m.GetType().Name).Distinct())}"
                    + (EditorApplication.isCompiling ? " compiling" : "")
                    + (EditorApplication.isUpdating ? " updating" : "");

            case "screenshot":
                return Screenshot(arg);

            // Async: enters play mode, recorder self-installs after the reload,
            // writes Recordings/shot/frame_*.png + done.txt, then stops play.
            // Poll for done.txt — the result line lands before recording runs.
            case "record":
            {
                var a = arg.Split(' ');
                float sec = a.Length > 0 && a[0].Length > 0 ? float.Parse(a[0], System.Globalization.CultureInfo.InvariantCulture) : 4f;
                int fps = a.Length > 1 && a[1].Length > 0 ? int.Parse(a[1]) : 15;
                SessionState.SetString(RecKey, $"{sec} {fps}");
                EditorApplication.isPlaying = true;
                return $"recording {sec}s @{fps}fps -> Recordings/shot (poll for Recordings/shot/done.txt)";
            }

            case "errors": return ConsoleTail(arg.Length == 0 ? 30 : int.Parse(arg));

            case "save":
                EditorSceneManager.SaveOpenScenes();
                return "saved";

            case "play": EditorApplication.isPlaying = true; return "playing";
            case "stop": EditorApplication.isPlaying = false; return "stopped";

            case "layout": return Layout();

            case "select":
            {
                UnityEngine.Object obj = AssetDatabase.LoadMainAssetAtPath(arg);
                if (obj == null)
                {
                    var go = GameObject.Find(arg);
                    if (go == null)
                        go = UnityEngine.SceneManagement.SceneManager.GetActiveScene().GetRootGameObjects()
                            .SelectMany(r => r.GetComponentsInChildren<Transform>(true))
                            .FirstOrDefault(t => t.name == arg)?.gameObject;
                    obj = go;
                }
                if (obj == null) return "ERROR not found: " + arg;
                Selection.activeObject = obj;
                if (obj is GameObject g && SceneView.lastActiveSceneView != null)
                {
                    SceneView.lastActiveSceneView.Focus();
                    SceneView.lastActiveSceneView.FrameSelected();
                }
                EditorGUIUtility.PingObject(obj);
                return "selected " + obj.name;
            }

            case "deselect": Selection.activeObject = null; return "deselected";

            case "tool":
                switch (arg.ToLowerInvariant())
                {
                    case "move": Tools.current = Tool.Move; break;
                    case "rotate": Tools.current = Tool.Rotate; break;
                    case "scale": Tools.current = Tool.Scale; break;
                    default: Tools.current = Tool.View; break;
                }
                SceneView.RepaintAll();
                return "tool " + Tools.current;

            case "scenecam":
            {
                var v = Parse(arg);
                var sv = SceneView.lastActiveSceneView;
                if (sv == null) return "ERROR no Scene view";
                sv.LookAtDirect(new Vector3(v[0], v[1], v[2]), Quaternion.Euler(v[4], v[3], 0f), v[5]);
                sv.Repaint();
                return "scenecam set";
            }

            case "focus":   // focus <name> <yaw> <pitch> <dist>
            {
                var a = arg.Split(' ');
                var t = UnityEngine.SceneManagement.SceneManager.GetActiveScene().GetRootGameObjects()
                    .SelectMany(r => r.GetComponentsInChildren<Transform>(true)).FirstOrDefault(x => x.name == a[0]);
                if (t == null) return "ERROR not found: " + a[0];
                var rs = t.GetComponentsInChildren<Renderer>();
                var center = t.position;
                if (rs.Length > 0) { var b = rs[0].bounds; foreach (var r in rs) b.Encapsulate(r.bounds); center = b.center; }
                var f = Parse(string.Join(" ", a.Skip(1)));
                var sv = SceneView.lastActiveSceneView;
                if (sv == null) return "ERROR no Scene view";
                sv.LookAtDirect(center, Quaternion.Euler(f[1], f[0], 0f), f[2]);
                sv.Repaint();
                return $"focus {t.name} at {center}";
            }

            case "window":
            {
                var w = Resources.FindObjectsOfTypeAll<EditorWindow>()
                    .FirstOrDefault(x => x.titleContent.text.Equals(arg, StringComparison.OrdinalIgnoreCase));
                if (w == null) return "ERROR no window: " + arg;
                w.Focus(); w.Repaint();
                return "focused " + arg;
            }

            case "repaint":
                foreach (var w in Resources.FindObjectsOfTypeAll<EditorWindow>()) w.Repaint();
                return "repainted";
        }
        return "ERROR unknown command: " + cmd;
    }

    static string Screenshot(string arg)
    {
        var cam = Camera.main;
        if (cam == null)
        {
            var all = Camera.allCameras;
            if (all.Length == 0) return "ERROR no camera in scene";
            cam = all[0];
        }
        var path = arg.Length == 0 ? "UnityRemote_shot.png" : arg;
        // Synchronous Render(): waiting for the player loop is unreliable —
        // an unfocused editor doesn't render at all, leaving the RT garbage.
        var rt = new RenderTexture(1280, 720, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB) { antiAliasing = 4 };
        var prevTarget = cam.targetTexture;
        var prevEnabled = cam.enabled;
        cam.enabled = false;
        cam.targetTexture = rt;
        // URP skips the background clear for offscreen Render() targets:
        // pre-clear with the camera background or the sky is RT garbage.
        var preActive = RenderTexture.active;
        RenderTexture.active = rt;
        GL.Clear(true, true, cam.backgroundColor);
        RenderTexture.active = preActive;
        cam.Render();
        var tex = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
        var prevActive = RenderTexture.active;
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        tex.Apply();
        RenderTexture.active = prevActive;
        cam.targetTexture = prevTarget;
        cam.enabled = prevEnabled;
        File.WriteAllBytes(path, tex.EncodeToPNG());
        UnityEngine.Object.DestroyImmediate(rt);
        UnityEngine.Object.DestroyImmediate(tex);
        Debug.Log("SHOT saved " + path);
        return "saved " + path;
    }

    static float[] Parse(string s) =>
        s.Split(' ').Where(x => x.Length > 0)
         .Select(x => float.Parse(x, System.Globalization.CultureInfo.InvariantCulture)).ToArray();

    /// <summary>
    /// Last n console lines via internal LogEntries APIs (stable 2019.1-2023.x).
    /// GetEntryInternal requires StartGettingEntries first. Raw first lines:
    /// compile failures show "error CS…".
    /// </summary>
    static string ConsoleTail(int n)
    {
        try
        {
            // Visibility of these internals varies across versions: match both.
            const BindingFlags F = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
            var t = Type.GetType("UnityEditor.LogEntries,UnityEditor");
            var entryType = Type.GetType("UnityEditor.LogEntry,UnityEditor");
            if (t == null || entryType == null) return "ERROR console API unavailable";

            int count = (int)t.GetMethod("StartGettingEntries", F).Invoke(null, null);

            var getM = t.GetMethod("GetEntryInternal", F);
            var msgF = entryType.GetField("message", BindingFlags.Instance | BindingFlags.Public);
            var sb = new StringBuilder();
            for (int i = Math.Max(0, count - n); i < count; i++)
            {
                var e = Activator.CreateInstance(entryType);
                var ret = getM.Invoke(null, new object[] { i, e });
                if (ret is bool b && !b) continue;
                // NOTE: plain Debug.Log entries legitimately have instanceID 0.
                // A failed read leaves message null/empty, so that's the gate.
                var msg = (string)msgF.GetValue(e);
                if (!string.IsNullOrEmpty(msg)) sb.AppendLine("  " + msg.Trim().Split('\n')[0]);
            }
            t.GetMethod("EndGettingEntries", F).Invoke(null, null);
            return sb.Length == 0 ? "console empty" : sb.ToString().TrimEnd();
        }
        catch (Exception e) { return "ERROR console read failed: " + e.Message; }
    }

    static string Layout()
    {
        var sb = new StringBuilder();
        var main = EditorGUIUtility.GetMainWindowPosition();
        sb.AppendLine($"pixelsPerPoint {EditorGUIUtility.pixelsPerPoint}");
        sb.AppendLine($"main {main.x} {main.y} {main.width} {main.height}");
        foreach (var w in Resources.FindObjectsOfTypeAll<EditorWindow>())
        {
            var r = w.position;
            if (r.width < 10) continue;
            sb.AppendLine($"win {w.titleContent.text.Replace(' ', '_')} {r.x} {r.y} {r.width} {r.height} docked={w.docked}");
        }
        return sb.ToString().TrimEnd();
    }
}
