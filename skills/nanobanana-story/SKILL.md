---
name: nanobanana-story
description: >
  Generate a sequence of related images that tell a visual story or show a
  process step-by-step using the Nano Banana MCP server. Use when the user
  wants to create visual narratives, storyboards, step-by-step tutorials,
  process diagrams as image sequences, or timeline visualizations. Triggers
  on requests like "create a visual story", "make a storyboard", "show a
  step-by-step process", "generate a tutorial sequence", "visualize a
  timeline", or any sequential image generation task.
---

# Nano Banana - Visual Story Generation

Generate sequential image stories via the `mcp_nanobanana_generate_story` MCP tool.

## Tool Call

Use `mcp_nanobanana_generate_story` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Story/process description |
| `files` | string[] | no | — | 1–14 reference image file paths for consistency |
| `steps` | number | no | 4 | Number of sequential images (2–8) |
| `type` | `"story"` \| `"process"` \| `"tutorial"` \| `"timeline"` | no | `"story"` | Sequence type |
| `style` | `"consistent"` \| `"evolving"` | no | `"consistent"` | Visual consistency across frames |
| `layout` | `"separate"` \| `"grid"` \| `"comic"` | no | `"separate"` | Output layout |
| `transition` | `"smooth"` \| `"dramatic"` \| `"fade"` | no | `"smooth"` | Transition style between steps |
| `format` | `"storyboard"` \| `"individual"` | no | `"individual"` | Output format |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `filename` | string | no | — | Custom output filename (suffixes auto-added) |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Important Notes

- Story sequences do **not** automatically reference the previous image.
- If `--files` reference images are provided, the entire series uses them as a consistency anchor.

## Workflow

1. Extract the story/process description from the user's request → `prompt`.
2. Determine type, steps, style, layout, and other preferences from context.
3. Call `mcp_nanobanana_generate_story` with the assembled parameters.
4. Report the generated file paths to the user.

## Examples

**Product development process:**

```
prompt: "from idea to product launch"
steps: 5
type: "process"
style: "consistent"
```

**Educational tutorial:**

```
prompt: "how to brew pour-over coffee"
steps: 6
type: "tutorial"
layout: "comic"
```

**Brand evolution timeline:**

```
prompt: "evolution of smartphone design"
steps: 5
type: "timeline"
transition: "smooth"
```
