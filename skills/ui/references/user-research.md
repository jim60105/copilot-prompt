# User Research Reference

## User Interview Guides

### Interview Types

| Type | Structure | When to Use |
|------|-----------|-------------|
| **Structured** | Fixed questions, fixed order | Comparing responses across many participants |
| **Semi-structured** | Prepared questions with flexible follow-ups | Most common; balances consistency with exploration |
| **Contextual inquiry** | Observe users in their environment, ask questions in context | Understanding real workflows and workarounds |
| **Unmoderated** | Recorded responses to prompts, no facilitator | Large sample, geographic diversity, budget constraints |

### Question Types

**Open-ended (preferred):**
- "Tell me about the last time you..."
- "Walk me through how you..."
- "What was the hardest part of..."
- "How do you decide when to..."

**Follow-up probes:**
- "Can you tell me more about that?"
- "Why do you think that happened?"
- "What would you have preferred instead?"
- "How did that make you feel?"

**Questions to avoid:**
- Leading questions: "Don't you think X is better?"
- Hypothetical questions: "Would you use a feature that..."
- Double-barreled questions: "Do you find it easy and useful?"
- Yes/no questions (unless followed by "why?")

### Interview Guide Template

```
1. Introduction (5 min)
   - Introduce yourself and the purpose
   - Explain there are no right or wrong answers
   - Ask permission to record
   - Confirm time commitment

2. Warm-up (5 min)
   - Role and background
   - Relationship to the topic

3. Core questions (30 min)
   - Current behavior and process
   - Pain points and frustrations
   - Goals and motivations
   - Tools and workarounds

4. Specific feature exploration (10 min)
   - Show concept or prototype (if applicable)
   - Observe reactions
   - Ask for interpretation, not opinion

5. Wrap-up (5 min)
   - "Is there anything I should have asked?"
   - Thank the participant
```

---

## Survey Design

### Question Types

| Type | Use Case | Example |
|------|----------|---------|
| **Multiple choice** | Categorical data, single answer | "How often do you...?" |
| **Checkbox** | Multiple selections allowed | "Which of these do you use?" |
| **Likert scale** | Agreement, satisfaction, frequency | "On a scale of 1-5..." |
| **Open text** | Qualitative detail | "Describe your biggest challenge" |
| **Ranking** | Priority ordering | "Rank these features by importance" |
| **Matrix** | Multiple items on same scale | Rating several attributes |

### Scale Design

- Use 5 or 7-point scales (odd numbers allow a neutral midpoint)
- Label all points, not just endpoints
- Keep scale direction consistent throughout the survey
- Include "Not applicable" when appropriate

### Bias Avoidance

- **Order bias** -- randomize option and question order
- **Acquiescence bias** -- mix positively and negatively worded items
- **Social desirability bias** -- emphasize anonymity, use behavioral questions over attitude questions
- **Anchoring bias** -- do not show results or norms before the participant responds
- **Survey fatigue** -- keep under 10 minutes; put critical questions early

### Sample Size Guidelines

| Research Goal | Minimum Sample |
|---------------|---------------|
| Identifying major themes | 5-8 interviews |
| Quantitative trends | 30+ survey responses |
| Statistical significance | 100+ (depends on effect size) |
| Usability testing | 5 per round (Nielsen) |
| Card sorting | 15-30 participants |

---

## Persona Templates

### Core Persona Structure

```
## [Persona Name]
[Photo placeholder -- representative, not stereotypical]

### Demographics
- Age range: [range, not exact]
- Role/occupation: [relevant to the product]
- Technical proficiency: [low / medium / high]
- Device preferences: [desktop, mobile, tablet]
- Relevant context: [only demographics that affect product use]

### Goals
- Primary: [the main thing they want to accomplish]
- Secondary: [supporting goals]
- Life goal: [broader aspiration the product connects to]

### Frustrations
- [What blocks them from their goals]
- [What wastes their time]
- [What causes anxiety or confusion]

### Behaviors
- [How they currently solve the problem]
- [Tools and workarounds they use]
- [Frequency and context of use]

### Scenarios
- Scenario 1: [A realistic situation where they use the product]
- Scenario 2: [A different context or need]

### Quotes
- "[A representative quote from research]"
```

### Anti-Personas

Define who the product is NOT for. Anti-personas prevent scope creep by making explicit which users are out of scope.

```
## Anti-Persona: [Name]
- Why they are not a target user
- What they would need that conflicts with primary persona needs
- What harm comes from designing for them (complexity, dilution)
```

---

## Empathy Mapping

### The Four Quadrants

```
+---------------------------+---------------------------+
|          SAYS             |          THINKS           |
| Direct quotes from        | What they believe but     |
| interviews or observed    | may not say aloud.        |
| statements.               | Inferred from behavior    |
|                           | and context.              |
+---------------------------+---------------------------+
|          DOES             |          FEELS            |
| Observable actions and    | Emotional states:         |
| behaviors. What do they   | frustrated, anxious,      |
| actually do (vs. what     | confident, overwhelmed,   |
| they say they do)?        | satisfied, confused.      |
+---------------------------+---------------------------+
```

