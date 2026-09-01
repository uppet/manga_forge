# Game art asset contract

Each accepted asset manifest entry includes:

```json
{
  "id": "hero-base-portrait-neutral",
  "character_id": "hero",
  "form_id": "base",
  "role": "portrait",
  "source": "local-comfyui",
  "generator": "model-or-workflow-id",
  "seed": 0,
  "license": "reviewed-license-id",
  "runtime_path": "res://assets/portraits/hero-base-neutral.png",
  "width": 512,
  "height": 512
}
```

Sprite entries additionally require action, direction, frame count, frame rate,
canvas size, foot baseline, pivot, and collision metadata. Cinematics require
duration, frame rate, audio channels, loop policy, subtitles, and target-platform
codec validation.

Reject assets with unresolved identity drift, untracked model/license provenance,
unreadable silhouettes, accidental text/watermarks, or missing alpha where the
runtime role requires it.
