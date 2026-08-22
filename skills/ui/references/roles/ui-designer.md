# UI Designer

## Role -> Reference Mapping

| Role | Reference Files |
|------|----------------|
| **UI Designer** | design-systems.md, interaction-patterns.md, accessibility.md, ui-patterns.md |

## Detection Keywords

- design system, design tokens, component spec, visual design, style guide
- interaction design, accessibility, WCAG, UI pattern, micro-interaction
- animation, color contrast, ARIA, keyboard navigation, screen reader
- form design, navigation pattern, responsive design, theming

## UI Task Type Routing Table

| Request Signal | Task Type | References Loaded |
|---|---|---|
| "design system", "component library", "design language", "atomic design" | **design-system** | design-systems.md |
| "component spec", "component design", "button spec", "input spec", "component API" | **component-spec** | design-systems.md, ui-patterns.md |
| "interaction design", "micro-interaction", "animation", "transition", "loading state", "gesture" | **interaction-design** | interaction-patterns.md |
| "design tokens", "color tokens", "spacing scale", "typography scale", "theming" | **design-tokens** | design-systems.md |
| "accessibility review", "WCAG audit", "a11y", "screen reader", "keyboard navigation", "color contrast" | **accessibility-review** | accessibility.md |
| "UI pattern", "form design", "navigation design", "table design", "modal design", "responsive layout" | **ui-patterns** | ui-patterns.md, interaction-patterns.md |

## UI Task Type Instructions

| Task Type | What the sub-agent does |
|---|---|
| **design-system** | Define or extend a design system: token foundations, component inventory, naming conventions, governance, and documentation standards |
| **component-spec** | Specify a UI component: props/variants, states, accessibility requirements, usage guidelines, and do/don't examples |
| **interaction-design** | Design interaction patterns: micro-interactions, transitions, loading states, gestures, and feedback mechanisms |
| **design-tokens** | Define design token architecture: color palette, spacing scale, typography scale, elevation, motion tokens, and theming strategy |
| **accessibility-review** | Audit an interface against WCAG 2.1 AA: contrast ratios, keyboard navigation, ARIA usage, screen reader compatibility; produce findings with severity |
| **ui-patterns** | Design UI patterns for specific needs: forms, tables, navigation, modals, empty states, error handling, responsive layouts |

## Guardrails

- **All designs must meet WCAG 2.1 Level AA** -- color contrast, keyboard navigation, ARIA labels, focus management
- **Components must specify all states** -- default, hover, active, focus, disabled, error, loading
- **Design tokens must be used** -- no hardcoded values; reference tokens for color, spacing, typography
- **Responsive behavior must be specified** -- how the component adapts at each breakpoint
- **Interaction feedback must be defined** -- every user action must have visible feedback
- **Dark mode must be addressed** -- state whether the design supports theming and how
