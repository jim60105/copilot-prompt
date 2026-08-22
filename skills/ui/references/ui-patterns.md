# UI Patterns Reference

## Navigation Patterns

### Top Bar Navigation

- Horizontal bar at the top of the page
- Best for 3-7 top-level items
- Include logo (left), nav items (center or left), and utility items (right: search, notifications, profile)
- On mobile: collapse into hamburger menu or move to bottom bar
- Current item should be visually indicated (underline, background, bold)

### Sidebar Navigation

- Vertical navigation on the left side of the page
- Best for applications with many sections or deep hierarchy
- Can be collapsible (full width with labels or icon-only)
- Supports grouping with section headers
- Shows nested items via expand/collapse or flyout

### Bottom Tabs (Mobile)

- Fixed at the bottom of the screen
- 3-5 items maximum
- Each tab has an icon and label (never icon only)
- Active tab is visually distinct (color, filled icon)
- Tapping the active tab should scroll to top or refresh

### Breadcrumbs

- Show the path from the root to the current page
- Each level is a clickable link except the current page
- Use a separator character (/ or >) between levels
- Do not use breadcrumbs as the primary navigation
- Most useful for hierarchical content structures

### Mega Menu

- Large dropdown panel showing multiple categories
- Include icons, descriptions, or featured items
- Group items logically (not alphabetically unless that serves users)
- Close on click outside, Escape key, or selection
- Support keyboard navigation with arrow keys

### Hamburger Menu

- Use only when space constraints prevent showing navigation items directly
- Always label it (three lines icon + "Menu" text)
- Opens a full-width or sidebar panel
- Ensure the panel can be closed via a close button, Escape, and clicking outside

---

## Form Patterns

### Single Column Forms

- All fields stack vertically in a single column
- Optimal for most forms -- reduces eye tracking and decision complexity
- Use consistent field widths or size fields to match expected input length
- Group related fields with visual separators or section headings

### Multi-Step Forms (Wizards)

- Break long forms into logical steps
- Show a progress indicator (step counter, progress bar, or breadcrumb)
- Validate each step before allowing progression
- Provide back navigation and the ability to review previous steps
- Save draft state so users can resume later
- Show a summary/review step before final submission

### Inline Validation

- Validate on blur (when the user leaves the field), not on every keystroke
- Show success confirmation for complex fields (email format, password strength)
- Show errors immediately next to the field, not in a distant location
- Use color + icon + text for error messages (never color alone)
- Do not clear the field on error -- let the user correct their input

### Auto-Save

- Save automatically after a short delay (1-2 seconds of inactivity)
- Show a subtle save indicator ("Saved" or "Saving..." in the header)
- Handle conflicts if multiple users edit simultaneously
- Provide version history or undo capability
- Still provide an explicit save/submit button for important transitions

### Conditional Fields

- Show or hide fields based on previous selections
- Animate the reveal (slide down, fade in)
- Clearly associate conditional fields with their trigger
- Do not require hidden fields for validation

---

## Table Patterns

### Sortable Tables

- Clicking a column header sorts by that column
- Show sort direction with an arrow indicator (up/down)
- Default sort should be the most useful order for the user
- Allow sorting by multiple columns (shift+click)
- Remember sort preferences across sessions

### Filterable Tables

- Provide filter controls above the table or in a sidebar
- Show active filters as chips/tags with removal option
- Show the count of filtered results ("Showing 15 of 234")
- Provide a "Clear all filters" option
- Apply filters in real-time when practical, on explicit action for complex queries

### Pagination vs Infinite Scroll

| Aspect | Pagination | Infinite Scroll |
|--------|-----------|----------------|
| Best for | Structured data, search results | Social feeds, content browsing |
| Navigation | Users can jump to specific pages | Users can only scroll forward |
| Performance | Predictable, bounded | Unbounded, may degrade |
| Bookmarking | Easy (URL includes page number) | Difficult (no stable position) |
| Footer access | Always accessible | Impossible without separate access |

### Responsive Tables

| Pattern | Implementation | Best For |
|---------|---------------|----------|
| **Horizontal scroll** | Table scrolls horizontally within a container | Wide tables with many columns |
| **Stack** | Each row becomes a card with label-value pairs | Simple tables on mobile |
| **Collapse columns** | Hide less important columns on small screens | Tables with clear priority columns |
| **Toggle columns** | Let users choose which columns to show | Data-heavy tables |

### Row Actions

- Place common actions in the last column (edit, delete, view)
- Use icon buttons with tooltips for actions
- For many actions, use a "more actions" dropdown (three dots)
- Support bulk actions with checkbox selection and action bar

---

## Modal / Dialog Patterns

### When to Use Modals

**Use modals for:**
- Confirmation of destructive actions ("Delete this item?")
- Critical decisions that require immediate attention
- Short forms that do not require navigation context

**Do not use modals for:**
- Informational messages (use toast or banner instead)
- Long forms or complex workflows (use a full page instead)
- Errors that can be shown inline
- Content that users might want to reference while interacting with the page

### Modal Behavior

- Trap focus inside the modal (Tab cycles through modal elements)
- Close on Escape key
- Close on backdrop click (unless confirming destructive action)
- Return focus to the trigger element on close
- Prevent scrolling of the background content
- Add `role="dialog"`, `aria-modal="true"`, and `aria-labelledby`

### Nested Modals

Avoid nested modals. If a modal needs to open another dialog:
- Replace the current modal content instead of stacking
- Or use a slide-over panel within the modal
- If nesting is truly necessary, ensure each modal manages its own focus trap

---

## Notification Patterns

