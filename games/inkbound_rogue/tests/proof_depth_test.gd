extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

var packed: PackedScene
var started := false
var profile_name := "proof_depth_test"


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
	if not _validate_controls_and_fresh_lock(game):
		return
	game.run_start_unlock_ids = game._unlocked_content_ids()
	for depth in range(10):
		game.max_proof_depth = depth
		game.proof_depth = depth
		game.run_won = true
		game.run_committed = false
		game.run_shards = depth + 1
		game.ending_id = "keep"
		game._finalize_run()
		if game.max_proof_depth != depth + 1 or game.highest_proof_cleared != depth:
			_fail("clearing Proof %d did not unlock exactly one next depth" % depth, game)
			return
		if int(game.last_run_summary.get("proof_depth", -1)) != depth or str(game.last_run_summary.get("proof_name", "")) != str(Content.PROOF_LEVELS[depth]["name"]):
			_fail("run summary lost Proof %d identity" % depth, game)
			return
		if "PROOF %d" % (depth + 1) not in " · ".join(game.last_run_summary.get("new_unlocks", [])):
			_fail("run result did not announce unlocked Proof %d" % (depth + 1), game)
			return
	game.proof_depth = 10
	game.run_won = true
	game.run_committed = false
	game.run_shards = 0
	game._finalize_run()
	if game.max_proof_depth != 10 or game.highest_proof_cleared != 10:
		_fail("Author's Proof clear was not recorded at the terminal depth", game)
		return
	if not game._save_run():
		_fail("Proof ladder profile did not save", game)
		return
	game.free()

	var restored = _new_game(false)
	if restored.max_proof_depth != 10 or restored.preferred_proof_depth != 10 or restored.highest_proof_cleared != 10:
		_fail("Proof ladder did not survive profile reload", restored)
		return
	restored._on_start_requested("standard", "open-draft", "marginalia", 10)
	if not _validate_runtime_modifiers(restored):
		return
	if not restored._save_checkpoint("proof-10"):
		_fail("Proof 10 draft did not create a checkpoint", restored)
		return
	restored.free()

	var continued = _new_game(false)
	if int(continued._checkpoint_summary(continued.checkpoint_data).get("proof_depth", -1)) != 10:
		_fail("title checkpoint summary lost Proof 10", continued)
		return
	continued._on_continue_requested()
	if continued.proof_depth != 10 or not is_equal_approx(continued.proof_enemy_damage, pow(1.04, 2)) or not is_equal_approx(continued.proof_dash_cooldown, 1.10):
		_fail("Continue / Load did not restore cumulative Proof modifiers", continued)
		return
	continued.debug_clear_save_files()
	continued.free()

	var legacy = _new_game(true)
	var legacy_payload: Dictionary = legacy._save_payload(1)
	legacy_payload["schema_version"] = 10
	legacy_payload["completed_endings"] = ["keep"]
	legacy_payload.erase("max_proof_depth")
	legacy_payload.erase("preferred_proof_depth")
	legacy_payload.erase("highest_proof_cleared")
	legacy._apply_save_payload(legacy_payload)
	if legacy.max_proof_depth != 1 or legacy.preferred_proof_depth != 1 or legacy.highest_proof_cleared != 0:
		_fail("schema-10 ending profile did not migrate into Proof 1", legacy)
		return
	legacy.debug_clear_save_files()
	legacy.free()
	print("INKBOUND_PROOF_OK depths=11 unlocks=sequential final=cleared clauses=10 rewards=2.16x/1.63x controller=P/LS checkpoint=depth10 save=schema12 migration=schema10")
	paused = false
	quit(0)


