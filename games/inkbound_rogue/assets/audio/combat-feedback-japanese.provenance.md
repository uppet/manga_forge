# Japanese combat feedback voice provenance

Status date: 2026-09-04. The project owner auditioned the complete A/B preview
set and selected **B** for all fatal performances. Non-fatal hit variations are
rotated at runtime. These 14 files are conservatively classified as
pre-generated AI audio.

## Generation record

- Service/model: OpenAI Realtime API, `gpt-realtime-2.1`
- Nara voice: `marin`, matching her existing Japanese Ink Art performances
- Masked-enemy voice: `ash`
- Ink-creature voice: `echo`
- Source: 24 kHz mono PCM generated during development; the shipped game makes
  no model or API calls
- Direction: terse, dark and physically grounded; enemy feedback remains below
  the player, weapon and telegraph hierarchy and never reads as comic relief

The accepted dialogue/vocalizations were Nara light `くっ！`, Nara heavy
`ぐっ……！`, Nara fatal `姉さん……ごめん……`, masked hit `ぐっ！`, masked fatal
`ぐあっ……！`, ink hit `ギィッ！`, and ink fatal `ギァァ……！`. Generation
metadata and rejected takes remain in the ignored local audition workspace.

## Runtime selection and derivation

All accepted preview masters were high-pass filtered, conservatively
peak-matched by role, trimmed for combat timing, and resampled to 44.1 kHz mono
PCM. The approved B deaths are the only fatal takes shipped. Player light/heavy
and enemy hit pools retain all approved variations. Runtime cooldowns prevent
enemy crowds from stacking voices into an unreadable wall, while 2D attenuation
keeps distant enemy reactions subordinate.

| Runtime asset | Length | SHA-256 |
| --- | ---: | --- |
| `voice/combat/nara_hit_light_01.wav` | 0.134 s | `639ff8e3ea6d8f2c241771f125d0c91dde4cfe9defd838adce4d18f9e712b1c9` |
| `voice/combat/nara_hit_light_02.wav` | 0.191 s | `122d1f780a150059472757780813146184e5343c0b1bf1a01ea5090ce51de7ce` |
| `voice/combat/nara_hit_light_03.wav` | 0.177 s | `d40142d7470f7cfca757580233cca014fce1f44d8b38a19da09dce378d814a88` |
| `voice/combat/nara_hit_heavy_01.wav` | 1.074 s | `b71467e695cb1fbb9ab22fbb88870b9531e5f9fdfc4c9685b9c0e1fbb0d53165` |
| `voice/combat/nara_hit_heavy_02.wav` | 0.172 s | `3543f1beb9a579f6c9ebaf79b925af89b7f3beb9673990b0e1d27e214b425f07` |
| `voice/combat/nara_death_b_jp.wav` | 2.839 s | `8a90bea9d6b590502b6ff28409dde7d461b86905ab26348ac1bf4ba147aa95ce` |
| `voice/combat/enemy_mask_hit_01.wav` | 0.358 s | `7a30b63b6c94ad1095d827a1e82dc4c5b377af315de4268b052634f44f32091a` |
| `voice/combat/enemy_mask_hit_02.wav` | 0.221 s | `7589a29965656915ef3e1e4bb509d71ba3cb9e36bc93b2c844814310c9caceee` |
| `voice/combat/enemy_mask_hit_03.wav` | 0.220 s | `18650e7f6aa1187e5dfac963d03c9bbdc19d773a7c6c4fe885b45b81a45a086b` |
| `voice/combat/enemy_mask_death_b.wav` | 1.369 s | `000a16e55af731e69fb001c8331e4d62ab76a71983b6b50a3cc6267bf0b05b6a` |
| `voice/combat/enemy_ink_hit_01.wav` | 0.469 s | `00b1c2bc7cae30303a9a4356cefcd5cd00c09302fd6fccc8d4abf9b315b70641` |
| `voice/combat/enemy_ink_hit_02.wav` | 0.323 s | `83b28e56c971612bd8e8e5b4a963808447e1ee4e843b7f83d4c19f2d8c38bd3a` |
| `voice/combat/enemy_ink_hit_03.wav` | 0.225 s | `25b4790c8935c598222ce78e086db390ad486e85cd26e9763caa710dadb3e9bc` |
| `voice/combat/enemy_ink_death_b.wav` | 0.927 s | `a94ca8f2c92b9951511bb7f035293c2c94296199775d522ea7c07c83304c4038` |

## Distribution gate

The owner authorized the B selection for the current demo. Before commercial
distribution, preserve the originating OpenAI account/billing record and
confirm the applicable OpenAI terms cover distribution of generated voice
assets. This is an engineering inventory, not legal advice.
