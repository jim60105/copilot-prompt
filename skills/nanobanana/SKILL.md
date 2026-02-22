---
name: nanobanana
description: >
  Natural language interface for image generation and manipulation using the
  Nano Banana MCP server. Automatically routes requests to the most appropriate
  specialized tool: generate images, edit existing images, restore/enhance photos,
  create icons/favicons, generate patterns/textures, produce visual stories,
  or create technical diagrams. Use when the user makes a general or ambiguous
  image-related request that doesn't clearly map to a single specialized command,
  or when they explicitly ask to use "nanobanana" for image tasks.
---

# Nano Banana - Natural Language Interface

Route natural language image requests to the appropriate Nano Banana MCP tool.

## Tool Selection

Analyze the user's intent and select the most specialized tool:

| Intent | MCP Tool |
|--------|----------|
| Generate new images from text | `mcp_nanobanana_generate_image` |
| Edit/modify an existing image | `mcp_nanobanana_edit_image` |
| Restore/enhance a damaged or old image | `mcp_nanobanana_restore_image` |
| Create app icons, favicons, UI elements | `mcp_nanobanana_generate_icon` |
| Create seamless patterns, textures, backgrounds | `mcp_nanobanana_generate_pattern` |
| Create visual stories, sequences, tutorials | `mcp_nanobanana_generate_story` |
| Create technical diagrams, flowcharts, architecture | `mcp_nanobanana_generate_diagram` |

## Routing Heuristics

- **Mentions an existing file to modify** → `edit_image`
- **Mentions restoring, fixing, enhancing quality** → `restore_image`
- **Mentions logo, icon, favicon, UI element** → `generate_icon`
- **Mentions pattern, texture, wallpaper, tiling** → `generate_pattern`
- **Mentions story, sequence, steps, tutorial, timeline** → `generate_story`
- **Mentions diagram, flowchart, architecture, schema, wireframe** → `generate_diagram`
- **General image creation** → `generate_image`

## Workflow

1. Parse the user's natural language request.
2. Identify the intent using the routing heuristics above.
3. Extract relevant parameters (prompt, files, options) from the request.
4. Call the selected MCP tool with the assembled parameters.
5. Report the result to the user.

## Common Parameters Across All Tools

- `filename`: Custom output filename (pass through if user specifies)
- `parallel`: Number of parallel generations (1–8, default: 2)
- `preview`: Open generated images in default viewer
- `resolution`: Output resolution (`1K`, `2K`, `4K`)

## Notes

- For `edit_image` and `restore_image`, the `file` parameter (single file) is required.
- For `generate_image`, `generate_icon`, `generate_pattern`, `generate_story`, and `generate_diagram`, the optional `files` parameter accepts an array of 1–14 reference images.
