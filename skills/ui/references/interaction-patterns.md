# Interaction Patterns Reference

## Micro-Interactions

### Anatomy of a Micro-Interaction

Every micro-interaction has four parts:

1. **Trigger** -- what initiates the interaction (user action or system event)
2. **Rules** -- what happens in response to the trigger
3. **Feedback** -- how the user knows the interaction occurred
4. **Loops and Modes** -- what happens over time or on repeat (e.g., animation loops, long-press mode)

### Common Micro-Interactions

| Interaction | Trigger | Feedback | Example |
|-------------|---------|----------|---------|
| Toggle | Click/tap | Visual state change + optional sound | Dark mode switch slides and changes color |
| Like/favorite | Click/tap | Icon fills, count increments, brief animation | Heart fills with color, bounces slightly |
| Pull-to-refresh | Pull gesture | Spinner appears, content refreshes | Arrow rotates into spinner |
| Swipe action | Horizontal swipe | Action panel reveals behind item | Swipe to reveal delete button |
| Form validation | Blur or keystroke | Checkmark, error icon, or message | Green checkmark appears next to valid field |
| Copy to clipboard | Click | Button text changes briefly | "Copy" becomes "Copied!" for 2 seconds |
| Scroll progress | Scroll | Progress bar fills at top of page | Reading progress indicator |

### Design Principles for Micro-Interactions

- Keep them fast (under 400ms for most)
- Make them feel responsive (respond within 100ms of input)
- Do not overuse -- reserve for moments that benefit from delight or clarity
- Ensure they communicate function, not just decoration
- Provide alternatives for users with motion sensitivity

---

## Animation Principles for UI

### Adapted from Disney's 12 Principles

| Principle | UI Application |
|-----------|---------------|
| **Anticipation** | Brief preparation before an action (button depresses before navigating, card lifts before dragging) |
| **Follow-through** | Elements settle after reaching their destination (slight overshoot and bounce on arrival) |
| **Ease-in / Ease-out** | Motion starts slow, accelerates, then decelerates (never use linear for spatial movement) |
| **Staging** | Direct attention to the important element (dim background, spotlight the modal) |
| **Timing** | Duration communicates weight and distance (small elements move faster, large ones slower) |
| **Secondary action** | Supporting animations that enhance the primary action (background blur as modal opens) |
| **Exaggeration** | Slightly amplified motion to communicate clearly (error shake is wider than a real shake) |
| **Solid drawing** | Consistent visual language (same easing, same duration scale, same shadow behavior) |

### What Not to Animate

- Do not animate text content appearing (use instant render or simple fade)
- Do not animate critical information (error messages should appear immediately)
- Do not animate the same element repeatedly (it becomes distracting)
- Do not use animation to delay user interaction (loading animations are acceptable; decorative delays are not)

---

## Transition Patterns

### Page Transitions

| Pattern | Use Case | Implementation |
|---------|----------|----------------|
| **Crossfade** | Default page transition | Fade out current (150ms), fade in next (150ms) |
| **Slide** | Hierarchical navigation (parent to child) | Slide in from right (forward), slide in from left (back) |
| **Scale** | Opening a new context (modal, detail view) | Scale up from origin point |
| **Shared element** | Same element exists on both pages | Animate the shared element between positions |
| **None** | Instant navigation (breadcrumb clicks, tab switches) | No animation; immediate content swap |

### Modal Enter / Exit

- **Enter:** fade in backdrop (200ms) + scale up modal from center (200ms, ease-out)
- **Exit:** scale down modal (150ms, ease-in) + fade out backdrop (150ms)
- Backdrop should capture clicks to close
- Focus should move to the modal on enter and return to the trigger on exit

### List Item Add / Remove

- **Add:** slide in from top or left + fade in (200ms)
- **Remove:** fade out (150ms) + collapse height (200ms)
- Remaining items slide to fill the gap smoothly
- For reorder, animate position change (200ms)

### Expand / Collapse

- Animate height from 0 to auto (or measured height)
- Use ease-out on expand, ease-in on collapse
- Duration: 200-300ms depending on content size
- Rotate chevron/arrow icon to indicate state

---

## Loading and Skeleton States

### Skeleton Screens

Replace content with placeholder shapes that match the layout:
- Use neutral gray rectangles for text lines
- Use slightly darker gray rectangles for images
- Match the approximate width and height of real content
- Apply a subtle shimmer animation (left-to-right gradient sweep)

### Skeleton Guidelines

- Show skeleton immediately (within 100ms of navigation)
- Match the expected layout -- do not show a generic loader
- Animate with a subtle pulse or shimmer (not a spinning indicator)
- Transition from skeleton to real content with a quick fade (100ms)

### Progressive Loading

Load and display content in priority order:
1. Navigation and page structure (instant)
2. Above-the-fold content (first paint)
3. Below-the-fold content (on scroll or after delay)
4. Non-critical enhancements (lazy load)

### Optimistic UI

Update the UI immediately before the server confirms:
- Show the new state instantly (e.g., message appears in chat)
- If the server confirms, no further action needed
- If the server rejects, revert the UI and show an error
- Use for low-risk, high-frequency actions (likes, toggles, comments)

### Loading State Decision Tree

| Wait Time | Pattern |
|-----------|---------|
| < 100ms | No indicator needed |
| 100ms - 1s | Subtle indicator (spinner on button, progress bar) |
| 1s - 10s | Skeleton screen or progress bar with estimate |
| > 10s | Progress bar with time estimate, allow cancellation |

---

## Gesture Patterns

### Core Gestures

