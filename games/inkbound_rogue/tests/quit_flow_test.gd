extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		return _fail("main scene did not load")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("quit_flow_test")
	game.debug_clear_save_files()
	root.add_child(game)
	await process_frame
	if auto_accept_quit:
		return _fail("window close requests were not intercepted")

	game.run_started = false
	game.hud.show_title(game._meta_snapshot())
	if game.hud.title_navigation_actions.count("quit") != 1 or game.hud.title_quit_button == null:
		return _fail("title navigation has no quit action")
	game.request_quit_confirmation()
	game.hud.debug_finish_popup_transition(game.hud.quit_panel)
	if not game.hud.quit_visible or not game.quit_confirmation_active or not paused:
		return _fail("title quit did not open a modal confirmation")
	if game.hud.quit_from_active_run:
		return _fail("title quit incorrectly claimed an active draft")
	_send_escape()
	game.hud.debug_finish_popup_transition(game.hud.quit_panel)
	if game.hud.quit_visible or game.quit_confirmation_active:
		return _fail("Escape did not cancel quit confirmation")

	game.hud.hide_title()
	game.run_started = true
	game.manually_paused = false
	game.application_focused = true
	game._sync_pause_state()
	if paused:
		return _fail("active run did not resume before the close-request probe")
	game.request_quit_confirmation()
	game.hud.debug_finish_popup_transition(game.hud.quit_panel)
	if not game.hud.quit_from_active_run or not paused:
		return _fail("window close did not pause and protect an active draft")
	_send_gamepad_cancel()
	game.hud.debug_finish_popup_transition(game.hud.quit_panel)
	if game.hud.quit_visible or paused:
		return _fail("B/Circle did not cancel quit and resume the draft")

	game.manually_paused = true
	game._sync_pause_state()
	game.hud.debug_finish_popup_transition(game.hud.pause_panel)
	if game.hud.pause_navigation_buttons.size() != 5 or game.hud.pause_navigation_index != 0:
		return _fail("pause menu did not expose its five ordered actions")
	for _step in range(4):
		_send_action("move_down")
	if game.hud.pause_navigation_index != 4:
		return _fail("pause navigation could not reach Quit to Desktop")
	_send_enter()
	game.hud.debug_finish_popup_transition(game.hud.quit_panel)
	if not game.hud.quit_visible or game.hud.quit_waiting or game.hud.quit_navigation_index != 0:
		return _fail("pause Quit to Desktop did not open with Cancel selected")
	_send_action("move_right")
	_send_enter()
	if not game.hud.quit_visible or not game.hud.quit_waiting or (not game.quit_in_progress and not game.debug_quit_completed):
		return _fail("confirming quit did not enter the graceful shutdown state")
	await process_frame
	await process_frame
	if not game.debug_quit_completed or game.quit_in_progress:
		return _fail("graceful quit did not complete after analytics handoff")
	game.debug_clear_save_files()
	print("INKBOUND_QUIT_FLOW_OK title=confirmed pause=controller window_close=intercepted analytics=graceful")
	quit(0)


func _send_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_escape() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_enter() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ENTER
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_gamepad_cancel() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	game.hud._unhandled_input(event)


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("QUIT FLOW TEST FAILED: " + message)
	if is_instance_valid(game):
		game.debug_clear_save_files()
	paused = false
	quit(1)
