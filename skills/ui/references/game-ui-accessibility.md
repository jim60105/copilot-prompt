# Game UI Accessibility Reference

## Colorblind Modes

### Color Vision Deficiency Types

| Type | Prevalence | Affected Colors | Common Confusions |
|------|-----------|----------------|-------------------|
| **Protanopia** (no red cones) | ~1% of males | Red-green | Red and green look similar, red appears dark |
| **Deuteranopia** (no green cones) | ~5% of males | Red-green | Red and green look similar, green appears muted |
| **Tritanopia** (no blue cones) | ~0.003% | Blue-yellow | Blue and yellow look similar |

### Implementation Approaches

**UI Element Recoloring:**
- Provide preset color palettes for each deficiency type
- Replace red/green with blue/orange or blue/yellow
- Test with colorblindness simulation tools (Sim Daltonism, Color Oracle)

**Shape and Icon Alternatives:**
- Never rely on color alone to convey information
- Use distinct shapes alongside colors (triangle for warning, circle for info, X for error)
- Add patterns or textures to differentiate colored elements (hatching, dots, stripes)
- Team indicators: use shapes, symbols, or outlines in addition to team colors

**Colorblind Mode Options:**
- Protanopia filter
- Deuteranopia filter
- Tritanopia filter
- Custom color override (let players pick their own colors for key UI elements)

### Testing

- Simulate each type of color blindness and verify all UI remains functional
- Verify that enemy vs. ally distinction works in all modes
- Verify that item rarity is distinguishable in all modes
- Verify that health/mana/stamina bars are readable in all modes

---

## Subtitle Systems

### Speaker Identification

- **Color-coded names:** each speaker has a unique, distinguishable color (test with colorblind modes)
- **Name labels:** show the speaker's name before their dialogue text
- **Portrait icons:** small portrait next to the speaker's name

### Sound Description

For deaf and hard-of-hearing players:
- Describe significant sounds in brackets: [Explosion in the distance], [Footsteps behind you]
- Indicate direction when relevant: [Growling -- left side]
- Describe music cues: [Tense music begins], [Music fades]
- Indicate when silence is meaningful: [Silence]

### Subtitle Display Options

| Setting | Options |
|---------|---------|
| **Font size** | Small, medium, large, extra large |
| **Background opacity** | 0%, 25%, 50%, 75%, 100% |
| **Background color** | Black, dark gray (default: semi-transparent black) |
| **Text color** | White (default), yellow, custom |
| **Position** | Bottom center (default), top, custom vertical position |
| **Line count** | 1-3 lines visible simultaneously |

### Subtitle Best Practices

- Maximum 2 lines of text on screen at a time
- Minimum display time: 1 second per line or 0.3 seconds per word (whichever is longer)
- Sync subtitles with audio timing
- Do not overlap multiple speakers' subtitles
- Provide separate toggles for dialogue subtitles and sound descriptions

---

## Input Remapping UI

### Full Rebinding

- Allow rebinding every game action to any key, button, or axis
- Show the current binding next to each action
- Support "press any key" binding mode (press the key you want to assign)
- Show a conflict warning if a key is already bound to another action
- Allow multiple keys bound to the same action (alternatives)

### Conflict Detection

When a player assigns a key already in use:
- Show a warning: "[Key] is already bound to [Action]. Reassign?"
- Options: swap the bindings, unbind the conflicting action, or cancel
- Never silently unbind an existing action

### Preset Schemes

Provide named control presets:
- **Default:** the standard layout
- **Alternative:** common alternative (e.g., swapped sticks)
- **Accessibility:** one-handed, simplified, or reach-optimized
- **Legacy:** layout from a previous game in the series
- **Custom:** player's personalized layout

### Separate Binding Contexts

- Keyboard/mouse bindings separate from gamepad bindings
- Allow different bindings for different game modes (on foot vs. driving vs. flying)
- Touch bindings for mobile (if applicable)

