# Design Systems Reference

## Atomic Design Methodology

### The Five Levels

| Level | Definition | Examples |
|-------|-----------|---------|
| **Atoms** | Smallest indivisible UI elements | Button, input field, label, icon, badge, avatar |
| **Molecules** | Simple groups of atoms functioning together | Search bar (input + button), form field (label + input + error), card header (avatar + name + timestamp) |
| **Organisms** | Complex, distinct sections of an interface | Header (logo + nav + search bar + user menu), product card (image + title + price + button), comment thread (avatar + text + actions) |
| **Templates** | Page-level structures showing content placement | Dashboard layout, settings page layout, list-detail layout |
| **Pages** | Specific instances of templates with real content | User dashboard with actual data, settings page with current values |

### Working with Atomic Design

- Design atoms first -- they are the foundation of visual consistency
- Molecules combine atoms to create reusable functional units
- Organisms are where the design system meets product needs
- Templates define layout without specifying content
- Pages are for testing with real content (edge cases, long strings, empty states)

### Component Composition Patterns

- **Slots:** components accept children in defined regions (e.g., Card accepts CardHeader, CardBody, CardFooter)
- **Props:** components accept configuration values (e.g., Button accepts variant="primary", size="large")
- **Compound components:** related components that share state (e.g., Tabs, TabList, Tab, TabPanel)
- **Render props / children as function:** components that delegate rendering to their consumer

---

## Design Tokens

### Token Categories

#### Color Palette

**Semantic colors (preferred for component use):**

| Token | Purpose | Example Value |
|-------|---------|---------------|
| `color-primary` | Primary brand action | #2563EB |
| `color-primary-hover` | Primary on hover | #1D4ED8 |
| `color-secondary` | Secondary action | #64748B |
| `color-success` | Positive feedback | #16A34A |
| `color-warning` | Caution | #D97706 |
| `color-error` | Error states | #DC2626 |
| `color-info` | Informational | #0284C7 |
| `color-text-primary` | Body text | #1E293B |
| `color-text-secondary` | Supporting text | #64748B |
| `color-text-disabled` | Disabled text | #94A3B8 |
| `color-text-inverse` | Text on dark backgrounds | #FFFFFF |
| `color-bg-primary` | Page background | #FFFFFF |
| `color-bg-secondary` | Card/section background | #F8FAFC |
| `color-bg-tertiary` | Subtle background | #F1F5F9 |
| `color-border` | Default borders | #E2E8F0 |
| `color-border-focus` | Focus ring | #2563EB |

**Neutral scale:** a 10-step grayscale from white to black, used as the base for semantic tokens.

#### Spacing Scale

Base unit: 4px. All spacing uses multiples of the base.

| Token | Value | Common Use |
|-------|-------|-----------|
| `space-0` | 0px | No spacing |
| `space-1` | 4px | Tight inline spacing |
| `space-2` | 8px | Related element spacing |
| `space-3` | 12px | Compact component padding |
| `space-4` | 16px | Standard component padding |
| `space-5` | 20px | Section gap (small) |
| `space-6` | 24px | Section gap (medium) |
| `space-8` | 32px | Section gap (large) |
| `space-10` | 40px | Page section spacing |
| `space-12` | 48px | Large section spacing |
| `space-16` | 64px | Major section spacing |

#### Typography Scale

Use a modular scale (ratio 1.25 or 1.333) for harmonious sizing:

| Token | Size | Weight | Line Height | Use |
|-------|------|--------|-------------|-----|
| `text-xs` | 12px | 400 | 16px | Captions, helper text |
| `text-sm` | 14px | 400 | 20px | Secondary text, labels |
| `text-base` | 16px | 400 | 24px | Body text |
| `text-lg` | 18px | 500 | 28px | Subheadings, emphasis |
| `text-xl` | 20px | 600 | 28px | Card titles |
| `text-2xl` | 24px | 600 | 32px | Section headings |
| `text-3xl` | 30px | 700 | 36px | Page headings |
| `text-4xl` | 36px | 700 | 40px | Hero headings |

#### Border Radius

| Token | Value | Use |
|-------|-------|-----|
| `radius-none` | 0px | Sharp corners |
| `radius-sm` | 2px | Subtle rounding |
| `radius-md` | 4px | Default for inputs, cards |
| `radius-lg` | 8px | Prominent rounding |
| `radius-xl` | 12px | Modal dialogs, feature cards |
| `radius-full` | 9999px | Circular elements, pills |

#### Shadow / Elevation

| Token | Value | Use |
|-------|-------|-----|
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.05) | Subtle lift (cards) |
| `shadow-md` | 0 4px 6px rgba(0,0,0,0.1) | Dropdowns, popovers |
| `shadow-lg` | 0 10px 15px rgba(0,0,0,0.1) | Modals, dialogs |
| `shadow-xl` | 0 20px 25px rgba(0,0,0,0.15) | Floating panels |

#### Transition / Motion Timing

| Token | Value | Use |
|-------|-------|-----|
| `duration-fast` | 100ms | Hover states, toggles |
| `duration-normal` | 200ms | Transitions, fade in/out |
| `duration-slow` | 300ms | Complex animations, modals |
| `duration-slower` | 500ms | Page transitions |
| `ease-default` | cubic-bezier(0.4, 0, 0.2, 1) | General purpose |
| `ease-in` | cubic-bezier(0.4, 0, 1, 1) | Elements leaving the screen |
| `ease-out` | cubic-bezier(0, 0, 0.2, 1) | Elements entering the screen |
| `ease-in-out` | cubic-bezier(0.4, 0, 0.2, 1) | Elements moving on screen |

