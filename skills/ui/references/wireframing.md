# Wireframing Reference

## Low-Fidelity Wireframe Conventions

### Visual Vocabulary

| Element | Representation | Notes |
|---------|---------------|-------|
| Image placeholder | Box with an X through it | Indicate image dimensions if known |
| Text block | Wavy horizontal lines | Number of lines indicates approximate length |
| Heading | Bold horizontal line | Thicker or bolder than body text lines |
| Button | Rectangle with label text | Use actual label text, not "Button" |
| Input field | Rectangle with placeholder text | Show label above the field |
| Link | Underlined text | Use actual link text |
| Icon | Small circle or square with label | Always label icons in wireframes |
| Dropdown | Rectangle with down arrow | Show the default selection |
| Checkbox/radio | Small square/circle | Show both checked and unchecked states |
| Logo | Rectangle with "LOGO" | Indicate approximate size |

### Fidelity Guidelines

- **Low-fi wireframes should not include:** color, real images, exact typography, shadows, gradients, or animations
- **Low-fi wireframes should include:** layout structure, content hierarchy, navigation, labels, and interaction annotations
- The purpose is to communicate structure and behavior, not visual design

---

## Text-Based / ASCII Wireframe Patterns

Since Claude produces text output, use these ASCII patterns to represent wireframes:

### Basic Page Layout

```
+--------------------------------------------------+
| [LOGO]          Navigation Item 1 | Item 2 | Item 3 |
+--------------------------------------------------+
|                                                    |
|  Page Title                                        |
|  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                   |
|                                                    |
|  +------------------+  +------------------+        |
|  |   [X]            |  |   [X]            |        |
|  |   Card Title     |  |   Card Title     |        |
|  |   ~~~ ~~~ ~~~    |  |   ~~~ ~~~ ~~~    |        |
|  |   [Button]       |  |   [Button]       |        |
|  +------------------+  +------------------+        |
|                                                    |
+--------------------------------------------------+
|  Footer content          Links | Links | Links     |
+--------------------------------------------------+
```

### Form Layout

```
+--------------------------------------------------+
|  Form Title                                        |
|                                                    |
|  Label                                             |
|  +--------------------------------------------+   |
|  | Placeholder text                            |   |
|  +--------------------------------------------+   |
|                                                    |
|  Label                                             |
|  +--------------------------------------------+   |
|  | Placeholder text                            |   |
|  +--------------------------------------------+   |
|  (!) Inline error message                          |
|                                                    |
|  Label                                             |
|  +--------------------+ v                          |
|  | Select an option   |                            |
|  +--------------------+                            |
|                                                    |
|  [x] I agree to the terms                          |
|                                                    |
|        [Cancel]  [  Submit  ]                       |
+--------------------------------------------------+
```

### Key for ASCII Wireframes

- `+---+` = container or card border
- `[X]` = image placeholder
- `~~~` = text content (body copy)
- `[Button]` = clickable button
- `v` = dropdown indicator
- `[x]` = checked checkbox
- `[ ]` = unchecked checkbox
- `(o)` = selected radio button
- `( )` = unselected radio button
- `(!)` = error or warning indicator
- `(i)` = informational note

---

## Layout Grids

### 12-Column Grid

The standard for responsive web design:

- **Desktop (>1024px):** 12 columns, 24px gutters, 72px margins
- **Tablet (768-1024px):** 8 columns, 16px gutters, 32px margins
- **Mobile (<768px):** 4 columns, 16px gutters, 16px margins

### Common Column Spans

| Layout | Desktop Columns | Tablet Columns | Mobile Columns |
|--------|----------------|----------------|----------------|
| Full width | 12 | 8 | 4 |
| Two equal | 6 + 6 | 4 + 4 | 4 (stacked) |
| Sidebar + content | 3 + 9 | 2 + 6 | 4 (stacked) |
| Three equal | 4 + 4 + 4 | 8 (stacked pairs) | 4 (stacked) |
| Four equal | 3 + 3 + 3 + 3 | 4 + 4 (two rows) | 4 (stacked) |

### Grid Rules