### Hold-to-Reassign

- Optional: hold a key for 2 seconds to reassign in a simplified view
- Show a progress indicator during the hold
- Provide a "Reset all to default" button

---

## Difficulty Settings UI

### Preset Difficulties

| Preset | Description Style |
|--------|------------------|
| Easy / Story | "Focus on the narrative. Combat is forgiving." |
| Normal | "A balanced experience for most players." |
| Hard | "A serious challenge. Enemies are tougher." |
| Custom | "Tune individual settings to your preference." |

### Custom Difficulty Sliders

| Slider | Range | Example |
|--------|-------|---------|
| Enemy health | 0.5x to 2.0x | Controls how much damage enemies can take |
| Enemy damage | 0.5x to 2.0x | Controls how much damage enemies deal |
| Player health | 0.5x to 2.0x | Controls the player's health pool |
| Resource scarcity | Abundant to Scarce | Controls how often items and ammo appear |
| Puzzle assistance | Off to Full hints | Controls hint availability for puzzles |

### Accessibility Assists (Separate from Difficulty)

These should NOT be tied to difficulty level:
- Auto-aim strength
- Hold vs. toggle for sprint, aim, crouch
- Skip-puzzle option
- Navigation assistance (enhanced waypoints)
- QTE assistance (slower timing, auto-complete option)
- Combat assistance (parry timing window, dodge window)

### No-Shame Messaging

- Never mock or penalize players for choosing lower difficulty
- Describe what changes, not who it is "for"
- Allow changing difficulty at any time during gameplay
- Do not lock content behind difficulty levels (except optional achievements)

---

## Font Scaling

### Minimum Readable Sizes

| Context | Minimum Size | Recommended Size |
|---------|-------------|-----------------|
| Body text | 18px at 1080p | 22-24px at 1080p |
| UI labels | 16px at 1080p | 18-20px at 1080p |
| HUD elements | 14px at 1080p | 16-18px at 1080p |
| Subtitle text | 22px at 1080p | 26-28px at 1080p |

### Scaling Options

- Provide a font size slider (80% to 200%)
- Scale relative to the base resolution (adjust for 720p, 1080p, 1440p, 4K)
- Show a live preview of the selected size

### UI Reflow at Large Sizes

- Text containers must grow to accommodate larger text
- Use flexible layouts that reflow content rather than truncating
- Test at maximum font scale to ensure no text is cut off
- Consider reducing HUD element count at very large font sizes

### Dynamic Text Containers

- Never use fixed-height text containers for user-facing text
- Allow text boxes to expand vertically
- Scrollbars for constrained areas (tooltip, quest description)
- Truncation with "..." and expand option as a last resort

---

## Screen Reader Support in Games

### Menu Narration

- Read aloud all menu items, labels, and values as the player navigates
- Announce the current selection and available actions
- Read tooltip content when focused on an item
- Announce state changes ("Difficulty changed to Easy")

### Item Description Reading

- Automatically read item name, type, stats, and special effects
- Read comparison information ("5 more attack power than equipped")
- Speak rarity level
- Allow re-reading with a keybind

### Navigation Announcements

- Announce when entering a new menu section
- Announce the current position in lists ("Item 3 of 15")
- Announce available navigation directions ("Press right to go to Equipment tab")
- Announce when reaching the end of a list

### Combat Log Reading

- Provide an optional combat log that screen readers can access
- Announce critical events: damage taken, status effects, health warnings
- Use distinct tones or earcons for different event types
- Allow filtering which events are announced

---

## One-Handed Control Options

### Input Simplification

- Remap all essential controls to one side of the keyboard or one gamepad stick
- Provide toggle mode for sprint/aim/crouch instead of hold
- Allow auto-movement (character moves forward automatically)
- Combine actions where possible (auto-reload, auto-climb)

### Movement Assist

