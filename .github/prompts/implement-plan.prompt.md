---
mode: agent
description: "This prompt is designed to guide the agent in implementing a development plan for a project, ensuring that all tasks are completed according to the specified requirements and protocols. The agent will follow a structured approach to code implementation, testing, and reporting using GitHub Issues and Pull Requests system."
tools: ['changes', 'codebase', 'editFiles', 'fetch', 'findTestFiles', 'githubRepo', 'problems', 'runCommands', 'search', 'terminalLastCommand', 'terminalSelection', 'testFailure', 'usages', 'github-sudo', 'add_issue_comment', 'add_pull_request_review_comment_to_pending_review', 'create_and_submit_pull_request_review', 'create_issue', 'create_pull_request', 'get_issue', 'get_issue_comments', 'get_pull_request', 'get_pull_request_comments', 'get_pull_request_diff', 'get_pull_request_files', 'get_pull_request_reviews', 'get_pull_request_status', 'list_issues', 'list_pull_requests', 'search_issues', 'update_issue', 'update_pull_request']
---
* **Additional Key Directives:**
  * Git commit after completing your work, using the conventional commit format for the title and a brief description in the body. Always commit with `--signoff`. Write the commit in English.
  * Create a comprehensive work report as pull request details or comments, detailing the work performed, code changes, and test results for the project.

# GitHub DevOps Implementation Protocol

**Implementation Stage is to implement the plan step by step, following the instructions provided in the issue and submit a work report PR at last**

> This time, the work requires greater accuracy. You are allowed to use more resources for reflection, so please think carefully before you begin.

0. **Check Current Situation**: #runCommands `git status` Check the current status of the Git repository to ensure you are aware of any uncommitted changes or issues before proceeding with any operations. If you are not on the master branch, you may still be in the half implementation state, get the git logs between the current branch and master branch to see what you have done so far. If you are on the master branch, you seem to be in the clean state, you can start to get a new issue to work on.

1. **Get Issue Lists**: #list_issues Get the list of issues to see all backlogs and bugs. Find the issue that user asks you to work on or the one you are currently working on. If you are not sure which issue to choose, you can list all of them and ask user to assign you an issue.

2. **Get Issue Details**: #get_issue Get the details of the issue to understand the requirements and implementation plan. Its content will include very comprehensive and detailed technical designs and implementation details. Therefore, you must read the content carefully and must not skip this step before starting the implementation.

3. **Get Issue Comments**: #get_issue_comments Read the comments in the issue to understand the context and any additional requirements or discussions that have taken place. Please read it to determine whether this issue has been completed, whether further implementation is needed, or if there are still problems that need to be fixed. This step must not be skipped before starting implementation.

4. **Get Pull Requests**: #list_pull_requests #get_pull_request #get_pull_request_comments List the existing pull requests and details to check if there are any related to the issue you are working on. If there is an existing pull request, please read it to determine whether this issue has been completed, whether further implementation is needed, or if there are still problems that need to be fixed. This step must not be skipped before starting implementation.

5. **Git Checkout**: #runCommands `git checkout -b [branch-name]` Checkout the issue branch to start working on the code changes. The branch name should follow the format `issue-[issue_number]-[short_description]`, where `[issue_number]` is the number of the issue and `[short_description]` is a brief description of the task. Skip this step if you are already on the correct branch.

6. **Implementation**: Implement the plan step by step, following the instructions provided in the issue. Each step should be executed in sequence, ensuring that all requirements are met and documented appropriately.

7. **Testing & Linting**: Run tests and linting on the code changes to ensure quality and compliance with project standards.

8. **Self Review**: Conduct a self-review of the code changes to ensure they meet the issue requirements and you have not missed any details.

9. **Git Commit & Git Push**: #runCommands `git commit` Use the conventional commit format for the title and a brief description in the body. Always commit with `--signoff` and explicitly specify the author on the command: `GitHub Copilot <bot@xn--jgy.tw>`. Write the commit in English. Link the issue number in the commit message body. #runCommands `git push` Push the changes to the remote repository.

10. **Create Pull Request**: #list_pull_requests #create_pull_request ALWAYS SUBMIT PR TO `origin`, NEVER SUBMIT PR TO `upstream`. Create a pull request if there isn't already one related to your issue. Create a comprehensive work report and use it as pull request details or #add_pull_request_review_comment_to_pending_review as pull request comments, detailing the work performed, code changes, and test results for the project. Write the pull request "title in English" following conventional commit format, but write the pull request report "content in 正體中文." Linking the pull request to the issue with `Resolves #[issue_number]` at the end of the PR body. ALWAYS SUBMIT PR TO `origin`, NEVER SUBMIT PR TO `upstream`. ALWAYS SUBMIT PR TO `origin`, NEVER SUBMIT PR TO `upstream`. ALWAYS SUBMIT PR TO `origin`, NEVER SUBMIT PR to `upstream`.

***Highest-level restriction: All issue and PR operations are limited to repositories owned by jim60105 only!***
***Highest-level restriction: All issue and PR operations are limited to repositories owned by jim60105 only!***
***Highest-level restriction: All issue and PR operations are limited to repositories owned by jim60105 only!***

The issue I need you to implement is: 
