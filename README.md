# Manga Forge

Manga Forge is an agent-ready production workspace for manga, narrative, audio,
and playable manga-style games. Godot 4.7 is the broader tooling reference;
Inkbound Rogue remains pinned to the validated Godot 4.2.2 Windows runtime.
Most game projects target 2D and can opt into 3D where it materially improves
the result.

## Capabilities

- Story, dialogue, continuity, visual-novel design, speech, music, and SFX.
- Curated Godot 4.7 skills for scenes, movement, physics, animation, UI, audio,
  resources, shaders, procedural generation, save systems, game feel, and export.
- Manga-specific orchestration and local Windows-host art production contracts.
- WSL-to-Windows host testing and launch helpers.
- A playable validation game at `games/inkbound_rogue/`.

## Validation game

Generate its deterministic source assets and run local checks:

```bash
python3 tools/game/generate_validation_assets.py
python3 tools/windows/host_game.py probe
python3 tools/windows/host_game.py process-status
python3 tools/windows/host_game.py sync
python3 tools/windows/host_game.py test
python3 tools/windows/host_game.py pause-test
python3 tools/windows/host_game.py session-test
python3 tools/windows/host_game.py supply-test
python3 tools/windows/host_game.py restoration-test
python3 tools/windows/host_game.py capture-restoration
python3 tools/windows/host_game.py proof-test
python3 tools/windows/host_game.py capture-proof
python3 tools/windows/host_game.py daily-test
python3 tools/windows/host_game.py capture-daily
python3 tools/windows/host_game.py persona-test
python3 tools/windows/host_game.py run
```

`host_game.py` reads `tools/windows/host_config.json` when present and otherwise
uses the checked-in example defaults for this WSL + Windows host.
`run` is single-instance for the exported game; `process-status` reports any
live Inkbound Rogue or Godot processes without terminating them.
