# X/Y/Z Plot Script API Guide

The `x/y/z plot` script generates multi-axis comparison grids through the txt2img (or img2img) API — one API call produces a grid of images varying parameters across X, Y, and Z axes. Use this instead of looping with different parameter combos.

## Discovering available scripts & args at runtime

Script names and their argument schemas vary between Forge variants (classic, Neo, upstream A1111). Always discover them from the running server rather than hardcoding:

```bash
# List all available scripts
curl -sS "${SD_WEBUI_URL}/sdapi/v1/scripts" | jq '."

"'

# Get the full arg schema for the X/Y/Z plot script
curl -sS "${SD_WEBUI_URL}/sdapi/v1/script-info" | jq '."x/y/z plot"'
```

The `script-info` response gives you the exact number and types of args, plus the list of valid axis type labels. Use `--arg-table` via `scripts/list.sh` if available.

## Request body

Add two fields to your txt2img (or img2img) request:

```json
{
  "prompt": "1girl, blue sky",
  "script_name": "x/y/z plot",
  "script_args": [ ... ],
  ...other txt2img params...
}
```

## Script args (19 elements)

`script_args` is a flat array of **19 values**. All 19 must be present, in order:

| Idx | Field | Type | Description |
|-----|-------|------|-------------|
| 0 | X type | int | Axis type as an **integer index** into the axis options list. **Do NOT use the string label** — it won't match on most Forge variants. |
| 1 | X values | str | Comma-separated values. For numeric types (Steps, CFG), use `"min-max+step"` range syntax (e.g. `"10-30+5"` = 10,15,20,25,30). For Prompt S/R, first value is the search term, rest are replacements. |
| 2 | X values (dropdown) | str | Used for dropdown types (Checkpoint, Sampler, etc.). Leave as `""` when using `"X values"` (idx 1). |
| 3 | Y type | int | Same as X. Use `0` for "Nothing" to disable. |
| 4 | Y values | str | Same as X values. |
| 5 | Y values (dropdown) | str | Same as X dropdown. |
| 6 | Z type | int | Same as X. Use `0` for "Nothing" to disable. |
| 7 | Z values | str | Same as X values. |
| 8 | Z values (dropdown) | str | Same as X dropdown. |
| 9 | Draw legend | bool | `true` to overlay parameter labels on the grid. |
| 10 | Include Sub Images | bool | `true` to return individual cell images alongside the grid. Increases response size. |
| 11 | Include Sub Grids | bool | `true` to include per-row/per-column sub-grids. |
| 12 | Keep -1 for seeds | bool | Use `-1` (random) seeds instead of the request seed for each cell. |
| 13 | Vary seeds for X | bool | Vary seed along the X axis. |
| 14 | Vary seeds for Y | bool | Vary seed along the Y axis. |
| 15 | Vary seeds for Z | bool | Vary seed along the Z axis. |
| 16 | Row Count | int (0–8) | Grid rows per page. 0 = auto. |
| 17 | Grid Margins | int | Margin pixels between cells. |
| 18 | Use text inputs | bool | Use text input fields instead of dropdowns for certain types. Typically `false`. |

## Axis type index reference

The type-to-index mapping is **variant-dependent**. Query it at runtime from `script-info`:

```bash
curl -sS "${SD_WEBUI_URL}/sdapi/v1/script-info" \
  | jq '."x/y/z plot".args[0].choices'
```

Typical values observed on Forge variants:

| Index | Type |
|-------|------|
| 0 | Nothing |
| 1 | Seed |
| 2 | Steps |
| 3 | CFG Scale (or nearby) |
| 5 | CFG Scale (on some variants) |
| 10 | Prompt S/R |
| 11 | Prompt order |
| 12 | Sampler |
| 13 | Checkpoint name |
| 14 | VAE |
| 15 | Clip skip |
| 16 | Denoising |

**Critical:** The indices above are **approximate** — Forge Neo may differ from Forge-classic. Always confirm with `script-info`. The wrong integer index silently mismatches the type and the request will either fail with a cryptic error or produce results for the wrong axis type.

## Prompt S/R (Search & Replace)

The first value is the **search term** (matched in both `prompt` and `negative_prompt`), and each subsequent value is a **replacement** that creates a separate grid cell:

```
"1girl, 1boy, 1cat"
```

With `prompt: "1girl, blue sky"`, this produces three cells:
- Cell 1: `1girl, blue sky` (self-replace — search term stays)
- Cell 2: `1boy, blue sky`
- Cell 3: `1cat, blue sky`

Use additional replacements for any axis values that the value-inplace syntax can't express (e.g., LoRA `<lora:name:0.5>` vs `<lora:name:1>`).

**Combining Prompt S/R with other axis types** works naturally — e.g., `X=Prompt S/R × Y=CFG` produces a 2D grid with prompt variants on one axis and CFG values on the other.

## Response

The response is identical to a normal txt2img response:

```json
{
  "images": ["<base64 PNG grid>", ...],
  "info": "<JSON string with seed, all_prompts, etc.>"
}
```

- `images[0]` contains the full grid as a single PNG.
- `info` → `all_prompts` lists every prompt used, in row-major order — useful for verifying cell layout.
- If `"Include Sub Images": true`, `images` contains the grid + individual cell images.

## Common pitfalls

1. **Wrong type index**: Using a string label (`"Prompt S/R"`) instead of an integer index (`10`). Most Forge variants only match on the integer.
2. **Wrong index for your variant**: The index mapping is not universal. Query `script-info` for the running server every time.
3. **Missing args**: All 19 args must be present, even unused Z-axis args.
4. **value-inplace vs dropdown**: Some axis types (Checkpoint, Sampler) use the `"X values (dropdown)"` field (idx 2/5/8) rather than `"X values"`. Check `script-info` → `.args[2].choices` — if non-empty, use the dropdown field.
5. **Prompt S/R search term not found**: If the search term doesn't appear in the prompt or negative prompt, that cell silently uses the original prompt — no error is raised.
6. **sub_images increase response size**: With `Include Sub Images: true` and a 3×3 grid, you get 1 grid + 9 sub-images = 10 base64 PNGs. Only enable this when you need individual cells.
