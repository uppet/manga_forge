extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var started := false
var packed: PackedScene
var profile_name := "progression_test"


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_progression_test()
	return false


func _run_progression_test() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	packed = loaded
	var game = _new_game(true)
	if game._unlocked_content_ids("contract") != ["open-draft"]:
		_fail("fresh profile exposed challenge contracts before their milestones")
		return
	if game._unlocked_content_ids("weapon") != ["greatbrush"]:
		_fail("fresh profile did not begin with exactly the Greatbrush form")
		return
	if game._unlocked_content_ids("difficulty") != ["story", "standard"]:
		_fail("fresh profile difficulty access is incorrect")
		return
	game.player.level = 10
	var fresh_pool: Array[Dictionary] = Content.available_upgrades({}, 10, game._unlocked_content_ids("weapon"))
	if not _pool_has(fresh_pool, "greatbrush") or _pool_has(fresh_pool, "needlepoint") or _pool_has(fresh_pool, "seal-caster") or _pool_has(fresh_pool, "twin-stroke"):
		_fail("fresh upgrade pool ignored persistent weapon-form locks")
		return

	game.hud.show_title(game._meta_snapshot())
	game.hud._cycle_contract(1)
	if Content.CONTRACTS[game.hud.contract_index]["id"] != "open-draft":
		_fail("title selector entered a locked contract")
		return
	game._on_start_requested("redline", "cursed-ink")
	if game.difficulty_id != "standard" or game.contract_id != "open-draft":
		_fail("runtime accepted locked difficulty or contract IDs")
		return

	game.run_shards = 17
	game.score = 12345
	game.kills = 67
	game.wave = 8
	game.highest_wave = 8
	game.lifetime_kills = 25
	game.player.level = 10
	game.player.apply_upgrade("greatbrush")
	game.run_directives_started = 5
	game.run_directives_completed = 4
	game.lifetime_directives_completed = 4
	game.elapsed = 395.0
	game._finalize_run()
	if game.meta_shards != 17 or game.lifetime_runs != 1 or game.recent_runs.size() != 1:
		_fail("run finalization did not bank Memory and append history")
		return
	var expected_contracts := ["open-draft", "quick-edition", "living-margins", "sealed-archive"]
	if game._unlocked_content_ids("contract") != expected_contracts:
		_fail("first-run milestone contract unlocks are incorrect")
		return
	if game._unlocked_content_ids("weapon") != ["greatbrush", "needlepoint", "seal-caster"]:
		_fail("first-run milestone weapon unlocks are incorrect")
		return
	var summary: Dictionary = game.last_run_summary
	if int(summary.get("memory_earned", 0)) != 17 or summary.get("new_unlocks", []).size() < 5 or int(summary.get("directives_completed", 0)) != 4:
		_fail("post-run summary omitted earned Memory or milestone unlocks")
		return
	game.hud.show_game_over(summary)
	if game.hud.game_over_label.text.find("MEMORY +17") < 0 or game.hud.game_over_label.text.find("NEW") < 0:
		_fail("post-run panel did not render rewards and new unlocks")
		return
	if not game._save_run():
		_fail("progression profile did not save")
		return
	game.free()

	var restored = _new_game(false)
	if restored.recent_runs.size() != 1 or restored.lifetime_runs != 1 or restored.meta_shards != 17 or restored.lifetime_directives_completed != 4 or restored.best_directives_completed != 4:
		_fail("recent run history did not survive profile reload")
		return
	restored.completed_endings.append("keep")
	restored.contract_wins = {"open-draft": 1, "quick-edition": 1, "living-margins": 1}
	if "glass-script" not in restored._unlocked_content_ids("contract") or "cursed-ink" not in restored._unlocked_content_ids("contract"):
		_fail("ending and three-contract milestones did not unlock late contracts")
		return
	if "redline" not in restored._unlocked_content_ids("difficulty") or "twin-stroke" not in restored._unlocked_content_ids("weapon"):
		_fail("ending milestone did not unlock Redline and Twin-Stroke")
		return
	var rank_data: Dictionary = restored._archive_rank_snapshot()
	if int(rank_data.get("rank", 0)) < 1 or int(rank_data.get("maximum", 0)) != Content.ARCHIVE_RANK_THRESHOLDS.size():
		_fail("Archive Rank snapshot is invalid")
		return
	restored.debug_clear_save_files()
	restored.free()
	print("INKBOUND_PROGRESSION_OK contracts=6 weapons=4 difficulties=3 history=10 profile=schema12")
	paused = false
	quit(0)


func _new_game(clear_files: bool) -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(707070)
	return game


func _pool_has(pool: Array[Dictionary], upgrade_id: String) -> bool:
	for entry in pool:
		if entry["id"] == upgrade_id:
			return true
	return false


func _fail(message: String) -> void:
	push_error("INKBOUND_PROGRESSION_FAIL: " + message)
	var cleanup = packed.instantiate() if packed != null else null
	if cleanup != null:
		cleanup.debug_set_save_namespace(profile_name)
		cleanup.debug_clear_save_files()
		cleanup.free()
	Engine.time_scale = 1.0
	paused = false
	quit(1)
