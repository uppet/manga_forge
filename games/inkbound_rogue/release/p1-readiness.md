# P1 candidate readiness — 0.23.3-alpha

Snapshot date: 2026-09-02. This is the automated development baseline for a
small, private Windows playtest. It is not evidence of Steam release quality or
of player enjoyment, accessibility, minimum hardware, or controller coverage.

## Automated candidate evidence

| Check | Result |
| --- | --- |
| Serial regression | Pass: 26/26 gameplay, save, pause, UI, localization, balance, persona, recorder, and stress gates |
| Modal transitions | Pass: upgrade drafts retain their 0.24-second/0.18-second elastic transitions and 1.016× opening/closing overshoot; relic, event, pause, manual, settings, binding, title-overlay, game-over, and credits panels use 0.16-second fade-ins and 0.12-second fade-outs. Input stays locked and gameplay stays paused until closing callbacks complete |
| Modal input handoff | Pass: held movement resumes immediately after a choice; only overlapping attack/dash/special actions are gated until release, with a 0.75-second lost-release fail-safe and focus/controller reset |
| Evidence directory | `build/p1-suite/20260902T011355Z/` in the Windows runtime; compact summary plus one log per gate |
| Recorded stress run | Pass: 1,200 frames, 139.2 processing FPS average, 78 peak enemies, 52 peak pickups, 747 peak nodes, 120.8 MiB static memory, Page 13, 252 kills |
| Unrecorded suite stress run | Pass: 1,200 frames, 141.6 processing FPS average, 75 peak enemies, 47 peak pickups, 735 peak nodes, 120.8 MiB static memory, Page 13, 231 kills |
| Windows export boot | Pass: embedded-PCK executable ran 120 frames with GL Compatibility on Radeon RX 9070 XT and exited normally |
| Recorded CMD launcher | Pass: consent-capable launcher started the real EXE, wrote a complete pseudonymous session, removed `incomplete.flag`, and left zero processes |
| Release/depot audit | Pass: 73 assets; 59 procedural, 14 pre-generated AI, zero live AI; exactly 3 Steam depot files (111,347,049 bytes) and 4 itch.io recorded-playtest files (111,350,414 bytes) |
| Candidate executable | `build/itch-windows/InkboundRogue.exe`; audited SHA-256 `48099a77ab3e6fa1e4754a3f06b2c0be52815e8cbfe69c4053361e454c7a6ac3` |
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