### Toast Notifications

- Position: top-right (desktop) or top-center/bottom-center (mobile)
- Duration: 3-5 seconds for success/info, persistent until dismissed for errors
- Stack: newest on top, limit visible count to 3
- Content: icon + brief message + optional action link
- Always include a close/dismiss button

### Banner Notifications

- Full-width bar at the top of the page (below navigation)
- Use for system-wide messages: maintenance, new features, policy changes
- Persistent until dismissed
- Include a close button
- Use semantic colors: blue for info, yellow for warning, red for error, green for success

### Badge Counts

- Small circle overlapping an icon to show unread/new count
- Show exact count up to a threshold (e.g., "99+")
- Remove when the user views the content
- Use a dot (no number) for binary unread/new indicators

---

## Search Patterns

### Search Bar

- Prominent placement: center of top bar or dedicated area
- Placeholder text should describe what can be searched ("Search products, orders, help...")
- Show a clear/reset button when the field has content
- Support Enter to submit and Escape to clear

### Autocomplete Suggestions

- Show suggestions after 2-3 characters
- Debounce input (300ms typical) to avoid excessive requests
- Highlight the matching portion of each suggestion
- Support keyboard navigation (arrow keys to select, Enter to confirm)
- Show search history for empty input (with clear history option)

### Faceted Search

- Filters organized by category (price, brand, color, size)
- Show counts next to each filter option
- Allow multiple selections within a category
- Update results in real-time
- Show active filters as removable chips

### Empty Results

- Show a clear message: "No results found for [query]"
- Offer suggestions: check spelling, try different keywords, browse categories
- Show popular or related items as alternatives
- Provide a way to clear the search and start over

---

## List / Detail Patterns

### Master-Detail

- List on the left, detail on the right (desktop)
- Selected item in the list highlights and shows detail
- On mobile: list is full screen, selecting an item navigates to detail (with back button)
- Keyboard: arrow keys to navigate list, Enter to select

### Split View

- Side-by-side panels, resizable
- Each panel can scroll independently
- Useful for email, file management, comparison views
- Collapse to single panel on narrow screens

### Expandable Rows

- Click a row to expand and show more detail inline
- Only one row expanded at a time (accordion behavior) or multiple (independent expansion)
- Use a chevron icon to indicate expandability
- Animate expand/collapse smoothly

---

## Empty States

### First-Use Empty State

- Welcome message or brief explanation
- Clear call to action ("Create your first project")
- Optional illustration or icon
- Keep it encouraging, not intimidating

### No Results Empty State

- Acknowledge the search/filter produced no results
- Suggest corrections or alternatives
- Provide a clear path to try again

### Error Empty State

- Explain what went wrong in plain language
- Provide a retry action
- Offer an alternative path (contact support, go to home page)

### Guidance Text

- Empty states are an opportunity to teach users about the feature
- Show what the area will look like when populated
- Include a call to action that begins populating the area

---

## Error States

### Inline Field Errors

- Show below the field, associated with `aria-describedby`
- Use error color + icon + descriptive text
- Trigger on blur or submit (not on every keystroke)
- Do not clear the user's input

### Form-Level Errors

- Summary at the top of the form listing all errors
- Each error links to the corresponding field
- Use `role="alert"` for the error summary
- Move focus to the error summary on submit

### Page-Level Errors

- Full-page error states (404, 500, permission denied)
- Use plain language, not error codes
- Provide clear next steps (go home, try again, contact support)
- Maintain site navigation so the user is not stranded

### Error Recovery

- Provide a clear action to resolve the error
- Auto-save draft content so errors do not lose user work
- Offer alternatives when the primary path is blocked
- Provide contact/support information for unrecoverable errors

---

## Responsive Layout Patterns

### Stack

- Elements that are side-by-side on desktop stack vertically on mobile
- Most common responsive pattern
- Content order must make sense when stacked

### Reflow

- Content reflowing into fewer columns as width decreases
- 4 columns on desktop, 2 on tablet, 1 on mobile
- Items maintain relative order

### Off-Canvas

- Sidebar or panel slides in from the edge on mobile
- Toggle with a button (hamburger for nav, filter icon for filters)
- Dismiss by closing, clicking outside, or swiping

---

## Progressive Disclosure

### Accordion

- Vertically stacked sections with headers
- Click header to expand/collapse content
- Show chevron or +/- icon to indicate expandability
- Decide: single or multiple sections open simultaneously

### Tabs

- Horizontal or vertical tab bar with content panels
- One panel visible at a time
- Do not nest tabs within tabs
- Consider vertical tabs on mobile when horizontal space is limited

### Show More / Read More

- Truncate long content with a "Show more" or "Read more" link
- Show 2-3 lines as preview
- Expand inline (do not navigate to a new page for short content)

### Tooltip Details

- Show additional information on hover (desktop) or tap (mobile)
- Keep tooltip content brief (1-2 sentences)
- Position to avoid obscuring the trigger element
- Dismiss on mouse leave, Escape key, or tap outside

---

## Card Patterns

### Media Card

- Image or video at top, content below
- Title, description, metadata, and optional action buttons
- Consistent aspect ratio for images across a grid

### Action Card

- Card that is entirely clickable
- Clear hover state indicating clickability
- Contains a title, brief description, and optional icon

### Stat Card

- Displays a key metric prominently
- Large number or value, supporting label
- Optional trend indicator (up/down arrow, percentage change)
- Optional sparkline or mini chart

### Profile Card

- Avatar or photo, name, role/title
- Brief bio or key attributes
- Contact actions (email, message)
- Used for team pages, user directories, social features
