# Inkbound: Blade of the Blank Page

A top-down manga-pixel action roguelike and Manga Forge's end-to-end release
validation game. A complete three-act run follows Nara through the Grand Archive,
the Forbidden Bindery, and the First Press, with seven animated story sequences
and two persistent endings. Completed runs continue as harder drafts.

## Playable content

- A project-bound 4×4 transparent combat-cast atlas replaces placeholder boxes
  with sixteen authored manga-pixel silhouettes: Nara, all twelve regular enemy
  roles, and the Red Editor, Binder, and First Author. Shared AtlasTexture
  regions, drawn ground shadows, movement squash, and dash stretch retain horde
  performance. Nara's slash now uses a separate four-frame anticipation, cut,
  contact, and recovery atlas plus a progressively drawn manga sweep instead of
  rotating one static combat pose. Slash, dash, and Ink Art taps buffer for
  120–140 ms, preserving deliberate inputs made at the end of recovery.
- Fifteen enemy archetypes: twelve regular roles, four elite affixes, and three
  bosses. The roster includes shields, teleport ambushes, support healers,
  stationary bullet hazards, timed parries, splitters, summoners, and drainers.
  Early-page natural spawns use mutually exclusive roster bands so newly
  introduced ranged enemies cannot dominate Page 3. Per-page hostile-shot
  budgets rise smoothly from 8 to 30, capping late-screen saturation while
  preserving authored radial patterns. Ordinary body attacks draw a shape-coded
  100–220 ms strike arc before damage; charged dash/teleport attacks retain
  their existing dedicated warning and now always enter a committed rush.
- Thirty-six stackable upgrades across blade, critical, projectile, status, dash,
  defense, economy, combo, and active Ink Art tags. Their tags write six named
  run disciplines with functional bonuses at three and six points. Once a
  discipline reaches two points, every level draft guarantees one marked
  Resonant option from that path; the HUD and cards preview identity, progress,
  and the exact choice that will awaken the next milestone.
- Four transformative weapon forms and twelve run-defining relics. Field drops,
  narrative bargains, and Directive rewards pause on a three-way Relic
  Restoration draft instead of silently assigning a random item. Owned relics
  never repeat, simultaneous rewards queue safely, and a completed relic archive
  converts further rewards into Memory.
- New Game now opens a five-form Armory. Marginalia stays flexible and can draft
  a restored transformation later; choosing Greatbrush, Needlepoint,
  Seal-Caster, or Twin-Stroke starts transformed and locks the other forms for
  that run. Locked blades show their persistent restoration milestone.
- Five weapon-specific active Ink Arts add a second combat cadence: Marginalia's
  Palimpsest Ring, Greatbrush's Final Period, Needlepoint's Red Line,
  Seal-Caster's Seal Storm, and Twin-Stroke's Cross Revision. Six techniques
  modify their damage, area, recovery, hit refunds, echo, and sustain.
- XP, recovery, permanent Memory shards, relic drops, rarity weighting, and
  duplicate-drop effects. Five rare combat pickups provide an Ink Bomb, arena
  magnet, Red Frenzy, five-point Ward, or six-second Hourglass slowdown. A
  low-health recovery pity and first-run Ink Bomb guarantee prevent dry streaks;
  recovery and AOE pickups carry animated `+HP` / `AOE` field callouts.
  Hostile shots use a cold-cyan diamond, dark isolation halo, reticle ticks, and
  a higher foreground layer; pickups retain the warm crimson/ivory/gold family.
- A six-branch Restoration Board turns banked Memory into thirty persistent
  ranks. Heartbind, Honed Nib, Lucky Misprint, Quick Margin, Deep Inkwell, and
  Reader's Thread cover survivability, blade damage, economy, mobility, active
  skills, and pickup flow; later branches unlock at Archive Ranks 2, 4, and 6,
  and every completed branch grants a distinct mastery bonus.
- Eleven cumulative Proof Depths create a post-ending Ascension ladder. Clearing
  the highest available proof unlocks exactly one new depth, records the clear,
  and adds named enemy, horde, recovery, boss, dash, or deadline clauses. Proof
  10 pays ×2.16 score and ×1.63 Memory, while Proof 0 remains the authored
  baseline; both ends are included in the 432-row balance gate.
