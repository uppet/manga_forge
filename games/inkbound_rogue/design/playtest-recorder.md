# Local playtest recorder

## Purpose

The recorder turns a small Windows playtest into evidence without adding an
account system, analytics vendor, network dependency, or Steam requirement. It
answers four practical questions: where a run ended, what immediately preceded
a reported problem, whether the build held frame rate under load, and how the
player rated controls, readability, fairness, build clarity, sound, and music
fatigue.

This is diagnostic evidence, not a substitute for watching a player. A marker
says *where* to investigate; the facilitator should still ask the player what
they expected and avoid teaching the solution during first-use observation.

## Privacy boundary

- Give each participant a facilitator-assigned code such as `P-001`. Do not use
  names, email addresses, platform account IDs, or other identifying labels.
- The recorder captures gameplay events, run state, aggregate performance,
  controller model names, locale, display size, and screenshots only when the
  participant deliberately marks a moment.
- It does not capture account details, key-by-key text input, microphone, camera,
  desktop video, or windows outside the game. The only free text is the optional
  280-character exit-survey note the participant chooses to submit.
- Files stay in the local Windows runtime. There is no upload implementation.
  Obtain consent before copying a session folder to another device or sharing a
  marked screenshot.
- Review survey notes and screenshots before distributing a report. Delete a
  participant's session directory if they withdraw consent.

## Facilitator workflow

From the Manga Forge repository in WSL:

```bash
python3 tools/windows/host_game.py process-status
python3 tools/windows/host_game.py playtest --participant P-001
```

`playtest` refuses to proceed while `InkboundRogue.exe` is already running,
syncs and exports the current source, then launches exactly that executable with
an anonymous build/session identity. For repeated sessions on the identical
export, use `--reuse-build`; do not use it after source, assets, or version data
changes.

Tell the participant only the four optional marker keys:

- `F6`: bug or broken behavior
- `F7`: confusing rule, prompt, or visual
- `F8`: unfair or unreadable damage
- `F9`: especially satisfying moment

Each mark records a state snapshot, up to 30 seconds / 80 events of preceding
context, and one in-game screenshot. Normal play is never paused by a mark.
Defeat and victory show a bilingual exit card. Sliders and buttons are keyboard,
mouse, and controller-focusable; typing a note remains optional.

After the player closes the game:

```bash
python3 tools/windows/host_game.py process-status
python3 tools/windows/host_game.py playtest-report
```

An `incomplete.flag` means the process did not finish its shutdown path. Keep
the remaining JSONL as crash evidence, but do not count that session as a normal
completion.

## Artifact layout

The runtime path is `games/inkbound_rogue/build/playtest/`:

```text
sessions/<session-id>/
  session.json          build, platform, locale, controller, privacy notice
  events.jsonl          timestamped gameplay decisions and combat outcomes
  performance.jsonl     one-second performance and scene-load samples
  markers.jsonl         categorized moments with recent event context
  screenshots/          only deliberate moment captures
  survey.json           optional exit ratings and note
  summary.json          compact normal-exit summary
  incomplete.flag       present only until a clean recorder shutdown
reports/
  playtest-report.json
  playtest-report.md
```

JSONL streams flush at least once per second, at 24 queued events, and on fatal
damage, markers, or session boundaries. This bounds crash loss while avoiding a
disk flush for every slash.

## P1 review order

Review individual marked screenshots and their context first; aggregate scores
can hide a severe single-player failure. Then compare fatal damage sources,
furthest page, starting weapon, input mode, incomplete sessions, and survey
ratings. Treat `music_fatigue` as a problem score: a higher number means more
fatigue, unlike the other five ratings.

Before inviting external players, the P1 gate is:

1. `playtest-recorder-test` passes on the Windows host.
2. One internal exported-build session produces a screenshot marker, survey,
   complete summary, and aggregate report.
3. The gameplay soak, persona, save, pause, controller, localization, audio, and
   visual-layout gates pass for the same commit.
4. Every participant is told what is recorded and is assigned a non-identifying
   code.
