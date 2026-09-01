# Manga game project contract

Use these contracts for projects that combine narrative, generated media, and
runtime gameplay.

## Project files

- `project.godot`: engine and input baseline.
- `art-bible.yaml`: palette, resolution, silhouettes, line weight, and prohibited drift.
- `asset-manifest.json`: source, generator/model, license, dimensions, role, and runtime path.
- `design/run-contract.md`: player loop, controls, loss condition, progression, and done criteria.
- `tests/`: import and gameplay smoke tests that terminate without user input.

## Stable IDs

Use lowercase slug IDs. A character form is a new ID, not an overwrite. Runtime
code refers to IDs and manifest entries, never to prompt prose or temporary
output filenames.

## Game architecture

- Compose scenes and small nodes instead of one universal manager.
- Put tuning values in resources or compact data dictionaries.
- Use signals/groups across ownership boundaries.
- Keep deterministic test hooks narrow and inert during normal play.
- Preserve a procedural or checked-in fallback for every required generated asset.

## Manga presentation

Gameplay readability wins over illustration detail. Preserve silhouettes, use a
small value range, reserve the accent color for threats and impact, and express
manga language through panel borders, halftones, speed lines, impact frames, and
short typographic bursts without hiding collision-critical action.
