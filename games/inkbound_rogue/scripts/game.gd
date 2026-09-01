extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PlayerWaveScript = preload("res://scripts/player_wave.gd")
const FxScript = preload("res://scripts/comic_fx.gd")
const ArenaScript = preload("res://scripts/arena.gd")
const HudScript = preload("res://scripts/hud.gd")
const CutsceneScript = preload("res://scripts/cutscene.gd")
const DirectiveZoneScript = preload("res://scripts/directive_zone.gd")
const RouteHazardScript = preload("res://scripts/route_hazard.gd")
const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")

const PAPER := Color("fff8e0")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")
const STEEL := Color("96aab0")

const SOUNDS := {
	"slash": preload("res://assets/audio/slash.wav"),
	"slash_heavy": preload("res://assets/audio/slash_heavy.wav"),
	"slash_light": preload("res://assets/audio/slash_light.wav"),
	"seal_cast": preload("res://assets/audio/seal_cast.wav"),
	"ink_art": preload("res://assets/audio/ink_art.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"dash": preload("res://assets/audio/dash.wav"),
	"enemy_cast": preload("res://assets/audio/enemy_cast.wav"),
	"enemy_dash": preload("res://assets/audio/enemy_dash.wav"),
	"teleport": preload("res://assets/audio/teleport.wav"),
	"parry": preload("res://assets/audio/parry.wav"),
	"shield": preload("res://assets/audio/shield.wav"),
	"heal": preload("res://assets/audio/heal.wav"),
	"ink_burst": preload("res://assets/audio/ink_burst.wav"),
	"powerup": preload("res://assets/audio/powerup.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"level_up": preload("res://assets/audio/level_up.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"relic": preload("res://assets/audio/relic.wav"),
	"boss_warning": preload("res://assets/audio/boss_warning.wav"),
	"boss_down": preload("res://assets/audio/boss_down.wav"),
	"ui_move": preload("res://assets/audio/ui_move.wav"),
	"ui_confirm": preload("res://assets/audio/ui_confirm.wav"),
	"ui_cancel": preload("res://assets/audio/ui_cancel.wav"),
	"save": preload("res://assets/audio/save.wav"),
}

const MUSIC := {
	"archive": preload("res://assets/audio/music_archive.wav"),
	"bindery": preload("res://assets/audio/music_bindery.wav"),
	"finale": preload("res://assets/audio/music_finale.wav"),
	"boss_editor": preload("res://assets/audio/music_editor.wav"),
	"boss_binder": preload("res://assets/audio/music_binder.wav"),
	"boss_author": preload("res://assets/audio/music_author.wav"),
}

const SOUND_COOLDOWNS_MSEC := {
	"hit": 22,
	"enemy_cast": 90,
	"enemy_dash": 180,
	"teleport": 220,
	"parry": 120,
	"shield": 90,
	"heal": 180,
	"ui_move": 45,
}

const BOSS_KINDS := ["editor", "binder", "author"]
const REBIND_ACTION_IDS := ["move_up", "move_down", "move_left", "move_right", "attack", "dash", "special", "pause", "options"]
const SAVE_SCHEMA := 12
const CHECKPOINT_SCHEMA := 1

var arena: InkboundArena
var player: InkboundPlayer
var camera: Camera2D
var hud: InkboundHUD
var cutscene: InkboundCutscene
var route_hazard
var rng := RandomNumberGenerator.new()

var elapsed := 0.0
var spawn_timer := 0.5
var wave := 1
var kills := 0
var score := 0
var best_score := 0
var best_kills := 0
var game_over := false
var choosing_upgrade := false
var choosing_relic := false
var choosing_event := false
var manually_paused := false
var current_choices: Array[Dictionary] = []
var current_relic_choices: Array[Dictionary] = []
var pending_relic_sources: Array[String] = []
var current_event: Dictionary = {}
var seen_events: Array[String] = []
var active_route_id := ""
var chosen_routes: Array[String] = []
var discovered_routes: Array[String] = []
var route_enemy_bias: Array[String] = []
var route_enemy_bias_chance := 0.0
var route_enemy_health := 1.0
var route_enemy_damage := 1.0
var route_enemy_speed := 1.0
var route_spawn_interval := 1.0
var route_enemy_cap := 1.0
var route_recovery := 1.0
var route_elite_bonus := 0.0
var route_score_multiplier := 1.0
var route_shard_multiplier := 1.0
var shake_strength := 0.0
var hit_stop_active := false
var test_mode := false
var deterministic_simulation := false
var enemy_spawn_serial := 0
var deterministic_echoes: Array[Dictionary] = []
var test_force_english := true
var using_gamepad := false
var application_focused := true
var focus_pause_engaged := false
var active_locale := Localization.LANGUAGE_ENGLISH
var story_seen: Dictionary = {}
var replaying_story := false
var manual_open := false
var onboarding_pending := false
var field_manual_seen := false
var pending_boss_kind := ""
var run_won := false
var ending_id := ""
var run_shards := 0
var meta_shards := 0
var relic_ids: Array[String] = []
var codex_kills: Dictionary = {}
var meta_upgrades: Dictionary = {
	"vital": 0,
	"edge": 0,
	"fortune": 0,
	"stride": 0,
	"inkwell": 0,
	"thread": 0,
}
var completed_endings: Array[String] = []
var lifetime_runs := 0
var run_started := false
var run_committed := false
var difficulty_id := "standard"
var difficulty_health := 1.0
var difficulty_damage := 1.0
var difficulty_speed := 1.0
var contract_id := "open-draft"
var starting_weapon_id := "marginalia"
var contract_enemy_health := 1.0
var contract_enemy_damage := 1.0
var contract_enemy_speed := 1.0
var contract_player_health := 1.0
var contract_player_damage := 1.0
var contract_spawn_interval := 1.0
var contract_enemy_cap := 1.0
var contract_recovery := 1.0
var contract_elite_bonus := 0.0
var contract_wave_duration := 42.0
var contract_score_multiplier := 1.0
var contract_shard_multiplier := 1.0
var proof_depth := 0
var max_proof_depth := 0
var preferred_proof_depth := 0
var highest_proof_cleared := -1
var proof_enemy_health := 1.0
var proof_enemy_damage := 1.0
var proof_enemy_speed := 1.0
var proof_player_health := 1.0
var proof_dash_cooldown := 1.0
var proof_spawn_interval := 1.0
var proof_enemy_cap := 1.0
var proof_recovery := 1.0
var proof_elite_bonus := 0.0
var proof_boss_health := 1.0
var proof_wave_duration := 1.0
var proof_score_multiplier := 1.0
var proof_shard_multiplier := 1.0
var daily_run := false
var daily_id := ""
var run_seed := 0
var daily_records: Dictionary = {}
var daily_current_streak := 0
var daily_best_streak := 0
var daily_last_clear_id := ""
var lifetime_daily_clears := 0
var debug_daily_date_override := ""
var contract_wins: Dictionary = {}
var contract_best: Dictionary = {}
var contract_attempts: Dictionary = {}
var unlocked_achievements: Array[String] = []
var discovered_relics: Array[String] = []
var discovered_upgrades: Array[String] = []
var lifetime_kills := 0
var lifetime_memory_earned := 0
var highest_wave := 1
var highest_level := 1
var redline_wins := 0
var recent_runs: Array[Dictionary] = []
var last_run_summary: Dictionary = {}
var run_start_unlock_ids: Array[String] = []
var music_player: AudioStreamPlayer
var music_fade_player: AudioStreamPlayer
var music_crossfade: Tween
var current_music := ""
var last_sound_id := ""
var sound_last_played_msec: Dictionary = {}
var settings: Dictionary = {
	"master": 0.8,
	"music": 0.65,
	"sfx": 0.85,
	"vibration": true,
	"aim_assist": 0.45,
	"screen_shake": 1.0,
	"hit_stop": true,
	"reduced_flashes": false,
	"fullscreen": false,
	"language": Localization.LANGUAGE_AUTO,
}
var custom_bindings: Dictionary = {}
var default_binding_events: Dictionary = {}
var input_actions_initialized := false
var save_path := "user://inkbound_save.json"
var backup_save_path := "user://inkbound_save.backup.json"
var corrupt_save_path := "user://inkbound_save.corrupt.json"
var corrupt_backup_save_path := "user://inkbound_save.backup.corrupt.json"
var temp_save_path := "user://inkbound_save.tmp.json"
var save_generation := 0
var save_recovered := false
var save_corrupt_detected := false
var save_incompatible := false
var checkpoint_path := "user://inkbound_checkpoint.json"
var backup_checkpoint_path := "user://inkbound_checkpoint.backup.json"
var corrupt_checkpoint_path := "user://inkbound_checkpoint.corrupt.json"
var corrupt_backup_checkpoint_path := "user://inkbound_checkpoint.backup.corrupt.json"
var temp_checkpoint_path := "user://inkbound_checkpoint.tmp.json"
var checkpoint_data: Dictionary = {}
var checkpoint_recovered := false
var checkpoint_corrupt_detected := false
var restoring_checkpoint := false
var kills_since_heal_drop := 0
var kills_since_supply_drop := 0
var heal_drops_spawned := 0
var combat_drops_spawned := 0
var active_directive: Dictionary = {}
var directive_progress := 0.0
var directive_target := 0.0
var directive_completed := false
var directive_history: Array[String] = []
var squad_history: Array[String] = []
var active_squad_id := ""
var active_squad_name := ""
var encounter_started_wave := 0
var pending_page_encounter := false
var run_directives_started := 0
var run_directives_completed := 0
var lifetime_directives_completed := 0
var best_directives_completed := 0
var directive_score_bonus := 0
var directive_zone_position := Vector2.ZERO
var directive_zone: InkboundDirectiveZone


func _ready() -> void:
	# Gameplay nodes inherit this mode and must stop with SceneTree.paused.
	# HUD, cutscenes, and music opt into ALWAYS individually so menus and story
	# playback remain responsive while the simulation is frozen.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	Engine.time_scale = 1.0
	_prepare_default_input_actions()
	_capture_default_binding_events()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	rng.randomize()
	_load_save()
	_apply_language_setting()
	_load_checkpoint()
	_apply_custom_bindings()
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = -15.0
	add_child(music_player)
	music_fade_player = AudioStreamPlayer.new()
	music_fade_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_fade_player.volume_db = -60.0
	add_child(music_fade_player)
	play_music("archive")

	arena = ArenaScript.new()
	add_child(arena)

	player = PlayerScript.new()
	player.global_position = Vector2.ZERO
	add_child(player)
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)
	player.build_changed.connect(_on_build_changed)
	player.build_milestone_unlocked.connect(_on_build_milestone_unlocked)
	player.ink_art_changed.connect(_on_ink_art_changed)

	route_hazard = RouteHazardScript.new().setup(self, player)
	add_child(route_hazard)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true
	player.add_child(camera)

	hud = HudScript.new()
	add_child(hud)
	hud.upgrade_selected.connect(_on_upgrade_selected)
	hud.relic_selected.connect(_on_relic_selected)
	hud.event_selected.connect(_on_event_selected)
	hud.restart_requested.connect(_restart)
	hud.pause_requested.connect(_toggle_pause)
	hud.start_requested.connect(_on_start_requested)
	hud.daily_requested.connect(_on_daily_requested)
	hud.continue_requested.connect(_on_continue_requested)
	hud.save_return_requested.connect(_on_save_return_requested)
	hud.story_requested.connect(_on_story_replay_requested)
	hud.meta_upgrade_requested.connect(_on_meta_upgrade_requested)
	hud.setting_adjusted.connect(_on_setting_adjusted)
	hud.binding_changed.connect(_on_binding_changed)
	hud.bindings_reset_requested.connect(_on_bindings_reset_requested)
	hud.manual_visibility_changed.connect(_on_manual_visibility_changed)
	hud.ui_sound_requested.connect(play_sound)
	hud.set_health(player.health, player.max_health)
	hud.set_xp(player.xp, player.xp_needed, player.level)
	hud.set_shards(run_shards)
	hud.set_build(player.get_build_summary())
	_on_ink_art_changed(str(player.ink_art_profile().get("name", "INK ART")), player.ink_art_cooldown, player.ink_art_cooldown_total())
	hud.set_settings(settings)
	hud.set_bindings(_binding_snapshot())
	_apply_meta_progression()
	_evaluate_achievements(false)
	_apply_settings()
	_set_input_mode(not Input.get_connected_joypads().is_empty())

	cutscene = CutsceneScript.new()
	add_child(cutscene)
	cutscene.finished.connect(_on_cutscene_finished)
	cutscene.choice_selected.connect(_on_story_choice)
	hud.set_input_enabled(application_focused)
	cutscene.set_input_enabled(application_focused)

	for i in range(3):
		spawn_enemy("mask", Vector2.from_angle(TAU * float(i) / 3.0) * 130.0)
	if test_mode:
		run_started = true
	else:
		hud.show_title(_meta_snapshot())
		if checkpoint_recovered:
			hud.show_device_notice("SAVED DRAFT RECOVERED FROM BACKUP")
		elif checkpoint_corrupt_detected:
			hud.show_device_notice("DAMAGED DRAFT PRESERVED  ·  START A NEW GAME")
		elif save_recovered:
			hud.show_device_notice("ARCHIVE RECOVERED FROM BACKUP")
		elif save_incompatible:
			hud.show_device_notice("ARCHIVE REQUIRES A NEWER GAME VERSION")
		elif save_corrupt_detected:
			hud.show_device_notice("DAMAGED ARCHIVE PRESERVED  ·  NEW PROFILE")
	var recorder := _playtest_recorder()
	if recorder != null:
		recorder.attach_game(self)
	_sync_pause_state()


func _playtest_recorder() -> Node:
	return get_node_or_null("/root/PlaytestSession")


func uses_deterministic_simulation() -> bool:
	return deterministic_simulation


func reduced_flashes_enabled() -> bool:
	return settings.get("reduced_flashes", false) == true


func assisted_aim_direction(origin: Vector2, raw_direction: Vector2, max_distance: float = 84.0) -> Vector2:
	# This is deliberately a direction correction, not lock-on or auto-fire. It
	# preserves the player's right-stick intent while making short melee strokes
	# less brittle on a controller.
	var direction := raw_direction.normalized() if raw_direction.length_squared() > 0.001 else Vector2.RIGHT
	var strength := float(settings.get("aim_assist", 0.45))
	if strength <= 0.001 or max_distance <= 0.0:
		return direction
	var maximum_angle := deg_to_rad(32.0)
	var best_direction := direction
	var best_score := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not (candidate is Node2D) or candidate.get("dead") == true:
			continue
		var offset: Vector2 = (candidate as Node2D).global_position - origin
		var distance := offset.length()
		if distance <= 0.001 or distance > max_distance:
			continue
		var candidate_direction := offset / distance
		var angle := absf(direction.angle_to(candidate_direction))
		if angle > maximum_angle:
			continue
		var score := angle / maximum_angle + distance / max_distance * 0.18
		if score < best_score:
			best_score = score
			best_direction = candidate_direction
	if best_score == INF:
		return direction
	return direction.lerp(best_direction, strength).normalized()


func record_playtest_event(kind: String, data: Dictionary = {}) -> void:
	var recorder := _playtest_recorder()
	if recorder != null and bool(recorder.get("enabled")):
		recorder.record_event(kind, data)


func request_playtest_survey(reason: String) -> void:
	var recorder := _playtest_recorder()
	if recorder != null and bool(recorder.get("enabled")):
		recorder.request_survey(reason)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_application_focus(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_application_focus(true)


func _set_application_focus(focused: bool) -> void:
	if application_focused == focused:
		return
	application_focused = focused
	record_playtest_event("focus_changed", {"focused": focused, "run_started": run_started, "wave": wave})
	if is_instance_valid(hud):
		hud.set_input_enabled(focused)
	if is_instance_valid(cutscene):
		cutscene.set_input_enabled(focused)
	if not focused:
		for device in Input.get_connected_joypads():
			Input.stop_joy_vibration(device)
		if run_started and not game_over and not run_won and not manually_paused:
			manually_paused = true
			focus_pause_engaged = true
		_sync_pause_state()
		return
	_set_input_mode(not Input.get_connected_joypads().is_empty())
	_sync_pause_state()
	if focus_pause_engaged and is_instance_valid(hud):
		hud.show_device_notice("FOCUS RESTORED  ·  PRESS PAUSE TO CONTINUE")


func debug_set_application_focus(focused: bool) -> void:
	_set_application_focus(focused)


func _process(delta: float) -> void:
	if not run_started or game_over or choosing_upgrade or choosing_relic or choosing_event or manually_paused or manual_open or run_won:
		return
	elapsed += delta
	var new_wave := 1 + int(elapsed / (contract_wave_duration * proof_wave_duration))
	if new_wave > wave:
		_expire_page_directive()
		wave = new_wave
		record_playtest_event("page_started", {"page": wave, "health": player.health, "level": player.level, "kills": kills})
		pending_page_encounter = true
		highest_wave = maxi(highest_wave, wave)
		_evaluate_achievements()
		player.on_new_wave()
		if wave == 5:
			arena.set_chapter(2)
			play_music("bindery")
		elif wave == 9:
			arena.set_chapter(3)
			play_music("finale")
		spawn_word(player.global_position + Vector2(0, -64), "PAGE %d" % wave, GOLD)
		if not test_mode and wave in [5, 9]:
			_offer_route(2 if wave == 5 else 3)
			return
		if wave in [3, 7, 10]:
			_offer_chapter_event(1 if wave == 3 else (2 if wave == 7 else 3))
			return
		if wave in [4, 8, 12] and get_tree().get_nodes_in_group("bosses").is_empty():
			var chapter_boss: String = {4: "editor", 8: "binder", 12: "author"}[wave]
			if chapter_boss == "author" and not story_seen.has("act3_confrontation"):
				pending_boss_kind = chapter_boss
				_play_story("act3_confrontation")
			else:
				spawn_enemy(chapter_boss)
		_start_page_encounter(wave)
		if not choosing_event and not (is_instance_valid(cutscene) and cutscene.active):
			_save_checkpoint("page-%d" % wave)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(0.18, (1.35 - elapsed * 0.008) * contract_spawn_interval * route_spawn_interval * proof_spawn_interval)
		var cap := mini(72, int(round(float(10 + wave * 4) * contract_enemy_cap * route_enemy_cap * proof_enemy_cap)))
		if get_tree().get_nodes_in_group("enemies").size() < cap:
			spawn_enemy(_roll_enemy_kind())

	var raw_score := int(elapsed * 10.0) + kills * 100 + (player.level - 1) * 250 + directive_score_bonus
	score = int(round(float(raw_score) * contract_score_multiplier * route_score_multiplier * proof_score_multiplier))
	hud.set_run_stats(wave, score, player.dash_cooldown <= 0.0)
	_update_boss_hud()
	_update_camera_shake(delta)


func _update_boss_hud() -> void:
	var bosses := get_tree().get_nodes_in_group("bosses")
	if bosses.is_empty():
		hud.set_boss("", 0.0, 0.0)
		return
	var boss = bosses[0]
	var boss_name := Localization.text(Content.ENEMIES.get(boss.enemy_kind, {}).get("name", boss.enemy_kind))
	hud.set_boss(boss_name, boss.health, boss.max_health)


func _chapter_for_page(page: int) -> int:
	return 1 if page < 5 else (2 if page < 9 else 3)


func _start_page_encounter(page: int) -> bool:
	if page < 1 or encounter_started_wave == page:
		pending_page_encounter = false
		return false
	pending_page_encounter = false
	encounter_started_wave = page
	active_squad_id = ""
	active_squad_name = ""
	if page in [4, 8, 12]:
		active_directive.clear()
		directive_progress = 0.0
		directive_target = 0.0
		directive_completed = false
		_clear_directive_zone()
		hud.hide_page_directive()
		record_playtest_event("boss_page_started", {"page": page})
		return true
	var chapter := _chapter_for_page(page)
	_spawn_page_squad(chapter)
	var directive_pool: Array[Dictionary] = Content.directives_for_chapter(chapter, directive_history)
	if directive_pool.is_empty():
		directive_pool = Content.directives_for_chapter(chapter)
	if directive_pool.is_empty():
		return false
	active_directive = directive_pool[rng.randi_range(0, directive_pool.size() - 1)]
	var directive_id := str(active_directive.get("id", ""))
	if directive_id not in directive_history:
		directive_history.append(directive_id)
	directive_progress = 0.0
	directive_target = maxf(1.0, float(active_directive.get("target", 1.0)))
	directive_completed = false
	run_directives_started += 1
	_update_directive_hud(false)
	var title := str(active_directive.get("title", "PAGE DIRECTIVE"))
	spawn_word(player.global_position + Vector2(0, -54), title, CRIMSON)
	if str(active_directive.get("kind", "")) == "hold":
		_spawn_directive_zone()
	elif str(active_directive.get("kind", "")) == "elites":
		_ensure_directive_elites(int(ceil(directive_target)))
	record_playtest_event("page_directive_started", {
		"page": page,
		"directive": str(active_directive.get("id", "")),
		"squad": active_squad_id,
		"target": directive_target,
	})
	return true


func _spawn_page_squad(chapter: int) -> int:
	var squad_pool: Array[Dictionary] = Content.squads_for_chapter(chapter, squad_history)
	if squad_pool.is_empty():
		squad_pool = Content.squads_for_chapter(chapter)
	if squad_pool.is_empty():
		return 0
	var squad: Dictionary = squad_pool[rng.randi_range(0, squad_pool.size() - 1)]
	return _spawn_squad_data(squad)


func _spawn_squad_data(squad: Dictionary) -> int:
	if squad.is_empty():
		return 0
	active_squad_id = str(squad.get("id", ""))
	active_squad_name = str(squad.get("name", "ENCOUNTER SQUAD"))
	if active_squad_id not in squad_history:
		squad_history.append(active_squad_id)
	var members: Array = squad.get("members", [])
	var formation := str(squad.get("formation", "ring"))
	var elite_count := clampi(int(squad.get("elites", 0)), 0, members.size())
	var base_angle := rng.randf_range(0.0, TAU)
	var forward := Vector2.from_angle(base_angle)
	var sideways := forward.rotated(PI * 0.5)
	for index in range(members.size()):
		var spawn_at := player.global_position
		match formation:
			"line":
				spawn_at += forward * 158.0 + sideways * (float(index) - float(members.size() - 1) * 0.5) * 34.0
			"wedge":
				var row := int(index / 2)
				var side := -1.0 if index % 2 == 0 else 1.0
				spawn_at += forward * (142.0 + row * 28.0) + sideways * side * (20.0 + row * 13.0)
			_:
				spawn_at += Vector2.from_angle(base_angle + TAU * float(index) / float(maxi(1, members.size()))) * 152.0
		var enemy := spawn_enemy(str(members[index]), clamp_to_arena(spawn_at, 24.0))
		if index < elite_count and not enemy.is_elite:
			enemy.promote_to_elite()
	spawn_word(player.global_position + Vector2(0, -40), active_squad_name, PAPER)
	return members.size()


func _ensure_directive_elites(required: int) -> void:
	var existing := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == self and bool(enemy.get("is_elite")):
			existing += 1
	var needed := maxi(0, required - existing)
	for index in range(needed):
		var angle := TAU * float(index) / float(maxi(1, needed)) + rng.randf_range(-0.2, 0.2)
		var enemy := spawn_enemy(_roll_enemy_kind(), clamp_to_arena(player.global_position + Vector2.from_angle(angle) * 172.0, 24.0))
		enemy.promote_to_elite()


func _spawn_directive_zone(restored_progress: float = 0.0, restored_position: Vector2 = Vector2.INF) -> void:
	_clear_directive_zone()
	if restored_position == Vector2.INF:
		var angle := rng.randf_range(0.0, TAU)
		directive_zone_position = clamp_to_arena(player.global_position + Vector2.from_angle(angle) * rng.randf_range(105.0, 155.0), 58.0)
	else:
		directive_zone_position = clamp_to_arena(restored_position, 58.0)
	directive_zone = DirectiveZoneScript.new().setup(directive_zone_position, player, directive_target, restored_progress)
	add_child(directive_zone)
	directive_zone.progress_changed.connect(_on_directive_zone_progress)
	directive_zone.completed.connect(_on_directive_zone_completed)


func _clear_directive_zone() -> void:
	for zone in get_tree().get_nodes_in_group("directive_zones"):
		if is_instance_valid(zone) and zone.get_parent() == self:
			zone.queue_free()
	if is_instance_valid(directive_zone) and not directive_zone.is_queued_for_deletion():
		directive_zone.queue_free()
	directive_zone = null


func _on_directive_zone_progress(current: float, target: float, occupied: bool) -> void:
	if active_directive.is_empty() or directive_completed:
		return
	directive_progress = clampf(current, 0.0, target)
	directive_target = target
	_update_directive_hud(occupied)


func _on_directive_zone_completed() -> void:
	directive_progress = directive_target
	_complete_page_directive()


func _advance_page_directive(kind: String, amount: float = 1.0) -> void:
	if active_directive.is_empty() or directive_completed or str(active_directive.get("kind", "")) != kind:
		return
	directive_progress = minf(directive_target, directive_progress + maxf(0.0, amount))
	_update_directive_hud(false)
	if directive_progress >= directive_target:
		_complete_page_directive()


func _complete_page_directive() -> bool:
	if active_directive.is_empty() or directive_completed:
		return false
	directive_completed = true
	directive_progress = directive_target
	run_directives_completed += 1
	lifetime_directives_completed += 1
	directive_score_bonus += 500 + _chapter_for_page(wave) * 250
	var reward := str(active_directive.get("reward", "shards"))
	var amount := float(active_directive.get("reward_amount", 1.0))
	match reward:
		"guard":
			player.guard += amount
		"heal":
			player.heal(amount)
		"upgrade":
			_grant_random_upgrade()
		"art":
			player.recharge_ink_art(99.0)
			player.guard += 2.0
		"relic":
			offer_relic_draft("PAGE DIRECTIVE REWARD")
		"heal_shards":
			player.heal(amount)
			collect_shards(int(amount))
		_:
			collect_shards(int(amount))
	_update_directive_hud(false)
	_clear_directive_zone()
	play_sound("level_up", 1.18)
	vibrate(0.2, 0.55, 0.14)
	spawn_word(player.global_position + Vector2(0, -52), "DIRECTIVE COMPLETE!", GOLD)
	_evaluate_achievements()
	if not test_mode:
		_save_run()
	_save_checkpoint("directive-" + str(active_directive.get("id", "complete")))
	record_playtest_event("page_directive_completed", {
		"page": wave,
		"directive": str(active_directive.get("id", "")),
		"reward": reward,
		"elapsed": elapsed,
	})
	return true


func _update_directive_hud(occupied: bool) -> void:
	if active_directive.is_empty():
		hud.hide_page_directive()
		return
	hud.set_page_directive(
		str(active_directive.get("title", "PAGE DIRECTIVE")),
		str(active_directive.get("kind", "kills")),
		directive_progress,
		directive_target,
		str(active_directive.get("reward_text", "MEMORY")),
		directive_completed,
		occupied
	)


func _expire_page_directive() -> void:
	if not active_directive.is_empty() and not directive_completed:
		spawn_word(player.global_position + Vector2(0, -48), "DIRECTIVE EXPIRED", CRIMSON)
	active_directive.clear()
	directive_progress = 0.0
	directive_target = 0.0
	directive_completed = false
	_clear_directive_zone()
	if is_instance_valid(hud):
		hud.hide_page_directive()


func _roll_enemy_kind() -> String:
	var effective_bias_chance := route_enemy_bias_chance * (0.45 if wave <= 3 else 1.0)
	if not route_enemy_bias.is_empty() and rng.randf() < effective_bias_chance:
		return route_enemy_bias[rng.randi_range(0, route_enemy_bias.size() - 1)]
	var roll := rng.randf()
	if wave >= 10 and roll < 0.08:
		return "duelist"
	if wave >= 9 and roll >= 0.08 and roll < 0.16:
		return "archivist"
	if wave >= 8 and roll >= 0.16 and roll < 0.24:
		return "warden"
	if wave >= 7 and roll >= 0.24 and roll < 0.32:
		return "errata"
	if wave >= 6 and roll >= 0.32 and roll < 0.4:
		return "leech"
	if wave >= 5 and roll >= 0.4 and roll < 0.48:
		return "splitter"
	if wave >= 4 and roll >= 0.48 and roll < 0.56:
		return "censor"
	if wave >= 3 and roll >= 0.56 and roll < 0.64:
		return "blot"
	if wave >= 3 and roll >= 0.64 and roll < 0.73:
		return "scribe"
	if wave >= 3 and roll >= 0.73 and roll < 0.82:
		return "brute"
	if wave >= 2 and roll >= 0.82 and roll < 0.9:
		return "dasher"
	return "mask"


func spawn_enemy(kind: String = "mask", at: Vector2 = Vector2.INF) -> InkboundEnemy:
	var spawn_position := at
	if spawn_position == Vector2.INF:
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(190.0, 285.0)
		spawn_position = clamp_to_arena(player.global_position + Vector2.from_angle(angle) * distance, 24.0)
	var enemy: InkboundEnemy = EnemyScript.new().configure(kind, player, wave)
	enemy_spawn_serial += 1
	enemy.simulation_order = enemy_spawn_serial
	if not restoring_checkpoint and kind not in BOSS_KINDS and not enemy.is_elite and rng.randf() < contract_elite_bonus + route_elite_bonus + proof_elite_bonus:
		enemy.promote_to_elite()
	enemy.max_health *= difficulty_health * contract_enemy_health * route_enemy_health * proof_enemy_health * (proof_boss_health if kind in BOSS_KINDS else 1.0)
	enemy.health = enemy.max_health
	enemy.contact_damage *= difficulty_damage * contract_enemy_damage * route_enemy_damage * proof_enemy_damage
	enemy.speed *= difficulty_speed * contract_enemy_speed * route_enemy_speed * proof_enemy_speed
	enemy.global_position = spawn_position
	add_child(enemy)
	if kind in BOSS_KINDS:
		enemy.add_to_group("bosses")
		var boss_name := Localization.text(Content.ENEMIES.get(kind, {}).get("name", kind.to_upper()))
		spawn_word(spawn_position + Vector2(0, -46), boss_name.to_upper(), CRIMSON)
		play_sound("boss_warning")
		play_music(_boss_music_id(kind))
		record_playtest_event("boss_started", {"boss": kind, "page": wave, "health": enemy.max_health})
	enemy.died.connect(_on_enemy_died)
	return enemy


func _on_enemy_died(_enemy: Node, xp_value: int, death_position: Vector2, enemy_kind: String) -> void:
	kills += 1
	kills_since_heal_drop += 1
	kills_since_supply_drop += 1
	lifetime_kills += 1
	player.on_enemy_killed(enemy_kind)
	codex_kills[enemy_kind] = int(codex_kills.get(enemy_kind, 0)) + 1
	_evaluate_achievements()
	var pickup: InkPickup = PickupScript.new().setup(death_position, player, xp_value)
	add_child(pickup)
	if "misprint" in relic_ids and rng.randf() < 0.09:
		spawn_pickup("xp", death_position + Vector2(5, -5), xp_value)
		spawn_word(death_position + Vector2(0, -24), "MISPRINT!", GOLD)
	var is_boss := enemy_kind in BOSS_KINDS
	var is_elite_enemy: bool = bool(_enemy.get("is_elite"))
	record_playtest_event("enemy_defeated", {
		"enemy": enemy_kind,
		"elite": is_elite_enemy,
		"boss": is_boss,
		"page": wave,
		"kill": kills,
		"player_health": player.health,
	})
	if not is_boss:
		_advance_page_directive("kills", 1.0)
		if is_elite_enemy:
			_advance_page_directive("elites", 1.0)
	if _should_drop_heal(is_boss, is_elite_enemy):
		spawn_pickup("heal", death_position + Vector2(7, -4), 1)
		heal_drops_spawned += 1
		kills_since_heal_drop = 0
		if heal_drops_spawned == 1:
			spawn_word(death_position + Vector2(0, -28), "RECOVERY DROP!", PAPER)
	var combat_drop := _combat_drop_for_kill(is_boss, is_elite_enemy)
	if is_boss:
		spawn_pickup("shard", death_position + Vector2(-8, 5), 6)
		spawn_pickup("relic", death_position + Vector2(9, 4), 1)
	elif is_elite_enemy:
		spawn_pickup("shard", death_position + Vector2(-5, 4), 2)
		if rng.randf() < 0.16 + player.luck * 0.18:
			spawn_pickup("relic", death_position + Vector2(7, 2), 1)
	elif rng.randf() < 0.025 + player.luck * 0.06:
		spawn_pickup("shard", death_position + Vector2(5, 3), 1)
	if not combat_drop.is_empty():
		spawn_pickup(combat_drop, death_position + Vector2(0, -9), 1)
		combat_drops_spawned += 1
		kills_since_supply_drop = 0
		if combat_drop == "bomb":
			spawn_word(death_position + Vector2(0, -31), "AOE: INK BOMB!", GOLD)
	var burst: ComicFX = FxScript.new().setup_burst(death_position, CRIMSON, 42.0 if is_boss else 24.0)
	add_child(burst)
	if is_boss:
		spawn_word(death_position + Vector2(0, -34), "REDACTED!", GOLD)
		hud.set_boss("", 0.0, 0.0)
		play_sound("boss_down")
		play_music(_chapter_music_id())
	match enemy_kind:
		"editor":
			_play_story("act1_reveal")
		"binder":
			_play_story("act2_revelation")
		"author":
			_play_story("ending_choice")


func _should_drop_heal(is_boss: bool, is_elite_enemy: bool) -> bool:
	if player.health >= player.max_health - 0.01:
		return false
	if contract_recovery <= 0.0 or route_recovery <= 0.0 or proof_recovery <= 0.0:
		return false
	if is_boss:
		return true
	var health_ratio := player.health / maxf(1.0, player.max_health)
	var pity_limit := 9 if health_ratio <= 0.5 else 14
	if heal_drops_spawned == 0 and kills >= 5:
		return true
	if kills_since_heal_drop >= pity_limit:
		return true
	var chance := (0.075 + player.luck * 0.1) * contract_recovery * route_recovery * proof_recovery
	if is_elite_enemy:
		chance += 0.18
	return rng.randf() < clampf(chance, 0.0, 0.8)


func _combat_drop_for_kill(is_boss: bool, is_elite_enemy: bool) -> String:
	if is_boss:
		return "bomb" if combat_drops_spawned == 0 else _roll_combat_pickup()
	if combat_drops_spawned == 0:
		if kills >= 8:
			return "bomb"
		var first_chance := 0.035 + player.luck * 0.04 + (0.24 if is_elite_enemy else 0.0)
		return "bomb" if rng.randf() < clampf(first_chance, 0.0, 0.75) else ""
	if kills_since_supply_drop >= 18:
		return "bomb"
	var chance := 0.035 + player.luck * 0.04
	if is_elite_enemy:
		chance += 0.24
	return _roll_combat_pickup() if rng.randf() < clampf(chance, 0.0, 0.75) else ""


func hostile_projectile_limit(page: int = -1) -> int:
	var resolved_page := wave if page < 0 else page
	if resolved_page <= 1:
		return 8
	if resolved_page == 2:
		return 10
	if resolved_page == 3:
		return 12
	if resolved_page == 4:
		return 16
	return mini(30, 12 + int(round(float(resolved_page) * 1.5)))


func active_hostile_projectile_count() -> int:
	var count := 0
	for projectile in get_tree().get_nodes_in_group("hostile_projectiles"):
		if is_instance_valid(projectile) and projectile.get_parent() == self and not projectile.is_queued_for_deletion():
			count += 1
	return count


func available_hostile_projectile_slots() -> int:
	return maxi(0, hostile_projectile_limit() - active_hostile_projectile_count())


func spawn_projectile(at: Vector2, direction: Vector2, speed: float = 92.0, source_id: String = "projectile") -> bool:
	if available_hostile_projectile_slots() <= 0:
		return false
	var projectile: InkboundProjectile = ProjectileScript.new().setup(at, direction, player, speed, source_id)
	add_child(projectile)
	return true


func spawn_player_wave(at: Vector2, direction: Vector2, damage: float, pierce: int = 0, splits: int = 0, returning: bool = false, depth: int = 0) -> void:
	var projectile: InkboundPlayerWave = PlayerWaveScript.new().setup(at, direction, damage, pierce, splits, returning, depth)
	add_child(projectile)


func spawn_pickup(kind: String, at: Vector2, value: int = 1) -> InkPickup:
	var pickup: InkPickup = PickupScript.new().setup(at, player, value, kind)
	add_child(pickup)
	return pickup


func _roll_combat_pickup() -> String:
	var pool := ["bomb", "magnet", "ward"]
	if wave >= 3:
		pool.append("frenzy")
	if wave >= 5:
		pool.append("hourglass")
	return pool[rng.randi_range(0, pool.size() - 1)]


func activate_combat_pickup(kind: String) -> void:
	record_playtest_event("combat_pickup_activated", {"pickup": kind, "page": wave, "health": player.health})
	match kind:
		"bomb":
			var hits := damage_nearby(player.global_position, 118.0, maxf(8.0, player.damage * 4.5), Vector2.ZERO)
			spawn_word(player.global_position + Vector2(0, -30), "INK BOMB!  %d" % hits, GOLD)
			var blast: ComicFX = FxScript.new().setup_burst(player.global_position, CRIMSON, 118.0)
			add_child(blast)
			shake_strength = maxf(shake_strength, 8.0 * float(settings.get("screen_shake", 1.0)))
		"magnet":
			for pickup in get_tree().get_nodes_in_group("pickups"):
				if is_instance_valid(pickup) and pickup.get_parent() == self:
					pickup.global_position = player.global_position
			spawn_word(player.global_position + Vector2(0, -30), "ALL MARGINS CALL!", GOLD)
		"frenzy":
			player.activate_frenzy(9.0)
			spawn_word(player.global_position + Vector2(0, -30), "RED FRENZY!", CRIMSON)
		"ward":
			player.guard += 5.0
			spawn_word(player.global_position + Vector2(0, -30), "WARD +5", STEEL)
		"hourglass":
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(enemy) and enemy.get_parent() == self:
					enemy.slow_amount = maxf(enemy.slow_amount, 0.62)
					enemy.slow_time = maxf(enemy.slow_time, 6.0)
			spawn_word(player.global_position + Vector2(0, -30), "TIME REDACTED!", STEEL)
	play_sound("ink_burst" if kind == "bomb" else "powerup", 1.0 if kind == "bomb" else 1.0 + ["magnet", "frenzy", "ward", "hourglass"].find(kind) * 0.06)
	vibrate(0.18, 0.42, 0.12)


func collect_shards(amount: int) -> void:
	var multiplier := 1.2 if "library-card" in relic_ids else 1.0
	var gained := maxi(1, int(round(float(amount) * multiplier * contract_shard_multiplier * route_shard_multiplier * proof_shard_multiplier)))
	run_shards += gained
	lifetime_memory_earned += gained
	_evaluate_achievements()
	play_sound("pickup", 1.18)
	spawn_word(player.global_position + Vector2(0, -28), "MEMORY +%d" % gained, GOLD)
	if hud.has_method("set_shards"):
		hud.set_shards(run_shards)


func _available_relics() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for relic_data in Content.RELICS:
		if str(relic_data.get("id", "")) not in relic_ids:
			pool.append(relic_data)
	return pool


func _pick_relic_choices(count: int = 3) -> Array[Dictionary]:
	var pool := _available_relics()
	var choices: Array[Dictionary] = []
	while choices.size() < count and not pool.is_empty():
		choices.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return choices


func offer_relic_draft(source: String = "FOUND IN THE MARGIN") -> bool:
	if not run_started or game_over or run_won:
		return false
	if choosing_relic or choosing_upgrade or choosing_event or _story_modal_active():
		pending_relic_sources.append(source.left(64))
		return true
	return _open_relic_draft(source)


func _open_relic_draft(source: String) -> bool:
	current_relic_choices.clear()
	for choice in _pick_relic_choices(3):
		current_relic_choices.append(choice)
	if current_relic_choices.is_empty():
		collect_shards(5)
		if is_instance_valid(hud):
			hud.show_device_notice("RELIC ARCHIVE COMPLETE · MEMORY +5")
		return false
	choosing_relic = true
	hud.show_relic_draft(current_relic_choices, source)
	var choice_ids: Array[String] = []
	for choice in current_relic_choices:
		choice_ids.append(str(choice.get("id", "")))
	record_playtest_event("relic_draft_opened", {"source": source.left(64), "choices": choice_ids, "page": wave})
	play_sound("relic", 0.92)
	_sync_pause_state()
	return true


func _try_open_pending_relic_draft() -> bool:
	if choosing_relic or choosing_upgrade or choosing_event or _story_modal_active() or game_over or run_won:
		return false
	var queued_count := pending_relic_sources.size()
	for _index in range(queued_count):
		var source := str(pending_relic_sources.pop_front())
		if _open_relic_draft(source):
			return true
	return false


func _story_modal_active() -> bool:
	return is_instance_valid(cutscene) and bool(cutscene.get("active"))


func _grant_relic(relic_id: String) -> bool:
	var selected := Content.relic(relic_id)
	if selected.is_empty() or relic_id in relic_ids:
		return false
	relic_ids.append(relic_id)
	if relic_id not in discovered_relics:
		discovered_relics.append(relic_id)
	player.apply_relic(relic_id)
	_evaluate_achievements()
	play_sound("relic")
	spawn_word(player.global_position + Vector2(0, -38), selected["name"], GOLD)
	if hud.has_method("set_relics"):
		hud.set_relics(relic_ids)
	return true


func grant_random_relic() -> String:
	var choices := _pick_relic_choices(1)
	if choices.is_empty():
		collect_shards(5)
		return ""
	var relic_id := str(choices[0].get("id", ""))
	return relic_id if _grant_relic(relic_id) else ""


func damage_nearby(at: Vector2, radius: float, damage: float, impulse: Vector2 = Vector2.ZERO) -> int:
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("take_damage"):
			continue
		if at.distance_squared_to(enemy.global_position) <= radius * radius:
			enemy.take_damage(damage, impulse, false)
			hits += 1
	return hits


func apply_status_nearby(at: Vector2, radius: float, bleed: float, burn: float, slow: float) -> int:
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("apply_status"):
			continue
		if at.distance_squared_to(enemy.global_position) <= radius * radius:
			enemy.apply_status(bleed, burn, slow)
			hits += 1
	return hits


func execute_ink_art(art_id: String, at: Vector2, direction: Vector2, art_damage: float, radius: float, echo: bool = false) -> int:
	var aim := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var hits := 0
	match art_id:
		"final-period":
			var impact_point := clamp_to_arena(at + aim * 54.0, 24.0)
			hits = _damage_ink_art_radius(impact_point, radius, art_damage, 290.0)
			spawn_ink_art_ring(impact_point, radius, GOLD if not echo else PAPER)
			spawn_slash(impact_point, aim, radius * 0.92, 240.0)
		"red-line":
			var line_end := clamp_to_arena(at + aim * (132.0 + radius), 18.0)
			hits = _damage_ink_art_line(at, line_end, radius, art_damage, aim * 260.0)
			spawn_ink_art_line(at, line_end, CRIMSON if not echo else PAPER)
			if not echo:
				for step in range(4):
					spawn_afterimage(at.lerp(line_end, float(step) / 4.0))
				player.global_position = line_end
				player.invulnerable_time = maxf(player.invulnerable_time, 0.32)
		"seal-storm":
			var wave_count := 12
			for index in range(wave_count):
				var wave_direction := Vector2.from_angle(TAU * float(index) / float(wave_count))
				spawn_player_wave(at + wave_direction * 14.0, wave_direction, art_damage, 1, 0, false)
			hits = _damage_ink_art_radius(at, radius * 0.58, art_damage * 0.65, 120.0)
			spawn_ink_art_ring(at, radius, STEEL if not echo else PAPER)
		"cross-revision":
			hits = _damage_ink_art_cross(at, aim, radius, maxf(18.0, radius * 0.28), art_damage)
			spawn_ink_art_line(at - aim * radius, at + aim * radius, PAPER)
			var perpendicular := aim.rotated(PI * 0.5)
			spawn_ink_art_line(at - perpendicular * radius, at + perpendicular * radius, CRIMSON)
			spawn_ink_art_ring(at, radius * 0.62, GOLD if not echo else PAPER)
		_:
			hits = _damage_ink_art_radius(at, radius, art_damage, 210.0)
			spawn_ink_art_ring(at, radius, CRIMSON if not echo else PAPER)
			for index in range(4):
				spawn_slash(at, Vector2.from_angle(float(index) * PI * 0.5), radius, 128.0)
	if not echo:
		var art_name := str(player.ink_art_profile().get("name", "INK ART"))
		spawn_word(player.global_position + Vector2(0, -36), "%s!  %d" % [art_name, hits], GOLD)
		play_sound("relic", 0.72)
		vibrate(0.34, 0.82, 0.18)
		shake_strength = maxf(shake_strength, 9.0 * float(settings.get("screen_shake", 1.0)))
	else:
		spawn_word(at + Vector2(0, -24), "ECHO!", PAPER)
	return hits


func queue_ink_art_echo(art_id: String, at: Vector2, direction: Vector2, art_damage: float, radius: float) -> void:
	if deterministic_simulation:
		deterministic_echoes.append({
			"remaining": 0.38,
			"art_id": art_id,
			"position": at,
			"direction": direction,
			"damage": art_damage,
			"radius": radius,
		})
		return
	await get_tree().create_timer(0.38, false).timeout
	if not run_started or game_over or run_won or not is_instance_valid(player):
		return
	execute_ink_art(art_id, at, direction, art_damage, radius, true)


func advance_deterministic_simulation(delta: float) -> void:
	if not deterministic_simulation or deterministic_echoes.is_empty():
		return
	for index in range(deterministic_echoes.size() - 1, -1, -1):
		var echo: Dictionary = deterministic_echoes[index]
		echo["remaining"] = float(echo.get("remaining", 0.0)) - delta
		if float(echo["remaining"]) > 0.0:
			deterministic_echoes[index] = echo
			continue
		deterministic_echoes.remove_at(index)
		if run_started and not game_over and not run_won and is_instance_valid(player):
			execute_ink_art(str(echo["art_id"]), echo["position"], echo["direction"], float(echo["damage"]), float(echo["radius"]), true)


func clear_deterministic_simulation_events() -> void:
	deterministic_echoes.clear()


func _damage_ink_art_radius(at: Vector2, radius: float, art_damage: float, impulse_strength: float) -> int:
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - at
		if offset.length_squared() > radius * radius:
			continue
		_apply_ink_art_status(enemy)
		var impulse := offset.normalized() * impulse_strength if offset.length_squared() > 0.01 else Vector2.ZERO
		enemy.take_damage(art_damage, impulse, false)
		hits += 1
	return hits


func _damage_ink_art_line(from: Vector2, to: Vector2, half_width: float, art_damage: float, impulse: Vector2) -> int:
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("take_damage"):
			continue
		if _distance_to_segment_squared(enemy.global_position, from, to) > half_width * half_width:
			continue
		_apply_ink_art_status(enemy)
		enemy.take_damage(art_damage, impulse, false)
		hits += 1
	return hits


func _damage_ink_art_cross(at: Vector2, direction: Vector2, reach: float, half_width: float, art_damage: float) -> int:
	var perpendicular := direction.rotated(PI * 0.5)
	var first_from := at - direction * reach
	var first_to := at + direction * reach
	var second_from := at - perpendicular * reach
	var second_to := at + perpendicular * reach
	var hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("take_damage"):
			continue
		var distance_squared := minf(
			_distance_to_segment_squared(enemy.global_position, first_from, first_to),
			_distance_to_segment_squared(enemy.global_position, second_from, second_to)
		)
		if distance_squared > half_width * half_width:
			continue
		_apply_ink_art_status(enemy)
		var outward: Vector2 = (enemy.global_position - at).normalized() * 220.0
		enemy.take_damage(art_damage, outward, false)
		hits += 1
	return hits


func _distance_to_segment_squared(point: Vector2, from: Vector2, to: Vector2) -> float:
	var segment := to - from
	if segment.length_squared() <= 0.001:
		return point.distance_squared_to(from)
	var amount := clampf((point - from).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_squared_to(from + segment * amount)


func _apply_ink_art_status(enemy: Node) -> void:
	if enemy.has_method("apply_status"):
		enemy.apply_status(player.bleed_power, player.burn_power, maxf(0.12, player.slow_power))


func spawn_slash(at: Vector2, direction: Vector2, reach: float, arc: float) -> void:
	var fx: ComicFX = FxScript.new().setup_slash(at, direction, reach, arc)
	add_child(fx)


func spawn_afterimage(at: Vector2) -> void:
	var fx: ComicFX = FxScript.new().setup_afterimage(at)
	add_child(fx)


func spawn_ink_art_ring(at: Vector2, radius: float, color: Color) -> void:
	var fx: ComicFX = FxScript.new().setup_art_ring(at, radius, color)
	add_child(fx)


func spawn_ink_art_line(from: Vector2, to: Vector2, color: Color) -> void:
	var fx: ComicFX = FxScript.new().setup_art_line(from, to, color)
	add_child(fx)


func spawn_word(at: Vector2, text_value: String, color: Color = PAPER) -> void:
	var fx: ComicFX = FxScript.new().setup_word(at, Localization.gameplay_text(text_value), color)
	add_child(fx)


func impact(at: Vector2, critical: bool, text_value: String, strength: float) -> void:
	play_sound("hit", 0.82 if critical else 1.0 + randf() * 0.12)
	var burst: ComicFX = FxScript.new().setup_burst(at, GOLD if critical else CRIMSON, 34.0 if critical else 22.0)
	add_child(burst)
	spawn_word(at + Vector2(0, -18), text_value, GOLD if critical else PAPER)
	shake_strength = maxf(shake_strength, strength * float(settings.get("screen_shake", 1.0)))
	vibrate(0.2 if critical else 0.1, 0.55 if critical else 0.28, 0.1 if critical else 0.06)
	if bool(settings.get("hit_stop", true)) and not test_mode and not hit_stop_active:
		_hit_stop(0.065 if critical else 0.038)


func _hit_stop(duration: float) -> void:
	hit_stop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	hit_stop_active = false


func _update_camera_shake(delta: float) -> void:
	if shake_strength <= 0.05:
		camera.offset = camera.offset.lerp(Vector2.ZERO, delta * 20.0)
		shake_strength = 0.0
		return
	camera.offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
	shake_strength = move_toward(shake_strength, 0.0, delta * 34.0)


func on_ink_collected(at: Vector2) -> void:
	play_sound("pickup", 0.94 + randf() * 0.12)
	_advance_page_directive("ink", 1.0)
	if rng.randf() < 0.24:
		spawn_word(at + Vector2(0, -12), "INK+", CRIMSON)


func play_sound(sound_id: String, pitch: float = 1.0) -> void:
	if not _claim_sound_request(sound_id):
		return
	var audio := AudioStreamPlayer.new()
	audio.stream = SOUNDS[sound_id]
	audio.pitch_scale = pitch
	var base_volume := _sound_base_volume(sound_id)
	audio.volume_db = base_volume + linear_to_db(maxf(0.001, float(settings.get("sfx", 0.85))))
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func play_spatial_sound(sound_id: String, at: Vector2, pitch: float = 1.0) -> void:
	if not _claim_sound_request(sound_id):
		return
	var audio := AudioStreamPlayer2D.new()
	audio.stream = SOUNDS[sound_id]
	audio.pitch_scale = pitch
	audio.global_position = at
	audio.max_distance = 520.0
	audio.attenuation = 1.35
	audio.volume_db = _sound_base_volume(sound_id) + linear_to_db(maxf(0.001, float(settings.get("sfx", 0.85))))
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func _claim_sound_request(sound_id: String) -> bool:
	if not SOUNDS.has(sound_id):
		return false
	last_sound_id = sound_id
	if test_mode:
		return false
	var now := Time.get_ticks_msec()
	var cooldown := int(SOUND_COOLDOWNS_MSEC.get(sound_id, 0))
	if cooldown > 0 and now - int(sound_last_played_msec.get(sound_id, -cooldown)) < cooldown:
		return false
	sound_last_played_msec[sound_id] = now
	return true


func _sound_base_volume(sound_id: String) -> float:
	if sound_id in ["hit", "slash", "slash_heavy", "slash_light", "ink_burst"]:
		return -5.0
	if sound_id in ["ui_move", "ui_confirm", "ui_cancel", "save"]:
		return -10.0
	if sound_id in ["enemy_cast", "enemy_dash", "teleport", "parry", "shield", "heal"]:
		return -8.0
	return -7.0


func play_music(music_id: String) -> void:
	if current_music == music_id or not MUSIC.has(music_id):
		return
	current_music = music_id
	if test_mode:
		return
	var stream = MUSIC[music_id].duplicate()
	stream.loop_mode = 1
	var target_volume := _music_volume_db()
	if not music_player.playing:
		music_player.stream = stream
		music_player.volume_db = target_volume
		music_player.play()
		return
	if music_crossfade != null and music_crossfade.is_valid():
		music_crossfade.kill()
	var outgoing := music_player
	var incoming := music_fade_player
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	music_player = incoming
	music_fade_player = outgoing
	music_crossfade = create_tween()
	music_crossfade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_crossfade.set_parallel(true)
	music_crossfade.tween_property(incoming, "volume_db", target_volume, 0.55).set_trans(Tween.TRANS_SINE)
	music_crossfade.tween_property(outgoing, "volume_db", -60.0, 0.55).set_trans(Tween.TRANS_SINE)
	music_crossfade.chain().tween_callback(outgoing.stop)


func _music_volume_db() -> float:
	return linear_to_db(maxf(0.001, float(settings.get("music", 0.65)) * 0.32))


func _chapter_music_id(page: int = wave) -> String:
	return "archive" if page < 5 else ("bindery" if page < 9 else "finale")


func _boss_music_id(enemy_kind: String) -> String:
	return "boss_" + enemy_kind if enemy_kind in BOSS_KINDS else _chapter_music_id()


func vibrate(weak: float, strong: float, duration: float) -> void:
	if test_mode or not bool(settings.get("vibration", true)):
		return
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)


func _on_health_changed(current: float, maximum: float) -> void:
	hud.set_health(current, maximum)


func _on_build_changed(summary: String) -> void:
	hud.set_build(summary)


func _on_build_milestone_unlocked(discipline_id: String, tier: int) -> void:
	if not is_instance_valid(hud):
		return
	var discipline := Content.build_discipline(discipline_id)
	if discipline.is_empty():
		return
	var discipline_name := Localization.text(discipline.get("name", "DRAFT"))
	var phase := Localization.text("MASTERWORK" if tier >= 2 else "BUILD AWAKENED")
	spawn_word(player.global_position + Vector2(0, -48), "%s %s" % [discipline_name, ["", "I", "II"][clampi(tier, 0, 2)]], GOLD)
	hud.show_device_notice("%s  ·  %s" % [phase, discipline_name])
	play_sound("relic", 0.86 if tier >= 2 else 0.78)


func _on_ink_art_changed(art_name: String, remaining: float, maximum: float) -> void:
	if is_instance_valid(hud):
		hud.set_ink_art(art_name, remaining, maximum)


func _on_xp_changed(current: int, needed: int, current_level: int) -> void:
	hud.set_xp(current, needed, current_level)


func _on_level_up(_level: int) -> void:
	if game_over:
		return
	highest_level = maxi(highest_level, player.level)
	choosing_upgrade = true
	current_choices = _pick_upgrades(3 + player.upgrade_choice_bonus)
	play_sound("level_up", 1.0)
	hud.show_upgrade(current_choices)
	var choice_ids: Array[String] = []
	for choice in current_choices:
		choice_ids.append(str(choice.get("id", "")))
	record_playtest_event("upgrade_draft_opened", {"level": player.level, "choices": choice_ids, "page": wave})
	_sync_pause_state()


func _pick_upgrades(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = Content.available_upgrades(player.upgrade_stacks, player.level, _unlocked_content_ids("weapon"))
	var chosen: Array[Dictionary] = []
	var resonant_choice_id := ""
	var dominant := Content.dominant_build_discipline(player.upgrade_stacks, 2)
	if not dominant.is_empty():
		var resonant_pool: Array[Dictionary] = []
		for upgrade_data in pool:
			if Content.upgrade_supports_discipline(upgrade_data, dominant["id"]):
				resonant_pool.append(upgrade_data)
		if not resonant_pool.is_empty():
			var resonant_choice := resonant_pool[_weighted_upgrade_index(resonant_pool)]
			resonant_choice_id = str(resonant_choice.get("id", ""))
			chosen.append(resonant_choice)
			for pool_index in range(pool.size() - 1, -1, -1):
				if str(pool[pool_index].get("id", "")) == resonant_choice_id:
					pool.remove_at(pool_index)
					break
	while chosen.size() < count and not pool.is_empty():
		var index := _weighted_upgrade_index(pool)
		chosen.append(pool.pop_at(index))
	for choice_index in range(chosen.size()):
		var choice := chosen[choice_index].duplicate(true)
		var discipline := Content.discipline_for_upgrade(choice, player.upgrade_stacks)
		if not discipline.is_empty():
			var score := int(discipline.get("score", 0))
			var next_threshold := int(discipline.get("next_threshold", maxi(1, score + 1)))
			choice["_discipline_id"] = str(discipline.get("id", ""))
			choice["_discipline_score"] = score
			choice["_next_threshold"] = next_threshold
			choice["_awakens"] = score < next_threshold and score + 1 >= next_threshold
		choice["_resonant"] = not resonant_choice_id.is_empty() and str(choice.get("id", "")) == resonant_choice_id
		if not dominant.is_empty():
			choice["_draft_discipline_id"] = str(dominant.get("id", ""))
			choice["_draft_score"] = int(dominant.get("score", 0))
			choice["_draft_tier"] = int(dominant.get("tier", 0))
			choice["_draft_next_threshold"] = int(dominant.get("next_threshold", 3))
		chosen[choice_index] = choice
	return chosen


func _weighted_upgrade_index(pool: Array[Dictionary]) -> int:
	var total := 0.0
	var weights: Array[float] = []
	for upgrade_data in pool:
		var rarity: String = upgrade_data.get("rarity", "common")
		var base_weight: float = float({"common": 60.0, "rare": 28.0, "epic": 9.0, "legendary": 3.0}.get(rarity, 20.0))
		var luck_multiplier := 1.0 + player.luck * (0.0 if rarity == "common" else (1.5 if rarity == "legendary" else 0.8))
		var weight: float = base_weight * luck_multiplier
		weights.append(weight)
		total += weight
	var roll := rng.randf_range(0.0, total)
	for index in range(weights.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return pool.size() - 1


func _play_story(sequence_name: String) -> void:
	if test_mode or not is_instance_valid(cutscene):
		return
	var story_data: Dictionary = Content.story(sequence_name)
	if story_data.is_empty():
		return
	story_seen[sequence_name] = true
	record_playtest_event("story_started", {"sequence": sequence_name, "replay": replaying_story, "page": wave})
	cutscene.play(sequence_name, story_data)
	_sync_pause_state()


func _on_cutscene_finished(sequence_name: String) -> void:
	record_playtest_event("story_finished", {"sequence": sequence_name, "replay": replaying_story, "page": wave})
	if replaying_story:
		replaying_story = false
		hud.show_title(_meta_snapshot())
		_sync_pause_state()
		return
	match sequence_name:
		"prologue":
			if test_mode:
				hud.set_objective("Reach Page 4 and confront the Red Editor")
				hud.show_run_intro()
			else:
				_offer_route(1)
		"act1_reveal":
			if TranslationServer.get_locale().begins_with("zh"):
				hud.set_objective("每日 %s · 抵达第 8 页并进入禁忌装订所" % daily_id if daily_run else "校样 %d · 抵达第 8 页并进入禁忌装订所" % proof_depth)
			else:
				hud.set_objective("DAILY %s · Reach Page 8 and enter the Forbidden Bindery" % daily_id if daily_run else "PROOF %d · Reach Page 8 and enter the Forbidden Bindery" % proof_depth)
		"act2_revelation":
			if TranslationServer.get_locale().begins_with("zh"):
				hud.set_objective("每日 %s · 抵达第 12 页并面对初代作者" % daily_id if daily_run else "校样 %d · 抵达第 12 页并面对初代作者" % proof_depth)
			else:
				hud.set_objective("DAILY %s · Reach Page 12 and face the First Author" % daily_id if daily_run else "PROOF %d · Reach Page 12 and face the First Author" % proof_depth)
		"act3_confrontation":
			if TranslationServer.get_locale().begins_with("zh"):
				hud.set_objective("每日 %s · 击败初代作者" % daily_id if daily_run else "校样 %d · 击败初代作者" % proof_depth)
			else:
				hud.set_objective("DAILY %s · Defeat the First Author" % daily_id if daily_run else "PROOF %d · Defeat the First Author" % proof_depth)
	if sequence_name == "act3_confrontation" and not pending_boss_kind.is_empty():
		var boss_kind := pending_boss_kind
		pending_boss_kind = ""
		spawn_enemy(boss_kind)
	if sequence_name in ["ending_keep", "ending_rewrite"]:
		run_won = true
		ending_id = sequence_name.trim_prefix("ending_")
		if ending_id not in completed_endings:
			completed_endings.append(ending_id)
		best_score = maxi(best_score, score)
		best_kills = maxi(best_kills, kills)
		_finalize_run()
		_save_run()
		if hud.has_method("show_victory"):
			hud.show_victory(last_run_summary)
		_sync_pause_state()
		request_playtest_survey("victory")
		return
	if not _try_open_pending_relic_draft():
		_sync_pause_state()
		_save_checkpoint("story-" + sequence_name)


func _on_story_choice(sequence_name: String, choice_id: String) -> void:
	record_playtest_event("story_choice", {"sequence": sequence_name, "choice": choice_id, "replay": replaying_story})
	if replaying_story:
		var ending_sequence := "ending_" + choice_id
		if _story_is_unlocked(ending_sequence):
			_play_replay_sequence(ending_sequence)
		else:
			replaying_story = false
			hud.show_title(_meta_snapshot())
			hud.show_device_notice("THAT ENDING HAS NOT BEEN RESTORED")
			_sync_pause_state()
		return
	if sequence_name != "ending_choice":
		_sync_pause_state()
		return
	_play_story("ending_" + choice_id)


func _daily_date_id() -> String:
	if Content.valid_daily_id(debug_daily_date_override):
		return debug_daily_date_override
	return Time.get_date_string_from_system(true)


func _daily_snapshot(date_id_value: String = "") -> Dictionary:
	var resolved_id := date_id_value if Content.valid_daily_id(date_id_value) else _daily_date_id()
	var snapshot := Content.daily_recipe(resolved_id)
	var record: Dictionary = daily_records.get(resolved_id, {})
	snapshot["attempts"] = maxi(0, int(record.get("attempts", 0)))
	snapshot["wins"] = maxi(0, int(record.get("wins", 0)))
	snapshot["best_score"] = maxi(0, int(record.get("best_score", 0)))
	snapshot["best_wave"] = maxi(0, int(record.get("best_wave", 0)))
	snapshot["cleared"] = bool(record.get("cleared", false))
	snapshot["current_streak"] = daily_current_streak
	snapshot["best_streak"] = daily_best_streak
	snapshot["lifetime_clears"] = lifetime_daily_clears
	return snapshot


func _on_daily_requested() -> void:
	var recipe := _daily_snapshot()
	hud.hide_title()
	_on_start_requested(
		str(recipe.get("difficulty", "standard")),
		str(recipe.get("contract_id", "open-draft")),
		str(recipe.get("starting_weapon", "marginalia")),
		int(recipe.get("proof_depth", 0)),
		true,
		int(recipe.get("seed", 1)),
		str(recipe.get("id", _daily_date_id()))
	)


func _seal_meta_progression_for_daily() -> void:
	var vital_rank := int(meta_upgrades.get("vital", 0))
	var edge_rank := int(meta_upgrades.get("edge", 0))
	var fortune_rank := int(meta_upgrades.get("fortune", 0))
	var stride_rank := int(meta_upgrades.get("stride", 0))
	var inkwell_rank := int(meta_upgrades.get("inkwell", 0))
	var thread_rank := int(meta_upgrades.get("thread", 0))
	player.max_health = maxf(2.0, player.max_health - float(vital_rank))
	player.health = player.max_health
	player.damage = maxf(0.1, player.damage - float(edge_rank) * 0.2)
	player.luck = maxf(0.0, player.luck - float(fortune_rank) * 0.05)
	player.move_speed = maxf(40.0, player.move_speed - float(stride_rank) * 3.0)
	if inkwell_rank > 0:
		player.ink_art_cooldown_max /= pow(0.96, inkwell_rank)
	player.pickup_radius = maxf(24.0, player.pickup_radius - float(thread_rank) * 18.0)
	if vital_rank >= 5:
		player.guard = maxf(0.0, player.guard - 2.0)
	if edge_rank >= 5:
		player.boss_damage_bonus = maxf(0.0, player.boss_damage_bonus - 0.10)
	if fortune_rank >= 5:
		player.xp_multiplier = maxf(0.1, player.xp_multiplier - 0.10)
	if stride_rank >= 5:
		player.dash_cooldown_max /= 0.90
	if inkwell_rank >= 5:
		player.ink_art_damage_multiplier = maxf(0.1, player.ink_art_damage_multiplier - 0.15)
	if thread_rank >= 5:
		player.pickup_radius = maxf(24.0, player.pickup_radius - 45.0)
	player.health_changed.emit(player.health, player.max_health)
	player.build_changed.emit(player.get_build_summary())
	player._notify_ink_art_changed(true)


func _on_start_requested(selected_difficulty: String, selected_contract: String = "open-draft", selected_weapon: String = "marginalia", selected_proof_depth: int = 0, daily_mode: bool = false, daily_seed_value: int = 0, requested_daily_id: String = "") -> void:
	_delete_checkpoint()
	replaying_story = false
	choosing_relic = false
	current_relic_choices.clear()
	pending_relic_sources.clear()
	if is_instance_valid(route_hazard):
		route_hazard.reset_run()
	daily_run = daily_mode
	daily_id = requested_daily_id if daily_mode and Content.valid_daily_id(requested_daily_id) else ""
	run_seed = maxi(1, daily_seed_value) if daily_run else 0
	if daily_run:
		debug_set_rng_seed(run_seed)
	_expire_page_directive()
	directive_history.clear()
	squad_history.clear()
	active_squad_id = ""
	active_squad_name = ""
	encounter_started_wave = 0
	pending_page_encounter = true
	run_directives_started = 0
	run_directives_completed = 0
	directive_score_bonus = 0
	kills_since_heal_drop = 0
	kills_since_supply_drop = 0
	heal_drops_spawned = 0
	combat_drops_spawned = 0
	var unlocked_difficulties := _unlocked_content_ids("difficulty")
	difficulty_id = "standard" if daily_run else (selected_difficulty if selected_difficulty in unlocked_difficulties else "standard")
	var unlocked_contracts := _unlocked_content_ids("contract")
	_configure_contract(selected_contract if daily_run or selected_contract in unlocked_contracts else "open-draft")
	run_start_unlock_ids = _unlocked_content_ids()
	_configure_difficulty(difficulty_id)
	_configure_proof(0 if daily_run else selected_proof_depth)
	preferred_proof_depth = proof_depth
	var unlocked_weapons := _unlocked_content_ids("weapon")
	starting_weapon_id = "marginalia" if daily_run else (selected_weapon if not Content.starting_weapon(selected_weapon).is_empty() else "marginalia")
	if starting_weapon_id != "marginalia" and starting_weapon_id not in unlocked_weapons:
		starting_weapon_id = "marginalia"
	if daily_run:
		_seal_meta_progression_for_daily()
	var starting_weapon: Dictionary = Content.starting_weapon(starting_weapon_id)
	var starting_upgrade_id := str(starting_weapon.get("upgrade_id", ""))
	if not starting_upgrade_id.is_empty():
		player.apply_upgrade(starting_upgrade_id)
		_record_upgrade(starting_upgrade_id)
	player.max_health = maxf(2.0, player.max_health * contract_player_health * proof_player_health)
	player.health = minf(player.max_health, player.health * contract_player_health * proof_player_health)
	player.dash_cooldown_max *= proof_dash_cooldown
	player.damage *= contract_player_damage
	player.health_changed.emit(player.health, player.max_health)
	player.build_changed.emit(player.get_build_summary())
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_elite and rng.randf() < contract_elite_bonus + proof_elite_bonus:
			enemy.promote_to_elite()
		enemy.max_health *= difficulty_health * contract_enemy_health * proof_enemy_health * (proof_boss_health if enemy.enemy_kind in BOSS_KINDS else 1.0)
		enemy.health = enemy.max_health
		enemy.contact_damage *= difficulty_damage * contract_enemy_damage * proof_enemy_damage
		enemy.speed *= difficulty_speed * contract_enemy_speed * proof_enemy_speed
	run_started = true
	record_playtest_event("run_started", {
		"difficulty": difficulty_id,
		"contract": contract_id,
		"starting_weapon": starting_weapon_id,
		"proof_depth": proof_depth,
		"daily": daily_run,
		"daily_id": daily_id,
		"seed": run_seed,
	})
	_refresh_run_objective()
	if test_mode:
		_start_page_encounter(1)
		hud.show_run_intro()
		_sync_pause_state()
	else:
		if not field_manual_seen:
			onboarding_pending = true
			hud.show_manual(0)
		else:
			_begin_run_opening()


func _begin_run_opening() -> void:
	if daily_run:
		_offer_route(1)
	elif lifetime_runs == 0 and completed_endings.is_empty():
		_play_story("prologue")
	else:
		_offer_route(1)


func _on_manual_visibility_changed(visible_now: bool) -> void:
	manual_open = visible_now
	record_playtest_event("manual_visibility", {"visible": visible_now, "page": wave, "run_started": run_started})
	if visible_now:
		_sync_pause_state()
		return
	if not field_manual_seen:
		field_manual_seen = true
		if not test_mode:
			_save_run()
	if onboarding_pending:
		onboarding_pending = false
		_begin_run_opening()
		return
	_sync_pause_state()


func _configure_difficulty(selected_difficulty: String) -> void:
	difficulty_id = selected_difficulty
	match difficulty_id:
		"story":
			difficulty_health = 0.78
			difficulty_damage = 0.72
			difficulty_speed = 0.92
		"redline":
			difficulty_health = 1.32
			difficulty_damage = 1.28
			difficulty_speed = 1.1
		_:
			difficulty_health = 1.0
			difficulty_damage = 1.0
			difficulty_speed = 1.0


func _on_story_replay_requested(sequence_name: String) -> void:
	if not _story_is_unlocked(sequence_name):
		hud.show_device_notice("MEMORY STILL LOCKED")
		return
	hud.hide_title()
	replaying_story = true
	if not _play_replay_sequence(sequence_name):
		replaying_story = false
		hud.show_title(_meta_snapshot())
	_sync_pause_state()


func _play_replay_sequence(sequence_name: String) -> bool:
	if not is_instance_valid(cutscene):
		return false
	var story_data: Dictionary = Content.story(sequence_name)
	return not story_data.is_empty() and cutscene.play(sequence_name, story_data)


func _story_is_unlocked(sequence_name: String) -> bool:
	match sequence_name:
		"prologue":
			return true
		"act1_reveal":
			return highest_wave >= 4
		"act2_revelation":
			return highest_wave >= 8
		"act3_confrontation", "ending_choice":
			return highest_wave >= 12
		"ending_keep":
			return "keep" in completed_endings
		"ending_rewrite":
			return "rewrite" in completed_endings
	return false


func _configure_contract(selected_contract: String) -> void:
	var data: Dictionary = Content.contract(selected_contract)
	contract_id = data.get("id", "open-draft")
	contract_enemy_health = float(data.get("enemy_health", 1.0))
	contract_enemy_damage = float(data.get("enemy_damage", 1.0))
	contract_enemy_speed = float(data.get("enemy_speed", 1.0))
	contract_player_health = float(data.get("player_health", 1.0))
	contract_player_damage = float(data.get("player_damage", 1.0))
	contract_spawn_interval = float(data.get("spawn_interval", 1.0))
	contract_enemy_cap = float(data.get("enemy_cap", 1.0))
	contract_recovery = float(data.get("recovery", 1.0))
	contract_elite_bonus = float(data.get("elite_bonus", 0.0))
	contract_wave_duration = float(data.get("wave_duration", 42.0))
	contract_score_multiplier = float(data.get("score", 1.0))
	contract_shard_multiplier = float(data.get("shards", 1.0))


func _refresh_run_objective() -> void:
	if not is_instance_valid(hud):
		return
	var chapter := _chapter_for_page(wave)
	var goal_source := "RED EDITOR · PAGE 4" if chapter == 1 else ("FORBIDDEN BINDER · PAGE 8" if chapter == 2 else "FIRST AUTHOR · PAGE 12")
	var goal := Localization.text(goal_source)
	var route_data := Content.route(active_route_id)
	var primary_name := Localization.text(route_data.get("short", route_data.get("name", Content.contract(contract_id).get("name", "OPEN DRAFT"))))
	var hazard_name := Localization.text(route_data.get("hazard_name", "LIVING MARGIN"))
	if TranslationServer.get_locale().begins_with("zh"):
		hud.set_objective("每日 %s · %s · %s" % [daily_id, hazard_name, goal] if daily_run else "%s · %s · 校样 %d · %s" % [primary_name, hazard_name, proof_depth, goal])
	else:
		hud.set_objective("DAILY %s · %s · %s" % [daily_id, hazard_name, goal] if daily_run else "%s · %s · PROOF %d · %s" % [primary_name, hazard_name, proof_depth, goal])


func _configure_proof(selected_depth: int, allow_locked: bool = false) -> void:
	var maximum := Content.PROOF_LEVELS.size() - 1 if allow_locked else max_proof_depth
	proof_depth = clampi(selected_depth, 0, maximum)
	var modifiers := Content.proof_modifiers(proof_depth)
	proof_enemy_health = float(modifiers["enemy_health"])
	proof_enemy_damage = float(modifiers["enemy_damage"])
	proof_enemy_speed = float(modifiers["enemy_speed"])
	proof_player_health = float(modifiers["player_health"])
	proof_dash_cooldown = float(modifiers["dash_cooldown"])
	proof_spawn_interval = float(modifiers["spawn_interval"])
	proof_enemy_cap = float(modifiers["enemy_cap"])
	proof_recovery = float(modifiers["recovery"])
	proof_elite_bonus = float(modifiers["elite_bonus"])
	proof_boss_health = float(modifiers["boss_health"])
	proof_wave_duration = float(modifiers["wave_duration"])
	proof_score_multiplier = float(modifiers["score"])
	proof_shard_multiplier = float(modifiers["shards"])


func _offer_route(chapter: int) -> bool:
	var routes := Content.routes_for_chapter(chapter)
	if routes.size() != 3:
		return false
	var options: Array[Dictionary] = []
	for route_data in routes:
		options.append({
			"label": route_data["name"],
			"description": route_data["card"],
			"effect": "route",
			"route_id": route_data["id"],
		})
	return _begin_event({
		"id": "route-choice-%d" % chapter,
		"title": "CHOOSE THE NEXT MARGIN",
		"text": (("第 %s 幕  ·  三条道路幸免于删改" if TranslationServer.get_locale().begins_with("zh") else "ACT %s  ·  THREE ROADS SURVIVED THE REDACTION") % ["I", "II", "III"][chapter - 1]),
		"options": options,
	})


func _activate_route(route_id: String) -> bool:
	var data: Dictionary = Content.route(route_id)
	if data.is_empty():
		return false
	active_route_id = route_id
	route_enemy_bias.clear()
	for enemy_id in data.get("enemy_bias", []):
		if Content.ENEMIES.has(str(enemy_id)):
			route_enemy_bias.append(str(enemy_id))
	route_enemy_bias_chance = clampf(float(data.get("bias_chance", 0.0)), 0.0, 1.0)
	route_enemy_health = maxf(0.1, float(data.get("enemy_health", 1.0)))
	route_enemy_damage = maxf(0.1, float(data.get("enemy_damage", 1.0)))
	route_enemy_speed = maxf(0.1, float(data.get("enemy_speed", 1.0)))
	route_spawn_interval = maxf(0.1, float(data.get("spawn_interval", 1.0)))
	route_enemy_cap = maxf(0.1, float(data.get("enemy_cap", 1.0)))
	route_recovery = maxf(0.0, float(data.get("recovery", 1.0)))
	route_elite_bonus = clampf(float(data.get("elite_bonus", 0.0)), 0.0, 0.8)
	route_score_multiplier = maxf(0.1, float(data.get("score", 1.0)))
	route_shard_multiplier = maxf(0.1, float(data.get("shards", 1.0)))
	if route_id not in chosen_routes:
		chosen_routes.append(route_id)
	if route_id not in discovered_routes:
		discovered_routes.append(route_id)
		_evaluate_achievements()
		if not test_mode:
			_save_run()
	if is_instance_valid(arena):
		arena.set_route(route_id)
	if is_instance_valid(route_hazard):
		route_hazard.set_route(route_id)
	_refresh_run_objective()
	spawn_word(player.global_position + Vector2(0, -48), str(data["name"]), GOLD)
	var hazard_name := Localization.text(data.get("hazard_name", "LIVING MARGIN"))
	hud.show_device_notice(("页边苏醒 · %s" if TranslationServer.get_locale().begins_with("zh") else "MARGIN AWAKENS · %s") % hazard_name)
	record_playtest_event("route_selected", {"route": route_id, "chapter": int(data.get("chapter", 0)), "page": wave})
	return true


func _offer_chapter_event(chapter: int) -> bool:
	var pool: Array[Dictionary] = Content.events_for_chapter(chapter, seen_events)
	if pool.is_empty():
		return false
	return _begin_event(pool[rng.randi_range(0, pool.size() - 1)])


func _begin_event(event_data: Dictionary) -> bool:
	if event_data.is_empty() or choosing_event or choosing_upgrade or choosing_relic or game_over:
		return false
	current_event = event_data.duplicate(true)
	var event_id: String = current_event.get("id", "")
	if not event_id.is_empty() and event_id not in seen_events:
		seen_events.append(event_id)
	choosing_event = true
	hud.show_event(current_event)
	var option_ids: Array[String] = []
	for option in current_event.get("options", []):
		option_ids.append(str(option.get("route_id", option.get("effect", ""))))
	record_playtest_event("event_opened", {"event": event_id, "options": option_ids, "page": wave})
	_sync_pause_state()
	return true


func _on_event_selected(index: int) -> void:
	if not choosing_event:
		return
	var options: Array = current_event.get("options", [])
	if index < 0 or index >= options.size():
		return
	var option: Dictionary = options[index]
	record_playtest_event("event_selected", {
		"event": str(current_event.get("id", "")),
		"index": index,
		"label": str(option.get("label", "")).left(80),
		"effect": str(option.get("effect", "")),
		"route": str(option.get("route_id", "")),
		"page": wave,
	})
	var is_route_choice := str(option.get("effect", "")) == "route"
	var selected_route_chapter := 0
	if is_route_choice:
		var selected_route_id := str(option.get("route_id", ""))
		selected_route_chapter = int(Content.route(selected_route_id).get("chapter", 0))
		_activate_route(selected_route_id)
	else:
		_apply_event_effect(str(option.get("effect", "")), float(option.get("amount", 0.0)))
	var label: String = option.get("label", "MARGIN CHOSEN")
	spawn_word(player.global_position + Vector2(0, -42), label, GOLD)
	current_event.clear()
	choosing_event = false
	if not _try_open_pending_relic_draft():
		_sync_pause_state()
	if pending_page_encounter:
		_start_page_encounter(wave)
	_save_checkpoint("route-%d" % selected_route_chapter if is_route_choice else "event")
	if is_route_choice and selected_route_chapter == 1:
		hud.show_run_intro()


func _apply_event_effect(effect: String, amount: float) -> void:
	match effect:
		"relic_cost_health":
			if amount > 0.0:
				player.max_health = maxf(2.0, player.max_health - amount)
				player.health = minf(player.health, player.max_health)
			else:
				player.health = maxf(1.0, player.health - 2.0)
			player.health_changed.emit(player.health, player.max_health)
			offer_relic_draft("MEMORY BARGAIN · CHOOSE ONE RELIC")
		"shards":
			collect_shards(int(amount))
		"heal":
			player.heal(amount)
		"upgrade":
			_grant_random_upgrade()
		"damage_health":
			player.damage += amount
			player.max_health = maxf(2.0, player.max_health - 1.0)
			player.health = minf(player.health, player.max_health)
			player.health_changed.emit(player.health, player.max_health)
			player.build_changed.emit(player.get_build_summary())
		"guard":
			player.guard += amount
		"max_health":
			player.max_health += amount
			player.heal(amount)
		"critical":
			player.critical_chance = minf(0.8, player.critical_chance + amount)
			player.build_changed.emit(player.get_build_summary())
		"speed":
			player.move_speed += amount
		"cleanse":
			player.heal(player.max_health)
			player.guard += amount
		"elite_ambush":
			collect_shards(int(amount) + 2)
			_spawn_elite_ambush(int(amount))
		"damage":
			player.damage += amount
			player.build_changed.emit(player.get_build_summary())
		"luck":
			player.luck += amount
		"relic":
			offer_relic_draft("ARCHIVE CACHE · CHOOSE ONE RELIC")
		"attack_speed":
			player.attack_period = maxf(0.16, player.attack_period * (1.0 - amount))
		"upgrade_guard":
			_grant_random_upgrade()
			player.guard += amount
		"defiance":
			player.damage += amount
			player.critical_chance = minf(0.8, player.critical_chance + 0.05)
			player.build_changed.emit(player.get_build_summary())
		"full_heal_health":
			player.max_health += amount
			player.heal(player.max_health)
		"blood_damage":
			player.damage += amount
			player.health = maxf(1.0, player.health - 2.0)
			player.health_changed.emit(player.health, player.max_health)
			player.build_changed.emit(player.get_build_summary())
		"critical_damage":
			player.critical_damage_bonus += amount
		"heal_shards":
			player.heal(amount)
			collect_shards(int(amount))
		"relic_ambush":
			offer_relic_draft("STOLEN RELIC · CHOOSE BEFORE THE AMBUSH")
			_spawn_elite_ambush(int(amount))


func _grant_random_upgrade() -> String:
	var pool: Array[Dictionary] = Content.available_upgrades(player.upgrade_stacks, player.level, _unlocked_content_ids("weapon"))
	if pool.is_empty():
		collect_shards(4)
		return ""
	var selected: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	player.apply_upgrade(selected["id"])
	_record_upgrade(selected["id"])
	spawn_word(player.global_position + Vector2(0, -34), selected["name"], GOLD)
	return selected["id"]


func _spawn_elite_ambush(count: int) -> void:
	for index in range(maxi(1, count)):
		var angle := TAU * float(index) / float(maxi(1, count))
		var enemy := spawn_enemy(_roll_enemy_kind(), clamp_to_arena(player.global_position + Vector2.from_angle(angle) * 105.0, 24.0))
		enemy.promote_to_elite()


func _on_meta_upgrade_requested(upgrade_id: String) -> void:
	var definition := Content.meta_restoration(upgrade_id)
	if definition.is_empty() or upgrade_id not in meta_upgrades:
		return
	var rank := int(meta_upgrades[upgrade_id])
	var maximum := int(definition["max_rank"])
	var archive_rank := int(_archive_rank_snapshot()["rank"])
	var cost := Content.meta_restoration_cost(upgrade_id, rank)
	if archive_rank < int(definition["required_rank"]) or rank >= maximum or cost <= 0 or meta_shards < cost:
		return
	meta_shards -= cost
	meta_upgrades[upgrade_id] = rank + 1
	_apply_meta_bonus(upgrade_id, rank + 1)
	_save_run()
	hud.refresh_title_meta(_meta_snapshot())
	play_sound("relic", 1.1)


func _on_setting_adjusted(setting_id: String, direction: int) -> void:
	if setting_id not in settings:
		return
	match setting_id:
		"master", "music", "sfx":
			settings[setting_id] = clampf(snappedf(float(settings[setting_id]) + 0.1 * signi(direction), 0.1), 0.0, 1.0)
		"vibration", "hit_stop", "reduced_flashes", "fullscreen":
			settings[setting_id] = not bool(settings[setting_id])
		"aim_assist":
			var levels := [0.0, 0.25, 0.45]
			var current_index := levels.find(float(settings[setting_id]))
			if current_index < 0:
				current_index = 2
			settings[setting_id] = levels[posmod(current_index + signi(direction), levels.size())]
		"screen_shake":
			var levels := [0.0, 0.5, 1.0]
			var current_index := levels.find(float(settings[setting_id]))
			if current_index < 0:
				current_index = 2
			settings[setting_id] = levels[posmod(current_index + signi(direction), levels.size())]
		"language":
			var current_language := Localization.LANGUAGE_CHOICES.find(str(settings[setting_id]))
			if current_language < 0:
				current_language = 0
			settings[setting_id] = Localization.LANGUAGE_CHOICES[posmod(current_language + signi(direction), Localization.LANGUAGE_CHOICES.size())]
	_apply_settings()
	hud.set_settings(settings)
	record_playtest_event("setting_changed", {"setting": setting_id, "value": settings.get(setting_id), "direction": signi(direction)})
	_refresh_run_objective()
	hud.refresh_localization()
	if is_instance_valid(cutscene):
		cutscene.refresh_localization()
	if not test_mode:
		_save_run()


func _apply_settings() -> void:
	_sanitize_settings()
	_apply_language_setting()
	var master := float(settings["master"])
	AudioServer.set_bus_mute(0, master <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, master)))
	if is_instance_valid(music_player):
		music_player.volume_db = _music_volume_db()
	if is_instance_valid(music_fade_player) and not music_fade_player.playing:
		music_fade_player.volume_db = -60.0
	if not test_mode:
		var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != desired_mode:
			DisplayServer.window_set_mode(desired_mode)


func _sanitize_settings() -> void:
	for volume_id in ["master", "music", "sfx"]:
		settings[volume_id] = clampf(float(settings.get(volume_id, 1.0)), 0.0, 1.0)
	settings["vibration"] = bool(settings.get("vibration", true))
	settings["hit_stop"] = bool(settings.get("hit_stop", true))
	settings["reduced_flashes"] = bool(settings.get("reduced_flashes", false))
	settings["fullscreen"] = bool(settings.get("fullscreen", false))
	var assist := float(settings.get("aim_assist", 0.45))
	settings["aim_assist"] = 0.0 if assist < 0.125 else (0.25 if assist < 0.35 else 0.45)
	var language := str(settings.get("language", Localization.LANGUAGE_AUTO))
	settings["language"] = language if language in Localization.LANGUAGE_CHOICES else Localization.LANGUAGE_AUTO
	var shake := float(settings.get("screen_shake", 1.0))
	settings["screen_shake"] = 0.0 if shake < 0.25 else (0.5 if shake < 0.75 else 1.0)


func _apply_language_setting() -> void:
	var requested := str(settings.get("language", Localization.LANGUAGE_AUTO))
	if test_mode and test_force_english:
		requested = Localization.LANGUAGE_ENGLISH
	active_locale = Localization.apply_language(requested)


func _on_binding_changed(action_id: String, device_type: String, binding: Dictionary) -> void:
	if action_id not in REBIND_ACTION_IDS or device_type not in ["keyboard", "gamepad"]:
		return
	if not custom_bindings.has(action_id):
		custom_bindings[action_id] = {}
	custom_bindings[action_id][device_type] = binding.duplicate(true)
	_apply_single_binding(action_id, device_type, binding)
	hud.set_bindings(_binding_snapshot())
	if not test_mode:
		_save_run()


func _on_bindings_reset_requested() -> void:
	custom_bindings.clear()
	_restore_default_bindings()
	hud.set_bindings(_binding_snapshot())
	if not test_mode:
		_save_run()


func _prepare_default_input_actions() -> void:
	for action_id in REBIND_ACTION_IDS:
		if not InputMap.has_action(action_id):
			continue
		for event in InputMap.action_get_events(action_id):
			if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
				InputMap.action_erase_event(action_id, event)
	_ensure_input_actions()


func _capture_default_binding_events() -> void:
	default_binding_events.clear()
	for action_id in REBIND_ACTION_IDS:
		var copies: Array[InputEvent] = []
		for event in InputMap.action_get_events(action_id):
			copies.append(event.duplicate(true))
		default_binding_events[action_id] = copies


func _restore_default_bindings() -> void:
	for action_id in REBIND_ACTION_IDS:
		InputMap.action_erase_events(action_id)
		for event in default_binding_events.get(action_id, []):
			InputMap.action_add_event(action_id, event.duplicate(true))


func _apply_custom_bindings() -> void:
	for action_id in custom_bindings:
		if action_id not in REBIND_ACTION_IDS or not (custom_bindings[action_id] is Dictionary):
			continue
		for device_type in custom_bindings[action_id]:
			_apply_single_binding(action_id, str(device_type), custom_bindings[action_id][device_type])


func _apply_single_binding(action_id: String, device_type: String, binding: Dictionary) -> bool:
	if not InputMap.has_action(action_id) or not (device_type in ["keyboard", "gamepad"]):
		return false
	var binding_type := str(binding.get("type", ""))
	if device_type == "keyboard" and binding_type not in ["key", "mouse"]:
		return false
	if device_type == "gamepad" and binding_type != "joy_button":
		return false
	for existing in InputMap.action_get_events(action_id):
		var remove_keyboard := device_type == "keyboard" and (existing is InputEventKey or existing is InputEventMouseButton)
		var remove_gamepad := device_type == "gamepad" and existing is InputEventJoypadButton
		if remove_keyboard or remove_gamepad:
			InputMap.action_erase_event(action_id, existing)
	var input_event: InputEvent
	match binding_type:
		"key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(binding.get("physical_keycode", 0))
			input_event = key_event
		"mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(binding.get("button_index", MOUSE_BUTTON_LEFT))
			input_event = mouse_event
		"joy_button":
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = int(binding.get("button_index", JOY_BUTTON_A))
			input_event = joy_event
		_:
			return false
	InputMap.action_add_event(action_id, input_event)
	return true


func _binding_snapshot() -> Dictionary:
	var snapshot := {}
	for action_id in REBIND_ACTION_IDS:
		var keyboard_binding: Dictionary = {}
		var mouse_binding: Dictionary = {}
		var gamepad_binding: Dictionary = {}
		for event in InputMap.action_get_events(action_id):
			if event is InputEventKey and keyboard_binding.is_empty():
				keyboard_binding = {"type": "key", "physical_keycode": int(event.physical_keycode)}
			elif event is InputEventMouseButton and mouse_binding.is_empty():
				mouse_binding = {"type": "mouse", "button_index": int(event.button_index)}
			elif event is InputEventJoypadButton and gamepad_binding.is_empty():
				gamepad_binding = {"type": "joy_button", "button_index": int(event.button_index)}
		snapshot[action_id] = {
			"keyboard": keyboard_binding if not keyboard_binding.is_empty() else mouse_binding,
			"gamepad": gamepad_binding,
		}
	return snapshot


func _apply_meta_progression() -> void:
	for upgrade_id in meta_upgrades:
		for reached_rank in range(1, int(meta_upgrades[upgrade_id]) + 1):
			_apply_meta_bonus(upgrade_id, reached_rank)


func _apply_meta_bonus(upgrade_id: String, reached_rank: int = 1) -> void:
	var definition := Content.meta_restoration(upgrade_id)
	if definition.is_empty() or reached_rank < 1 or reached_rank > int(definition["max_rank"]):
		return
	match upgrade_id:
		"vital":
			player.max_health += 1.0
			player.health += 1.0
		"edge":
			player.damage += 0.2
		"fortune":
			player.luck += 0.05
		"stride":
			player.move_speed += 3.0
		"inkwell":
			player.ink_art_cooldown_max = maxf(3.5, player.ink_art_cooldown_max * 0.96)
		"thread":
			player.pickup_radius += 18.0
	if reached_rank == int(definition["max_rank"]):
		match upgrade_id:
			"vital":
				player.guard += 2.0
			"edge":
				player.boss_damage_bonus += 0.10
			"fortune":
				player.xp_multiplier += 0.10
			"stride":
				player.dash_cooldown_max = maxf(0.45, player.dash_cooldown_max * 0.90)
			"inkwell":
				player.ink_art_damage_multiplier += 0.15
			"thread":
				player.pickup_radius += 45.0
	player.health_changed.emit(player.health, player.max_health)
	player.build_changed.emit(player.get_build_summary())
	player._notify_ink_art_changed(true)


func _record_upgrade(upgrade_id: String) -> void:
	if upgrade_id not in discovered_upgrades:
		discovered_upgrades.append(upgrade_id)
	_evaluate_achievements()


func _contract_clear_count() -> int:
	var clears := 0
	for contract_data in Content.CONTRACTS:
		if int(contract_wins.get(contract_data["id"], 0)) > 0:
			clears += 1
	return clears


func _progression_metric(metric: String) -> int:
	match metric:
		"runs":
			return lifetime_runs
		"kills":
			return lifetime_kills
		"wave":
			return highest_wave
		"endings":
			return completed_endings.size()
		"contract_clears":
			return _contract_clear_count()
	return 0


func _unlocked_content_ids(kind: String = "") -> Array[String]:
	var unlocked: Array[String] = []
	for entry in Content.PROGRESSION_UNLOCKS:
		if not kind.is_empty() and entry["kind"] != kind:
			continue
		if _progression_metric(str(entry["metric"])) >= int(entry["target"]):
			unlocked.append(str(entry["content_id"]) if not kind.is_empty() else str(entry["id"]))
	return unlocked


func _archive_rank_snapshot() -> Dictionary:
	var archive_xp := lifetime_memory_earned
	var rank := 1
	for index in range(Content.ARCHIVE_RANK_THRESHOLDS.size()):
		if archive_xp >= int(Content.ARCHIVE_RANK_THRESHOLDS[index]):
			rank = index + 1
	var next_threshold := -1
	if rank < Content.ARCHIVE_RANK_THRESHOLDS.size():
		next_threshold = int(Content.ARCHIVE_RANK_THRESHOLDS[rank])
	return {
		"rank": rank,
		"xp": archive_xp,
		"next_threshold": next_threshold,
		"maximum": Content.ARCHIVE_RANK_THRESHOLDS.size(),
	}


func _progression_snapshot() -> Dictionary:
	var progress := {}
	var next_unlock: Dictionary = {}
	for entry in Content.PROGRESSION_UNLOCKS:
		var current := _progression_metric(str(entry["metric"]))
		var target := int(entry["target"])
		progress[entry["id"]] = {"current": current, "target": target, "unlocked": current >= target}
		if next_unlock.is_empty() and current < target:
			next_unlock = {
				"name": entry["name"],
				"current": current,
				"target": target,
				"hint": entry["hint"],
			}
	return {
		"archive_rank": _archive_rank_snapshot(),
		"unlocked_contracts": _unlocked_content_ids("contract"),
		"unlocked_weapon_forms": _unlocked_content_ids("weapon"),
		"unlocked_difficulties": _unlocked_content_ids("difficulty"),
		"unlock_progress": progress,
		"next_unlock": next_unlock,
	}


func _achievement_metric(metric: String) -> int:
	match metric:
		"kills":
			return lifetime_kills
		"memory":
			return lifetime_memory_earned
		"wave":
			return highest_wave
		"endings":
			return completed_endings.size()
		"contracts":
			return _contract_clear_count()
		"relics":
			return discovered_relics.size()
		"upgrades":
			return discovered_upgrades.size()
		"codex":
			var restored := 0
			for enemy_id in Content.ENEMIES:
				if int(codex_kills.get(enemy_id, 0)) > 0:
					restored += 1
			return restored
		"redline_wins":
			return redline_wins
		"routes":
			return discovered_routes.size()
		"directives":
			return lifetime_directives_completed
		"daily_clears":
			return lifetime_daily_clears
		"daily_streak":
			return daily_best_streak
	return 0


func _achievement_progress_snapshot() -> Dictionary:
	var progress := {}
	for achievement in Content.ACHIEVEMENTS:
		progress[achievement["id"]] = _achievement_metric(str(achievement["metric"]))
	return progress


func _evaluate_achievements(notify_player: bool = true) -> int:
	var newly_unlocked := 0
	for achievement in Content.ACHIEVEMENTS:
		var achievement_id: String = achievement["id"]
		if achievement_id in unlocked_achievements:
			continue
		if _achievement_metric(str(achievement["metric"])) < int(achievement["target"]):
			continue
		unlocked_achievements.append(achievement_id)
		newly_unlocked += 1
		if notify_player and is_instance_valid(hud) and hud.has_method("show_achievement"):
			hud.show_achievement(str(achievement["name"]), str(achievement["description"]))
	if newly_unlocked > 0 and not test_mode:
		_save_run()
	return newly_unlocked


func _meta_snapshot() -> Dictionary:
	var snapshot := {
		"meta_shards": meta_shards,
		"best_score": best_score,
		"completed_endings": completed_endings.duplicate(),
		"meta_upgrades": meta_upgrades.duplicate(),
		"codex_kills": codex_kills.duplicate(),
		"lifetime_runs": lifetime_runs,
		"contract_wins": contract_wins.duplicate(),
		"contract_best": contract_best.duplicate(),
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"achievement_progress": _achievement_progress_snapshot(),
		"lifetime_kills": lifetime_kills,
		"lifetime_memory_earned": lifetime_memory_earned,
		"highest_wave": highest_wave,
		"highest_level": highest_level,
		"lifetime_directives_completed": lifetime_directives_completed,
		"best_directives_completed": best_directives_completed,
		"max_proof_depth": max_proof_depth,
		"preferred_proof_depth": preferred_proof_depth,
		"highest_proof_cleared": highest_proof_cleared,
		"daily": _daily_snapshot(),
		"discovered_routes": discovered_routes.duplicate(),
		"recent_runs": recent_runs.duplicate(true),
		"field_manual_seen": field_manual_seen,
		"checkpoint": _checkpoint_summary(checkpoint_data),
	}
	snapshot.merge(_progression_snapshot(), true)
	return snapshot


func _daily_ordinal(date_id_value: String) -> int:
	if not Content.valid_daily_id(date_id_value):
		return -1
	return int(floor(float(Time.get_unix_time_from_datetime_string(date_id_value + "T00:00:00")) / 86400.0))


func _recalculate_daily_streaks() -> void:
	var cleared_ids: Array[String] = []
	for record_id in daily_records:
		if Content.valid_daily_id(str(record_id)) and bool(_safe_dictionary(daily_records[record_id]).get("cleared", false)):
			cleared_ids.append(str(record_id))
	cleared_ids.sort()
	if cleared_ids.is_empty():
		daily_current_streak = 0
		daily_last_clear_id = ""
		return
	var sequence := 0
	var previous_ordinal := -999999
	var calculated_best := 0
	for record_id in cleared_ids:
		var ordinal := _daily_ordinal(record_id)
		sequence = sequence + 1 if ordinal == previous_ordinal + 1 else 1
		calculated_best = maxi(calculated_best, sequence)
		previous_ordinal = ordinal
	daily_current_streak = sequence
	daily_best_streak = maxi(daily_best_streak, calculated_best)
	daily_last_clear_id = cleared_ids[-1]


func _prune_daily_records() -> void:
	var record_ids: Array[String] = []
	for record_id in daily_records:
		if Content.valid_daily_id(str(record_id)):
			record_ids.append(str(record_id))
	record_ids.sort()
	while record_ids.size() > 64:
		daily_records.erase(record_ids.pop_front())


func _record_daily_result() -> int:
	if not daily_run or not Content.valid_daily_id(daily_id):
		return 0
	var record: Dictionary = _safe_dictionary(daily_records.get(daily_id, {}))
	var was_cleared := bool(record.get("cleared", false))
	record["attempts"] = maxi(0, int(record.get("attempts", 0))) + 1
	record["wins"] = maxi(0, int(record.get("wins", 0))) + (1 if run_won else 0)
	record["best_score"] = maxi(int(record.get("best_score", 0)), score)
	record["best_wave"] = maxi(int(record.get("best_wave", 0)), wave)
	record["seed"] = run_seed
	record["contract_id"] = contract_id
	record["cleared"] = was_cleared or run_won
	daily_records[daily_id] = record
	var first_clear := run_won and not was_cleared
	if first_clear:
		lifetime_daily_clears += 1
	_prune_daily_records()
	_recalculate_daily_streaks()
	return Content.DAILY_CLEAR_BONUS if first_clear else 0


func _finalize_run() -> void:
	if run_committed:
		return
	run_committed = true
	_delete_checkpoint()
	var daily_bonus := _record_daily_result()
	if daily_bonus > 0:
		run_shards += daily_bonus
	var earned_memory := run_shards
	var unlocks_before := run_start_unlock_ids.duplicate()
	contract_attempts[contract_id] = int(contract_attempts.get(contract_id, 0)) + 1
	contract_best[contract_id] = maxi(int(contract_best.get(contract_id, 0)), score)
	if run_won:
		contract_wins[contract_id] = int(contract_wins.get(contract_id, 0)) + 1
		highest_proof_cleared = maxi(highest_proof_cleared, proof_depth)
		if difficulty_id == "redline":
			redline_wins += 1
	var unlocked_proof_depth := -1
	if run_won and proof_depth >= max_proof_depth and max_proof_depth < Content.PROOF_LEVELS.size() - 1:
		max_proof_depth += 1
		preferred_proof_depth = max_proof_depth
		unlocked_proof_depth = max_proof_depth
	meta_shards += run_shards
	run_shards = 0
	lifetime_runs += 1
	best_directives_completed = maxi(best_directives_completed, run_directives_completed)
	_evaluate_achievements()
	var new_unlocks: Array[String] = []
	for unlock_id in _unlocked_content_ids():
		if unlock_id not in unlocks_before:
			var unlock_data: Dictionary = Content.progression_unlock(unlock_id)
			if not unlock_data.is_empty():
				new_unlocks.append(str(unlock_data["name"]))
	if unlocked_proof_depth >= 0:
		new_unlocks.append("PROOF %d · %s" % [unlocked_proof_depth, Content.proof_level(unlocked_proof_depth)["name"]])
	if daily_bonus > 0:
		new_unlocks.append("DAILY FIRST CLEAR · MEMORY +%d" % daily_bonus)
	last_run_summary = {
		"run_number": lifetime_runs,
		"won": run_won,
		"ending": ending_id,
		"score": score,
		"kills": kills,
		"wave": wave,
		"level": player.level,
		"duration_seconds": int(elapsed),
		"difficulty": difficulty_id,
		"contract": contract_id,
		"contract_name": str(Content.contract(contract_id).get("name", contract_id.to_upper())),
		"proof_depth": proof_depth,
		"proof_name": str(Content.proof_level(proof_depth).get("name", "OPEN PROOF")),
		"daily_run": daily_run,
		"daily_id": daily_id,
		"run_seed": run_seed,
		"daily_bonus": daily_bonus,
		"daily_streak": daily_current_streak,
		"starting_weapon": starting_weapon_id,
		"weapon_form": player.weapon_form,
		"relic_ids": relic_ids.duplicate(),
		"relic_count": relic_ids.size(),
		"route_ids": chosen_routes.duplicate(),
		"memory_earned": earned_memory,
		"best_score": best_score,
		"new_unlocks": new_unlocks,
		"archive_rank": int(_archive_rank_snapshot()["rank"]),
		"directives_completed": run_directives_completed,
		"directives_started": run_directives_started,
		"squad_id": active_squad_id,
	}
	recent_runs.push_front(last_run_summary.duplicate(true))
	if recent_runs.size() > 10:
		recent_runs.resize(10)
	record_playtest_event("run_finalized", last_run_summary)


func _on_upgrade_selected(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return
	var choice := current_choices[index]
	record_playtest_event("upgrade_selected", {"index": index, "upgrade": str(choice.get("id", "")), "level": player.level, "page": wave})
	player.apply_upgrade(choice["id"])
	_record_upgrade(choice["id"])
	spawn_word(player.global_position + Vector2(0, -38), choice["name"], GOLD)
	current_choices.clear()
	choosing_upgrade = false
	if not _try_open_pending_relic_draft():
		_sync_pause_state()
		_save_checkpoint("level-%d" % player.level)
	vibrate(0.12, 0.25, 0.08)


func _on_relic_selected(index: int) -> void:
	if not choosing_relic or index < 0 or index >= current_relic_choices.size():
		return
	var selected: Dictionary = current_relic_choices[index]
	var relic_id := str(selected.get("id", ""))
	record_playtest_event("relic_selected", {"index": index, "relic": relic_id, "page": wave})
	current_relic_choices.clear()
	choosing_relic = false
	_grant_relic(relic_id)
	vibrate(0.22, 0.5, 0.12)
	if _try_open_pending_relic_draft():
		return
	_sync_pause_state()
	_save_checkpoint("relic-" + relic_id)


func _toggle_pause() -> void:
	if not application_focused:
		return
	if choosing_upgrade or choosing_relic or choosing_event or game_over or run_won or (is_instance_valid(cutscene) and cutscene.active):
		return
	manually_paused = not manually_paused
	record_playtest_event("manual_pause", {"paused": manually_paused, "page": wave})
	if not manually_paused:
		focus_pause_engaged = false
	_sync_pause_state()


func _on_save_return_requested() -> void:
	if not run_started or not manually_paused or game_over or run_won:
		return
	if not _save_checkpoint("manual"):
		record_playtest_event("save_return_failed", {"page": wave})
		hud.show_device_notice("SAVE FAILED  ·  DRAFT STILL RUNNING")
		return
	_save_run()
	record_playtest_event("save_return", {"page": wave, "elapsed": elapsed, "health": player.health})
	play_sound("save")
	if not test_mode:
		await get_tree().create_timer(0.16, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _simulation_should_pause() -> bool:
	var story_active := is_instance_valid(cutscene) and cutscene.active
	return not application_focused or not run_started or manually_paused or manual_open or choosing_upgrade or choosing_relic or choosing_event or game_over or run_won or story_active


func _sync_pause_state() -> void:
	# Every modal path goes through this one arbitration point. Closing one modal
	# must never resume a run while another pause reason is still active.
	get_tree().paused = _simulation_should_pause()
	if is_instance_valid(hud):
		hud.set_paused(manually_paused)


func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	Engine.time_scale = 1.0
	best_score = maxi(best_score, score)
	best_kills = maxi(best_kills, kills)
	_finalize_run()
	_save_run()
	spawn_word(player.global_position + Vector2(0, -32), "THE END?", CRIMSON)
	hud.show_game_over(last_run_summary)
	_sync_pause_state()
	request_playtest_survey("defeat")


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func clamp_to_arena(point: Vector2, margin: float = 20.0) -> Vector2:
	return arena.clamp_point(point, margin) if is_instance_valid(arena) else point


func _ensure_input_actions() -> void:
	if input_actions_initialized:
		return
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_bind_keys("move_up", [KEY_W, KEY_UP])
	_bind_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_bind_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_bind_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)

	_bind_joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_bind_joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_bind_joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	_bind_keys("attack", [KEY_J])
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)
	_bind_joy_button("attack", JOY_BUTTON_X)
	_bind_joy_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_bind_keys("dash", [KEY_SPACE, KEY_K])
	_bind_mouse("dash", MOUSE_BUTTON_RIGHT)
	_bind_joy_button("dash", JOY_BUTTON_A)
	_bind_joy_button("dash", JOY_BUTTON_LEFT_SHOULDER)
	_bind_keys("special", [KEY_E])
	_bind_mouse("special", MOUSE_BUTTON_MIDDLE)
	_bind_joy_button("special", JOY_BUTTON_B)

	_bind_keys("pause", [KEY_ESCAPE])
	_bind_joy_button("pause", JOY_BUTTON_START)
	_bind_keys("options", [KEY_O, KEY_F10])
	_bind_joy_button("options", JOY_BUTTON_BACK)
	_bind_keys("manual", [KEY_F1, KEY_H])
	_bind_joy_axis("manual", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_bind_keys("restoration", [KEY_M])
	_bind_joy_button("restoration", JOY_BUTTON_RIGHT_STICK)
	_bind_keys("proof_ledger", [KEY_P])
	_bind_joy_button("proof_ledger", JOY_BUTTON_LEFT_STICK)
	_bind_keys("daily_chronicle", [KEY_T])
	_bind_joy_button("daily_chronicle", JOY_BUTTON_DPAD_DOWN)
	_bind_keys("contract_prev", [KEY_Q])
	_bind_joy_button("contract_prev", JOY_BUTTON_LEFT_SHOULDER)
	_bind_keys("contract_next", [KEY_E])
	_bind_joy_button("contract_next", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_keys("restart", [KEY_R])
	_bind_joy_button("restart", JOY_BUTTON_A)
	_bind_joy_button("restart", JOY_BUTTON_START)

	_bind_keys("upgrade_1", [KEY_1])
	_bind_joy_button("upgrade_1", JOY_BUTTON_X)
	_bind_joy_button("upgrade_1", JOY_BUTTON_DPAD_LEFT)
	_bind_keys("upgrade_2", [KEY_2])
	_bind_joy_button("upgrade_2", JOY_BUTTON_Y)
	_bind_joy_button("upgrade_2", JOY_BUTTON_DPAD_UP)
	_bind_keys("upgrade_3", [KEY_3])
	_bind_joy_button("upgrade_3", JOY_BUTTON_B)
	_bind_joy_button("upgrade_3", JOY_BUTTON_DPAD_RIGHT)
	_bind_keys("upgrade_4", [KEY_4])
	_bind_joy_axis("upgrade_4", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	input_actions_initialized = true


func _bind_keys(action: StringName, keys: Array) -> void:
	_ensure_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		_add_input_event(action, event)


func _bind_mouse(action: StringName, button: MouseButton) -> void:
	_ensure_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add_input_event(action, event)


func _bind_joy_button(action: StringName, button: int) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_add_input_event(action, event)


func _bind_joy_axis(action: StringName, axis: int, axis_value: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	_add_input_event(action, event)


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.22)


func _add_input_event(action: StringName, event: InputEvent) -> void:
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _input(event: InputEvent) -> void:
	if not application_focused:
		return
	if event is InputEventJoypadButton and event.pressed:
		_set_input_mode(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.42:
		_set_input_mode(true)
	elif event is InputEventKey and event.pressed:
		_set_input_mode(false)
	elif event is InputEventMouseButton and event.pressed:
		_set_input_mode(false)
	elif event is InputEventMouseMotion and event.relative.length_squared() > 4.0:
		_set_input_mode(false)


func _set_input_mode(gamepad_active: bool) -> void:
	var changed := using_gamepad != gamepad_active
	using_gamepad = gamepad_active
	if is_instance_valid(player):
		player.using_gamepad = gamepad_active
	if is_instance_valid(hud):
		hud.set_input_mode(gamepad_active)
	if changed:
		record_playtest_event("input_mode_changed", {"mode": "gamepad" if gamepad_active else "keyboard_mouse"})


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not application_focused:
		return
	if connected:
		record_playtest_event("gamepad_connection", {"device": device, "connected": true, "name": Input.get_joy_name(device).left(80)})
		_set_input_mode(true)
		if is_instance_valid(hud):
			hud.show_device_notice(("手柄已就绪  ·  P%d  ·  B / ○ 墨术" if TranslationServer.get_locale().begins_with("zh") else "GAMEPAD READY  ·  P%d  ·  B / CIRCLE INK ART") % (device + 1))
	elif Input.get_connected_joypads().is_empty():
		record_playtest_event("gamepad_connection", {"device": device, "connected": false})
		_set_input_mode(false)
		if is_instance_valid(hud):
			hud.show_device_notice("GAMEPAD DISCONNECTED")


func _checkpoint_summary(payload: Dictionary) -> Dictionary:
	if payload.is_empty():
		return {}
	var player_state: Dictionary = payload.get("player", {})
	return {
		"wave": maxi(1, int(payload.get("wave", 1))),
		"level": maxi(1, int(player_state.get("level", 1))),
		"kills": maxi(0, int(payload.get("kills", 0))),
		"score": maxi(0, int(payload.get("score", 0))),
		"difficulty": str(payload.get("difficulty_id", "standard")),
		"contract": str(payload.get("contract_id", "open-draft")),
		"proof_depth": clampi(int(payload.get("proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1),
		"daily_run": bool(payload.get("daily_run", false)),
		"daily_id": str(payload.get("daily_id", "")),
		"run_seed": maxi(0, int(payload.get("run_seed", 0))),
		"saved_at": int(payload.get("saved_at_unix", 0)),
	}


func _checkpoint_enemy_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get_parent() != self or bool(enemy.get("dead")):
			continue
		result.append({
			"kind": str(enemy.get("enemy_kind")),
			"position": [enemy.global_position.x, enemy.global_position.y],
			"health": float(enemy.get("health")),
			"max_health": float(enemy.get("max_health")),
			"contact_damage": float(enemy.get("contact_damage")),
			"speed": float(enemy.get("speed")),
			"elite": bool(enemy.get("is_elite")),
		})
		if result.size() >= 72:
			break
	return result


func _checkpoint_payload(reason: String) -> Dictionary:
	return {
		"checkpoint_schema": CHECKPOINT_SCHEMA,
		"profile_schema": SAVE_SCHEMA,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"reason": reason.left(32),
		"elapsed": elapsed,
		"spawn_timer": spawn_timer,
		"wave": wave,
		"kills": kills,
		"score": score,
		"run_shards": run_shards,
		"difficulty_id": difficulty_id,
		"contract_id": contract_id,
		"proof_depth": proof_depth,
		"daily_run": daily_run,
		"daily_id": daily_id,
		"run_seed": run_seed,
		"rng_state": str(rng.state),
		"starting_weapon_id": starting_weapon_id,
		"active_route_id": active_route_id,
		"route_hazard": route_hazard.get_state() if is_instance_valid(route_hazard) else {},
		"chosen_routes": chosen_routes.duplicate(),
		"seen_events": seen_events.duplicate(),
		"story_seen": story_seen.duplicate(true),
		"pending_boss_kind": pending_boss_kind,
		"relic_ids": relic_ids.duplicate(),
		"run_start_unlock_ids": run_start_unlock_ids.duplicate(),
		"kills_since_heal_drop": kills_since_heal_drop,
		"kills_since_supply_drop": kills_since_supply_drop,
		"heal_drops_spawned": heal_drops_spawned,
		"combat_drops_spawned": combat_drops_spawned,
		"active_directive": active_directive.duplicate(true),
		"directive_progress": directive_progress,
		"directive_target": directive_target,
		"directive_completed": directive_completed,
		"directive_history": directive_history.duplicate(),
		"squad_history": squad_history.duplicate(),
		"active_squad_id": active_squad_id,
		"encounter_started_wave": encounter_started_wave,
		"run_directives_started": run_directives_started,
		"run_directives_completed": run_directives_completed,
		"directive_score_bonus": directive_score_bonus,
		"directive_zone_position": [directive_zone_position.x, directive_zone_position.y],
		"player_position": [player.global_position.x, player.global_position.y],
		"player": player.get_session_state(),
		"enemies": _checkpoint_enemy_snapshot(),
	}


func _is_valid_checkpoint_payload(payload: Dictionary) -> bool:
	if int(payload.get("checkpoint_schema", -1)) != CHECKPOINT_SCHEMA:
		return false
	for required_key in ["elapsed", "wave", "kills", "difficulty_id", "contract_id", "player", "enemies"]:
		if not payload.has(required_key):
			return false
	if not (payload["player"] is Dictionary) or not (payload["enemies"] is Array):
		return false
	if not (payload.get("chosen_routes", []) is Array) or not (payload.get("seen_events", []) is Array) or not (payload.get("story_seen", {}) is Dictionary):
		return false
	if not (payload.get("route_hazard", {}) is Dictionary):
		return false
	if not (payload.get("active_directive", {}) is Dictionary) or not (payload.get("directive_history", []) is Array) or not (payload.get("squad_history", []) is Array):
		return false
	if str(payload.get("difficulty_id", "")) not in ["story", "standard", "redline"]:
		return false
	if Content.contract(str(payload.get("contract_id", ""))).is_empty():
		return false
	if int(payload.get("proof_depth", 0)) < 0 or int(payload.get("proof_depth", 0)) >= Content.PROOF_LEVELS.size():
		return false
	if bool(payload.get("daily_run", false)) and (not Content.valid_daily_id(str(payload.get("daily_id", ""))) or int(payload.get("run_seed", 0)) <= 0):
		return false
	if payload.has("starting_weapon_id") and Content.starting_weapon(str(payload.get("starting_weapon_id", ""))).is_empty():
		return false
	if float(payload.get("elapsed", -1.0)) < 0.0 or int(payload.get("wave", 0)) < 1:
		return false
	return true


func _read_checkpoint_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"state": "missing", "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"state": "corrupt", "data": {}}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not (parser.data is Dictionary):
		return {"state": "corrupt", "data": {}}
	var parsed: Dictionary = parser.data
	if int(parsed.get("checkpoint_schema", -1)) > CHECKPOINT_SCHEMA:
		return {"state": "future", "data": parsed}
	if not _is_valid_checkpoint_payload(parsed):
		return {"state": "corrupt", "data": {}}
	return {"state": "ok", "data": parsed}


func _load_checkpoint() -> void:
	checkpoint_data.clear()
	checkpoint_recovered = false
	checkpoint_corrupt_detected = false
	var primary := _read_checkpoint_file(checkpoint_path)
	if primary["state"] == "ok":
		checkpoint_data = primary["data"].duplicate(true)
		return
	var backup := _read_checkpoint_file(backup_checkpoint_path)
	if backup["state"] == "ok":
		checkpoint_data = backup["data"].duplicate(true)
		checkpoint_recovered = true
		_restore_checkpoint_primary(checkpoint_data)
		return
	if primary["state"] == "corrupt":
		checkpoint_corrupt_detected = true
		_quarantine_file(checkpoint_path, corrupt_checkpoint_path)
	if backup["state"] == "corrupt":
		checkpoint_corrupt_detected = true
		_quarantine_file(backup_checkpoint_path, corrupt_backup_checkpoint_path)


func _save_checkpoint(reason: String = "auto") -> bool:
	if not run_started or game_over or run_won or choosing_upgrade or choosing_relic or choosing_event or not pending_relic_sources.is_empty() or replaying_story:
		return false
	var payload := _checkpoint_payload(reason)
	var temp := FileAccess.open(temp_checkpoint_path, FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(JSON.stringify(payload, "  "))
	temp.flush()
	temp = null
	if _read_checkpoint_file(temp_checkpoint_path)["state"] != "ok":
		_remove_file_if_present(temp_checkpoint_path)
		return false
	if FileAccess.file_exists(checkpoint_path):
		_remove_file_if_present(backup_checkpoint_path)
		if _rename_save_file(checkpoint_path, backup_checkpoint_path) != OK:
			_remove_file_if_present(temp_checkpoint_path)
			return false
	if _rename_save_file(temp_checkpoint_path, checkpoint_path) != OK:
		if FileAccess.file_exists(backup_checkpoint_path):
			_rename_save_file(backup_checkpoint_path, checkpoint_path)
		_remove_file_if_present(temp_checkpoint_path)
		return false
	checkpoint_data = payload.duplicate(true)
	record_playtest_event("checkpoint_saved", {"reason": reason, "page": wave, "elapsed": elapsed})
	return true


func _restore_checkpoint_primary(payload: Dictionary) -> bool:
	var temp := FileAccess.open(temp_checkpoint_path, FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(JSON.stringify(payload, "  "))
	temp.flush()
	temp = null
	if _read_checkpoint_file(temp_checkpoint_path)["state"] != "ok":
		_remove_file_if_present(temp_checkpoint_path)
		return false
	if FileAccess.file_exists(checkpoint_path):
		_quarantine_file(checkpoint_path, corrupt_checkpoint_path)
	if _rename_save_file(temp_checkpoint_path, checkpoint_path) != OK:
		_remove_file_if_present(temp_checkpoint_path)
		return false
	return true


func _delete_checkpoint() -> void:
	checkpoint_data.clear()
	for path in [checkpoint_path, backup_checkpoint_path, temp_checkpoint_path]:
		_remove_file_if_present(path)


func _on_continue_requested() -> void:
	if checkpoint_data.is_empty():
		_load_checkpoint()
	if checkpoint_data.is_empty() or not _apply_checkpoint(checkpoint_data):
		record_playtest_event("continue_failed")
		hud.show_device_notice("SAVED DRAFT COULD NOT BE LOADED")
		return
	record_playtest_event("run_continued", {"page": wave, "elapsed": elapsed, "health": player.health, "weapon": player.weapon_form})


func _restore_route_modifiers(route_id: String) -> void:
	active_route_id = ""
	if is_instance_valid(route_hazard):
		route_hazard.clear_route()
	route_enemy_bias.clear()
	route_enemy_bias_chance = 0.0
	route_enemy_health = 1.0
	route_enemy_damage = 1.0
	route_enemy_speed = 1.0
	route_spawn_interval = 1.0
	route_enemy_cap = 1.0
	route_recovery = 1.0
	route_elite_bonus = 0.0
	route_score_multiplier = 1.0
	route_shard_multiplier = 1.0
	var data: Dictionary = Content.route(route_id)
	if data.is_empty():
		return
	active_route_id = route_id
	for enemy_id in data.get("enemy_bias", []):
		if Content.ENEMIES.has(str(enemy_id)):
			route_enemy_bias.append(str(enemy_id))
	route_enemy_bias_chance = clampf(float(data.get("bias_chance", 0.0)), 0.0, 1.0)
	route_enemy_health = maxf(0.1, float(data.get("enemy_health", 1.0)))
	route_enemy_damage = maxf(0.1, float(data.get("enemy_damage", 1.0)))
	route_enemy_speed = maxf(0.1, float(data.get("enemy_speed", 1.0)))
	route_spawn_interval = maxf(0.1, float(data.get("spawn_interval", 1.0)))
	route_enemy_cap = maxf(0.1, float(data.get("enemy_cap", 1.0)))
	route_recovery = maxf(0.0, float(data.get("recovery", 1.0)))
	route_elite_bonus = clampf(float(data.get("elite_bonus", 0.0)), 0.0, 0.8)
	route_score_multiplier = maxf(0.1, float(data.get("score", 1.0)))
	route_shard_multiplier = maxf(0.1, float(data.get("shards", 1.0)))
	if is_instance_valid(route_hazard):
		route_hazard.set_route(route_id)


func _apply_checkpoint(payload: Dictionary) -> bool:
	if not _is_valid_checkpoint_payload(payload):
		return false
	restoring_checkpoint = true
	daily_run = bool(payload.get("daily_run", false))
	daily_id = str(payload.get("daily_id", "")) if daily_run else ""
	run_seed = maxi(0, int(payload.get("run_seed", 0))) if daily_run else 0
	_configure_difficulty(str(payload.get("difficulty_id", "standard")))
	_configure_contract(str(payload.get("contract_id", "open-draft")))
	_configure_proof(int(payload.get("proof_depth", 0)), true)
	starting_weapon_id = str(payload.get("starting_weapon_id", "marginalia"))
	if Content.starting_weapon(starting_weapon_id).is_empty():
		starting_weapon_id = "marginalia"
	elapsed = clampf(float(payload.get("elapsed", 0.0)), 0.0, 7200.0)
	spawn_timer = clampf(float(payload.get("spawn_timer", 0.5)), 0.05, 5.0)
	wave = clampi(int(payload.get("wave", 1)), 1, 100)
	kills = maxi(0, int(payload.get("kills", 0)))
	score = maxi(0, int(payload.get("score", 0)))
	run_shards = maxi(0, int(payload.get("run_shards", 0)))
	kills_since_heal_drop = maxi(0, int(payload.get("kills_since_heal_drop", 0)))
	kills_since_supply_drop = maxi(0, int(payload.get("kills_since_supply_drop", 0)))
	heal_drops_spawned = maxi(0, int(payload.get("heal_drops_spawned", 0)))
	combat_drops_spawned = maxi(0, int(payload.get("combat_drops_spawned", 0)))
	active_directive.clear()
	var saved_directive: Dictionary = payload.get("active_directive", {})
	var saved_directive_id := str(saved_directive.get("id", ""))
	if not Content.directive(saved_directive_id).is_empty():
		active_directive = Content.directive(saved_directive_id)
	directive_progress = maxf(0.0, float(payload.get("directive_progress", 0.0)))
	directive_target = maxf(0.0, float(payload.get("directive_target", active_directive.get("target", 0.0))))
	directive_completed = bool(payload.get("directive_completed", false)) and not active_directive.is_empty()
	directive_history.clear()
	for directive_id in payload.get("directive_history", []):
		var clean_directive_id := str(directive_id)
		if not Content.directive(clean_directive_id).is_empty() and clean_directive_id not in directive_history:
			directive_history.append(clean_directive_id)
	squad_history.clear()
	for squad_id in payload.get("squad_history", []):
		var clean_squad_id := str(squad_id)
		if not Content.squad(clean_squad_id).is_empty() and clean_squad_id not in squad_history:
			squad_history.append(clean_squad_id)
	active_squad_id = str(payload.get("active_squad_id", ""))
	active_squad_name = str(Content.squad(active_squad_id).get("name", ""))
	encounter_started_wave = maxi(0, int(payload.get("encounter_started_wave", 0)))
	run_directives_started = maxi(0, int(payload.get("run_directives_started", 0)))
	run_directives_completed = clampi(int(payload.get("run_directives_completed", 0)), 0, run_directives_started)
	directive_score_bonus = maxi(0, int(payload.get("directive_score_bonus", 0)))
	var saved_zone_position: Array = payload.get("directive_zone_position", [0.0, 0.0])
	if saved_zone_position.size() >= 2:
		directive_zone_position = Vector2(float(saved_zone_position[0]), float(saved_zone_position[1]))
	chosen_routes.clear()
	for route_id in payload.get("chosen_routes", []):
		var clean_route_id := str(route_id)
		if not Content.route(clean_route_id).is_empty() and clean_route_id not in chosen_routes:
			chosen_routes.append(clean_route_id)
	seen_events.clear()
	for event_id in payload.get("seen_events", []):
		seen_events.append(str(event_id))
	story_seen = payload.get("story_seen", {}).duplicate(true)
	pending_boss_kind = str(payload.get("pending_boss_kind", ""))
	run_start_unlock_ids.clear()
	for unlock_id in payload.get("run_start_unlock_ids", []):
		run_start_unlock_ids.append(str(unlock_id))
	_restore_route_modifiers(str(payload.get("active_route_id", "")))
	var saved_hazard_state: Dictionary = payload.get("route_hazard", {})
	if is_instance_valid(route_hazard) and not saved_hazard_state.is_empty():
		route_hazard.apply_state(saved_hazard_state)
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node.get_parent() == self:
			node.free()
	for node in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(node) and node.get_parent() == self:
			node.free()
	if not player.apply_session_state(payload.get("player", {})):
		restoring_checkpoint = false
		return false
	var player_position: Array = payload.get("player_position", [0.0, 0.0])
	if player_position.size() >= 2:
		player.global_position = clamp_to_arena(Vector2(float(player_position[0]), float(player_position[1])), 22.0)
	relic_ids.clear()
	for relic_id in payload.get("relic_ids", []):
		var clean_relic_id := str(relic_id)
		if not clean_relic_id.is_empty() and clean_relic_id not in relic_ids:
			relic_ids.append(clean_relic_id)
	var restored_enemies := 0
	for enemy_state in payload.get("enemies", []):
		if not (enemy_state is Dictionary):
			continue
		var kind := str(enemy_state.get("kind", "mask"))
		if not Content.ENEMIES.has(kind):
			continue
		var position_data: Array = enemy_state.get("position", [0.0, 0.0])
		if position_data.size() < 2:
			continue
		var restored_enemy := spawn_enemy(kind, clamp_to_arena(Vector2(float(position_data[0]), float(position_data[1])), 24.0))
		if bool(enemy_state.get("elite", false)) and not restored_enemy.is_elite and kind not in BOSS_KINDS:
			restored_enemy.promote_to_elite()
		restored_enemy.max_health = clampf(float(enemy_state.get("max_health", restored_enemy.max_health)), 1.0, 100000.0)
		restored_enemy.health = clampf(float(enemy_state.get("health", restored_enemy.max_health)), 0.1, restored_enemy.max_health)
		restored_enemy.contact_damage = clampf(float(enemy_state.get("contact_damage", restored_enemy.contact_damage)), 0.0, 1000.0)
		restored_enemy.speed = clampf(float(enemy_state.get("speed", restored_enemy.speed)), 0.0, 1000.0)
		restored_enemies += 1
	if restored_enemies == 0:
		var resume_pack_size := mini(8, 3 + int(wave / 2))
		for index in range(resume_pack_size):
			spawn_enemy(_roll_enemy_kind(), clamp_to_arena(player.global_position + Vector2.from_angle(TAU * float(index) / float(maxi(1, resume_pack_size))) * 150.0, 24.0))
	var saved_rng_state := str(payload.get("rng_state", ""))
	if saved_rng_state.is_valid_int():
		rng.state = int(saved_rng_state)
	if is_instance_valid(arena):
		arena.set_chapter(1 if wave < 5 else (2 if wave < 9 else 3))
		if not active_route_id.is_empty():
			arena.set_route(active_route_id)
	run_started = true
	run_committed = false
	game_over = false
	run_won = false
	ending_id = ""
	choosing_upgrade = false
	choosing_relic = false
	choosing_event = false
	current_relic_choices.clear()
	pending_relic_sources.clear()
	manually_paused = false
	replaying_story = false
	restoring_checkpoint = false
	hud.hide_title()
	hud.set_health(player.health, player.max_health)
	hud.set_xp(player.xp, player.xp_needed, player.level)
	hud.set_run_stats(wave, score, true)
	hud.set_shards(run_shards)
	hud.set_relics(relic_ids)
	hud.set_build(player.get_build_summary())
	pending_page_encounter = false
	if not active_directive.is_empty():
		_update_directive_hud(false)
		if str(active_directive.get("kind", "")) == "hold" and not directive_completed:
			_spawn_directive_zone(directive_progress, directive_zone_position)
	elif encounter_started_wave != wave:
		_start_page_encounter(wave)
	else:
		hud.hide_page_directive()
	_refresh_run_objective()
	var restored_bosses := get_tree().get_nodes_in_group("bosses")
	play_music(_boss_music_id(str(restored_bosses[0].enemy_kind)) if not restored_bosses.is_empty() else _chapter_music_id())
	if TranslationServer.get_locale().begins_with("zh"):
		hud.show_device_notice("每日 %s 已读取  ·  第 %d 页  ·  1.2 秒保护" % [daily_id, wave] if daily_run else "草稿已读取  ·  第 %d 页  ·  校样 %d  ·  1.2 秒保护" % [wave, proof_depth])
	else:
		hud.show_device_notice("DAILY %s LOADED  ·  PAGE %d  ·  1.2s GRACE" % [daily_id, wave] if daily_run else "DRAFT LOADED  ·  PAGE %d  ·  PROOF %d  ·  1.2s GRACE" % [wave, proof_depth])
	_sync_pause_state()
	return true


func _load_save() -> void:
	save_recovered = false
	save_corrupt_detected = false
	save_incompatible = false
	var primary := _read_save_file(save_path)
	if primary["state"] == "ok":
		_apply_save_payload(primary["data"])
		return
	if primary["state"] == "future":
		save_incompatible = true
		return

	var backup := _read_save_file(backup_save_path)
	if backup["state"] == "ok":
		_apply_save_payload(backup["data"])
		save_recovered = true
		_restore_primary_from_payload(backup["data"])
		return
	if backup["state"] == "future":
		save_incompatible = true
		return

	if primary["state"] == "corrupt":
		save_corrupt_detected = true
		_quarantine_file(save_path, corrupt_save_path)
	if backup["state"] == "corrupt":
		save_corrupt_detected = true
		_quarantine_file(backup_save_path, corrupt_backup_save_path)


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"state": "missing", "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"state": "corrupt", "data": {}}
	var text := file.get_as_text()
	file = null
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"state": "corrupt", "data": {}}
	var parsed = parser.data
	if not (parsed is Dictionary):
		return {"state": "corrupt", "data": {}}
	var schema := int(parsed.get("schema_version", -1))
	if schema > SAVE_SCHEMA:
		return {"state": "future", "data": parsed}
	if not _is_valid_save_payload(parsed):
		return {"state": "corrupt", "data": {}}
	return {"state": "ok", "data": parsed}


func _is_valid_save_payload(payload: Dictionary) -> bool:
	var schema := int(payload.get("schema_version", -1))
	if schema < 1 or schema > SAVE_SCHEMA:
		return false
	for required_key in ["best_score", "best_kills", "meta_shards", "lifetime_runs", "settings"]:
		if not payload.has(required_key):
			return false
	for dictionary_key in ["settings", "meta_upgrades", "codex_kills", "contract_wins", "contract_best", "contract_attempts", "daily_records", "custom_bindings"]:
		if payload.has(dictionary_key) and not (payload[dictionary_key] is Dictionary):
			return false
	for array_key in ["completed_endings", "unlocked_achievements", "discovered_relics", "discovered_upgrades", "discovered_routes", "recent_runs"]:
		if payload.has(array_key) and not (payload[array_key] is Array):
			return false
	return true


func _safe_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _safe_array(value: Variant) -> Array:
	return value if value is Array else []


func _sanitize_recent_run(value: Variant) -> Dictionary:
	if not (value is Dictionary):
		return {}
	var difficulty := str(value.get("difficulty", "standard"))
	if difficulty not in ["story", "standard", "redline"]:
		difficulty = "standard"
	var contract := str(value.get("contract", "open-draft"))
	if Content.contract(contract).get("id", "open-draft") != contract:
		contract = "open-draft"
	var unlocks: Array[String] = []
	for unlock_name in _safe_array(value.get("new_unlocks", [])):
		var clean_name := str(unlock_name).left(48)
		if not clean_name.is_empty() and clean_name not in unlocks:
			unlocks.append(clean_name)
	var route_ids: Array[String] = []
	for route_id in _safe_array(value.get("route_ids", [])):
		var clean_route_id := str(route_id)
		if not Content.route(clean_route_id).is_empty() and clean_route_id not in route_ids:
			route_ids.append(clean_route_id)
		if route_ids.size() >= 3:
			break
	var run_relic_ids: Array[String] = []
	for relic_id in _safe_array(value.get("relic_ids", [])):
		var clean_relic_id := str(relic_id)
		if not Content.relic(clean_relic_id).is_empty() and clean_relic_id not in run_relic_ids:
			run_relic_ids.append(clean_relic_id)
		if run_relic_ids.size() >= Content.RELICS.size():
			break
	var was_daily := bool(value.get("daily_run", false)) and Content.valid_daily_id(str(value.get("daily_id", "")))
	return {
		"run_number": maxi(0, int(value.get("run_number", 0))),
		"won": bool(value.get("won", false)),
		"ending": str(value.get("ending", "")).left(16),
		"score": maxi(0, int(value.get("score", 0))),
		"kills": maxi(0, int(value.get("kills", 0))),
		"wave": maxi(1, int(value.get("wave", 1))),
		"level": maxi(1, int(value.get("level", 1))),
		"duration_seconds": maxi(0, int(value.get("duration_seconds", 0))),
		"difficulty": difficulty,
		"contract": contract,
		"contract_name": str(Content.contract(contract).get("name", "OPEN DRAFT")),
		"proof_depth": clampi(int(value.get("proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1),
		"proof_name": str(Content.proof_level(clampi(int(value.get("proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)).get("name", "OPEN PROOF")),
		"daily_run": was_daily,
		"daily_id": str(value.get("daily_id", "")) if was_daily else "",
		"run_seed": maxi(0, int(value.get("run_seed", 0))) if was_daily else 0,
		"daily_bonus": maxi(0, int(value.get("daily_bonus", 0))) if was_daily else 0,
		"daily_streak": maxi(0, int(value.get("daily_streak", 0))) if was_daily else 0,
		"starting_weapon": str(value.get("starting_weapon", "marginalia")).left(24) if not Content.starting_weapon(str(value.get("starting_weapon", "marginalia"))).is_empty() else "marginalia",
		"weapon_form": str(value.get("weapon_form", "MARGINALIA")).left(24),
		"relic_ids": run_relic_ids,
		"relic_count": run_relic_ids.size() if value.has("relic_ids") else clampi(int(value.get("relic_count", 0)), 0, Content.RELICS.size()),
		"route_ids": route_ids,
		"memory_earned": maxi(0, int(value.get("memory_earned", 0))),
		"best_score": maxi(0, int(value.get("best_score", 0))),
		"new_unlocks": unlocks,
		"archive_rank": clampi(int(value.get("archive_rank", 1)), 1, Content.ARCHIVE_RANK_THRESHOLDS.size()),
		"directives_completed": maxi(0, int(value.get("directives_completed", 0))),
		"directives_started": maxi(0, int(value.get("directives_started", 0))),
		"squad_id": str(value.get("squad_id", "")).left(32),
	}


func _apply_save_payload(parsed: Dictionary) -> void:
	best_score = maxi(0, int(parsed.get("best_score", 0)))
	best_kills = maxi(0, int(parsed.get("best_kills", 0)))
	meta_shards = maxi(0, int(parsed.get("meta_shards", 0)))
	lifetime_runs = maxi(0, int(parsed.get("lifetime_runs", 0)))
	save_generation = maxi(0, int(parsed.get("save_generation", 0)))
	var saved_meta := _safe_dictionary(parsed.get("meta_upgrades", {}))
	for upgrade_id in meta_upgrades:
		var definition := Content.meta_restoration(upgrade_id)
		var maximum := int(definition.get("max_rank", 0))
		meta_upgrades[upgrade_id] = clampi(int(saved_meta.get(upgrade_id, 0)), 0, maximum)
	completed_endings.clear()
	for ending in _safe_array(parsed.get("completed_endings", [])):
		var ending_id := str(ending)
		if ending_id in ["keep", "rewrite"] and ending_id not in completed_endings:
			completed_endings.append(ending_id)
	var migrated_proof_depth := 1 if int(parsed.get("schema_version", 1)) <= 10 and not completed_endings.is_empty() else 0
	max_proof_depth = clampi(int(parsed.get("max_proof_depth", migrated_proof_depth)), 0, Content.PROOF_LEVELS.size() - 1)
	preferred_proof_depth = clampi(int(parsed.get("preferred_proof_depth", max_proof_depth)), 0, max_proof_depth)
	highest_proof_cleared = clampi(int(parsed.get("highest_proof_cleared", max_proof_depth - 1)), -1, Content.PROOF_LEVELS.size() - 1)
	max_proof_depth = maxi(max_proof_depth, mini(Content.PROOF_LEVELS.size() - 1, highest_proof_cleared + 1))
	codex_kills = _safe_dictionary(parsed.get("codex_kills", {}))
	contract_wins = _safe_dictionary(parsed.get("contract_wins", {}))
	contract_best = _safe_dictionary(parsed.get("contract_best", {}))
	contract_attempts = _safe_dictionary(parsed.get("contract_attempts", {}))
	unlocked_achievements.clear()
	for achievement_id in _safe_array(parsed.get("unlocked_achievements", [])):
		var achievement_clean_id := str(achievement_id)
		if not Content.achievement(achievement_clean_id).is_empty() and achievement_clean_id not in unlocked_achievements:
			unlocked_achievements.append(achievement_clean_id)
	discovered_relics.clear()
	for relic_id in _safe_array(parsed.get("discovered_relics", [])):
		var relic_clean_id := str(relic_id)
		if not Content.relic(relic_clean_id).is_empty() and relic_clean_id not in discovered_relics:
			discovered_relics.append(relic_clean_id)
	discovered_upgrades.clear()
	for upgrade_id in _safe_array(parsed.get("discovered_upgrades", [])):
		var upgrade_clean_id := str(upgrade_id)
		if not Content.upgrade(upgrade_clean_id).is_empty() and upgrade_clean_id not in discovered_upgrades:
			discovered_upgrades.append(upgrade_clean_id)
	discovered_routes.clear()
	for route_id in _safe_array(parsed.get("discovered_routes", [])):
		var route_clean_id := str(route_id)
		if not Content.route(route_clean_id).is_empty() and route_clean_id not in discovered_routes:
			discovered_routes.append(route_clean_id)
	var legacy_kills := 0
	for kill_count in codex_kills.values():
		legacy_kills += maxi(0, int(kill_count))
	lifetime_kills = maxi(legacy_kills, int(parsed.get("lifetime_kills", 0)))
	lifetime_memory_earned = maxi(meta_shards, int(parsed.get("lifetime_memory_earned", 0)))
	var legacy_wave := 12 if not completed_endings.is_empty() else 1
	highest_wave = maxi(legacy_wave, int(parsed.get("highest_wave", 1)))
	highest_level = maxi(1, int(parsed.get("highest_level", 1)))
	redline_wins = maxi(0, int(parsed.get("redline_wins", 0)))
	lifetime_directives_completed = maxi(0, int(parsed.get("lifetime_directives_completed", 0)))
	best_directives_completed = maxi(0, int(parsed.get("best_directives_completed", 0)))
	daily_records.clear()
	var saved_daily_records := _safe_dictionary(parsed.get("daily_records", {}))
	for record_id_value in saved_daily_records:
		var record_id := str(record_id_value)
		if not Content.valid_daily_id(record_id):
			continue
		var raw_record := _safe_dictionary(saved_daily_records[record_id_value])
		var recipe := Content.daily_recipe(record_id)
		var wins := maxi(0, int(raw_record.get("wins", 0)))
		daily_records[record_id] = {
			"attempts": maxi(wins, int(raw_record.get("attempts", 0))),
			"wins": wins,
			"best_score": maxi(0, int(raw_record.get("best_score", 0))),
			"best_wave": maxi(0, int(raw_record.get("best_wave", 0))),
			"seed": int(recipe["seed"]),
			"contract_id": str(recipe["contract_id"]),
			"cleared": bool(raw_record.get("cleared", wins > 0)) or wins > 0,
		}
	daily_best_streak = maxi(0, int(parsed.get("daily_best_streak", 0)))
	lifetime_daily_clears = maxi(0, int(parsed.get("lifetime_daily_clears", 0)))
	_prune_daily_records()
	_recalculate_daily_streaks()
	var retained_clears := 0
	for record in daily_records.values():
		if bool(_safe_dictionary(record).get("cleared", false)):
			retained_clears += 1
	lifetime_daily_clears = maxi(lifetime_daily_clears, retained_clears)
	recent_runs.clear()
	for run_entry in _safe_array(parsed.get("recent_runs", [])):
		var clean_run := _sanitize_recent_run(run_entry)
		if not clean_run.is_empty():
			recent_runs.append(clean_run)
		if recent_runs.size() >= 10:
			break
	custom_bindings = _safe_dictionary(parsed.get("custom_bindings", {}))
	field_manual_seen = bool(parsed.get("field_manual_seen", false))
	var saved_settings := _safe_dictionary(parsed.get("settings", {}))
	for setting_id in settings:
		if saved_settings.has(setting_id):
			settings[setting_id] = saved_settings[setting_id]
	_sanitize_settings()


func _save_payload(generation: int) -> Dictionary:
	return {
		"schema_version": SAVE_SCHEMA,
		"save_generation": generation,
		"best_score": best_score,
		"best_kills": best_kills,
		"meta_shards": meta_shards,
		"lifetime_runs": lifetime_runs,
		"meta_upgrades": meta_upgrades,
		"completed_endings": completed_endings,
		"codex_kills": codex_kills,
		"contract_wins": contract_wins,
		"contract_best": contract_best,
		"contract_attempts": contract_attempts,
		"unlocked_achievements": unlocked_achievements,
		"discovered_relics": discovered_relics,
		"discovered_upgrades": discovered_upgrades,
		"discovered_routes": discovered_routes,
		"lifetime_kills": lifetime_kills,
		"lifetime_memory_earned": lifetime_memory_earned,
		"highest_wave": highest_wave,
		"highest_level": highest_level,
		"redline_wins": redline_wins,
		"max_proof_depth": max_proof_depth,
		"preferred_proof_depth": preferred_proof_depth,
		"highest_proof_cleared": highest_proof_cleared,
		"daily_records": daily_records,
		"daily_current_streak": daily_current_streak,
		"daily_best_streak": daily_best_streak,
		"daily_last_clear_id": daily_last_clear_id,
		"lifetime_daily_clears": lifetime_daily_clears,
		"lifetime_directives_completed": lifetime_directives_completed,
		"best_directives_completed": best_directives_completed,
		"recent_runs": recent_runs,
		"field_manual_seen": field_manual_seen,
		"custom_bindings": custom_bindings,
		"settings": settings,
	}


func _save_run() -> bool:
	if save_incompatible:
		return false
	var next_generation := save_generation + 1
	var payload := _save_payload(next_generation)
	if not _write_save_text_atomic(JSON.stringify(payload, "  ")):
		return false
	save_generation = next_generation
	return true


func _write_save_text_atomic(text: String) -> bool:
	var temp := FileAccess.open(temp_save_path, FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(text)
	temp.flush()
	temp = null
	if _read_save_file(temp_save_path)["state"] != "ok":
		_remove_file_if_present(temp_save_path)
		return false
	if FileAccess.file_exists(save_path):
		_remove_file_if_present(backup_save_path)
		if _rename_save_file(save_path, backup_save_path) != OK:
			_remove_file_if_present(temp_save_path)
			return false
	if _rename_save_file(temp_save_path, save_path) != OK:
		if FileAccess.file_exists(backup_save_path):
			_rename_save_file(backup_save_path, save_path)
		_remove_file_if_present(temp_save_path)
		return false
	return true


func _restore_primary_from_payload(payload: Dictionary) -> bool:
	var temp := FileAccess.open(temp_save_path, FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(JSON.stringify(payload, "  "))
	temp.flush()
	temp = null
	if _read_save_file(temp_save_path)["state"] != "ok":
		_remove_file_if_present(temp_save_path)
		return false
	if FileAccess.file_exists(save_path):
		_quarantine_file(save_path, corrupt_save_path)
	if _rename_save_file(temp_save_path, save_path) != OK:
		_remove_file_if_present(temp_save_path)
		return false
	return true


func _quarantine_file(source_path: String, quarantine_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return true
	_remove_file_if_present(quarantine_path)
	return _rename_save_file(source_path, quarantine_path) == OK


func _remove_file_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _rename_save_file(from_path: String, to_path: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from_path), ProjectSettings.globalize_path(to_path))


func debug_set_save_namespace(profile_name: String) -> void:
	var prefix := "user://inkbound_%s" % profile_name
	save_path = prefix + ".json"
	backup_save_path = prefix + ".backup.json"
	corrupt_save_path = prefix + ".corrupt.json"
	corrupt_backup_save_path = prefix + ".backup.corrupt.json"
	temp_save_path = prefix + ".tmp.json"
	var checkpoint_prefix := prefix + "_checkpoint"
	checkpoint_path = checkpoint_prefix + ".json"
	backup_checkpoint_path = checkpoint_prefix + ".backup.json"
	corrupt_checkpoint_path = checkpoint_prefix + ".corrupt.json"
	corrupt_backup_checkpoint_path = checkpoint_prefix + ".backup.corrupt.json"
	temp_checkpoint_path = checkpoint_prefix + ".tmp.json"


func debug_clear_save_files() -> void:
	for path in [save_path, backup_save_path, corrupt_save_path, corrupt_backup_save_path, temp_save_path, checkpoint_path, backup_checkpoint_path, corrupt_checkpoint_path, corrupt_backup_checkpoint_path, temp_checkpoint_path]:
		_remove_file_if_present(path)
	checkpoint_data.clear()


func debug_set_rng_seed(value: int) -> void:
	rng.seed = value
	seed(value)
	if is_instance_valid(route_hazard):
		route_hazard.set_rng_seed(value + 1907)


func debug_set_daily_date(date_id_value: String) -> void:
	debug_daily_date_override = date_id_value if Content.valid_daily_id(date_id_value) else ""
	if is_instance_valid(hud) and hud.title_visible:
		hud.refresh_title_meta(_meta_snapshot())


func debug_set_language(language_setting: String) -> void:
	if language_setting not in Localization.LANGUAGE_CHOICES:
		return
	settings["language"] = language_setting
	test_force_english = false
	_apply_settings()
	if is_instance_valid(hud):
		hud.set_settings(settings)
		hud.refresh_localization()
	if is_instance_valid(cutscene):
		cutscene.refresh_localization()


func debug_spawn_enemy(kind: String, at: Vector2) -> InkboundEnemy:
	return spawn_enemy(kind, at)


func debug_apply_upgrade(upgrade_id: String) -> void:
	player.apply_upgrade(upgrade_id)
	_record_upgrade(upgrade_id)


func debug_play_story(sequence_name: String) -> bool:
	var story_data: Dictionary = Content.story(sequence_name)
	return cutscene.play(sequence_name, story_data) if not story_data.is_empty() else false


func debug_offer_event(event_id: String) -> bool:
	return _begin_event(Content.event(event_id))


func debug_start_directive(directive_id: String) -> bool:
	var data: Dictionary = Content.directive(directive_id)
	if data.is_empty():
		return false
	_expire_page_directive()
	active_directive = data
	directive_progress = 0.0
	directive_target = maxf(1.0, float(data.get("target", 1.0)))
	directive_completed = false
	run_directives_started += 1
	_update_directive_hud(false)
	if str(data.get("kind", "")) == "hold":
		_spawn_directive_zone()
	elif str(data.get("kind", "")) == "elites":
		_ensure_directive_elites(int(ceil(directive_target)))
	return true


func debug_spawn_squad(squad_id: String) -> int:
	return _spawn_squad_data(Content.squad(squad_id))


func debug_force_route_hazard() -> bool:
	return route_hazard.debug_force_cycle() if is_instance_valid(route_hazard) else false
