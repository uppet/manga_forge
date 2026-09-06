# Pre-generated AI content worksheet

Status date: 2026-09-05. This is a production inventory, not legal advice or a
substitute for publisher review.

A zero-price public Beta is still public distribution. Before uploading the
itch.io/Quark candidate, the owner must confirm the applicable generation-time
account and tool terms, review the shipped assets for third-party IP or real
person likeness concerns, and either approve or replace assets with unresolved
rights records. Keeping this worksheet visible does not itself complete that
review.

Steamworks' current Content Survey treats player-consumed content made with AI
help during development as **Pre-Generated** AI content, while content generated
during play is **Live-Generated** and requires additional guardrail disclosure:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?l=english>.

## Product declaration draft

**Pre-Generated AI: Yes.** OpenAI image generation was used under project
direction to create one storefront cover image, one 16-character manga-pixel combat atlas, a derivative
four-frame protagonist slash atlas, seven unlettered manga cutscene
backgrounds, ten weapon-specific Ink Art cut-in/startup images, two choice-icon
atlases, and three identity-referenced boss-introduction portraits. OpenAI
Realtime was also used to pre-generate 14 Japanese player/enemy combat-feedback
performances. A locally operated IndexTTS 2.5 pipeline generated six Japanese
Nara Ink Art performances from one consistent reference voice.
The project owner generated and supplied five AIGC-tagged 海绵音乐 tracks for
menu, combat, story, and two endings. OpenAI Codex (GPT-5) assisted during
development with game design, code, UI text, localization, documentation,
production tooling, validation, and asset integration under project-owner
direction and review. Human-directed, offline-authored code supplies all
gameplay, collision, animation timing, UI, dialogue, localization, progression,
narrative choices, music-state mapping, and loop processing. The assets were
reviewed in the running game and are integrity-hashed in the asset manifest.
The project owner also identifies ComfyUI, Stable Diffusion, and MiniMax H3 as
resource-production or previsualization tools. The current manifest does not
yet map their exact checkpoints/jobs to individual runtime files, so this draft
records their involvement without inventing a conflicting asset attribution.

**Live-Generated AI: No.** The shipped executable makes no model/API requests
and generates no text, images, audio, code, or other player-consumed content
with AI while running. The local playtest recorder is deterministic telemetry,
not an AI service.

## Inventory

| Class | Count | Prompt/provenance record | Commercial gate |
| --- | ---: | --- | --- |
| Store cover-art candidates | 2 generated / 1 retained | `release/cover-art-v2.provenance.md` records the rejected v1 hash/reason and the current v2 prompt, reference roles, hash, and review status; the incorrect v1 bitmap is not retained | Publish v2 only after project-owner approval and publisher rights/IP review |
| Combat cast atlas | 1 | `assets/characters/combat-cast-atlas-v1.provenance.md`; exact original prompt not retained | Publisher rights/IP review or replacement |
| Nara slash atlas | 1 | `assets/characters/nara-slash-atlas-v1.prompt.md`; full generation/edit trail retained | Publisher rights/IP review |
| Narrative backgrounds | 7 | `assets/cutscenes/README.md`; shared constraints retained, exact per-image prompts not retained | Publisher rights/IP review or replacement |
| Ink Art cinematics | 10 | `assets/ink_art/README.md`; shared identity constraints, weapon briefs, source dimensions, and runtime derivation retained | Publisher rights/IP review |
| Technique/relic choice icons | 2 | `assets/ui/choice_icons/provenance.md`; complete final production briefs retained | Publisher rights/IP review |
| Boss introduction portraits | 3 | `assets/boss_intro/provenance.md`; shared constraints and all three character prompts retained | Publisher rights/IP review |
| Japanese Ink Art voice | 6 | `assets/audio/nara-ink-art-japanese.provenance.md`; lines, model, reference-voice description, selection distribution, and hashes retained | Owner approved demo use; verify IndexTTS/dependency, reference recording, and generated-output rights before commercial distribution |
| Japanese combat-feedback voice | 14 | `assets/audio/combat-feedback-japanese.provenance.md`; dialogue, model/voices, B selection, transformations, and hashes retained | Owner approved B selection for demo use; publisher/OpenAI terms review before commercial distribution |
| Hai Mian Music soundtrack | 5 | `assets/audio/hai-mian-music.provenance.md`; source/runtime hashes, known AIGC ProduceIDs, roles, processing, and production briefs retained | Owner approved demo use; confirm generation-time plan and terms before commercial distribution |
| Procedural pixel art and WAV audio | 64 | Reproducible `tools/game/generate_validation_assets.py` source; no generative AI | Source/license review complete |

`asset-manifest.json` schema 3 is the machine-readable source of truth. It
covers every player-consumed PNG/WAV/OGG, records SHA-256, creation method,
whether AI was involved, whether generation is live, provenance location,
prompt-record status, human review, and rights-review status.

## Required sign-off before a public Beta or Steam review

- Confirm distribution rights against the originating OpenAI account and terms
  that applied when each image was created.
- Review every AI-assisted image for recognizable third-party IP, trademarks,
  real-person likeness, watermark fragments, and misleading imitation claims.
- Replace or explicitly approve assets whose exact prompt record is missing.
- Preserve the Hai Mian Music generation/download records and confirm the
  generation-time account plan and terms grant commercial game-distribution
  rights before a paid or otherwise commercial public build.
- Preserve the OpenAI generation account and API billing records for the 14
  shipped combat-feedback voice takes, and confirm the applicable OpenAI terms
  before a paid or otherwise commercial public build.
- Preserve the IndexTTS delivery manifest, model/dependency versions, and
  reference-voice authorization; review each component's terms before a paid or
  otherwise commercial public build.
- Backfill the ComfyUI workflow JSON, Stable Diffusion checkpoint/license, and
  MiniMax H3 job/output records; map any player-consumed output to its runtime
  file and update the inventory before commercial distribution.
- Keep the Steam Content Survey answer consistent with both the uploaded build
  and store imagery; revisit the survey whenever content changes.
- Preserve the approved hashes and reviewer/date in a publisher-owned release
  record outside public credentials or account data.
