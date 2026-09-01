# Nara slash atlas v1

Generated with the built-in OpenAI image generation tool from
`combat-cast-atlas-v1.png`; only its top-left swordsman was used as the identity
and style reference.

## Generation prompt

```text
Use case: stylized-concept
Asset type: production 2D game character attack-animation sprite sheet
Input image: Image 1 is the visual identity and style reference; use only the top-left swordsman character.
Primary request: create four genuinely distinct hand-drawn keyframes of that exact swordsman performing one forceful horizontal sword slash.
Subject invariants: preserve his long black hair, red scarf and sash, white shirt, loose black trousers, black ink-like sword, lean body proportions, limited black/ivory/crimson palette, and gritty manga pixel-art rendering.
Composition: exact 2-by-2 grid on one square transparent canvas. Every cell is exactly equal size with the character centered at consistent scale and feet on the same baseline. Reading order is top-left, top-right, bottom-left, bottom-right.
Frame 1: strong anticipation, weight lowered, sword pulled behind him.
Frame 2: accelerating cut through the torso line, coat and hair trailing.
Frame 3: decisive contact/follow-through, sword fully extended, one short ivory/crimson ink slash accent.
Frame 4: recovery into a low guard, momentum still visible in hair and scarf.
Style/medium: crisp high-resolution pixel-art sprite, authored manga silhouette, hard clusters and selective dithering, matching Image 1.
Constraints: actual transparent background and preserved alpha; one complete character per cell; no cropping; no overlap between cells; no grid lines; no gutters; no labels; no text; no UI; no shadow; no extra character; no watermark. The pose, limbs, sword angle, cloth and silhouette must visibly change in every frame.
Avoid: static repeated pose, simple rotation of one drawing, smooth vector art, 3D render, blur, photographic lighting.
```

The first render baked a checkerboard into RGB. After background extraction, a
bottom-left sword tip crossed the cell boundary. The final two edit prompts were:

```text
Use case: precise-object-edit
Asset type: production 2D game attack-animation sprite sheet
Input image: Image 1 is the exact edit target, a 1254-by-1254 RGBA canvas divided into four exact 627-by-627 cells.
Primary request: fix only the bottom-left frame so every visible pixel belonging to that frame stays strictly inside x=0..626 and y=627..1253. Move that entire bottom-left swordsman and his sword/ink accent slightly left and shorten only the extreme sword-tip/ink accent as needed; keep the complete figure uncropped.
Critical contamination fix: erase the bottom-left frame's sword-tip and red ink pixels that currently cross x=627 into the bottom-right cell. The bottom-right frame must contain only its own swordsman with transparent empty space around it.
Invariants: top-left, top-right, and bottom-right frames must remain pixel-for-pixel visually unchanged in pose, placement, identity, scale, colors, and details. Preserve the bottom-left pose, character identity, feet baseline, crisp pixel-art style, and overall scale. Preserve the exact 1254-by-1254 canvas and exact 2-by-2 layout.
Constraints: genuine transparent RGBA background; no checkerboard; no grid; no labels; no text; no watermark; no pixels from any frame may cross into another cell; no cropping of bodies, hair, scarf, hands, feet, or main sword blade.
```

```text
Use case: background-extraction
Asset type: production 2D game attack-animation sprite sheet
Input image: Image 1 is the exact edit target.
Primary request: remove only the solid near-black background and replace it with genuine full alpha transparency.
Invariants: preserve every visible swordsman, every pose, sword, scarf, hair strand, red ink accent, crisp pixel edge, exact 1254-by-1254 dimensions, exact 2-by-2 placement, empty center gutters, scale, alignment, and colors. Do not redraw, reposition, crop, rescale, retouch, or add anything.
Constraints: output an actual RGBA PNG; all empty background and center-gutter pixels must have alpha 0; preserve opaque sprite pixels; no black matte or color fill; no halos; no checkerboard; no grid; no text; no watermark.
```
