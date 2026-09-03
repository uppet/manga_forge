extends SceneTree

const Localization = preload("res://scripts/localization.gd")
const NAMESPACE := "accessibility_test"

var started := false
var game


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_test()
	return false


func _run_test() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)
	game.debug_clear_save_files()

	if not is_equal_approx(float(game.settings.get("aim_assist", -1.0)), 0.45):
		_fail("controller aim assist is not enabled at the restrained Standard default")
		return
	if game.settings.get("reduced_flashes", true) == true:
		_fail("reduced flashes unexpectedly replaced the authored default")
		return

	var origin: Vector2 = game.player.global_position
	var intended = game.debug_spawn_enemy("mask", origin + Vector2(60.0, 18.0))
	var outside_cone = game.debug_spawn_enemy("mask", origin + Vector2(42.0, 48.0))
	var raw := Vector2.RIGHT
	var corrected: Vector2 = game.assisted_aim_direction(origin, raw, 90.0)
	var intended_direction: Vector2 = (intended.global_position - origin).normalized()
	if corrected.y <= 0.01 or absf(corrected.angle_to(intended_direction)) >= absf(raw.angle_to(intended_direction)):
		_fail("Standard controller assist did not gently correct toward the intended in-cone target")
		return
	if absf(corrected.angle()) >= deg_to_rad(16.0):
		_fail("controller assist overrode rather than blended right-stick intent")
		return
	outside_cone.global_position = origin + Vector2(34.0, 60.0)
	intended.global_position = origin + Vector2(180.0, 40.0)
	if not game.assisted_aim_direction(origin, raw, 90.0).is_equal_approx(raw):
		_fail("aim assist selected a target outside its range or 32-degree intent cone")
		return
	game.settings["aim_assist"] = 0.0
	intended.global_position = origin + Vector2(60.0, 18.0)
	if not game.assisted_aim_direction(origin, raw, 90.0).is_equal_approx(raw):
		_fail("Off did not disable controller aim correction")
		return

	game.settings["reduced_flashes"] = true
	if game.player.damage_flash_cycles() != 1:
		_fail("reduced flashes did not collapse the player damage strobe")
		return
	var calm_a: Color = intended.charge_warning_color(Color("d33037"), 0)
	var calm_b: Color = intended.charge_warning_color(Color("d33037"), 1)
	if calm_a != calm_b:
		_fail("reduced flashes left enemy charge warnings alternating")
		return
	game.settings["reduced_flashes"] = false
	if game.player.damage_flash_cycles() != 3:
		_fail("authored damage response did not restore after disabling reduced flashes")
		return
	if intended.charge_warning_color(Color("d33037"), 0) == intended.charge_warning_color(Color("d33037"), 1):
		_fail("authored enemy charge warning lost its two visual phases")
		return

	game.debug_set_language(Localization.LANGUAGE_CHINESE)
	# test_mode starts directly in the arena; enter the real title state before
	# probing title-owned secondary panels and their background controls.
	game.run_started = false
	game.hud.show_title(game._meta_snapshot())
	game.hud.show_settings()
	game.hud.debug_finish_popup_transition()
	var aim_row: int = game.hud.SETTINGS_ROWS.find(["aim_assist", "CONTROLLER AIM ASSIST"])
	var flashes_row: int = game.hud.SETTINGS_ROWS.find(["reduced_flashes", "REDUCED FLASHES"])
	var cutin_row: int = game.hud.SETTINGS_ROWS.find(["ink_art_cutins", "INK ART CUT-INS"])
	var analytics_row: int = game.hud.SETTINGS_ROWS.find(["analytics_consent", "ANONYMOUS ANALYTICS"])
	if aim_row < 0 or flashes_row < 0 or cutin_row < 0 or analytics_row < 0:
		_fail("accessibility options are absent from the controller-navigable Settings list")
		return
	if game.hud.settings_buttons[aim_row].text.find("手柄瞄准辅助") < 0 or game.hud.settings_buttons[flashes_row].text.find("减弱闪烁") < 0 or game.hud.settings_buttons[cutin_row].text.find("墨术全屏特写") < 0 or game.hud.settings_buttons[analytics_row].text.find("匿名使用数据") < 0:
		_fail("accessibility options are not translated into Simplified Chinese")
		return
	if not bool(game.settings.get("ink_art_cutins", false)):
		_fail("Ink Art cut-ins are not enabled by default")
		return
	game._on_setting_adjusted("ink_art_cutins", 1)
	if bool(game.settings.get("ink_art_cutins", true)):
		_fail("Ink Art cut-in setting could not be disabled")
		return
	game._on_setting_adjusted("ink_art_cutins", 1)
	var last_button: Button = game.hud.settings_buttons[game.hud.settings_buttons.size() - 1]
	if last_button.position.y + last_button.size.y > game.hud.settings_panel.size.y - 22.0:
		_fail("expanded Settings list overlaps its footer (button_bottom=%.1f footer_top=%.1f)" % [last_button.position.y + last_button.size.y, game.hud.settings_panel.size.y - 22.0])
		return
	if not _validate_modal_input_isolation():
		return

	print("INKBOUND_ACCESSIBILITY_OK controller_assist=off/gentle/standard intent_cone=32deg reduced_flashes=damage/charge/cutscene ink_art_cutins=default_on/toggle settings=en/zh_CN modal_input=mouse+keyboard+gamepad background_buttons=isolated")
	_cleanup(0)