- Daily Chronicle turns the local calendar date into one deterministic seed and
  rotates through all six contracts. Every player receives Standard difficulty,
  Marginalia, Proof 0, and sealed Restoration bonuses while events, squads,
  techniques, drops, routes, and hazards remain part of the normal run. The
  first clear of a date awards 12 bonus Memory; attempts, wins, best score,
  current streak, best streak, Continue identity, and recent history persist.
- Three difficulty drafts, three visually distinct acts, three 32-second act
  loops and three 24-second boss themes with modal-safe crossfades, a bestiary
  codex, ten Archive ranks, permanent restoration upgrades,
  milestone unlocks, recent-run history, and two endings.
- Nine manga-environment routes form a player-chosen three-act route chain. Each
  route changes enemy composition, horde cadence, durability, elite pressure,
  recovery, Memory yield, score, and the arena's drawn environmental motifs.
  Each also owns a distinct telegraphed battlefield rule: beneficial Echo
  Sanctuaries, bilateral Razor Sweeps, Redaction Stamps, Binding Crosses, ink
  canal surges, timed Contraband caches, shared White Revisions, triple Press
  verdicts, or whole-page gusts. Hazards affect masks as well as the player and
  preserve an active warning across Continue / Load.
- Six optional challenge contracts change health, damage, horde pressure, elite
  frequency, page timing, score, and Memory rewards. Contracts, Redline, and
  advanced weapon forms unlock across repeated drafts; old profiles receive
  unlocks immediately from their existing history.
- Nine chapter events provide 27 risk/reward choices across all three acts.
- Nine Page Directives replace passive timer waiting with kill orders, Ink
  recovery, elite hunts, and visible hold zones. Nine named ring, line, and
  wedge squads turn enemy archetypes into authored combat combinations.
- Nineteen persistent achievements track kills, pages, endings, contracts, routes,
  discoveries, Redline victories, lifetime Memory, a Daily clear, and a seven-day
  Daily streak; each has a stable Steam
  API identifier ready for the eventual partner-account integration.
- Seven unique project-bound 2D manga cutscene paintings with per-line camera
  focus, independently moving establishing and close-up layers, speaker-colored
  panel borders, manga wipes, typewriter dialogue, device-aware prompts, and an
  ending choice. The title-screen Story Archive replays every unlocked sequence
  without changing run or ending state.
- A five-page Field Manual opens automatically on the first New Game, pauses the
  draft whenever reopened, explains controls and build systems, and exposes
  in-game credits and legal attribution. Its completion state persists without
  invalidating older profiles.
- Complete English and Simplified Chinese presentation covers the title shell,
  settings, HUD, Field Manual, techniques, relics, weapons, routes, contracts,
  Proof clauses, Daily Chronicle, bestiary, achievements, events, results, and
  all seven story sequences. The default follows the Windows display language;
  `Options & Accessibility` can switch between System, English, and 简体中文 at
  runtime, and the preference persists without invalidating older profiles.
- Separate atomic profile and current-draft saves. `Continue / Load` restores
  player position, health, XP, weapon build, relics, route, enemies, run counters,
  and supply-pity state; corrupted current drafts recover from a rotated backup.
  New Game requires confirmation when it would replace a saved draft.
- Twenty-five deterministic sound cues distinguish all five weapon rhythms,
  Ink Arts, enemy casts, dash warnings, teleport, parry, shield, restoration,
  combat supplies, boss entry/defeat, menu navigation, and Save & Return. Enemy
  warnings are spatial and rate-limited so large squads remain readable.
  Blade cuts are led by shaped air, edge, paper, and handle transients rather
  than oscillator sweeps; the six extended scores use dry paper/wood/brush
  layers and 32-second act / 24-second boss arrangements to reduce loop fatigue.

## Controls

Gamepads work by default and can be connected or disconnected while the game is
running. Xbox, PlayStation, Switch Pro, and compatible XInput/SDL controllers use
the same position-based layout. Standard controller aim assist softly bends an
attack toward an enemy within 32 degrees and the active attack's useful range;
it never attacks, locks a target, or changes keyboard/mouse aim:

