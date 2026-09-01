---
name: manga-local-art
description: Produce and prepare manga-style game art or cinematic source media through the configured WSL-to-Windows ComfyUI host. Use for character references, portraits, backgrounds, comic cut-ins, keyframes, sprite source poses, and pre-rendered motion-comic scenes. Do not claim that raw generated images or videos are game-ready sprites without deterministic post-processing and in-engine validation.
---

# Manga Local Art

Choose the output role before choosing a model.

- Illustration roles: concept, canonical reference, portrait, background, prop,
  cut-in, or cinematic keyframe.
- Sprite roles: produce reference-anchored source poses, then normalize alpha,
  canvas, baseline, pivot, frames, and metadata outside the image model.
- Video roles: use for pre-rendered cutscenes, motion comics, menu backgrounds,
  or motion reference; never for collision-critical combat frames by default.

Read [references/local-backends.md](references/local-backends.md) before invoking
the Windows media stack. Read [references/asset-contract.md](references/asset-contract.md)
when the output enters a game repository.

Register every accepted asset with its stable ID, character/form version, prompt,
seed, model/workflow, source references, license, dimensions, and runtime role.
Prefer an original style bible over a named-artist tag for shipped work.