- Content should align to column edges
- Gutters provide breathing room between columns -- do not place content in gutters
- Margins provide padding from screen edges
- Nest grids within columns for complex layouts
- Break the grid intentionally and rarely (e.g., full-bleed hero images)

---

## Responsive Breakpoints

### Standard Breakpoints

| Name | Width | Typical Devices |
|------|-------|----------------|
| **Mobile small** | < 375px | Older phones, small screens |
| **Mobile** | 375px - 767px | Modern phones |
| **Tablet** | 768px - 1023px | Tablets in portrait |
| **Desktop** | 1024px - 1439px | Laptops, tablets in landscape |
| **Desktop large** | >= 1440px | Desktop monitors |

### Design Approach

- **Mobile-first:** design for the smallest screen first, then add complexity for larger screens
- **Content-first:** let the content determine where breakpoints are needed, not arbitrary device widths
- **Test at breakpoints AND between them** -- layouts should work at all widths, not just the defined breakpoints

### What Changes at Breakpoints

| Element | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| Navigation | Hamburger or bottom bar | Top bar (may collapse) | Full top bar or sidebar |
| Grid columns | 1-2 | 2-3 | 3-4+ |
| Typography | Smaller scale | Medium scale | Full scale |
| Images | Full width, smaller | Flexible sizing | Fixed or proportional |
| Spacing | Tighter | Medium | Full spacing scale |
| Interactions | Tap, swipe | Tap, some hover | Click, hover, drag |

---

## Content Prioritization in Wireframes

### Visual Hierarchy Principles

Establish hierarchy through size, weight, position, contrast, and spacing:

1. **Most important:** largest, boldest, highest on the page
2. **Supporting:** medium size, regular weight, near the primary content
3. **Tertiary:** smaller, lighter, lower on the page or in secondary positions
4. **Actions:** visually distinct from content (buttons, links)

### Reading Patterns

**F-Pattern (content-heavy pages):**
- Users scan horizontally across the top
- Then scan a shorter horizontal line below
- Then scan vertically down the left side
- Place the most important content at the top and left

**Z-Pattern (landing pages, marketing):**
- Users scan top-left to top-right
- Then diagonally down to bottom-left
- Then across to bottom-right
- Place the CTA at the bottom-right of the Z

**Center-stage pattern (dashboards):**
- Primary content occupies the center and majority of the screen
- Supporting tools and navigation occupy the periphery
- User focus is drawn to the center

---

## Annotation Standards

### Numbered Callouts

- Number each annotation sequentially
- Place the number near the element being annotated
- Include a legend at the bottom or side with explanations

### Annotation Content

Each annotation should specify:
1. **What the element is** (e.g., "Search input field")
2. **Behavior on interaction** (e.g., "Expands to show autocomplete suggestions on focus")
3. **Content requirements** (e.g., "Max 200 characters, supports Markdown")
4. **Error states** (e.g., "Shows inline error if query returns no results")
5. **Conditional visibility** (e.g., "Only shown to logged-in users")

### Interaction Notes

- Use arrows to indicate navigation flow between wireframes
- Label transitions (e.g., "On submit, navigate to confirmation screen")
- Note any animations or transitions (e.g., "Slide in from right")
- Indicate loading states (e.g., "Show skeleton while data loads")

---

## Wireframe-to-Prototype Progression

### Fidelity Levels

| Level | Content | Visual | Interaction | Purpose |
|-------|---------|--------|-------------|---------|
| **Low-fi** | Placeholder text, labels | No color, no styling | None (static) | Structure and layout validation |
| **Mid-fi** | Real content, actual labels | Basic styling, typography | Click-through navigation | Flow and content validation |
| **High-fi** | Final content | Full visual design | Full interaction, animations | Visual and interaction design validation |
| **Interactive prototype** | Final content | Full visual design | Working interactions, real data | Usability testing, stakeholder demo |

### When to Use Each Level

- **Low-fi:** early exploration, brainstorming, stakeholder alignment on structure
- **Mid-fi:** content strategy validation, developer estimation, initial usability testing
- **High-fi:** visual design review, final usability testing, accessibility auditing
- **Interactive prototype:** user testing with realistic tasks, final sign-off

---

## Common Page Templates

### Landing Page

