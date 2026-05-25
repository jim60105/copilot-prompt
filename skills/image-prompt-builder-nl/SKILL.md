---
name: image-prompt-builder-nl
description: Craft high-quality natural-language image prompts for any modern text-to-image or image-edit model that accepts flowing English. Trigger when the user wants help writing, rewriting, improving, or translating an English natural-language image prompt — including "write me an image prompt", "improve this image prompt", "describe this scene for an image model", or "convert these tags into a natural language prompt". Do NOT trigger for requests that are purely about dispatching to an image API, choosing samplers/schedulers, picking LoRAs, or setting up ControlNet — those belong to a runtime skill.
license: GFDL-1.3-or-later
---

# Image Prompt Builder — Natural Language

You help the user transform a vague idea, a sketch of intent, a tag list, or an existing rough prompt into a precise, evocative, **natural-language English image prompt**. This skill is **model-agnostic by design** — do not name, assume, or branch on a specific image model. A paragraph that follows the workflow below will work across any NL-capable image model; the user routes it to whatever runtime they prefer.

## What this skill IS and IS NOT

**IS:** A general-purpose, model-agnostic natural-language prompt writer.

**IS NOT:**

- Not a Danbooru tag generator and not a weight-syntax writer. No `1girl, blue_eyes` lists, no `(tag:1.5)`, `{{tag}}`, `[tag]`, `<lora:...>`.
- Not a runtime advisor (samplers, CFG, seed, negative prompts, dispatch). If the runtime needs those, defer to a runtime skill or ask the user separately.
- Not a content-policy gate — acceptability is judged elsewhere in the pipeline; this skill focuses purely on prompt craft.

## Important content rule (always apply)

**Do not render text/letters/words inside the image unless the user explicitly asks for text in the image.** Image models commonly hallucinate gibberish text whenever the prompt mentions readable signage, logos, captions, etc. So:

- If the user did NOT ask for text → never include text content in the prompt. If signage, books, screens, menu boards, etc. appear in the scene, prefer wording like *"bearing no readable text"*, *"with unreadable / illegible characters"*, *"out of focus and indistinct"*, **or omit the surface entirely**. The bare word *"indistinct"* alone is often not enough — many models will still render partially legible glyphs unless you explicitly negate readability.
- If the user DID ask for text → enclose the exact wording in double quotes (e.g. `the words "URBAN EXPLORER"`), name the typography style (e.g. *bold sans-serif*, *flowing brush script*), and place it deliberately.
- **Editing exception**: if the user is editing an existing image and that image already contains text/signage they did NOT ask to change, instruct the model to keep that region unchanged from the source (e.g. *"the existing signage on the left remains as in the source image"*) rather than describing what the text says. This preserves the source pixels without asking the model to re-render legible glyphs.

## Reasoning flow (think this through before drafting)

Treat prompt-writing as a layered build. Mentally pass through these eight layers and decide what each contributes; percentages are rough attention weights for a typical request.

1. **Concept distillation (~15%)** — extract the single core image. Strip competing ideas; the rest become possible variations.
2. **Style / medium fusion (~15%)** — decide the medium and any blended influences (*cinematic photograph*, *gouache illustration with line-art overlay*, *isometric vector*, *moody oil painting with impasto*). Lead the prompt with this.
3. **Technical / craft alchemy (~15%)** — pick medium-appropriate craft language: camera/lens/aperture for photo; brush, line, shading for illustration; layout, hierarchy, line weight, palette for graphic design.
4. **Composition (~20%)** — the highest-weight layer. Decide shot type / framing, viewpoint, eye-line, depth layers, and the layout rule (rule of thirds, central symmetry, leading lines, golden spiral, negative-space framing).
5. **Sensory enchantment (~10%)** — cross-sensory cues that make the image feel real: temperature, air (humid / dry / smoky / dusty), tactile materials, implied sound or stillness.
6. **Narrative micro-spell (~10%)** — weave a hint of before/after into the frame: posture suggesting motion just stopped, an object out of place, an expression between two emotions.
7. **Color & texture (~10%)** — name the palette and the dominant materials/textures (raw linen, brushed brass, weathered concrete, watercolor paper bleed).
8. **Art lineage (~5%, optional)** — if appropriate, anchor with a style family or movement (*Art Nouveau*, *Ukiyo-e*, *mid-century modern poster art*). Prefer movements over naming living artists.

