---
name: nanobanana-pattern
description: >
  Generate seamless patterns and textures for backgrounds and design elements
  using the Nano Banana MCP server. Use when the user wants to create tiling
  patterns, seamless textures, wallpapers, background materials, or repeating
  design elements. Triggers on requests like "create a pattern", "generate a
  texture", "make a seamless background", "design a wallpaper", or any
  pattern/texture creation task.
---

# Nano Banana - Pattern Generation

Generate patterns and textures via the `mcp_nanobanana_generate_pattern` MCP tool.

## Tool Call

Use `mcp_nanobanana_generate_pattern` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Pattern/texture description |
| `files` | string[] | no | — | 1–14 reference image file paths |
| `size` | string | no | `"256x256"` | Tile size (e.g., `"128x128"`, `"512x512"`) |
| `type` | `"seamless"` \| `"texture"` \| `"wallpaper"` | no | `"seamless"` | Pattern type |
| `style` | `"geometric"` \| `"organic"` \| `"abstract"` \| `"floral"` \| `"tech"` | no | `"abstract"` | Pattern style |
| `density` | `"sparse"` \| `"medium"` \| `"dense"` | no | `"medium"` | Element density |
| `colors` | `"mono"` \| `"duotone"` \| `"colorful"` | no | `"colorful"` | Color scheme |
| `repeat` | `"tile"` \| `"mirror"` | no | `"tile"` | Tiling method |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `filename` | string | no | — | Custom output filename |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Workflow

1. Extract the pattern description from the user's request → `prompt`.
2. Determine type, style, density, colors, and other preferences from context.
3. Call `mcp_nanobanana_generate_pattern` with the assembled parameters.
4. Report the generated file path to the user.

## Examples

**Website background:**

```
prompt: "subtle geometric hexagons"
type: "seamless"
colors: "duotone"
density: "sparse"
```

**Material texture:**

```
prompt: "brushed metal surface"
type: "texture"
style: "tech"
colors: "mono"
```

**Decorative wallpaper:**

```
prompt: "art deco design"
type: "wallpaper"
style: "geometric"
size: "512x512"
```
