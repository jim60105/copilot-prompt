# Output Patterns

Choose a structure that matches the user's request. Do not force every section into every response.

## UI critique

Use this default structure for reviewing an existing screen or HUD:

1. Context and assumptions
2. Highest-impact findings, ordered by player impact
3. Evidence for each finding
4. Recommended change with a concrete implementation direction
5. Validation method

For each finding, use:

**Finding:** [observable issue]  
**Player impact:** [decision, comprehension, navigation, or accessibility consequence]  
**Evidence:** [research, platform guideline, or task-analysis reasoning]  
**Recommendation:** [specific change]  
**Validate by:** [playtest or measurable check]

## Design brief

Use this for designing UI from scratch:

### Player and platform
State genre, platform, input, viewing distance, pace, audience, and accessibility targets.

### Decision inventory
List the player's main decisions and the information each decision needs.

### Information architecture
Group information into immediate, near-term, and reference-only layers.

### Presentation mapping
For each information type, choose HUD, diegetic, spatial/world-space, audio, haptic, or menu presentation and explain why.

### Interaction model
Define navigation, focus, cancel/back behavior, input prompts, rebinding behavior, and destructive-action handling.

### Learnability
Define what is taught, when it appears, how players practice it, and how they revisit it.

### Accessibility constraints
Define text, contrast, redundant cues, motion, input, focus, and configurable UI requirements.

### Validation
Specify prototype checks and player tasks that can falsify the design assumptions.

## Research-backed guidelines

When the user asks for best practices or a guideline document:

- Start with the small set of conclusions that have the strongest evidence.
- Separate experimental research from platform guidance and from design inference.
- Attach the relevant paper or official guideline to each strong claim.
- Include scope limitations for genre-specific or descriptive studies.
- End with an implementation checklist suitable for a design review.

## Prioritization

Prioritize findings by expected player impact:

- **Blocker:** prevents progress, input, perception, or navigation for a meaningful set of players.
- **High:** frequently causes wrong decisions, missed critical state, navigation failure, or destructive mistakes.
- **Medium:** adds repeated search cost, confusion, or unnecessary cognitive load.
- **Low:** polish issue with limited effect on task success.

Avoid assigning severity from visual taste alone.
