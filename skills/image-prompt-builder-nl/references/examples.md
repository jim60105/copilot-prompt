# Example Prompts — Annotated

Reference these when calibrating tone, length, and structure. Each example shows the **input intent** (what the user asked for) and the **delivered prompt**, with brief notes on which formula and toolkit choices were applied.

## Example 1 — Simple portrait, photographic

**Intent:** "A confident woman in a red coat for a fashion ad."

**Prompt:**

> An editorial fashion photograph of a tall woman in her thirties wearing a tailored crimson wool overcoat, charcoal cigarette trousers, and pointed black ankle boots, standing with one hand in her pocket and a faint smile, slightly turned toward camera. Set against a seamless deep cherry-red studio backdrop. Medium-full shot, centered, 85mm lens at f/2.8, shallow depth of field. Three-point softbox lighting with a warm key from camera-right and a subtle rim from behind, shot on medium-format film, pronounced grain, saturated reds, cinematic warmth.

**Notes:**

- Formula §1 (text-to-image).
- Style/medium: editorial fashion photograph + medium-format film.
- Camera: 85mm f/2.8, medium-full, centered.
- Lighting: three-point softbox + warm key + rim.
- Material: tailored wool, pointed leather boots.

## Example 2 — Cinematic narrative scene

**Intent:** "Lonely diner at night."

**Prompt:**

> A long-exposure 35mm film photograph of an empty corner diner at 2 a.m., a single weary waitress in a faded teal uniform leaning on the counter and staring at her phone, an untouched coffee cup at her elbow. Wide medium shot through the rain-streaked plate-glass window from the sidewalk outside, 35mm lens at f/4. Cold blue ambient streetlight outside contrasting with the warm fluorescent buzz inside, soft halation around the interior lights, muted teal-and-amber color grade, fine 35mm grain, faint reflection of indistinct neon glow across the wet asphalt in the foreground.

**Notes:**

- Subject is singular (the waitress) with environmental story.
- Positive framing ("empty corner diner") rather than "no customers".
- Lighting names both sources (cold streetlight + warm fluorescent).
- Composition layered: foreground (wet asphalt + reflection), midground (window), subject behind.

## Example 3 — Multi-reference product render

**Intent:** Two images provided — a wireframe sketch of a chair and a fabric swatch. User wants a finished render.

**Prompt:**

> Using the attached wireframe sketch as the structural form and the attached oat-colored bouclé swatch as the upholstery texture, render a high-fidelity 3D product visualization of the resulting single-seater armchair. Place it in a sun-drenched minimalist Scandinavian living room with a pale oak floor and a single ceramic vase on a low side table. Three-quarter front view, 50mm lens, eye-level, shallow depth of field with the chair sharp and the background gently blurred. Soft warm key light from a large window camera-right, cool fill bouncing from a white wall on the left, neutral natural color palette with subtle warm highlights on the bouclé fibers.

**Notes:**

- Formula §2 (multimodal).
- Each reference's role stated explicitly: sketch → structure, swatch → texture.
- Setting and lighting added on top of the references.

## Example 4 — Edit existing image

**Intent:** "Remove the bystander from my photo without messing up anything else."

**Prompt:**

> Remove the man in the dark blue jacket standing on the right edge of the frame. Cleanly inpaint the space he occupied as a continuation of the brick wall and the cobblestones behind him. Keep the subject, her pose, her clothing, the lighting direction and quality, and all background elements unchanged from the source image; any existing signage on the left stays in place as it appears in the source but its text is not re-rendered or altered.

**Notes:**

- Formula §3 (editing).
- Names the target precisely ("man in the dark blue jacket on the right").
- Equal weight on what to PRESERVE.
- No new lighting / style invented; the edit is surgical.

## Example 5 — Style transfer

**Intent:** "Make my street photo look like a Van Gogh."

**Prompt:**

> Recreate the exact composition and content of the source photograph in the painted style of late Van Gogh: keep every building, the street layout, the figure positions, and the perspective unchanged, but render the scene with thick impasto brushwork, visible directional strokes following form, swirling textured sky, and a warm yellow / deep cobalt-blue palette with vivid contrast.

**Notes:**

- Formula §4 (style transfer).
- "Keep composition / content unchanged" is explicit so the model doesn't reinvent geometry.
- Style call-outs are specific: impasto, directional strokes, swirling sky, two-color palette.

## Example 6 — Text inside the image (user explicitly asked)

**Intent:** "A poster that says 'NEW YORK' with the skyline showing through the letters."

**Prompt:**

> A graphic typographic poster on a solid black background. The bold sans-serif letters "NEW YORK" fill the center of the frame in a single line, acting as a cut-out window: a photograph of the Manhattan skyline at golden hour is visible only inside the letterforms, with the rest of the canvas remaining pure black. Crisp, perfectly legible type. Tight centered composition, slight letterforms tracking, contemporary minimalist poster style.

**Notes:**

