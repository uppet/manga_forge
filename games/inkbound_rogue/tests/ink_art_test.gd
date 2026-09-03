extends SceneTree

const PlayerWaveScript = preload("res://scripts/player_wave.gd")

var started := false


func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	return false


func _run() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail(null, "main scene did not load")
		return
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("ink_art_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.run_started = true
	game.spawn_timer = 999.0
	game.player.controls_enabled = false
	_clear_enemies(game)

	if not _has_keyboard_key("special", KEY_E) or not _has_gamepad_button("special", JOY_BUTTON_B):
		_fail(game, "Ink Art defaults are not mapped to E and B/Circle")
		return
	var expected_profiles := {
		"MARGINALIA": "palimpsest-ring",
		"GREATBRUSH": "final-period",
		"NEEDLEPOINT": "red-line",
		"SEAL-CASTER": "seal-storm",
		"TWIN-STROKE": "cross-revision",
	}
	for form in expected_profiles:
		game.player.weapon_form = form
		if str(game.player.ink_art_profile().get("id", "")) != expected_profiles[form]:
			_fail(game, "weapon form has the wrong Ink Art: " + form)
			return

	game.player.weapon_form = "MARGINALIA"
	game.player.global_position = Vector2.ZERO
	var ring_target = _sturdy_enemy(game, Vector2(58, 0))
	var ring_health: float = ring_target.health
	if not game.player.debug_ink_art(Vector2.RIGHT) or ring_target.health >= ring_health:
		_fail(game, "Palimpsest Ring did not damage a radial target")
		return
	if game.player.ink_art_cooldown <= 0.0 or game.player.perform_ink_art(Vector2.RIGHT):
		_fail(game, "Ink Art cooldown did not block repeated activation")
		return

	_clear_enemies(game)
	game.player.weapon_form = "GREATBRUSH"
	game.player.global_position = Vector2.ZERO
	var brush_target = _sturdy_enemy(game, Vector2(54, 0))
	var brush_health: float = brush_target.health
	game.player.debug_ink_art(Vector2.RIGHT)
	if brush_target.health >= brush_health:
		_fail(game, "Final Period did not strike its forward impact area")
		return

	_clear_enemies(game)
	game.player.weapon_form = "NEEDLEPOINT"
	game.player.global_position = Vector2.ZERO
	var line_target = _sturdy_enemy(game, Vector2(82, 0))
	var line_health: float = line_target.health
	game.player.debug_ink_art(Vector2.RIGHT)
	if game.player.global_position.x < 120.0 or line_target.health >= line_health or game.player.invulnerable_time < 0.3:
		_fail(game, "Red Line did not cut, reposition, and grant its brief safety window")
		return

	_clear_enemies(game)
	game.player.weapon_form = "SEAL-CASTER"
	game.player.global_position = Vector2.ZERO
	var waves_before := _count_player_waves(game)
	game.player.debug_ink_art(Vector2.RIGHT)
	if _count_player_waves(game) < waves_before + 12:
		_fail(game, "Seal Storm did not emit twelve radial waves")
		return

	_clear_enemies(game)
	game.player.weapon_form = "TWIN-STROKE"
	game.player.global_position = Vector2.ZERO
	var cross_target = _sturdy_enemy(game, Vector2(0, 70))
	var cross_health: float = cross_target.health
	game.player.debug_ink_art(Vector2.RIGHT)
	if cross_target.health >= cross_health:
		_fail(game, "Cross Revision did not damage its perpendicular lane")
		return

	var damage_before: float = game.player.ink_art_damage_multiplier
	var cooldown_before: float = game.player.ink_art_cooldown_max
	var radius_before: float = game.player.ink_art_radius_bonus
	game.player.apply_upgrade("living-ink")
	game.player.apply_upgrade("quickscript")
	game.player.apply_upgrade("violent-margin")
	game.player.apply_upgrade("red-harvest")
	game.player.apply_upgrade("echoed-panel")
	game.player.apply_upgrade("merciful-revision")
	if game.player.ink_art_damage_multiplier <= damage_before or game.player.ink_art_cooldown_max >= cooldown_before or game.player.ink_art_radius_bonus <= radius_before:
		_fail(game, "Ink Art stat upgrades did not change damage, recovery, and area")
		return
	if not game.player.ink_art_echo or not game.player.ink_art_heal or game.player.ink_art_hit_refund <= 0.0:
		_fail(game, "Ink Art synergy upgrades did not activate")
		return
	game.player.ink_art_cooldown = 5.0
	var recharge_before: float = game.player.ink_art_cooldown
	game.player.on_enemy_killed("mask")
	if game.player.ink_art_cooldown >= recharge_before:
		_fail(game, "Red Harvest did not refund recovery on a kill")
		return

	game.player.ink_art_cooldown = 3.25
	game.player.ink_art_uses = 7
	var state: Dictionary = game.player.get_session_state()
	game.player.ink_art_cooldown = 0.0
	game.player.ink_art_uses = 0
	game.player.ink_art_echo = false
	if not game.player.apply_session_state(state):
		_fail(game, "Ink Art checkpoint state was rejected")
		return
	if not is_equal_approx(game.player.ink_art_cooldown, 3.25) or game.player.ink_art_uses != 7 or not game.player.ink_art_echo:
		_fail(game, "Ink Art cooldown, usage, or build did not survive state restore")
		return
	if not _validate_weapon_cinematics(game):
		return

	print("INKBOUND_ART_OK forms=5 upgrades=6 input=keyboard+gamepad cooldown=ok checkpoint=ok cinematics=5 cutins=optional startup_frames=5 release=authored freeze=ok scale=bounded sound=charge+5 voice=ja+5 tempo=2.0x synchronized=0.15s")
	_cleanup(game, 0)


func _validate_weapon_cinematics(game: Node) -> bool:
	var forms := ["MARGINALIA", "GREATBRUSH", "NEEDLEPOINT", "SEAL-CASTER", "TWIN-STROKE"]
	var target_positions := {
		"MARGINALIA": Vector2(58, 0),
		"GREATBRUSH": Vector2(54, 0),
		"NEEDLEPOINT": Vector2(82, 0),
		"SEAL-CASTER": Vector2(42, 0),
		"TWIN-STROKE": Vector2(0, 70),
	}
	var release_frames := {
		"MARGINALIA": 3,
		"GREATBRUSH": 4,
		"NEEDLEPOINT": 2,
		"SEAL-CASTER": 3,
		"TWIN-STROKE": 3,
	}
	var release_sounds := {
		"MARGINALIA": "ink_art_palimpsest",
		"GREATBRUSH": "ink_art_final_period",
		"NEEDLEPOINT": "ink_art_red_line",
		"SEAL-CASTER": "ink_art_seal_storm",
		"TWIN-STROKE": "ink_art_cross_revision",
	}
	game.test_mode = false
	game.settings["ink_art_cutins"] = true
	game.player.ink_art_echo = false
	game.player.ink_art_heal = false
	for form in forms:
		_clear_enemies(game)
		game.player.weapon_form = form
		game.player.global_position = Vector2.ZERO
		game.player.ink_art_cooldown = 0.0
		var target = _sturdy_enemy(game, target_positions[form])
		var health_before: float = target.health
		var waves_before := _count_player_waves(game)
		game.last_sound_id = ""
		game.ink_art_cinematic.last_voice_form = ""
		if not game.player.debug_ink_art(Vector2.RIGHT):
			return _cinematic_fail(game, "%s cinematic cast was rejected" % form)
		if not game.ink_art_cinematic_active or not game.ink_art_cinematic.active or not paused:
			return _cinematic_fail(game, "%s did not freeze the live battlefield" % form)
		if not game.ink_art_cinematic.cutin_root.visible or game.ink_art_cinematic.phase != "cutin":
			return _cinematic_fail(game, "%s did not open its full-screen cut-in" % form)
		if game.ink_art_cinematic.last_voice_form != form or game.ink_art_cinematic.voice_player.stream != game.ink_art_cinematic.VOICES[form] or not game.ink_art_cinematic.voice_player.playing:
			return _cinematic_fail(game, "%s did not start its mapped Japanese voice" % form)
		var sequence_duration := float(game.ink_art_cinematic.FORM_DATA[form]["cutin_duration"])
		for frame_duration in game.ink_art_cinematic.FORM_DATA[form]["frame_durations"]:
			sequence_duration += float(frame_duration)
		if absf(sequence_duration - float(game.ink_art_cinematic.VOICES[form].get_length())) > 0.15:
			return _cinematic_fail(game, "%s voice and cut-in sequence length drifted apart" % form)
		if target.health < health_before or game.last_sound_id != "ink_art":
			return _cinematic_fail(game, "%s applied damage before its release frame or lost the shared charge cue" % form)
		if game.hud.input_enabled or game.cutscene.input_enabled:
			return _cinematic_fail(game, "%s left menu/story input enabled during the cinematic" % form)
		game.ink_art_cinematic.debug_advance_to_startup()
		if game.ink_art_cinematic.phase != "startup" or game.ink_art_cinematic.current_frame != 0 or not game.player.ink_art_cinematic_pose_active:
			return _cinematic_fail(game, "%s did not return to battle on startup frame zero" % form)
		if game.player.sprite.scale.x > 0.18 or 360.0 * game.player.sprite.scale.y > 65.0:
			return _cinematic_fail(game, "%s startup pose is oversized relative to the combat cast" % form)
		if target.health < health_before:
			return _cinematic_fail(game, "%s dealt damage before the authored startup release" % form)
		game.ink_art_cinematic.debug_advance_to_release()
		if not game.ink_art_cinematic.released or game.ink_art_cinematic.current_frame != int(release_frames[form]):
			return _cinematic_fail(game, "%s did not release on authored frame %d" % [form, int(release_frames[form])])
		if target.health >= health_before or game.last_sound_id != release_sounds[form]:
			return _cinematic_fail(game, "%s release did not synchronize damage and its dedicated cue" % form)
		if form == "NEEDLEPOINT" and game.player.global_position.x < 120.0:
			return _cinematic_fail(game, "Needlepoint release did not move the startup pose with Red Line")
		if form == "SEAL-CASTER" and _count_player_waves(game) < waves_before + 12:
			return _cinematic_fail(game, "Seal-Caster release did not synchronize its twelve waves")
		game.ink_art_cinematic.debug_finish_sequence()
		if game.ink_art_cinematic_active or game.ink_art_cinematic.active or paused:
			return _cinematic_fail(game, "%s did not resume the battlefield after recovery" % form)
		if game.ink_art_cinematic.last_sequence_frame_count != 5 or game.player.ink_art_cinematic_pose_active:
			return _cinematic_fail(game, "%s did not present and restore all five startup frames" % form)
		if game.ink_art_cinematic.voice_player.playing:
			return _cinematic_fail(game, "%s left its voice playing beyond the synchronized cut-in" % form)
		if not game.player.sprite.scale.is_equal_approx(game.player.visual_base_scale) or game.player.sprite.texture != game.player.idle_texture:
			return _cinematic_fail(game, "%s did not restore the normal combat sprite scale" % form)
		if not game.hud.input_enabled or not game.cutscene.input_enabled:
			return _cinematic_fail(game, "%s did not restore UI input after the cinematic" % form)

	_clear_enemies(game)
	game.settings["ink_art_cutins"] = false
	game.player.weapon_form = "MARGINALIA"
	game.player.global_position = Vector2.ZERO
	game.player.ink_art_cooldown = 0.0
	_sturdy_enemy(game, Vector2(58, 0))
	if not game.player.debug_ink_art(Vector2.RIGHT):
		return _cinematic_fail(game, "cut-in-disabled cast was rejected")
	if not game.ink_art_cinematic.active or game.ink_art_cinematic.phase != "startup" or game.ink_art_cinematic.cutin_root.visible:
		return _cinematic_fail(game, "disabling full-screen cut-ins also removed or exposed the battle startup")
	if game.ink_art_cinematic.last_voice_form != "MARGINALIA" or not game.ink_art_cinematic.voice_player.playing:
		return _cinematic_fail(game, "cut-in-disabled path did not retain the Japanese voice")
	game.ink_art_cinematic.debug_finish_sequence()
	if game.ink_art_cinematic.last_sequence_frame_count != 5 or paused:
		return _cinematic_fail(game, "cut-in-disabled path did not complete five frames and resume")
	if not game.ink_art_cinematic.voice_player.playing:
		return _cinematic_fail(game, "cut-in-disabled path cut off the Japanese voice instead of resuming combat")
	game.ink_art_cinematic.voice_player.stop()
	game.settings["ink_art_cutins"] = true
	game.test_mode = true
	return true


func _cinematic_fail(game: Node, message: String) -> bool:
	_fail(game, message)
	return false


func _sturdy_enemy(game: Node, at: Vector2) -> Node:
	var enemy = game.debug_spawn_enemy("brute", at)
	enemy.max_health = 500.0
	enemy.health = 500.0
	return enemy


func _clear_enemies(game: Node) -> void:
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()


func _count_player_waves(game: Node) -> int:
	var count := 0
	for child in game.get_children():
		if child.get_script() == PlayerWaveScript:
			count += 1
	return count


func _has_keyboard_key(action: StringName, physical_keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and int(event.physical_keycode) == physical_keycode:
			return true
	return false


func _has_gamepad_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_ART_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
