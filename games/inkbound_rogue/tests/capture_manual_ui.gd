extends SceneTree

const NAMESPACE := "capture_manual_ui"

var game
var frames := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)
	game.debug_clear_save_files()


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		game.hud.show_title(game._meta_snapshot())
		game.hud.set_input_mode(true)
		game.hud.show_manual(0)
		game.hud.debug_finish_popup_transition()
	elif frames == 12:
		if not _capture("inkbound-field-manual.png"):
			return true
		game.hud.manual_page = 4
		game.hud._refresh_manual()
	elif frames == 21:
		if not _capture("inkbound-credits-legal.png"):
			return true
		print("INKBOUND_MANUAL_CAPTURE_OK pages=2 size=%dx%d" % [root.get_texture().get_width(), root.get_texture().get_height()])
		game.debug_clear_save_files()
		quit(0)
		return true
	return false


func _capture(filename: String) -> bool:
	game.hud.debug_finish_popup_transition()
	var design_height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 270))
	var viewport_scale := maxf(1.0, float(root.get_texture().get_height()) / maxf(1.0, design_height))
	if game.hud.manual_body_label.get_content_height() > game.hud.manual_body_label.size.y * viewport_scale:
		return _fail("rendered manual copy overflows on page %d" % (game.hud.manual_page + 1))
	var image := root.get_texture().get_image()
	if image == null:
		return _fail("viewport texture unavailable")
	var output_dir := ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		return _fail("save_png error %d" % result)
	return true


func _fail(message: String) -> bool:
	push_error("INKBOUND_MANUAL_CAPTURE_FAIL: %s" % message)
	game.debug_clear_save_files()
	quit(1)
	return false
