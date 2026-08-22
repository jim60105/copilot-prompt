# Menu Systems Reference

## Menu State Machines

### State Flow

```
Title Screen
  |
  +-- New Game --> Character Creation --> Loading --> Gameplay
  +-- Continue --> Save Select --> Loading --> Gameplay
  +-- Settings --> Settings Menu --> (back to Title)
  +-- Quit --> Confirm Dialog --> Exit

Gameplay
  |
  +-- Pause (Escape/Start)
        |
        +-- Resume --> Gameplay
        +-- Settings --> Settings Menu --> (back to Pause)
        +-- Save --> Save Menu --> (back to Pause)
        +-- Load --> Load Menu --> Confirm --> Loading --> Gameplay
        +-- Quit to Menu --> Confirm --> Title Screen
        +-- Quit to Desktop --> Confirm --> Exit
```

### State Machine Rules

- Every menu state must have a defined parent state for back navigation
- Escape/B button always goes to the parent state or closes the current menu
- The back navigation stack should be deterministic (no ambiguity about where "back" goes)
- Transitioning between states should preserve the previous state for return (do not rebuild from scratch)
- Save game state before entering any menu that allows quitting

---

## Settings Menu Patterns

### Category Organization

| Category | Settings |
|----------|----------|
| **Gameplay** | Difficulty, language, tutorial prompts, auto-aim, subtitles toggle |
| **Video/Display** | Resolution, window mode, refresh rate, VSync, quality presets, brightness, HDR, FOV |
| **Audio** | Master volume, music volume, SFX volume, voice volume, audio device, spatial audio |
| **Controls** | Key bindings, mouse sensitivity, gamepad sensitivity, invert Y axis, vibration |
| **Accessibility** | Colorblind mode, subtitle size, screen reader, font scaling, hold vs toggle, motion reduction |
| **Network** | Region, matchmaking preferences, voice chat, privacy settings |

### Settings Behavior

- **Live preview:** show the effect of video/audio changes in real-time
- **Apply / Revert:** for display settings, require explicit "Apply" and auto-revert after 15 seconds if not confirmed (prevents being stuck at unusable resolution)
- **Reset to defaults:** provide per-category and global reset options
- **Tooltips:** explain what each setting does in plain language
- **Settings persistence:** save to local file; cloud sync if applicable

### Settings UI Layout

```
+--------------------------------------------------+
| Settings                              [x] Close   |
+----------+---------------------------------------+
| Gameplay | Setting Label          [Value/Toggle]  |
| Video    | Setting Label          [Slider-----]  |
| Audio    | Setting Label          [Dropdown   v]  |
| Controls | Setting Label          [On/Off     ]  |
| Access.  |                                        |
|          | [Reset to Defaults]   [Apply] [Cancel] |
+----------+---------------------------------------+
```

---

## Pause Menu

### Game State Preservation

When the pause menu opens:
- Freeze game simulation (single-player) or show pause overlay (multiplayer)
- Dim or blur the game world behind the menu
- Preserve all game state -- nothing should change while paused
- Audio: reduce game audio volume, play menu music/ambient

### Pause Menu Options

Standard order:
1. **Resume** -- return to gameplay (also bound to Escape/Start)
2. **Settings** -- open settings menu
3. **Save Game** -- save current progress
4. **Load Game** -- load a different save
5. **Photo Mode** -- (if supported)
6. **Quit to Main Menu** -- with confirmation dialog
7. **Quit to Desktop** -- with confirmation dialog

### Pause in Multiplayer

- Cannot pause the game world in multiplayer
- Show a menu overlay while the game continues
- Clearly indicate the game is still running
- Auto-timeout: return to game after 30 seconds of inactivity in menu

---

## Save / Load UI

### Save Slot Display

```
+--------------------------------------------------+
| Save Slot 1                                        |
| [Screenshot]  Character: Warrior Lv.32             |
|               Location: Dragon's Keep              |
|               Playtime: 24h 13m                    |
|               Saved: 2026-03-21 14:30              |
|                                                    |
| [Save Here]  [Delete]                              |
+--------------------------------------------------+
```

### Save Information

Each save slot should display:
- Screenshot from the moment of saving
- Character name, class, and level
- Current location or chapter
- Total playtime
- Save date and time
- Save type indicator (manual, auto-save, quicksave)

### Auto-Save Indicators

- Show a subtle icon (floppy disk, spinning circle) when auto-saving
- Do not block gameplay during auto-save
- Place the auto-save indicator in a consistent, unobtrusive location (bottom-right corner)
- Auto-save at key moments: entering a new area, before boss fights, after quest completion

### Overwrite Confirmation

- Always confirm before overwriting an existing save
- Show what will be overwritten (screenshot, playtime, date)
- Provide "Save to new slot" as an alternative

---

## Character Selection / Creation

### Class Picker

- Show all available classes with icon, name, and brief description
- Highlight the selected class with visual emphasis
- Show a preview of the character (3D model, sprite, or portrait)
- Display key stats or abilities for the selected class
- Support gamepad navigation (left/right to cycle, A/Enter to select)

### Customization UI

