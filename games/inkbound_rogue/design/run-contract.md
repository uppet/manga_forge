# Run contract

## Player loop

Move through a large manuscript arena, aim a short sword arc, dash through danger,
collect Ink from defeated masks, and select one of three or four techniques at each level.
Every weapon form also owns a distinct active Ink Art on a recoverable second
combat button, turning form selection into a new attack pattern rather than only
a stat package. Blade hits can refund its recovery, and six upgrades form a
dedicated active-skill build path.
New Game pauses at a five-form Armory before it commits the draft. Marginalia
preserves every unlocked transformation in the later technique pool; a restored
Greatbrush, Needlepoint, Seal-Caster, or Twin-Stroke can instead be guaranteed
from the first room at the cost of locking the other forms for that run.
Pressure increases by page across three acts. Pages 4, 8, and 12 add unique bosses,
story transitions, arena treatments, music, objectives, and new enemy roles.
Each non-boss page opens with one of nine named enemy squads and a Page Directive:
kill a quota, recover loose Ink, hunt marked elites, or occupy a drawn hold zone.
Completing an order before the page turns grants Memory, healing, Ward, an active
Art refresh, a technique, or a relic and is recorded in the run ledger.
Every relic source opens the same three-way Restoration draft. Choices exclude
owned relics, pause the simulation, support the default gamepad face-button row,
queue behind an existing event or technique draft, and checkpoint only after the
choice is committed. Once all twelve relics are bound, later rewards become Memory.
Pages 3, 7, and 10 offer randomized narrative events with persistent run consequences.
Before Act I and on Pages 5 and 9, play pauses for a three-route draft. The selected
route changes the arena motif, enemy roster bias, spawn pressure, combat multipliers,
drop economy, score, and one of nine telegraphed battlefield rules until the next
act, producing 27 ordered route chains. These rules include spaces worth entering,
lines and stamps worth dodging or weaponizing against masks, timed loot, shared
healing, and whole-arena displacement rather than nine bundles of passive numbers.
Before starting, players may select unlocked contracts that alter the run rules
and multiply score and Memory rewards. Reaching pages, defeating masks, finishing
endings, and clearing distinct contracts progressively restores the full six-contract,
four-form, three-difficulty ruleset.
After the first ending, the Proof Ledger becomes a second long-form challenge
track. Proof 0 is the baseline; clearing the highest available depth unlocks the
next of ten cumulative named clauses. The ladder progressively changes damage,
health, horde cadence, elites, recovery, speed, bosses, dash recovery, deadlines,
score, and Memory without replacing difficulty, contract, route, or build choices.
Daily Chronicle adds one comparable draft per local calendar date. Its seed and
rotating contract are deterministic, while Standard, Marginalia, Proof 0, and
sealed Restoration remove account-power variance. A first clear pays 12 bonus
Memory and daily attempts, wins, best score, and consecutive-date streaks persist.

## Loss and persistence

The run ends at zero health. Best score, best kill count, contract attempts,
contract clears, contract best scores, settings, endings, and progression are saved to
`user://inkbound_save.json`. Schema 12 stores the ten most recent run summaries,
their route chains, persistent route discoveries, and up to 64 Daily Chronicle
records. The result panel reports
Memory banked, build, duration, Archive Rank, route chain, and newly unlocked
content. Restart never requires returning to the editor.

An independent schema-1 current-draft checkpoint rotates a backup separately
from permanent profile data. Safe page, route, event, technique, and manual
pause saves preserve the player build, health, XP, position, route, enemy state,
run counters, supply-pity counters, and an in-progress route-hazard warning.
Continue / Load resumes that draft with
a brief damage grace period. Save & Return reaches the title without committing
the run; New Game requires confirmation before replacing the current draft.
Final victory or defeat clears the checkpoint. A seven-entry Story Archive
replays unlocked cinematics without applying run or ending side effects.

## Validation content

- Responsive 8-way movement with keyboard/mouse and a default gamepad layout:
  left stick/D-pad movement, right-stick aim, face-button/trigger attack, shoulder
  dash, Start pause, menu selection, hot-plug prompts, and vibration feedback.
- A shared transparent 4×4 combat atlas gives the player, all twelve regular
  roles, and all three bosses distinct project-bound manga-pixel silhouettes.
  Grounding shadows and procedural move, dash, and attack poses add clarity
  without changing collisions or exceeding the existing scene-node budget.
- Arc-based multi-target slash with knockback, crits, freeze, flash, sound,
  particles, camera shake, and comic typography.
- Three sixteen-second act loops crossfade into three dedicated twelve-second
  boss themes. Twenty-five cues distinguish weapon forms, Ink Arts, positional
  enemy warnings, supplies, UI navigation, pause, and saving, with squad-safe
  cooldowns and persistent volume settings.
- Dash with cooldown and brief invulnerability.
- Five weapon-specific active Ink Arts with cooldown, area, damage, recovery,
  echo, sustain, keyboard/mouse, gamepad, HUD, and checkpoint integration.
- Five-form starting Armory with persistent progression locks, explicit
  flexibility-versus-certainty tradeoff, controller navigation, cancel-safe New
  Game confirmation, checkpoint recovery, and run-history attribution.
- Fifteen enemy archetypes, four elite affixes, three bosses, status effects,
  splitters, summoners, life-drainers, chargers, ranged skirmishers, area denial,
  frontal shields, teleport ambushes, support healing, and timed parries.
- Nine authored enemy squads and nine Page Directives spanning kill, collection,
  elite-hunt, and territory-control play, with rewards, HUD, checkpoint recovery,
  run summaries, persistent totals, and two achievements.
