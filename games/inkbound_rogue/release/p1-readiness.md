# P1 candidate readiness — 0.23.2-alpha

Snapshot date: 2026-09-02. This is the automated development baseline for a
small, private Windows playtest. It is not evidence of Steam release quality or
of player enjoyment, accessibility, minimum hardware, or controller coverage.

## Automated candidate evidence

| Check | Result |
| --- | --- |
| Serial regression | Pass: 26/26 gameplay, save, pause, UI, localization, balance, persona, recorder, and stress gates |
| Evidence directory | `build/p1-suite/20260901T162501Z/` in the Windows runtime; compact summary plus one log per gate |
| Recorded stress run | Pass: 1,200 frames, 141.1 processing FPS average, 74 peak enemies, 58 peak pickups, 784 peak nodes, 120.3 MiB static memory, Page 13, 223 kills |
| Unrecorded suite stress run | Pass: 1,200 frames, 141.0 processing FPS average, 76 peak enemies, 61 peak pickups, 768 peak nodes, 120.0 MiB static memory, Page 13, 238 kills |
| Windows export boot | Pass: embedded-PCK executable ran 120 frames with GL Compatibility on Radeon RX 9070 XT and exited normally |
| Recorded CMD launcher | Pass: consent-capable launcher started the real EXE, wrote a complete pseudonymous session, removed `incomplete.flag`, and left zero processes |
| Release/depot audit | Pass: 73 assets; 59 procedural, 14 pre-generated AI, zero live AI; exactly 3 Steam depot files (111,333,225 bytes) and 4 itch.io recorded-playtest files (111,336,590 bytes) |
| Candidate executable | `build/itch-windows/InkboundRogue.exe`; audited SHA-256 `0d27ded951304eeede3dc270d95b93be43dac2a22045db2206bb7075b13f2d50` |
| Process hygiene | Pass: zero Godot or exported-game processes after the serial suite |

The recorded and unrecorded stress figures are development-machine processing
rates from accelerated automation, not rendered player FPS or a hardware
minimum-spec claim.

## P1 session procedure

1. Run `python3 tools/windows/host_game.py playtest --participant P-001` from
   the repository. Use a facilitator-assigned pseudonymous code, never a name or
   email address.
2. Tell the player that recording is local and opt-in. It stores semantic game
   events, coarse performance samples, facilitator/player markers, optional
   game screenshots, and the exit survey. It does not store raw key/button
   streams, microphone, camera, account data, or network telemetry.
3. During play, use `F6` for a bug, `F7` for confusion, `F8` for unfairness, and
   `F9` for a highlight. Each marker retains the preceding 30-second semantic
   event context and may save a game-only screenshot.
4. Let the player complete the bilingual exit survey and close normally. An
   interrupted session keeps `incomplete.flag` so it cannot silently count as a
   clean completion.
5. Run `python3 tools/windows/host_game.py playtest-report`. Attach the session
   ID and hardware summary to observations, then record concrete follow-up work
   without treating the numeric ratings as statistically representative.

Local sessions live under `build/playtest/sessions/`; aggregate JSON and
Markdown reports live under `build/playtest/reports/`. Both locations are
excluded from Git and the Steam depot.

## Required human evidence before expanding beyond P1

- At least five fresh players spanning action-roguelike familiarity, including
  Chinese-language and controller-first players; observe onboarding without
  coaching before asking follow-up questions.
- A complete run, an early defeat, Save & Return / Continue, New Game
  confirmation, Story Archive replay, controller disconnect/reconnect, and
  background-focus pause across the session set.
- One Windows 10 integrated/older-GPU pass at the provisional floor; one
  keyboard-only pass; physical Xbox-layout, PlayStation-layout, and Switch Pro
  compatible controller passes. Record failures as failures, not blank cells.
- Review marker clusters, death/page distributions, selected builds, recovery
  pressure, survey comments, and performance outliers together. Do not tune the
  game from aggregate scores alone.
- Publisher review or replacement of every pre-generated AI asset whose exact
  historical prompt is unavailable, followed by the appropriate Steam content
  disclosure before any commercial submission.

The detailed hardware rows are maintained in `p1-compatibility-matrix.md`; the
facilitator script and privacy/data schema are in
`../design/playtest-recorder.md`.
