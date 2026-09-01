extends SceneTree

var frames := 0
var game: Node
var capture_failed := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		push_error("INKBOUND_CAPTURE_FAIL: main scene did not load")
		quit(1)
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(909090)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		game.lifetime_runs = 6
		game.lifetime_memory_earned = 140
		game.highest_wave = 12
		game.lifetime_kills = 180
		game.completed_endings.assign(["keep"])
		game.contract_wins = {"open-draft": 2, "quick-edition": 1, "living-margins": 1}
		game.recent_runs.assign([
			{"run_number": 6, "won": true, "score": 18420, "wave": 12, "level": 18, "difficulty": "standard", "contract_name": "LIVING MARGINS", "memory_earned": 24},
			{"run_number": 5, "won": false, "score": 9350, "wave": 8, "level": 12, "difficulty": "redline", "contract_name": "OPEN DRAFT", "memory_earned": 11},
			{"run_number": 4, "won": false, "score": 6120, "wave": 6, "level": 10, "difficulty": "standard", "contract_name": "QUICK EDITION", "memory_earned": 9},
		])
		game.hud.show_title(game._meta_snapshot())
		paused = true
	elif frames == 6:
		game.hud._cycle_contract(1)
	elif frames == 12:
		_capture("inkbound-title-render.png")
		if capture_failed:
			return true
		game.hud._toggle_history()
		game.hud.debug_finish_popup_transition()
	elif frames == 16:
		_capture("inkbound-history-render.png")
		if capture_failed:
			return true
		game.hud._toggle_history()
		game.hud._toggle_achievements()
		game.hud.debug_finish_popup_transition()
	elif frames == 20:
		_capture("inkbound-achievements-render.png")
		if capture_failed:
			return true
		game.hud._toggle_achievements()
		game.hud.show_settings()
		game.hud.debug_finish_popup_transition()
	elif frames == 24:
		_capture("inkbound-options-render.png")
		if capture_failed:
			return true
		game.hud.show_bindings()
		game.hud.debug_finish_popup_transition()
	elif frames == 32:
		_capture("inkbound-bindings-render.png")
		if capture_failed:
			return true
		game.hud.hide_bindings()
		game.hud.debug_finish_popup_transition()
		game.hud.hide_settings()
		game.hud.debug_finish_popup_transition()
		game.hud.hide_title()
		game.debug_play_story("prologue")
	elif frames == 40:
		_capture("inkbound-cutscene-render.png")
		if capture_failed:
			return true
		game.cutscene.debug_complete()
		game.run_started = true
		paused = false
	elif frames == 150:
		game.debug_offer_event("forgotten-shrine")
		game.hud.debug_finish_popup_transition()
	elif frames == 158:
		_capture("inkbound-event-render.png")
		if capture_failed:
			return true
		game.hud._choose_event(1)
		game.hud.debug_finish_popup_transition()
	elif frames == 166:
		game.wave = 5
		game.arena.set_chapter(2)
		game.hud.set_run_stats(5, game.score, true)
		game._offer_route(2)
		game.hud.debug_finish_popup_transition()
	elif frames == 174:
		_capture("inkbound-route-render.png")
		if capture_failed:
			return true
		game.hud._choose_event(0)
		game.hud.debug_finish_popup_transition()
	elif frames == 204:
		if game.hud.achievement_toast_tween != null and game.hud.achievement_toast_tween.is_valid():
			game.hud.achievement_toast_tween.kill()
		game.hud.achievement_toast.visible = false
		game.hud.achievement_queue.clear()
	elif frames == 210:
		_capture("inkbound-gameplay-render.png")
		if capture_failed:
			return true
		_prepare_combat_gallery()
	elif frames == 218:
		_capture("inkbound-enemy-powerup-render.png")
		if capture_failed:
			return true
		game.hud.show_game_over({
			"won": false, "wave": 9, "level": 14, "score": 12840, "kills": 93,
			"best_score": 18420, "memory_earned": 16, "archive_rank": 4,
			"duration_seconds": 487, "difficulty": "redline",
			"contract_name": "SEALED ARCHIVE", "weapon_form": "NEEDLEPOINT",
			"route_ids": ["razor-gallery", "errata-canals", "red-press"],
			"new_unlocks": ["GLASS SCRIPT", "TWIN-STROKE FORM"],
		})
		game.hud.debug_finish_popup_transition()
	elif frames == 226:
		_capture("inkbound-run-summary-render.png")
		if capture_failed:
			return true
		print("INKBOUND_CAPTURE_OK gallery=11 size=960x540")
		paused = false
		game.free()
		quit(0)
		return true
	return false


func _prepare_combat_gallery() -> void:
	paused = false
	game.spawn_timer = 999.0
	game.player.controls_enabled = false
	game.player.global_position = Vector2.ZERO
	game.player.visible = false
	for enemy in game.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for pickup in game.get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and pickup.get_parent() == game:
			pickup.free()
	for child in game.get_children():
		if child in [game.arena, game.player, game.hud, game.cutscene, game.music_player]:
			continue
		if child is Node2D:
			child.free()

	var enemy_kinds := ["censor", "errata", "archivist", "blot", "duelist"]
	var enemy_offsets := [
		Vector2(-176, -28), Vector2(-88, -28), Vector2(0, -28),
		Vector2(88, -28), Vector2(176, -28),
	]
	for index in range(enemy_kinds.size()):
		var enemy = game.debug_spawn_enemy(enemy_kinds[index], game.player.global_position + enemy_offsets[index])
		if enemy.enemy_kind == "errata":
			enemy.teleport_pending = true
			enemy.teleport_charge = 0.35
		elif enemy.enemy_kind == "archivist":
			enemy.support_timer = 0.35
		elif enemy.enemy_kind == "duelist":
			enemy.parry_window = 0.5
		game.spawn_word(enemy.global_position + Vector2(0, -28), enemy_kinds[index].to_upper(), Color("fff8e0"))

	var pickup_kinds := ["bomb", "magnet", "frenzy", "ward", "hourglass"]
	for index in range(pickup_kinds.size()):
		var offset := Vector2(-168 + index * 84, 62)
		game.spawn_pickup(pickup_kinds[index], game.player.global_position + offset, 1)
		game.spawn_word(game.player.global_position + offset + Vector2(0, 24), pickup_kinds[index].to_upper(), Color("f2b344"))
	paused = true


func _capture(filename: String) -> void:
	game.hud.debug_finish_popup_transition()
	var output_dir := ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_fail("active display server has no viewport texture", 2)
		return
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		_fail("save_png error %d for %s" % [result, filename], 1)
		return
	print("INKBOUND_CAPTURE_FRAME file=%s size=%dx%d" % [filename, image.get_width(), image.get_height()])


func _fail(message: String, code: int) -> void:
	capture_failed = true
	push_error("INKBOUND_CAPTURE_FAIL: " + message)
	paused = false
	game.free()
	quit(code)
