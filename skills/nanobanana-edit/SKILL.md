---
name: nanobanana-edit
description: >
  Edit an existing image based on natural language instructions using the Nano Banana MCP server.
  Use when the user wants to modify, alter, or transform an existing image file — such as
  adding elements, changing backgrounds, removing objects, adjusting colors, or applying
  visual effects to a photo or picture. Triggers on requests like "edit this image",
  "modify this photo", "add sunglasses to the person", "change the background",
  or any image manipulation task that starts from an existing file.
---

# Nano Banana - Image Editing

Edit existing images via the `mcp_nanobanana_edit_image` MCP tool.

## Tool Call

Use `mcp_nanobanana_edit_image` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Natural language edit instructions |
| `file` | string | **yes** | — | Input image filename to edit |
| `filename` | string | no | — | Custom output filename |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Workflow

1. Identify the input image file from the user's request → `file`.
2. Extract the edit instructions → `prompt`.
3. Map any resolution, filename, or preview preferences to the corresponding parameters.
4. Call `mcp_nanobanana_edit_image` with the assembled parameters.
5. Report the output file path to the user.

## Examples

**Add an element:**

```
file: "portrait.jpg"
prompt: "add sunglasses to the person"
```

**Change background with custom output:**

```
file: "my_photo.png"
prompt: "change the background to a beach scene"
filename: "beach_version"
```

**High-resolution edit with preview:**

```
file: "product.jpg"
prompt: "make the lighting warmer and more dramatic"
resolution: "4K"
preview: true
```
