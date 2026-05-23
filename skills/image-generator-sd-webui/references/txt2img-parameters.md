# `txt2img` request parameters

Body of `POST /sdapi/v1/txt2img`. Only `prompt` is strictly required; everything else has a server-side default. Numeric defaults shown match AUTOMATIC1111 / Forge stock behaviour and may differ on your server depending on `/sdapi/v1/options`.

## Core

| Field | Type | Default | Notes |
|---|---|---|---|
| `prompt` | string | — | Positive prompt. **Required.** |
| `negative_prompt` | string | `""` | Negative prompt. |
| `seed` | integer | `-1` | `-1` = random; otherwise a 64-bit signed seed. The actual seed used is echoed in the response `info` JSON. |
| `subseed` | integer | `-1` | Variation seed. |
| `subseed_strength` | number | `0` | Variation strength, 0..1. |
| `seed_resize_from_h` | integer | `0` | Resize-seed-from height. `0` to disable. |
| `seed_resize_from_w` | integer | `0` | Resize-seed-from width. `0` to disable. |
| `sampler_name` | string | `"Euler"` | Must match a name returned by `GET /sdapi/v1/samplers`. |
| `scheduler` | string | `"Automatic"` | Must match a `label`/`name` from `GET /sdapi/v1/schedulers`. Forge-only; ignored on vanilla. |
| `steps` | integer | `20` | Sampling steps. Quality plateaus quickly past 30–40 for most samplers. |
| `cfg_scale` | number | `7.0` | Classifier-free-guidance scale. Higher = stronger prompt adherence, lower = more creative. SDXL works best around 4–7; SD1.5 around 7–12. |
| `distilled_cfg_scale` | number | `3.5` | Distilled-CFG (Forge-classic, used by Flux and other distilled models). Ignored for non-distilled checkpoints. |
| `width` | integer | `512` | Multiples of 8. SDXL native: 1024×1024 (or 832×1216 portrait). |
| `height` | integer | `512` | Same constraints as width. |
| `batch_size` | integer | `1` | Images generated in parallel per job. |
| `n_iter` | integer | `1` | Number of jobs (sequential). Total images = `batch_size * n_iter`. |
| `styles` | string[] | `[]` | Names from `GET /sdapi/v1/prompt-styles`. Server prepends/appends the matching prompt/negative. |
| `tiling` | boolean | `false` | Generate a tileable texture. |
| `restore_faces` | boolean | `false` | Run face-restoration post-processing. |
| `do_not_save_samples` | boolean | `false` | Don't save the image to the server's output dir. |
| `do_not_save_grid` | boolean | `false` | Don't save a grid image. |

## HiRes-fix

| Field | Type | Default | Notes |
|---|---|---|---|
| `enable_hr` | boolean | `false` | Enable HiRes-fix two-stage upscale. |
| `hr_scale` | number | `2.0` | Upscale factor. |
| `hr_upscaler` | string | `"Latent"` | Name from `GET /sdapi/v1/upscalers`. |
| `hr_second_pass_steps` | integer | `0` | `0` = same as `steps`. |
| `denoising_strength` | number | `0.7` | Denoising for the second pass. |
| `hr_resize_x` / `hr_resize_y` | integer | `0` | Explicit target resolution. `0` = derived from `hr_scale`. |
| `hr_sampler_name` | string | `""` | Second-pass sampler. Empty = same as `sampler_name`. |
| `hr_scheduler` | string | `""` | Second-pass scheduler (Forge-classic). |
| `hr_prompt` / `hr_negative_prompt` | string | `""` | Optional override for the second pass. Empty = reuse the original. |
| `hr_checkpoint_name` | string | `""` | Second-pass model checkpoint (Forge-classic). Empty = same as first pass. |
| `hr_additional_modules` | string[] | `[]` | Second-pass `forge_additional_modules` (Forge-classic). Empty = same as first pass. |
| `hr_cfg` / `hr_distilled_cfg` | number | `0` | Second-pass CFG / distilled-CFG (Forge-classic). `0` = same as first pass. |

## Refiner (SDXL)

