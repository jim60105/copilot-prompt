# Cross-Role Tasks (UI plugin)

When a task spans multiple roles (e.g., "design an accessible game inventory" or "create a design system with usability validation"):

1. Identify all roles involved
2. Load all relevant reference files (godot pattern -- multiple references in one sub-agent)
3. Spawn a **single sub-agent** with combined references
4. If concerns are truly independent, spawn separate sub-agents sequentially

## Common cross-role combinations

| Scenario | References Loaded |
|----------|-------------------|
| Accessible game UI | game-ui-patterns.md + game-ui-accessibility.md + accessibility.md |
| Game menu with gamepad accessibility | menu-systems.md + game-ui-accessibility.md |
| Design system with accessibility audit | design-systems.md + accessibility.md |
| Wireframe with interaction specs | wireframing.md + interaction-patterns.md |
| User flow to wireframe pipeline | user-flows.md + wireframing.md |
| Game HUD usability review | hud-systems.md + usability-heuristics.md |
| Full UI specification | design-systems.md + ui-patterns.md + accessibility.md + interaction-patterns.md |
