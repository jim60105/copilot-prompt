---
name: nanobanana-icon
description: >
  Generate app icons, favicons, and UI elements in multiple sizes and formats
  using the Nano Banana MCP server. Use when the user wants to create app icons,
  favicons, UI elements, logo icons, or any icon-sized graphics with specific
  dimensions, styles, and transparency options. Triggers on requests like
  "create an app icon", "generate a favicon", "make a UI icon",
  "design a logo icon", or any icon/favicon creation task.
---

# Nano Banana - Icon Generation

Generate icons via the `mcp_nanobanana_generate_icon` MCP tool.

## Tool Call

Use `mcp_nanobanana_generate_icon` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Icon description |
| `files` | string[] | no | — | 1–14 reference image file paths |
| `sizes` | number[] | no | — | Icon sizes in pixels (16, 32, 64, 128, 256, 512, 1024) |
| `type` | `"app-icon"` \| `"favicon"` \| `"ui-element"` | no | `"app-icon"` | Icon type |
| `style` | `"flat"` \| `"skeuomorphic"` \| `"minimal"` \| `"modern"` | no | `"modern"` | Visual style |
| `format` | `"png"` \| `"jpeg"` | no | `"png"` | Output format |
| `background` | string | no | `"transparent"` | Background: `transparent`, `white`, `black`, or color name |
| `corners` | `"rounded"` \| `"sharp"` | no | `"rounded"` | Corner style for app icons |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `filename` | string | no | — | Custom output filename (size suffixes auto-added) |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Workflow

1. Extract the icon description from the user's request → `prompt`.
2. Determine icon type, sizes, style, and other preferences from context.
3. Call `mcp_nanobanana_generate_icon` with the assembled parameters.
4. Report the generated file path(s) to the user.

## Examples

**Full app icon set:**

```
prompt: "productivity app with a checkmark"
sizes: [64, 128, 256, 512]
type: "app-icon"
corners: "rounded"
```

**Favicon set:**

```
prompt: "mountain logo"
type: "favicon"
sizes: [16, 32, 64]
format: "png"
```

**UI element:**

```
prompt: "notification bell"
type: "ui-element"
style: "flat"
background: "transparent"
```