| Field | Type | Default | Notes |
|---|---|---|---|
| `refiner_checkpoint` | string | `""` | Refiner checkpoint `title`. |
| `refiner_switch_at` | number | `0` | 0..1 — fraction of total steps at which to swap to the refiner. |

## `override_settings`

Object whose keys are entries from `GET /sdapi/v1/options`. Applied only for this request when `override_settings_restore_afterwards: true` (recommended — always set this).

Most commonly used keys:

| Key | Type | Notes |
|---|---|---|
| `sd_model_checkpoint` | string | Active checkpoint. Must match a `title` from `GET /sdapi/v1/sd-models`. |
| `sd_vae` | string | VAE name, or `"Automatic"`, or `"None"`. |
| `CLIP_stop_at_last_layers` | integer | Clip-skip (1 = no skip; 2 = SD1.5 anime convention). |
| `samples_format` | string | Server-side output format. **Always force `"png"`** for transport; convert locally afterwards. Forge validates this *before* applying overrides, so if the server's persistent value is unsupported (e.g. `"avif"`), the entire request fails. The `generate.sh` script in this skill pre-pins it via `POST /sdapi/v1/options` *and* sets it in `override_settings` as a redundant safeguard. |
| `eta_noise_seed_delta` | integer | Anime-finetune convention often sets this to `31337`. |

### Forge-specific `override_settings`

These keys only exist on Forge / Forge-classic forks. Verify against your server with `scripts/options.sh get | jq 'keys[] | select(startswith("forge_"))'`.

| Key | Type | Notes |
|---|---|---|
| `forge_additional_modules` | string[] | Array of `model_name` from `GET /sdapi/v1/sd-modules`. Stacks extra TE/VAE/etc. modules for this request. The currently-active list mirrors the active preset's `forge_additional_modules_<preset>` (e.g. `_sd`, `_xl`, `_flux`). |
| `forge_preset` | string | Forge UI preset name (`"sd"`, `"xl"`, `"flux"`, `"qwen"`, `"wan"`, `"lumina"`, `"klein"`, `"anima"`, `"zit"` on Forge-classic). |
| `setting_allocated_vram` | number | Reserved VRAM in GB for inference (Forge-classic). Not all Forge variants expose this — check first. |
| `sd_vae` | string | Active VAE name, `"Automatic"`, or `"None"`. |
| `sd_vae_decode_method` / `sd_vae_encode_method` | string | VAE precision / fallback strategy. |

## `override_settings_restore_afterwards`

Boolean, default `false`. **Always set to `true`** unless you specifically intend to mutate the server's persistent settings.

## Script-args fields (advanced)

| Field | Type | Notes |
|---|---|---|
| `script_name` | string | Name of an Always-On / Script-tab script to invoke. |
| `script_args` | array | Positional arguments for that script. |
| `alwayson_scripts` | object | Map of `{ "ScriptName": { "args": [...] } }` for ControlNet, ADetailer, etc. The shape of `args` is script-specific and undocumented — extract from the UI's network panel as a reference. |

## Minimal request example

```json
{
  "prompt": "a watercolor portrait of a fox",
  "negative_prompt": "lowres, jpeg artifacts",
  "steps": 28,
  "cfg_scale": 4.0,
  "width": 832,
  "height": 1216,
  "sampler_name": "Euler a",
  "scheduler": "Beta",
  "styles": [],
  "override_settings": {
    "sd_model_checkpoint": "myModel.safetensors [a1b2c3d4]"
  }
}
```

## Forge example with extra modules

```json
{
  "prompt": "1girl, looking at viewer, masterpiece",
  "negative_prompt": "lowres, bad anatomy",
  "steps": 32,
  "cfg_scale": 4.0,
  "width": 832,
  "height": 1216,
  "sampler_name": "ER SDE",
  "scheduler": "Beta",
  "styles": ["anime-detail"],
  "override_settings": {
    "sd_model_checkpoint": "illustriousXL.safetensors [deadbeef]",
    "forge_additional_modules": ["clip_l.safetensors", "t5xxl_fp16.safetensors", "ae.safetensors"]
  }
}
```
