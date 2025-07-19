---
# applyTo: '**/*.zsh'
---
# Zsh Development Guidelines

This project provides tools with Zsh scripts that process files in the current working directory. All scripts are designed to run from any directory via PATH.

## Project Context & Architecture

All Zsh scripts are designed to run separately from any directory, processing files in the current working directory rather than the script location. Scripts use PATH execution and relative file patterns for cross-directory operation.

## Zsh Coding Standards

### Script Headers & License

Use GPL-3.0-or-later license headers with Jim Chen copyright:

```zsh
#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
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

### Error Handling & User Feedback

- Use color codes for output (RED, YELLOW, GRAY, RESET)
- Implement proper error handling with exit codes
- Provide verbose output options where appropriate

### Function Organization

Organize scripts into logical sections:

- Utility functions
- Content processing functions
- Main execution functions
- Parameter handling functions

### Dependencies & External Tools

Document external tool requirements clearly in README.md.

Check for required tools before execution:

```zsh
if ! command -v tool_name >/dev/null 2>&1; then
    echo "ERROR: tool_name is required but not installed" >&2
    exit 1
fi
```

### API Integration

For API scripts, implement:

- Proper rate limiting
- Authentication via environment variables only
- Safe HTTP operations (GET only, no modification unless specified and double notice the user)
- Temporary file handling with cleanup

### Testing Integration

Follow ShellSpec testing patterns established in the project:

- Basic functionality tests
- Functional workflow tests
- Framework integration tests
- Error condition handling tests

Read [ShellSpec documentation](https://github.com/shellspec/shellspec/raw/refs/heads/master/README.md) and [zsh-testing-testing-guideline.md](../../docs/zsh-testing-guideline.md) for more details on writing tests.

## Working Directory Conventions

Scripts process files in `$(pwd)` (current working directory), not script location. Use relative patterns and `Path.cwd()` equivalent approaches.

## Comments & Documentation

- All comments and docstrings in English
- Include usage examples in script headers
- Document parameter handling and processing logic
- Explain complex operations and business logic

## Error Recovery & Safety

- Implement atomic operations where possible
- Use temporary files with proper cleanup
- Validate input parameters before processing
- Provide clear error messages with suggested solutions
- Prefer Fail Fast behavior to catch issues early
