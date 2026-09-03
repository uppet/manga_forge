# Nara Ink Art — Japanese OpenAI Realtime audition v1

These are AI-generated Japanese voice auditions for Nara's five Ink Art
finishers. They are preview assets only and are not connected to the game
runtime. Human review is required before integration.

## Generation

- Model: `gpt-realtime-2.1`
- Voice: `marin`
- Source format: 24 kHz mono PCM WAV
- Character direction: the same young trained woman warrior used in the
  Chinese audition; low chest resonance, slightly raspy, controlled and
  dangerous rather than cute or announcer-like
- Performance direction: `術` / `じゅつ` is the first seal-breaking impact;
  the final imperative syllable lands on the physical hit
- Text gate: every accepted take passed its expected Japanese transcript

## Lines and audition order

1. MARGINALIA — `墨術――古き痕よ、巡れ！`
   - Reading: `ぼくじゅつ――ふるきあとよ、めぐれ！`
   - Chinese meaning: `墨术——旧痕，回环！`
2. GREATBRUSH — `墨術――終の一筆、落ちろ！`
   - Reading: `ぼくじゅつ――ついのひとふで、おちろ！`
   - Chinese meaning: `墨术——终笔，落！`
3. NEEDLEPOINT — `墨術――赤き線よ、貫け！`
   - Reading: `ぼくじゅつ――あかきせんよ、つらぬけ！`
   - Chinese meaning: `墨术——赤线，贯！`
4. SEAL-CASTER — `墨術――千の印よ、鎮め！`
   - Reading: `ぼくじゅつ――せんのしるしよ、しずめ！`
   - Chinese meaning: `墨术——千印，镇！`
5. TWIN-STROKE — `墨術――双刃、運命を斬り変えろ！`
   - Reading: `ぼくじゅつ――そうじん、うんめいをきりかえろ！`
   - Chinese meaning: `墨术——双锋，改命！`

The transcript service represented `墨術` as the phonetic `ぼくじゅつ` in
four takes. This is an orthographic difference only; the required pronunciation
was preserved and those gates used the phonetic spelling.

Listen to `realtime_japanese_raw_comparison.wav` first. It concatenates all
five original takes in the order above with 0.6 seconds between them.

`realtime_japanese_game_preview_comparison.wav` contains light delivery
processing: a 65 Hz high-pass, an 18 kHz low-pass, conservative peak matching
around -3 dBFS, and resampling to 44.1 kHz mono. No compressor is used, so the
performance dynamics remain intact. Individual originals and processed files
are in `raw/` and `game_preview/`.

No API key or other credential is stored in this directory.
