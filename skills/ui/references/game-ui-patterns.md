# Game UI Patterns Reference

## Inventory UI

### Layout Types

| Layout | Description | Best For |
|--------|------------|----------|
| **Grid** | Items in a fixed-size grid of slots | RPGs with many items (Diablo, Minecraft) |
| **List** | Vertical list with item details | When items have important text descriptions |
| **Paper doll** | Character silhouette with equipment slots | Equipment management, visual feedback |
| **Bag/container** | Multiple grid containers | Inventory organization, limited bag space |

### Grid Inventory Features

- Fixed slot count or expandable (unlock more slots as progression)
- Item icons with rarity border color (gray, green, blue, purple, gold)
- Stack count in the corner of stackable items
- Empty slots clearly distinguishable from filled slots
- Drag-and-drop for moving items between slots
- Right-click or long-press context menu (use, equip, drop, destroy)

### Item Comparison Tooltip

```
+----------------------------------+
| [Item Name]              [Rarity] |
| [Item Type]                       |
|                                   |
| +15 Attack Power    (^ +5)       |
| +8 Critical Chance  (v -2)       |
| +20 Health                        |
|                                   |
| Special: Chance to ignite         |
|                                   |
| Requires: Level 15               |
| [Equipped item comparison below]  |
+----------------------------------+
```

- Green up-arrows for stat improvements over current equipment
- Red down-arrows for stat decreases
- Show the item being compared against (currently equipped)
- Include special effects, set bonuses, and requirements

### Sorting and Filtering

- Sort by: name, type, rarity, level, value, recent
- Filter by: type (weapon, armor, consumable), rarity, usable by class
- Provide a search box for inventories with many items
- Remember last sort/filter preference

### Stack Splitting

- Hold a modifier key and click to split a stack
- Show a slider or number input to choose the split amount
- Drag half-stack to a new slot

---

## Tooltip Systems

### Hover Behavior

- Delay before showing: 300-500ms (prevents tooltip flash during mouse movement)
- Follow the mouse cursor or anchor to the element
- Position to avoid going off-screen (flip sides if near an edge)
- Fade in over 100ms, fade out immediately on mouse leave

### Pinned Tooltips

- Allow clicking or pressing a key to pin a tooltip in place
- Pinned tooltips remain visible while the user interacts elsewhere
- Useful for item comparison (pin one item, hover another)
- Show a close button on pinned tooltips

### Comparison Tooltips

- Show two tooltips side by side when comparing items
- Clearly label which is "equipped" and which is "new"
- Highlight stat differences with color (green = better, red = worse)
- Include set bonus information if applicable

### Context-Sensitive Content

- Tooltip content changes based on context (inventory vs. shop vs. crafting)
- In shop: show price and buy/sell value
- In crafting: show materials and quantity needed
- In combat: show quick stats only (abbreviate)

---

## Crafting UI

### Recipe List

- Show all known recipes in a categorized list or grid
- Indicate craftable (have materials) vs. uncraftable (missing materials)
- Gray out or dim recipes with insufficient materials
- Show material costs with current inventory counts

### Crafting Interface Layout

```
+--------------------------------------------------+
| Crafting: [Category Tabs]                          |
+------------------+-------------------------------+
| Recipe List      | Selected Recipe                 |
|                  |                                 |
| [icon] Sword  *  | [Result Item Preview]          |
| [icon] Shield    |                                 |
| [icon] Potion *  | Materials:                      |
| [icon] Scroll    | [icon] Iron x3 (have: 5)       |
|                  | [icon] Wood x1 (have: 0) [!]   |
| * = craftable    |                                 |
|                  | [Craft] [Craft All]             |
+------------------+-------------------------------+
```

### Crafting Queue

- Show items being crafted with progress bars
- Allow cancellation of queued items (refund materials)
- Show estimated time for completion
- Provide a notification when crafting completes

### Discovery / Unlock

- Unknown recipes shown as "???" or locked icon
- Unlock through gameplay: finding recipes, leveling crafting skill, completing quests
- Show unlock conditions if appropriate ("Requires Blacksmithing Level 5")

---

## Quest Log / Journal

### Structure

```
+--------------------------------------------------+
| Quest Log                                          |
+------------------+-------------------------------+
| Active Quests    | Quest: [Quest Name]             |
|                  |                                 |
| > Main Story     | [Quest giver portrait]          |
|   Quest A [!]    |                                 |
|   Quest B        | Description text here.          |
|                  |                                 |
| > Side Quests    | Objectives:                     |
|   Quest C        | [x] Find the lost sword         |
|   Quest D        | [ ] Return to the blacksmith    |
|                  |                                 |
| Completed        | Rewards:                        |
| Failed           | [icon] 500 Gold                 |
|                  | [icon] Iron Sword               |
|                  |                                 |
|                  | [Track] [Abandon]               |
+------------------+-------------------------------+
```

### Quest Tracking

- Allow players to track 1-3 active quests on the HUD
- Tracked quests show objectives on screen with waypoint markers
- Provide a keybind to quickly toggle quest tracking
- Sort: tracked first, then by proximity or priority

### Objective Checklist

- Checkboxes for each objective
- Completed objectives are checked and may be struck through or dimmed
- Show progress for count-based objectives ("Kill goblins: 3/10")
- Bonus objectives clearly marked as optional

### Reward Preview

- Show all rewards before accepting or completing a quest
- For choice rewards, let the player select before turning in
- Show XP, currency, and items with icons and quantities

---

## Dialogue Systems

### Text Presentation

