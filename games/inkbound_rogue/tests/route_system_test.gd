extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var started := false
var packed: PackedScene
var profile_name := "route_system_test"


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_route_test()
	return false


func _run_route_test() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	packed = loaded
	if Content.ROUTES.size() != 9:
		_fail("route database does not contain exactly nine routes")
		return
	var route_ids: Array[String] = []
	var hazard_ids: Array[String] = []
	for chapter in range(1, 4):
		var chapter_routes := Content.routes_for_chapter(chapter)
		if chapter_routes.size() != 3:
			_fail("chapter %d does not offer exactly three routes" % chapter)
			return
		for route_data in chapter_routes:
			var route_id := str(route_data.get("id", ""))
			var hazard_id := str(route_data.get("hazard", ""))
			if route_id.is_empty() or route_id in route_ids or route_data.get("enemy_bias", []).is_empty() or hazard_id.is_empty() or hazard_id in hazard_ids:
				_fail("route metadata has a missing ID, duplicate, or empty enemy bias")
				return
			route_ids.append(route_id)
			hazard_ids.append(hazard_id)

	var game = _new_game(true)
	if not game._offer_route(1) or not game.choosing_event or not paused or not game.hud.event_visible:
		_fail("act-one route choice did not enter a paused modal state")
		return
	if game.can_process() or game.player.can_process():
		_fail("route choice left the simulation processing")
		return
	if game.current_event.get("options", []).size() != 3:
		_fail("route modal did not expose three choices")
		return
	game.hud._choose_event(1)
	if paused or game.choosing_event or game.active_route_id != "razor-gallery":
		_fail("route selection did not activate Razor Gallery and resume play")
		return
	if game.arena.route_id != "razor-gallery" or game.discovered_routes != ["razor-gallery"] or game.route_hazard.hazard_id != "razor-sweep":
		_fail("route selection did not update the arena and persistent discovery")
		return
	if not is_equal_approx(game.route_enemy_health, 1.08) or game.route_enemy_bias.size() != 2 or game.route_score_multiplier <= 1.0:
		_fail("Razor Gallery gameplay modifiers were not configured")
		return
	game.wave = 1
	var routed_enemy = game.spawn_enemy("mask", Vector2(80, 0))
	if not is_equal_approx(routed_enemy.max_health, 4.0 * 1.08):
		_fail("route health modifier was not applied to spawned enemies")
		return
	var biased := 0
	var seen_bias: Array[String] = []
	game.debug_set_rng_seed(808080)
	for _index in range(200):
		var kind: String = game._roll_enemy_kind()
		if kind in ["dasher", "brute"]:
			biased += 1
			if kind not in seen_bias:
				seen_bias.append(kind)
	# Early pages deliberately scale route bias to 45% of its full value so the
	# Page 3 ranged/readability fix cannot be bypassed by a route. Compare with
	# the same seed and roster without route bias instead of asserting the old
	# late-page absolute count.
	var baseline_biased := 0
	var configured_bias_chance: float = game.route_enemy_bias_chance
	game.route_enemy_bias_chance = 0.0
	game.debug_set_rng_seed(808080)
	for _index in range(200):
		if game._roll_enemy_kind() in ["dasher", "brute"]:
			baseline_biased += 1
	game.route_enemy_bias_chance = configured_bias_chance
	if biased < baseline_biased + 25 or seen_bias.size() != 2:
		_fail("route enemy bias did not materially alter the encounter roster")
		return

	if not game._offer_route(2):
		_fail("act-two route choice did not open")
		return
	game.hud._choose_event(1)
	if game.active_route_id != "errata-canals" or game.route_spawn_interval >= 1.0:
		_fail("Errata Canals did not activate its faster encounter tide")
		return
	if not game._offer_route(3):
		_fail("act-three route choice did not open")
		return
	game.hud._choose_event(1)
	if game.active_route_id != "red-press" or game.route_enemy_damage <= 1.0:
		_fail("Red Press did not activate its damage pressure")
		return
	if game.chosen_routes != ["razor-gallery", "errata-canals", "red-press"]:
		_fail("three-act route chain was not recorded in order")
		return

	game.score = 14000
	game.wave = 11
	game.kills = 88
	game.run_shards = 12
	game.elapsed = 455.0
	game._finalize_run()
	if game.last_run_summary.get("route_ids", []) != game.chosen_routes:
		_fail("run summary omitted the three-act route chain")
		return
	game.hud.show_game_over(game.last_run_summary)
	if game.hud.game_over_label.text.find("RAZOR › ERRATA › PRESS") < 0:
		_fail("post-run panel did not render the route chain")
		return

	for route_id in route_ids:
		game._activate_route(route_id)
	if game.discovered_routes.size() != 9 or "map-the-margins" not in game.unlocked_achievements:
		_fail("discovering all routes did not restore the atlas achievement")
		return
	if not game._save_run():
		_fail("route discovery profile did not save")
		return
	game.free()

	var restored = _new_game(false)
	if restored.discovered_routes.size() != 9 or restored.recent_runs.size() != 1:
		_fail("route discoveries or route run history did not survive reload")
		return
	if restored.recent_runs[0].get("route_ids", []).size() != 3:
		_fail("reloaded run history lost its route chain")
		return
	restored.debug_clear_save_files()
	restored.free()
	print("INKBOUND_ROUTES_OK routes=9 choices=3x3 bias=ok pause=ok history=ok achievement=ok schema=12")
	paused = false
	quit(0)


func _new_game(clear_files: bool) -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(808080)
	return game


func _fail(message: String) -> void:
	push_error("INKBOUND_ROUTES_FAIL: " + message)
	if packed != null:
		var cleanup = packed.instantiate()
		cleanup.debug_set_save_namespace(profile_name)
		cleanup.debug_clear_save_files()
		cleanup.free()
	Engine.time_scale = 1.0
	paused = false
	quit(1)
