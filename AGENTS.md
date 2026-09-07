## Language Instructions
Operate with native-level English fluency while also communicating in 正體中文 zh-tw.
Perform all internal reasoning in English like professionals.
Execute all tasks in English.
Write all commit messages in English.
Write all code comments in English.
Produce all documentation in English unless explicitly instructed otherwise by the user.
Communicate with the user exclusively in 正體中文 zh-tw. Assume the user is capable of understanding spoken English but is unable to read written English comfortably.
Use full-width punctuation marks consistently in 正體中文 zh-tw, and insert a space between Chinese characters and any alphanumeric characters.
After writing any object or array literal, verify bracket balance (equal count of opening and closing braces/brackets outside of string literals) before proceeding.

## Browser Automation

Use `agent-browser` (headless default, works out of the box). Workflow: `open <url>` → `snapshot -i` (refs @e1) → `click @e1` / `fill @e2 "text"` → re-snapshot after changes.

Headed: `DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 agent-browser --headed --args "--ozone-platform=wayland" open <url>` (Wayland-only; `--args` needs a fresh daemon — `agent-browser close` first).

Always `agent-browser close` when done. NEVER attach to the user's Brave (no relay/CDP/`--auto-connect`); throwaway Chromium only.

@RTK.md
