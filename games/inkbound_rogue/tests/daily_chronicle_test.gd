extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var packed: PackedScene
var started := false
var profile_name := "daily_chronicle_test"


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
	var day_one := "2031-05-17"
	var day_two := "2031-05-18"
	var day_gap := "2031-05-20"
	var recipe := Content.daily_recipe(day_one)
	if not _validate_recipe(day_one, day_two, recipe):
		return

	var game = _new_game(true)
	if not _validate_controls_and_panel(game, day_one):
		return
	for restoration_id in game.meta_upgrades:
		game.meta_upgrades[restoration_id] = 5
	game._apply_meta_progression()
	game.debug_set_daily_date(day_one)
	game._on_daily_requested()
	if not game.daily_run or game.daily_id != day_one or game.run_seed != int(recipe["seed"]):
		_fail("Daily start lost its date or seed identity", game)
		return
	if game.difficulty_id != "standard" or game.contract_id != str(recipe["contract_id"]) or game.proof_depth != 0 or game.starting_weapon_id != "marginalia":
		_fail("Daily start did not enforce its fixed rules", game)
		return
	if not _meta_was_sealed(game):
		_fail("Daily start did not seal permanent Restoration bonuses", game)
		return
	var signature_state: int = game.rng.state
	var signature_one := _run_signature(game)
	game.rng.state = signature_state
	var signature_two := _run_signature(game)
	if signature_one != signature_two:
		_fail("same-date Daily runs did not produce the same content sequence", game)
		return

	if not game._save_checkpoint("daily-seed"):
		_fail("Daily run could not create a current-draft checkpoint", game)
		return
	var checkpoint: Dictionary = game.checkpoint_data.duplicate(true)
	var expected_next_roll: int = game.rng.randi()
	var continued = _new_game(true, "daily_chronicle_continue")
	if not continued._apply_checkpoint(checkpoint):
		_fail("Daily checkpoint could not be applied", game)
		return
	if not continued.daily_run or continued.daily_id != day_one or continued.run_seed != int(recipe["seed"]) or continued.rng.randi() != expected_next_roll:
		_fail("Continue did not restore Daily identity and exact RNG state", game)
		return
	continued.debug_clear_save_files()
	continued.free()

	game.score = 12345
	game.wave = 12
	game.run_shards = 5
	game.run_won = true
	game.ending_id = "keep"
	game.run_committed = false
	game._finalize_run()
	var first_record: Dictionary = game.daily_records.get(day_one, {})
	if int(first_record.get("attempts", 0)) != 1 or int(first_record.get("wins", 0)) != 1 or not bool(first_record.get("cleared", false)):
		_fail("first Daily clear was not recorded", game)
		return
	if int(game.last_run_summary.get("daily_bonus", 0)) != Content.DAILY_CLEAR_BONUS or int(game.last_run_summary.get("memory_earned", 0)) != 5 + Content.DAILY_CLEAR_BONUS or game.lifetime_daily_clears != 1 or game.daily_current_streak != 1:
		_fail("first Daily clear did not grant its one-time reward and streak", game)
		return
	if "daily-reader" not in game.unlocked_achievements:
		_fail("first Daily clear did not unlock Today's Reader", game)
		return

	_prepare_daily_result(game, day_one, 20000, true)
	if int(game.daily_records[day_one]["attempts"]) != 2 or int(game.daily_records[day_one]["wins"]) != 2 or int(game.last_run_summary.get("daily_bonus", -1)) != 0 or game.lifetime_daily_clears != 1 or game.daily_current_streak != 1:
		_fail("repeat Daily clear duplicated its reward or streak", game)
		return
	_prepare_daily_result(game, day_two, 18000, true)
	if game.daily_current_streak != 2 or game.daily_best_streak != 2 or game.lifetime_daily_clears != 2:
		_fail("consecutive Daily clear did not extend the streak", game)
		return
	_prepare_daily_result(game, day_gap, 17000, true)
	if game.daily_current_streak != 1 or game.daily_best_streak != 2 or game.lifetime_daily_clears != 3:
		_fail("a skipped date did not reset the active streak while preserving the best", game)
		return
	if not game._save_run():
		_fail("Daily Chronicle profile did not save", game)
		return
	game.free()

	var restored = _new_game(false)
	if restored.SAVE_SCHEMA != 12 or restored.lifetime_daily_clears != 3 or restored.daily_best_streak != 2 or restored.daily_records.size() != 3:
		_fail("schema-12 profile did not preserve Daily history", restored)
		return
	var legacy_payload: Dictionary = restored._save_payload(1)
	legacy_payload["schema_version"] = 11
	for key in ["daily_records", "daily_current_streak", "daily_best_streak", "daily_last_clear_id", "lifetime_daily_clears"]:
		legacy_payload.erase(key)
	restored._apply_save_payload(legacy_payload)
	if not restored.daily_records.is_empty() or restored.lifetime_daily_clears != 0 or restored.daily_best_streak != 0:
		_fail("schema-11 profile did not migrate to an empty Daily Chronicle", restored)
		return
	restored.debug_clear_save_files()
	restored.free()
	print("INKBOUND_DAILY_OK seed=stable rules=standard/marginalia/proof0 meta=sealed input=T/down checkpoint=exact reward=12 once=ok streak=1/2/1 history=3 achievements=2 save=schema12 migration=schema11")
	paused = false
	quit(0)