- Nine route-specific battlefield rules with code-drawn warning geometry,
  player/enemy interaction, pause arbitration, and exact checkpoint recovery.
- XP, recovery and Memory drops; visible low-health and AOE drop guarantees;
  five combat pickups; 36 rarity-weighted
  upgrades, four weapon forms, twelve functional relics with a unified three-way
  draft, four-choice bonuses, six named disciplines with 3/6-point combat
  milestones, a guaranteed Resonant choice after committing two points, build HUD,
  and permanent Archive restoration.
- A six-branch, thirty-rank Restoration Board spends 720 lifetime Memory across
  health, damage, luck, mobility, Ink Art, and pickup paths. Branches unlock at
  Archive Ranks 1/2/4/6, each path has a functional mastery bonus, keyboard and
  controller can navigate the 2×3 board, and schema-9 profiles migrate safely.
- Eleven cumulative Proof Depths provide sequential post-ending clears, named
  gameplay clauses, increasing score/Memory rewards, a two-column controller
  ledger, checkpoint identity, run-history attribution, and schema-10 migration.
- Daily Chronicle provides a date-stable seed, six-contract rotation, sealed
  account power, exact RNG checkpoint recovery, first-clear reward, streak
  history, title/controller flow, two achievements, and schema-11 migration.
- Seven uniquely illustrated, layered manga cutscenes, a three-act plot, a final choice, two persistent
  endings, three difficulty drafts, six contracts, nine events with 27 choices,
  nine routes with 27 three-act chains, a codex, nineteen achievements, runtime
  keyboard/mouse and gamepad remapping, ten Archive ranks, recent-run history,
  milestone-gated content, and schema-v12 profile data with schema-v11 migration.
- Centralized simulation pause arbitration during menus, events, upgrades,
  cutscenes, focus loss, game-over, and restart; a cross-frame regression gate
  proves that positions, cooldowns, spawn timers, and run time remain frozen,
  and that background gamepad events cannot reach gameplay, HUD, or cutscenes.
- Four representative endgame builds are measured across Proof 0 and Proof 10
  for all 54 combinations of difficulty, contract, and final-act route: 432 rows.
  The gate bounds attack cadence,
  build disparity, survivability, and final-boss encounter time and writes a JSON
  balance report.
- Four accelerated behavior personas—first-timer, blade rusher, margin kiter,
  and speedreader—drive the live movement, slash, dash, Ink Art, enemy AI,
  projectile, and drop systems across three stages and three difficulties. The
  36-row report exposes survival, clear ratio, incoming damage, DPS, action use,
  and upgrade growth while explicitly remaining distinct from human feel tests.

## Done signal

The pipeline is valid when Godot imports without parse errors, the smoke test
prints `INKBOUND_SMOKE_OK`, the Windows host launches the project, and a Windows
export is created when matching templates are installed. The independent soak
gate must also print `INKBOUND_SOAK_OK` without exceeding its enemy, drop, node,
or memory budgets. The modal-state gate must print `INKBOUND_PAUSE_OK`, and the
save-integrity gate must print `INKBOUND_SAVE_OK`.
The build matrix must print `INKBOUND_BALANCE_OK` for all 432 rows.
The long-term progression gate must print `INKBOUND_PROGRESSION_OK`.
The route-system gate must print `INKBOUND_ROUTES_OK`.
The story-presentation gate must print `INKBOUND_CUTSCENE_OK` with seven unique
images, twenty-eight authored shots, layered motion, wipe transitions, and ending input.
The current-draft and story-replay gate must print `INKBOUND_SESSION_OK`.
The recovery/AOE drop gate must print `INKBOUND_SUPPLY_OK`.
The active-combat gate must print `INKBOUND_ART_OK`.
The encounter-director gate must print `INKBOUND_ENCOUNTERS_OK`.
The route-hazard gate must print `INKBOUND_HAZARDS_OK` for all nine mechanics.
The starting-loadout gate must print `INKBOUND_LOADOUT_OK` for all five forms.
The relic-agency gate must print `INKBOUND_RELIC_DRAFT_OK` for field, event,
Directive, queue, controller, checkpoint, run-summary, and exhausted-pool paths.
The combat-cast gate must print `INKBOUND_CAST_OK` for all sixteen clipped atlas
regions, transparent alpha, unique actor mapping, ground shadows, and dynamic poses.
The audio gate must print `INKBOUND_AUDIO_OK` for 25 cues, six exact-length
loops, adaptive boss transitions, production crossfade, spatial warnings, weapon
timbres, supply feedback, UI feedback, and anti-spam cooldowns.
The persistent-upgrade gate must print `INKBOUND_RESTORATION_OK` for six branches,
thirty ranks, mastery effects, rank locks, two-axis controller navigation,
schema-12 persistence, and schema-9 migration. Its Windows renderer companion
must print `INKBOUND_RESTORATION_UI_OK` with all six cards contained.
The post-ending challenge gate must print `INKBOUND_PROOF_OK` for all eleven
depths, sequential unlocks, ten cumulative clauses, terminal clear state,
rewards, controller input, checkpoint recovery, schema-12 persistence, and
schema-10 migration. Its Windows companion must print `INKBOUND_PROOF_UI_OK`.
The date-seeded replay gate must print `INKBOUND_DAILY_OK` for deterministic
rules, sealed meta power, exact checkpoint RNG, one-time reward, streaks,
history, achievements, schema-12 persistence, and schema-11 migration. Its
Windows renderer companion must print `INKBOUND_DAILY_UI_OK`.
The behavior simulation gate must print `INKBOUND_PERSONA_OK` for four personas,
three difficulties, three progression stages, and all 36 report rows.