func _validate_modal_input_isolation() -> bool:
	if not game.hud.settings_visible or game.hud._active_modal_panel() != game.hud.settings_panel:
		_fail("Settings did not register as the active modal panel")
		return false
	if game.hud.settings_buttons[0].disabled:
		_fail("active Settings controls remained disabled after the opening fade")
		return false
	for button in game.hud.title_navigation_buttons:
		if not button.disabled:
			_fail("a title button remained mouse-interactive behind Settings: %s" % button.text)
			return false
	game.last_sound_id = ""
	game.hud._on_ui_button_hovered(game.hud.start_button)
	if game.last_sound_id == "ui_move":
		_fail("hover feedback leaked from a title button behind Settings")
		return false

	game.hud.show_bindings()
	game.hud.debug_finish_popup_transition()
	if not game.hud.bindings_visible or game.hud.settings_visible or game.hud._active_modal_panel() != game.hud.bindings_panel:
		_fail("Control Bindings did not replace Settings as the top modal")
		return false
	if game.hud.binding_buttons[0].disabled:
		_fail("active Control Bindings controls remained disabled")
		return false
	for button in game.hud.settings_buttons:
		if not button.disabled:
			_fail("a Settings button remained interactive behind Control Bindings")
			return false

	game.hud.hide_bindings()
	game.hud.debug_finish_popup_transition()
	if not game.hud.settings_visible or game.hud.bindings_visible or game.hud._active_modal_panel() != game.hud.settings_panel:
		_fail("closing Control Bindings did not restore the Settings modal")
		return false
	game.hud.hide_settings()
	game.hud.debug_finish_popup_transition()
	if game.hud.settings_visible or game.hud._active_modal_panel() != null:
		_fail("closing Settings left a stale modal owner")
		return false
	if game.hud.start_button.disabled or game.hud.settings_button.disabled:
		_fail("closing Settings did not restore title button interaction")
		return false

	game.hud._toggle_achievements()
	game.hud.debug_finish_popup_transition()
	if not game.hud.achievements_visible or game.hud._active_modal_panel() != game.hud.achievements_panel:
		_fail("Achievements did not register as the active modal panel")
		return false
	if game.hud.achievements_panel.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("Achievements does not stop pointer events inside its modal bounds")
		return false
	for button in game.hud.title_navigation_buttons:
		if not button.disabled:
			_fail("a title button remained mouse-interactive behind Achievements: %s" % button.text)
			return false
	game.last_sound_id = ""
	game.hud._on_ui_button_hovered(game.hud.settings_button)
	if game.last_sound_id == "ui_move":
		_fail("hover feedback leaked from a title button behind Achievements")
		return false
	game.hud._toggle_achievements()
	game.hud.debug_finish_popup_transition()
	if game.hud.achievements_visible or game.hud._active_modal_panel() != null:
		_fail("closing Achievements left a stale modal owner")
		return false
	if game.hud.start_button.disabled or game.hud.settings_button.disabled:
		_fail("closing Achievements did not restore title button interaction")
		return false
	return true


func _fail(message: String) -> void:
	push_error("INKBOUND_ACCESSIBILITY_FAIL: " + message)
	_cleanup(1)


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	TranslationServer.set_locale(Localization.LANGUAGE_ENGLISH)
	paused = false
	quit(exit_code)
