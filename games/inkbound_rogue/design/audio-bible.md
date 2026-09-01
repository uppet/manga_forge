# Audio bible

## Musical identity

Inkbound uses dry percussion, low calligraphy-brush drones, struck paper, wood
resonance, and restrained plucked tones. Material noise leads the mix; pitched
voices provide shadow and tension instead of arcade-like melody. Music must
support combat readability rather than fill every frequency. All runtime music
is 22.05 kHz, 16-bit mono WAV and uses a short boundary guard so loop transients
return to zero.

| State | Runtime ID | Length | Character |
| --- | --- | ---: | --- |
| Public Archive | `archive` | 32 s | Sparse bass, paper taps, restrained two-beat phrase |
| Forbidden Bindery | `bindery` | 32 s | Triple-meter binding knocks and darker brush grain |
| First Press | `finale` | 32 s | Four-beat wood press rhythm and rising urgency |
| Red Editor | `boss_editor` | 24 s | Fast stamped verdict rhythm with dry paper cracks |
| Binder | `boss_binder` | 24 s | Heavy binding accents and circular phrase |
| First Author | `boss_author` | 24 s | Wide press impacts and unstable plucked register |

Boss entry crossfades from the active act loop over 0.55 seconds. Defeat returns
to the current act loop; restored checkpoints select the boss layer whenever a
boss is present. Both music players process during modal pause so transitions do
not stall underneath story or interface states. The saved music setting is the
single user-facing gain; no second internal attenuation may make an enabled loop
effectively inaudible beneath combat cues.

## Cue language

- Marginalia and Twin-Stroke use a dry, broadband blade-air cut; Greatbrush uses
  a slower low-bodied stroke, Needlepoint a short bright edge, and Seal-Caster a
  paper drag plus stamp. Weapon cues lead with shaped noise and material
  transients rather than swept oscillator tones. Edge chirp and handle/body
  resonance support the cut, but tonal beeps never become its identity.
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

`audio_system_test.gd` verifies all 25 cues, all six extended loops and their lengths,
weapon mappings, six enemy warning families, supply and UI cues, adaptive boss
selection, persistent-pause players, cooldown coverage, and a production-mode
two-player crossfade.
