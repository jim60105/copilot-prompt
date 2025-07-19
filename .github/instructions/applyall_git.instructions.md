---
applyTo: '**'
---

# Git Workflow Instructions

These are the standardized Git workflow instructions extracted from project prompts to ensure consistent version control practices across all development activities.

## Git Repository Management

### Status Checking

- **Command**: `git status`
- **Purpose**: Check the current status of the Git repository to ensure awareness of any uncommitted changes or issues before proceeding with any operations
- **When to use**: Before starting any new development work or switching branches

### Repository History Investigation

- **Commands**: `git log`, `git diff`
- **Purpose**: Understand the history of the project and investigate issues
- **Usage**: Use these commands during research phase to understand project evolution and identify relevant changes

### Branch Management

#### Branch Status Assessment

- If not on the master branch: Check git logs between current branch and master to understand current work progress
- If on master branch: (The user may instruct you to create a new branch; otherwise,) Indicates clean state, ready to start new work

### Commit Guidelines

#### Commit Format

- **Title**: Use conventional commit format
- **Body**: Include brief description linking to the issue
- **Language**: Always write commits in English
- **Signing**: Always use `--signoff` flag
- **Author**: Explicitly specify author as `GitHub Copilot <bot@ChenJ.im>`
- **Newline**: Use real newlines in commit message, not \n.

**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!

#### Commit Command Template

```bash
git commit --signoff --author="GitHub Copilot <bot@ChenJ.im>" -m "chore: standardize linting, centralize guides, pin Python

- Introduce a root .flake8 config enforcing a 100-character line limit and ignoring specific style checks
- Remove inlined Python and Zsh guideline sections from copilot-instructions.md in favor of dedicated files
- Pin project Python version to 3.12 via a new .python-version file
- Rename docs/testing-guideline.md to docs/zsh-testing-guideline.md
- Refactor fetch_tags.py for consistent double-quoted strings, streamlined pattern definitions, logging calls, and URL assignment

Resolves issue #42"
```

#### Conventional Commit Types

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions or modifications
- `chore`: Maintenance tasks

### Push Guidelines

- **Command**: `git push`
- **Timing**: After completing implementation, testing, and self-review
- **Purpose**: Only push changes when the user asks you to do so, typically before creating a pull request

## Integration with GitHub Workflow

### Pull Request Submission Rules

- **Target**: ALWAYS submit PR to `origin`, NEVER to `upstream`
- **Title**: English, following conventional commit format
- **Description**: 正體中文 for comprehensive work reports
- **Linking**: Include `Resolves #[issue_number]` at the end of PR body
- **Purpose**: Only create PR when the user asks you to do so, ensuring that all changes are ready for review and integration

### Repository Restrictions

- All issue and PR operations are limited to repositories owned by jim60105 only
- This restriction applies to all GitHub operations including issue creation, PR submission, and repository management
