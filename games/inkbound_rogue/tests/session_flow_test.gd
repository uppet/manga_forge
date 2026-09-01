extends SceneTree

const NAMESPACE := "session_flow_test"

var started := false


func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	return false


func _new_game() -> Node:
	var packed = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)
	return game


func _run() -> void:
	print("INKBOUND_SESSION_STAGE boot")
	var game = _new_game()
	game.debug_clear_save_files()
	game.run_started = true
	game.elapsed = 97.5
	game.wave = 3
	game.kills = 27
	game.score = 4321
	game.run_shards = 9
	game.kills_since_heal_drop = 7
	game.kills_since_supply_drop = 11
	game.heal_drops_spawned = 2
	game.combat_drops_spawned = 1
	game._configure_contract("open-draft")
	game._configure_difficulty("standard")
	game.active_route_id = "whisper-stacks"
	game.chosen_routes.clear()
	game.chosen_routes.append("whisper-stacks")
	game._restore_route_modifiers(game.active_route_id)
	game.player.apply_upgrade("razor-ink")
	game.player.apply_upgrade("ink-wave")
	game.player.apply_upgrade("living-ink")
	game.player.apply_upgrade("echoed-panel")
	game.player.ink_art_cooldown = 3.4
	game.player.ink_art_uses = 2
	game.debug_start_directive("whisper-circle")
	game._on_directive_zone_progress(2.5, game.directive_target, true)
	game.player.apply_relic("wax-seal")
	game.relic_ids.clear()
	game.relic_ids.append("wax-seal")
	game.player.health = 4.25
	game.player.global_position = Vector2(41.0, -33.0)
	var expected_damage: float = game.player.damage
	if not game._save_checkpoint("test-fixture"):
		_fail(game, "could not write a valid run checkpoint")
		return
	if not FileAccess.file_exists(game.checkpoint_path) or game._read_checkpoint_file(game.checkpoint_path)["state"] != "ok":
		_fail(game, "checkpoint was not atomically readable")
		return
	if not game._save_checkpoint("test-backup") or not FileAccess.file_exists(game.backup_checkpoint_path):
		_fail(game, "checkpoint rotation did not create a backup")
		return
	var damaged := FileAccess.open(game.checkpoint_path, FileAccess.WRITE)
	if damaged == null:
		_fail(game, "could not create the corruption recovery fixture")
		return
	damaged.store_string("damaged checkpoint")
	damaged.flush()
	damaged = null
	print("INKBOUND_SESSION_STAGE saved")
	game.free()

	var loaded = _new_game()
	print("INKBOUND_SESSION_STAGE rebooted")
	if loaded.checkpoint_data.is_empty() or not loaded.checkpoint_recovered:
		_fail(loaded, "title boot did not discover the saved draft")
		return
	loaded.hud.show_title(loaded._meta_snapshot())
	if loaded.hud.continue_button.disabled or loaded.hud.continue_button.text.find("PAGE 3") < 0:
		_fail(loaded, "Continue / Load was not enabled with its page summary")
		return
	loaded._on_continue_requested()
	print("INKBOUND_SESSION_STAGE continued")
	if not loaded.run_started or loaded.wave != 3 or loaded.kills != 27 or loaded.score != 4321:
		_fail(loaded, "loaded run counters do not match the checkpoint")
		return
	if not is_equal_approx(loaded.player.damage, expected_damage) or int(loaded.player.upgrade_stacks.get("ink-wave", 0)) != 1:
		_fail(loaded, "player weapon build was not restored")
		return
	if not is_equal_approx(loaded.player.ink_art_cooldown, 3.4) or loaded.player.ink_art_uses != 2 or not loaded.player.ink_art_echo or loaded.player.ink_art_damage_multiplier <= 1.0:
		_fail(loaded, "Ink Art build and cooldown were not restored")
		return
	if str(loaded.active_directive.get("id", "")) != "whisper-circle" or not is_equal_approx(loaded.directive_progress, 2.5) or not is_instance_valid(loaded.directive_zone):
		_fail(loaded, "Page Directive progress and hold zone were not restored")
		return
	if not loaded.player.global_position.is_equal_approx(Vector2(41.0, -33.0)) or not is_equal_approx(loaded.player.health, 4.25):
		_fail(loaded, "player health or position was not restored")
		return
	if loaded.kills_since_heal_drop != 7 or loaded.kills_since_supply_drop != 11 or loaded.combat_drops_spawned != 1:
		_fail(loaded, "drop-pity state was not restored")
		return
	if paused or loaded.hud.title_visible:
		_fail(loaded, "Continue / Load did not return to live gameplay")
		return
	print("INKBOUND_SESSION_STAGE restore-verified")

	loaded.highest_wave = 12
	loaded.completed_endings.clear()
	loaded.completed_endings.append("keep")
	loaded.run_started = false
	loaded.hud.show_title(loaded._meta_snapshot())
	print("INKBOUND_SESSION_STAGE title-shown")
	var archive: Array[Dictionary] = loaded.hud._story_archive_entries()
	print("INKBOUND_SESSION_STAGE archive=%d" % archive.size())
	if archive.size() != 7 or not bool(archive[4]["unlocked"]) or not bool(archive[5]["unlocked"]) or bool(archive[6]["unlocked"]):
		_fail(loaded, "story archive unlock rules are incorrect")
		return
	var lifetime_before: int = loaded.lifetime_runs
	loaded.run_started = true
	loaded.hud.hide_title()
	loaded.replaying_story = true
	if not loaded._play_replay_sequence("ending_keep"):
		_fail(loaded, "story replay sequence could not start")
		return
	print("INKBOUND_SESSION_STAGE replaying")
	if not loaded.replaying_story or not loaded.cutscene.active:
		_fail(loaded, "story replay did not enter its cinematic state")
		return
	loaded.cutscene.debug_complete()
	print("INKBOUND_SESSION_STAGE replay-complete")
	if loaded.replaying_story or loaded.cutscene.active or loaded.run_won or loaded.lifetime_runs != lifetime_before or not loaded.hud.title_visible:
		_fail(loaded, "replayed ending leaked gameplay completion side effects")
		return

	loaded._delete_checkpoint()
	if FileAccess.file_exists(loaded.checkpoint_path) or FileAccess.file_exists(loaded.backup_checkpoint_path):
		_fail(loaded, "final checkpoint cleanup left an active Continue slot")
		return
	print("INKBOUND_SESSION_OK new=confirmed checkpoint=atomic continue=page3 build=restored story=7 replay=safe cleanup=ok")
	_cleanup(loaded, 0)


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_SESSION_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
