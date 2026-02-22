---
name: nanobanana-restore
description: >
  Restore or enhance an existing image using the Nano Banana MCP server.
  Use when the user wants to fix, repair, restore, upscale, enhance, or improve
  an old, damaged, blurry, or low-quality image — such as removing scratches,
  fixing tears, enhancing colors, improving sharpness, or denoising photos.
  Triggers on requests like "restore this old photo", "fix this damaged image",
  "enhance this picture", "improve image quality", or "upscale this photo".
---

# Nano Banana - Image Restoration

Restore or enhance existing images via the `mcp_nanobanana_restore_image` MCP tool.

## Tool Call

Use `mcp_nanobanana_restore_image` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Restoration/enhancement instructions |
| `file` | string | **yes** | — | Input image filename to restore |
| `filename` | string | no | — | Custom output filename |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Workflow

1. Identify the input image file from the user's request → `file`.
2. Extract the restoration instructions → `prompt`.
3. Map any resolution, filename, or preview preferences to the corresponding parameters.
4. Call `mcp_nanobanana_restore_image` with the assembled parameters.
5. Report the output file path to the user.

## Examples

**Remove scratches:**

```
file: "old_family_photo.jpg"
prompt: "remove scratches and enhance clarity"
```

**Color enhancement:**

```
file: "faded_photo.png"
prompt: "enhance colors and repair torn edges"
preview: true
```

**High-resolution restoration:**

```
file: "vintage_portrait.jpg"
prompt: "restore facial details and fix discoloration"
resolution: "4K"
filename: "restored_portrait"
```
