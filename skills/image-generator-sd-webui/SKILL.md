---
name: image-generator-sd-webui
description: Generate images via the Stable Diffusion WebUI / Forge HTTP API (AUTOMATIC1111-compatible `/sdapi/v1/*`). Use when the user wants to (1) discover or pick a model / extra module (TE/VAE) / sampler / scheduler / style preset from a running sd-webui server, (2) generate an image with a given prompt (txt2img), (3) check generation progress, (4) cancel/interrupt an in-flight generation, (5) inspect or change a global sd-webui option (e.g. active checkpoint), or (6) test connectivity. This skill talks to a *generic* sd-webui-compatible server (AUTOMATIC1111, Forge, reForge, sd-webui-forge-classic). Do NOT trigger for requests that are purely writing the prompt itself.
license: GFDL-1.3-or-later
---

# Image Generator (sd-webui API)

## Overview

Drive a Stable Diffusion WebUI / Forge server through its REST API to enumerate available resources, run `txt2img`, poll progress, and interrupt jobs. All scripts under `scripts/` are thin `curl` wrappers; they print JSON or extracted fields to stdout so the agent can pipe / parse them.

## Server connection

Before doing anything, confirm the server URL (and optional HTTP Basic Auth) with the user. Pass them as environment variables to every script:

```bash
export SD_WEBUI_URL="http://localhost:7860"   # required, no trailing slash
export SD_WEBUI_USER=""                       # optional, HTTP Basic Auth
export SD_WEBUI_PASS=""                       # optional
```

If unset, scripts default to `http://localhost:7860` with no auth.

Quick connectivity test (returns `OK <url>` on success, exits non-zero on failure):

```bash
scripts/probe.sh
```

## Workflow

1. **Probe** — Verify the server is reachable (`scripts/probe.sh`). On failure, ask the user for the correct URL / credentials.
2. **Enumerate & choose** — List the resources to pick (models, modules, samplers, schedulers, styles) and ask the user to choose. Capture their choice **verbatim** in the API's English `name` / `title` / `model_name` — sd-webui matches exactly, do not translate or rename.
3. **Prompt** — Obtain the positive prompt, negative prompt, and any extra params (steps, CFG, size). See "Prompt engineering" for sourcing these.
4. **Generate** — Call `scripts/generate.sh` with a request JSON. It returns a JSON object containing the base64 PNG image and the generation `info`.
5. **(Optional) Track progress** — While generation is running (in another shell / background), call `scripts/progress.sh` to print `progress` (0–1), `eta_relative`, and `state`.
6. **(Optional) Cancel** — Call `scripts/cancel.sh` to interrupt the current job.

## Tasks

### Listing available resources

| User wants | Command | API endpoint |
|---|---|---|
| Checkpoints (models) | `scripts/list.sh models` | `GET /sdapi/v1/sd-models` → array of `{title, model_name, hash, ...}` |
| Extra modules (TE / VAE, Forge-only) | `scripts/list.sh modules` | `GET /sdapi/v1/sd-modules` → array of `{model_name, ...}` |
| Samplers | `scripts/list.sh samplers` | `GET /sdapi/v1/samplers` → array of `{name, aliases}` |
| Schedulers | `scripts/list.sh schedulers` | `GET /sdapi/v1/schedulers` → array of `{name, label}` |
| Style presets | `scripts/list.sh styles` | `GET /sdapi/v1/prompt-styles` → array of `{name, prompt, negative_prompt}` |
| Upscalers | `scripts/list.sh upscalers` | `GET /sdapi/v1/upscalers` |
| LoRAs | `scripts/list.sh loras` | `GET /sdapi/v1/loras` |
| Embeddings | `scripts/list.sh embeddings` | `GET /sdapi/v1/embeddings` |

`scripts/list.sh <kind>` prints the canonical English identifier for each entry, one per line — pipe to `column`, `fzf`, etc. Add `--json` for the raw JSON.

After listing, present the options to the user (use `ask_user` with an enum if the list is short). For models, prefer the full `title` (which embeds the hash suffix, e.g. `anima/animaika_v36.safetensors [d50fb5b9a0]`) over `model_name` because the title is unambiguous — if the user supplies a bare filename without the hash, verify it via `list.sh models` and substitute the exact title before sending it to the API. For schedulers, `list.sh schedulers` prints the human-readable `label` (e.g. `Beta`); both `label` and the lowercase `name` (`beta`) are accepted by the txt2img `scheduler` field.

### Generating an image (txt2img)

1. Build a JSON request. Required field: `prompt`. Recommended: `negative_prompt`, `steps`, `cfg_scale`, `width`, `height`, `sampler_name`, `scheduler`, `styles` (array of style names), and `override_settings.sd_model_checkpoint` (model title) / `override_settings.forge_additional_modules` (array of module names, Forge only). See `references/txt2img-parameters.md` for every field.
2. Run:
   ```bash
   scripts/generate.sh request.json > result.json
   # or pipe:
   cat request.json | scripts/generate.sh - > result.json
   ```
3. Extract the image (base64 PNG):
   ```bash
   jq -r '.images[0]' result.json | base64 -d > out.png
   ```
