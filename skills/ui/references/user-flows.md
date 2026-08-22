# User Flows Reference

## Flow Diagram Conventions

### Shape Vocabulary

| Shape | Meaning | Example |
|-------|---------|---------|
| Rectangle | Screen or page | Login Screen, Dashboard |
| Rounded rectangle | Start or end point | User arrives, Flow complete |
| Diamond | Decision point | Is authenticated? Has permission? |
| Parallelogram | Input or output | User enters email, System sends notification |
| Circle | Connector (to another part of the flow) | Go to Flow B |

### Notation Standards

- Use solid arrows for primary (happy) paths
- Use dashed arrows for alternative or error paths
- Label every arrow with the trigger or condition
- Number steps sequentially along the primary path
- Use color or line weight sparingly -- the flow must be readable in grayscale

---

## Task Analysis

### Breaking Down User Goals

Task analysis decomposes a high-level user goal into the discrete steps required to achieve it.

**Structure:**
1. **Goal** -- what the user wants to accomplish (e.g., "Purchase a product")
2. **Tasks** -- major phases (e.g., "Browse catalog", "Add to cart", "Complete checkout")
3. **Subtasks** -- specific actions within each task (e.g., "Enter shipping address", "Select payment method")
4. **Operations** -- atomic interactions (e.g., "Click the Submit button", "Type into the ZIP code field")

### Hierarchical Task Analysis (HTA)

```
0. Purchase a product
  1. Find a product
    1.1. Browse categories
    1.2. Use search
    1.3. Apply filters
  2. Evaluate product
    2.1. View product details
    2.2. Read reviews
    2.3. Compare with alternatives
  3. Add to cart
    3.1. Select variant (size, color)
    3.2. Set quantity
    3.3. Confirm add
  4. Complete checkout
    4.1. Review cart
    4.2. Enter shipping info
    4.3. Enter payment info
    4.4. Review and confirm order
```

### When to Use Task Analysis

- Before designing flows, to understand what steps exist
- When optimizing an existing flow, to find unnecessary steps
- When onboarding new team members to a complex domain
- When comparing your flow to a competitor's

---

## Entry and Exit Points

### Entry Points

Users do not always start at the home page. Document all realistic entry points:

- **Direct navigation** -- user types URL or uses bookmark
- **Search engine** -- user lands on a deep page from Google
- **Email link** -- user clicks a link in a transactional or marketing email
- **Push notification** -- user taps a notification on mobile
- **Deep link** -- user clicks a link shared by another user
- **Redirect** -- user is sent here from another part of the system (e.g., after login)

### Exit Points

Every flow has places where users can or will leave:

- **Intentional completion** -- the happy path end (e.g., order confirmed)
- **Intentional abandonment** -- user navigates away, closes tab, hits back
- **Forced exit** -- session timeout, server error, payment failure
- **Detour** -- user leaves to get information (e.g., checks bank balance, looks up a code) and may or may not return

### Recovery Paths

For each exit point, define:
- Can the user resume where they left off?
- Is state preserved (draft saved, cart retained)?
- How does the system communicate resumption options (email reminder, persistent cart badge)?

---

## Error Flow Patterns

Every flow must document what happens when things go wrong.

### Validation Errors

- **Inline validation** -- errors shown next to the field as the user types or on blur
- **Form-level validation** -- errors shown at the top of the form on submit
- **Best practice** -- combine both; show inline as user interacts, summarize on submit

### System Errors

- **Transient errors** -- network timeout, server 500; offer retry
- **Permanent errors** -- resource not found, permission denied; explain and offer alternatives
- **Degraded service** -- partial failure; show what is available, indicate what is not

### Timeout Patterns

- **Session timeout** -- warn before expiring (e.g., 2 minutes before), offer extension, preserve data on timeout
- **Action timeout** -- long-running operation; show progress, allow cancellation, provide fallback

### Permission Denied

- **Not authenticated** -- redirect to login, then back to the original destination
- **Not authorized** -- show a clear message explaining what permission is needed and who to contact
- **Feature gated** -- explain the feature is available on a different plan or role

---

## Happy Path vs Alternative Paths

### Happy Path

The happy path is the primary, most common flow through a feature. It represents the ideal case where nothing goes wrong and the user follows the expected steps.

- Always design and document the happy path first
- Mark it clearly in flow diagrams (bold line, primary color, or explicit label)
- Use it as the basis for task counts and time estimates

### Alternative Paths

Alternative paths are valid but less common routes through the same feature:

