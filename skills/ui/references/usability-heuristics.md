# Usability Heuristics Reference

## Nielsen's 10 Usability Heuristics

### 1. Visibility of System Status

**Definition:** The system should always keep users informed about what is going on, through appropriate feedback within reasonable time.

**Examples of good implementation:**
- Progress bars during file uploads
- Loading spinners with estimated time
- "Saving..." indicator in auto-save applications
- Read receipts in messaging apps
- Page load indicators in the browser

**Violation signs:**
- User clicks a button and nothing visibly happens
- Long operations with no progress indication
- Form submitted but no confirmation shown
- Background processes with no status communication

**Fix patterns:**
- Add loading indicators for any operation over 1 second
- Show progress bars for operations over 10 seconds
- Provide confirmation messages for completed actions
- Use optimistic UI updates with background sync indicators

---

### 2. Match Between System and Real World

**Definition:** The system should speak the users' language, with words, phrases, and concepts familiar to the user, rather than system-oriented terms.

**Examples of good implementation:**
- Shopping cart icon for e-commerce (matches physical shopping metaphor)
- "Trash" or "Recycle Bin" for deleted items
- Calendar views that look like physical calendars
- Using industry terminology the user knows

**Violation signs:**
- Technical jargon in user-facing text (e.g., "Error 500: Internal Server Exception")
- Unfamiliar icons without labels
- Data displayed in system formats (e.g., timestamps in epoch format)
- Organizational structure exposed in navigation (users do not think in departments)

**Fix patterns:**
- Use language from user interviews, not engineering specs
- Test labels with card sorting or first-click testing
- Translate error codes into plain language actions
- Format data in human-readable ways (dates, currency, names)

---

### 3. User Control and Freedom

**Definition:** Users often perform actions by mistake. They need a clearly marked "emergency exit" to leave the unwanted action without going through an extended process.

**Examples of good implementation:**
- Undo/redo in text editors
- "Cancel" buttons on every form and dialog
- Gmail's "Undo send" feature
- Back button works as expected
- Easy unsubscribe from emails

**Violation signs:**
- Destructive actions with no confirmation or undo
- Modals with no close button
- Wizard flows with no back button
- Forced completion of multi-step processes

**Fix patterns:**
- Support undo for all destructive actions
- Provide cancel/close on every dialog and form
- Allow going back in multi-step flows
- Auto-save drafts so work is not lost

---

### 4. Consistency and Standards

**Definition:** Users should not have to wonder whether different words, situations, or actions mean the same thing. Follow platform conventions.

**Examples of good implementation:**
- Consistent button styles for similar actions across the application
- Standard icons (gear for settings, magnifying glass for search)
- Same terminology used everywhere for the same concept
- Platform-standard gestures and shortcuts

**Violation signs:**
- "Save" in one place, "Submit" in another, "Confirm" in a third -- for the same action
- Different navigation patterns on different pages
- Inconsistent icon usage
- Custom controls that ignore platform conventions

**Fix patterns:**
- Create and enforce a design system with documented patterns
- Audit terminology across the entire product
- Follow platform conventions (Material Design for Android, HIG for iOS)
- Use a component library to enforce visual consistency

---

### 5. Error Prevention

**Definition:** Even better than good error messages is a careful design that prevents a problem from occurring in the first place.

**Examples of good implementation:**
- Confirmation dialogs before destructive actions ("Delete 47 items?")
- Input masks and constraints (date pickers instead of free text)
- Disabling the submit button until the form is valid
- Showing character counts approaching limits

**Violation signs:**
- Free text fields where structured input would work
- No confirmation for irreversible actions
- Allowing invalid states to be saved
- No validation until after form submission

**Fix patterns:**
- Use constrained input controls (dropdowns, date pickers, sliders)
- Validate inline as the user types
- Require confirmation for destructive or expensive actions
- Default to the safest option

---

### 6. Recognition Rather Than Recall

**Definition:** Minimize the user's memory load by making objects, actions, and options visible. The user should not have to remember information from one part of the dialogue to another.

**Examples of good implementation:**
- Recent items and search history
- Autocomplete suggestions
- Tooltips showing what icons mean
- Breadcrumbs showing navigation path
- Visible labels on all form fields (not just placeholder text)

**Violation signs:**
- Icons without labels
- Form fields that only have placeholder text (disappears on focus)
- Requiring users to remember codes or IDs
- Hidden features accessible only through keyboard shortcuts

**Fix patterns:**
- Label all icons, at least with tooltips
- Use persistent labels above form fields, not just placeholders
- Show recently used items
- Provide autocomplete and suggestions

---

### 7. Flexibility and Efficiency of Use

**Definition:** Accelerators -- unseen by the novice user -- may speed up the interaction for the expert user so that the system can cater to both inexperienced and experienced users.

**Examples of good implementation:**
- Keyboard shortcuts for common actions
- Customizable toolbars or dashboards
- Bulk actions for managing multiple items
- Templates and presets for common configurations
- Touch gestures as shortcuts (swipe to delete)

**Violation signs:**
- No keyboard shortcuts for frequent actions
- Forcing all users through the same lengthy process
- No way to customize or personalize the interface
- No batch or bulk operations

**Fix patterns:**
- Add keyboard shortcuts and display them in menus
- Provide both simple and advanced modes
- Allow saving frequently used configurations
- Support bulk operations for repetitive tasks

---

### 8. Aesthetic and Minimalist Design

**Definition:** Interfaces should not contain information that is irrelevant or rarely needed. Every extra unit of information in an interface competes with the relevant units of information and diminishes their relative visibility.

**Examples of good implementation:**
- Clean layouts with clear visual hierarchy
- Progressive disclosure (show details on demand)
- White space used effectively
- Only the most important actions prominently displayed

