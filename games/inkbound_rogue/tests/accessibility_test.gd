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
	game.hud.show_settings()
	game.hud.debug_finish_popup_transition()
	var aim_row: int = game.hud.SETTINGS_ROWS.find(["aim_assist", "CONTROLLER AIM ASSIST"])
	var flashes_row: int = game.hud.SETTINGS_ROWS.find(["reduced_flashes", "REDUCED FLASHES"])
	var analytics_row: int = game.hud.SETTINGS_ROWS.find(["analytics_consent", "ANONYMOUS ANALYTICS"])
	if aim_row < 0 or flashes_row < 0 or analytics_row < 0:
		_fail("accessibility options are absent from the controller-navigable Settings list")
		return
	if game.hud.settings_buttons[aim_row].text.find("手柄瞄准辅助") < 0 or game.hud.settings_buttons[flashes_row].text.find("减弱闪烁") < 0 or game.hud.settings_buttons[analytics_row].text.find("匿名使用数据") < 0:
		_fail("accessibility options are not translated into Simplified Chinese")
		return
	var last_button: Button = game.hud.settings_buttons[game.hud.settings_buttons.size() - 1]
	if last_button.position.y + last_button.size.y > game.hud.settings_panel.size.y - 22.0:
		_fail("expanded Settings list overlaps its footer")
		return

	print("INKBOUND_ACCESSIBILITY_OK controller_assist=off/gentle/standard intent_cone=32deg reduced_flashes=damage/charge/cutscene settings=en/zh_CN")
	_cleanup(0)


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
