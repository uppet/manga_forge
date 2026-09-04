# Audio bible

## Musical identity

Last Inkwarden's experimental score uses five 海绵音乐 (Hai Mian Music) AIGC tracks
as its player-facing baseline. All runtime cues are 44.1 kHz stereo Ogg Vorbis
at roughly -16 to -17 LUFS. Music must still support combat readability rather
than fill every frequency.

| State | Runtime ID | Length | Source |
| --- | --- | ---: | --- |
| Title and Story Archive shell | `menu` | 106.88 s | 《墨色残响》, trimmed and cyclically crossfaded |
| All active gameplay and bosses | `battle` | 110.78 s | 《墨战交响》, trimmed and cyclically crossfaded |
| Prologue, chapter cutscenes, ending choice, story replay | `story` | 128.62 s | 《墨痕残忆》, trimmed for linear playback |
| Keep ending and its credits | `ending_keep` | 206.00 s | 《笔迹归处》, trimmed for linear playback |
| Rewrite ending and its credits | `ending_rewrite` | 220.88 s | 《白页余响》, trimmed for linear playback |

Every music-state change uses a 0.55-second crossfade. Only the menu and battle
cues loop, using a 1.50-second cyclic seam; story and ending cues remain linear.
Chapter cutscenes restore battle music when play resumes. Each selected ending
continues through its credits, and the title cue returns only after the player
leaves the credits. Both music players process during modal pause so transitions
do not stall underneath story or interface states. The saved music setting is
the single user-facing gain; no second internal attenuation may make an enabled
cue effectively inaudible beneath combat sounds.

## Cue language

- Marginalia and Twin-Stroke use a dry, broadband blade-air cut; Greatbrush uses
  a slower low-bodied stroke, Needlepoint a short narrow edge, and Seal-Caster a
  paper drag plus stamp. Weapon cues lead with shaped noise and material
  transients rather than swept oscillator tones. Edge chirp and handle/body
  resonance support the cut, but tonal beeps never become its identity.
- Every Ink Art begins with a shared wet brush draw under the character cut-in,
  then resolves with one of five authored material cues: four circular cuts,
  heavy brush-period impact, needle puncture and brake, seal stamp with twelve
  paper waves, or paired cross-cuts. Weapon identity comes from timing, impact,
  paper, bristle, and restrained metal resonance rather than electronic sweeps.
- Every Ink Art rolls one pre-generated Japanese IndexTTS 2.5 performance on a
  persistent-pause voice player. Voice zero is a short common `は！` kiai used
  for 90% of casts; the current weapon's named line is selected for the other
  10%. The common cry resolves inside the existing cut-in. Rare 2.17–2.65
  second lines continue over resumed combat instead of extending the time stop
  or being truncated. Disabling cut-ins retains the same distribution and fast
  startup. The SFX slider controls all six performances.
- Nara has three light-hit and two heavy-hit Japanese pain variants, with a
  dedicated owner-selected B death line. Fatal damage suppresses the normal hit
  bark so the last words remain clean. Masked and ink-creature enemies each use
  three quiet positional hit variants and one selected B death reaction.
  Per-family crowd cooldowns and a shorter 440-pixel attenuation range prevent
  enemy reactions from masking attacks or telegraphs. All combat performances
  process through pause, allowing Nara's last words to complete beneath the
  defeat fade.
- Enemy projectile casts, dash charges, teleport windups, parries, shields, and
  Archivist restoration are positional warnings, not decorative noise. Their
  silhouettes use paper snaps, cloth movement, hollow knocks, and restrained
  metal resonance while remaining distinct from pickup sounds.
- Ink Bomb and combat supplies use separate burst and power-up families. Pickup,
  healing, level-up, and relic cues avoid rising arpeggios: muted token contact,
  wax/paper movement, and low resonances communicate reward without sounding
  playful.
- Menu movement, confirm, cancel, and Save & Return have short non-positional
  cues that remain audible during pause. These use page flicks and dry wood
  clicks rather than UI beeps.

High-frequency combat cues have per-family millisecond cooldowns. This prevents
large squads from allocating unbounded simultaneous players while retaining the
first readable warning. Master, music, and SFX settings continue to apply to all
new cues.

## Validation

`audio_system_test.gd` verifies all 30 sound cues, six Japanese Ink Art voices
with the exact 90% common / 10% specialized selection boundary, 14 Japanese
combat-feedback voices,
all five Hai Mian stereo music
cues and their production-length floors, cyclic menu/battle versus linear
story/endings, menu/run/boss/story/ending state mapping, weapon mappings, the
shared Ink Art charge and five release cues, six enemy warning families, supply
and UI cues, persistent-pause players, cooldown coverage, and a production-mode
two-player crossfade.
