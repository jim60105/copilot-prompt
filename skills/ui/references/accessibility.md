# Accessibility Reference

## WCAG 2.1 Level AA Requirements

Organized by the four principles (POUR):

### Perceivable

Users must be able to perceive the information presented.

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| **1.1.1 Non-text Content** | All non-text content has a text alternative | `alt` attributes on images, labels on icons, captions on video |
| **1.2.1 Audio/Video** | Captions for prerecorded audio, descriptions for prerecorded video | Provide synchronized captions and audio descriptions |
| **1.3.1 Info and Relationships** | Structure and relationships conveyed through presentation are programmatically determinable | Use semantic HTML: headings, lists, tables, landmarks |
| **1.3.2 Meaningful Sequence** | Reading order is logical and meaningful | DOM order matches visual order; use CSS for visual positioning only |
| **1.3.3 Sensory Characteristics** | Instructions do not rely solely on shape, color, size, position, or sound | "Click the green button" must also say "Click the Submit button" |
| **1.4.1 Use of Color** | Color is not the only visual means of conveying information | Pair color with text, icons, or patterns |
| **1.4.2 Audio Control** | Auto-playing audio can be paused or stopped | Provide controls; prefer not auto-playing |
| **1.4.3 Contrast (Minimum)** | Text has 4.5:1 contrast ratio (3:1 for large text) | See contrast requirements below |
| **1.4.4 Resize Text** | Text can be resized to 200% without loss of content | Use relative units (rem, em), test at 200% zoom |
| **1.4.5 Images of Text** | Use real text, not images of text | Exception: logos |
| **1.4.10 Reflow** | Content reflows at 320px width without horizontal scrolling | Responsive design, no fixed-width layouts |
| **1.4.11 Non-text Contrast** | UI components and graphics have 3:1 contrast | Borders, icons, focus rings |

### Operable

Users must be able to operate the interface.

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| **2.1.1 Keyboard** | All functionality available from keyboard | Tab, Enter, Space, Arrow keys, Escape |
| **2.1.2 No Keyboard Trap** | Keyboard focus can always be moved away | Modals must allow Escape; no infinite focus loops |
| **2.4.1 Bypass Blocks** | Skip mechanism for repeated content | Skip links, landmark roles |
| **2.4.2 Page Titled** | Pages have descriptive titles | `<title>` element describes the page |
| **2.4.3 Focus Order** | Focus order is logical and meaningful | Tab order follows visual and reading order |
| **2.4.4 Link Purpose** | Link purpose is clear from text or context | Avoid "click here"; use descriptive link text |
| **2.4.6 Headings and Labels** | Headings and labels describe topic or purpose | Use descriptive, unique headings |
| **2.4.7 Focus Visible** | Keyboard focus indicator is visible | Never remove outline; enhance with custom focus styles |
| **2.5.5 Target Size** | Touch/click targets are at least 44x44px | Larger targets with adequate spacing |

### Understandable

Users must be able to understand the information and operation.

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| **3.1.1 Language of Page** | Page language is programmatically set | `<html lang="en">` |
| **3.2.1 On Focus** | Focus does not trigger unexpected changes | No auto-submit on focus, no unexpected navigation |
| **3.2.2 On Input** | Input does not trigger unexpected changes | Warn before auto-submitting; provide explicit submit |
| **3.3.1 Error Identification** | Errors are identified and described in text | Show error message next to the field |
| **3.3.2 Labels or Instructions** | Labels or instructions for user input | All fields have visible labels |
| **3.3.3 Error Suggestion** | Suggest corrections when errors are detected | "Did you mean user@example.com?" |
| **3.3.4 Error Prevention** | Allow review and correction before submission | Confirmation step for financial/legal transactions |

### Robust

Content must be robust enough for assistive technologies.

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| **4.1.1 Parsing** | No duplicate IDs, proper nesting | Valid HTML |
| **4.1.2 Name, Role, Value** | All UI components have accessible name, role, and value | Use semantic HTML or ARIA |
| **4.1.3 Status Messages** | Status messages are announced without focus | Use `role="status"` or `aria-live` |

---

## Color Contrast Requirements

