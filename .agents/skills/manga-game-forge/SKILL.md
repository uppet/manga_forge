---
name: manga-game-forge
description: Build, extend, test, and export manga-style games in Manga Forge, primarily with Godot 4.7 and 2D action or narrative systems. Use when a request must turn story and art assets into a playable game, add combat or roguelike systems, create a vertical slice, validate game feel, or run/export a project on the configured Windows host. Do not use for manga pages without interactive gameplay.
---

# Manga Game Forge

Deliver a playable, observable result. A design document alone is not a game.

## Route the work

- Load only the relevant installed Godot, discipline, genre, and workflow skills.
- Use `story-forge`, `visual-novel`, and `dialogue-systems` for narrative work.
- Use `manga-local-art` when source art or cinematics must be produced locally.
- For a new project or cross-system change, read
  [references/project-contract.md](references/project-contract.md).
- Before invoking the Windows host, read
  [references/windows-host.md](references/windows-host.md).
- For completion criteria and playtest gates, read
  [references/validation.md](references/validation.md).

## Required workflow

1. Define one short player loop and the smallest vertical slice that proves it.
2. Keep story IDs, character/form IDs, asset IDs, save keys, and scene IDs stable.
3. Implement input, feedback, failure, progression, pause/restart, and persistence
   before expanding content breadth.
4. Treat imported AI media as source material until dimensions, alpha, pivots,
   loops, licenses, and in-engine readability have been validated.
5. Run import/parse checks, deterministic smoke tests, and a real Windows-host
   launch. Export a standalone build when templates are available.

Never report success from screenshots or source inspection alone. Capture the
actual command, exit status, and game/test signal that demonstrate completion.
