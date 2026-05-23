# sd-webui / Forge API endpoint reference

All paths are relative to the server base URL (e.g. `http://localhost:7860`). Requests use `Content-Type: application/json`. Authentication, when enabled, is HTTP Basic (`-u user:pass`).

This document covers the endpoints actually used by this skill plus a few useful adjacent ones. The full surface area of the sd-webui API is larger — consult the running server's `/docs` (OpenAPI Swagger UI) for everything else.

## Connectivity / health

### `GET /sdapi/v1/samplers`

Lightweight "is the server up?" probe. Returns `200 OK` with an array of `{name, aliases, options}` once the server has finished loading. Used by `probe.sh`.

## Enumeration

### `GET /sdapi/v1/sd-models`

Returns the installed checkpoints:

```json
[
  {
    "title": "model.safetensors [a1b2c3d4]",
    "model_name": "model",
    "hash": "a1b2c3d4",
    "sha256": "...",
    "filename": "/path/to/model.safetensors",
    "config": null
  }
]
```

Use `title` (includes the hash suffix) as the value of `override_settings.sd_model_checkpoint` — that is the unambiguous identifier the server matches against.

### `GET /sdapi/v1/sd-modules` *(Forge-only)*

Forge-style extra modules (text encoders, VAE, etc.) that can be stacked at inference time:

```json
[{"model_name": "ae.safetensors", "filename": "..."}]
```

Pass an array of `model_name` strings as `override_settings.forge_additional_modules`. AUTOMATIC1111 vanilla returns 404 here.

### `GET /sdapi/v1/samplers`

```json
[{"name": "Euler a", "aliases": ["k_euler_a"], "options": {}}]
```

Use `name` as `sampler_name` in the txt2img request.

### `GET /sdapi/v1/schedulers`

```json
[{"name": "automatic", "label": "Automatic"}]
```

Use `label` (or `name`) as `scheduler` in the txt2img request. Vanilla AUTOMATIC1111 may not expose schedulers separately from samplers — in that case the endpoint returns an empty array and `scheduler` is ignored.

### `GET /sdapi/v1/prompt-styles`

```json
[{"name": "my-style", "prompt": "...", "negative_prompt": "..."}]
```

Use `name` (as an array element) in the `styles` field of the txt2img request.

### `GET /sdapi/v1/upscalers`

`[{"name": "Lanczos", "model_name": null, "model_path": null, "model_url": null, "scale": 4}]`

Used for `extras` API or `hr_upscaler` in HiRes-fix.

### `GET /sdapi/v1/loras`

LoRAs installed on the server. Reference them inline in prompts as `<lora:name:weight>`.

### `GET /sdapi/v1/embeddings`

`{"loaded": {...}, "skipped": {...}}` — textual inversion embeddings. Reference them in prompts by their key name.

## Generation

### `POST /sdapi/v1/txt2img`

Submits a text-to-image job. Synchronous: the request blocks until the image is generated. Body is the txt2img request JSON — see `txt2img-parameters.md`. Response:

```json
{
  "images": ["<base64 PNG>", "..."],
  "parameters": { "...": "echoed request" },
  "info": "<JSON-encoded string with seed, all_prompts, subseed, sampler_name, etc.>"
}
```

To get the seed: `jq -r '.info | fromjson | .seed'`.

### `POST /sdapi/v1/img2img`

Same structure as `txt2img` but additionally accepts `init_images` (array of base64-encoded source images) and `denoising_strength`. Not wrapped by a script in this skill — call directly with `curl` if needed.

## Progress / control

### `GET /sdapi/v1/progress?skip_current_image=true`

```json
{
  "progress": 0.42,
  "eta_relative": 3.7,
  "state": {
    "skipped": false,
    "interrupted": false,
    "job": "txt2img",
    "job_count": 1,
    "job_timestamp": "20240101000000",
    "job_no": 0,
    "sampling_step": 12,
    "sampling_steps": 28
  },
  "current_image": null,
  "textinfo": "..."
}
```

`skip_current_image=true` omits the base64 preview to keep responses small. Set to `false` to fetch the in-progress image.

`state.job` is the empty string when the server is idle.

### `POST /sdapi/v1/interrupt`

Body `{}` (or empty). Returns `{}`. Cooperatively stops the current sampler — the in-flight txt2img call returns normally with the partial result. Use to cancel a job.

### `POST /sdapi/v1/skip`

Body `{}`. Skips the current job in a batch (`job_count > 1`); subsequent jobs in the batch continue.

### `GET /queue/status`

Not under `/sdapi/v1/`. Returns the underlying Gradio queue layer status as an `EstimationMessage`:

```json
{
  "event_id": "...",
  "msg": "estimation",
  "queue_size": 0,
  "rank": null,
  "rank_eta": null
}
```

`queue_size` is the queue depth; `rank` / `rank_eta` are populated when the caller's request is queued behind others. Useful when multiple clients share the server. The reference plugin wraps this as `getQueueStatus()`. This skill does not provide a dedicated script — call directly:

```bash
curl -sS "${SD_WEBUI_URL}/queue/status"
```

## Options (global / persistent)

### `GET /sdapi/v1/options`

Returns a large flat JSON object of every setting in the UI. Notable keys:

- `sd_model_checkpoint` — active checkpoint `title`
- `samples_format` — `"png"` / `"jpg"` / `"webp"` etc.
- `CLIP_stop_at_last_layers` — clip-skip integer
- `sd_vae` — active VAE name or `"Automatic"`
- `eta_noise_seed_delta`

### `POST /sdapi/v1/options`

Body: a JSON object with one or more option keys to update. Returns `{}`. **Persists** across requests and affects every client connected to the server.

For request-scoped overrides, use `override_settings` inside the txt2img/img2img body together with `override_settings_restore_afterwards: true` (this skill does both).

### `POST /sdapi/v1/refresh-checkpoints`

Body `{}`. Tells the server to rescan its models folder. Useful after dropping a new `.safetensors` file in.

## Less-common but useful

| Method | Path | Purpose |
|---|---|---|
| GET | `/sdapi/v1/cmd-flags` | Server launch flags |
| GET | `/sdapi/v1/memory` | Free / used VRAM and RAM |
| POST | `/sdapi/v1/refresh-vae` | Rescan the VAE folder (there is **no** `GET /sdapi/v1/sd-vae` on Forge-classic; query active VAE via `/sdapi/v1/options` → `sd_vae`) |
| POST | `/sdapi/v1/png-info` | Read embedded generation parameters from a PNG |
| POST | `/sdapi/v1/extra-single-image` | Run an "extras" job (upscale / face restore) on one image |
| POST | `/sdapi/v1/extra-batch-images` | Same, for a batch |
| GET | `/sdapi/v1/face-restorers` | List face restorer models |
| GET | `/sdapi/v1/latent-upscale-modes` | List latent upscale modes (for HiRes-fix) |
| GET | `/sdapi/v1/scripts` / `/sdapi/v1/script-info` | List Always-On / Script-tab scripts + their argument schemas |
| POST | `/sdapi/v1/unload-checkpoint` | Free VRAM by unloading the current model |
| POST | `/sdapi/v1/refresh-loras` / `/sdapi/v1/refresh-embeddings` / `/sdapi/v1/refresh-checkpoints` | Rescan respective folders |

Note: vanilla AUTOMATIC1111 historically exposed `/sdapi/v1/hypernetworks` and `/sdapi/v1/sd-vae` (GET); both are absent on the current Forge-classic API surface. Always confirm against the running server:

```bash
curl -sS "${SD_WEBUI_URL}/openapi.json" | jq -r '.paths | keys[]'
```
