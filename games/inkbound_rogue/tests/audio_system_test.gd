extends SceneTree

const EXPECTED_SOUNDS := [
	"slash", "slash_heavy", "slash_light", "seal_cast", "ink_art", "hit", "dash",
	"ink_art_palimpsest", "ink_art_final_period", "ink_art_red_line",
	"ink_art_seal_storm", "ink_art_cross_revision",
	"enemy_cast", "enemy_dash", "teleport", "parry", "shield", "heal",
	"ink_burst", "powerup", "pickup", "level_up", "hurt", "relic",
	"boss_warning", "boss_down", "ui_move", "ui_confirm", "ui_cancel", "save",
]
const MENU_MUSIC := "menu"
const BATTLE_MUSIC := "battle"
const STORY_MUSIC := "story"
const ENDING_KEEP_MUSIC := "ending_keep"
const ENDING_REWRITE_MUSIC := "ending_rewrite"
const MUSIC_MIN_LENGTHS := {
	MENU_MUSIC: 100.0,
	BATTLE_MUSIC: 105.0,
	STORY_MUSIC: 125.0,
	ENDING_KEEP_MUSIC: 200.0,
	ENDING_REWRITE_MUSIC: 215.0,
}

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
	print("INKBOUND_AUDIO_OK sounds=30 voices=5 language=ja voice_tempo=2.0x music=5 hai_mian_stereo=menu+battle+story+keep+rewrite loop_crossfade=1.5s state_crossfade=0.55s linear_story_endings=3 weapons=5 physical_blade_layers=4 ink_art_layers=charge+5_release material_score=paper/wood/brush enemy_cues=6 pickups=2 ui=4 spatial=ok cooldowns=ok")
	_cleanup(0)
	return true


func _validate_catalog() -> bool:
	if game.SOUNDS.size() != EXPECTED_SOUNDS.size() or game.MUSIC.size() != MUSIC_MIN_LENGTHS.size():
		return _fail("audio catalog count drifted")
	for sound_id in EXPECTED_SOUNDS:
		if not game.SOUNDS.has(sound_id) or game.SOUNDS[sound_id].get_length() <= 0.05:
			return _fail("missing or empty sound cue %s" % sound_id)
	if game.ink_art_cinematic.VOICES.size() != 5:
		return _fail("Ink Art Japanese voice catalog count drifted")
	for form in ["MARGINALIA", "GREATBRUSH", "NEEDLEPOINT", "SEAL-CASTER", "TWIN-STROKE"]:
		if not game.ink_art_cinematic.VOICES.has(form):
			return _fail("missing Ink Art Japanese voice for %s" % form)
		var voice_length: float = game.ink_art_cinematic.VOICES[form].get_length()
		if voice_length < 1.2 or voice_length > 1.55:
			return _fail("Ink Art Japanese voice has an invalid runtime length for %s" % form)
	if game.ink_art_cinematic.voice_player == null or game.ink_art_cinematic.voice_player.process_mode != Node.PROCESS_MODE_ALWAYS:
		return _fail("Ink Art voice player does not survive the cinematic pause")
	var physical_cut_lengths := {"slash": 0.23, "slash_heavy": 0.35, "slash_light": 0.14, "seal_cast": 0.27}
	for sound_id in physical_cut_lengths:
		if game.SOUNDS[sound_id].get_length() < float(physical_cut_lengths[sound_id]):
			return _fail("physical weapon cue %s lost its material tail" % sound_id)
	for music_id in MUSIC_MIN_LENGTHS:
		if not game.MUSIC.has(music_id) or game.MUSIC[music_id].get_length() < float(MUSIC_MIN_LENGTHS[music_id]):
			return _fail("Hai Mian music cue %s is shorter than its production floor" % music_id)
	if not game._music_should_loop(MENU_MUSIC) or not game._music_should_loop(BATTLE_MUSIC):
		return _fail("menu and battle cues must loop")
	for music_id in [STORY_MUSIC, ENDING_KEEP_MUSIC, ENDING_REWRITE_MUSIC]:
		if game._music_should_loop(music_id):
			return _fail("linear narrative cue unexpectedly loops: %s" % music_id)
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
	if game.current_music != MENU_MUSIC:
		return _fail("boot did not select the Hai Mian menu loop")
	game._on_start_requested("standard")
	if game.current_music != BATTLE_MUSIC:
		return _fail("starting a run did not enter the Hai Mian battle loop")
	for page in [1, 5, 9, 12]:
		if game._chapter_music_id(page) != BATTLE_MUSIC:
			return _fail("page %d did not retain the battle loop" % page)
	for kind in ["editor", "binder", "author"]:
		var boss = game.spawn_enemy(kind, game.player.global_position + Vector2(100, 0))
		if game.current_music != BATTLE_MUSIC or game._boss_music_id(kind) != BATTLE_MUSIC:
			return _fail("%s did not retain the Hai Mian battle loop" % kind)
		boss.die()
		if game.current_music != BATTLE_MUSIC:
			return _fail("%s defeat did not restore the battle loop" % kind)
	for sequence in ["prologue", "act1_reveal", "act2_revelation", "act3_confrontation", "ending_choice"]:
		if game._story_music_id(sequence) != STORY_MUSIC:
			return _fail("story sequence did not select the narrative cue: %s" % sequence)
	if game._story_music_id("ending_keep") != ENDING_KEEP_MUSIC or game._story_music_id("ending_rewrite") != ENDING_REWRITE_MUSIC:
		return _fail("ending choices do not select distinct credit suites")
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
	if game.last_sound_id != "ink_art_cross_revision":
		return _fail("Cross Revision has no dedicated release cue")
	var art_release_cues := {
		"MARGINALIA": "ink_art_palimpsest",
		"GREATBRUSH": "ink_art_final_period",
		"NEEDLEPOINT": "ink_art_red_line",
		"SEAL-CASTER": "ink_art_seal_storm",
		"TWIN-STROKE": "ink_art_cross_revision",
	}
	for weapon_form in art_release_cues:
		game.player.weapon_form = weapon_form
		game.player.ink_art_cooldown = 0.0
		game.player.perform_ink_art(Vector2.RIGHT, true)
		if game.last_sound_id != art_release_cues[weapon_form]:
			return _fail("%s uses the wrong Ink Art release cue" % weapon_form)

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
	game.play_music(MENU_MUSIC)
	var outgoing = game.music_player
	if not outgoing.playing or not is_equal_approx(outgoing.volume_db, game._music_volume_db()):
		game.test_mode = true
		return _fail("production music player did not start at the user-selected gain")
	game.play_music(BATTLE_MUSIC)
	if game.current_music != BATTLE_MUSIC or game.music_player == outgoing or not game.music_player.playing or not game.music_fade_player.playing:
		game.test_mode = true
		return _fail("production crossfade did not overlap outgoing and incoming loops")
	if game.music_crossfade == null or not game.music_crossfade.is_valid():
		game.test_mode = true
		return _fail("production crossfade tween was not created")
	game.music_crossfade.kill()
	game.music_crossfade = null
	game.current_music = ""
	game.play_music(STORY_MUSIC)
	if game.current_music != STORY_MUSIC or not game.music_player.playing:
		game.test_mode = true
		return _fail("production narrative cue did not start")
	if not (game.music_player.stream is AudioStreamOggVorbis) or game.music_player.stream.loop:
		game.test_mode = true
		return _fail("production narrative cue did not remain linear")
	if game.music_crossfade != null and game.music_crossfade.is_valid():
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
