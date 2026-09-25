---
name: commit
description: Create a git commit with clear, conventional commit messages. You MUST read this when the user wants to commit staged changes, write a commit message, or finalize code changes with proper conventional commit format since it describes how to follow the user's specific requirements.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Commit

Create git commits with conventional commit messages.

## Steps

0. Run `git log -3 --format=%B` to review the last three commit messages and understand the existing commit message pattern.
1. Run `git --no-pager diff` to review the full changes.
2. Analyze the changes thoroughly to understand what was modified.
3. Create a git commit with a clear, conventional commit message.

## Commit Guidelines

### Format
- **Title**: Use conventional commit format (`type: description`)
- **Body**: Include brief description linking to the issue
- **Language**: Always write commits in English
- **Newline**: The final commit message passed to Git must contain literal line-feed characters (LF, U+000A) between the title, body paragraphs, and footer. Do not use the literal two-character sequence backslash + `n` as a substitute for a line break.
- **Resolve Issues**: If applicable, include "Resolves issue #X" in the body to link the commit to an issue. Skip this if there is no relevant issue.
- **Co-Authored-By**: AVOID THIS. NEVER WRITE `Co-Authored-By: model-name <model-email>`
- **Signed-off-by**: Use `-s` to write Signed-off-by with the current username <email>.

**IMPORTANT**: Prefer a multiline message source that preserves line breaks exactly, such as `git commit -F -` with a heredoc, or use separate `-m` arguments for separate paragraphs.
**IMPORTANT**: Treat the rendered commit message as the source of truth. After committing, verify it with `git log -1 --format=%B` when newline handling is uncertain.
**IMPORTANT**: Do not allow the final commit message to contain the literal two-character sequence backslash + `n` as a substitute for a line break.

### Commit Command Template

```bash
git commit -s -F - <<'EOF'
chore: standardize linting, centralize guides, pin Python

- Introduce a root .flake8 config enforcing a 100-character line limit and ignoring specific style checks
- Remove inlined Python and Zsh guideline sections from copilot-instructions.md in favor of dedicated files
- Pin project Python version to 3.12 via a new .python-version file
- Rename docs/testing-guideline.md to docs/zsh-testing-guideline.md
- Refactor fetch_tags.py for consistent double-quoted strings, streamlined pattern definitions, logging calls, and URL assignment

Resolves issue #42
EOF
```
