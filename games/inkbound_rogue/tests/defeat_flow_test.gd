extends SceneTree

var game
var frames := 0
var restart_emitted := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("defeat_flow_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(40904)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	_run_test()
	return true


func _run_test() -> void:
	game._on_start_requested("standard")
	game.last_voice_id = ""
	game.player.invulnerable_time = 0.0
	if not game.player.take_damage(1.0, Vector2.LEFT, "test:light") or game.last_voice_id != "player_hit_light":
		_fail("non-fatal player damage did not request a pain performance")
		return
	game.player.invulnerable_time = 0.0
	game.player.health = game.player.max_health
	if not game.player.take_damage(game.player.max_health * 0.25, Vector2.LEFT, "test:heavy") or game.last_voice_id != "player_hit_heavy":
		_fail("heavy player damage did not select the heavy pain pool")
		return

	var mask = game.spawn_enemy("mask", game.player.global_position + Vector2(60, 0))
	mask.take_damage(0.5, Vector2.RIGHT)
	if game.last_voice_id != "enemy_mask_hit":
		_fail("masked enemy hit did not use the subdued humanoid pool")
		return
	mask.take_damage(mask.health + 1.0, Vector2.RIGHT)
	if game.last_voice_id != "enemy_mask_death_b":
		_fail("masked enemy fatal hit did not use selected B death take")
		return

	var blot = game.spawn_enemy("blot", game.player.global_position + Vector2(80, 0))
	blot.take_damage(0.5, Vector2.RIGHT)
	if game.last_voice_id != "enemy_ink_hit":
		_fail("ink enemy hit did not use the restrained creature pool")
		return
	blot.take_damage(blot.health + 1.0, Vector2.RIGHT)
	if game.last_voice_id != "enemy_ink_death_b":
		_fail("ink enemy fatal hit did not use selected B death take")
		return

	game.player.invulnerable_time = 0.0
	game.player.death_save_available = false
	game.player.health = 1.0
	game.last_voice_id = ""
	game.player.take_damage(10.0, Vector2.LEFT, "test:fatal")
	if not game.game_over or not paused or game.last_voice_id != "player_death_b":
		_fail("fatal damage did not pause the run and request Nara's selected B last words")
		return
	if not game.hud.game_over_visible or not game.hud.game_over_backdrop.visible or game.hud.game_over_panel.visible or game.hud.game_over_input_ready:
		_fail("defeat panel appeared before the screen-darkening phase completed")
		return

	if game.hud.restart_requested.is_connected(game._restart):
		game.hud.restart_requested.disconnect(game._restart)
	game.hud.restart_requested.connect(_on_restart_requested)
	game.hud._request_game_over_restart()
	if restart_emitted:
		_fail("defeat accepted restart during the protected fade")
		return

	game.hud.debug_finish_game_over_transition(false)
	if not game.hud.game_over_panel.visible or game.hud.game_over_input_ready or not game.hud.restart_button.disabled:
		_fail("defeat reveal did not retain its post-panel input lock")
		return
	game.hud.game_over_input_deadline_msec = 0
	Input.action_press("restart")
	game.hud._update_game_over_input_gate()
	if game.hud.game_over_input_ready:
		Input.action_release("restart")
		_fail("held pre-defeat input unlocked restart without a release edge")
		return
	Input.action_release("restart")
	game.hud._update_game_over_input_gate()
	if not game.hud.game_over_input_ready or game.hud.restart_button.disabled:
		_fail("released input did not arm restart after the minimum delay")
		return
	game.hud._request_game_over_restart()
	game.hud.debug_finish_popup_transition()
	if not restart_emitted:
		_fail("an armed defeat panel did not emit restart")
		return

	print("INKBOUND_DEFEAT_FLOW_OK player=light+heavy+B-death enemies=mask+ink positional=cooldown fade=1.25s restart=delay+release")
	_cleanup(0)


func _on_restart_requested() -> void:
	restart_emitted = true


func _fail(message: String) -> void:
	push_error("DEFEAT FLOW TEST FAILED: " + message)
	_cleanup(1)


func _cleanup(code: int) -> void:
	Input.action_release("restart")
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(code)
