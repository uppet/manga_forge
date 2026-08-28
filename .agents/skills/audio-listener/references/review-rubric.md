# Audio Review Rubric

Use this rubric for model-assisted listening. Technical measurements can support a
finding, but they cannot establish naturalness, emotion, acting quality, or scene fit.

## Score anchors

| Score | Meaning |
| --- | --- |
| 0-2 | Unusable. The intended content fails or severe artifacts dominate. |
| 3-4 | Weak. Major reconstruction or rerecording is required. |
| 5-6 | Functional. The idea is legible but conspicuous changes are still needed. |
| 7-8 | Strong. Convincing and close to release quality, with limited refinements. |
| 9 | Exceptional, polished, and confidently release-ready. |
| 10 | Reference-grade for the exact brief. Use rarely and only with unusually strong evidence. |

Do not compress every result into 7 or 8. A numeric score without timestamped audible
evidence is invalid.

## Core dimensions

- **Content accuracy**: required words, events, order, and duration are present.
- **Naturalness**: voices, breaths, laughs, movement, instruments, and ambience behave
  plausibly rather than mechanically or as disconnected samples.
- **Performance and emotion**: delivery has believable intent, variation, reaction,
  timing, and interpersonal responsiveness.
- **Intelligibility**: important dialogue or cues remain understandable without strain.
- **Artifact control**: no obvious synthesis warble, phasing, clicks, clipped attacks,
  abrupt tails, time-stretching, loop seams, or unnatural repetition.
- **Timing and scene fit**: pacing, entrances, exits, intensity, and emotional arc serve
  the supplied brief.
- **Production and mix**: balance, masking, dynamics, frequency distribution, stereo
  image, depth, ambience, and transitions form a coherent asset.
- **Overall readiness**: the asset can ship for its intended use, not merely be decoded.

## Focus dimensions

### Voice and laughter

Score pronunciation, prosody, timbre continuity, breath behavior, emotional credibility,
laugh onset and decay, variation between people, overlap behavior, distance consistency,
and whether vocalizations sound performed rather than spelled or synthesized. For a
group laugh, identify whether each apparent person has a distinct register, rhythm, and
spatial position. Penalize identical timing, copy-like repetitions, sudden speaker
morphing, and laughter that resembles spoken syllables.

### Music

Score motif and identity, harmony, rhythm and groove, arrangement, dynamics, transitions,
emotional arc, production, scene fit, and loopability when relevant. Do not reward genre
labels alone. Listen for a deliberate musical argument and for space left for gameplay or
dialogue.

### Sound effects

Score recognizability, transient shape, body, tail, material impression, variation,
layer coherence, scale, responsiveness, and mix compatibility. Flag effects that sound
like a generic library composite when the brief calls for a specific object or action.

### Final mix

Score hierarchy, dialogue intelligibility, masking, spectral crowding, loudness and
dynamics, clipping, stereo or spatial placement, depth, ambience continuity, and
transition cleanliness. Distinguish a source problem from a balance problem when the
evidence permits; otherwise state the uncertainty.

## Required report behavior

1. Describe only events actually audible in the selected file.
2. Give timestamps for transcript segments, strengths, and defects.
3. Mark uncertain words, speakers, or sources instead of guessing.
4. Use at most three top issues, ordered by impact. Each issue needs a concrete revision.
5. End with exactly one verdict:
   - `usable_as_is`
   - `usable_after_changes`
   - `needs_rebuild`
6. State that the listening was model-assisted and name the model if the current
   conversation model did not directly consume the audio.
