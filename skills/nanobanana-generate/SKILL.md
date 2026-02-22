---
name: nanobanana-generate
description: >
  Generate single or multiple images from text prompts using the Nano Banana MCP server.
  Supports style variations, reference images, resolution control, and batch generation.
  Use when the user wants to generate images, create artwork, produce illustrations,
  make visual content from text descriptions, or create multiple image variations
  with different artistic styles. Triggers on requests like "generate an image",
  "create a picture", "make an illustration", "draw something", or any image
  creation task that does not involve editing existing images.
---

# Nano Banana - Image Generation

Generate images from text prompts via the `mcp_nanobanana_generate_image` MCP tool.

## Tool Call

Use `mcp_nanobanana_generate_image` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Text description of the image to generate |
| `files` | string[] | no | — | 1–13 reference image file paths |
| `outputCount` | number | no | 1 | Number of variations (1–8) |
| `styles` | string[] | no | — | Artistic styles to apply |
| `variations` | string[] | no | — | Variation types to apply |
| `format` | `"grid"` \| `"separate"` | no | `"separate"` | Output format |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `seed` | number | no | — | Seed for reproducible results |
| `filename` | string | no | — | Custom output filename (suffixes auto-added for multiple) |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open generated images in default viewer |

## Allowed Values

**Styles:** `photorealistic`, `watercolor`, `oil-painting`, `sketch`, `pixel-art`, `anime`, `vintage`, `modern`, `abstract`, `minimalist`

**Variations:** `lighting`, `angle`, `color-palette`, `composition`, `mood`, `season`, `time-of-day`

## Workflow

1. Extract the image description from the user's request as `prompt`.
2. Map any style, variation, count, resolution, filename, or reference file preferences to the corresponding parameters.
3. Call `mcp_nanobanana_generate_image` with the assembled parameters.
4. Report the generated file path(s) to the user.

## Examples

**Single image:**

```
prompt: "a watercolor painting of a fox in a snowy forest"
```

**Multiple variations with styles:**

```
prompt: "mountain landscape"
outputCount: 4
styles: ["watercolor", "oil-painting", "sketch", "photorealistic"]
```

**With reference images:**

```
prompt: "similar composition but in autumn colors"
files: ["reference.jpg"]
outputCount: 2
```

**With custom filename:**

```
prompt: "sunset over mountains"
outputCount: 3
filename: "sunset_mountains"
→ produces: sunset_mountains_1.jpg, sunset_mountains_2.jpg, sunset_mountains_3.jpg
```
