# Debug startup-state JSON

The startup-state path is explicit: the game reads it only from the
`INKBOUND_STARTUP_STATE` environment variable or a Godot user argument such as
`-- --startup-state=S:\path\state.json`. A normal Steam/itch.io launch never
looks for a debug file.

The Windows development export contains `Start-Debug-State.cmd`, a working
`startup-state.json`, and a clean `startup-state.example.json`. Edit the working
JSON and double-click the CMD. An optional JSON path may be passed as its first
argument. Export preserves an existing working JSON so local reproduction
recipes are not overwritten.

Every document requires `schema: 1` and `enabled: true`. Invalid IDs, malformed
types, unsupported schemas, mutually exclusive weapon forms, or missing files
reject the whole state instead of partially applying it. Numeric values outside
safe limits are clamped and reported as warnings. Active debug runs use a
separate profile namespace, reject save/checkpoint writes, disable
GameAnalytics, and prefix the combat objective with `[DEBUG]` / `[调试]`.

## Fields

- `profile`: filename-safe reproduction label. It never selects a real player
  profile.
- `seed`: deterministic random-upgrade, random-relic, encounter, and enemy seed.
- `settings`: `language` (`auto`, `en`, `zh_CN`), `ink_art_cutins`, `hit_stop`,
  and `reduced_flashes`.
- `run.page`: Page 1–12. `page_progress` is the fraction already elapsed on that
  page, from 0 to 0.95.
- `run.difficulty`: `story`, `standard`, or `redline`.
- `run.contract`: any ID from `Content.CONTRACTS`; locked contracts are allowed
  because this is an isolated debug run.
- `run.proof_depth`: 0–10. Locked proof depths are allowed.
- `run.starting_weapon`: `marginalia`, `greatbrush`, `needlepoint`,
  `seal-caster`, or `twin-stroke`.
- `run.route`: a route ID, or an empty string for no route.
- `run.spawn_page_content`: creates that page's normal squad/directive.
- `run.ambient_spawning`: permits the normal continuous enemy director.
- `run.page_timer`: permits time to advance into later pages. Disable this and
  ambient spawning when isolating a combat bug.
- `run.clear_existing_enemies`: removes the three title-background masks before
  applying the configured world.
- `run.boss`: `auto`, `none`, or a concrete boss ID (`editor`, `binder`,
  `author`). Auto selects the normal boss on Pages 4, 8, and 12.
- `run.boss_intro`: enables the boss cut-in for the configured boss.
- `run.boss_position`: offset from the configured player position.
- `run.memory` and `run.kills`: initial run counters.
- `player.level`, `xp`, `health_ratio`, `guard`, `ink_art_ready`, and
  `position`: direct player state. XP is clamped below the configured level's
  next threshold; health is applied after all build effects.
- `player.upgrades`: fixed technique IDs or `{ "id": ..., "stacks": ... }`
  objects. Normal maximum stacks and minimum levels are validated.
- `player.random_upgrades.count`: number of additional random technique stacks.
  `max_stacks_per_upgrade`, `allow_weapon_forms`, optional tag filters, and
  exclusions constrain the pool. An empty tag list means every eligible tag.
- `player.relics`: fixed unique relic IDs.
- `player.random_relics.count` and `exclude`: additional unique random relics.
- `enemies`: exact fixtures with `kind`, `[x, y]` position,
  `relative_to_player`, `elite`, and `health_ratio`. Boss fixtures are allowed,
  though `run.boss` is usually clearer.

Technique, relic, route, contract, enemy, and weapon IDs live in
`scripts/content_db.gd`. The committed `release/startup-state.example.json` is
the canonical editable template.