| Category | Controls |
|----------|----------|
| **Appearance** | Preset faces/heads, or sliders for individual features |
| **Body** | Sliders for height, build, proportions |
| **Hair** | Style selector (grid of options) + color picker |
| **Colors** | Palette selector or RGB/HSV sliders |
| **Clothing/Armor** | Category tabs with item grid |
| **Accessories** | Toggle on/off, color options |

### Customization UX

- Show a real-time preview of all changes
- Allow camera rotation to view from different angles
- Provide randomize button for quick character generation
- Support undo/redo for customization changes
- Allow saving custom presets

### Name Input

- Show character count limit clearly
- Filter inappropriate content (profanity filter)
- Show availability for online games
- Provide a random name generator
- Support the platform's native keyboard

---

## Gamepad Navigation for Menus

### D-Pad Movement

- D-pad up/down: navigate between menu items vertically
- D-pad left/right: adjust values (sliders, options) or navigate tabs
- Movement should wrap around (down from the last item goes to the first)
- Visual focus indicator should be large and clear

### Button Assignments

| Button (Xbox / PlayStation) | Action |
|----------------------------|--------|
| A / X | Select, confirm |
| B / Circle | Back, cancel |
| X / Square | Secondary action, context-dependent |
| Y / Triangle | Tertiary action, context-dependent |
| LB/RB / L1/R1 | Switch between tabs or categories |
| LT/RT / L2/R2 | Page up/down in long lists |
| Start | Open/close pause menu |
| Back/Select | Open specific menu (map, inventory) |

### Focus Indicators for Gamepad

- Focused item must be highly visible (bright border, highlight background, or scale increase)
- Unfocused items should be clearly distinguishable from the focused item
- Focus indicator should animate smoothly between items (slide, not jump)
- Show the currently available button actions at the bottom of the screen

---

## Keyboard Navigation for Menus

### Standard Key Mappings

| Key | Action |
|-----|--------|
| Arrow Up/Down | Navigate between items |
| Arrow Left/Right | Adjust values, switch tabs |
| Enter / Space | Select, confirm |
| Escape | Back, cancel, close menu |
| Tab | Next section or control group |
| Shift+Tab | Previous section or control group |
| Home / End | Jump to first / last item |
| Page Up / Page Down | Scroll large lists |

### Keyboard-Specific Considerations

- Always show which key bindings are available (unlike gamepad, keyboard users may not discover them)
- Support rebinding all keys, including menu navigation
- Allow both WASD and arrow key navigation
- Show keyboard prompts when keyboard is the active input method, gamepad prompts when gamepad is active

---

## Menu Transitions

### Transition Types

| Transition | Use Case | Duration |
|-----------|----------|----------|
| **Slide left/right** | Navigating between sibling menus (tabs) | 200-300ms |
| **Slide up** | Sub-menu opening from a parent | 200ms |
| **Fade** | Overlaying a menu on gameplay | 200ms |
| **Scale up** | Modal confirmation dialog | 150ms |
| **Stagger** | List items appearing sequentially | 50ms delay between items |

### Transition Principles

- Back navigation should reverse the forward transition (if forward slides right, back slides left)
- Keep transitions under 300ms -- menus must feel snappy
- Allow skipping transitions by pressing the input again (pressing A during a transition should complete the transition and process the action)
- Disable input during the first 100ms of a transition to prevent double-selection

---

## Title Screen Patterns

### Elements

```
+--------------------------------------------------+
|                                                    |
|               [Background Scene]                   |
|                                                    |
|                  [GAME LOGO]                       |
|                                                    |
|              Press Start / Any Key                 |
|                                                    |
|               New Game                             |
|               Continue                             |
|               Settings                             |
|               Credits                              |
|               Quit                                 |
|                                                    |
|  v1.2.3                        [Legal notices]     |
+--------------------------------------------------+
```

### Title Screen Behavior

- "Press Start" prompt blinks or pulses subtly
- After pressing, transition to the menu options (fade or slide)
- If no save exists, "Continue" should be disabled or hidden
- Background can be an animated scene, video, or parallax artwork
- Version number should be visible but unobtrusive (bottom-left corner)

---

## Loading Screens

### Progress Indication

| Pattern | Implementation |
|---------|---------------|
| **Progress bar** | Horizontal fill bar with percentage |
| **Spinner** | Rotating icon for indeterminate loading |
| **Progress ring** | Circular fill indicator |
| **Icon animation** | Game-themed loading icon (spinning coin, walking character) |

### Loading Screen Content

- **Tips:** rotate gameplay tips during loading ("Hold Shift to sprint")
- **Artwork:** show concept art, screenshots, or character art
- **Lore:** show world-building text or story recaps
- **Interactive:** provide a mini-game or interactive element during loading

### Loading Screen UX

- Show a loading indicator immediately (do not show a blank screen)
- If loading takes longer than expected, update the player ("Loading... this may take a moment")
- Minimum display time: 0.5 seconds (prevent flash of loading screen for fast loads)
- Keep the loading screen functional even if loading stalls (allow cancellation or quitting)
- For fast loads, consider no loading screen at all (seamless transition)
