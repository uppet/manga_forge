# Automated player personas

The player-persona gate complements formula balance and stress tests with
behavior. It drives the existing Godot combat nodes rather than substituting a
separate damage spreadsheet.

| Persona | Behavior under test |
| --- | --- |
| First-timer | Slow reactions, loose aim, inconsistent targets, hesitant attacks, rare dodges, mixed defensive build |
| Blade rusher | Close engagement, high attack commitment, moderate dodging, aggressive combo build |
| Margin kiter | Edge-of-reach spacing, frequent retreat/strafe, strong dodging, wave-oriented build |
| Speedreader | Fast target updates, precise aim, deliberate Ink Art use, high dodge timing, active-skill synergy |

Each persona faces representative Page 1, ranged Page 3, Page 6, and Page 12
encounters on Story, Standard, and Redline. The same persona seed is reused
across difficulty settings. Test-only explicit position integration and stable
spawn ordering make repeated reports byte-identical while production movement
continues to use normal Godot collision. The test
records survival, remaining health, encounter clear ratio, damage dealt/taken,
DPS, attacks, dashes, Ink Arts, threat time, movement time, and early-to-late
upgrade growth in `build/playtest/player-persona-report.json`.

The gate catches broken combat participation and invalid measurements. It also
requires at least 90% Standard survival, 75% late-stage survival, 58%
first-timer clear, 83% blade-rusher survival, a non-trivial Standard ceiling,
and strictly descending Story → Standard → Redline clear ratios. It emits broad
diagnostic observations instead of automatically changing balance.
It cannot judge controller latency, animation readability, accessibility,
fatigue, emotional pacing, or enjoyment; those still require human sessions.
