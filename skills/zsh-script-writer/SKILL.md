---
name: zsh-script-writer
description: "Write and test Zsh scripts following project coding standards with ShellSpec BDD testing. Use when the user wants to: (1) create a new Zsh script, (2) write or fix ShellSpec tests for Zsh scripts, (3) review Zsh code for best practices, (4) add error handling or dependency checking to shell scripts, (5) implement API integration in Zsh, (6) achieve 85%+ test coverage for shell scripts, or (7) work with any .zsh file or spec/*_spec.sh test file."
license: GFDL-1.3-or-later
---

# Zsh Script Writer

Write Zsh scripts and ShellSpec tests following project standards.

## Script Structure

```zsh
#!/bin/zsh
# Copyright (C) 2026 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==================================================================
#
# [Script description and usage information]
```

## Coding Standards

### Error Handling & Output

```zsh
# Color codes for user feedback
RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; RESET='\033[0m'

# Dependency check (fail fast)
if ! command -v tool_name >/dev/null 2>&1; then
    echo "${RED}ERROR: tool_name is required but not installed${RESET}" >&2
    exit 1
fi
```

- Use color codes: RED (errors), YELLOW (warnings), GRAY (info), RESET
- Exit with non-zero codes on failure
- Write errors to stderr (`>&2`)
- Fail fast: validate inputs and dependencies before processing

### Function Organization

Organize scripts into logical sections:

1. Utility functions (colors, logging, helpers)
2. Content processing functions (core logic)
3. Main execution function
4. Parameter handling (getopts or positional args)

### Working Directory Convention

Scripts process files in `$(pwd)`, NOT the script location. Use relative file patterns for cross-directory operation via PATH execution.

### API Integration

- Rate limiting for API calls
- Authentication via environment variables only (never hardcode)
- Safe HTTP operations (GET only unless explicitly specified)
- Temporary file handling with cleanup traps:

```zsh
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT INT TERM
```

### Safety

- Atomic operations where possible
- Validate input parameters before processing
- Clear error messages with suggested solutions
- Prefer fail-fast behavior

## Testing

Use ShellSpec for BDD testing. Target **85%+ coverage**.

For complete testing patterns, mocking strategies, and ShellSpec syntax:
See [references/testing-shellspec.md](references/testing-shellspec.md)

### Quick Reference

```bash
# Run all tests
shellspec

# Run specific test
shellspec spec/script_name_spec.sh

# Run with coverage
shellspec --kcov

# Verbose output
shellspec --format documentation
```

### Critical Rule

Always use `When run script` for coverage measurement:

```bash
# ✅ Correct — coverage is measured
When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"

# ❌ Wrong — coverage NOT measured
When run zsh "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"
```
