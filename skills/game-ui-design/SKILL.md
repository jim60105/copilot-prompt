---
name: game-ui-design
description: Research-grounded workflow for designing, reviewing, and improving video game user interfaces, including HUDs, menus, navigation, focus states, onboarding/tutorials, objective tracking, input prompts, readability, accessibility, and destructive-action flows. Use when asked how to make good game UI, critique a game UI or HUD, propose UI/UX guidelines, design menu or gameplay interfaces, compare HUD vs diegetic/spatial presentation, create a UI design brief, or run a usability/accessibility review for PC, console, mobile, or VR games.
license: GFDL-1.3-or-later
metadata:
  author: Jim@ChenJ.im
---

# Game UI Design

Design game UI around player decisions and task-relevant information. Use visual style to reinforce those decisions after the information architecture and interaction model are defined.

## Workflow

1. Identify the play context.
   - Determine genre, platform, camera perspective, input devices, expected viewing distance, pace, multiplayer constraints, and target audience.
   - If important context is missing, make explicit assumptions and keep recommendations conditional.

2. Map player decisions to information.
   - List the decisions the player must make during each game state.
   - For each decision, identify the minimum information needed, how frequently it changes, and how quickly the player must notice it.
   - Classify information as immediate, near-term, or reference-only.

3. Choose the presentation method.
   - Select HUD, diegetic, spatial/world-space, audio, haptic, or menu presentation according to task, urgency, frequency, and occlusion cost.
   - Do not assume diegetic UI or minimal HUD is inherently more immersive or more usable. Evidence does not support a universal winner across information types.
   - Use persistent presentation for information that must be monitored continuously. Use contextual or on-demand presentation for lower-priority information when it reduces distraction without hiding required state.

4. Establish hierarchy and interaction consistency.
   - Give the highest visual priority to information that changes the player's next action.
   - Keep interaction mappings, button prompts, focus treatment, terminology, and menu structure predictable.
   - Make selected, focused, pressed, disabled, cooldown, warning, and error states perceptibly distinct.

5. Design learning and recovery.
   - Teach mechanics through practice when possible, with timely feedback and access to reminders later.
   - Stage complex instruction so the player learns near the moment of use.
   - Let players revisit objectives, tutorials, narrative summaries, and progress when the game requires memory over time.

6. Apply accessibility constraints early.
   - Treat readability, contrast, focus visibility, input flexibility, redundant sensory channels, and error recovery as design constraints rather than late polish.
   - For platform-specific numeric requirements, verify the current official guideline before quoting a number. The bundled accessibility reference contains a dated snapshot for fallback use.

7. Evaluate with the right method.
   - Use heuristic review for early concepts and prototypes.
   - Use playtesting for task completion, comprehension, attention, and preference.
   - Separate usability findings from aesthetic preference and from game-balance difficulty.

## Evidence and reference routing

Read `references/research-evidence.md` when making claims about HUDs, diegetic interfaces, tutorials, learnability, or game usability research.

Read `references/accessibility-platform-guidelines.md` when reviewing text size, contrast, sensory redundancy, input, objectives, menu navigation, focus, context, errors, or destructive actions.

Read `references/review-checklist.md` when auditing an existing UI, screenshot, prototype, or design document.

Read `references/output-patterns.md` when producing a critique, design brief, implementation guideline, or research-backed recommendation.

## Core decision rules

- Preserve immediate comprehension during play. A visually elegant interface that obscures required state has failed its task.
- Optimize information placement for the specific gameplay task. Health, ammunition, navigation, targeting, objectives, and inventory can justify different presentation methods.
- Minimize simultaneous competition for attention. Reduce decorative motion, notifications, and low-priority indicators around high-pressure decisions.
- Keep critical status visible or quickly recoverable. Avoid forcing memory when the game can present current state or progress.
- Use more than color alone for critical distinctions. Combine color with shape, label, pattern, position, outline, audio, haptic, or narration as appropriate.
- Provide a clearly visible focus indicator for controller/keyboard menu navigation.
- Update on-screen prompts after input rebinding or input-device changes.
- Give players a review, confirm, cancel, or undo path for destructive or permanent actions.
- Prefer player-configurable UI density, subtitles/captions, contrast, text scale, and input behavior when those settings are relevant to the game.

## Quality bar

Ground strong recommendations in one of three forms: cited research, a current platform/accessibility guideline, or an explicit task-analysis argument. State study scope and limitations when a paper is descriptive, genre-specific, or based on a limited sample. Avoid turning one game's convention into a universal rule.