- **Shortcut paths** -- experienced user skips steps (e.g., uses keyboard shortcut, skips tutorial)
- **Branch paths** -- user makes a different choice at a decision point (e.g., guest checkout vs. account creation)
- **Recovery paths** -- user makes an error and recovers (e.g., edits address after entering it wrong)
- **Edge case paths** -- unusual but valid scenarios (e.g., user has no items in cart, user has 100 items)

### Documentation Standard

For each alternative path, document:
1. Where it diverges from the happy path
2. What triggers the divergence
3. Where it rejoins the happy path (if it does)
4. Any unique screens or states along the path

---

## Information Architecture

### Content Hierarchy

Organize content by user mental models, not by organizational structure.

**Methods for discovering hierarchy:**
- Card sorting (open and closed)
- Tree testing
- User interviews about how they think about content
- Analytics showing actual navigation patterns

### Navigation Models

| Model | Structure | Best For |
|-------|-----------|----------|
| **Hub and spoke** | Central hub with independent sections | Mobile apps, dashboards |
| **Linear** | Sequential steps | Wizards, onboarding, checkout |
| **Tree (hierarchical)** | Parent-child categories | Content-heavy sites, documentation |
| **Matrix** | Multiple classification dimensions | Faceted search, product catalogs |
| **Network** | Cross-linked nodes | Wikis, knowledge bases |

### Choosing a Navigation Model

- **Few sections, deep content** -- tree or hub-and-spoke
- **Many sections, shallow content** -- matrix or network
- **Sequential tasks** -- linear
- **Exploratory tasks** -- network or matrix
- **Mixed tasks** -- hub-and-spoke with linear sub-flows

---

## Navigation Patterns

### Global Navigation

- **Top bar** -- horizontal, always visible; works well for 3-7 top-level items
- **Sidebar** -- vertical, expandable; works well for many items or deep hierarchies
- **Bottom bar** -- mobile primary navigation; limit to 3-5 items

### Supplementary Navigation

- **Breadcrumbs** -- show the user's location in the hierarchy; always link each level
- **Tabs** -- switch between related views within a page; do not nest tabs
- **Hamburger menu** -- hidden navigation; use only when space is constrained; label it
- **Mega menu** -- large dropdown showing multiple sections; useful for content-rich sites

### Navigation Principles

1. Users should always know where they are
2. Users should always know where they can go
3. Users should always know how to get back
4. Navigation labels should match page titles
5. Current location should be visually indicated
6. No dead ends -- every page should offer a path forward

---

## Flow Annotation Conventions

### Numbering Steps

- Number primary path steps sequentially: 1, 2, 3, 4
- Number alternative paths with a branch indicator: 2a, 2b
- Number error paths with an E prefix: E1, E2

### Decision Labels

- Label the condition, not just "yes/no" (e.g., "Has account?" with "Yes: existing user" and "No: new user")
- Keep labels concise but unambiguous

### Notes for Edge Cases

- Use callout boxes or footnotes for edge case documentation
- Reference the edge case back to the step where it occurs
- Include frequency estimate if known (e.g., "~5% of users encounter this")

---

## Multi-Device Flows

### Cross-Device Considerations

The same flow may work differently on desktop, tablet, and mobile:

| Aspect | Desktop | Tablet | Mobile |
|--------|---------|--------|--------|
| Navigation | Top bar or sidebar | Top bar, may collapse | Bottom bar or hamburger |
| Forms | Multi-column possible | Single column preferred | Single column required |
| Content | Full content visible | May need tabs | Accordion or progressive disclosure |
| Interactions | Hover states available | Tap only, larger targets | Tap only, largest targets |
| Input | Full keyboard, mouse | On-screen keyboard, touch | On-screen keyboard, touch |

### Documenting Device Differences

- Note where the flow differs by device, not where it is the same
- Call out any steps that are impossible or significantly harder on a specific device
- Specify if certain features are desktop-only or mobile-only

---

## Flow Review Checklist

Before finalizing any user flow, verify:

- [ ] Happy path is complete from entry to exit
- [ ] All decision points have both/all branches documented
- [ ] Error paths are documented for every step that can fail
- [ ] Entry points include at least: direct URL, search, email link
- [ ] Exit points document whether state is preserved
- [ ] Recovery paths exist for all forced exits
- [ ] Steps are numbered consistently
- [ ] Decision labels are unambiguous
- [ ] No dead ends -- every screen has a forward path
- [ ] Multi-device differences are noted where applicable
- [ ] Flow complexity is appropriate for the user's skill level
- [ ] Total step count is documented for the happy path