func _validate_recipe(day_one: String, day_two: String, recipe: Dictionary) -> bool:
	var repeated := Content.daily_recipe(day_one)
	var next := Content.daily_recipe(day_two)
	if recipe != repeated or int(recipe.get("seed", 0)) <= 0 or int(recipe.get("seed", 0)) == int(next.get("seed", 0)):
		_fail("Daily recipe is not stable per date and distinct across dates")
		return false
	if Content.contract(str(recipe.get("contract_id", ""))).get("id", "") != str(recipe.get("contract_id", "")) or int(recipe.get("first_clear_bonus", 0)) != 12:
		_fail("Daily recipe references an invalid contract or reward")
		return false
	return true


func _validate_controls_and_panel(game: Node, date_id: String) -> bool:
	if not InputMap.has_action("daily_chronicle"):
		_fail("Daily Chronicle input action is missing", game)
		return false
	var has_keyboard := false
	var has_gamepad := false
	for event in InputMap.action_get_events("daily_chronicle"):
		if event is InputEventKey and event.physical_keycode == KEY_T:
			has_keyboard = true
		elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_DOWN:
			has_gamepad = true
	if not has_keyboard or not has_gamepad:
		_fail("Daily Chronicle lacks default T / D-pad Down bindings", game)
		return false
	game.debug_set_daily_date(date_id)
	game.hud.show_title(game._meta_snapshot())
	var open_event := InputEventJoypadButton.new()
	open_event.button_index = JOY_BUTTON_DPAD_DOWN
	open_event.pressed = true
	game.hud._unhandled_input(open_event)
	if not game.hud.daily_visible or not game.hud.daily_panel.visible or game.hud.daily_contract_label.text.find("SEED") < 0 or game.hud.daily_rules_label.text.find("RESTORATIONS SEALED") < 0:
		_fail("D-pad Down did not open the complete Daily Chronicle panel", game)
		return false
	var close_event := InputEventJoypadButton.new()
	close_event.button_index = JOY_BUTTON_B
	close_event.pressed = true
	game.hud._unhandled_input(close_event)
	if game.hud.daily_visible:
		_fail("B/Circle did not close the Daily Chronicle panel", game)
		return false
	return true


func _meta_was_sealed(game: Node) -> bool:
	return is_equal_approx(game.player.max_health, 8.0) and is_equal_approx(game.player.health, 8.0) and is_equal_approx(game.player.damage, 2.0) and is_equal_approx(game.player.move_speed, 112.0) and is_equal_approx(game.player.luck, 0.0) and is_equal_approx(game.player.pickup_radius, 100.0) and is_equal_approx(game.player.dash_cooldown_max, 1.15) and is_equal_approx(game.player.ink_art_cooldown_max, 8.0) and is_equal_approx(game.player.guard, 0.0)


func _run_signature(game: Node) -> String:
	game.player.level = 10
	var parts := PackedStringArray()
	for choice in game._pick_upgrades(4):
		parts.append(str(choice["id"]))
	for _index in range(12):
		parts.append(game._roll_enemy_kind())
	return "|".join(parts)


func _prepare_daily_result(game: Node, date_id: String, result_score: int, won: bool) -> void:
	var recipe := Content.daily_recipe(date_id)
	game.daily_run = true
	game.daily_id = date_id
	game.run_seed = int(recipe["seed"])
	game.contract_id = str(recipe["contract_id"])
	game.proof_depth = 0
	game.run_won = won
	game.ending_id = "keep" if won else ""
	game.score = result_score
	game.wave = 12 if won else 7
	game.run_shards = 0
	game.run_committed = false
	game._finalize_run()


func _new_game(clear_files: bool, namespace_value: String = "") -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name if namespace_value.is_empty() else namespace_value)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	return game


func _fail(message: String, game: Node = null) -> void:
	push_error("INKBOUND_DAILY_FAIL: " + message)
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