After this mental pass, write **one flowing paragraph** that integrates the chosen layers — do not output them as a list. The layers are scaffolding for thought, not the shape of the prompt.

## Workflow

The four phases below are the operational version of the reasoning flow. Move through them quickly for simple asks, deliberately for complex ones.

### 1. Distill the intent

Identify:

- **Dominant visual focus** — what should the viewer see first? May be a single subject, a relationship between subjects, an environment, a product group, or a graphic layout. Most prompts benefit from one clearly dominant focus.
- **Action / pose / expression** — what is the subject doing or feeling?
- **Setting** — where, when, weather, time of day?
- **Mood / story** — what emotion or micro-narrative?
- **Medium** — photo / illustration / 3D / painting / graphic-design? Drives Phase 3 vocabulary.
- **Constraints** — aspect ratio, style family, forbidden elements, brand/character continuity.

If a critical detail is missing AND a reasonable default would materially change the result, ask one focused clarifying question. Otherwise pick a sensible default and note it so the user can override.

### 2. Draft using the core formula

The canonical sentence-level structure:

```
[Style / medium] → [Subject + key descriptors] → [Action / expression]
→ [Setting / environment] → [Lighting / atmosphere] → [Camera or medium-specific craft / composition]
→ [Color & texture details]
```

Write it as **one flowing paragraph** of natural English. Typical length is 60–180 words (short 40–80, medium 80–160, long/complex 160–250 — see Phase 4 checklist). Open with a strong noun phrase or verb (e.g. *"A cinematic close-up photograph of…"*, *"Render a moody oil-painting scene where…"*).

For the per-scenario phrasing (text-to-image, multi-reference, editing, real-time/web-search-informed, text-in-image), see [references/formulas.md](references/formulas.md).

### 3. Direct the scene (medium-aware)

A draft becomes a *great* prompt when you swap generic adjectives for concrete production language. Which vocabulary to reach for depends on the medium:

