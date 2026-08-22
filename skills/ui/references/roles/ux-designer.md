# UX Designer

## Role -> Reference Mapping

| Role | Reference Files |
|------|----------------|
| **UX Designer** | user-flows.md, user-research.md, usability-heuristics.md, wireframing.md |

## Detection Keywords

- user flow, journey map, user research, persona, usability, wireframe
- information architecture, card sorting, empathy map, task analysis
- usability testing, user interview, survey design, Jobs-to-be-Done
- affinity diagram, competitive analysis, heuristic evaluation

## UX Task Type Routing Table

| Request Signal | Task Type | References Loaded |
|---|---|---|
| "user flow", "task flow", "flow diagram", "process flow", "screen flow" | **user-flow** | user-flows.md |
| "journey map", "customer journey", "experience map", "touchpoints" | **journey-map** | user-flows.md, user-research.md |
| "information architecture", "IA", "site map", "content hierarchy", "navigation structure" | **information-architecture** | user-flows.md, wireframing.md |
| "user research", "user interview", "survey", "persona", "empathy map", "Jobs-to-be-Done", "card sorting", "competitive analysis" | **user-research** | user-research.md |
| "usability review", "heuristic evaluation", "usability audit", "UX review", "usability testing" | **usability-review** | usability-heuristics.md, user-research.md |
| "wireframe", "mockup", "lo-fi", "page layout", "screen design" | **wireframe** | wireframing.md, user-flows.md |

## UX Task Type Instructions

| Task Type | What the sub-agent does |
|---|---|
| **user-flow** | Create user flow diagrams showing screens, decisions, and paths through a feature or process; must include error paths and alternative flows |
| **journey-map** | Map the end-to-end user experience across touchpoints, identifying pain points, opportunities, and emotional states |
| **information-architecture** | Design content hierarchy, navigation models, and page structure; output site maps and navigation specifications |
| **user-research** | Design research plans, interview guides, survey instruments, or synthesize research findings into actionable insights |
| **usability-review** | Evaluate an interface against usability heuristics; produce findings with severity ratings and recommended fixes |
| **wireframe** | Create text-based wireframe layouts showing content placement, hierarchy, and interaction points |

## Guardrails

- **Flows must show error paths** -- happy path alone is incomplete; every flow must document validation errors, system errors, and recovery paths
- **User goals must be stated** -- every flow or wireframe must begin with the user goal it serves
- **Accessibility must be considered from the start** -- not bolted on after visual design
- **Content hierarchy must be explicit** -- wireframes must show clear visual hierarchy and reading order
- **Multi-device considerations must be addressed** -- state how the design adapts across screen sizes
- **Edge cases must be documented** -- empty states, maximum content, first-time use, error recovery
