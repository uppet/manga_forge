extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const ComicFXScript = preload("res://scripts/comic_fx.gd")

var frames := 0
var game: Node
var failed := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_session_ui")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(717171)


func _process(_delta: float) -> bool:
	frames += 1
	match frames:
		2:
			game.lifetime_runs = 4
			game.lifetime_kills = 80
			game.highest_wave = 12
			game.completed_endings.assign(["keep"])
			game.checkpoint_data = {
				"checkpoint_schema": 1,
				"wave": 6,
				"kills": 54,
				"score": 8370,
				"difficulty_id": "standard",
				"contract_id": "open-draft",
				"saved_at_unix": int(Time.get_unix_time_from_system()),
				"player": {"level": 10},
			}
			game.hud.show_title(game._meta_snapshot())
			paused = true
		8:
			_capture("last-inkwarden-session-title.png")
			game.hud._show_loadout()
			game.hud.debug_finish_popup_transition()
		10:
			_capture("last-inkwarden-starting-armory.png")
			game.hud._cancel_loadout()
			game.hud._toggle_story()
			game.hud.debug_finish_popup_transition()
		12:
			_capture("last-inkwarden-story-archive.png")
			game.hud._toggle_story()
			game.hud.debug_finish_popup_transition()
			game.hud.hide_title()
			game.run_started = true
			game.manually_paused = true
			game._sync_pause_state()
			game.hud.debug_finish_popup_transition()
		16:
			_capture("last-inkwarden-save-return.png")
			game.manually_paused = false
			game._sync_pause_state()
			game.hud.debug_finish_popup_transition()
			_prepare_supplies()
		22:
			_capture("last-inkwarden-recovery-aoe.png")
			paused = false
			var worst_case_choices: Array[Dictionary] = [
				Content.upgrade("greatbrush"),
				Content.upgrade("needlepoint"),
				Content.upgrade("execution-clause"),
				Content.upgrade("last-word"),
			]
			game.hud.show_upgrade(worst_case_choices)
			game.hud.debug_finish_upgrade_transition()
		26:
			_capture("last-inkwarden-upgrade-cards.png")
			game.hud.upgrade_visible = false
			game.hud.upgrade_panel.visible = false
			game.hud.current_choices.clear()
			paused = false
			game.offer_relic_draft("FIELD RELIC · CHOOSE ONE MEMORY")
			game.hud.debug_finish_popup_transition()
		28:
			_capture("last-inkwarden-relic-draft.png")
			game.hud._choose_relic(0)
			game.hud.debug_finish_popup_transition()
			paused = false
			_prepare_ink_art()
		30:
			game.player.debug_ink_art(Vector2.RIGHT)
			paused = true
		33:
			_capture("last-inkwarden-ink-art.png")
			paused = false
			_prepare_page_directive()
		35:
			game.directive_zone._physics_process(3.4)
			paused = true
		37:
			_capture("last-inkwarden-page-directive.png")
			paused = false
			_prepare_route_hazard()
		41:
			_capture("last-inkwarden-route-hazard.png")
			paused = false
			_prepare_boss_hud()
		43:
			_capture("last-inkwarden-boss-hud.png")
			game.hud.set_boss("", 0.0, 0.0)
			game.hud.show_victory({
				"won": true,
				"ending": "keep",
				"wave": 12,
				"level": 18,
				"score": 42860,
				"kills": 186,
				"best_score": 42860,
				"memory_earned": 24,
				"archive_rank": 5,
				"duration_seconds": 1187,
				"difficulty": "standard",
				"contract_name": "OPEN DRAFT",
				"proof_depth": 0,
				"weapon_form": "GREATBRUSH",
				"relic_count": 3,
				"directives_completed": 7,
				"directives_offered": 9,
			})
			game.hud.debug_finish_popup_transition()
		45:
			_capture("last-inkwarden-victory-results.png")
			game.hud._skip_victory_credits_to_thanks()
		47:
			_capture("last-inkwarden-thank-you.png")
			print("INKBOUND_SESSION_CAPTURE_OK gallery=13 size=%dx%d" % [root.get_texture().get_width(), root.get_texture().get_height()])
			paused = false
			game.debug_clear_save_files()
			game.free()
			quit(0)
			return true
	return false


func _prepare_supplies() -> void:
	game.spawn_timer = 999.0
	game.player.controls_enabled = false
	game.player.global_position = Vector2.ZERO
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for pickup in get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and pickup.get_parent() == game:
			pickup.free()
	game.spawn_pickup("heal", Vector2(-132, 16), 1)
	game.spawn_pickup("bomb", Vector2(132, 16), 1)
	game.spawn_word(Vector2(-132, 48), "RECOVERY · +HP", Color("fff8e0"))
	game.spawn_word(Vector2(132, 48), "INK BOMB · 118PX AOE", Color("f2b344"))
	paused = true


