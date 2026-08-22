# Game UI Designer

## Role -> Reference Mapping

| Role | Reference Files |
|------|----------------|
| **Game UI Designer** | hud-systems.md, menu-systems.md, game-ui-patterns.md, game-ui-accessibility.md |

## Detection Keywords

- game UI, HUD, game menu, inventory UI, health bar, minimap
- dialog system, game overlay, game HUD, quest log, crafting UI
- skill tree, loot popup, tooltip, crosshair, damage indicator
- game settings menu, save/load UI, character creation, shop UI

## Game UI Task Type Routing Table

| Request Signal | Task Type | References Loaded |
|---|---|---|
| "HUD", "heads-up display", "health bar", "minimap", "crosshair", "damage indicator", "status effects", "ammo counter" | **hud-design** | hud-systems.md |
| "game menu", "main menu", "pause menu", "settings menu", "title screen", "loading screen" | **menu-architecture** | menu-systems.md |
| "inventory", "equipment", "item management", "loot", "crafting", "shop UI", "vendor" | **inventory-ui** | game-ui-patterns.md |
| "dialog", "dialogue system", "quest log", "journal", "tooltip", "skill tree", "map UI" | **dialog-ui** | game-ui-patterns.md, menu-systems.md |
| "game accessibility", "colorblind", "subtitle", "input remapping", "game font size", "one-handed", "game screen reader" | **game-ui-accessibility** | game-ui-accessibility.md |

## Game UI Task Type Instructions

| Task Type | What the sub-agent does |
|---|---|
| **hud-design** | Design HUD layout, element placement, scaling strategy, and contextual visibility rules; specify how each element responds to game state changes |
| **menu-architecture** | Design menu state machines, navigation flow, gamepad/keyboard support, and transitions; cover settings categories and save/load patterns |
| **inventory-ui** | Design inventory, equipment, crafting, or shop interfaces: grid/list layouts, item comparison, drag-and-drop, filtering, and tooltip systems |
| **dialog-ui** | Design dialogue presentation, quest tracking, journal systems, skill trees, or map interfaces; specify text reveal, branching, and navigation |
| **game-ui-accessibility** | Audit or design game UI for accessibility: colorblind modes, subtitles, input remapping, font scaling, screen reader support, motion sensitivity |

## Guardrails

- **Must specify gamepad and keyboard navigation** -- every game UI element must be navigable without a mouse
- **HUD elements must respect safe zones** -- account for TV overscan and ultrawide monitor support
- **UI scaling must be defined** -- how the interface adapts to different resolutions and DPI settings
- **Game state transitions must be specified** -- what happens to UI during loading, cutscenes, pause, death
- **Performance impact must be considered** -- minimize draw calls, use texture atlases, avoid per-frame layout recalculation
- **Localization must be considered** -- text containers must handle varying string lengths across languages
