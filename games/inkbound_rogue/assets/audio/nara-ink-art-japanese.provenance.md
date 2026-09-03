# Nara Japanese Ink Art voice provenance

Status date: 2026-09-03. The project owner auditioned these five Japanese
performances and approved them for integration into the current game demo. All
five are conservatively classified as pre-generated AI audio.

## Generation record

- Service/model: OpenAI Realtime API, `gpt-realtime-2.1`
- Built-in voice: `marin`
- Character direction: Nara is a young trained woman warrior with low chest
  resonance, slight rasp, controlled danger, and no cute or announcer-like
  delivery.
- Performance direction: `墨術` is pronounced `ぼくじゅつ`; `術` is the first
  seal-breaking impact, and each final imperative syllable is an all-out strike
  with controlled vocal tearing while remaining intelligible.
- Generation happened during development. The shipped game performs no model
  or API calls.

| Weapon | Japanese line | Runtime asset |
| --- | --- | --- |
| Marginalia | `墨術――古き痕よ、巡れ！` | `voice/nara_ink_art_marginalia_jp.wav` |
| Greatbrush | `墨術――終の一筆、落ちろ！` | `voice/nara_ink_art_greatbrush_jp.wav` |
| Needlepoint | `墨術――赤き線よ、貫け！` | `voice/nara_ink_art_needlepoint_jp.wav` |
| Seal-Caster | `墨術――千の印よ、鎮め！` | `voice/nara_ink_art_seal_caster_jp.wav` |
| Twin-Stroke | `墨術――双刃、運命を斬り変えろ！` | `voice/nara_ink_art_twin_stroke_jp.wav` |

The Realtime transcript gate accepted every line. Four transcripts represented
`墨術` phonetically as `ぼくじゅつ`; this is an orthographic difference and the
required pronunciation was preserved.

## Runtime derivation

The accepted 24 kHz mono PCM sources remain in the ignored development output.
The reviewed preview masters were high-pass filtered at 65 Hz, low-pass
filtered at 18 kHz, conservatively peak-matched near -3 dBFS, and resampled to
44.1 kHz mono PCM. For runtime pacing, FFmpeg `silenceremove` capped long
dramatic pauses at 160 ms. FFmpeg `atempo=2.0` then doubled the delivery speed
without changing pitch. A final per-take gain match restores peaks to roughly
-3 dBFS. No dynamic compression, reordering, or removal of spoken words was
applied.

| Runtime asset | Length | SHA-256 |
| --- | ---: | --- |
| `nara_ink_art_marginalia_jp.wav` | 1.277 s | `a4f38e5bf64e1d58d722d07fcd98870c66b4bd6cfe86af070cacecd59bb10fe4` |
| `nara_ink_art_greatbrush_jp.wav` | 1.467 s | `dc6b1a7522ce355b08951c6a7e1b78136280aa8feb5c019e5564a79dfdef5c77` |
| `nara_ink_art_needlepoint_jp.wav` | 1.289 s | `f046dbdb69cefca9a27e7508207cd660c57572460b9bf87183ea6a212265ef24` |
| `nara_ink_art_seal_caster_jp.wav` | 1.379 s | `8fee53abb5e60c62a8c4deb315eec0c4e84d45669d15f6aebc90476e803ce075` |
| `nara_ink_art_twin_stroke_jp.wav` | 1.440 s | `afbec3df8fb96da85dbb9479201a8a36fa642cc7f48c99e5a0fc15a9689d0354` |

## Distribution gate

The owner authorized the performances for the current demo. Before commercial
distribution, preserve the originating OpenAI account/billing record and
confirm that the applicable OpenAI terms cover distribution of generated voice
assets. This file is an engineering inventory, not legal advice.
