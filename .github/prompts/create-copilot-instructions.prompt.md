---
mode: 'agent'
description: "Create a `.github/copilot-instructions.md` file for the project."
tools: ['codebase', 'editFiles', 'fetch']
---
To facilitate more effective collaboration moving forward, please adhere to the following protocol to establish a `.github/copilot-instructions.md` or `AGENTS.md` file:

1. Carefully review the following documentation to gain a comprehensive understanding of what constitutes a well-crafted `copilot-instructions.md` with #fetch tool:
   https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot

2. Conduct a thorough examination of the #codebase to familiarize yourself with the overarching architecture and stylistic conventions of our codebase.

3. Within the project folder, find `AGENTS.md` or `.github/copilot-instructions.md` file if it exists. `.github/copilot-instructions.md` takes precedence over `AGENTS.md`. If either file is found, meticulously analyze its contents to extract any pertinent information that should be incorporated into the new `copilot-instructions.md` file.

4. Compose a meticulously constructed `copilot-instructions.md` document that adheres to established best practices. This document should include, but is not limited to, the following elements:

   * A concise yet informative summary of the project's objectives and functionalities.
   * A clear delineation of the project's coding style and formatting standards.
   * Guidance on the usage of any unconventional libraries, frameworks, or tools encountered within the codebase.
   * Any additional project-specific conventions, constraints, or nuanced considerations that should inform Copilot's behavior.
   * What is the designated language employed for in-code annotations and commentary throughout the project.

5. Utilize the #editFiles tool to create or rewrite `AGENTS.md` or `.github/copilot-instructions.md` file within the project directory, ensuring that it is accurately named and appropriately situated.

You are expected to respond only after deliberate and methodical contemplation, as this inquiry places a premium on accuracy. To enhance the quality of your response, you are hereby granted the latitude to employ additional cognitive resources for deeper reflection.

Let's do this step by step.
