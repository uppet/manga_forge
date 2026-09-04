extends SceneTree

const Localization = preload("res://scripts/localization.gd")
const NAMESPACE := "capture_credits_ui"

var game
var frames := 0
var locale_index := 0
var page_index := 0
var page_ready := false
var capture_count := 0
var initialized := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.test_force_english = false
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if not initialized:
		if game.hud == null:
			return false
		initialized = true
		game.debug_clear_save_files()
		game.hud.hide_title()
		_prepare_locale(Localization.LANGUAGE_ENGLISH)
		return false
	if frames < 3:
		return false
	if page_index >= game.hud.victory_credit_pages.size():
		if locale_index == 0:
			locale_index = 1
			_prepare_locale(Localization.LANGUAGE_CHINESE)
			return false
		print("INKBOUND_CREDITS_CAPTURE_OK locales=2 pages=%d size=%dx%d" % [capture_count, root.get_texture().get_width(), root.get_texture().get_height()])
		game.debug_clear_save_files()
		paused = false
		quit(0)
		return true
	if not page_ready:
		game.hud.victory_credit_page = page_index
		game.hud._show_victory_credit_page()
		page_ready = true
		return false
	if not _capture_page():
		return true
	page_index += 1
	page_ready = false
	return false


func _prepare_locale(locale: String) -> void:
	game.debug_set_language(locale)
	game.hud.show_victory({
		"won": true,
		"ending": "keep",
		"wave": 12,
		"level": 18,
		"score": 42860,
		"kills": 186,
		"best_score": 42860,
		"memory_earned": 24,
		"archive_rank": 5,
		"duration_seconds": 1187,
		"difficulty": "standard",
		"contract_name": "OPEN DRAFT",
		"weapon_form": "GREATBRUSH",
		"relic_count": 3,
		"directives_completed": 7,
		"directives_offered": 9,
	})
	game.hud.debug_finish_popup_transition(game.hud.victory_credits_panel)
	page_index = 0
	page_ready = false
	paused = true


func _capture_page() -> bool:
	if game.hud.victory_credit_tween != null and game.hud.victory_credit_tween.is_valid():
		game.hud.victory_credit_tween.kill()
	var image := root.get_texture().get_image()
	if image == null:
		return _fail("viewport texture unavailable")
	var output_dir := ProjectSettings.globalize_path("res://build/captures/credits")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var locale_tag := "zh-cn" if locale_index == 1 else "en"
	var filename := "last-inkwarden-credits-%s-%02d.png" % [locale_tag, page_index + 1]
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		return _fail("save_png error %d on page %d" % [result, page_index + 1])
	capture_count += 1
	return true


func _fail(message: String) -> bool:
	push_error("INKBOUND_CREDITS_CAPTURE_FAIL: %s" % message)
	game.debug_clear_save_files()
	paused = false
	quit(1)
	return false