- **Photographic / cinematic / photo-realistic 3D / product shot** — use the full cinematography toolkit: lighting setup, camera body, lens / focal length, aperture / depth-of-field, color grade / film stock, materiality.
- **Illustration / painting / anime / comic / concept art** — replace camera language with: medium (oil / watercolor / gouache / ink / digital paint), line quality, brushwork, shading technique (cel-shaded / soft-shaded / hatched), color palette, art movement or named tradition (e.g. *Art Nouveau*, *Ukiyo-e*, *Studio Ghibli–inspired backgrounds*), **and explicit shot framing + viewpoint** (close-up portrait / medium half-body shot / wide establishing shot / over-the-shoulder; eye-level / low-angle / bird's-eye). Illustration models do not infer shot scale from "depth" or "framing" — state it. ⚠️ If the user has chosen an illustration / anime model, photographic terms like *"85mm f/2.0"* may be reinterpreted loosely or ignored — lean on this bullet's vocabulary instead, even if the user describes the scene cinematically.
- **Graphic design / logo / vector / poster / UI mockup / pixel art / icon / diagram** — replace camera language with: layout / visual hierarchy, negative space, line weight, typography behavior (only if the user wants text), color system, geometric shape language. Do NOT specify lens or f-stop for vector or pixel-art outputs.

For the concrete vocabulary in each category — and for any other medium — see [references/director-toolkit.md](references/director-toolkit.md).

Scan your draft for vague descriptors (*good lighting*, *nice colors*, *beautiful*) and replace each with a concrete choice from the toolkit appropriate to the chosen medium.

### 4. Critique and refine

Run the draft against this checklist; rewrite weak lines:

- [ ] Opens with a strong, specific style/medium descriptor (not "beautiful", "amazing").
- [ ] **Priority ordering**: the most important subject + action + style constraints appear in the first sentence. Later sentences refine lighting, composition, materiality — they should not introduce competing concepts.
- [ ] Subject / focus is unambiguous; multi-subject prompts state the dominant focus.
- [ ] **Positive framing for generation prompts**: describe what IS in the frame, not what isn't ("an empty street", not "no cars"). **Edit prompts are exempt** — explicit *remove* / *preserve* / *unchanged* language is allowed and usually necessary.
- [ ] Lighting is named (direction + quality + temperature), not just "good lighting" — OR for non-photographic media, replaced with a medium-appropriate equivalent (palette, line weight, brushwork, etc.).
- [ ] At least one piece of medium-appropriate craft language (camera + lens for photo; brushwork / line / shading for illustration; layout / hierarchy / negative space for graphic design).
- [ ] At least one concrete material or texture word (skip for pure vector / flat-design outputs).
- [ ] No tag/weight syntax: no `{}`, `[]`, `(tag:1.5)`, `<lora:>`, no comma-separated keyword soup.
- [ ] No accidental text-rendering instructions unless the user asked for text (re-read the "Important content rule").
- [ ] **Shot framing is explicit** — close-up / medium / wide, plus viewpoint (eye-level / low-angle / bird's-eye / over-the-shoulder). Do not rely on "depth" or "framing" alone to imply it.
- [ ] **At least one narrative micro-anchor** — a single concrete physical detail that gives the eye something to land on (steam curling from a cup, a single fallen petal, a half-written line on paper, a fingerprint on glass). Skip only for pure logo / icon / vector work.
- [ ] **Art-lineage anchor present (recommended, not strict)** — a style family, movement, or aesthetic tradition (*Studio Ghibli–inspired*, *Art Nouveau*, *Ukiyo-e*, *mid-century modern poster*). Prefer movements / studios over naming living artists. Omit only when the user explicitly wants neutral / generic styling.
- [ ] Length is appropriate and matches Phase 2: short (40–80 words) for simple subjects, medium (80–160) for cinematic scenes, long (160–250) for complex multi-element compositions. Beyond ~250 words you are usually hurting the model.
- [ ] If references were provided, the relationship between each reference and the output is stated explicitly ("use the pose from image A, the color palette from image B").

### Optional: offer the user a follow-up

After delivering the prompt, briefly offer 1–3 specific variations (e.g. *"want me to swap the lighting to harsh midday sun?"*, *"want a 9:16 portrait variant?"*). One line, not another draft.

## Output shape

Default to this response shape unless the user requests otherwise:

```
Prompt:
<one-paragraph natural-language prompt, 60–180 words>

Notes (optional, ≤3 bullets):
- Aspect ratio / size recommendation if relevant
- Any assumption you made (so the user can override it)
- One suggested variation
```

For multiple distinct scenes (storyboard, ad campaign, character sheet), output one prompt per scene with a one-line caption above each; keep subject/style continuity language consistent across the set.

## When to load reference files

- **Simple text-to-image prompt for a familiar medium** → the core formula in this file is enough; do not load anything.
- **Reference images, editing, text-in-image, real-time/web-search, or character-consistency sets** → load [references/formulas.md](references/formulas.md) for the scenario-specific template.
- **Draft feels generic / "AI-slop" / over-uses vague adjectives** → load [references/director-toolkit.md](references/director-toolkit.md) and replace weak words with specific vocabulary.
- **Need to calibrate tone, length, or structure against known-good prompts** → load [references/examples.md](references/examples.md).

## What to do when the input is hostile to good output

- **Input is just tags** ("1girl, blue dress, beach, sunset") → ack the tags, then **rewrite as flowing English** following the workflow. Don't echo the tags back.
- **Input is extremely vague** ("make me a cool image") → ask one focused question (typically subject + mood) before drafting.
- **Input is too long / a wall of contradictory adjectives** → distill it down to the essential intent before drafting; the prompt you deliver should be tighter than the input.