---

## Component API Patterns

### Props and Variants

Every component should define:
- **Variants:** visual variations (e.g., Button: primary, secondary, ghost, destructive)
- **Sizes:** scale options (e.g., sm, md, lg)
- **States:** interactive states (default, hover, active, focus, disabled, error, loading)
- **Boolean flags:** optional features (e.g., fullWidth, disabled, loading)

### Component State Matrix

| State | Visual Indicators | Behavior |
|-------|------------------|----------|
| **Default** | Base styling | Normal interaction |
| **Hover** | Subtle background change, cursor change | Mouse over (desktop only) |
| **Active / Pressed** | Darkened or pressed appearance | Mouse down or touch |
| **Focus** | Visible focus ring (2px solid, offset) | Keyboard navigation |
| **Disabled** | Reduced opacity (0.5), no pointer | No interaction, removed from tab order |
| **Error** | Red border, error icon, error message | Validation failure |
| **Loading** | Spinner or skeleton, disabled | Waiting for async operation |

### Documentation for Each Component

Every component in the design system should have:

1. **Description** -- what it is and when to use it
2. **Variants** -- each variant with its use case
3. **Props table** -- name, type, default, description
4. **States** -- visual representation of each state
5. **Usage guidelines** -- when to use and when not to use
6. **Do / Don't examples** -- correct and incorrect usage
7. **Accessibility** -- ARIA roles, keyboard behavior, screen reader behavior
8. **Code example** -- implementation reference

---

## Theming

### Light and Dark Mode

Every design system should support at minimum light and dark themes:

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `color-bg-primary` | #FFFFFF | #0F172A |
| `color-bg-secondary` | #F8FAFC | #1E293B |
| `color-text-primary` | #1E293B | #F8FAFC |
| `color-text-secondary` | #64748B | #94A3B8 |
| `color-border` | #E2E8F0 | #334155 |

### Implementation Strategy

- Use CSS custom properties (variables) for all token values
- Switch themes by changing custom property values on a root element
- Test all components in both themes -- do not assume inverting colors works
- Ensure contrast ratios meet WCAG AA in both themes

### Brand Theming

For white-label or multi-brand products:
- Define a core token set that brands override
- Limit overridable tokens to colors, typography, and border radius
- Do not allow structural changes through theming (spacing, layout)
- Test each brand theme independently

---

## Naming Conventions

### Token Naming Pattern

`{category}-{property}-{variant}-{state}`

Examples:
- `color-text-primary` -- category: color, property: text, variant: primary
- `color-bg-error-hover` -- category: color, property: bg, variant: error, state: hover
- `space-4` -- category: space, value: 4 (16px)
- `radius-md` -- category: radius, variant: md

### Component Naming

Use PascalCase for component names, BEM-inspired for sub-elements:

- `Button` -- the component
- `ButtonGroup` -- a container for related buttons
- `Card`, `CardHeader`, `CardBody`, `CardFooter` -- compound component
- `FormField`, `FormLabel`, `FormInput`, `FormError` -- compound component

---

## Design System Governance

### Contribution Process

1. **Proposal** -- describe the need, show examples, explain why existing components do not suffice
2. **Review** -- design system team evaluates against principles and existing patterns
3. **Design** -- create the component spec following system standards
4. **Build** -- implement following component API patterns
5. **Document** -- add to the component library with all required documentation
6. **Release** -- version bump, changelog entry, migration guide if breaking

### Deprecation Process

1. Mark the component as deprecated in documentation
2. Provide a migration path to the replacement
3. Set a removal timeline (at least 2 major versions)
4. Log usage to track migration progress
5. Remove only when usage reaches zero or the timeline expires

### Versioning

- **Patch (0.0.x)** -- bug fixes, no API changes
- **Minor (0.x.0)** -- new components or variants, backward compatible
- **Major (x.0.0)** -- breaking changes, removed components, API changes

---

## Icon Systems

### Icon Grid

- Use a consistent grid size (e.g., 24x24px with 2px padding)
- Maintain consistent stroke width across all icons (e.g., 1.5px or 2px)
- Align to pixel grid to avoid blurriness at small sizes

### Icon Sizing

| Token | Size | Use |
|-------|------|-----|
| `icon-xs` | 12px | Inline with small text |
| `icon-sm` | 16px | Inline with body text, form indicators |
| `icon-md` | 20px | Buttons, navigation items |
| `icon-lg` | 24px | Section headers, standalone |
| `icon-xl` | 32px | Feature icons, empty states |

### Icon Naming Convention

`{category}-{object}` -- e.g., `action-edit`, `nav-arrow-left`, `status-error`, `file-document`

---

## Motion and Animation Tokens

### Duration Scale

- **Micro (50-100ms):** state changes (hover, toggle)
- **Short (150-200ms):** simple transitions (fade, color change)
- **Medium (250-350ms):** layout changes (expand, slide)
- **Long (400-500ms):** complex animations (page transitions, modals)
- **Extra long (500ms+):** decorative animations (use sparingly)

### Easing Curves

| Name | Curve | Use Case |
|------|-------|----------|
| Standard | ease-in-out | General movement, repositioning |
| Decelerate | ease-out | Elements entering the screen |
| Accelerate | ease-in | Elements leaving the screen |
| Linear | linear | Progress bars, opacity changes |

### Reduced Motion

Always provide a `prefers-reduced-motion` alternative:
- Replace animations with instant state changes or simple fades
- Keep opacity transitions (they are generally safe)
- Remove parallax, auto-playing animations, and complex transitions
- Maintain functionality -- reduced motion should not remove features