### Contrast Ratios

| Content Type | Minimum Ratio | Tool |
|-------------|---------------|------|
| Normal text (< 18pt / 14pt bold) | **4.5:1** | WebAIM Contrast Checker |
| Large text (>= 18pt / 14pt bold) | **3:1** | WebAIM Contrast Checker |
| UI components (borders, icons) | **3:1** | Against adjacent colors |
| Focus indicators | **3:1** | Against surrounding content |
| Disabled elements | No minimum | But should be visually distinct |

### Testing Contrast

- Test against the actual background color, not white
- Test in both light and dark modes
- Test with transparency and gradients (use the resulting computed color)
- Test placeholder text (often fails -- use a label instead)

---

## ARIA Patterns

### Landmark Roles

| Role | HTML Element | Purpose |
|------|-------------|---------|
| `banner` | `<header>` | Site header |
| `navigation` | `<nav>` | Navigation blocks |
| `main` | `<main>` | Primary content |
| `complementary` | `<aside>` | Supporting content |
| `contentinfo` | `<footer>` | Site footer |
| `search` | `<search>` or `role="search"` | Search functionality |
| `form` | `<form>` | Named form regions |
| `region` | `<section>` | Generic labeled section |

### Common Widget Patterns

**Tabs:**
```
role="tablist" on container
role="tab" on each tab, aria-selected="true/false"
role="tabpanel" on each panel, aria-labelledby="tab-id"
Arrow keys to navigate between tabs
```

**Modal dialog:**
```
role="dialog", aria-modal="true", aria-labelledby="title-id"
Focus trapped inside dialog
Escape closes dialog
Focus returns to trigger on close
```

**Accordion:**
```
button with aria-expanded="true/false", aria-controls="panel-id"
panel with role="region", aria-labelledby="button-id"
```

**Combobox (autocomplete):**
```
role="combobox", aria-expanded, aria-autocomplete
role="listbox" for the options list
role="option" for each option, aria-selected
```

### Live Regions

| Attribute | Behavior |
|-----------|----------|
| `aria-live="polite"` | Announced after current speech finishes (use for most updates) |
| `aria-live="assertive"` | Interrupts current speech (use for errors only) |
| `role="status"` | Implicit `aria-live="polite"` (use for status updates) |
| `role="alert"` | Implicit `aria-live="assertive"` (use for errors) |

---

## Keyboard Navigation

### Standard Key Bindings

| Key | Action |
|-----|--------|
| **Tab** | Move focus to next focusable element |
| **Shift + Tab** | Move focus to previous focusable element |
| **Enter** | Activate link or button |
| **Space** | Activate button, toggle checkbox |
| **Arrow keys** | Navigate within components (tabs, menus, radio groups) |
| **Escape** | Close modal, dropdown, or popover |
| **Home / End** | Jump to first / last item in a list |

### Focus Management

- **Tab order** should follow visual and logical reading order
- **Roving tabindex:** within a composite widget (toolbar, menu), one element has `tabindex="0"` and the rest have `tabindex="-1"`; arrow keys move the `tabindex="0"` between elements
- **Focus traps:** modals and drawers should trap focus inside until closed
- **Focus restoration:** when a modal or popover closes, return focus to the element that opened it
- **Skip links:** the first focusable element on the page should skip navigation

---

## Screen Reader Considerations

### Heading Hierarchy

- Use one `<h1>` per page (the page title)
- Do not skip heading levels (do not go from `h2` to `h4`)
- Headings create an outline that screen reader users navigate by
- Every section of content should have a heading

### Alternative Text

| Image Type | Alt Text |
|-----------|----------|
| Informative image | Describe the content: "Bar chart showing revenue growth from $1M to $3M" |
| Decorative image | Use `alt=""` (empty alt) or CSS background |
| Functional image (button/link) | Describe the action: "Submit form", "Close dialog" |
| Complex image (chart, diagram) | Provide a summary in alt + detailed description nearby or via `aria-describedby` |

### Form Labels

- Every input must have a visible `<label>` associated via `for` and `id`
- Group related inputs with `<fieldset>` and `<legend>`
- Required fields: indicate in the label text ("Email (required)") or with `aria-required="true"`
- Error messages: associate with `aria-describedby` on the input

