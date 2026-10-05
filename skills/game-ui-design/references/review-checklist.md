# Game UI Review Checklist

Use this checklist for screenshots, interactive prototypes, implemented menus, HUDs, or design documents. Mark findings as Pass, Risk, Fail, or Not Applicable. Add evidence and a concrete recommendation for every Risk or Fail.

## Context and player task

- Is the target platform, input method, viewing distance, genre, and pace known?
- For each screen or gameplay state, is the player's immediate goal identifiable?
- Is every prominent UI element tied to a player decision, status check, navigation need, or explicit presentation goal?
- Are assumptions about new players and experienced players documented?

## HUD and visual hierarchy

- Can the player identify critical state without searching across the entire screen?
- Does the strongest visual emphasis correspond to the most urgent information?
- Are frequently monitored values placed where repeated checking has low cost?
- Are low-priority notifications prevented from competing with combat, targeting, driving, timing, or other high-pressure tasks?
- Does the UI remain legible over the brightest, darkest, busiest, and most animated gameplay backgrounds?
- If information is hidden contextually, can it appear before the player needs it rather than after failure?

## Presentation method

- Is each information type using a presentation method suited to its task rather than following a blanket HUD-minimalism rule?
- For diegetic or world-space UI, is information readable under camera motion, distance changes, occlusion, and lighting variation?
- For screen-space HUD, does it avoid covering high-value gameplay regions?
- Can essential state still be obtained quickly if the player misses a transient notification?

## Menus, navigation, and focus

- Is focus always visible when using controller or keyboard navigation?
- Does focus order follow the visual and semantic structure?
- Can players reliably go back, cancel, and return to a stable parent screen?
- Are repeated controls located and named consistently across screens?
- Do dialogs capture focus correctly and return focus to a sensible location when closed?
- Does each screen make its hierarchy and current location understandable?

## Input and prompts

- Do prompts match the currently active input device and current bindings?
- Can supported menus be operated without requiring unnecessary analog precision?
- Are holds, repeated presses, simultaneous presses, and timing-sensitive actions configurable or avoidable where feasible?
- Are hover-only or pointer-only interactions avoided when controller/keyboard support is expected?

## Learnability and onboarding

- Does the player practice core mechanics instead of only reading about them?
- Does feedback appear soon enough for the player to connect action and result?
- Are instructions presented near the moment they become relevant?
- Can tutorials, controls, objectives, and key mechanics be revisited later?
- Does guidance adapt appropriately when the player is already experienced?

## Accessibility and readability

- Does critical meaning survive removal of color information?
- Do text and important visual elements meet the applicable current contrast guideline?
- Does text meet the applicable platform guideline and remain functional when scaled?
- Does critical visual information have another suitable sensory channel when necessary?
- Does critical audio information have a visual/text/haptic alternative when necessary?
- Can users reduce distracting motion, visual clutter, or unnecessary notifications when the game presents them heavily?

## Objectives, memory, and recovery

- Can players review current objectives and progress at any time when objectives drive progression?
- Can returning players recover narrative or progress context without relying on memory alone?
- Are save slots descriptive enough to distinguish progress states when manual saves exist?
- Are errors localized and explained with a way to correct them?
- Do destructive actions provide review, cancel, undo, or confirmation as appropriate?

## Validation plan

- Has the interface been reviewed heuristically before expensive implementation work?
- Has it been tested with representative players performing real tasks?
- Are comprehension time, task success, navigation errors, missed cues, and recovery failures measured where relevant?
- Are aesthetic preference findings separated from usability failures and game-balance feedback?
