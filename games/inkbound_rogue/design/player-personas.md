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

Each persona faces representative Page 1, Page 6, and Page 12 encounters on
Story, Standard, and Redline. The same persona seed is reused across difficulty
settings so elite rolls, aim noise, and decisions remain comparable. The test
records survival, remaining health, encounter clear ratio, damage dealt/taken,
DPS, attacks, dashes, Ink Arts, threat time, movement time, and early-to-late
upgrade growth in `build/playtest/player-persona-report.json`.

The gate catches broken combat participation and invalid measurements, then
emits broad diagnostic observations instead of automatically changing balance.
It cannot judge controller latency, animation readability, accessibility,
fatigue, emotional pacing, or enjoyment; those still require human sessions.
