# Accessibility and Platform Guidelines

Snapshot reviewed: 2026-10-05.

Prefer current official sources when web access is available. Platform guidance can change. Treat the numeric values below as a dated fallback snapshot and verify before using them as release criteria.

## Xbox Accessibility Guidelines

Index: https://learn.microsoft.com/en-us/xbox/accessibility/guidelines

Microsoft describes the Xbox Accessibility Guidelines (XAGs) as best practices for designers, developers, and test teams. They are not presented as legal-compliance certification.

### XAG 101: Text display

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101

Current snapshot values found in the guideline:

- Console default text: at least 26 px at 1080p, 52 px at 4K.
- PC/VR default text: at least 18 px at 1080p, 36 px at 4K.
- Mobile/Xbox Game Streaming: 18 px at 100 DPI, 36 px at 200 DPI, 72 px at 400 DPI, scaling linearly with DPI.

Use these as platform-specific reference points, not as universal typography laws. Viewing distance, device size, localization, typeface metrics, and user scaling still need testing.

### XAG 102: Contrast

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102

Current snapshot values:

- Standard-size important text and visual elements: at least 4.5:1 against background.
- Large-scale text and visual elements: at least 3:1.
- Inactive-element text: at least 3:1.
- High-contrast-mode elements: target 7:1 in the guideline's current implementation guidance.

For gameplay HUDs over moving imagery, test the lowest-contrast background condition. Consider backing plates, outlines, opacity controls, and color configurability.

### XAG 103: Additional channels for visual and audio cues

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103

Critical visual information should have at least one additional sensory method where appropriate, such as audio, haptics, or narration. Critical audio information should have a visual or other alternative. Avoid using color as the sole carrier of essential meaning.

### XAG 107: Input

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107

Design so players can operate interfaces through supported input mechanisms that fit their needs. Audit assumptions about analog precision, simultaneous presses, holds, timing, reach, and device type. When a game supports rebinding or multiple input devices, update prompts to match the active mapping.

### XAG 109: Objective clarity

Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/109

Provide a way to review tasks and objectives. For games with long narratives or long gaps between play sessions, support story/progress review. Descriptive saves can include location, time, image, and progress context.

### XAG 112: UI navigation

Source: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112

Keep menu navigation consistent. Use logical focus order that preserves meaning and tracks visual layout. Make paths to important settings accessible from initial launch.

### XAG 113: UI focus handling

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/113

Every focusable UI element should expose a highly visible focus indication. Test focus against every background state, including overlays and dialog boxes.

### XAG 114: UI context

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114

Give enough context for players to understand where they are in the UI hierarchy, what a control does, and what will happen when it is activated. Announce or visibly communicate context changes that are not initiated by the player.

### XAG 115: Error messages and destructive actions

Source: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/115

Make errors identifiable and correctable. For permanent or destructive actions, provide review, confirmation, cancellation, reversal, or undo where feasible. The current guideline explicitly advises against requiring a button hold as the only confirmation mechanism for destructive actions.

## AbleGamers Accessible Player Experiences

Overview: https://accessible.games/accessible-player-experiences/  
Second Channel pattern: https://accessible.games/accessible-player-experiences/access-patterns/second-channel/

APX organizes accessibility around barriers in player experiences rather than around a list of diagnoses. Its 22 design patterns include Clear Text, Second Channel, Flexible Displays, Personal Interface, Flexible Controllers, Distinguish This From That, Training Ground, Undo Redo, Total Recall, and Save Early, Save Often.

Use APX to brainstorm alternatives and configurability during concept and prototyping. Pair it with platform-specific test criteria when preparing release checklists.