- Formula §6 (text-in-image).
- Exact words in quotes: `"NEW YORK"`.
- Type style named: *bold sans-serif*.
- Effect described precisely (letters as cut-out window).
- Restriction stated ("rest of the canvas remaining pure black") to prevent the model from also painting a skyline outside the letters.

## Example 7 — Character consistency set (3 shots)

**Intent:** "Three shots of the same detective character — at a desk, on a rooftop, in a car."

**Canon block (reused):**

> A wiry man in his late forties with close-cropped salt-and-pepper hair, a three-day stubble, deep-set tired grey eyes, wearing a rumpled charcoal trench coat over a wrinkled white shirt with the top button undone and a loosened black tie, holding a worn leather notepad.

**Shot 1 — desk:**

> [canon block]. Sitting alone at a cluttered wooden desk in a dim precinct office at night, leaning over a spread of crime-scene photographs, brow furrowed. Medium close-up, slightly high angle, 50mm lens at f/2.2. Single warm desk-lamp key from camera-left casting deep shadows across his face, cool blue light leaking in through window blinds in the background, muted teal-and-amber grade, 35mm grain.

**Shot 2 — rooftop:**

> [canon block]. Standing at the edge of a rain-slick rooftop at dawn, looking out over a grey city skyline, breath visible in the cold air. Wide medium shot, slight low angle, 35mm lens at f/4. Cool overcast pre-sunrise key from camera-right, faint warm city lights below, desaturated blue-grey palette with a single warm note from a distant neon sign, fine grain.

**Shot 3 — car:**

> [canon block]. Sitting behind the wheel of a stationary sedan parked on an empty avenue at night, half-lit by the dashboard glow, eyes scanning out the windshield. Close-up from the passenger seat, 35mm lens at f/1.8. Warm amber dashboard underlight on his face, cold cyan streetlight from outside the driver's window, strong chiaroscuro, deep blacks, anamorphic-flavored widescreen.

**Notes:**

- Formula §7 (consistency).
- Canon block is verbatim across all three; only setting/action/lighting vary.
- Each shot still picks lighting + camera + grade individually.

## Example 8 — Tag-list input → NL rewrite

**Intent (raw user input):** `"1girl, long blonde hair, blue eyes, white dress, beach, sunset, looking at viewer, smiling, cinematic, masterpiece"`

**Prompt (rewritten):**

> A warm cinematic photograph of a young woman with long flowing blonde hair and pale blue eyes, wearing a flowing white linen sundress that catches the breeze, standing barefoot on a stretch of damp sand at the water's edge, looking directly into the camera with a soft genuine smile. Wide medium shot, low angle close to the sand, 50mm lens at f/2.2, shallow depth of field. Golden-hour backlight from the setting sun behind her creating a halo through her hair and a long shadow stretching toward the camera, warm amber-and-rose palette, fine 35mm grain.

**Notes:**

- All tag-syntax residue removed.
- "1girl" → "young woman"; "looking at viewer" → "looking directly into the camera"; *masterpiece / cinematic* → replaced with real production language.
- Added specific lighting (golden-hour backlight) and one material call-out (*linen* sundress).

## Example 9 — Vague input clarified

**Intent (raw user input):** *"make me a cool image of a robot"*

**Skill response shape:**

> Quick question before I draft — what mood: *clean futuristic / battle-worn / cute companion / unsettling uncanny*? Want me to make a sensible default (battle-worn, cinematic) and you can redirect from there?

> [On user OK or no response in single-turn mode, default and proceed:]

> A cinematic medium close-up of a battle-worn humanoid robot standing in a fog-filled industrial yard at dusk, scratched matte-grey alloy plating streaked with rust and oil, exposed cabling running down one arm, a single intact glowing amber eye-lens fixed on something off-frame. Low angle, 35mm lens at f/2.0, shallow depth of field. Cool overcast key from above and a single warm sodium-vapor lamp from camera-right creating a strong rim along the wet metal, volumetric haze, desaturated steel-and-amber grade, fine grain.

**Notes:**

- Asked exactly one focused clarifying question before drafting.
- Stated the assumed default explicitly so the user can override.
- Final prompt still followed the full workflow.

## Example 10 — Avoiding accidental text rendering

**Intent:** "A coffee shop interior" (user did NOT ask for text/signage).

**Prompt:**

> An editorial-style photograph of a quiet independent coffee shop interior on a weekday morning, a single barista in a denim apron polishing a brass espresso machine behind a worn wooden counter, two empty stools in the foreground. Warm overhead pendant lights with exposed filament bulbs casting a soft golden glow across the room, daylight filtering in through a large front window out of frame to the left. Medium shot from across the counter, 35mm lens at f/2.8. Materials: reclaimed barnwood counter, brushed brass espresso machine, white subway-tile back wall, hanging dried-flower bouquets. Any signage, menu boards, or labels are softly out of focus and indistinct in the background. Warm earthy palette, fine 35mm grain.

**Notes:**

- Explicitly handled the text trap: *"any signage… softly out of focus and indistinct"* prevents the model from rendering hallucinated coffee-menu gibberish.
- Materials section reinforces tactile realism without resorting to *"masterpiece quality"* style filler.
