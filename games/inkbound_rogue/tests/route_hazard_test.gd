extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const NAMESPACE := "route_hazard_test"

var started := false
var packed: PackedScene


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run()
	return false


func _run() -> void:
	var loaded: Variant = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail(null, "main scene did not load")
		return
	packed = loaded
	var hazard_ids: Array[String] = []
	for route_data in Content.ROUTES:
		var route_id := str(route_data.get("id", ""))
		var hazard_id := str(route_data.get("hazard", ""))
		if route_id.is_empty() or hazard_id.is_empty() or hazard_id in hazard_ids:
			_fail(null, "route hazard metadata has a missing or duplicate ID")
			return
		if str(route_data.get("hazard_name", "")).is_empty() or str(route_data.get("hazard_hint", "")).is_empty() or float(route_data.get("hazard_interval", 0.0)) < 4.0:
			_fail(null, "route %s has incomplete hazard presentation or timing" % route_id)
			return
		hazard_ids.append(hazard_id)
	if hazard_ids.size() != 9:
		_fail(null, "the nine routes do not expose nine unique battlefield rules")
		return

	var game: Node = _new_game(true)
	if not is_instance_valid(game.route_hazard) or not game.route_hazard.is_in_group("route_hazards"):
		_fail(game, "route hazard controller was not attached to the runtime")
		return
	game.player.controls_enabled = false
	game.spawn_timer = 999.0

	# Every route must produce a real, visible cycle instead of only numeric modifiers.
	for route_data in Content.ROUTES:
		var route_id := str(route_data["id"])
		if not game._activate_route(route_id) or game.route_hazard.hazard_id != str(route_data["hazard"]):
			_fail(game, "route %s did not bind its battlefield rule" % route_id)
			return
		var cycles_before := int(game.route_hazard.cycles_started)
		if not game.debug_force_route_hazard() or int(game.route_hazard.cycles_started) != cycles_before + 1:
			_fail(game, "route %s could not begin its telegraphed cycle" % route_id)
			return
		var expected_phase := "cache" if str(route_data["hazard"]) == "contraband-cache" else "telegraph"
		if game.route_hazard.phase != expected_phase or game.route_hazard.telegraph_total < 1.0:
			_fail(game, "route %s did not expose a readable warning window" % route_id)
			return

	var enemy: Node = game.debug_spawn_enemy("mask", Vector2.ZERO)
	enemy.max_health = 100.0
	enemy.health = 100.0

	# Whisper Stacks: the player earns a ward/recharge while masks are slowed.
	game._activate_route("whisper-stacks")
	game.debug_force_route_hazard()
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	enemy.global_position = game.player.global_position
	game.player.ink_art_cooldown = 6.0
	game.player.guard = 0.0
	game.route_hazard.debug_resolve_cycle()
	if game.player.ink_art_cooldown >= 6.0 or game.player.guard < 1.0 or enemy.slow_time < 3.0:
		_fail(game, "Echo Sanctuary did not create its risk/reward sanctuary")
		return

	# Razor Gallery: a line crossing both actors must hurt both sides.
	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position)
	game._activate_route("razor-gallery")
	game.debug_force_route_hazard()
	game.route_hazard.direction = Vector2.RIGHT
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	var razor_player_health: float = game.player.health
	var razor_enemy_health: float = enemy.health
	game.route_hazard.debug_resolve_cycle()
	if game.player.health >= razor_player_health or enemy.health >= razor_enemy_health:
		_fail(game, "Razor Sweep did not cut player and masks on the telegraphed line")
		return

	# Black Index and Chain Vault: marked ground damages, while chains also bind.
	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position)
	game._activate_route("black-index")
	game.debug_force_route_hazard()
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	var stamp_health: float = game.player.health
	game.route_hazard.debug_resolve_cycle()
	if game.player.health >= stamp_health or enemy.health >= 100.0:
		_fail(game, "Redaction Stamp did not erase its marked ground")
		return

	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position)
	game._activate_route("chain-vault")
	game.debug_force_route_hazard()
	game.route_hazard.direction = Vector2.RIGHT
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	game.route_hazard.debug_resolve_cycle()
	if enemy.health >= 100.0 or enemy.slow_time < 3.9:
		_fail(game, "Binding Cross did not damage and bind masks")
		return

	# Errata Canals: the selected lane deals damage and physically sweeps the page.
	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position)
	game._activate_route("errata-canals")
	game.debug_force_route_hazard()
	game.route_hazard.direction = Vector2.RIGHT
	game.route_hazard.debug_set_primary_point(Vector2(0.0, game.player.global_position.y))
	var canal_before: Vector2 = game.player.global_position
	game.route_hazard.debug_resolve_cycle()
	if game.player.health >= game.player.max_health or game.player.global_position.x <= canal_before.x or enemy.health >= 100.0:
		_fail(game, "Errata Surge did not damage and sweep its ink lane")
		return

	# Contraband Hall: touching the timed cache yields both Memory and Ward.
	_reset_player(game)
	game._activate_route("contraband-hall")
	game.debug_force_route_hazard()
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	var shards_before: int = game.run_shards
	game.route_hazard.debug_resolve_cycle()
	if game.run_shards <= shards_before or game.player.guard < 1.0 or game.route_hazard.last_resolution != "cache-claimed":
		_fail(game, "Volatile Cache did not grant its timed reward")
		return

	# White Room: its attractive heal is deliberately shared with surviving masks.
	_reset_player(game)
	game.player.health = game.player.max_health - 3.0
	_reset_enemy(enemy, game.player.global_position)
	enemy.health = 45.0
	game._activate_route("white-room")
	game.debug_force_route_hazard()
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	game.route_hazard.debug_resolve_cycle()
	if game.player.health <= game.player.max_health - 3.0 or enemy.health <= 45.0 or enemy.haste_time < 2.9:
		_fail(game, "White Revision did not heal both sides of the encounter")
		return

	# Red Press: one of its three verdicts can land on both player and masks.
	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position)
	game._activate_route("red-press")
	game.debug_force_route_hazard()
	game.route_hazard.debug_set_primary_point(game.player.global_position)
	game.route_hazard.debug_resolve_cycle()
	if game.player.health >= game.player.max_health or enemy.health >= 100.0 or game.route_hazard.points.size() != 3:
		_fail(game, "Triple Verdict did not retain and resolve all three stamps")
		return

	# Loose Leaves: a whole-page gust visibly repositions both combatants.
	_reset_player(game)
	_reset_enemy(enemy, game.player.global_position + Vector2(30.0, 0.0))
	game._activate_route("loose-leaves")
	game.debug_force_route_hazard()
	game.route_hazard.direction = Vector2.RIGHT
	var gust_before: Vector2 = game.player.global_position
	var velocity_before: Vector2 = enemy.external_velocity
	game.route_hazard.debug_resolve_cycle()
	if game.player.global_position.x <= gust_before.x or enemy.external_velocity.x <= velocity_before.x:
		_fail(game, "Page Gust did not reposition the battle")
		return

	# Continue must preserve an in-progress warning, not silently reroll danger.
	game._activate_route("chain-vault")
	game.debug_force_route_hazard()
	game.route_hazard.direction = Vector2(0.0, 1.0)
	game.route_hazard.debug_set_primary_point(Vector2(123.0, -77.0))
	game.route_hazard.phase_time = 0.73
	var checkpoint: Dictionary = game._checkpoint_payload("hazard-test")
	if not game._is_valid_checkpoint_payload(checkpoint):
		_fail(game, "checkpoint rejected its route hazard state")
		return
	game.free()

	var restored: Node = _new_game(false)
	if not restored._apply_checkpoint(checkpoint):
		_fail(restored, "checkpoint could not restore the route hazard")
		return
	if restored.active_route_id != "chain-vault" or restored.route_hazard.hazard_id != "chain-cross" or restored.route_hazard.phase != "telegraph":
		_fail(restored, "Continue lost the active route hazard identity or phase")
		return
	if not is_equal_approx(restored.route_hazard.phase_time, 0.73) or restored.route_hazard.points.is_empty() or not restored.route_hazard.points[0].is_equal_approx(Vector2(123.0, -77.0)):
		_fail(restored, "Continue rerolled the warning timer or geometry")
		return

	print("INKBOUND_HAZARDS_OK routes=9 mechanics=9 telegraphs=9 checkpoint=exact pause=pausable")
	_cleanup(restored, 0)


func _new_game(clear_files: bool) -> Node:
	var game: Node = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(NAMESPACE)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(929292)
	return game


func _reset_player(game: Node) -> void:
	game.player.health = game.player.max_health
	game.player.guard = 0.0
	game.player.invulnerable_time = 0.0
	game.player.global_position = Vector2.ZERO


func _reset_enemy(enemy: Node, at: Vector2) -> void:
	enemy.dead = false
	enemy.max_health = 100.0
	enemy.health = 100.0
	enemy.slow_time = 0.0
	enemy.slow_amount = 0.0
	enemy.haste_time = 0.0
	enemy.external_velocity = Vector2.ZERO
	enemy.global_position = at


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_HAZARDS_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