### Live Region Announcements

- Use `aria-live="polite"` for non-urgent updates (new search results, item added to cart)
- Use `role="alert"` for error messages
- Keep announcements concise -- screen readers do not handle long text well
- Do not update live regions too frequently (throttle to avoid overwhelming users)

---

## Forms Accessibility

### Accessible Form Patterns

1. **Label every field** -- use `<label for="id">` (not just placeholder text)
2. **Group related fields** -- `<fieldset>` with `<legend>` for radio groups, address blocks
3. **Mark required fields** -- in the label text and with `aria-required="true"`
4. **Error messages** -- display inline next to the field, associate with `aria-describedby`
5. **Autocomplete** -- use `autocomplete` attribute for common fields (name, email, address, credit card)
6. **Input types** -- use appropriate `type` attribute (email, tel, url, number, date) for proper keyboard on mobile
7. **Instructions** -- provide before the form or at the top, not hidden at the bottom

### Error Handling

- Move focus to the first error field on submit (or to an error summary)
- Use `aria-invalid="true"` on fields with errors
- Describe the error in text next to the field
- Suggest corrections when possible
- Do not clear the form on error

---

## Color-Independent Communication

Information must never rely on color alone:

| Bad | Good |
|-----|------|
| Red fields have errors | Red fields with error icon and error text message |
| Green dot = online | Green dot + "Online" text label |
| Red/green chart bars | Patterned bars + legend with text labels |
| Yellow = warning | Warning icon + "Warning:" prefix + yellow highlight |

---

## Touch Target Sizes

### Minimum Sizes

| Platform | Minimum Target Size | Recommended |
|----------|-------------------|-------------|
| Mobile (WCAG) | 44x44px | 48x48px |
| Mobile (Material) | 48x48px | 48x48px |
| Mobile (Apple HIG) | 44x44pt | 44x44pt |
| Desktop | 24x24px | 32x32px |

### Spacing Between Targets

- Minimum 8px spacing between adjacent touch targets
- Group related targets closer, separate unrelated targets further
- Place destructive actions (delete) away from frequent actions (save)

---

## Testing Tools and Methods

### Automated Testing

| Tool | What It Tests |
|------|--------------|
| **axe-core / axe DevTools** | WCAG violations in the DOM |
| **Lighthouse** | Accessibility score + specific issues |
| **ESLint jsx-a11y** | Accessibility issues in JSX at lint time |
| **Pa11y** | Automated WCAG testing in CI pipelines |

### Manual Testing

1. **Keyboard-only navigation** -- can you complete all tasks without a mouse?
2. **Screen reader testing** -- test with VoiceOver (macOS), NVDA (Windows), or Orca (Linux)
3. **Zoom testing** -- test at 200% and 400% zoom
4. **Color contrast** -- check with WebAIM Contrast Checker or browser DevTools
5. **Reduced motion** -- enable `prefers-reduced-motion` and verify animations are suppressed

---

## Common Accessibility Violations and Fixes

### Top 10 Issues

1. **Missing alt text** -- add descriptive `alt` attributes to all informative images
2. **Low contrast text** -- increase contrast to meet 4.5:1 ratio
3. **Missing form labels** -- add `<label>` elements associated with inputs via `for`/`id`
4. **Missing document language** -- add `lang` attribute to `<html>` element
5. **Empty links/buttons** -- add visible text or `aria-label` to all interactive elements
6. **Missing skip link** -- add a skip-to-content link as the first focusable element
7. **Keyboard traps** -- ensure Escape closes modals and focus returns to trigger
8. **Missing heading structure** -- use proper heading hierarchy (h1 through h6, no skips)
9. **Auto-playing media** -- provide pause/stop controls; prefer no auto-play
10. **Focus indicator removed** -- never remove `outline` on focus; enhance it instead

### Fix Priority

- Fix Critical issues first (prevent task completion)
- Then Major issues (significant difficulty for some users)
- Then Minor issues (inconvenience or suboptimal experience)
- Address Cosmetic issues as part of regular development
