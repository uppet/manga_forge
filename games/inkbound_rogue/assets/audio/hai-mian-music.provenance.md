# Hai Mian Music soundtrack provenance

Status date: 2026-09-02. The project owner generated and supplied these five
tracks from 海绵音乐 (Hai Mian Music) and approved their use in the current
demo. The supplied files carry AI/AIGC fingerprints, so all five runtime cues
are conservatively classified as pre-generated AI audio.

## Source records

| Runtime cue | Hai Mian source | Source SHA-256 | Embedded AIGC identifier |
| --- | --- | --- | --- |
| Menu | `《墨色残响》JoyerHuang_悦-流行.mp3` | `e744bceb562e19be0cd29f30aee1d60dd44d1bda4551708b1907135400a909cb` | ProduceID `v03c0bg10001dabfcq27dld4mcsj3jo0` |
| Battle and bosses | `《墨战交响》JoyerHuang_悦-流行.mp3` | `d3cd786eca96d4cc8ff51f18c6b5fc0af176d466ba0912cfe3d5ec021d12b8ea` | ProduceID `v03c0bg10001dabfdti7dldbgfoo4rv0` |
| Story cutscenes | `《墨痕残忆》JoyerHuang_悦.mp3` | `fa7221dc4d7e20047a4685f133b7bd0f5e960b10095a79ff05af51db19347de6` | ProduceID `v02c0bg10001dabfehq7dldc8loeq7lg` |
| Keep ending and credits | `《笔迹归处》JoyerHuang_悦-流行.m4a` | `6e53d1053a66bec96941383db76ca68f43c53999755732f8b953281f6977efb0` | AI fingerprint reported by owner; the M4A custom field was not exposed by FFprobe 4.4.2 |
| Rewrite ending and credits | `《白页余响》JoyerHuang_悦-流行.mp3` | `07c0171227a9f244450b6c4177d06aa4f06f659432f445f165d5998a4d987671` | ProduceID `v0dc0bg10001dabfgiq7dld0r23si1ug` |

The four MP3 sources are 44.1 kHz stereo at approximately 256 kbit/s; the M4A
is 44.1 kHz stereo AAC at approximately 128 kbit/s. Measured source integrated
loudness is -16.4, -16.0, -16.0, -17.2, and -16.9 LUFS respectively in the
table's order. The Chinese music briefs for menu, battle, story, and the two
ending variants are retained in the project conversation. Exact generation
job settings, account plan, download receipt, and a dated terms snapshot are
not committed.

The untouched supplied files are backed up outside the Git/depot payload at
`S:\bld\manga-forge-runtime\games\inkbound_rogue\build\source-audio\hai-mian-music\`.

## Runtime derivation

The committed Ogg Vorbis files were produced with FFmpeg 4.4.2 at quality 6.
No generative model, composition, or creative remix was applied during runtime
processing, and no loudness normalization was applied.

| Runtime asset | Processing | Length | Runtime SHA-256 |
| --- | --- | ---: | --- |
| `music_menu_hai_mian.ogg` | Trim source to 0.000-108.380 s; 1.500 s cyclic tail/head crossfade | 106.880 s | `5c18665a0d1b2f5e125a20786530f2fb85dbbc31295ed846679d6a96f97855fc` |
| `music_battle_hai_mian.ogg` | Trim source to 1.700-113.980 s; 1.500 s cyclic tail/head crossfade | 110.780 s | `ce885f2b823844c1756a9fb04c76064f9097c64a6c4985122332c8ced0aaf1ec` |
| `music_story_hai_mian.ogg` | Trim source to 0.380-129.000 s; linear playback | 128.620 s | `a086f129c6e5050eb3ecea6e6d9e02b6192b8ed867fc68baa3fcb9d0c70ebf62` |
| `music_ending_keep_hai_mian.ogg` | Trim source to 0.000-206.000 s; linear playback | 206.000 s | `9bf0b605afa96d6c29f5a651ea320dc2bed4084280985837fd810cb33554c1f1` |
| `music_ending_rewrite_hai_mian.ogg` | Trim source to 0.720-221.600 s; linear playback | 220.880 s | `71032638cd36af2363a1aca1a2e8dea5370aedc57e6c39399d88e6629018ff7e` |

Only menu and battle are cyclic loops. Story and both endings play linearly;
each ending cue continues into its credits sequence. Runtime changes between
music states use the game's 0.55-second two-player crossfade.

## Distribution gate

The project owner authorized these tracks for the current demo. Before a paid
or otherwise commercial public release, preserve the 海绵音乐 account/plan and
generation/download records, capture the terms that applied at generation,
and confirm that those terms cover game distribution. Replace or regenerate
the tracks if that review is inconclusive. This record is an engineering
inventory, not legal advice.
