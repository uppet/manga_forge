# Pre-generated AI content worksheet

Status date: 2026-09-04. This is a production inventory, not legal advice or a
substitute for publisher review.

Steamworks' current Content Survey treats player-consumed content made with AI
help during development as **Pre-Generated** AI content, while content generated
during play is **Live-Generated** and requires additional guardrail disclosure:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?l=english>.

## Product declaration draft

**Pre-Generated AI: Yes.** OpenAI image generation was used under project
direction to create one 16-character manga-pixel combat atlas, a derivative
four-frame protagonist slash atlas, seven unlettered manga cutscene
backgrounds, and ten weapon-specific Ink Art cut-in/startup images. OpenAI
Realtime was also used to pre-generate 14 Japanese player/enemy combat-feedback
performances. A locally operated IndexTTS 2.5 pipeline generated six Japanese
Nara Ink Art performances from one consistent reference voice.
The project owner generated and supplied five AIGC-tagged 海绵音乐 tracks for
menu, combat, story, and two endings. Human-authored code supplies all
gameplay, collision, animation timing, UI, dialogue, localization, progression,
narrative choices, music-state mapping, and loop processing. The assets were
reviewed in the running game and are integrity-hashed in the asset manifest.

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
| Ink Art cinematics | 10 | `assets/ink_art/README.md`; shared identity constraints, weapon briefs, source dimensions, and runtime derivation retained | Publisher rights/IP review |
| Japanese Ink Art voice | 6 | `assets/audio/nara-ink-art-japanese.provenance.md`; lines, model, reference-voice description, selection distribution, and hashes retained | Owner approved demo use; verify IndexTTS/dependency, reference recording, and generated-output rights before commercial distribution |
| Japanese combat-feedback voice | 14 | `assets/audio/combat-feedback-japanese.provenance.md`; dialogue, model/voices, B selection, transformations, and hashes retained | Owner approved B selection for demo use; publisher/OpenAI terms review before commercial distribution |
| Hai Mian Music soundtrack | 5 | `assets/audio/hai-mian-music.provenance.md`; source/runtime hashes, known AIGC ProduceIDs, roles, processing, and production briefs retained | Owner approved demo use; confirm generation-time plan and terms before commercial distribution |
| Procedural pixel art and WAV audio | 64 | Reproducible `tools/game/generate_validation_assets.py` source; no generative AI | Source/license review complete |

`asset-manifest.json` schema 3 is the machine-readable source of truth. It
covers every player-consumed PNG/WAV/OGG, records SHA-256, creation method,
whether AI was involved, whether generation is live, provenance location,
prompt-record status, human review, and rights-review status.

## Required sign-off before a public Steam review

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
- Keep the Steam Content Survey answer consistent with both the uploaded build
  and store imagery; revisit the survey whenever content changes.
- Preserve the approved hashes and reviewer/date in a publisher-owned release
  record outside public credentials or account data.
