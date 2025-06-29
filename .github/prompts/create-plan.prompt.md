---
mode: 'agent'
description: "Create a detailed development plan for a new project."
tools: ['codebase', 'editFiles', 'fetch', 'githubRepo', 'problems', 'runCommands', 'search', 'testFailure', 'usages', 'github-sudo', 'add_issue_comment', 'add_pull_request_review_comment_to_pending_review', 'create_and_submit_pull_request_review', 'create_issue', 'create_pull_request', 'get_issue', 'get_issue_comments', 'get_pull_request', 'get_pull_request_comments', 'get_pull_request_diff', 'get_pull_request_files', 'get_pull_request_reviews', 'get_pull_request_status', 'list_issues', 'list_pull_requests', 'search_issues', 'update_issue', 'update_pull_request']
---
**We are at planning stage so don't start to implement anything!**
**Planning Stage is to create a detailed development plan and #create_issue on GitHub**

> This time, the work requires greater accuracy. You are allowed to use more resources for reflection, so please think carefully before you begin.

0. **Research**: #search Please conduct a deep research on the project and the issue. You can use #search , #codebase to search for relevant information in code; use #list_issues , #search_issues , #get_issue , #get_issue_comments to find related issues and comments. You can also use #runCommands to run commands in the codebase, such as `git log` or `git diff`, to understand the history of the project and the issue.
1. **Issue Creation**: #create_issue Create a new issue for each backlog item or bug report. Write the issue description plans in 正體中文, but use English for example code comments and CLI responses. The plan should be very detailed (try your best!) because I will assign these tasks to newbies in the future. Please write documentation that enables anyone to complete the work successfully. However, do not mention 'newbies' in the document, as I do not want to undermine the employee's confidence. Please write that enables anyone to complete the work successfully.
2. **Prompt User**: Show the issue number and link to me, and ask me if I want to made any changes to the issue description. If I do, you can edit the issue description using #update_issue .

