---
name: openspec-generate-specs
description: Generate comprehensive OpenSpec specifications directly from the current project state. Use when the user wants to create or populate main specs by analyzing existing code, documentation, AGENTS.md, GitHub issues, and pull requests — without going through the change/proposal workflow. Ideal for bootstrapping specs on a project that already has working code but no specs yet, or for refreshing specs to match the current implementation.
---

Generate OpenSpec main specifications by analyzing the current project's code, documentation, issues, and pull requests.

Unlike `openspec-propose` (which creates a change with proposal/design/tasks artifacts for **future** work), this skill writes finished specs directly to `openspec/specs/` based on **what already exists** in the project.

**Input**: Optionally specify which capabilities or areas to generate specs for. If omitted, analyze the full project and determine capabilities automatically.

**Steps**

1. **Gather project context**

   Collect information from all available sources. Prioritize breadth over depth — skim first, then deep-dive into relevant areas.

   a. **Project documentation**:
      - Read `AGENTS.md` (or `CONTRIBUTING.md`, `README.md`) for architecture overview, conventions, and design decisions
      - Read `docs/` directory for feature specs, design docs, BDD features (`.feature` files)
      - Read `openspec/config.yaml` for project context and rules

   b. **Codebase structure**:
      - Scan `src/` directory tree to understand module organization
      - Read key files (entry points, type definitions, core modules) to understand capabilities
      - Identify the main functional areas / capabilities the system provides

   c. **GitHub issues and PRs** (if available):
      - Use GitHub MCP tools to fetch recent open/closed issues for requirements context
      - Use GitHub MCP tools to fetch recent merged PRs for implemented features
      - Extract requirement-like information (feature requests, bug fixes, design decisions)

   d. **Existing specs** (if any):
      - Read `openspec/specs/` to understand what's already documented
      - Identify gaps between existing specs and actual implementation

2. **Identify capabilities**

   Based on the gathered context, determine the project's main capability areas. Each capability becomes a spec file at `openspec/specs/<capability>/spec.md`.

   Use the **AskUserQuestion tool** to confirm the identified capabilities before proceeding:
   > "I've identified these capabilities from the project. Which should I generate specs for?"

   Present the list with brief descriptions. Let the user select all or a subset.

   **Naming convention**: Use kebab-case for capability names (e.g., `memory-system`, `platform-abstraction`, `acp-integration`).

3. **Check existing specs**

   For each selected capability:
   - If `openspec/specs/<capability>/spec.md` already exists, read it
   - Use **AskUserQuestion tool** to ask: "Spec for `<capability>` already exists. Overwrite, merge, or skip?"
     - **Overwrite**: Replace entirely with newly generated spec
     - **Merge**: Add missing requirements/scenarios to existing spec, preserve existing content
     - **Skip**: Leave as-is

4. **Generate specs**

   For each capability, create a spec file following the OpenSpec spec format.

   Use the **TodoWrite tool** to track progress through capabilities.

   **Spec file structure** (`openspec/specs/<capability>/spec.md`):

   ```markdown
   # <Capability Name>

   ## Purpose

   <Brief description of what this capability does and why it exists.>

   ## Requirements

   ### Requirement: <Requirement Name>

   <The system SHALL/SHOULD/MAY description using RFC 2119 language.>

   #### Scenario: <Scenario Name>
   - **GIVEN** <precondition>
   - **WHEN** <action>
   - **THEN** <expected outcome>

   #### Scenario: <Another Scenario>
   - **GIVEN** <precondition>
   - **WHEN** <action>
   - **THEN** <expected outcome>
   ```

   **Writing guidelines**:
   - Use RFC 2119 keywords (SHALL, SHOULD, MAY) for requirement strength
   - Derive requirements from actual code behavior, not aspirational features
   - Include scenarios that reflect real code paths (check tests for scenario ideas)
   - Reference source files in requirement descriptions when helpful (e.g., "Implemented in `src/core/workspace-manager.ts`")
   - Keep requirements atomic — one concern per requirement
   - Group related scenarios under their parent requirement

5. **Write spec files**

   For each capability:
   ```bash
   mkdir -p openspec/specs/<capability>
   ```
   Write the spec content to `openspec/specs/<capability>/spec.md`.

   After writing each file, verify it exists and show brief progress.

6. **Validate output**

   Run validation if available:
   ```bash
   openspec validate --specs --json
   ```

   If validation fails, fix issues and re-validate.

7. **Show summary**

   Display what was generated:
   ```
   ## Specs Generated

   | Capability | Requirements | Scenarios | Status |
   |------------|-------------|-----------|--------|
   | <name>     | N           | M         | New/Merged/Overwritten |

   Total: X capabilities, Y requirements, Z scenarios

   Files written to `openspec/specs/`.
   ```

**Source Priority**

When information conflicts across sources, prefer in this order:
1. Actual code behavior (ground truth)
2. Test assertions (verified behavior)
3. BDD feature files / design docs (intended behavior)
4. GitHub issues/PRs (discussed behavior)
5. README / AGENTS.md (described behavior)

**Guardrails**
- Always confirm capability list with user before generating
- Never fabricate requirements not supported by code or documentation
- If a capability area is ambiguous, ask for clarification
- Preserve existing spec content when merging (only add, don't remove unless user confirms)
- Each spec file must have at least a Purpose section and one requirement
- Use consistent formatting across all generated spec files