- Auto-aim with adjustable strength
- Aim lock-on (snap to nearest target)
- Auto-path-finding to waypoints
- Simplified combat inputs (one-button combos)

### Accessibility Controller Support

- Support adaptive controllers (Xbox Adaptive Controller)
- Support switch-based input (single switch, dual switch)
- Support sip-and-puff controllers
- Allow extreme deadzone customization
- Support foot pedal input

---

## Motion Sensitivity

### Camera Shake

- Provide a toggle to disable camera shake entirely
- Alternatively, provide an intensity slider (0% to 100%)
- Default: reduced or off (opt-in to camera shake is more accessible)

### Screen Shake

- Separate setting from camera shake (screen shake affects the entire viewport)
- Intensity slider: 0% to 100%
- Consider replacing shake with alternative feedback (flash, sound, controller vibration)

### Motion Blur

- Provide a toggle to disable motion blur
- Motion blur should be off by default
- If enabled, provide an intensity slider

### Field of View (FOV)

- Provide an FOV slider (60 to 120 degrees)
- Default: 90 degrees for first-person, 60-70 for third-person
- Wide FOV can reduce motion sickness for some players
- Narrow FOV can reduce it for others -- let the player choose

### Additional Motion Settings

- **Head bob:** toggle on/off or intensity slider
- **Screen effects intensity:** vignette, chromatic aberration, film grain
- **Camera smoothing:** how quickly the camera follows movement
- **Aim sway:** reduce or disable weapon sway during aiming

---

## Audio Accessibility

### Visual Sound Indicators

For deaf and hard-of-hearing players:
- Show a sound radar or visual indicator showing the direction of important sounds
- Use icons or symbols to represent sound types (footsteps, gunfire, voice, environmental)
- Show intensity (distance/volume) through icon size or opacity
- Position indicators on the screen edge corresponding to the sound's direction

### Directional Audio Visualization

```
+--------------------------------------------------+
|                   [Gunfire]                         |
|                                                    |
| [Footsteps]          [Player]         [Explosion]  |
|                                                    |
|                   [Voice]                          |
+--------------------------------------------------+
```

### Volume Per Channel

Provide separate volume controls for:
- Master volume
- Music
- Sound effects
- Voice / dialogue
- Ambient / environmental
- UI sounds
- Voice chat (multiplayer)

### Audio Cue Alternatives

When audio communicates gameplay information:
- Provide a visual alternative (screen flash, icon, text prompt)
- Provide a haptic alternative (controller vibration pattern)
- Document which sounds carry gameplay significance

---

## Accessibility Menu Organization

### Dedicated Accessibility Section

- Place accessibility settings in their own top-level settings category
- Do not bury accessibility options deep in sub-menus
- Group by type: visual, audio, controls, gameplay assists

### First-Launch Accessibility Prompt

On first launch, before gameplay:
- Ask about key accessibility preferences: subtitle size, colorblind mode, control scheme
- Keep this prompt brief (3-5 settings maximum)
- Allow skipping with "Use defaults"
- Make it easy to find the full settings later

### In-Game Toggle Access

- Allow toggling key accessibility features during gameplay via quick menu or keybind
- Subtitle toggle: accessible during cutscenes
- Colorblind mode: accessible from pause menu
- Font size: accessible from any menu
- Do not require restarting the game for accessibility changes

### Accessibility Settings Checklist

Before shipping, verify the game includes:

- [ ] Subtitle options (toggle, size, background, speaker names)
- [ ] Colorblind mode options (at least protanopia and deuteranopia)
- [ ] Font scaling option
- [ ] Full input remapping
- [ ] Separate volume controls per audio channel
- [ ] Camera shake / motion settings
- [ ] Toggle vs. hold options for sustained inputs
- [ ] Visual alternatives for audio cues
- [ ] Gamepad and keyboard navigation for all menus
- [ ] Contrast and brightness settings
- [ ] Tutorial skip option
- [ ] Difficulty customization separate from accessibility
