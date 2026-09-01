extends SceneTree

const NAMESPACE := "field_manual_test"

var game
var frames := 0


func _initialize() -> void:
	game = _new_game()
	game.debug_clear_save_files()


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		if not _validate_manual_input_and_layout():
			return true
	elif frames == 6:
		if not _validate_navigation_pause_and_persistence():
			return true
	elif frames == 9:
		if not _validate_first_run_flow():
			return true
		print("INKBOUND_MANUAL_OK pages=5 first_run=auto keyboard=F1/H gamepad=LT pause=modal old_save=compatible persistence=ok credits=visible")
		_cleanup(0)
		return true
	return false


func _new_game():
	var packed = load("res://scenes/main.tscn")
	var instance = packed.instantiate()
	instance.test_mode = true
	instance.debug_set_save_namespace(NAMESPACE)
	root.add_child(instance)
	return instance


func _validate_manual_input_and_layout() -> bool:
	if not _has_keyboard_key("manual", KEY_F1) or not _has_keyboard_key("manual", KEY_H):
		return _fail("manual is not mapped to F1 and H")
	if not _has_gamepad_axis("manual", JOY_AXIS_TRIGGER_LEFT, 1.0):
		return _fail("manual is not mapped to the left trigger")
	if game.hud.FIELD_MANUAL_PAGES.size() != 5 or game.hud.manual_panel == null:
		return _fail("five-page manual UI was not built")
	game.run_started = true
	game.manually_paused = false
	game._sync_pause_state()
	game.hud.show_manual(0)
	game.hud.debug_finish_popup_transition()
	if not game.manual_open or not game.hud.manual_visible or not paused:
		return _fail("opening the manual did not pause a live run")
	var body: RichTextLabel = game.hud.manual_body_label
	if body.position.y + body.size.y + 8.0 > game.hud.manual_prev_button.position.y:
		return _fail("manual copy overlaps navigation buttons")
	if body.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART or not body.clip_contents:
		return _fail("manual copy is not safely wrapped and clipped")
	return true


func _validate_navigation_pause_and_persistence() -> bool:
	if not _content_fits(game.hud.manual_body_label):
		return _fail("first manual page overflows its text region (content=%.1f region=%.1f)" % [game.hud.manual_body_label.get_content_height(), _scaled_region_height(game.hud.manual_body_label)])
	for expected_page in range(1, 5):
		_send_action("move_right")
		if game.hud.manual_page != expected_page:
			return _fail("manual page navigation stopped before page %d" % (expected_page + 1))
		if not _content_fits(game.hud.manual_body_label):
			return _fail("manual page %d overflows its text region" % (expected_page + 1))
		if expected_page == 3 and game.hud.manual_body_label.text.find("Daily Chronicle") < 0:
			return _fail("return page does not explain Daily Chronicle access")
	if game.hud.manual_body_label.text.find("Godot Engine") < 0 or game.hud.manual_body_label.text.find("THIRD_PARTY_NOTICES.txt") < 0:
		return _fail("credits and legal notice are not visible in game")
	if not _content_fits(game.hud.manual_body_label):
		return _fail("credits page overflows its text region")
	_send_action("manual")
	game.hud.debug_finish_popup_transition()
	if game.manual_open or game.hud.manual_visible or paused or not game.field_manual_seen:
		return _fail("closing the live-run manual did not resume or mark it seen")
	game.field_manual_seen = true
	if not game._save_run():
		return _fail("manual completion state could not be saved")
	var payload: Dictionary = game._save_payload(game.save_generation + 1)
	payload.erase("field_manual_seen")
	game.field_manual_seen = true
	game._apply_save_payload(payload)
	if game.field_manual_seen:
		return _fail("older profiles without the manual field do not receive a safe default")
	game.field_manual_seen = true
	if not game._save_run():
		return _fail("manual completion state could not be resaved")
	game.free()
	game = _new_game()
	if not game.field_manual_seen:
		return _fail("manual completion state did not persist across boot")
	return true


func _validate_first_run_flow() -> bool:
	game.test_mode = false
	game.field_manual_seen = false
	game.lifetime_runs = 0
	game.completed_endings.clear()
	game.run_started = false
	game._on_start_requested("standard", "open-draft", "marginalia")
	game.hud.debug_finish_popup_transition()
	if not game.run_started or not game.onboarding_pending or not game.manual_open or not paused:
		return _fail("a fresh New Game did not stop at the field manual")
	if game.cutscene.active:
		return _fail("prologue started underneath first-run onboarding")
	_send_action("manual")
	game.hud.debug_finish_popup_transition()
	if game.onboarding_pending or game.manual_open or not game.field_manual_seen:
		return _fail("closing first-run onboarding did not commit its state")
	if not game.cutscene.active or game.cutscene.sequence_id != "prologue" or not paused:
		return _fail("first-run onboarding did not hand off to the prologue")
	var saved: Dictionary = game._read_save_file(game.save_path)
	if saved.get("state", "") != "ok" or not bool(saved.get("data", {}).get("field_manual_seen", false)):
		return _fail("first-run onboarding completion was not written atomically")
	game.cutscene._hide()
	game.manual_open = false
	game.manually_paused = true
	game._sync_pause_state()
	game.hud.show_manual(2)
	game.hud.debug_finish_popup_transition()
	if not paused or game.hud.pause_panel.visible:
		return _fail("manual opened from pause did not replace the pause panel")
	_send_action("manual")
	game.hud.debug_finish_popup_transition()
	if not paused or not game.hud.pause_panel.visible:
		return _fail("closing the manual did not return to the existing pause menu")
	return true


func _send_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game.hud._unhandled_input(event)


func _has_keyboard_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _has_gamepad_axis(action: String, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _scaled_region_height(label: Control) -> float:
	var design_height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 270))
	var render_height := float(label.get_viewport().get_texture().get_height())
	return label.size.y * maxf(1.0, render_height / maxf(1.0, design_height))


func _content_fits(label: RichTextLabel) -> bool:
	return label.get_content_height() <= _scaled_region_height(label)


func _fail(message: String) -> bool:
	push_error("INKBOUND_MANUAL_FAIL: %s" % message)
	_cleanup(1)
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
