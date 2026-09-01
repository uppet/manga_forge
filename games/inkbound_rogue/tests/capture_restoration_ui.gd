extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var game
var frames := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_restoration_ui")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		game.meta_shards = 72
		game.lifetime_memory_earned = 110
		game.meta_upgrades = {
			"vital": 5,
			"edge": 3,
			"fortune": 1,
			"stride": 2,
			"inkwell": 0,
			"thread": 0,
		}
		game.hud.show_title(game._meta_snapshot())
		game.hud._show_restoration()
		game.hud.restoration_selected = 4
		game.hud._refresh_restoration_board()
		return false
	if frames < 5:
		return false
	if not _validate_layout():
		_cleanup(1)
		return true
	var output_dir := ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("INKBOUND_RESTORATION_UI_FAIL: viewport texture unavailable")
		_cleanup(1)
		return true
	var output_path := output_dir.path_join("inkbound-restoration-board.png")
	var result := image.save_png(output_path)
	if result != OK:
		push_error("INKBOUND_RESTORATION_UI_FAIL: save_png error %d" % result)
		_cleanup(1)
		return true
	print("INKBOUND_RESTORATION_UI_OK branches=6 layout=2x3 cards=contained modal=opaque input=M/RS size=%dx%d" % [image.get_width(), image.get_height()])
	_cleanup(0)
	return true


func _validate_layout() -> bool:
	if not game.hud.restoration_visible or not game.hud.restoration_panel.visible:
		push_error("INKBOUND_RESTORATION_UI_FAIL: board is not visible")
		return false
	if not is_equal_approx(game.hud.restoration_panel.color.a, 0.998):
		push_error("INKBOUND_RESTORATION_UI_FAIL: board is not visually opaque")
		return false
	if game.hud.meta_upgrade_buttons.size() != Content.META_RESTORATIONS.size():
		push_error("INKBOUND_RESTORATION_UI_FAIL: branch count drifted")
		return false
	for index in range(game.hud.meta_upgrade_buttons.size()):
		var button: Button = game.hud.meta_upgrade_buttons[index]
		if button.text.split("\n").size() != 3:
			push_error("INKBOUND_RESTORATION_UI_FAIL: branch %d does not use three safe text rows" % index)
			return false
		if button.position.x + button.size.x > game.hud.restoration_panel.size.x - 10.0 or button.position.y + button.size.y > 212.0:
			push_error("INKBOUND_RESTORATION_UI_FAIL: branch %d leaves the card grid" % index)
			return false
		for other_index in range(index + 1, game.hud.meta_upgrade_buttons.size()):
			if button.get_rect().intersects(game.hud.meta_upgrade_buttons[other_index].get_rect()):
				push_error("INKBOUND_RESTORATION_UI_FAIL: branch cards overlap")
				return false
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