func _validate_catalog() -> bool:
	if Content.PROOF_LEVELS.size() != 11:
		_fail("Proof Ledger must contain depths 0 through 10")
		return false
	var names: Array[String] = []
	var last_score := 0.0
	var last_shards := 0.0
	for depth in range(Content.PROOF_LEVELS.size()):
		var definition: Dictionary = Content.PROOF_LEVELS[depth]
		if int(definition.get("depth", -1)) != depth or str(definition.get("name", "")).is_empty() or str(definition.get("description", "")).is_empty() or str(definition["name"]) in names:
			_fail("Proof catalog identity drifted at depth %d" % depth)
			return false
		names.append(str(definition["name"]))
		var modifiers := Content.proof_modifiers(depth)
		if depth > 0 and (float(modifiers["score"]) <= last_score or float(modifiers["shards"]) <= last_shards):
			_fail("Proof rewards are not strictly cumulative at depth %d" % depth)
			return false
		last_score = float(modifiers["score"])
		last_shards = float(modifiers["shards"])
	var final_modifiers := Content.proof_modifiers(10)
	if not is_equal_approx(float(final_modifiers["enemy_health"]), pow(1.06, 2)) or not is_equal_approx(float(final_modifiers["enemy_damage"]), pow(1.04, 2)) or not is_equal_approx(float(final_modifiers["boss_health"]), 1.12 * 1.08):
		_fail("terminal Proof combat multipliers drifted")
		return false
	return true


func _validate_controls_and_fresh_lock(game: Node) -> bool:
	if not InputMap.has_action("proof_ledger"):
		_fail("Proof Ledger input action is missing", game)
		return false
	var has_keyboard := false
	var has_gamepad := false
	for event in InputMap.action_get_events("proof_ledger"):
		if event is InputEventKey and event.physical_keycode == KEY_P:
			has_keyboard = true
		elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_LEFT_STICK:
			has_gamepad = true
	if not has_keyboard or not has_gamepad:
		_fail("Proof Ledger lacks default P / left-stick bindings", game)
		return false
	game.hud.show_title(game._meta_snapshot())
	game.hud._show_proof_ledger()
	if not game.hud.proof_visible or game.hud.proof_buttons.size() != 11 or not game.hud.proof_buttons[1].disabled:
		_fail("fresh Proof Ledger did not expose one open and ten locked depths", game)
		return false
	game._on_start_requested("standard", "open-draft", "marginalia", 10)
	if game.proof_depth != 0:
		_fail("runtime accepted a locked Proof depth", game)
		return false
	return true


func _validate_runtime_modifiers(game: Node) -> bool:
	var expected := Content.proof_modifiers(10)
	for pair in [
		[game.proof_enemy_health, expected["enemy_health"]],
		[game.proof_enemy_damage, expected["enemy_damage"]],
		[game.proof_enemy_speed, expected["enemy_speed"]],
		[game.proof_spawn_interval, expected["spawn_interval"]],
		[game.proof_enemy_cap, expected["enemy_cap"]],
		[game.proof_recovery, expected["recovery"]],
		[game.proof_boss_health, expected["boss_health"]],
		[game.proof_wave_duration, expected["wave_duration"]],
		[game.proof_score_multiplier, expected["score"]],
		[game.proof_shard_multiplier, expected["shards"]],
	]:
		if not is_equal_approx(float(pair[0]), float(pair[1])):
			_fail("runtime Proof multiplier does not match the content ledger", game)
			return false
	if not is_equal_approx(game.player.dash_cooldown_max, 1.15 * 1.10):
		_fail("Broken Gutter did not slow dash recovery", game)
		return false
	game.wave = 12
	var baseline_author = EnemyScript.new().configure("author", game.player, 12)
	var baseline_health: float = baseline_author.max_health
	baseline_author.free()
	var author = game.spawn_enemy("author", game.player.global_position + Vector2(120, 0))
	var expected_health: float = baseline_health * float(game.proof_enemy_health) * float(game.proof_boss_health)
	if not is_equal_approx(author.max_health, expected_health):
		_fail("Red Pen / Author's Proof boss health did not reach the spawned boss", game)
		return false
	var shards_before: int = game.run_shards
	game.collect_shards(10)
	if game.run_shards - shards_before != int(round(10.0 * game.proof_shard_multiplier)):
		_fail("Proof Memory reward multiplier did not reach collected shards", game)
		return false
	return true


func _new_game(clear_files: bool) -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(190019)
	return game


func _fail(message: String, game: Node = null) -> void:
	push_error("INKBOUND_PROOF_FAIL: " + message)
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
