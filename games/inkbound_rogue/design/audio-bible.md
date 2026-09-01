# Audio bible

## Musical identity

Inkbound uses dry percussion, low calligraphy-brush drones, struck paper, metal
bindings, and deliberately synthetic pulse voices. Music must support combat
readability rather than fill every frequency. All runtime music is 22.05 kHz,
16-bit mono WAV and loops at a boundary where transient envelopes return to zero.

| State | Runtime ID | Length | Character |
| --- | --- | ---: | --- |
| Public Archive | `archive` | 16 s | Sparse bass, air, restrained two-beat phrase |
| Forbidden Bindery | `bindery` | 16 s | Triple-meter chain scrape and darker pulse |
| First Press | `finale` | 16 s | Four-beat press rhythm and rising urgency |
| Red Editor | `boss_editor` | 12 s | Fast stamped verdict rhythm |
| Binder | `boss_binder` | 12 s | Heavy chain accents and circular phrase |
| First Author | `boss_author` | 12 s | Wide press impacts and unstable high register |

Boss entry crossfades from the active act loop over 0.55 seconds. Defeat returns
to the current act loop; restored checkpoints select the boss layer whenever a
boss is present. Both music players process during modal pause so transitions do
not stall underneath story or interface states.

## Cue language

- Marginalia and Twin-Stroke use a dry, broadband blade-air cut; Greatbrush uses
  a slower low-bodied stroke, Needlepoint a short bright edge, and Seal-Caster a
  paper drag plus stamp. Weapon cues lead with shaped noise and material
  transients rather than swept oscillator tones. A restrained metal tick or
  handle/body resonance may support the sound, but never becomes its identity.
- Every Ink Art shares a recognizable rising ink release, pitch-shifted by form.
- Enemy projectile casts, dash charges, teleport windups, parries, shields, and
  Archivist restoration are positional warnings, not decorative noise.
- Ink Bomb and combat supplies use separate burst and power-up families.
- Menu movement, confirm, cancel, and Save & Return have short non-positional
  cues that remain audible during pause.

High-frequency combat cues have per-family millisecond cooldowns. This prevents
large squads from allocating unbounded simultaneous players while retaining the
first readable warning. Master, music, and SFX settings continue to apply to all
new cues.

## Validation

`audio_system_test.gd` verifies all 25 cues, all six loops and their lengths,
weapon mappings, six enemy warning families, supply and UI cues, adaptive boss
selection, persistent-pause players, cooldown coverage, and a production-mode
two-player crossfade.
