---
mode: agent
description: "This prompt is designed to guide the agent in implementing a development plan for a project, ensuring that all tasks are completed according to the specified requirements and protocols. The agent will follow a structured approach to code implementation, testing, and reporting."
---
* **Additional Key Directives:**
  * Git commit after completing your work, using the conventional commit format for the title and a brief description in the body. Always commit with `--signoff`. Write the commit in English.
  * Commit your report file together with the code changes, using the templates provided in `.github/reports/`.

# Work Report Protocol

Development progress for this project is systematically tracked within the `.github/reports` directory. Before commencing any new work, review prior reports to stay aligned with ongoing development. Treat all past reports as immutable references—do not edit or revise them under any circumstance. Upon the completion of each task, you are required to generate a new comprehensive work report. Refer to the naming conventions of existing files to determine an appropriate filename.

Your report must include a detailed account of the work performed, encompassing all relevant code modifications and corresponding test outcomes.

You will implement the plan step by step, following the instructions provided in the `plans/` directory. Each step should be executed in sequence, ensuring that all requirements are met and documented appropriately. The plan I need you to implement is:
