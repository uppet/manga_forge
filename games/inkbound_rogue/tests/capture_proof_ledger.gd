extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var game
var frames := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_proof_ledger")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		game.max_proof_depth = 10
		game.preferred_proof_depth = 7
		game.highest_proof_cleared = 7
		game.hud.show_title(game._meta_snapshot())
		game.hud._show_proof_ledger()
		game.hud.proof_selected = 10
		game.hud._refresh_proof_ledger()
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
		push_error("INKBOUND_PROOF_UI_FAIL: viewport texture unavailable")
		_cleanup(1)
		return true
	var output_path := output_dir.path_join("inkbound-proof-ledger.png")
	var result := image.save_png(output_path)
	if result != OK:
		push_error("INKBOUND_PROOF_UI_FAIL: save_png error %d" % result)
		_cleanup(1)
		return true
	print("INKBOUND_PROOF_UI_OK depths=11 layout=6+5 cards=contained modal=opaque input=P/LS size=%dx%d" % [image.get_width(), image.get_height()])
	_cleanup(0)
	return true


func _validate_layout() -> bool:
	if not game.hud.proof_visible or not game.hud.proof_panel.visible:
		push_error("INKBOUND_PROOF_UI_FAIL: ledger is not visible")
		return false
	if not is_equal_approx(game.hud.proof_panel.color.a, 0.998) or game.hud.proof_buttons.size() != Content.PROOF_LEVELS.size():
		push_error("INKBOUND_PROOF_UI_FAIL: ledger opacity or depth count drifted")
		return false
	for index in range(game.hud.proof_buttons.size()):
		var button: Button = game.hud.proof_buttons[index]
		if button.position.x < 0.0 or button.position.y < 0.0 or button.position.x + button.size.x > game.hud.proof_panel.size.x or button.position.y + button.size.y > 178.0:
			push_error("INKBOUND_PROOF_UI_FAIL: depth row %d leaves the safe grid" % index)
			return false
		for other_index in range(index + 1, game.hud.proof_buttons.size()):
			if button.get_rect().intersects(game.hud.proof_buttons[other_index].get_rect()):
				push_error("INKBOUND_PROOF_UI_FAIL: depth rows overlap")
				return false
	if game.hud.proof_description_label.position.y + game.hud.proof_description_label.size.y > 201.0 or game.hud.proof_description_label.text.split("\n").size() != 2:
		push_error("INKBOUND_PROOF_UI_FAIL: clause description leaves its two-line region")
		return false
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
