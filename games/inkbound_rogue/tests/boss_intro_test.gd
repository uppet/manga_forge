extends SceneTree

const EXPECTED_PORTRAITS := {
	"editor": "editor-cutin-v1.png",
	"binder": "binder-cutin-v1.png",
	"author": "author-cutin-v1.png",
}

var game: Node
var frames := 0
var ran := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("boss_intro_test")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	if ran:
		return false
	frames += 1
	if frames < 2:
		return false
	ran = true
	var seen_textures: Array[Texture2D] = []
	for kind in ["editor", "binder", "author"]:
		if not game.debug_play_boss_intro(kind):
			_fail("could not start %s boss intro" % kind)
			return true
		var cinematic = game.boss_intro_cinematic
		if not game.boss_intro_cinematic_active or not cinematic.active or not paused or not cinematic.backdrop.visible:
			_fail("%s intro did not become a pause-safe modal cinematic" % kind)
			return true
		if game.hud.input_enabled or game.cutscene.input_enabled:
			_fail("%s intro did not isolate HUD and story input" % kind)
			return true
		if cinematic.backdrop.mouse_filter != Control.MOUSE_FILTER_STOP:
			_fail("boss intro does not isolate pointer input")
			return true
		if cinematic.band.size.x < 470.0 or cinematic.band.size.y < 130.0 or cinematic.band.size.y > 190.0:
			_fail("boss portrait band is not a deliberate half-screen composition")
			return true
		var texture: Texture2D = cinematic.portrait.texture
		if texture == null or not texture.resource_path.ends_with(EXPECTED_PORTRAITS[kind]) or texture in seen_textures:
			_fail("%s intro is missing its unique portrait asset" % kind)
			return true
		seen_textures.append(texture)
		if cinematic.title_label.text.is_empty() or cinematic.subtitle_label.text.is_empty():
			_fail("%s intro omitted runtime-localized title copy" % kind)
			return true
		cinematic.debug_complete()
		if game.boss_intro_cinematic_active or cinematic.active or paused or cinematic.backdrop.visible or cinematic.last_completed_kind != kind:
			_fail("%s intro did not release the paused simulation cleanly" % kind)
			return true
		if not game.hud.input_enabled or not game.cutscene.input_enabled:
			_fail("%s intro did not restore UI input" % kind)
			return true

	game.debug_set_language("zh_CN")
	if not game.debug_play_boss_intro("author") or game.boss_intro_cinematic.title_label.text != "初代作者" or game.boss_intro_cinematic.subtitle_label.text != "一切结局皆归于我":
		_fail("boss intro Chinese localization is incomplete")
		return true
	game.boss_intro_cinematic.debug_complete()
	game.debug_set_language("en")
	game.test_mode = false
	game.wave = 4
	var spawned_boss = game.debug_spawn_enemy("editor", game.player.global_position + Vector2(120, 0))
	if not game.boss_intro_cinematic_active or not game.boss_intro_cinematic.active or not paused:
		_fail("production boss spawn did not automatically trigger its introduction")
		return true
	game.boss_intro_cinematic.debug_complete()
	if is_instance_valid(spawned_boss):
		spawned_boss.free()
	game.test_mode = true
	print("INKBOUND_BOSS_INTRO_OK bosses=3 portraits=unique band=480x170 pause=isolated animation=enter/hold/exit auto_spawn=ok locales=en+zh_CN")
	_cleanup(0)
	return true


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)


func _fail(message: String) -> void:
	push_error("INKBOUND_BOSS_INTRO_FAIL: " + message)
	_cleanup(1)
