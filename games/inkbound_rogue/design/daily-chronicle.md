# Daily Chronicle

Daily Chronicle is a deterministic local-date challenge that gives repeat
players one comparable draft without requiring a server or online account.

## Rules

- The local date uses `YYYY-MM-DD`; a stable 31-bit hash becomes the run seed.
- All six contracts rotate by date. Difficulty is Standard, the starting blade
  is Marginalia, Proof is 0, and all thirty Restoration ranks are sealed.
- Routes, events, squads, upgrades, relics, combat drops, and battlefield
  hazards still use the normal systems, but their RNG begins from the shared
  date seed.
- Continue / Load stores the Daily identity and exact game and hazard RNG states.
- The first clear of each date grants 12 bonus Memory. Replays can improve the
  score but cannot claim that bonus twice.
- Attempts, wins, best score, current consecutive-date streak, best streak, and
  lifetime clears persist. Records are pruned to the newest 64 dates.

The feature is deliberately offline. Calendar changes affect which new Daily is
offered, but never mutate an existing checkpoint or an archived result.

## Interaction and validation

Open from the title with `T`, D-pad down, or the visible Daily button. Enter or
A/Cross begins; Escape, Start, B/Circle, or the Daily shortcut closes the panel.
Starting a Daily replaces an existing current-draft save through the same
explicit title flow used by New Game.

`daily_chronicle_test.gd` verifies seed stability and date variance, input,
sealed meta stats, deterministic content order, exact checkpoint RNG, one-time
reward, streak break/recovery, both achievements, schema-12 persistence, and
schema-11 migration. `capture_daily_chronicle.gd` checks the real Windows
renderer for contained copy and captures the title and modal.
