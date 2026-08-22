# HUD Systems Reference

## HUD Layout Patterns

### Screen Region Allocation

```
+--------------------------------------------------+
|  [Health/Shield]              [Minimap/Compass]   |
|                                                    |
|                                                    |
|                   [Crosshair]                      |
| [Damage          [Alerts/     [Damage              |
|  Indicator        Objectives]  Indicator]           |
|  Left]                         Right]               |
|                                                    |
|  [Status Effects]                                  |
|                                                    |
|  [Ammo/Resource]   [Hotbar/Abilities]  [Score/XP]  |
+--------------------------------------------------+
```

### Region Assignments

| Region | Content | Rationale |
|--------|---------|-----------|
| **Top-left** | Health, shield, player name | Frequently referenced, consistent placement across games |
| **Top-right** | Minimap, compass, scoreboard | Spatial awareness, secondary reference |
| **Bottom-left** | Ammo, resource counters, weapon info | Related to player actions |
| **Bottom-center** | Hotbar, ability bar, quick items | Central for quick access |
| **Bottom-right** | XP bar, quest tracker, score | Progress and goals |
| **Center** | Crosshair, interaction prompts | Immediate gameplay feedback |
| **Edges** | Damage indicators, alerts | Directional information |

### Layout Principles

- Keep the center of the screen clear for gameplay visibility
- Group related information together (health + shield, ammo + weapon)
- Anchor to screen corners and edges, not floating in arbitrary positions
- Maintain consistent positions -- do not move HUD elements during gameplay
- Reserve center for momentary feedback only (hit markers, interaction prompts)

---

## Health / Mana / Stamina Bars

### Bar Styles

| Style | Implementation | Best For |
|-------|---------------|----------|
| **Continuous bar** | Smooth fill from 0-100% | Simple health systems, RPGs |
| **Segmented bar** | Divided into discrete chunks | Games with hit-point segments (Dark Souls style) |
| **Circular/radial** | Arc or ring around an element | When screen space is limited, character portraits |
| **Numeric** | Number display (e.g., "85/100") | Precise values matter to gameplay |
| **Combined** | Bar + numeric overlay | When both visual and precise reading matter |

### Color Coding

| Resource | Color | Warning Color | Critical Color |
|----------|-------|--------------|----------------|
| Health | Green or red fill | Yellow (< 30%) | Red pulse/flash (< 15%) |
| Mana/Energy | Blue | Light blue (< 25%) | Flash (< 10%) |
| Stamina | Yellow or green | Orange (< 30%) | Red (< 15%) |
| Shield/Armor | Blue or cyan | Dim (< 25%) | Flash before breaking |

### Animation on Change

- **Damage:** instant reduction of the main bar + delayed reduction of a trailing bar (shows damage amount)
- **Healing:** smooth fill animation over 0.5-1 second
- **Regeneration:** subtle pulse while regenerating
- **Low health effects:** vignette, desaturation, heartbeat pulse, screen edge reddening
- **Shield break:** shatter animation, flash, sound cue

---

## Minimap Architecture

### Orientation Modes

| Mode | Behavior | Best For |
|------|----------|----------|
| **North-up (fixed)** | Map stays fixed, player icon rotates | Open world games, navigation-heavy |
| **Player-up (rotating)** | Map rotates so player always faces up | Action games, fast-paced movement |

### Minimap Elements

| Element | Representation | Priority |
|---------|---------------|----------|
| Player | Arrow or triangle pointing in facing direction | Always visible |
| Enemies | Red dots or triangles | High when in range |
| Allies/NPCs | Green or blue dots | Medium |
| Objectives | Highlighted icon or marker | High |
| Points of interest | Unique icons per type | Low-medium |
| Map terrain | Simplified top-down view | Background |

### Minimap Features

- **Zoom levels:** allow players to zoom the minimap in/out (mouse wheel or keybind)
- **Fog of war:** unexplored areas are hidden or dimmed
- **Edge indicators:** off-screen objective markers on the minimap border
- **Click to ping:** allow clicking the minimap to place markers (multiplayer)
- **Toggle size:** allow expanding minimap to larger view without opening full map

---

## Compass and Waypoint Systems

### Compass Bar

A horizontal strip at the top of the screen showing cardinal directions:
- N, E, S, W markers with degree markings
- Waypoint icons placed on the compass at the correct bearing
- Current facing direction centered on the compass
- Fade distant markers, brighten near markers

### Waypoint Markers

- **Quest markers:** unique icon per quest type, show distance
- **Custom markers:** player-placed pins with color options
- **Dynamic markers:** appear/disappear based on proximity or quest state
- **Vertical indicators:** show if the waypoint is above or below the player
- **Occlusion:** markers behind geometry should be dimmed or show through walls with reduced opacity

### Distance Indicators

| Distance | Display |
|----------|---------|
| < 10m | Distance hidden, interaction prompt shown |
| 10-100m | Exact distance in meters |
| 100-1000m | Distance in meters, marker prominent |
| > 1km | Distance in km (e.g., "1.2 km"), marker subtle |

---

## Damage Indicators