- Left stick / D-pad: move
- Right stick: aim
- `X` / Square or right trigger: slash
- `A` / Cross or left shoulder: dash
- `B` / Circle: weapon-specific Ink Art
- Start: pause / resume
- Left trigger: open / close the Field Manual; shoulder buttons turn its pages
- Start on the title screen: continue a saved draft when present
- D-pad / left stick up-down in the Armory: select a starting blade
- `A` / Cross in the Armory: confirm; `B` / Circle: return without erasing a save
- View / Back: options and accessibility
- Left/right shoulder on the title screen: previous/next challenge contract
- Right-stick click on the title screen: open/close the Restoration Board
- Left-stick click on the title screen: open/close the Proof Ledger
- D-pad down on the title screen: open/close Daily Chronicle
- `X` / Square on the title screen: recent run history
- Right trigger on the title screen: unlocked Story Archive
- `X` / Square in the pause menu: save the current draft and return to title
- `X`, `Y`, `B`, RT / Square, Triangle, Circle, R2: choose techniques 1–4
- `X`, `Y`, `B` / Square, Triangle, Circle: choose relics 1–3
- `A` / Cross or Start: restart after defeat

Keyboard and mouse remain fully supported:

- `WASD` / arrow keys: move
- Mouse: aim
- Left mouse / `J`: slash
- `Space` / right mouse / `K`: dash
- `E` / middle mouse: weapon-specific Ink Art
- `1`, `2`, `3`, `4`: choose a level-up technique
- `R`: restart after defeat
- `Esc`: pause
- `F1` / `H`: open / close the Field Manual; arrow keys turn its pages
- `C` on the title screen: continue / load the current draft
- Arrow keys / `1`–`5` in the Armory: select a starting blade; Enter confirms
- `1` in the pause menu: save the current draft and return to title
- `O` / `F10`: options and accessibility
- `Q` / `E` on the title screen: previous/next challenge contract
- `M` on the title screen: open/close the Restoration Board
- `P` on the title screen: open/close the Proof Ledger
- `T` on the title screen: open/close Daily Chronicle

The HUD automatically switches prompts to the most recently used input device.
Combat hits, critical strikes, damage, and dashes provide gamepad vibration when
supported by the connected controller. Master/music/SFX volume, fullscreen,
vibration, controller aim assist (Off/Gentle/Standard), screen shake,
impact-freeze, reduced flashes, and language preferences persist with the profile.
Reduced flashes preserves warning shapes, scale changes, sounds, and colors while
removing rapid white/accent alternation from charge and damage feedback.
Options also exposes eighteen runtime binding slots for movement, slash, dash, Ink Art,
pause, and menu access across keyboard/mouse and gamepad. `Y`/Triangle or
Backspace restores the complete default layout.

When the application loses focus, gameplay pauses immediately and HUD,
cutscene, keyboard, mouse, and gamepad input are gated. Refocusing leaves the
pause in place until the player explicitly presses pause again. This prevents a
controller shared with another Windows application from moving or confirming in
the background.

Survive escalating manuscript waves, harvest red Ink, and choose techniques.
Page 4 summons the Red Editor, Page 8 the Binder, and Page 12 the First Author.
Pages 3, 7, and 10 interrupt the action with a randomized three-way event choice.
The opening and Pages 5 and 9 pause for a three-way route draft, producing one of
27 route chains before contracts, difficulty, and build choices are considered.
Defeated enemies recover Memory shards used for permanent upgrades on the title
screen. The codex reveals each restored archetype and its lifetime defeat count.

## Local run

```bash
python3 ../../tools/game/generate_validation_assets.py
godot --path .
```

