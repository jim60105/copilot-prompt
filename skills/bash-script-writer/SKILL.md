---
name: bash-script-writer
description: "Write, review, and optionally test Bash and Zsh shell scripts following project coding standards. Use for ANY shell scripting task: (1) creating a new Bash or Zsh script, (2) editing, fixing, or reviewing an existing .sh, .bash, or .zsh file, (3) adding error handling, dependency checks, or cleanup traps to shell scripts, (4) implementing API integration or file processing in shell, (5) writing or fixing ShellSpec tests (spec/*_spec.sh), or (6) deciding whether a script should be written in Bash or Zsh. Defaults to Bash; Zsh-specific guidance lives in a reference file that is loaded only when writing Zsh."
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Bash Script Writer

Write Bash (default) or Zsh scripts following project standards, and decide whether ShellSpec tests are warranted.

## Workflow

1. **Choose the shell** — see [Step 1: Shell Selection](#step-1-shell-selection). Bash unless the user confirms Zsh.
2. **Load Zsh guidance only if needed** — when the chosen shell is Zsh, read [references/zsh.md](references/zsh.md) before writing any code. Do NOT load it for Bash work.
3. **Write the script** following [Script Structure](#script-structure) and [Coding Standards](#coding-standards). For Zsh, apply the overrides in `references/zsh.md`.
4. **Decide on testing** — see [Step 4: Testing Decision](#step-4-testing-decision). ShellSpec is optional, not the default.
5. **Verify** — always run at least the lightweight checks in [Verification](#verification).

## Step 1: Shell Selection

### Already decided — skip the decision

- **Editing an existing script**: keep its current shell. Do not migrate it unless the user asks.
- **User explicitly named the shell** ("write a zsh script", "make this a .zsh"): that counts as confirmation; use it.
- **The context dictates the shell**: Dockerfile `RUN`, GitHub Actions `run:`, container entrypoints, `Makefile` recipes, CI images, or anything that runs where Zsh is not guaranteed to be installed → Bash, no suggestion.
- **Zsh plugins, `.zshrc` helpers, autoload functions, completion functions** (`_command`) → Zsh is inherent; no confirmation needed.

### Otherwise — prefer Bash, suggest Zsh only when it clearly pays off

Bash is the default: it is installed nearly everywhere, most contributors read it fluently, and ShellCheck fully supports it (ShellCheck does **not** lint Zsh).

Suggest Zsh only when the script would make **substantial** use of one or more of these advantages:

| Zsh advantage | What it replaces in Bash |
| --- | --- |
| Glob qualifiers: `*(.)`, `*(/)`, `*(om[1,5])`, `*(Lm+10)`, `*(N)` | `find ... -printf \| sort \| head` pipelines, `stat` loops |
| Native floating-point arithmetic: `(( x = 1.5 * y ))`, `zsh/mathfunc` | Shelling out to `bc` / `awk` for every calculation |
| Parameter expansion flags: `${(s:,:)var}` split, `${(j:,:)arr}` join, `${(o)arr}` sort, `${(u)arr}` unique, `${(U)var}` upper-case | `IFS` juggling, `sort -u`, `tr`, subshells |
| No word-splitting of unquoted `$var` by default | Defensive quoting everywhere (still recommended in Bash) |
| `zparseopts` with long options and arrays | Hand-rolled `while/case` loops for `--long` options (`getopts` is short-only) |
| Loadable modules: `zsh/datetime` (`strftime`, `$EPOCHREALTIME`), `zsh/stat`, `zsh/files`, `zsh/net/tcp` | External `date`, `stat`, `nc` calls |
| Nested/qualified recursive globbing `**/*.jpg(.N)` with filters | `shopt -s globstar nullglob` plus manual filtering |

Weigh against the costs:

- Zsh may not be installed on servers, containers, CI runners, or teammates' machines.
- No ShellCheck support; fewer reviewers are fluent in Zsh idioms.
- Mixed shells in one project add cognitive load.

**Decision rule:**

- One or two minor conveniences (e.g. a single split or a single glob) → **use Bash, do not ask**.
- Several advantages used heavily, or an advantage that removes significant complexity or external dependencies, and the script runs on machines where Zsh is available → **recommend Zsh and ask the user to confirm**.

### Asking for confirmation

When recommending Zsh, stop before writing code and ask the user. Present:

1. The specific Zsh features the script would use and what they simplify (concrete, not generic).
2. The costs that apply in this context (runtime availability, ShellCheck, team familiarity).
3. A clear default: "I will write it in Bash unless you confirm Zsh."

Only proceed with Zsh after explicit confirmation. If the user declines or does not answer clearly, use Bash.

## Script Structure

```bash
#!/usr/bin/env bash
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

set -Eeuo pipefail
```

- Use `#!/usr/bin/env bash` for portability (Bash lives in `/usr/local/bin` on macOS Homebrew and BSDs).
- If the script lives inside a project with a different license, match that project's existing header convention instead of the GPL header.

## Coding Standards

### Strict Mode

- Start with `set -Eeuo pipefail`.
- Be aware of `set -e` pitfalls: it is suppressed inside `if`, `&&`, `||` conditions and in functions called from them. Check critical commands explicitly.
- Use `"${VAR:-}"` when an unset variable is legitimately possible under `set -u`.

### Error Handling & Output

```bash
# Color codes for user feedback (ANSI-C quoting so Bash `echo` emits real escapes)
RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'; GRAY=$'\033[0;90m'; RESET=$'\033[0m'

# Dependency check (fail fast)
if ! command -v tool_name >/dev/null 2>&1; then
    echo "${RED}ERROR: tool_name is required but not installed${RESET}" >&2
    exit 1
fi
```

- Use color codes: RED (errors), YELLOW (warnings), GRAY (info), RESET
- Define colors with `$'...'` (or use `printf`); plain `'\033[...]'` strings are NOT interpreted by Bash's `echo`
- Exit with non-zero codes on failure
- Write errors to stderr (`>&2`)
- Fail fast: validate inputs and dependencies before processing

### Bash Idioms

- Use `[[ ... ]]` for tests and `(( ... ))` for integer arithmetic.
- Quote every expansion: `"$var"`, `"${arr[@]}"`, `"$(cmd)"`.
- Declare function variables with `local`; use `local -r` / `readonly` for constants.
- Use arrays for argument lists instead of space-joined strings: `args=(--flag "$value"); cmd "${args[@]}"`.
- Read lines safely: `while IFS= read -r line; do ...; done < file`, or `mapfile -t lines < file`.
- Enable `shopt -s nullglob` (and `globstar` if needed) when looping over globs that may match nothing.
- Use `$(...)` not backticks; use `printf` over `echo` when the content may start with `-` or contain backslashes.
- Bash arrays are 0-indexed. Associative arrays require `declare -A` (Bash 4+; macOS ships Bash 3.2 — note this if the script must run on stock macOS).

### Function Organization

Organize scripts into logical sections:

1. Utility functions (colors, logging, helpers)
2. Content processing functions (core logic)
3. Main execution function
4. Parameter handling (getopts or positional args)

End with `main "$@"` so the script can also be sourced for testing without side effects when guarded:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Working Directory Convention

Scripts process files in `$(pwd)`, NOT the script location. Use relative file patterns for cross-directory operation via PATH execution. When the script needs its own resources, resolve them explicitly: `SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)`.

### API Integration

- Rate limiting for API calls
- Authentication via environment variables only (never hardcode)
- Safe HTTP operations (GET only unless explicitly specified)
- Temporary file handling with cleanup traps:

```bash
TMPFILE=$(mktemp)
trap 'rm -f -- "$TMPFILE"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
```

Use single quotes in `trap` so the variable is expanded when the trap fires, and quote it to survive spaces.

### Safety

- Atomic operations where possible (write to a temp file, then `mv`)
- Validate input parameters before processing
- Clear error messages with suggested solutions
- Prefer fail-fast behavior

## Step 4: Testing Decision

ShellSpec is **optional**. Decide based on the project, not habit.

| Situation | Testing approach |
| --- | --- |
| The project is **mainly a Bash/Zsh script project** (the shell scripts are the product) | Use ShellSpec, target **85%+ coverage** |
| The user **explicitly asks** for tests of the script | Use ShellSpec, target **85%+ coverage** |
| The script is a small helper inside a project mainly written in another language (Python, TypeScript, Rust, Go, ...) | **Do NOT add ShellSpec** — it adds a new framework, config, and CI step disproportionate to the script. Use [Verification](#verification) only |
| Unsure | Do not add ShellSpec; mention to the user that tests can be added with ShellSpec if wanted |

Signs that a repository is mainly a shell script project: most source files are `.sh`/`.bash`/`.zsh`, a `spec/` directory or `.shellspec` file already exists, or the README describes the scripts as the deliverable.

When ShellSpec is used, follow [references/testing-shellspec.md](references/testing-shellspec.md) for structure, mocking, and coverage rules.

### ShellSpec Quick Reference

```bash
shellspec                                # Run all tests
shellspec spec/script_name_spec.sh       # Run a specific test
shellspec --kcov                         # Run with coverage
shellspec --format documentation         # Verbose output
```

Critical rule — always use `When run script` so coverage is measured:

```bash
# ✅ Correct — coverage is measured
When run script "$SHELLSPEC_PROJECT_ROOT/script_name.sh"

# ❌ Wrong — coverage NOT measured
When run bash "$SHELLSPEC_PROJECT_ROOT/script_name.sh"
```

## Verification

Run these regardless of whether ShellSpec is used:

```bash
bash -n script_name.sh          # Syntax check
shellcheck script_name.sh       # Lint (if shellcheck is installed)
./script_name.sh --help         # Smoke test with safe arguments
```

For Zsh scripts, use the checks listed in `references/zsh.md` instead (ShellCheck does not support Zsh).

Fix every ShellCheck warning or add a targeted `# shellcheck disable=SCxxxx` comment with a reason.
