extends SceneTree

const FORMS := ["MARGINALIA", "GREATBRUSH", "NEEDLEPOINT", "SEAL-CASTER", "TWIN-STROKE"]
const ComicFXScript = preload("res://scripts/comic_fx.gd")

var frames := 0
var wait_frames := 0
var form_index := 0
var capture_stage := 0
var game: Node
var failed := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_ink_art_cinematics")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3 or failed:
		return false
	if wait_frames > 0:
		wait_frames -= 1
		return false
	if form_index >= FORMS.size():
		print("INKBOUND_INK_ART_CAPTURE_OK forms=5 screenshots=15 scale=runtime")
		paused = false
		game.debug_clear_save_files()
		game.free()
		quit(0)
		return true
	match capture_stage:
		0:
			_start_form(FORMS[form_index])
			wait_frames = 4
			capture_stage = 1
		1:
			_capture("%s-cutin.png" % FORMS[form_index].to_lower())
			game.ink_art_cinematic.debug_advance_to_startup()
			game.ink_art_cinematic.release_flash.visible = false
			wait_frames = 2
			capture_stage = 2
		2:
			_capture("%s-startup.png" % FORMS[form_index].to_lower())
			game.ink_art_cinematic.debug_advance_to_release()
			game.ink_art_cinematic.release_flash.visible = false
			wait_frames = 2
			capture_stage = 3
		3:
			_capture("%s-release.png" % FORMS[form_index].to_lower())
			game.ink_art_cinematic.debug_finish_sequence()
			wait_frames = 2
			capture_stage = 4
		4:
			form_index += 1
			capture_stage = 0
	return false


func _start_form(form: String) -> void:
	paused = false
	game.test_mode = false
	game.spawn_timer = 999.0
	game.settings["ink_art_cutins"] = true
	game.settings["reduced_flashes"] = true
	game.player.global_position = Vector2.ZERO
	game.player.weapon_form = form
	game.player.ink_art_cooldown = 0.0
	game.hud.set_ink_art(str(game.player.ink_art_profile()["name"]), 0.0, game.player.ink_art_cooldown_total())
	for child in game.get_children():
		if child.get_script() == ComicFXScript:
			child.free()
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()
	for index in range(4):
		var angle := TAU * float(index) / 4.0
		var enemy = game.debug_spawn_enemy("brute" if index % 2 == 0 else "mask", Vector2.from_angle(angle) * 88.0)
		enemy.max_health = 500.0
		enemy.health = 500.0
		enemy.speed = 0.0
		enemy.contact_damage = 0.0
	if not game.player.perform_ink_art(Vector2.RIGHT, true):
		_fail("could not start %s cinematic" % form)
		return
	# The capture harness advances authored frames explicitly. Suspend its
	# PROCESS_ALWAYS clock so screenshot I/O cannot create a large delta and
	# skip a short Needlepoint pose on slower machines.
	game.ink_art_cinematic.set_process(false)
	# Hold the authored cut-in at full opacity long enough for an exact viewport
	# capture without making the runtime animation itself any slower.
	game.ink_art_cinematic.phase_elapsed = 0.12
	game.ink_art_cinematic._update_cutin(0.0)


func _capture(filename: String) -> void:
	var output_dir := ProjectSettings.globalize_path("res://build/captures/ink-art-runtime")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_fail("viewport texture unavailable")
		return
	var output_path := output_dir.path_join(filename)
	var result := image.save_png(output_path)
	if result != OK:
		_fail("save_png error %d for %s" % [result, filename])
		return
	print("INKBOUND_INK_ART_CAPTURE_FRAME file=%s size=%dx%d" % [filename, image.get_width(), image.get_height()])


func _fail(message: String) -> void:
	failed = true
	push_error("INKBOUND_INK_ART_CAPTURE_FAIL: " + message)
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(1)
