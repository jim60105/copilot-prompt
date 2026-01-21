---
mode: 'agent'
description: "Create a detailed development plan for a new project."
tools: ['codebase', 'editFiles', 'fetch', 'githubRepo', 'problems', 'runCommands', 'search', 'testFailure', 'usages', 'github']
---
**We are at planning stage so don't start to implement anything!**
**Planning Stage is to create a detailed development plan and #issue_write on GitHub**

> This time, the work requires greater accuracy. You are allowed to use more resources for reflection, so please think carefully before you begin.

0. **Research**: #search Please conduct a deep research on the project and the issue. You can use #search , #codebase to search for relevant information in code; use #list_issues , #search_issues , #issue_read to find related issues and comments. You can also use #runCommands to run commands in the codebase, such as `git log` or `git diff`, to understand the history of the project and the issue. #askQuestions If you have any questions about the project or the issue, please ask me for clarification only using this tool. If #askQuestions is not available, you should keep on without asking questions.
1. **Plan Creation**: Based on your research, create a detailed development plan for the project. The plan should include:
   * A breakdown of tasks and subtasks required to complete the project.
   * Dependencies between tasks.
   * Any potential challenges and how to address them.
   * Testing and validation strategies to ensure the quality of the implementation.
2. **Review Plan**: Review the plan to ensure it is comprehensive and feasible. Make any necessary adjustments based on your review. Always challenge yourself to think of edge cases and potential pitfalls that may arise during implementation.
3. **Issue Creation**: #issue_write #sub_issue_write Create a new issue for each backlog item or bug report. You may have several solutions for this plan, but only write THE BEST ONE. Write the issue description plans in 正體中文, but use English for example code comments and CLI responses. The plan should be very detailed (try your best!) because I will assign these tasks to newbies in the future. Please write documentation that enables anyone to complete the work successfully. However, do not mention 'newbies' in the document, as I do not want to undermine the employee's confidence. Please write that enables anyone to complete the work successfully.
4. **Prompt User**: Show the issue number and link to me, and ask me if I want to made any changes to the issue description. If I do, you can edit the issue description using #issue_write or #sub_issue_write
