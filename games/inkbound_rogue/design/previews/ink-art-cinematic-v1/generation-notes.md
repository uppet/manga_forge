# Ink Art cinematic concept v1

This is a non-runtime visual prototype. No Godot scene, script, import, or
shipping asset reference was changed.

> Canon correction, 2026-09-06: Nara is an adult young woman. The historical
> prompts below incorrectly use `swordsman` and `he/his`; they are retained
> verbatim as provenance for the already-generated prototype and must not be
> reused as character direction. Future briefs must follow
> `design/narrative-bible.md` and use `woman warrior` plus `she/her`.

## Generated source art

The two source images were generated with the built-in OpenAI image generation
tool on 2026-09-02. Both used these committed images as identity/style
references:

- `assets/characters/combat-cast-atlas-v1.png`
- `assets/characters/nara-slash-atlas-v1.png`

### Full-screen cut-in prompt

```text
Use case: stylized-concept
Asset type: 16:9 full-screen ultimate-skill character cut-in for the 2D manga action game Last Inkwarden / 墨卫残章
Input images: Image 1 and Image 2 are identity and rendering-style references. Use only Nara, the top-left swordsman in Image 1 and the same swordsman shown in Image 2. Do not include any other character.
Primary request: create one spectacular full-screen manga cut-in of Nara the instant he activates an ink technique. Preserve his exact identity: lean young swordsman, long black hair in a high ponytail, red headband and long red scarf/sash, white wrap shirt with rolled short sleeves, loose charcoal-black hakama trousers, sandals, black ink-like katana with a small gold guard. He draws the sword upward across the foreground, three-quarter close-up from waist/chest upward, eyes sharp and calm, face clearly recognizable, scarf and hair exploding in the motion.
Scene/backdrop: abstract torn-paper panel, deep black sumi-ink eruption and diagonal speed lines, ivory paper slash, restrained crimson energy accents. No literal battlefield.
Style/medium: premium hand-painted manga key art blended with crisp high-resolution pixel-art edge clusters, dramatic cel shading, gritty ink texture, matching the supplied game art; polished enough for a commercial game ultimate cut-in.
Composition/framing: cinematic wide landscape 16:9, Nara fills most of the frame, strong diagonal from lower-left to upper-right, readable silhouette, sword never cropped at the hilt, face and eyes unobstructed. Strong black frame-edge vignette so it can wipe over gameplay.
Lighting/mood: violent ivory rim light and crimson reflected light against deep ink black; heroic, severe, exhilarating, never cute or comedic.
Color palette: near-black #08070B, ink #141218, ivory paper #EFE2C4, white #FFF8E0, crimson #D33037, dark red #701820, tiny gold #F2B344.
Constraints: no text, no letters, no UI, no logo, no watermark, no enemy, no extra person, no modern weapon, no blue glow, no photorealism. Keep all key detail safely inside a 16:9 crop.
```

### Five-pose startup strip prompt

```text
Use case: stylized-concept
Asset type: production 2D game ultimate-skill startup animation sprite sheet
Input images: Image 1 and Image 2 are identity and pixel-art style references. Use only Nara, the top-left swordsman in Image 1 and the same swordsman in all four cells of Image 2.
Primary request: create exactly five distinct full-body keyframes of Nara performing one continuous aerial ink-sword finisher: scoop upward, rise, overhead apex, falling cleave, sword stabbed into the ground.
Subject invariants: preserve the same lean young swordsman, long black high ponytail, red headband, long red scarf and waist sash, white short-sleeve wrap shirt, loose charcoal-black hakama trousers, sandals, black ink-like katana with small gold guard, and the limited black/ivory/crimson palette of the references.
Layout: exact 5-column by 1-row horizontal sprite sheet. Five equal cells from left to right, no gutters and no panel lines. One complete Nara per cell, centered horizontally within the cell, consistent character scale, no overlap or pixel contamination between cells. Keep feet or lowest action point aligned to a consistent baseline.
Frame 1: low planted crouch, sword scooping upward from near the floor, anticipation and a short ivory arc.
Frame 2: launching upward, toes just leaving the floor, torso stretched, sword continuing vertically, scarf and ponytail trailing downward.
Frame 3: airborne apex, knees slightly tucked, both hands raising the sword overhead, clear suspended silhouette.
Frame 4: forceful descending diagonal cleave, body extended downward, hair and scarf whipping upward, short crimson-and-ivory slash trail.
Frame 5: hard three-point landing, one knee bent, sword point driven vertically into the ground between both hands, compact radial black-ink cracks and crimson impact splash confined tightly around the sword tip.
Style/medium: crisp high-resolution manga pixel-art sprite, hard pixel clusters, selective dithering, authored animation silhouette, matching the supplied character atlases; no smooth vector edges and no 3D rendering.
Background: genuine fully transparent RGBA canvas.
Constraints: exactly five figures and no more; actual alpha transparency; every figure fully inside its own cell; no cropping; no extra character; no enemies; no floor except the tiny frame-5 impact cracks; no shadow; no text, labels, numbers, grid, UI, logo or watermark. Pose, limbs, sword angle, clothing, hair and silhouette must visibly progress in every frame. Do not repeat or simply rotate one drawing.
```

The initial strip returned a baked checkerboard, so a background-extraction edit
removed only that checkerboard and preserved the five poses on genuine alpha.

## Preview assembly

- Duration: 2.67 seconds
- Master: 960 x 540, 30 FPS, H.264, silent
- Review GIF: 640 x 360, 15 FPS
- Timing: battlefield, full-screen cut-in, ivory flash, five startup poses,
  impact hold, return to battlefield
- `battle-stage.png` is a review mock-up assembled from committed game assets;
  it is not a replacement game background.
