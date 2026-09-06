# Last Inkwarden / 墨卫残章 — Steam store metadata draft

Public product name: **Last Inkwarden**

Simplified Chinese product name: **墨卫残章**

Promotional line: **Blade of the Blank Page / 空白页之刃**

## Current distribution status

The project is preparing a **free public Windows Beta** for identical
distribution through itch.io and a Quark Drive mirror while feedback is
collected. The public candidate still requires final packaging, rights review,
and download-link replacement. It is not a finished Steam release.

- itch.io: <https://your-itch-username.itch.io/last-inkwarden> (replace before publication)
- Quark Drive mirror: <https://pan.quark.cn/s/REPLACE_ME> (replace before publication)
- Player-facing page copy: `itch-description.md`
- Cover-art candidate: `cover-art-v2.png` (project-owner approval pending; the
  rejected v1 bitmap is not retained)

## Short description

Cut through a living manuscript in a manga-pixel action roguelike. Forge a
blade build, recover erased memories, survive twelve escalating pages, and
decide which ending the Grand Archive deserves.

## Long-description pillars

- Fast top-down melee with directional slashes, invulnerable dashes, five
  weapon-specific active Ink Arts, hit freeze, gamepad vibration, and readable
  manga impact effects.
- Adaptive audio moves between three 32-second act scores and dedicated
  24-second Red Editor, Binder, and First Author themes. Dry paper, wood, brush,
  and blade-material layers replace arcade-like oscillator sweeps; distinct Ink
  Art, spatial enemy-warning, pickup, boss, and menu cues keep dense pages readable.
- A five-form starting Armory makes each draft immediately build-defining:
  retain Marginalia's flexible transformation pool or commit to a restored form
  and its unique Ink Art from Page 1.
- Thirty-six stackable techniques, four weapon forms, twelve functional relics
  offered through three-way Restoration drafts, five rare combat pickups, six
  contracts, three difficulty drafts, and 27 player-built
  route chains across nine distinct Archive regions. Every region adds a unique
  readable battlefield rule, from shared healing circles and timed caches to
  razor lines, triple stamps, and page-wide gusts that also affect enemies.
- Fifteen enemies with shields, teleport ambushes, support healing, parries,
  radial hazards, elite affixes, and three multi-pattern bosses.
- Sixteen project-bound manga-pixel combat silhouettes give Nara, every regular
  enemy role, and all three bosses unique weapons, costumes, and readable forms,
  with grounded movement, dash, and attack posing.
- Nine named combat squads and nine Page Directives add kill orders, Ink
  recovery, elite hunts, hold zones, immediate rewards, and persistent records.
- A complete three-act story told through seven uniquely illustrated, layered 2D manga sequences,
  nine narrative events, a replayable Story Archive, a final choice, and two
  persistent endings.
- A six-branch, thirty-rank Restoration Board adds permanent health, blade,
  fortune, mobility, Ink Art, and pickup paths with Archive Rank gates and
  branch mastery bonuses. Bestiary discovery, contract and Directive records,
  and nineteen in-game achievements support repeat runs.
- Eleven cumulative Proof Depths form a post-ending mastery ladder with named
  combat clauses, sequential clears, escalating score/Memory rewards, saved
  personal progress, and a dedicated keyboard/controller Proof Ledger.
- Daily Chronicle provides one date-seeded challenge with a rotating contract,
  normalized account power, persistent bests and streaks, and a first-clear
  Memory bonus.
- Atomic current-draft saves support Continue / Load and Save & Return, including
  weapon build, route, combat state, and corruption recovery from backup.
- A persistent first-run Field Manual teaches keyboard and controller play,
  combat telegraphs, build crafting, saving, credits, and legal notices without
  leaving the game.

## Store-facing capability flags

- Single-player
- Full controller support (Xbox/PlayStation/Switch-style position layout)
- Keyboard and mouse
- Steam Achievements: definitions and stable API IDs prepared; Steamworks API
  hookup requires the final App ID and partner credentials.
- Languages: English and Simplified Chinese interface, subtitles, narrative,
  gameplay content, controller prompts, and settings. The first launch follows
  the Windows display language and the player can override it at runtime.

## Suggested tags

Action Roguelike, Roguelite, Pixel Graphics, 2D, Hack and Slash, Bullet Hell,
Story Rich, Comic Book, Controller, Singleplayer.

## Provisional Windows requirements for the free Beta

- Windows 10/11 64-bit
- OpenGL 3.3-capable graphics
- 4 GB RAM
- 200 MB available storage
- Keyboard/mouse or compatible XInput/SDL controller

These are public-Beta targets, not final store minimum specifications.
The integrated/older-GPU row in `p1-compatibility-matrix.md` must receive a real
hardware pass before publishing final requirements.

## Generative AI disclosure draft

Pre-generated AI-assisted content and development assistance are present.
OpenAI image generation produced this storefront cover, two character atlases, seven unlettered story
backgrounds, and ten Ink Art cinematic images. OpenAI Realtime
`gpt-realtime-2.1` and a local IndexTTS 2.5 pipeline produced the shipped
Japanese combat voices. 海绵音乐 / Hai Mian Music produced five AIGC soundtrack
tracks. OpenAI Codex (GPT-5) assisted with game design, code, text,
localization, production tooling, validation, and asset integration under the
project owner's direction and review. ComfyUI, Stable Diffusion, and MiniMax H3
also participated in the visual-resource/previsualization workflow; their
precise file-level attribution is a documented pre-release backfill gate. All
gameplay logic and shipped media are fixed offline content; the runtime uses no
live generative AI. The exact inventory and unresolved publisher sign-offs are
in `ai-content-disclosure.md`.
