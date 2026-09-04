extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var game
var frames := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_daily_chronicle")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		var date_id := "2031-05-17"
		var recipe := Content.daily_recipe(date_id)
		game.debug_set_daily_date(date_id)
		game.daily_records[date_id] = {
			"attempts": 3,
			"wins": 1,
			"best_score": 48210,
			"best_wave": 12,
			"seed": recipe["seed"],
			"contract_id": recipe["contract_id"],
			"cleared": true,
		}
		game.lifetime_daily_clears = 4
		game.daily_current_streak = 3
		game.daily_best_streak = 5
		game.hud.set_input_mode(true)
		game.hud.show_title(game._meta_snapshot())
		game.hud._show_daily()
		game.hud.debug_finish_popup_transition()
		return false
	if frames < 5:
		return false
	game.hud.debug_finish_popup_transition()
	if not _validate_layout():
		_cleanup(1)
		return true
	var output_dir := ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("INKBOUND_DAILY_UI_FAIL: viewport texture unavailable")
		_cleanup(1)
		return true
	var output_path := output_dir.path_join("last-inkwarden-daily-chronicle.png")
	var result := image.save_png(output_path)
	if result != OK:
		push_error("INKBOUND_DAILY_UI_FAIL: save_png error %d" % result)
		_cleanup(1)
		return true
	print("INKBOUND_DAILY_UI_OK modal=opaque copy=contained input=T/down confirm=A/enter title_buttons=split size=%dx%d" % [image.get_width(), image.get_height()])
	_cleanup(0)
	return true


func _validate_layout() -> bool:
	var hud = game.hud
	if not hud.daily_visible or not hud.daily_panel.visible or not is_equal_approx(hud.daily_panel.color.a, 0.998):
		push_error("INKBOUND_DAILY_UI_FAIL: Daily Chronicle is not an opaque visible modal")
		return false
	if hud.daily_button.get_rect().intersects(hud.restoration_open_button.get_rect()):
		push_error("INKBOUND_DAILY_UI_FAIL: Daily and Restoration title buttons overlap")
		return false
	for control in [hud.daily_title_label, hud.daily_contract_label, hud.daily_rules_label, hud.daily_record_label, hud.daily_start_button]:
		if control.position.x < 0.0 or control.position.y < 0.0 or control.position.x + control.size.x > hud.daily_panel.size.x or control.position.y + control.size.y > hud.daily_panel.size.y:
			push_error("INKBOUND_DAILY_UI_FAIL: Daily copy leaves the modal")
			return false
	if hud.daily_title_label.position.y + hud.daily_title_label.size.y > hud.daily_contract_label.position.y:
		push_error("INKBOUND_DAILY_UI_FAIL: title overlaps the contract heading")
		return false
	if hud.daily_contract_label.position.y + hud.daily_contract_label.size.y > hud.daily_rules_label.position.y:
		push_error("INKBOUND_DAILY_UI_FAIL: contract heading overlaps rules")
		return false
	if hud.daily_rules_label.position.y + hud.daily_rules_label.size.y > hud.daily_record_label.position.y:
		push_error("INKBOUND_DAILY_UI_FAIL: rules overlap the record row")
		return false
	if hud.daily_record_label.position.y + hud.daily_record_label.size.y > hud.daily_start_button.position.y:
		push_error("INKBOUND_DAILY_UI_FAIL: record row overlaps the start button")
		return false
	if hud.daily_rules_label.text.find("RESTORATIONS SEALED") < 0 or hud.daily_contract_label.text.find("SEED") < 0 or hud.daily_start_button.text.find("A/") < 0:
		push_error("INKBOUND_DAILY_UI_FAIL: required rules, seed, or controller prompt is missing")
		return false
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
