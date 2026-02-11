---
agent: agent
tools: ['runCommands']
model: Grok Code Fast 1
---
#runCommands

## Tasks

1. Use `git --no-pager diff` to see the full changes.
2. Ultrathink about what's in the changes according to git diff result.
2. Git commit with clear, conventional commit messages.

### Commit Guidelines

#### Commit Format

- **Title**: Use conventional commit format
- **Body**: Include brief description linking to the issue
- **Language**: Always write commits in English
- **Newline**: Use real newlines in commit message, not \n.

**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!
**IMPORTANT**: Don't use `\n` that's not working, use real newlines!!!

#### Commit Command Template

```bash
git commit -m "chore: standardize linting, centralize guides, pin Python

- Introduce a root .flake8 config enforcing a 100-character line limit and ignoring specific style checks
- Remove inlined Python and Zsh guideline sections from copilot-instructions.md in favor of dedicated files
- Pin project Python version to 3.12 via a new .python-version file
- Rename docs/testing-guideline.md to docs/zsh-testing-guideline.md
- Refactor fetch_tags.py for consistent double-quoted strings, streamlined pattern definitions, logging calls, and URL assignment

Resolves issue #42"
```
