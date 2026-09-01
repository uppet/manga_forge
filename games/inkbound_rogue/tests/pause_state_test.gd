extends SceneTree

const SETTLE_FRAMES := 12
const FROZEN_FRAMES := 36

class AlwaysProbe:
	extends Node
	var callback: Callable

	func _process(delta: float) -> void:
		callback.call(delta)


var game: Node
var enemy: Node2D
var probe: AlwaysProbe
var bootstrapped := false
var phase := 0
var phase_frames := 0
var snapshot := {}


func _process(_delta: float) -> bool:
	if not bootstrapped:
		bootstrapped = true
		_setup()
	return false


func _setup() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("pause_state_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(727272)
	game.player.controls_enabled = false
	game.run_started = true
	game._activate_route("razor-gallery")
	game.debug_force_route_hazard()
	game.debug_start_directive("whisper-circle")
	game.player.global_position = game.directive_zone.global_position
	game._sync_pause_state()
	for candidate in get_nodes_in_group("enemies"):
		if candidate.get_parent() == game:
			enemy = candidate
			break
	if not is_instance_valid(enemy):
		_fail("no enemy available for movement probe")
		return
	probe = AlwaysProbe.new()
	probe.process_mode = Node.PROCESS_MODE_ALWAYS
	probe.callback = _advance_test
	root.add_child(probe)
	snapshot = _capture()


func _advance_test(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(enemy):
		return
	phase_frames += 1
	match phase:
		0:
			if phase_frames >= SETTLE_FRAMES:
				if game.elapsed <= float(snapshot["elapsed"]) or enemy.global_position.is_equal_approx(snapshot["enemy_position"]):
					_fail("unpaused simulation did not advance before the pause probe")
					return
				_send_pause_key()
				if not game.manually_paused or not paused:
					_fail("Escape did not enter manual pause")
					return
				game.player.attack_cooldown = 0.75
				snapshot = _capture()
				_next_phase()
		1:
			if phase_frames >= FROZEN_FRAMES:
				if not _matches_snapshot(snapshot):
					_fail("manual pause allowed gameplay state to advance")
					return
				if game.can_process() or game.player.can_process() or enemy.can_process() or not game.hud.can_process():
					_fail("manual pause process modes are inconsistent")
					return
				_send_pause_gamepad()
				if game.manually_paused or paused:
					_fail("gamepad Start did not resume manual pause")
					return
				snapshot = _capture()
				_next_phase()
		2:
			if phase_frames >= SETTLE_FRAMES:
				if game.elapsed <= float(snapshot["elapsed"]):
					_fail("simulation did not resume after manual pause")
					return
				game._on_level_up(game.player.level)
				if not game.choosing_upgrade or not paused or not game.hud.upgrade_visible:
					_fail("upgrade selection did not enter modal pause")
					return
				game.player.attack_cooldown = 0.75
				snapshot = _capture()
				_next_phase()
		3:
			if phase_frames >= FROZEN_FRAMES:
				if not _matches_snapshot(snapshot):
					_fail("upgrade selection allowed gameplay state to advance")
					return
				_send_upgrade_gamepad()
				if game.choosing_upgrade or paused or game.hud.upgrade_visible:
					_fail("gamepad upgrade choice did not resume the run")
					return
				snapshot = _capture()
				_next_phase()
		4:
			if phase_frames >= SETTLE_FRAMES:
				if game.elapsed <= float(snapshot["elapsed"]) or game.player.attack_cooldown >= float(snapshot["attack_cooldown"]):
					_fail("simulation did not advance after upgrade selection")
					return
				game.offer_relic_draft("PAUSE REGRESSION RELIC")
				if not game.choosing_relic or not paused or not game.hud.relic_draft_visible:
					_fail("relic selection did not enter modal pause")
					return
				game.player.attack_cooldown = 0.75
				snapshot = _capture()
				_next_phase()
		5:
			if phase_frames >= FROZEN_FRAMES:
				if not _matches_snapshot(snapshot):
					_fail("relic selection allowed gameplay state to advance")
					return
				_send_relic_gamepad()
				if game.choosing_relic or paused or game.hud.relic_draft_visible:
					_fail("gamepad relic choice did not resume the run")
					return
				snapshot = _capture()
				_next_phase()
		6:
			if phase_frames >= SETTLE_FRAMES:
				if game.elapsed <= float(snapshot["elapsed"]) or game.player.attack_cooldown >= float(snapshot["attack_cooldown"]):
					_fail("simulation did not advance after relic selection")
					return
				game._set_input_mode(false)
				game.debug_set_application_focus(false)
				if game.application_focused or not game.manually_paused or not paused or game.hud.input_enabled or game.cutscene.input_enabled:
					_fail("focus loss did not gate every input layer and pause gameplay")
					return
				game.player.attack_cooldown = 0.75
				snapshot = _capture()
				_next_phase()
		7:
			if phase_frames >= FROZEN_FRAMES:
				if not _matches_snapshot(snapshot):
					_fail("focus loss allowed gameplay state to advance")
					return
				_send_pause_gamepad()
				var background_event := InputEventJoypadButton.new()
				background_event.button_index = JOY_BUTTON_A
				background_event.pressed = true
				game._input(background_event)
				if not game.manually_paused or not paused or game.using_gamepad:
					_fail("background gamepad input reached the game or HUD")
					return
				game.debug_set_application_focus(true)
				if not game.application_focused or not game.hud.input_enabled or not game.cutscene.input_enabled or not game.manually_paused or not paused:
					_fail("focus restore did not re-enable input while retaining explicit pause")
					return
				_send_pause_gamepad()
				if game.manually_paused or paused:
					_fail("explicit pause input did not resume after focus restore")
					return
				snapshot = _capture()
				_next_phase()
		8:
			if phase_frames >= SETTLE_FRAMES:
				if game.elapsed <= float(snapshot["elapsed"]):
					_fail("simulation did not resume after focus restore")
					return
				print("INKBOUND_PAUSE_OK menu=frozen upgrade=frozen relic=frozen focus=frozen background_gamepad=ignored restore=explicit keyboard=ok gamepad=ok frames=%d" % (FROZEN_FRAMES * 4))
				_cleanup(0)
				return


func _capture() -> Dictionary:
	return {
		"elapsed": game.elapsed,
		"spawn_timer": game.spawn_timer,
		"attack_cooldown": game.player.attack_cooldown,
		"player_position": game.player.global_position,
		"enemy_position": enemy.global_position,
		"directive_progress": game.directive_progress,
		"hazard_phase": game.route_hazard.phase,
		"hazard_phase_time": game.route_hazard.phase_time,
		"hazard_cooldown": game.route_hazard.cooldown,
	}


func _matches_snapshot(expected: Dictionary) -> bool:
	return (
		is_equal_approx(game.elapsed, float(expected["elapsed"]))
		and is_equal_approx(game.spawn_timer, float(expected["spawn_timer"]))
		and is_equal_approx(game.player.attack_cooldown, float(expected["attack_cooldown"]))
		and game.player.global_position.is_equal_approx(expected["player_position"])
		and enemy.global_position.is_equal_approx(expected["enemy_position"])
		and is_equal_approx(game.directive_progress, float(expected["directive_progress"]))
		and game.route_hazard.phase == str(expected["hazard_phase"])
		and is_equal_approx(game.route_hazard.phase_time, float(expected["hazard_phase_time"]))
		and is_equal_approx(game.route_hazard.cooldown, float(expected["hazard_cooldown"]))
	)


func _send_pause_key() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_pause_gamepad() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_START
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_upgrade_gamepad() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_X
	event.pressed = true
	game.hud._unhandled_input(event)


func _send_relic_gamepad() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = true
	game.hud._unhandled_input(event)


func _next_phase() -> void:
	phase += 1
	phase_frames = 0


func _fail(message: String) -> void:
	push_error("INKBOUND_PAUSE_FAIL: " + message)
	_cleanup(1)


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(probe):
		probe.queue_free()
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