```
+--------------------------------------------------+
| Navigation                                         |
+--------------------------------------------------+
| Hero: Headline + Subheading + CTA                  |
| [Hero Image or Video]                              |
+--------------------------------------------------+
| Social Proof / Logos                               |
+--------------------------------------------------+
| Feature 1    | Feature 2    | Feature 3            |
| [icon]       | [icon]       | [icon]               |
| Description  | Description  | Description          |
+--------------------------------------------------+
| Testimonials or Case Studies                       |
+--------------------------------------------------+
| CTA Section: Headline + Button                     |
+--------------------------------------------------+
| Footer                                             |
+--------------------------------------------------+
```

### Dashboard

```
+--------------------------------------------------+
| Top Bar: Logo | Search | Notifications | Profile  |
+--------+---------------------------------------+
| Sidebar| Summary Cards (KPIs)                  |
| Nav    |---------------------------------------+
| Item 1 | Primary Chart or Data View            |
| Item 2 |                                       |
| Item 3 |---------------------------------------+
| Item 4 | Secondary Content: Table or List      |
|        |                                       |
+--------+---------------------------------------+
```

### Form Page

```
+--------------------------------------------------+
| Navigation                                         |
+--------------------------------------------------+
| Form Title                                         |
| Progress indicator (Step 2 of 4)                   |
|                                                    |
| Section heading                                    |
| [Field] [Field]                                    |
| [Field]                                            |
|                                                    |
| Section heading                                    |
| [Field]                                            |
| [Field]                                            |
|                                                    |
| [Back]                            [Continue]       |
+--------------------------------------------------+
```

### List / Detail (Master-Detail)

```
+--------------------------------------------------+
| Navigation                                         |
+--------+---------------------------------------+
| Filters| List Item 1                           |
|        | List Item 2 (selected)                 |
| Search | List Item 3          | Detail Panel    |
|        | List Item 4          | Title           |
| Sort   | List Item 5          | Content         |
|        |                      | Actions         |
+--------+---------------------------------------+
```

### Search Results

```
+--------------------------------------------------+
| Navigation                                         |
+--------------------------------------------------+
| Search bar: [query text]           [Search]        |
| Showing X results for "query" | Sort: [Relevance]  |
+--------------------------------------------------+
| Filters  | Result 1: Title, snippet, metadata     |
|          | Result 2: Title, snippet, metadata     |
| Category | Result 3: Title, snippet, metadata     |
| Price    |                                         |
| Rating   | [< 1 2 3 ... 10 >] Pagination          |
+--------------------------------------------------+
```

---

## Mobile Wireframe Patterns

### Bottom Navigation

- Limit to 3-5 items
- Use icons with labels (never icons alone on mobile)
- Highlight the current section
- Consider a floating action button for the primary action

### Pull-to-Refresh

- Indicate the gesture is available (e.g., subtle arrow at top)
- Show loading indicator during refresh
- Provide feedback on completion

### Swipe Gestures

- Swipe left/right on list items for actions (delete, archive, favorite)
- Reveal action buttons behind the swiped item
- Provide alternative tap-based access to the same actions

### Mobile-Specific Considerations

- Thumb zone: place primary actions in the lower third of the screen
- One-handed operation: avoid requiring precise actions in the top corners
- Large touch targets: minimum 44x44px
- Avoid hover-dependent interactions

---

## Wireframe Review Checklist

Before finalizing any wireframe, verify:

- [ ] Content hierarchy is clear -- most important content is most prominent
- [ ] All interactive elements are labeled (buttons have text, icons have labels)
- [ ] Navigation is complete -- user can reach all sections
- [ ] Error states are documented for forms and data-dependent views
- [ ] Empty states are designed (what does the user see with no data?)
- [ ] Loading states are specified
- [ ] Responsive behavior is indicated for at least mobile and desktop
- [ ] Annotations explain interaction behavior, not just layout
- [ ] Content requirements are noted (character limits, required fields, data types)
- [ ] Accessibility considerations are noted (heading hierarchy, tab order, focus management)
- [ ] The wireframe matches the user flow it implements
- [ ] No dead ends -- every screen offers a path forward or back
