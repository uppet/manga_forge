# Accessibility and controller intent contract

Inkbound keeps accessibility options inside the same controller-navigable panel
as audio, display, language, and bindings. Every setting is local, contains no
account data, and persists in the atomic profile save. Profiles created before a
setting existed inherit the documented default without a schema break.

## Controller aim assist

`settings.aim_assist` has three sanitized strengths: Off (`0.0`), Gentle
(`0.25`), and Standard (`0.45`, default). It is applied only to gamepad attacks
and Ink Art after the player supplies a direction.

- Candidates must be alive, inside the action's useful range, and within 32
  degrees of the supplied direction.
- The best angular/distance candidate bends the direction by the selected
  strength; the result does not snap fully to the enemy.
- It never moves the player, presses an action, maintains a lock, or changes
  mouse/keyboard aiming.

This narrow contract helps short-range slashes survive analogue-stick error
without replacing player intent or trivializing positioning.

## Reduced flashes

`settings.reduced_flashes` defaults to Off. When enabled, player damage feedback
uses one slower, softer color pulse; enemy charge/parry/teleport warnings hold a
stable tinted color; hit and status flashes are softened; and comic-panel
transition flashes use lower opacity and a longer fade.

The option does not remove spatial telegraph arcs, silhouettes, squash/stretch,
warning sounds, hostile-projectile cyan trails, danger-zone geometry, or hit
confirmation. Threat information therefore remains readable without relying on
rapid luminance alternation.

## Regression gates

`tests/accessibility_test.gd` verifies the aim cone/range, blend rather than
lock-on, Off behavior, damage-flash cycle count, stable enemy warnings, Chinese
labels, and settings-panel containment. `tests/save_recovery_test.gd` verifies
that both settings survive backup recovery and that older profiles receive safe
defaults. Run them on the Windows host with `host_game.py accessibility-test`
and `host_game.py save-test`.
