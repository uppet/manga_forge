extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var packed: PackedScene
var started := false
var profile_name := "restoration_board_test"


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_test()
	return false


func _run_test() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	packed = loaded
	if not _validate_catalog():
		return
	var game = _new_game(true)
	if not _validate_controls_and_layout(game):
		return
	game.hud.show_title(game._meta_snapshot())
	game.hud._show_restoration()
	game.hud.debug_finish_popup_transition()
	if not game.hud.restoration_visible or not game.hud.restoration_panel.visible:
		_fail("Restoration Board did not open as a title modal", game)
		return
	game.hud._move_restoration(1, 0)
	game.hud._move_restoration(0, 1)
	if game.hud.restoration_selected != 3:
		_fail("two-axis controller navigation did not reach the expected branch", game)
		return

	game.meta_shards = 999
	game._on_meta_upgrade_requested("stride")
	if int(game.meta_upgrades["stride"]) != 0 or game.meta_shards != 999:
		_fail("Archive Rank lock did not reject Quick Margin", game)
		return
	game.lifetime_memory_earned = 270
	game.meta_shards = 1000
	game.hud.refresh_title_meta(game._meta_snapshot())
	for definition in Content.META_RESTORATIONS:
		for _rank in range(int(definition["max_rank"])):
			game._on_meta_upgrade_requested(str(definition["id"]))
	if game.meta_shards != 280:
		_fail("thirty ranks did not spend the expected 720 Memory", game)
		return
	for definition in Content.META_RESTORATIONS:
		if int(game.meta_upgrades.get(definition["id"], 0)) != 5:
			_fail("branch %s did not reach mastery" % definition["id"], game)
			return
	if not _validate_mastery_stats(game):
		return
	if not game.hud.restoration_visible:
		_fail("buying a rank closed the Restoration Board", game)
		return
	for button in game.hud.meta_upgrade_buttons:
		if not button.disabled or button.text.find("MASTERED") < 0:
			_fail("mastered branch did not render its terminal state", game)
			return
	if not game._save_run():
		_fail("mastered Restoration Board did not save", game)
		return
	game.free()

	var restored = _new_game(false)
	for definition in Content.META_RESTORATIONS:
		if int(restored.meta_upgrades.get(definition["id"], 0)) != 5:
			_fail("branch %s did not survive profile reload" % definition["id"], restored)
			return
	if not _validate_mastery_stats(restored):
		return
	restored.free()

	var legacy = _new_game(true)
	var legacy_payload: Dictionary = legacy._save_payload(1)
	legacy_payload["schema_version"] = 9
	legacy_payload["meta_upgrades"] = {"vital": 2, "edge": 1, "fortune": 3}
	legacy._apply_save_payload(legacy_payload)
	if int(legacy.meta_upgrades["vital"]) != 2 or int(legacy.meta_upgrades["edge"]) != 1 or int(legacy.meta_upgrades["fortune"]) != 3:
		_fail("schema-9 core restoration ranks did not migrate", legacy)
		return
	for new_id in ["stride", "inkwell", "thread"]:
		if int(legacy.meta_upgrades[new_id]) != 0:
			_fail("schema-9 migration invented a new restoration rank", legacy)
			return
	legacy.debug_clear_save_files()
	legacy.free()
	print("INKBOUND_RESTORATION_OK branches=6 ranks=30 costs=720 unlocks=1/2/4/6 mastery=6 controller=2d save=schema12 migration=schema9")
	paused = false
	quit(0)


func _validate_catalog() -> bool:
	if Content.META_RESTORATIONS.size() != 6:
		_fail("expected six restoration branches")
		return false
	var ids: Array[String] = []
	var total_ranks := 0
	var total_cost := 0
	for definition in Content.META_RESTORATIONS:
		var restoration_id := str(definition.get("id", ""))
		if restoration_id.is_empty() or restoration_id in ids or Content.meta_restoration(restoration_id).is_empty():
			_fail("restoration catalog contains a missing or duplicate ID")
			return false
		ids.append(restoration_id)
		total_ranks += int(definition["max_rank"])
		for rank in range(int(definition["max_rank"])):
			total_cost += Content.meta_restoration_cost(restoration_id, rank)
	if total_ranks != 30 or total_cost != 720:
		_fail("restoration economy drifted from 30 ranks / 720 Memory")
		return false
	return true


func _validate_controls_and_layout(game: Node) -> bool:
	if not InputMap.has_action("restoration"):
		_fail("Restoration Board input action is missing", game)
		return false
	var has_keyboard := false
	var has_gamepad := false
	for event in InputMap.action_get_events("restoration"):
		if event is InputEventKey and event.physical_keycode == KEY_M:
			has_keyboard = true
		elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_STICK:
			has_gamepad = true
	if not has_keyboard or not has_gamepad:
		_fail("Restoration Board lacks its default M / right-stick bindings", game)
		return false
	if game.hud.meta_upgrade_buttons.size() != Content.META_RESTORATIONS.size():
		_fail("Restoration Board did not construct six branch cards", game)
		return false
	for index in range(game.hud.meta_upgrade_buttons.size()):
		var button: Button = game.hud.meta_upgrade_buttons[index]
		if button.position.x < 0.0 or button.position.y < 0.0 or button.position.x + button.size.x > game.hud.restoration_panel.size.x or button.position.y + button.size.y > 216.0:
			_fail("branch card %d escapes the safe board region" % index, game)
			return false
		for other_index in range(index + 1, game.hud.meta_upgrade_buttons.size()):
			if button.get_rect().intersects(game.hud.meta_upgrade_buttons[other_index].get_rect()):
				_fail("branch cards %d and %d overlap" % [index, other_index], game)
				return false
	return true


func _validate_mastery_stats(game: Node) -> bool:
	var expected_art_cooldown := 8.0 * pow(0.96, 5)
	if not is_equal_approx(game.player.max_health, 13.0) or not is_equal_approx(game.player.guard, 2.0):
		_fail("Heartbind ranks or mastery are not active", game)
		return false
	if not is_equal_approx(game.player.damage, 3.0) or not is_equal_approx(game.player.boss_damage_bonus, 0.10):
		_fail("Honed Nib ranks or mastery are not active", game)
		return false
	if not is_equal_approx(game.player.luck, 0.25) or not is_equal_approx(game.player.xp_multiplier, 1.10):
		_fail("Lucky Misprint ranks or mastery are not active", game)
		return false
	if not is_equal_approx(game.player.move_speed, 127.0) or not is_equal_approx(game.player.dash_cooldown_max, 1.035):
		_fail("Quick Margin ranks or mastery are not active", game)
		return false
	if not is_equal_approx(game.player.ink_art_cooldown_max, expected_art_cooldown) or not is_equal_approx(game.player.ink_art_damage_multiplier, 1.15):
		_fail("Deep Inkwell ranks or mastery are not active", game)
		return false
	if not is_equal_approx(game.player.pickup_radius, 235.0):
		_fail("Reader's Thread ranks or mastery are not active", game)
		return false
	return true


func _new_game(clear_files: bool) -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(180018)
	return game


func _fail(message: String, game: Node = null) -> void:
	push_error("INKBOUND_RESTORATION_FAIL: " + message)
	if game != null and is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	elif packed != null:
		var cleanup = packed.instantiate()
		cleanup.debug_set_save_namespace(profile_name)
		cleanup.debug_clear_save_files()
		cleanup.free()
	Engine.time_scale = 1.0
	paused = false
	quit(1)
