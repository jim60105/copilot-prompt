---
name: nanobanana-diagram
description: >
  Generate technical diagrams, flowcharts, and architectural mockups from text
  descriptions using the Nano Banana MCP server. Use when the user wants to
  create flowcharts, system architecture diagrams, network diagrams, database
  schemas, wireframes, mindmaps, or sequence diagrams as images (not as code
  or draw.io files). Triggers on requests like "generate a diagram image",
  "create a flowchart picture", "make an architecture diagram as an image",
  or any diagram generation task that should produce a raster image output.
---

# Nano Banana - Diagram Generation

Generate technical diagrams via the `mcp_nanobanana_generate_diagram` MCP tool.

## Tool Call

Use `mcp_nanobanana_generate_diagram` with these parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **yes** | — | Diagram description |
| `files` | string[] | no | — | 1–14 reference image file paths |
| `type` | string | no | `"flowchart"` | Diagram type (see below) |
| `style` | `"professional"` \| `"clean"` \| `"hand-drawn"` \| `"technical"` | no | `"professional"` | Visual style |
| `layout` | `"horizontal"` \| `"vertical"` \| `"hierarchical"` \| `"circular"` | no | `"hierarchical"` | Layout orientation |
| `complexity` | `"simple"` \| `"detailed"` \| `"comprehensive"` | no | `"detailed"` | Detail level |
| `colors` | `"mono"` \| `"accent"` \| `"categorical"` | no | `"accent"` | Color scheme |
| `annotations` | `"minimal"` \| `"detailed"` | no | `"detailed"` | Label/annotation level |
| `resolution` | `"1K"` \| `"2K"` \| `"4K"` | no | `"1K"` | Output resolution |
| `filename` | string | no | — | Custom output filename |
| `parallel` | number | no | 2 | Parallel generation count (1–8) |
| `preview` | boolean | no | false | Open result in default viewer |

## Diagram Types

| Type | Use Case |
|------|----------|
| `flowchart` | Processes, decision trees, workflows |
| `architecture` | System architecture, microservices, infrastructure |
| `network` | Network topology, server configuration |
| `database` | Database schema, entity relationships |
| `wireframe` | UI/UX wireframes, page layouts |
| `mindmap` | Mind maps, concept hierarchies |
| `sequence` | Sequence diagrams, API interactions |

## Workflow

1. Extract the diagram description from the user's request → `prompt`.
2. Determine the appropriate diagram type, style, layout, and complexity from context.
3. Call `mcp_nanobanana_generate_diagram` with the assembled parameters.
4. Report the generated file path to the user.

## Examples

**CI/CD flowchart:**

```
prompt: "CI/CD pipeline with test stages"
type: "flowchart"
complexity: "detailed"
```

**System architecture:**

```
prompt: "chat application architecture with microservices"
type: "architecture"
style: "technical"
```

**Database schema:**

```
prompt: "social media database with users, posts, and comments"
type: "database"
annotations: "detailed"
```