4. The `info` field is a JSON string with `seed`, `all_prompts`, `sampler_name`, etc. — parse with `jq -r '.info | fromjson'`.

**Important behaviour notes:**

- **`samples_format` pre-pin**: sd-webui/Forge validates `samples_format` *before* applying `override_settings`, so if the server's persistent value is unsupported (e.g. `avif`), txt2img fails. `generate.sh` preemptively `POST`s `samples_format=png` to `/sdapi/v1/options` **and** redundantly injects `override_settings.samples_format=png`. ⚠️ The pre-pin mutates the server's persistent default to `"png"` — `override_settings_restore_afterwards` cannot undo it. If the user shares the server with clients expecting a different default, restore manually after: `scripts/options.sh set samples_format '"webp"'`. Convert locally if you need non-PNG output (see "Converting to another format" below).
- `override_settings_restore_afterwards: true` is forced on by `generate.sh` so the *other* `override_settings` keys (model checkpoint, modules, VAE) do not stick.
- Generation is **synchronous** — the POST blocks until the image is ready. The script uses a 600s curl timeout; override with `SD_WEBUI_TIMEOUT=900 scripts/generate.sh ...`.

#### Converting to another format

If the user wants the output in a non-PNG format (WebP, AVIF, JPEG, etc.), do **not** try to re-enable a different `samples_format` on the server. Instead, convert locally while preserving the embedded sd-webui generation metadata:

1. Check whether **both** `format-converter.sh` and `copy-info.sh` are available on `PATH` (e.g. `command -v format-converter.sh && command -v copy-info.sh`).
2. If both are present, run `format-converter.sh` on the PNG — it calls `copy-info.sh` internally to carry the parameters over. Run `format-converter.sh -h` to see the current usage.
3. If either is missing, guide the user to install the helper project once: <https://github.com/jim60105/sd-image-format-converter>. It has system dependencies that must be set up manually, so it can't be auto-installed. After install, both scripts should be on `PATH` and `-h` will show usage.

### Tracking progress

Call from another terminal (or background the `generate.sh` call with `&` first):

```bash
scripts/progress.sh                  # one-shot, prints JSON
scripts/progress.sh --watch          # poll every 1s until progress reaches 1.0 or state.job is empty
scripts/progress.sh --watch --interval 2
scripts/progress.sh --field progress # just the numeric 0..1 value
scripts/progress.sh --field state.job
```

Endpoint: `GET /sdapi/v1/progress?skip_current_image=true`. Key response fields:

- `progress` — float 0..1, fraction of current job complete.
- `eta_relative` — estimated seconds remaining.
- `state.job` — current job name (empty string when idle).
- `state.sampling_step` / `state.sampling_steps` — current step index / total.
- `current_image` — base64 PNG preview of the in-progress image (omitted by the script via `skip_current_image=true` to keep responses small; fetch raw with `curl` if needed).

### Cancelling

```bash
scripts/cancel.sh         # POST /sdapi/v1/interrupt — stop current job, return current partial result
scripts/cancel.sh --skip  # POST /sdapi/v1/skip — skip current job in a batch
```

Note: `interrupt` is *cooperative* — it tells the sampler to stop at the next step. The pending `generate.sh` call will return with whatever the model produced so far (often a usable but partial image). It does **not** raise an HTTP error on the txt2img call.

### Global options (advanced)

`scripts/options.sh` wraps `GET /sdapi/v1/options` and `POST /sdapi/v1/options`:

```bash
scripts/options.sh get                                # print all options as JSON
scripts/options.sh get sd_model_checkpoint            # print one key
scripts/options.sh set sd_model_checkpoint '"<title>"' # set one key (value is JSON; string must be quoted)
scripts/options.sh set-json '{"k1":"v1","k2":"v2"}'   # set multiple keys
scripts/options.sh refresh-checkpoints                # POST /sdapi/v1/refresh-checkpoints
```

Prefer `override_settings` inside the `txt2img` request over `options set` — `override_settings` is request-scoped and reverts after the call, while `options set` persists globally and affects every other client.

## Prompt engineering

This skill **does not** generate or refine prompts. When the user asks for prompt help:

1. Check whether another agent skill is available for prompt engineering (search by name: e.g. `sd-prompt-builder`, `danbooru-prompt`, `image-prompt-*`). If so, delegate to it.
2. Otherwise, ask the user for the prompt explicitly, or accept a natural-language description and pass it through verbatim as the `prompt` field. Do not invent Danbooru tags or stylistic modifiers on your own.

## References

- `references/api-endpoints.md` — full sd-webui / Forge endpoint reference with request / response shapes for every endpoint this skill uses, plus useful adjacent ones (`/sdapi/v1/memory`, `/sdapi/v1/png-info`, etc.).
- `references/txt2img-parameters.md` — every `txt2img` request field including HiRes-fix, refiner, Forge-specific extensions (`forge_additional_modules`, `forge_inference_memory`, `forge_preset`), and `override_settings` keys.

Read these only when constructing a non-trivial request or hitting an error that needs deeper investigation.