### Directional Damage

- Show a red wedge or arc on the screen edge indicating damage direction
- Wedge appears on the side the damage came from
- Fade out over 1-2 seconds
- Multiple simultaneous indicators for multiple damage sources

### Screen Effects

| Effect | Trigger | Duration |
|--------|---------|----------|
| **Vignette** | Taking damage | 0.5-1s, fade out |
| **Blood spatter** | Health damage | 1-2s, clear on heal |
| **Screen shake** | Explosion, heavy hit | 0.3-0.5s |
| **Chromatic aberration** | Critical health | Persistent while critical |
| **Desaturation** | Near death | Increases as health decreases |

### Hit Numbers (Damage Numbers)

- Float upward from the point of damage
- Color-code by damage type (white=normal, yellow=critical, red=fire, blue=ice)
- Scale size by damage amount
- Stagger positions to prevent overlap
- Fade out over 1-2 seconds
- Optional: combine rapid small hits into accumulated numbers

---

## Crosshairs and Reticles

### Types

| Type | Behavior | Use Case |
|------|----------|----------|
| **Static dot** | Fixed center point | Precise aiming (sniper) |
| **Dynamic cross** | Lines spread with movement/firing | Showing accuracy spread (FPS) |
| **Circle** | Ring that shrinks when aiming | Bloom/accuracy indicator |
| **Context-sensitive** | Changes shape based on target | Interaction prompts, weapon switching |

### Hit Confirmation

- Brief color flash on the crosshair (white or red)
- Small X or checkmark animation on hit
- Different indicator for headshot/critical hits
- Kill confirmation with distinct visual (skull icon, larger flash)
- Audio feedback paired with visual confirmation

---

## HUD Scaling and Safe Zones

### TV Safe Area

For console games, respect TV safe zones:
- **Action safe area:** 93% of screen (5% margin on each side) -- all interactive elements inside
- **Title safe area:** 90% of screen (5% margin on each side) -- all text inside
- Modern TVs have less overscan, but still design for safety

### Ultrawide Support

- Do not stretch HUD elements to fill ultrawide (21:9, 32:9)
- Anchor HUD to 16:9 boundaries or allow custom positioning
- Test at common aspect ratios: 16:9, 21:9, 32:9, 16:10, 4:3

### UI Scaling Options

- Provide a HUD scale slider (50% to 150% in 10% increments)
- Scale uniformly -- do not allow individual element scaling (too complex)
- Test at minimum and maximum scale to ensure nothing overlaps or goes off-screen
- Default to 100% and auto-detect high DPI displays

---

## Contextual HUD

### Show/Hide Based on Game State

| Game State | HUD Visibility | Rationale |
|------------|---------------|-----------|
| **Exploration** | Minimal -- compass, minimap, health | Maximize world visibility |
| **Combat** | Full -- all combat elements | Player needs all information |
| **Dialogue / Cutscene** | Hidden or minimal | Immersion; UI would obstruct |
| **Photo mode** | Fully hidden | Clean screenshot |
| **Menu open** | HUD dimmed or hidden | Focus on menu content |
| **Safe zone / town** | Minimal | Low threat, less info needed |

### Fade Behavior

- HUD elements fade in when relevant and fade out when not
- Use 0.3-0.5 second transitions
- Health bar can auto-hide when full and show on damage
- Ammo counter can show on weapon draw and hide when holstered
- Always allow a "show all" toggle for players who prefer persistent HUD

---

## Ammo and Resource Counters

### Numeric Display

```
[Icon] 24 / 120
        ^    ^
   Magazine  Reserve
```

### Magazine Visualization

- Show individual rounds for small magazines (shotgun, revolver)
- Use a numeric counter for large magazines
- Flash or change color when low (last 25%)
- Show reload indicator when magazine is empty

### Resource Counters

| Resource Type | Display Pattern |
|--------------|----------------|
| **Ammunition** | Current / Reserve with weapon icon |
| **Grenades/Items** | Icon with count, dim when at zero |
| **Currency** | Icon with number, abbreviate large values (1.2K, 3.5M) |
| **Crafting materials** | Icon with count, show only when relevant |
| **Cooldowns** | Circular sweep or countdown number over icon |

---

## Status Effect Indicators

### Display Patterns

- Row of small icons near the health bar or in a dedicated status area
- Each icon represents one active buff or debuff
- Show remaining duration as a circular timer sweep or countdown number
- Stack identical effects with a multiplier number (x3)

### Visual Hierarchy

| Priority | Style | Example |
|----------|-------|---------|
| **Positive (buff)** | Blue or green border, upward arrow | Damage boost, speed increase |
| **Negative (debuff)** | Red or orange border, downward arrow | Poison, slow, burning |
| **Neutral** | Gray or white border | Immunity, transformation |
| **Critical** | Pulsing border, larger size | Lethal poison, incoming death |

### Overflow Handling

- If many effects are active, show the most important 6-8
- Provide "..." or expand button to see all active effects
- Sort by priority: critical > debuffs > buffs
- Sort within priority by remaining duration (expiring soonest first)
