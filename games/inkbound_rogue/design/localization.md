# Localization contract

Inkbound ships English (`en`) and Simplified Chinese (`zh_CN`). English source
text is canonical for content IDs, simulation state, checkpoints, and profile
history. `scripts/localization.gd` registers the Chinese catalogue as a Godot
`Translation` before the HUD is built; dynamic strings explicitly translate
their content fragments before formatting.

## Player setting

`settings.language` accepts exactly `auto`, `en`, or `zh_CN`.

- `auto` selects Chinese when `OS.get_locale_language()` returns `zh`, otherwise
  English.
- English and Simplified Chinese are explicit runtime overrides.
- The choice is saved in profile schema 12. Profiles created before the field
  existed safely inherit `auto`; invalid values are sanitized to `auto`.
- Switching language refreshes the title shell, settings, manual, active
  technique/relic/event draft, HUD build/objective/directive state, result copy,
  and an active cutscene without restarting the run.

## Windows font contract

The UI uses a `SystemFont` chain headed by Microsoft YaHei UI and Microsoft
YaHei, followed by Noto/Source Han/Droid CJK fallbacks and Arial. This keeps the
Windows export self-contained without redistributing a third-party font file.
The same font is used by Controls and canvas-drawn combat/hazard callouts.

## Regression gates

`tests/localization_test.gd` runs with the real Windows renderer and verifies:

- explicit Chinese selection, runtime English switching, and persistence;
- compatibility with older profiles lacking the language field;
- CJK glyph availability through the configured system font;
- translated title, settings row, techniques, event choices, and story text;
- contained settings and technique-card layout.

`tests/capture_localization_ui.gd` writes four renderer proofs for the Chinese
title, settings, upgrade cards, and prologue. The Windows host entry points are
`host_game.py localization-test` and `host_game.py capture-localization`.
