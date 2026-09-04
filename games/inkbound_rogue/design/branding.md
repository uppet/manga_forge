# Brand identity and rename contract

## Public identity

- English product name: **Last Inkwarden**
- Simplified Chinese product name: **墨卫残章**
- Optional promotional line: **Blade of the Blank Page / 空白页之刃**
- Windows executable: `LastInkwarden.exe`
- Publisher/workspace identity: **Manga Forge**

Use the localized product names as equivalents, not as a title plus subtitle.
The promotional line may appear below the logo or in campaign copy, but it is
not part of the formal store product name. Public screenshots, reports, release
notes, store copy, and distributable files must not present the former name as
the current product identity.

## Visual usage

Write the English logo as `LAST INKWARDEN` and the Simplified Chinese logo as
`墨卫残章`. Preserve the established deep-ink, ivory, crimson, and gold palette.
Do not bake either language into narrative backgrounds: the runtime title text
must remain localizable and captures should be generated once per locale.

## Compatibility identifiers

The following names are deliberately retained as private compatibility
interfaces during the rename:

- source/runtime directory `games/inkbound_rogue/`;
- `Inkbound*` GDScript class names and `INKBOUND_*` automated gate tokens;
- `INKBOUND_*` launcher and GameAnalytics environment variables;
- the `inkbound_rogue` key in local GameAnalytics build configuration;
- `user://inkbound_*.json` profile and checkpoint filenames.

Changing these identifiers adds migration risk without changing the public
brand. New public-facing files must use Last Inkwarden naming; new private
interfaces should use neutral or Last Inkwarden naming where practical.

## Existing profile migration

Changing Godot's application name changes the default `user://` directory.
`scripts/brand_migration.gd` therefore runs before the other autoloads and
copies missing profile, checkpoint, and analytics files from the previous
Godot application-data directory on first launch. Existing files in the new
directory always win. Historical logs and local playtest recordings are left
in place, and the old directory is never deleted.

This rename contract was adopted on 2026-09-04 for version `0.23.4-alpha`.
