extends SceneTree

const EXPECTED_SOUNDS := [
	"slash", "slash_heavy", "slash_light", "seal_cast", "ink_art", "hit", "dash",
	"enemy_cast", "enemy_dash", "teleport", "parry", "shield", "heal",
	"ink_burst", "powerup", "pickup", "level_up", "hurt", "relic",
	"boss_warning", "boss_down", "ui_move", "ui_confirm", "ui_cancel", "save",
]
const ACT_MUSIC := ["archive", "bindery", "finale"]
const BOSS_MUSIC := ["boss_editor", "boss_binder", "boss_author"]

var game
var frames := 0
var validated := false
var audio_released_at_msec := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("audio_system_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(170017)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if frames == 3:
		if not _validate_catalog() or not _validate_adaptive_music() or not _validate_combat_cues() or not _validate_ui_cues() or not _validate_runtime_crossfade():
			return true
		validated = true
		return false
	if not validated or frames < 6 or Time.get_ticks_msec() - audio_released_at_msec < 250:
		return false
	print("INKBOUND_AUDIO_OK sounds=25 music=6 act_loops=3x32s boss_themes=3x24s crossfade=0.55s weapons=5 physical_blade_layers=4 material_score=paper/wood/brush enemy_cues=6 pickups=2 ui=4 spatial=ok cooldowns=ok")
	_cleanup(0)
	return true


func _validate_catalog() -> bool:
	if game.SOUNDS.size() != EXPECTED_SOUNDS.size() or game.MUSIC.size() != ACT_MUSIC.size() + BOSS_MUSIC.size():
		return _fail("audio catalog count drifted")
	for sound_id in EXPECTED_SOUNDS:
		if not game.SOUNDS.has(sound_id) or game.SOUNDS[sound_id].get_length() <= 0.05:
			return _fail("missing or empty sound cue %s" % sound_id)
	var physical_cut_lengths := {"slash": 0.23, "slash_heavy": 0.35, "slash_light": 0.14, "seal_cast": 0.27}
	for sound_id in physical_cut_lengths:
		if game.SOUNDS[sound_id].get_length() < float(physical_cut_lengths[sound_id]):
			return _fail("physical weapon cue %s lost its material tail" % sound_id)
	for music_id in ACT_MUSIC:
		if not game.MUSIC.has(music_id) or game.MUSIC[music_id].get_length() < 31.9:
			return _fail("act loop %s is shorter than thirty-two seconds" % music_id)
	for music_id in BOSS_MUSIC:
		if not game.MUSIC.has(music_id) or game.MUSIC[music_id].get_length() < 23.9:
			return _fail("boss theme %s is shorter than twenty-four seconds" % music_id)
	if game.music_player == null or game.music_fade_player == null or game.music_player.process_mode != Node.PROCESS_MODE_ALWAYS or game.music_fade_player.process_mode != Node.PROCESS_MODE_ALWAYS:
		return _fail("crossfade players do not survive modal pause")
	var expected_music_gain := linear_to_db(float(game.settings.get("music", 0.65)))
	if not is_equal_approx(game._music_volume_db(), expected_music_gain) or game._music_volume_db() < -5.0:
		return _fail("background music is still hidden behind a second attenuation cap")
	for limited_id in ["enemy_cast", "enemy_dash", "teleport", "parry", "shield", "heal", "ui_move"]:
		if int(game.SOUND_COOLDOWNS_MSEC.get(limited_id, 0)) <= 0:
			return _fail("spam limiter missing for %s" % limited_id)
	return true


func _validate_adaptive_music() -> bool:
	if game.current_music != "archive":
		return _fail("boot did not select the Archive loop")
	for entry in [
		{"kind": "editor", "wave": 4, "boss": "boss_editor", "after": "archive"},
		{"kind": "binder", "wave": 8, "boss": "boss_binder", "after": "bindery"},
		{"kind": "author", "wave": 12, "boss": "boss_author", "after": "finale"},
	]:
		game.wave = int(entry["wave"])
		var boss = game.spawn_enemy(str(entry["kind"]), game.player.global_position + Vector2(100, 0))
		if game.current_music != str(entry["boss"]):
			return _fail("%s did not enter its dedicated music layer" % entry["kind"])
		boss.die()
		if game.current_music != str(entry["after"]):
			return _fail("%s defeat did not restore its act loop" % entry["kind"])
	return true


func _validate_combat_cues() -> bool:
	var weapon_cues := {
		"MARGINALIA": "slash",
		"GREATBRUSH": "slash_heavy",
		"NEEDLEPOINT": "slash_light",
		"SEAL-CASTER": "seal_cast",
		"TWIN-STROKE": "slash",
	}
	for weapon_form in weapon_cues:
		game.player.weapon_form = weapon_form
		game.player.perform_attack(Vector2.RIGHT, true)
		if game.last_sound_id != weapon_cues[weapon_form]:
			return _fail("%s uses the wrong attack timbre" % weapon_form)
	game.player.ink_art_cooldown = 0.0
	game.player.perform_ink_art(Vector2.RIGHT, true)
	if game.last_sound_id != "ink_art":
		return _fail("Ink Art has no dedicated release cue")

	var scribe = game.spawn_enemy("scribe", game.player.global_position + Vector2(90, 0))
	scribe.shoot_projectiles(Vector2.LEFT)
	if game.last_sound_id != "enemy_cast":
		return _fail("projectile telegraph has no spatial cast cue")
	var dasher = game.spawn_enemy("dasher", game.player.global_position + Vector2(80, 0))
	dasher.dash_timer = 0.0
	dasher.dash_charge = 0.0
	dasher._dasher_movement(Vector2.LEFT, 80.0)
	if game.last_sound_id != "enemy_dash":
		return _fail("dash telegraph cue is missing")
	var errata = game.spawn_enemy("errata", game.player.global_position + Vector2(70, 0))
	errata.teleport_timer = -0.1
	errata._errata_movement(Vector2.LEFT, 50.0)
	if game.last_sound_id != "teleport":
		return _fail("teleport cue is missing")
	var archivist = game.spawn_enemy("archivist", game.player.global_position + Vector2(60, 0))
	archivist._support_pulse()
	if game.last_sound_id != "heal":
		return _fail("enemy restoration cue is missing")
	var duelist = game.spawn_enemy("duelist", game.player.global_position + Vector2(50, 0))
	duelist.parry_window = 0.4
	duelist._try_defend(1.0, Vector2.RIGHT)
	if game.last_sound_id != "parry":
		return _fail("parry cue is missing")
	var censor = game.spawn_enemy("censor", game.player.global_position + Vector2(40, 0))
	censor._try_defend(1.0, Vector2.RIGHT)
	if game.last_sound_id != "shield":
		return _fail("shield cue is missing")
	game.activate_combat_pickup("bomb")
	if game.last_sound_id != "ink_burst":
		return _fail("Ink Bomb has no dedicated burst cue")
	game.activate_combat_pickup("ward")
	if game.last_sound_id != "powerup":
		return _fail("combat supplies have no dedicated powerup cue")
	return true


func _validate_ui_cues() -> bool:
	for sound_id in ["ui_move", "ui_confirm", "ui_cancel", "save"]:
		game.last_sound_id = ""
		game.hud.ui_sound_requested.emit(sound_id)
		if game.last_sound_id != sound_id:
			return _fail("HUD cue %s is not connected to the audio system" % sound_id)
	return true


func _validate_runtime_crossfade() -> bool:
	game.test_mode = false
	game.current_music = ""
	game.play_music("archive")
	var outgoing = game.music_player
	if not outgoing.playing or not is_equal_approx(outgoing.volume_db, game._music_volume_db()):
		game.test_mode = true
		return _fail("production music player did not start at the user-selected gain")
	game.play_music("boss_editor")
	if game.current_music != "boss_editor" or game.music_player == outgoing or not game.music_player.playing or not game.music_fade_player.playing:
		game.test_mode = true
		return _fail("production crossfade did not overlap outgoing and incoming loops")
	if game.music_crossfade == null or not game.music_crossfade.is_valid():
		game.test_mode = true
		return _fail("production crossfade tween was not created")
	game.music_crossfade.kill()
	game.music_crossfade = null
	game.music_player.stop()
	game.music_fade_player.stop()
	game.music_player.stream = null
	game.music_fade_player.stream = null
	game.music_player.free()
	game.music_fade_player.free()
	game.music_player = null
	game.music_fade_player = null
	game.test_mode = true
	audio_released_at_msec = Time.get_ticks_msec()
	return true


func _fail(message: String) -> bool:
	push_error("INKBOUND_AUDIO_FAIL: %s" % message)
	_cleanup(1)
	return false


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
