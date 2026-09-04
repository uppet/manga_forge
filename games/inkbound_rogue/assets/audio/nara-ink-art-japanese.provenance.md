# Nara Japanese Ink Art voice provenance

Status date: 2026-09-04. The project owner supplied and approved this six-file
Japanese delivery for integration into the current demo. All files are
conservatively classified as pre-generated AI audio.

## Generation record

- Service/model: locally operated IndexTTS 2.5
- Reference voice: one consistent, capable young-woman timbre across the
  Japanese and separately retained Chinese delivery
- Runtime scope in this revision: Japanese only
- Source/runtime format: 22.05 kHz mono 16-bit PCM WAV
- Mastering: de-clipped and denoised by the delivery pipeline, with peaks
  normalized to 0.89 (approximately -1 dBFS)
- Performance direction: a cool, grounded woman warrior; technique names are
  concise, their final syllables carry emphasis, and tails fade naturally
- Generation happened during development. The shipped game performs no model
  or API calls.

## Runtime selection

Every Ink Art rolls once when cast. A roll below `0.10` selects the current
weapon's specialized line; all other rolls select voice zero, the common
`は！` kiai. Thus the exact authored distribution is 10% specialized and 90%
common. The short common cry resolves during the time-stop cut-in. Specialized
lines are deliberately allowed to finish after combat resumes, so their
2.17–2.65 second deliveries neither lengthen the time stop nor get truncated.

| ID | Weapon/use | Japanese line | Runtime asset | Length | SHA-256 |
| ---: | --- | --- | --- | ---: | --- |
| 0 | Common | `は！` | `voice/nara_ink_art_kiai_jp.wav` | 0.885 s | `829b313ceea687c92e55f43c5b7e61e1438ca04cb9dc0ea3045fbd378c72bc00` |
| 1 | Marginalia | `もくじゅつ――きゅうこん、かいかん！` | `voice/nara_ink_art_marginalia_jp.wav` | 2.174 s | `6287decc0435eba9496f47e871eb3b0ee06d39118f1cd4fd45abf3ea98611777` |
| 2 | Greatbrush | `もくじゅつ――しゅうひつ、おとせ！` | `voice/nara_ink_art_greatbrush_jp.wav` | 2.423 s | `d13d9cc366b8c1c36268bfc975100493b66b54c28b29bd7651b89d718a772351` |
| 3 | Needlepoint | `もくじゅつ――せきせん、つらぬけ！` | `voice/nara_ink_art_needlepoint_jp.wav` | 2.654 s | `b5a4b9c53454ddb019442fe6e7bd6b6ab6ca0913f4776ce9e5efd1c963a31805` |
| 4 | Seal-Caster | `もくじゅつ――せんいん、しずまれ！` | `voice/nara_ink_art_seal_caster_jp.wav` | 2.283 s | `ca2ad4458a4667f43a3217adc49bc868cd289a08b47a7013a4c47bc00d3c9f41` |
| 5 | Twin-Stroke | `もくじゅつ――そうほう、かいめい！` | `voice/nara_ink_art_twin_stroke_jp.wav` | 2.431 s | `21fde3dd7f0b8088a0635373bc8cbdaba0cee04f96f146e240ed85c33280ef13` |

## Distribution gate

The owner authorized this delivery for the current demo. Before commercial
distribution, preserve the local generation/reference-voice records and verify
the IndexTTS model, dependencies, reference recording, and generated-output
rights applicable to the release. This file is an engineering inventory, not
legal advice.
