# Cover art v2 provenance

`cover-art-v2.png` is an AI-assisted storefront image generated on 2026-09-05
with OpenAI's built-in image-generation tool under Manga Forge project
direction. It corrects the rejected v1 candidate by depicting Nara as the adult
young woman established in `design/narrative-bible.md`. It is a release/store
asset and is not loaded by the game runtime.

- Dimensions: 1410 × 1116 RGB PNG
- SHA-256: `e952142a7790330eea9b16ab6f8897d07c44ff3beeb48c9a8130e04950eca188`
- Human review: pending project-owner approval
- Rights/IP review: pending before public distribution

## Input images

1. Rejected cover-art v1 — edit target and authoritative composition. The
   rejected bitmap is not retained in Git because it depicted Nara as male;
   its SHA-256 was
   `e79b9184c3369ad447c40416b1512b8d021da604afe303540bd86129e866c7c1`.
2. `assets/characters/combat-cast-atlas-v1.png` — supporting character
   reference; the top-left figure is Nara.

## Final edit prompt

```text
Use case: identity-preserve
Asset type: corrected v2 storefront cover art for Last Inkwarden / 墨卫残章.
Input images: Image 1 is the edit target and authoritative cover composition. Image 2 is a supporting character reference; the top-left pixel-art figure is Nara, the female protagonist.
Primary request: Correct Nara in Image 1 so she is unmistakably an adult young woman warrior while preserving her fierce competence and the full power of the action. Change only Nara's gender presentation and the anatomy needed to express it: a clearly feminine but mature face, slightly narrower jaw and shoulders, lean athletic female build, natural feminine torso proportions beneath the fully covering layered white wrap shirt, and strong but less bulky forearms. Keep her expression severe, focused, and battle-hardened—not cute, smiling, fragile, glamorous, or sexualized.
Character invariants: Nara is one adult woman in her twenties. Preserve her long black high ponytail, red headband, long red scarf and waist sash, white wrap shirt with rolled short sleeves, loose charcoal-black hakama trousers, sandals, black ink-like katana/brush-blade with small gold guard, exact pose, direction of gaze, hand placement, and readable weapon silhouette.
Image invariants: keep the exact near-landscape framing, title placement, title spelling, ruined Grand Archive, window and manuscript rings, all paper-mask enemies, torn pages, black ink arc, gold sparks, lighting, palette, linework, and mature manga rendering unchanged. Preserve the exact text "LAST INKWARDEN" and "墨卫残章", each exactly once, with no extra text.
Constraints: one female protagonist only; correct hands and limbs; practical non-revealing clothing; no cleavage emphasis; no exposed midriff; no male facial hair; no masculine bodybuilder anatomy; no childlike proportions; no redesign of the costume; no extra person; no UI; no watermark.
Avoid: changing the background, enemies, title typography, color palette, crop, pose, weapon, or action; avoid pin-up styling, excessive makeup, oversized breasts, generic fantasy armor, glossy 3D rendering, invented letters.
```

The historical edit prompt below describes Image 1 as the v1 file even though
that rejected bitmap is deliberately absent from version control.

Before publishing, the owner should inspect the full-resolution image for
gender readability at thumbnail size, recognizable third-party characters or
marks, artist imitation, malformed anatomy, and stray text; confirm the
generation-account terms and record approval or replace the candidate.