**Violation signs:**
- Cluttered screens with too many elements
- All options shown at once, regardless of frequency of use
- Dense text blocks without formatting or hierarchy
- Multiple competing calls to action

**Fix patterns:**
- Audit each screen: what can be hidden, removed, or moved?
- Use progressive disclosure for advanced or rare options
- Establish clear visual hierarchy with size, color, and spacing
- Limit primary actions to 1-2 per screen

---

### 9. Help Users Recognize, Diagnose, and Recover from Errors

**Definition:** Error messages should be expressed in plain language (no codes), precisely indicate the problem, and constructively suggest a solution.

**Examples of good implementation:**
- "The email address you entered is not in a valid format. Example: name@example.com"
- "We could not connect to the server. Check your internet connection and try again."
- Inline field errors that appear next to the relevant field
- Error messages that suggest next steps

**Violation signs:**
- "An error occurred" with no detail
- Error codes without explanation (e.g., "Error 0x80070005")
- Error messages far from the source of the error
- No suggestion for how to fix the problem

**Fix patterns:**
- State what went wrong in plain language
- Explain why it went wrong (if helpful)
- Tell the user what to do next
- Place the error message near the source of the problem

---

### 10. Help and Documentation

**Definition:** Even though it is better if the system can be used without documentation, it may be necessary to provide help and documentation. Help should be easy to search, focused on the user's task, list concrete steps, and not be too large.

**Examples of good implementation:**
- Contextual help tooltips near complex features
- Searchable help center
- Onboarding tours for first-time users
- Empty state messages that guide the user

**Violation signs:**
- No help available at all
- Help content that is outdated or inaccurate
- Help that only describes features, not tasks
- No way to search help content

**Fix patterns:**
- Add contextual help where users commonly get stuck
- Write help in terms of user tasks, not feature descriptions
- Keep help content current with product changes
- Make help searchable and browsable

---

## Cognitive Load Theory

### Types of Cognitive Load

| Type | Definition | Design Implication |
|------|-----------|-------------------|
| **Intrinsic** | Complexity inherent to the task itself | Simplify the task; break into smaller steps |
| **Extraneous** | Load created by poor design | Eliminate through better layout, clearer language, fewer distractions |
| **Germane** | Load from learning and building mental models | Support through good information structure and progressive disclosure |

### Reducing Extraneous Load

- **Chunking** -- group related information into meaningful clusters (e.g., phone number as XXX-XXX-XXXX, not XXXXXXXXXX)
- **Progressive disclosure** -- show only what is needed now; reveal details on demand
- **Defaults** -- pre-fill sensible values to reduce decisions
- **Recognition over recall** -- show options rather than requiring memory
- **Consistency** -- same patterns everywhere reduce learning cost

---

## Fitts's Law

**Principle:** The time to reach a target is a function of the distance to the target and the size of the target.

### Design Implications

- **Make important targets large** -- primary buttons should be bigger than secondary
- **Reduce distance** -- place frequent actions near the user's current focus
- **Edge and corner advantage** -- targets at screen edges are effectively infinite in one dimension (easier to hit)
- **Minimum target size** -- at least 44x44px for touch, 24x24px for mouse
- **Spacing** -- leave enough space between targets to prevent mis-clicks

---

## Hick's Law

**Principle:** The time it takes to make a decision increases with the number and complexity of choices.

### Design Implications

- **Limit choices per screen** -- 5-7 options is a good maximum for navigation
- **Group and categorize** -- if many options exist, organize them into meaningful groups
- **Highlight recommended options** -- reduce decision effort by suggesting a default
- **Progressive disclosure** -- show top-level categories first, details on demand
- **Remove unnecessary options** -- every option adds decision time

---

## Heuristic Evaluation Methodology

### Evaluator Selection

- Use 3-5 evaluators for best coverage (diminishing returns after 5)
- Mix of UX expertise levels yields broadest findings
- Each evaluator works independently, then findings are combined

### Severity Ratings

| Rating | Label | Definition |
|--------|-------|-----------|
| 0 | Not a problem | Disagree that this is a usability problem |
| 1 | Cosmetic | Fix only if time allows |
| 2 | Minor | Low priority; causes minor delays |
| 3 | Major | High priority; causes significant difficulty |
| 4 | Catastrophe | Must fix before release; prevents task completion |

### Reporting Template

```
## Finding [N]
- Heuristic violated: [number and name]
- Severity: [0-4]
- Location: [page, screen, or component]
- Description: [what the problem is]
- Evidence: [screenshot or quote]
- Recommendation: [how to fix it]
```

---

## Common Usability Anti-Patterns

### Mystery Meat Navigation

Icons without labels, relying on users to guess meanings. Fix: always label icons, at least with tooltips.

### Modal Abuse

Using modal dialogs for non-critical information, blocking user flow. Fix: use modals only for confirmation of destructive actions or critical decisions. Use inline messages or banners for informational content.

### Infinite Scroll Without Waypoints

Endless content streams with no way to return to a specific position. Fix: provide pagination, a "back to top" button, or persistent position indicators. Allow users to bookmark or share specific positions.

### Placeholder-Only Labels

Form fields that use placeholder text as the only label, which disappears on focus. Fix: use persistent labels above or beside the field; reserve placeholder for example input.

### Disabled Buttons Without Explanation

Buttons that are grayed out with no indication of what the user needs to do to enable them. Fix: show a tooltip or inline message explaining the precondition.

### Unexpected Navigation

Clicking a link opens a new tab, navigates away from the current flow, or triggers a download without warning. Fix: indicate external links, downloads, and new-tab behavior in the link text or with an icon.
