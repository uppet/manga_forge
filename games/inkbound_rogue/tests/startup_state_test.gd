extends SceneTree

const StartupState = preload("res://scripts/startup_state.gd")

var game: Node
var frames := 0
var ran := false


func _initialize() -> void:
	var invalid := StartupState.parse_document({
		"schema": 99,
		"enabled": true,
		"run": {"starting_weapon": "greatbrush", "boss": "not-a-boss"},
		"player": {
			"level": 2,
			"upgrades": [{"id": "needlepoint", "stacks": 2}],
			"relics": ["not-a-relic"],
		},
		"enemies": [{"kind": "not-an-enemy"}],
	}, "invalid-test.json")
	if bool(invalid.get("active", true)) or invalid.get("errors", []).size() < 5:
		_fail("invalid or conflicting startup state was accepted")
		return

	var file_path := "user://startup-state-parser-test.json"
	var temp := FileAccess.open(file_path, FileAccess.WRITE)
	if temp == null:
		_fail("could not create parser fixture")
		return
	var document := _valid_document()
	temp.store_string(JSON.stringify(document, "  "))
	temp = null
	var loaded := StartupState.load_file(file_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
	if not bool(loaded.get("active", false)) or str(loaded.get("config", {}).get("profile", "")) != "repro-page-8":
		_fail("valid JSON file did not parse and normalize")
		return

	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	var injected: Dictionary = game.debug_set_startup_state_document(document, "startup-state-test.json")
	if not bool(injected.get("active", false)):
		_fail("valid injected startup state was rejected: %s" % str(injected.get("errors", [])))
		return
	root.add_child(game)


func _process(_delta: float) -> bool:
	if ran:
		return false
	frames += 1
	if frames < 3:
		return false
	ran = true
	if not game.startup_state_active or not game.run_started or game.startup_state_source != "startup-state-test.json":
		_fail("startup state did not become an active run")
		return true
	if game.wave != 8 or game.player.level != 14 or game.player.xp != 11 or game.player.xp_needed != 46:
		_fail("page or player level state is wrong")
		return true
	if game.difficulty_id != "redline" or game.contract_id != "glass-script" or game.proof_depth != 7 or game.active_route_id != "chain-vault":
		_fail("run difficulty/contract/proof/route state is wrong")
		return true
	if game.player.weapon_form != "NEEDLEPOINT":
		_fail("configured starting weapon was not applied")
		return true
	if int(game.player.upgrade_stacks.get("wide-panel", 0)) != 2 or int(game.player.upgrade_stacks.get("ink-wave", 0)) != 1:
		_fail("fixed upgrade stacks were not applied")
		return true
	if game.startup_state_applied_upgrades.size() != 8 or game.player.upgrade_stacks.size() != 8:
		_fail("random upgrade fill is incomplete or counted the starting weapon incorrectly")
		return true
	for expected_upgrade in ["living-ink", "violent-margin", "red-harvest", "echoed-panel", "merciful-revision"]:
		if int(game.player.upgrade_stacks.get(expected_upgrade, 0)) != 1:
			_fail("tag-filtered random fill omitted %s" % expected_upgrade)
			return true
	if game.relic_ids.size() != 4 or "black-tea" not in game.relic_ids or "iori-ribbon" in game.relic_ids:
		_fail("fixed/random relic fill or exclusion is wrong")
		return true
	if not is_equal_approx(game.player.health, game.player.max_health * 0.5) or not is_equal_approx(game.player.guard, 4.0):
		_fail("configured health ratio or guard was not applied after build effects")
		return true
	if game.player.global_position.distance_to(Vector2(12.0, -18.0)) > 0.1:
		_fail("configured player position was not applied")
		return true
	var enemies := get_nodes_in_group("enemies")
	var bosses := get_nodes_in_group("bosses")
	if enemies.size() != 3 or bosses.size() != 1 or str(bosses[0].enemy_kind) != "binder":
		_fail("exact enemy fixtures or configured boss are missing")
		return true
	for enemy in enemies:
		if str(enemy.enemy_kind) == "scribe" and (not enemy.is_elite or not is_equal_approx(enemy.health, enemy.max_health * 0.5)):
			_fail("elite/health settings were not applied to the exact scribe fixture")
			return true
		if str(enemy.enemy_kind) == "blot" and enemy.is_elite:
			_fail("elite=false fixture was randomly promoted")
			return true
	if game.boss_intro_cinematic_active or paused:
		_fail("boss_intro=false did not keep the debug state immediately playable")
		return true
	if game.startup_state_page_timer_enabled or game.startup_state_ambient_spawning:
		_fail("frozen page/spawn controls were ignored")
		return true
	var frozen_elapsed: float = float(game.elapsed)
	var frozen_enemy_count: int = enemies.size()
	game._process(3.0)
	if not is_equal_approx(game.elapsed, frozen_elapsed) or get_nodes_in_group("enemies").size() != frozen_enemy_count:
		_fail("disabled page timer or ambient spawning still advanced")
		return true
	if not game.hud.objective_label.text.begins_with("[调试]"):
		_fail("debug-state run is not visibly marked in the HUD")
		return true
	if game._save_checkpoint("debug-test") or game._save_run() or FileAccess.file_exists(game.save_path) or FileAccess.file_exists(game.checkpoint_path):
		_fail("debug-state run wrote persistent save data")
		return true
	var analytics = root.get_node_or_null("GameAnalyticsClient")
	if analytics != null:
		var snapshot: Dictionary = analytics.debug_snapshot()
		if bool(snapshot.get("active", true)) or str(snapshot.get("status", "")) != "test_mode":
			_fail("GameAnalytics was not disabled for startup-state debugging")
			return true
	print("INKBOUND_STARTUP_STATE_TEST_OK schema=1 page=8 level=14 fixed_upgrades=3 random_upgrades=5 relics=4 enemies=3 timer=frozen spawning=frozen saves=false analytics=false locale=zh_CN")
	_cleanup(0)
	return true


func _valid_document() -> Dictionary:
	return {
		"schema": 1,
		"enabled": true,
		"profile": "Repro Page 8",
		"seed": 8082026,
		"settings": {
			"language": "zh_CN",
			"ink_art_cutins": true,
			"hit_stop": true,
			"reduced_flashes": false,
		},
		"run": {
			"page": 8,
			"page_progress": 0.25,
			"difficulty": "redline",
			"contract": "glass-script",
			"proof_depth": 7,
			"starting_weapon": "needlepoint",
			"route": "chain-vault",
			"spawn_page_content": false,
			"ambient_spawning": false,
			"page_timer": false,
			"clear_existing_enemies": true,
			"boss": "binder",
			"boss_intro": false,
			"boss_position": [150, 0],
			"memory": 9,
			"kills": 17,
		},
		"player": {
			"level": 14,
			"xp": 11,
			"health_ratio": 0.5,
			"guard": 4,
			"ink_art_ready": true,
			"position": [12, -18],
			"upgrades": [
				{"id": "wide-panel", "stacks": 2},
				"ink-wave",
			],
			"random_upgrades": {
				"count": 5,
				"max_stacks_per_upgrade": 1,
				"allow_weapon_forms": false,
				"tags": ["art"],
				"exclude": ["quickscript"],
			},
			"relics": ["black-tea"],
			"random_relics": {
				"count": 3,
				"exclude": ["iori-ribbon"],
			},
		},
		"enemies": [
			{"kind": "scribe", "position": [90, 0], "relative_to_player": true, "elite": true, "health_ratio": 0.5},
			{"kind": "blot", "position": [-100, 10], "relative_to_player": false, "elite": false, "health_ratio": 1.0},
		],
	}


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)


func _fail(message: String) -> void:
	push_error("INKBOUND_STARTUP_STATE_TEST_FAIL: " + message)
	_cleanup(1)