## Automated validation

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/pause_state_test.gd
godot --headless --path . --script res://tests/save_recovery_test.gd
godot --headless --path . --script res://tests/session_flow_test.gd
godot --headless --path . --script res://tests/supply_drop_test.gd
godot --headless --path . --script res://tests/ink_art_test.gd
godot --headless --path . --script res://tests/encounter_director_test.gd
godot --headless --path . --script res://tests/route_hazard_test.gd
godot --headless --path . --script res://tests/starting_loadout_test.gd
godot --headless --path . --script res://tests/relic_draft_test.gd
godot --headless --path . --script res://tests/cutscene_animation_test.gd
godot --path . --script res://tests/field_manual_test.gd
godot --path . --script res://tests/localization_test.gd
godot --headless --path . --script res://tests/combat_cast_test.gd
godot --headless --path . --script res://tests/audio_system_test.gd
godot --headless --path . --script res://tests/combat_feel_test.gd
godot --headless --path . --script res://tests/accessibility_test.gd
godot --headless --path . --script res://tests/restoration_board_test.gd
godot --headless --path . --script res://tests/proof_depth_test.gd
godot --headless --path . --script res://tests/daily_chronicle_test.gd
godot --headless --path . --script res://tests/balance_matrix_test.gd
godot --headless --path . --script res://tests/player_persona_test.gd
godot --headless --path . --script res://tests/playtest_recorder_test.gd
godot --headless --path . --script res://tests/progression_test.gd
godot --headless --path . --script res://tests/route_system_test.gd
godot --headless --path . --script res://tests/soak_test.gd
```

The Windows host workflow exposes the same gates through `host_game.py test`,
`host_game.py pause-test`, `host_game.py save-test`, `host_game.py progression`,
`host_game.py session-test`, `host_game.py supply-test`, `host_game.py art-test`, `host_game.py encounter-test`,
`host_game.py hazard-test`, `host_game.py loadout-test`, `host_game.py relic-test`,
`host_game.py cutscene-test`, `host_game.py manual-test`, `host_game.py localization-test`, `host_game.py cast-test`,
`host_game.py audio-test`, `host_game.py combat-feel-test`, `host_game.py accessibility-test`, `host_game.py restoration-test`, `host_game.py proof-test`,
`host_game.py daily-test`, `host_game.py persona-test`, `host_game.py routes`,
`host_game.py playtest-recorder-test`, `host_game.py soak`, and
`host_game.py recorded-soak`. `host_game.py release-audit` verifies complete
asset provenance and, when present, the isolated three-file depot.
All host-side timeouts escalate from termination to forced recovery after ten
seconds so a failed Godot test cannot linger indefinitely. `host_game.py
process-status` reports every game/Godot process with elapsed time, CPU, memory,
and command line; `host_game.py cleanup-tests` terminates only this project's
`res://tests/` processes and never matches an editor or exported game.
`host_game.py p1-suite` first mirrors/imports current source, then runs 26 core
gates serially in one delegate session and finishes with a zero-process check.
It keeps a compact summary and one diagnostic log per gate under
`build/p1-suite/<UTC timestamp>/`; `build/p1-suite/latest.txt` identifies the
newest run without deleting earlier evidence.
`host_game.py capture-session` renders a ten-frame title, Armory, Story Archive,
Save & Return, recovery/AOE, technique, relic-draft, Ink Art, Directive, and
route-hazard readability gallery.
`host_game.py capture-cutscenes` renders all seven story sequences after their
panel wipe, including the independent close-up layer.
`host_game.py capture-upgrades` checks every technique card for safe title,
prompt, description, and rarity spacing before capturing the longest copy;
`host_game.py capture-restoration` renders the six-branch persistent upgrade board;
`host_game.py capture-proof` renders all eleven Proof Depths and their cumulative clause;
`host_game.py capture-daily` checks the date, seed, fixed rules, reward, and record panel;
`host_game.py capture-manual` captures onboarding and credits pages.
`host_game.py capture-localization` renders Simplified Chinese title, settings,
technique cards, and story subtitles with the Windows CJK font fallback chain.
Use `host_game.py balance` for the four-build × three-difficulty × six-contract ×
three-final-route matrix. `host_game.py persona-test` accelerates four behavioral
players through early, middle, and late combat on all three difficulties and
writes `build/playtest/player-persona-report.json`. The pause gate observes live
state across frozen frames, including background controller rejection, instead
of only checking menu visibility. Release metadata, legal notices, version identity,
and inert Steam depot templates live under `release/`; real App/Depot IDs are
never stored in the repository.

`asset-manifest.json` schema 3 integrity-hashes all 68 player-consumed PNG/WAV
assets and distinguishes 59 deterministic procedural outputs from nine
pre-generated AI-assisted images. `release/ai-content-disclosure.md` keeps the
Steam survey draft and unresolved publisher sign-offs explicit; the shipped
game performs no live AI generation.

## Local playtest recording

The Windows launcher can prepare an exported build and start one anonymous,
local-only playtest session:

```bash
python3 tools/windows/host_game.py playtest --participant P-001
```

During play, `F6` marks a bug, `F7` a confusing moment, `F8` an unfair moment,
and `F9` a highlight. A mark stores the previous 30 seconds of gameplay events,
the current run state, and a screenshot. Defeat or victory opens a bilingual
six-rating exit card with an optional 280-character note. Nothing is uploaded;
the build writes only pseudonymous gameplay data below
`build/playtest/sessions/` in the Windows runtime copy.

After the game closes, aggregate any complete and interrupted sessions with:

```bash
python3 tools/windows/host_game.py playtest-report
```

The resulting JSON and Markdown live under `build/playtest/reports/`. See
`design/playtest-recorder.md` for privacy boundaries, facilitator procedure,
artifact layout, and interpretation limits.