| Gesture | Action | Use Case |
|---------|--------|----------|
| **Tap** | Select, activate | Buttons, links, list items |
| **Long press** | Secondary action menu | Context menu, drag initiation |
| **Swipe horizontal** | Navigate or reveal actions | Dismiss, delete, archive |
| **Swipe vertical** | Scroll | Content navigation |
| **Pinch** | Zoom in/out | Maps, images, galleries |
| **Double tap** | Quick action (like, zoom) | Social media like, image zoom |
| **Drag** | Move or reorder | Reorder list items, move cards |
| **Pull down** | Refresh | Refresh content in lists |

### Gesture Design Rules

- Never make gestures the only way to perform an action -- always provide a visible button alternative
- Provide visual feedback during the gesture (element moves with finger, action preview)
- Define threshold distances for gesture completion (how far to swipe before the action triggers)
- Support gesture cancellation (drag back to cancel a swipe action)
- Consider one-handed operation -- primary gestures should work with thumb

---

## Feedback Patterns

### Visual Feedback

| Feedback Type | Duration | Use Case |
|---------------|----------|----------|
| **Highlight** | 200ms | Selection confirmation, hover state |
| **Toast notification** | 3-5 seconds | Success/info messages, auto-dismiss |
| **Progress bar** | Duration of operation | File upload, form submission |
| **Inline message** | Until dismissed or resolved | Error messages, validation |
| **Badge / dot** | Persistent until cleared | Unread count, new content indicator |
| **Ripple / pulse** | 300ms | Touch feedback (Material Design) |

### Haptic Feedback (Mobile / Gamepad)

| Type | Intensity | Use Case |
|------|-----------|----------|
| **Light tap** | Low | Selection, toggle |
| **Medium impact** | Medium | Action completion, confirmation |
| **Heavy impact** | High | Error, warning, destructive action |
| **Vibration pattern** | Varies | Notification, game event |

### Auditory Feedback

- Use sparingly -- most UI interactions should be silent
- Reserved for: notifications, errors, completion of significant actions
- Always provide a mute option
- Pair audio with visual feedback (never audio-only)

---

## Scroll Behaviors

### Sticky Headers

- Header fixes to top of viewport when scrolling past it
- Use for navigation, table headers, section titles
- Sticky elements should not consume more than 20% of viewport height
- Add a subtle shadow when the header becomes sticky (indicates elevation)

### Parallax Scrolling

- Background moves slower than foreground content
- Use for decorative effect only, never for content
- Disable for users who prefer reduced motion
- Keep parallax subtle (0.3-0.5x scroll speed for background)

### Infinite Scroll

- Load more content when the user scrolls near the bottom (1-2 viewport heights before the end)
- Show a loading indicator while fetching
- Provide a way to reach the footer (load button, or sticky footer)
- Consider providing a "load more" button instead of pure infinite scroll
- Always provide a way to return to a specific position (back button, scroll position preservation)

### Snap Scrolling

- Content snaps to predefined positions (e.g., each card or section)
- Use for carousels, galleries, full-page sections
- Provide visual indicators for scroll position (dots, progress bar)

### Virtual Scrolling

- Render only visible items in long lists (plus a small buffer above and below)
- Maintain scroll position and list height with spacer elements
- Use for lists with 100+ items
- Ensure keyboard navigation works correctly with virtualized items

---

## Hover and Focus States

### Hover States (Desktop Only)

| Element | Hover Behavior |
|---------|---------------|
| Button | Background color shift, cursor: pointer |
| Link | Underline or color change |
| Card | Subtle shadow increase or border highlight |
| Image | Slight zoom or overlay |
| Row | Background highlight |
| Icon button | Background circle appears |

### Focus States

- **Focus ring:** 2px solid outline, offset by 2px, using the focus color token
- **Never remove focus indicators** -- they are essential for keyboard navigation
- **Focus-visible:** show focus ring only on keyboard focus, not mouse click (where supported)
- **Custom focus styles** must be at least as visible as the browser default

### Skip Links

- First focusable element on every page
- Hidden until focused (position off-screen, revealed on focus)
- Links to the main content area, bypassing navigation
- Text: "Skip to main content" or "Skip to content"

---

## Notification Patterns

### Notification Types

| Type | Position | Persistence | Interaction |
|------|----------|-------------|-------------|
| **Toast** | Top-right or bottom-center | Auto-dismiss (3-5s) | Dismiss, optional action |
| **Banner** | Top of page, below nav | Until dismissed | Dismiss, action button |
| **Badge** | On icon or element | Until cleared | Click to view |
| **Inline** | Within content flow | Until resolved | Read, action |
| **Modal** | Center, with backdrop | Until user responds | Confirm/cancel |
| **Push** | System notification | Until interacted with | Tap to open |

### Toast Notification Guidelines

- Stack from the newest at the top or bottom, depending on position
- Limit to 3 visible at once -- queue the rest
- Auto-dismiss after 3-5 seconds for informational toasts
- Error toasts should require manual dismissal
- Include a close button on all toasts
- Do not block user interaction with the page

---

## Performance Considerations for Animations

### 60fps Target

To maintain 60fps, each frame has approximately 16ms of budget:
- Animate only `transform` and `opacity` (these are GPU-composited)
- Avoid animating `width`, `height`, `top`, `left`, `margin`, `padding` (these trigger layout)
- Avoid animating `box-shadow`, `border-radius` (these trigger paint)

### Optimization Techniques

- Use `will-change` on elements about to animate (apply just before, remove after)
- Use `transform: translateZ(0)` or `will-change: transform` to promote to GPU layer
- Batch DOM reads and writes to avoid forced reflow
- Use `requestAnimationFrame` for JavaScript-driven animations
- Prefer CSS transitions and animations over JavaScript where possible

### Testing Animation Performance

- Use browser DevTools Performance panel to check for dropped frames
- Monitor paint and layout events during animations
- Test on low-end devices -- not just development machines
- Test with many items animating simultaneously (list reorder, stagger)
