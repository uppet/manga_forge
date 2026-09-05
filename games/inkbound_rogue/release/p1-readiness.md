# P1 candidate readiness — 0.24.0-alpha

Snapshot date: 2026-09-05. This is the automated development baseline for a
small, private Windows playtest. It is not evidence of Steam release quality or
of player enjoyment, accessibility, minimum hardware, or controller coverage.

## Automated candidate evidence

| Check | Result |
| --- | --- |
| Serial regression | Pass: 30/30 gameplay, save, pause, quit, defeat, UI, localization, balance, persona, recorder, analytics, combat-presentation, and stress gates |
| Modal transitions | Pass: upgrade drafts retain their 0.24-second/0.18-second elastic transitions and 1.016× opening/closing overshoot; relic, event, pause, manual, settings, binding, title-overlay, and credits panels use 0.16-second fade-ins and 0.12-second fade-outs. Defeat uses a 1.25-second battlefield darkening before the result panel, then a 1.50-second input guard plus release-before-repress protection |
| Modal input handoff | Pass: held movement resumes immediately after a choice; only overlapping attack/dash/special actions are gated until release, with a 0.75-second lost-release fail-safe and focus/controller reset |
| Choice and combat presentation | Pass: 36 upgrades and 12 unique relics have illustrated, gamepad-readable cards; enemy melee/ranged attacks traverse anticipate/coil/strike/recover keyframes with hitbox-matched FX; all three bosses use unique localized 480×170 modal cut-ins that pause play and isolate HUD/story input |
| Brand and localization | Pass: public identity is `Last Inkwarden / 墨卫残章`; English and Chinese title captures are contained, and the former profile directory is copied forward without overwriting new data or deleting old data |
| Evidence directory | `build/p1-suite/20260905T043921Z/` in the Windows runtime; compact summary plus one log per gate |
| Recorded stress run | Pass: 1,200 frames, 143.5 processing FPS average, 77 peak enemies, 50 peak pickups, 795 peak nodes, 184.5 MiB static memory, Page 13, 246 kills |
| Unrecorded suite stress run | Pass: 1,200 frames, 143.9 processing FPS average, 77 peak enemies, 35 peak pickups, 770 peak nodes, 184.3 MiB static memory, Page 13, 225 kills |
| Windows export boot | Pass: embedded-PCK executable ran 120 frames with GL Compatibility on Radeon RX 9070 XT and exited normally |
| Recorded CMD launcher | Pass: consent-capable launcher started the real EXE, wrote a complete pseudonymous session, removed `incomplete.flag`, and left zero processes |
| Release/depot audit | Pass: 113 assets; 64 procedural, 49 pre-generated AI, zero live AI; exactly 3 Steam depot files (127,037,167 bytes) and 4 itch.io recorded-playtest files (127,040,530 bytes) |
| Candidate executable | `build/itch-windows/LastInkwarden.exe`; audited SHA-256 `528c143c1aca3f7feed64b921e1857080594290ffccc6edb37d92218402acd81` |
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
