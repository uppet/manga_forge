extends SceneTree

var game: Node
var frames := 0
var capture_index := 0
var capture_pending := false
const BOSSES := ["editor", "binder", "author"]


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_boss_intro")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if capture_index >= BOSSES.size():
		print("INKBOUND_BOSS_INTRO_CAPTURE_OK bosses=3 size=%dx%d" % [root.get_texture().get_width(), root.get_texture().get_height()])
		_cleanup(0)
		return true
	if not capture_pending:
		var kind: String = BOSSES[capture_index]
		if not game.debug_play_boss_intro(kind):
			_fail("could not stage %s" % kind)
			return true
		game.boss_intro_cinematic.debug_seek(0.2)
		capture_pending = true
		return false
	var output_dir := ProjectSettings.globalize_path("res://build/captures/boss-intros")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_fail("viewport texture unavailable")
		return true
	var output_path := output_dir.path_join("last-inkwarden-boss-intro-%s.png" % BOSSES[capture_index])
	var result := image.save_png(output_path)
	if result != OK:
		_fail("save_png error %d" % result)
		return true
	game.boss_intro_cinematic.debug_complete()
	capture_index += 1
	capture_pending = false
	return false


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)


func _fail(message: String) -> void:
	push_error("INKBOUND_BOSS_INTRO_CAPTURE_FAIL: " + message)
	_cleanup(1)
