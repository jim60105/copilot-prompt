---
name: commit
  description: Create a git commit with clear, conventional commit messages. You MUST read this when the user wants to commit staged changes, write a commit message, or finalize code changes with proper conventional commit format since it describes how to follow the user's specific requirements.
metadata:
  original-prompt: commit.prompt.md
  suggested-model: fast
---

# Commit

Create git commits with conventional commit messages.

## Steps

1. Run `git --no-pager diff` to review the full changes.
2. Analyze the changes thoroughly to understand what was modified.
3. Create a git commit with a clear, conventional commit message.

## Commit Guidelines

### Format
- **Title**: Use conventional commit format (`type: description`)
- **Body**: Include brief description linking to the issue
- **Language**: Always write commits in English
- **Newline**: Use real newlines in commit message, not `\n`
- **Resolve Issues**: If applicable, include "Resolves issue #X" in the body to link the commit to an issue. Skip this if there is no relevant issue.

**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!

### Commit Command Template

```bash
git commit -m "chore: standardize linting, centralize guides, pin Python

- Introduce a root .flake8 config enforcing a 100-character line limit and ignoring specific style checks
- Remove inlined Python and Zsh guideline sections from copilot-instructions.md in favor of dedicated files
- Pin project Python version to 3.12 via a new .python-version file
- Rename docs/testing-guideline.md to docs/zsh-testing-guideline.md
- Refactor fetch_tags.py for consistent double-quoted strings, streamlined pattern definitions, logging calls, and URL assignment

Resolves issue #42"
```
