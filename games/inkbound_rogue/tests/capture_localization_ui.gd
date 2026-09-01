extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")

var game
var frames := 0
var output_dir := ""


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.test_force_english = false
	game.debug_set_save_namespace("capture_localization_ui")
	game.debug_clear_save_files()
	root.add_child(game)
	output_dir = ProjectSettings.globalize_path("res://build/captures")
	DirAccess.make_dir_recursive_absolute(output_dir)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		game.debug_set_language(Localization.LANGUAGE_CHINESE)
		game.hud.show_title(game._meta_snapshot())
	elif frames == 5:
		if not _capture("inkbound-zh-title.png"):
			return true
		game.hud.show_settings()
	elif frames == 8:
		if not _capture("inkbound-zh-settings.png"):
			return true
		game.hud.hide_settings()
		game.hud.hide_title()
		var upgrade_choices: Array[Dictionary] = [Content.upgrade("razor-ink"), Content.upgrade("ink-wave"), Content.upgrade("merciful-revision")]
		game.hud.show_upgrade(upgrade_choices)
	elif frames == 11:
		if not _capture("inkbound-zh-upgrades.png"):
			return true
		game.hud.upgrade_visible = false
		game.hud.upgrade_panel.visible = false
		game.debug_play_story("prologue")
		game.cutscene.advance()
	elif frames == 100:
		if not _capture("inkbound-zh-story.png"):
			return true
		game.cutscene._hide()
		paused = false
		game.hud.set_input_mode(true)
		game.hud.set_run_stats(4, 2180, true)
		game.hud.set_objective("Reach Page 4 and confront the Red Editor")
		game.hud.set_ink_art("PALIMPSEST RING", 3.6, 8.0)
		game.hud.set_boss("THE RED EDITOR", 72.0, 100.0)
		game.spawn_word(Vector2(0, -32), "RECOVERY DROP!", Color("fff8e0"))
		paused = true
	elif frames == 104:
		if not _capture("inkbound-zh-combat-hud.png"):
			return true
		print("INKBOUND_LOCALIZATION_UI_OK locale=zh_CN captures=5 title=settings=upgrades=story=combat_hud font=system-fallback")
		_cleanup(0)
		return true
	return false


func _capture(filename: String) -> bool:
	var image := root.get_texture().get_image()
	if image == null:
		push_error("INKBOUND_LOCALIZATION_UI_FAIL: viewport texture unavailable")
		_cleanup(1)
		return false
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		push_error("INKBOUND_LOCALIZATION_UI_FAIL: save_png error %d for %s" % [result, filename])
		_cleanup(1)
		return false
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	paused = false
	quit(exit_code)
