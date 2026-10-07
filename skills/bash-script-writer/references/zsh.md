# Zsh Addendum

Load this file **only** when the script is being written in Zsh (the user confirmed Zsh, explicitly asked for it, or is editing an existing `.zsh` file). Everything in `SKILL.md` still applies; this file lists the Zsh-specific overrides and idioms.

## Script Structure

```zsh
#!/usr/bin/env zsh
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

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
```

- `emulate -L zsh` resets options to Zsh defaults so the user's `.zshenv` cannot change script behavior.
- `setopt ERR_EXIT NO_UNSET PIPE_FAIL` is the Zsh equivalent of Bash's `set -euo pipefail` (the `set -euo pipefail` spelling also works).
- Existing scripts that use `#!/bin/zsh` may keep it; prefer `#!/usr/bin/env zsh` for new scripts.

## Output

Zsh's `echo` interprets backslash escapes by default, so plain-quoted color codes work:

```zsh
RED='\033[0;31m'; YELLOW='\033[1;33m'; GRAY='\033[0;90m'; RESET='\033[0m'
echo "${RED}ERROR: tool_name is required but not installed${RESET}" >&2
```

`print -P '%F{red}ERROR%f'` is the idiomatic alternative using prompt escapes.

## Key Differences From Bash

| Topic | Zsh behavior | Watch out for |
| --- | --- | --- |
| Array indexing | **1-indexed**; `$arr[1]` is the first element | Porting Bash `${arr[0]}` code |
| Word splitting | Unquoted `$var` is **not** split | Use `${=var}` to split explicitly; still quote for clarity |
| Unmatched globs | Error by default (`NOMATCH`) | Add the `(N)` qualifier: `for f in *.jpg(N)` |
| Script location | `${0:A:h}` gives the script's absolute directory | `BASH_SOURCE` does not exist |
| Local variables | `local` / `typeset`; `typeset -A` for associative arrays | `declare -A` also works |
| Sourcing guard | `if [[ $ZSH_EVAL_CONTEXT == toplevel ]]; then main "$@"; fi` | `BASH_SOURCE` comparison does not work |
| `trap ... EXIT` inside a function | Fires when the **function** returns, not when the script exits | Set cleanup traps at top level, or use `TRAPEXIT` deliberately |
| `read -p` | Means "read from coprocess", not "prompt" | Use `read "var?Prompt: "` |

## Idioms Worth Using

These are the reasons Zsh was chosen; use them instead of Bash-style workarounds.

```zsh
# Glob qualifiers: regular files only, newest first, top 5, no error if none
files=( *.log(.Nom[1,5]) )

# Recursive glob with filters (files larger than 10 MB)
big=( **/*(.NLm+10) )

# Parameter expansion flags
parts=( ${(s:,:)csv_line} )   # split on comma
joined=${(j:, :)parts}        # join with ", "
sorted=( ${(o)parts} )        # sort ascending
unique=( ${(u)parts} )        # deduplicate
upper=${(U)name}              # upper-case

# Floating-point arithmetic
(( ratio = width / 1.0 / height ))
zmodload zsh/mathfunc && (( r = sqrt(2.0) ))

# Date/time without external `date`
zmodload zsh/datetime
strftime '%Y-%m-%d %H:%M:%S' $EPOCHSECONDS

# Option parsing with long options
zparseopts -D -E -F -- \
    h=opt_help -help=opt_help \
    o:=opt_output -output:=opt_output || exit 1
```

## Temporary Files

```zsh
TMPFILE=$(mktemp)
trap 'rm -f -- "$TMPFILE"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
```

Set these at the top level of the script, not inside a function (see the `trap` row above).

## Verification

ShellCheck does not support Zsh. Use:

```zsh
zsh -n script_name.zsh          # Syntax check
./script_name.zsh --help        # Smoke test with safe arguments
```

## ShellSpec With Zsh

When ShellSpec is warranted (see the testing decision in `SKILL.md`), follow `testing-shellspec.md` with these adjustments:

- Run with `shellspec --shell zsh`, or set `--shell zsh` in `.shellspec`.
- Use `#!/bin/zsh` (or `#!/usr/bin/env zsh`) as the spec file shebang.
- Reference `.zsh` scripts: `When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"`.
- Never `When run zsh "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"` — coverage is not measured.
- Syntax checks use `zsh -n` and stay centralized in `spec/framework_integration_spec.sh`.