### How to Fill an Empathy Map

1. Start with SAYS -- direct quotes from research
2. Move to DOES -- observable behaviors, especially contradictions with SAYS
3. Infer THINKS -- what beliefs drive the gap between SAYS and DOES
4. Identify FEELS -- emotional undercurrent across all quadrants

### Empathy Map Insights

Look for:
- Contradictions between SAYS and DOES (reveals true behavior)
- Negative emotions in FEELS (reveals pain points)
- Workarounds in DOES (reveals unmet needs)
- Assumptions in THINKS (reveals mental models to design for or against)

---

## Jobs-to-be-Done Framework

### Job Statement Format

```
When [SITUATION/CONTEXT],
I want to [MOTIVATION/GOAL],
so I can [EXPECTED OUTCOME].
```

### Components

- **Circumstances** -- the specific situation that triggers the need (time, place, social context)
- **Functional job** -- the practical task to accomplish
- **Emotional job** -- how the user wants to feel
- **Social job** -- how the user wants to be perceived

### Outcome Expectations

Outcomes are measurable criteria for success:
- **Minimize the time it takes to** [do something]
- **Minimize the likelihood of** [a negative outcome]
- **Increase the ability to** [achieve something]

### Example

```
When I am preparing for a team meeting (circumstance),
I want to quickly see what has changed since the last meeting (functional job),
so I can feel prepared and ask informed questions (emotional job),
and be seen as an engaged team member (social job).

Outcomes:
- Minimize time to identify changes since last meeting
- Minimize likelihood of being surprised by new information
- Increase ability to contribute meaningfully to discussion
```

---

## Card Sorting

### Open Card Sort

- Participants group cards into categories they create and name
- Use when: you do not have an existing structure
- Analysis: look for common groupings and labels; disagreement reveals ambiguity
- Tools: OptimalSort, Maze, physical cards

### Closed Card Sort

- Participants sort cards into predefined categories
- Use when: you have a proposed structure and want to validate it
- Analysis: measure agreement percentage per card; items below 60% agreement need rethinking
- Can reveal if your categories make sense to users

### When to Use Card Sorting

- Designing information architecture from scratch
- Reorganizing existing navigation
- Naming categories or sections
- Understanding user mental models for content grouping

---

## Usability Testing Scripts

### Task Scenario Format

```
Scenario: [Brief context setting]
Task: [What the participant should try to accomplish]
Success criteria: [How you will know they succeeded]
Time limit: [Optional -- maximum time before moving on]
```

### Think-Aloud Protocol

Ask participants to verbalize their thoughts as they interact:
- "Tell me what you are looking at."
- "What are you thinking right now?"
- "What do you expect to happen if you click that?"
- "Is this what you expected?"

**Do not:**
- Help the participant unless they are completely stuck
- React to their comments (no "good" or "right")
- Ask leading questions ("Did you see the button in the top right?")

### Observer Guidelines

- Take notes with timestamps
- Record facial expressions and body language
- Note hesitations, errors, and backtracking
- Do not intervene unless the participant asks for help or the time limit is reached
- Use a standardized observation form

---

## Competitive Analysis Framework

### Feature Comparison Matrix

| Feature | Our Product | Competitor A | Competitor B | Competitor C |
|---------|------------|--------------|--------------|--------------|
| [Feature 1] | [Status] | [Status] | [Status] | [Status] |
| [Feature 2] | [Status] | [Status] | [Status] | [Status] |

Status values: Full support, Partial, Not supported, Better than ours, Worse than ours

### UX Benchmarking

For each competitor, evaluate:
- Onboarding experience (time to first value)
- Core task completion (steps, time, error rate)
- Navigation clarity (can users find things?)
- Error handling (how gracefully do errors recover?)
- Accessibility (basic WCAG compliance)
- Mobile experience (responsive, native, or absent)

---

## Research Synthesis

### Affinity Diagrams

1. Write each observation or quote on a separate note
2. Group related notes together (without predefined categories)
3. Name each group with a descriptive label
4. Look for themes across groups
5. Identify the 3-5 most significant themes

### Insight Statements

Transform observations into actionable insights:

```
Observation: Users frequently abandon the checkout at the shipping step.
Insight: Users are surprised by shipping costs because they are not shown
         until late in the process, creating a trust violation.
Opportunity: Show estimated shipping cost earlier (product page or cart).
```

### Research Repository Patterns

- Tag insights by user segment, feature area, and research method
- Make insights searchable by keyword
- Link insights to the raw data (interview transcripts, recordings)
- Review and retire outdated insights quarterly
- Track which insights have been acted on and which remain open
