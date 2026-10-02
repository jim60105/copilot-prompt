using System.Collections;
using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

/// <summary>
/// Runtime frame recorder (ships in the player assembly: no UnityEditor usage).
/// Spawned by UnityRemote.cs when a 'record' command enters Play mode.
/// Grabs the Game-view backbuffer each frame via ScreenCapture while the
/// player loop runs normally — no targetTexture (the 2D URP renderer mis-
/// clears backgrounds when a camera targets an offscreen RT). Real time:
/// done.txt reports measured fps.   ffmpeg -framerate <measured> -i ...
/// </summary>
public class UnityRemoteRecorder : MonoBehaviour
{
    public string dir = "Recordings/untitled";
    public float seconds = 4f;
    public int fps = 15;
    public int width = 640, height = 360;   // resize frame on write-back if Game view differs

    IEnumerator Run()
    {
        Application.runInBackground = true;
#if UNITY_EDITOR
        // An UNFOCUSED editor stops repainting the Game view, so every capture
        // path (RT ReadPixels, ScreenCapture backbuffer) reads stale garbage.
        // Drive repaints from inside: the windows repaint without OS focus.
        EditorApplication.update += RepaintGameViews;
#endif
        var cam = Camera.main;
        if (cam == null)
        {
            var all = Camera.allCameras;
            if (all.Length == 0) { Debug.LogError("RECERROR no camera in scene"); Stop(); yield break; }
            cam = all[0];
        }

        Directory.CreateDirectory(dir);

        float t0 = Time.realtimeSinceStartup;
        int total = Mathf.Max(1, Mathf.CeilToInt(seconds * 600f));  // runaway guard only; stop is time-based
        int i = 0;
        float nextCap = 0f;   // throttle PNG writes to 'fps'
        while (Time.realtimeSinceStartup - t0 < seconds && i < total)
        {
            // Let URP render the Game view exactly as it normally does.
            yield return new WaitForEndOfFrame();
            if (Time.realtimeSinceStartup < nextCap) continue;
            nextCap = t0 + (i + 1) / (float)fps;
            var shot = ScreenCapture.CaptureScreenshotAsTexture();
            File.WriteAllBytes(Path.Combine(dir, string.Format("frame_{0:D4}.png", i)), shot.EncodeToPNG());
            Destroy(shot);
            i++;
        }
        float measured = i > 1 ? (i - 1) / (Time.realtimeSinceStartup - t0) : fps;
#if UNITY_EDITOR
        EditorApplication.update -= RepaintGameViews;
#endif


        File.WriteAllText(Path.Combine(dir, "done.txt"),
            $"{System.DateTime.Now:HH:mm:ss} frames={i} fps={measured:0.#}");
        Debug.Log($"REC done {dir} frames={i} fps={measured:0.#}");
        Stop();
    }

    void Start() => StartCoroutine(Run());

#if UNITY_EDITOR
    static void RepaintGameViews()
    {
        foreach (var w in Resources.FindObjectsOfTypeAll<EditorWindow>())
            if (w.GetType().FullName == "UnityEditor.GameView") w.Repaint();
    }
#endif

    void Stop()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#endif
    }
}
