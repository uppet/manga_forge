# Free Beta candidate readiness — 0.25.0-beta.1

Snapshot date: 2026-09-06. This is the automated development baseline for a
planned no-cost public Windows Beta distributed through itch.io and a Quark
Drive mirror. `P1` remains the internal test-suite and evidence-directory name.
This is not evidence of Steam release quality or of player enjoyment,
accessibility, minimum hardware, or controller coverage.

## Automated candidate evidence

| Check | Result |
| --- | --- |
| Engine migration | Pass: Windows host and project are pinned to Godot 4.5.2 stable; the official Windows debug/release templates are installed, 70 generated script UID companions are versioned, and the renderer remains GL Compatibility |
| Serial regression | Pass on Godot 4.5.2: 32/32 gameplay, save, pause, quit, defeat, UI, localization, balance, persona, recorder, analytics, privacy-consent, debug-state, combat-presentation, and stress gates |
| Modal transitions | Pass: upgrade drafts retain their 0.24-second/0.18-second elastic transitions and 1.016× opening/closing overshoot; relic, event, pause, manual, settings, binding, title-overlay, and credits panels use 0.16-second fade-ins and 0.12-second fade-outs. Defeat uses a 1.25-second battlefield darkening before the result panel, then a 1.50-second input guard plus release-before-repress protection |
| Modal input handoff | Pass: held movement resumes immediately after a choice; only overlapping attack/dash/special actions are gated until release, with a 0.75-second lost-release fail-safe and focus/controller reset |
| Choice and combat presentation | Pass: 36 upgrades and 12 unique relics have illustrated, gamepad-readable cards; enemy melee/ranged attacks traverse anticipate/coil/strike/recover keyframes with hitbox-matched FX; all three bosses use unique localized 480×170 modal cut-ins that pause play and isolate HUD/story input |
| Reproduction startup state | Pass: schema-validated external JSON can restore Page 1–12, level/XP/health, run rules, fixed/random build, boss, and enemy fixtures; malformed/conflicting recipes fail closed; debug runs visibly disable save/checkpoint and GameAnalytics writes. The real exported EXE and double-click CMD both passed on Windows |
| Brand and localization | Pass: public identity is `Last Inkwarden / 墨卫残章`; English and Chinese title captures are contained, and the former profile directory is copied forward without overwriting new data or deleting old data |
| Evidence directory | `build/p1-suite/20260906T041537Z/` in the Windows runtime; compact summary plus one log per gate |
| Recorded stress run | Pass on Godot 4.5.2: 1,200 frames, 140.9 processing FPS average, 77 peak enemies, 44 peak pickups, 815 peak nodes, 198.8 MiB static memory, Page 13, 217 kills |
| Unrecorded suite stress run | Pass on Godot 4.5.2: 1,200 frames, 142.4 processing FPS average, 76 peak enemies, 51 peak pickups, 810 peak nodes, 198.7 MiB static memory, Page 13, 226 kills |
| Windows export boot | Pass: the account owner exported a credential-bearing Godot 4.5.2 embedded-PCK `0.25.0-beta.1` EXE; the exact executable ran 120 GL Compatibility frames on Radeon RX 9070 XT and reported `analytics_embedded=true`, `analytics_profile=public_beta`. Runtime source credentials were scrubbed immediately afterward |
| Recorded CMD launcher | Pass on the preceding internal candidate: the consent-capable launcher started the real EXE, wrote a complete pseudonymous session, removed `incomplete.flag`, and left zero processes |
| Source release audit | Pass after the Godot 4.5/version/privacy-allowlist migration: 113 assets; 64 procedural, 49 pre-generated AI, zero live AI; isolated Steam depot has four allowlisted files and the itch staging bundle has five. The final public-Beta ZIP still requires a fresh export because the preceding export stopped before archive creation on the now-corrected audit |
| Analytics consent/privacy | Pass: clean profiles receive a separate first-run allow/deny choice defaulting to deny; title/settings controls are isolated behind the modal; the Data & Privacy page exposes direct mouse/keyboard/controller allow/deny controls; withdrawal clears local state; bilingual in-game and packaged notices are present |
| Analytics event contract | Pass: exactly 12 allowlisted low-frequency game semantics, content-backed IDs with `other` fallback, no frame/input/attack/bullet/damage/kill/pickup stream, and an aggregated run-final summary |
| Public candidate executable | Pending final packaging. The current credential-bearing `build/windows/LastInkwarden.exe` passed its boot check, but a bare EXE is not the upload artifact; rerun the owner-controlled export to create and audit the complete ZIP |
| Distribution decision | The build gate now requires `profile=public_beta` and project label `Last Inkwarden - Public Beta`, and rejects reused development/release credentials. The account owner must still verify that the local key actually belongs to that dashboard project before producing a credential-bearing candidate |
| Process hygiene | Pass: zero Godot or exported-game processes after the serial suite |

The recorded and unrecorded stress figures are development-machine processing
rates from accelerated automation, not rendered player FPS or a hardware
minimum-spec claim.

## Public Beta feedback procedure

1. Export one audited `build/itch-windows/` candidate and publish the identical
   ZIP through itch.io and the Quark Drive mirror. Record its version and
   SHA-256 beside both links.
2. Players may launch `LastInkwarden.exe` normally. Local recording is optional
   and begins only through `Start-Recorded-Playtest.cmd` after explicit consent.
   It stores semantic game events, coarse performance samples, deliberate
   F6–F9 markers, optional game screenshots, and the exit survey. It does not
   store raw key/button streams, microphone, camera, or account data, and it
   does not upload the resulting files.
3. Ask public testers to report build version, Windows version, GPU/controller,
   input method, furthest page, expected behavior, and observed behavior. A
   pseudonymous recorded-session folder may be shared only when the player
   chooses to do so.
4. Treat itch.io comments, feedback-form entries, locally shared recorder data,
   and opt-in GameAnalytics as separate evidence sources. Never infer consent
   for one channel from use of another.
5. Maintainers can reproduce a local facilitated session with
   `python3 tools/windows/host_game.py playtest --participant P-001`, then run
   `playtest-report`. Do not treat aggregate ratings as statistically
   representative without reviewing individual failures and device context.

Local sessions live under `build/playtest/sessions/`; aggregate JSON and
Markdown reports live under `build/playtest/reports/`. Both locations are
excluded from Git and the Steam depot.

## Human evidence to collect during the public Beta

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
