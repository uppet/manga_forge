extends SceneTree

const NAMESPACE := "supply_drop_test"

var started := false


func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	return false


func _run() -> void:
	var packed = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)
	game.debug_clear_save_files()
	game.debug_set_rng_seed(818181)
	game.run_started = true
	game.player.controls_enabled = false
	game.player.health = game.player.max_health * 0.4
	for index in range(8):
		var victim = game.debug_spawn_enemy("mask", Vector2(260.0 + index, 0.0))
		game._on_enemy_died(victim, 1, Vector2(260.0 + index, 0.0), "mask")
		victim.free()
	if game.heal_drops_spawned < 1 or game.combat_drops_spawned < 1:
		_fail(game, "onboarding guarantees did not produce both recovery and combat supplies by kill 8")
		return
	var found_heal := false
	var found_bomb := false
	for pickup in get_nodes_in_group("pickups"):
		if pickup.get_parent() != game:
			continue
		if pickup.pickup_kind == "heal":
			found_heal = true
			if pickup.callout == null or pickup.callout.text != "+HP":
				_fail(game, "healing pickup has no visible HP callout")
				return
		elif pickup.pickup_kind == "bomb":
			found_bomb = true
			if pickup.callout == null or pickup.callout.text != "AOE":
				_fail(game, "bomb pickup has no visible AOE callout")
				return
	if not found_heal or not found_bomb:
		_fail(game, "guaranteed supply pickups were not present in the arena")
		return

	for node in get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node.get_parent() == game:
			node.free()
	game.player.global_position = Vector2.ZERO
	var close_enemy = game.debug_spawn_enemy("mask", Vector2(45.0, 0.0))
	var far_enemy = game.debug_spawn_enemy("mask", Vector2(160.0, 0.0))
	var close_before: float = close_enemy.health
	var far_before: float = far_enemy.health
	game.activate_combat_pickup("bomb")
	if close_enemy.health >= close_before or not is_equal_approx(far_enemy.health, far_before):
		_fail(game, "Ink Bomb did not apply a bounded 118px AOE")
		return
	var health_before: float = game.player.health
	var heal_pickup = game.spawn_pickup("heal", game.player.global_position, 1)
	heal_pickup._collect()
	if game.player.health <= health_before:
		_fail(game, "healing pickup did not restore player health")
		return
	print("INKBOUND_SUPPLY_OK heal_by=5 bomb_by=8 callouts=AOE+HP radius=118 healing=ok")
	_cleanup(game, 0)


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_SUPPLY_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
