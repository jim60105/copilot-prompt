---
name: implement-local-plan
description: Implement a development plan from local plan files with work report tracking. Use when the user wants to execute a local development plan from `.github/plans/` or `.github/reports/`, implement backlog items step by step, or create work reports for completed tasks.
metadata:
  original-prompt: implement-local-plan.prompt.md
---

# Implement Local Plan

Implement a development plan from local plan files with systematic work report tracking.

## Key Directives

- Git commit after completing work, using conventional commit format for the title and a brief description in the body. Always commit with `--signoff`. Write the commit in English.
- Commit the report file together with the code changes, using the templates provided in `.github/reports/`.

## Work Report Protocol

Development progress is tracked within the `.github/reports` directory. Before starting any new work, review prior reports to stay aligned with ongoing development. Treat all past reports as immutable references — do not edit or revise them. Upon task completion, generate a new comprehensive work report. Refer to naming conventions of existing files to determine an appropriate filename.

Reports must include a detailed account of the work performed, encompassing all relevant code modifications and corresponding test outcomes.

## Implementation

Implement the plan step by step, following the instructions provided in the `plans/` directory. Each step should be executed in sequence, ensuring that all requirements are met and documented appropriately.