func _prepare_ink_art() -> void:
	game.spawn_timer = 999.0
	game.player.controls_enabled = false
	game.player.global_position = Vector2(-54, 0)
	game.player.health = game.player.max_health
	game.hud.set_health(game.player.health, game.player.max_health)
	game.player.weapon_form = "GREATBRUSH"
	game.player.apply_upgrade("living-ink")
	game.player.apply_upgrade("violent-margin")
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for pickup in get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and pickup.get_parent() == game:
			pickup.free()
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	if game.hud.achievement_toast_tween != null and game.hud.achievement_toast_tween.is_valid():
		game.hud.achievement_toast_tween.kill()
	game.hud.achievement_toast.visible = false
	game.hud.achievement_queue.clear()
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var enemy = game.debug_spawn_enemy("brute" if index % 3 == 0 else "mask", Vector2.from_angle(angle) * 76.0)
		enemy.max_health = 500.0
		enemy.health = 500.0
		enemy.speed = 0.0
		enemy.contact_damage = 0.0
	game.hud.set_objective("GREATBRUSH INK ART · FINAL PERIOD · B / E")


func _prepare_page_directive() -> void:
	game._expire_page_directive()
	game.spawn_timer = 999.0
	game.wave = 6
	game.player.controls_enabled = false
	game.player.global_position = Vector2.ZERO
	game.player.health = game.player.max_health
	game.hud.set_health(game.player.health, game.player.max_health)
	game.hud.set_run_stats(6, 12480, true)
	game.arena.set_chapter(2)
	game.arena.set_route("chain-vault")
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for pickup in get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and pickup.get_parent() == game:
			pickup.free()
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	game.debug_spawn_squad("censor-escort")
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.max_health = 500.0
			enemy.health = 500.0
			enemy.speed = 0.0
			enemy.contact_damage = 0.0
	game.debug_start_directive("bindery-circle")
	game.directive_zone.global_position = game.player.global_position
	game.directive_zone_position = game.player.global_position
	game.hud.set_objective("CHAIN · IRON CENSOR ESCORT · HOLD THE FORBIDDEN CIRCLE")


func _prepare_route_hazard() -> void:
	game._expire_page_directive()
	game.spawn_timer = 999.0
	game.wave = 10
	game.player.controls_enabled = false
	game.player.global_position = Vector2(0.0, 116.0)
	game.player.health = game.player.max_health
	game.hud.set_health(game.player.health, game.player.max_health)
	game.hud.set_run_stats(10, 28740, true)
	game.arena.set_chapter(3)
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	game._activate_route("red-press")
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	if game.hud.achievement_toast_tween != null and game.hud.achievement_toast_tween.is_valid():
		game.hud.achievement_toast_tween.kill()
	game.hud.achievement_toast.visible = false
	game.hud.achievement_queue.clear()
	game.debug_force_route_hazard()
	game.route_hazard.points.assign([Vector2(-178.0, -12.0), Vector2(0.0, 78.0), Vector2(178.0, -4.0)])
	game.route_hazard.phase_time = 0.72
	game.route_hazard.queue_redraw()
	for position in [Vector2(-178.0, -12.0), Vector2(0.0, 78.0), Vector2(178.0, -4.0)]:
		var enemy = game.debug_spawn_enemy("duelist", position + Vector2(0.0, -28.0))
		enemy.max_health = 500.0
		enemy.health = 500.0
		enemy.speed = 0.0
		enemy.contact_damage = 0.0
	game.hud.set_objective("PRESS · TRIPLE VERDICT · READ ALL THREE STAMPS")
	paused = true


func _prepare_boss_hud() -> void:
	game._expire_page_directive()
	game.spawn_timer = 999.0
	game.wave = 4
	game.player.controls_enabled = false
	game.player.global_position = Vector2(-62.0, 18.0)
	game.hud.set_run_stats(4, 5210, true)
	game.hud.set_objective("RED EDITOR · PAGE 4")
	game.hud.set_ink_art("PALIMPSEST RING", 0.0, 8.0)
	if is_instance_valid(game.route_hazard):
		game.route_hazard.phase = "idle"
		game.route_hazard.points.clear()
		game.route_hazard.queue_redraw()
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	var boss = game.debug_spawn_enemy("editor", Vector2(70.0, -2.0))
	boss.max_health = 100.0
	boss.health = 72.0
	boss.speed = 0.0
	boss.contact_damage = 0.0
	game.hud.set_boss("THE RED EDITOR", boss.health, boss.max_health)
	paused = true


func _capture(filename: String) -> void:
	game.hud.debug_finish_popup_transition()
	if failed:
		return
	var output_dir := ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_fail("viewport texture unavailable")
		return
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		_fail("save_png error %d for %s" % [result, filename])
		return
	print("INKBOUND_SESSION_CAPTURE_FRAME file=%s size=%dx%d" % [filename, image.get_width(), image.get_height()])


func _fail(message: String) -> void:
	failed = true
	push_error("INKBOUND_SESSION_CAPTURE_FAIL: " + message)
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(1)
