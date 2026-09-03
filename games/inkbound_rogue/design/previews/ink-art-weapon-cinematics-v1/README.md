# Weapon-specific Ink Art cinematic previews v1

These are silent, non-runtime visual prototypes for review. They do not modify
or reference any Godot scene, script, import, save schema, input path, or shipped
asset. The battle stage is a static comparison mock-up; frozen enemies provide a
common visual baseline for the proposed hit-stop sequence.

| Weapon form | Ink Art | Timing identity | Preview |
| --- | --- | --- | --- |
| Marginalia Blade | Palimpsest Ring | Balanced stationary circle and four cardinal cuts | `marginalia/palimpsest-ring-preview.mp4` |
| Greatbrush | Final Period | Slow shoulder load, overhead commitment, heavy period impact | `greatbrush/final-period-preview.mp4` |
| Needlepoint | Red Line | Compressed stance followed by a very fast horizontal displacement | `needlepoint/red-line-preview.mp4` |
| Seal-Caster | Seal Storm | Ground seal, staged wave count, held twelve-direction release | `seal-caster/seal-storm-preview.mp4` |
| Twin-Stroke | Cross Revision | Measured real cut, delayed mirrored cut, crossed impact | `twin-stroke/cross-revision-preview.mp4` |

`all-weapons-comparison.mp4` concatenates the five clean masters and adds an
English identification label to each segment. Individual previews have no
labels. Every master is 960 x 540, 30 FPS, H.264, and silent.

## Generation method

The built-in OpenAI image generation tool produced one dedicated 16:9 cut-in
and one five-keyframe strip for each weapon. Every call used the committed Nara
combat atlas and slash atlas as identity/style references; cut-ins also used the
approved first cinematic concept as a quality reference. Generated checkerboard
contamination was removed before compositing. No live or runtime generation is
involved.

## Final prompt set

All ten image prompts shared these invariants:

- Preserve Nara's long black high ponytail, red headband/scarf/sash, white wrap
  shirt, charcoal hakama, sandals, lean build, face, and limited
  black/ivory/crimson/gold manga-pixel palette.
- Cut-ins are premium 16:9 manga key art with crisp pixel-edge clusters, hard
  cel shading, dry-brush ink, no text, UI, enemy, logo, watermark, blue glow, or
  photorealism.
- Animation sources are exact five-column strips: one complete real Nara per
  cell, consistent scale and baseline, distinct readable poses, confined
  effects, and genuine RGBA transparency.

Weapon-specific final briefs:

### Marginalia / Palimpsest Ring

- Cut-in: one normal black katana tracing a broken full circle, with four short
  cardinal cuts; calm centered composition revealing ivory paper beneath ink.
- Frames: low guard, first quarter-circle, pivot through the back half, compact
  four-direction finishing cuts, recovery inside the completed ground ring.

### Greatbrush / Final Period

- Cut-in: low-angle Nara hauling one enormous black-bristle calligraphy
  brush-blade overhead above a dense gold-edged ink period.
- Frames: bristles drag behind a low stance, shoulder load, two-handed overhead
  commitment, vertical slam, deep landing in a circular period shock ring.

### Needlepoint / Red Line

- Cut-in: extreme close-up sighting along one needle-thin calligraphy-nib blade;
  a single straight crimson line crosses the focused eye and blade point.
- Frames: compressed side-on guard, explosive first step, full piercing dash,
  low brake beyond the target, controlled recovery behind a breaking red line.

### Seal-Caster / Seal Storm

- Cut-in: one compact reverse-grip seal-blade, abstract square red/gold seal in
  the foreground, and exactly twelve evenly spaced cutting waves behind Nara.
- Frames: reverse guard, ground stamp, four cardinal waves, held twelve-wave
  radial release, recovery in a fading steel/gold ring. Seals contain no text.

### Twin-Stroke / Cross Revision

- Cut-in: one physical black katana on the crimson diagonal and one translucent
  ivory delayed reflection on the opposite diagonal, joined by a gold ring.
- Frames: contained diagonal guard, first real cut, delayed mirrored cut,
  completed X impact around one real Nara, recovery behind breaking crossed
  trails. The echo is not a second physical person or dual wielding.

The videos add only timing, frozen battle-stage compositing, form-colored
flashes, and a return to gameplay. Greatbrush is intentionally the slowest;
Needlepoint is intentionally the shortest and translates Nara across the arena;
Seal Storm holds its fourth frame; Cross Revision uses two offset flashes.
