# Pre-generated AI content worksheet

Status date: 2026-09-01. This is a production inventory, not legal advice or a
substitute for publisher review.

Steamworks' current Content Survey treats player-consumed content made with AI
help during development as **Pre-Generated** AI content, while content generated
during play is **Live-Generated** and requires additional guardrail disclosure:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?l=english>.

## Product declaration draft

**Pre-Generated AI: Yes.** OpenAI image generation was used under project
direction to create one 16-character manga-pixel combat atlas, a derivative
four-frame protagonist slash atlas, and seven unlettered manga cutscene
backgrounds. Human-authored code supplies all gameplay, collision, animation
timing, UI, dialogue, localization, progression, and narrative choices. The
images were reviewed in the running game and are integrity-hashed in the asset
manifest.

**Live-Generated AI: No.** The shipped executable makes no model/API requests
and generates no text, images, audio, code, or other player-consumed content
with AI while running. The local playtest recorder is deterministic telemetry,
not an AI service.

## Inventory

| Class | Count | Prompt/provenance record | Commercial gate |
| --- | ---: | --- | --- |
| Combat cast atlas | 1 | `assets/characters/combat-cast-atlas-v1.provenance.md`; exact original prompt not retained | Publisher rights/IP review or replacement |
| Nara slash atlas | 1 | `assets/characters/nara-slash-atlas-v1.prompt.md`; full generation/edit trail retained | Publisher rights/IP review |
| Narrative backgrounds | 7 | `assets/cutscenes/README.md`; shared constraints retained, exact per-image prompts not retained | Publisher rights/IP review or replacement |
| Procedural pixel art and WAV audio | 59 | Reproducible `tools/game/generate_validation_assets.py` source; no generative AI | Source/license review complete |

`asset-manifest.json` schema 3 is the machine-readable source of truth. It
covers every player-consumed PNG/WAV, records SHA-256, creation method, whether
AI was involved, whether generation is live, provenance location, prompt-record
status, human review, and rights-review status.

## Required sign-off before a public Steam review

- Confirm distribution rights against the originating OpenAI account and terms
  that applied when each image was created.
- Review every AI-assisted image for recognizable third-party IP, trademarks,
  real-person likeness, watermark fragments, and misleading imitation claims.
- Replace or explicitly approve assets whose exact prompt record is missing.
- Keep the Steam Content Survey answer consistent with both the uploaded build
  and store imagery; revisit the survey whenever content changes.
- Preserve the approved hashes and reviewer/date in a publisher-owned release
  record outside public credentials or account data.
