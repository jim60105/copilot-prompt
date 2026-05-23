# Prompt Formulas by Scenario

Reach for the formula matching the user's task. All formulas produce **flowing natural English**, never tag lists or weight syntax.

## 1. Text-to-image (no reference images)

**Formula:**

```
[Style / medium] + [Subject + key descriptors] + [Action / expression]
+ [Setting / context] + [Composition / framing] + [Lighting] + [Color / texture]
```

**Template paragraph:**

> A `[style/medium descriptor]` of `[subject with 2–3 vivid descriptors]`, `[action or pose]`, set in `[location with one or two environmental details]`. `[Composition: framing + camera angle + lens/DOF]`. `[Lighting: direction + quality + temperature]`, with `[color palette and notable textures]`.

**Worked example:**

> A cinematic medium-format film photograph of a weathered fisherman in a yellow oilskin coat, hauling a net over the gunwale of a small wooden boat, set against a churning slate-grey North Atlantic at dawn. Low-angle shot from the waterline with a 35mm lens at f/2.8, shallow depth of field. Cold, diffuse pre-sunrise light from the upper left, with cool steel-blue tones offset by the saturated yellow of the coat and the raw, salt-stained grain of the wood.

## 2. Multimodal generation (with reference images)

When the user attaches reference images.

**Formula:**

```
[Reference roles] + [Relationship instruction] + [New scenario] + [Style/composition direction]
```

State explicitly which reference contributes what. Common roles: *subject*, *pose*, *style*, *texture / material*, *color palette*, *background*, *layout/structure*.

**Template:**

> Using `[reference A]` as the `[role of A]` and `[reference B]` as the `[role of B]`, render `[new scenario]` in `[style/medium]`. `[Optional: lighting + composition direction]`.

**Worked example:**

> Using the attached napkin sketch as the structural layout and the attached linen swatch as the upholstery texture, render a high-fidelity studio product shot of a single-seater armchair in a sun-drenched minimalist living room. Three-point softbox lighting with warm key from camera-right, shot on a 50mm lens at f/4.

## 3. Image editing (conversational, no new references)

Treat the existing image as the unchanged baseline. The prompt should make crystal clear **what changes** and **what must stay the same**.

**Formula:**

```
[Edit operation: remove / add / replace / change] + [Target region or element]
+ [Desired result] + [What to preserve exactly]
```

**Worked examples:**

> Remove the man in the red jacket from the left side of the frame. Keep the lighting, the woman's pose and outfit, and the background unchanged from the source image; existing café signage stays in place but remains indistinct and is not re-rendered. Cleanly inpaint the space behind him as a continuation of the wet cobblestones.

> Change the car's color from black to a deep burgundy with a subtle metallic flake. Preserve the exact lighting, reflections, and the rest of the scene unchanged.

## 4. Style transfer / composition (editing with new references)

**Formula:**

```
[Source: existing image] + [Reference: style image] + [What to keep from source]
+ [What to take from reference]
```

**Worked example:**

> Recreate the exact content and composition of the source photograph in the painterly style of the attached Van Gogh reference: keep the buildings, street layout, and figure positions exactly, but apply the reference's thick impasto brushwork, swirling sky, and warm-cool yellow-blue palette.

## 5. Real-time / web-search informed (when the runtime supports grounding)

When the model can pull live data.

**Formula:**

```
[Search / retrieval request] + [Analytical translation step]
+ [Visualization instruction]
```

**Worked example:**

> Search for the current weather and time in Reykjavík. Use that data to choose the lighting and atmospheric conditions of the scene. Visualize a miniature diorama of the city sitting inside a glass snow globe, rendered as a photorealistic studio product shot on a dark walnut desk, soft top-down key light.

## 6. Text rendered inside the image (only when user asks)

**Default: do NOT add text.** When the user explicitly wants legible text in the image:

**Formula:**

```
[Exact wording in double quotes] + [Typography style] + [Placement / hierarchy] + [Rest of scene]
```

Rules:

- Quote the exact words: `the word "URBAN EXPLORER"`.
- Name the type style: *bold sans-serif*, *flowing brush script*, *condensed serif*, *hand-painted lettering*, *neon tube lettering*. Naming a specific font (e.g. *Century Gothic*, *Impact*) helps stronger models.
- Place it deliberately: *centered banner across the top*, *small caption in the lower-right corner*, *engraved into the metal plate*.
- For multilingual rendering, name the target language explicitly: *the word "歓迎" in elegant Japanese kanji brush script*.

**Worked example:**

> A high-end commercial beauty shot of a sleek nude-pink moisturizer jar on a warm beige studio background, soft diffused key light from above. Across the top, render the word "GLOW" in a flowing elegant brush-script font, centered. Below it, render "10% OFF" in a heavy blocky Impact-style font, and below that "Your First Order" in a thin minimalist Century Gothic. Keep all three lines crisp and legible.

## 7. Character or product consistency across a set

For storyboards, ad sets, or character sheets where the SAME subject must appear in multiple shots.

**Formula:**

```
[Character/product canon block] (reused verbatim across prompts)
+ [Per-shot: setting + action + framing + lighting]
```

Write the canon block once — a tight 30–50 word description of fixed traits (hair, build, clothing signature, distinguishing marks, or product silhouette + material + color). Reuse it word-for-word in every prompt of the set, then vary only the scene-specific portion.

**Worked example (canon block):**

> A tall lean woman in her late twenties with copper-red shoulder-length hair tucked behind one ear, pale freckled skin, sharp green eyes, wearing a navy oversized wool peacoat over a charcoal turtleneck and dark jeans, plain brown leather boots.

Then per-shot:

> [canon block]. Sitting alone in a window seat of a near-empty Tokyo subway car at night, reading a worn paperback. Wide medium shot from across the aisle, 35mm lens, shallow depth of field. Cool fluorescent overhead light reflecting off the dark window beside her, muted teal and amber grade, fine 35mm grain.

## Quick reference: scenario → formula

| User wants | Use formula |
|---|---|
| Make a prompt from scratch | §1 Text-to-image |
| Attach refs, generate new image | §2 Multimodal |
| Tweak an existing generated image | §3 Editing |
| Apply a style from another image | §4 Style transfer |
| Use live web data in the image | §5 Real-time |
| Put readable words in the image | §6 Text-in-image |
| Multiple shots of same character/product | §7 Consistency |