| Feature | Implementation |
|---------|---------------|
| **Typewriter reveal** | Characters appear one at a time (40-60 chars/second) |
| **Skip** | Press button to instantly show full text |
| **Auto-advance** | Optional: automatically advance after a delay |
| **Text speed setting** | Slow, normal, fast, instant |
| **Speaker portrait** | Character image next to the dialogue box |
| **Speaker name** | Colored or labeled name above or beside the text |

### Dialogue Box Layout

```
+--------------------------------------------------+
| [Portrait]  Speaker Name                           |
|                                                    |
| Dialogue text appears here with typewriter         |
| effect, one character at a time...                 |
|                                                    |
|                              [Continue indicator]  |
+--------------------------------------------------+
```

### Choice Buttons

- Display choices vertically below the dialogue text
- Highlight the focused choice (for gamepad/keyboard navigation)
- Show consequences or skill checks if applicable ("[Persuade] Let us pass")
- Gray out unavailable choices with a reason ("Requires: Charisma 15")
- Number choices for keyboard shortcut access (1, 2, 3)

### Branching Indicators

- Show when a choice leads to a significant branch (icon or color)
- Optionally show when a choice is a "point of no return"
- Post-choice: indicate which branch was taken in the quest log

---

## Notification / Toast Systems

### Priority Queue

| Priority | Content | Duration | Behavior |
|----------|---------|----------|----------|
| **Critical** | Quest complete, level up, achievement | Until dismissed | Large, prominent, center or top |
| **High** | Item acquired, objective update | 5 seconds | Medium, top or side |
| **Medium** | XP gain, resource pickup | 3 seconds | Small, side or bottom |
| **Low** | Environmental hint, flavor text | 2 seconds | Minimal, corner |

### Stacking Behavior

- Maximum 3-4 visible notifications at once
- New notifications push older ones down or up
- If the queue is full, newer high-priority messages replace lower-priority ones
- Group identical notifications ("Picked up Iron Ore x5" instead of five separate toasts)

### Auto-Dismiss and Interaction

- All notifications auto-dismiss after their duration
- Click/tap to dismiss immediately
- Notification center or log to review missed notifications
- Critical notifications may require a button press to dismiss

---

## Loot / Reward Popups

### Item Reveal

```
+----------------------------------+
|        [Glow/Particle Effect]     |
|                                   |
|          [Item Icon]              |
|                                   |
|     [Item Name] [Rarity Color]    |
|     +15 Attack Power              |
|     Special: Fire damage           |
|                                   |
|  [Equip Now]  [Add to Inventory]  |
|  [Compare]    [Dismantle]         |
+----------------------------------+
```

### Rarity Effects

| Rarity | Visual Treatment |
|--------|-----------------|
| Common (white/gray) | No special effect |
| Uncommon (green) | Subtle glow |
| Rare (blue) | Prominent glow, particles |
| Epic (purple) | Intense glow, particles, sound |
| Legendary (gold/orange) | Full-screen flash, unique animation, fanfare |

### Batch Loot

- For many items at once, show a scrollable loot window
- "Take All" button for convenience
- "Auto-sort" to organize by rarity or type
- Comparison tooltips on hover

---

## Shop / Vendor UI

### Layout

```
+--------------------------------------------------+
| Shop: [Vendor Name]                    Gold: 5,420 |
+------------------+-------------------------------+
| Buy | Sell        | [Item Grid or List]            |
|                  |                                 |
| Categories:      | [Item] [Item] [Item]           |
| Weapons          | [Item] [Item] [Item]           |
| Armor            |                                 |
| Consumables      | Selected Item:                  |
| Materials        | [Preview] + Stats + Price       |
|                  |                                 |
|                  | [Buy x1] [Buy x5] [Buy x10]    |
+------------------+-------------------------------+
```

### Shop Features

- Show the player's current currency balance prominently
- Items the player cannot afford are dimmed with price in red
- Compare shop items to currently equipped items
- Show buy and sell prices (sell price is typically lower)
- Buyback tab for recently sold items
- Confirm before expensive purchases

---

## Skill Tree UI

### Node Graph

- Nodes connected by lines/paths showing prerequisites
- Unlocked nodes are bright and colored
- Locked but available nodes have a subtle highlight or glow
- Locked and unavailable nodes are dimmed/grayed
- Lines between nodes show the required path

### Interaction

- Click/select a node to see its description
- Allocate points to unlock nodes
- Show total points available and spent
- Provide a reset/respec option (may cost in-game currency)
- Zoom in/out for large skill trees
- Pan to navigate the tree

### Hover Preview

- Show skill name, description, and effect values
- Show stat changes at the next rank
- Show prerequisites not yet met
- Show synergies with other skills

---

## Map UI

### Map Layers

| Layer | Content |
|-------|---------|
| **Terrain** | Landmass, water, elevation, biomes |
| **Roads/Paths** | Routes, trails, roads |
| **Locations** | Towns, dungeons, points of interest (icons) |
| **Player markers** | Current position, waypoints, party members |
| **Quest markers** | Active quest objectives with icons |
| **Fog of war** | Unexplored areas hidden or obscured |

### Map Interaction

- Zoom in/out with mouse wheel, pinch, or buttons
- Pan by dragging or with WASD/arrow keys
- Click locations to see details (name, discovered status, fast travel option)
- Click to place custom waypoints
- Show a legend explaining icon meanings

### Fast Travel

- Available only to discovered/unlocked locations
- Show travel time or cost if applicable
- Confirm before traveling
- Show loading screen during travel

### Map Fog of War

- Completely unexplored: fully opaque, no detail visible
- Explored but not visible: terrain visible, but no dynamic elements (enemies, NPCs)
- Currently visible: full detail with dynamic elements
- Reveal fog of war as the player explores
