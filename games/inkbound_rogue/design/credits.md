# Last Inkwarden / 墨卫残章 — production credits

Status date: 2026-09-04. This is the canonical human-readable credit roster for
tools and models used in the current game's resource-production workflow. It
distinguishes manifest-mapped runtime assets from owner-confirmed production
and previsualization tools whose file-level job records still need to be
backfilled. Detailed hashes, prompts where retained, transformations, and
distribution gates remain in `asset-manifest.json`, the asset provenance
records, and `release/ai-content-disclosure.md`.

## People and collaboration

| Credit | Role |
| --- | --- |
| Joyer Huang | Creator; creative direction; game and narrative direction; prompt direction; asset selection, integration approval, and production |
| OpenAI Codex (GPT-5) | AI development collaborator; game design, code, production tooling, documentation, validation, and asset-integration support |
| Playtesters | Usability, balance, input, presentation, and defect feedback |

## Engine and production tools

| Tool | Shipped use |
| --- | --- |
| Godot Engine 4.2.2 | Game runtime, editor, UI, input, audio, animation, and Windows export |
| Manga Forge | Project production pipeline and resource workflow |
| Python 3 | Deterministic pixel-art/audio generation, manifests, build orchestration, validation, and playtest tooling |
| FFmpeg 4.4.2 | Deterministic trimming, crossfading, transcoding, and runtime-audio preparation |

## Generative models and platforms

| Model or platform | Assets or production role | Record policy |
| --- | --- | --- |
| OpenAI image generation | Two character atlases, seven story backgrounds, and ten Ink Art cut-in/startup images | The exact image-model version was not retained for every asset, so the credits do not invent one |
| Stable Diffusion through ComfyUI | Local illustration generation and visual-resource workflow | Project-owner-confirmed production credit; exact checkpoint, workflow JSON, and runtime-file mapping must be backfilled before commercial release |
| MiniMax H3 | Motion/cinematic generation and previsualization workflow | Project-owner-confirmed production credit; exact job identifiers, outputs, and runtime-file mapping must be backfilled before commercial release |
| OpenAI Realtime API — `gpt-realtime-2.1` | Fourteen Japanese player/enemy combat-feedback performances | Exact shipped model and voice roles are recorded in `assets/audio/combat-feedback-japanese.provenance.md` |
| Locally operated IndexTTS 2.5 | Six Japanese Nara Ink Art performances | Reference-voice and runtime-selection details are recorded in `assets/audio/nara-ink-art-japanese.provenance.md` |
| 海绵音乐 / Hai Mian Music | Five pre-generated AIGC tracks for menu, battle, story, and two endings | The underlying platform model name was not exposed or retained; known ProduceIDs and source hashes are recorded in `assets/audio/hai-mian-music.provenance.md` |

All generated content above is pre-generated. The shipped executable makes no
live model or API request. Joyer Huang directed, selected, reviewed, and
integrated the delivered assets. ComfyUI, Stable Diffusion, and MiniMax H3 are
credited from the project owner's production record; until their file-level
mapping is restored, this roster does not silently reassign the provenance of
assets already mapped to another service.

## Deliberate exclusions

Rejected auditions, temporary previews, and tools whose output does not appear
in the build are not credited as shipped-resource producers. In particular,
the rejected Edge-TTS experiments are not part of the runtime asset set.

Godot's full MIT notice and the concise production disclosure ship beside the
executable in `THIRD_PARTY_NOTICES.txt`.
