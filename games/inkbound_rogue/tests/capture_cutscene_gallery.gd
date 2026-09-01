extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Cutscene = preload("res://scripts/cutscene.gd")

const STORY_ORDER := ["prologue", "act1_reveal", "act2_revelation", "act3_confrontation", "ending_choice", "ending_keep", "ending_rewrite"]
const REPRESENTATIVE_PANELS := [1, 1, 4, 2, 1, 0, 0]

var cutscene: InkboundCutscene
var story_index := 0
var scene_frames := 0


func _initialize() -> void:
	_install_actions()
	var background := ColorRect.new()
	background.size = Vector2(480, 270)
	background.color = Color("08070b")
	root.add_child(background)
	cutscene = Cutscene.new()
	root.add_child(cutscene)


func _process(_delta: float) -> bool:
	scene_frames += 1
	if scene_frames == 2:
		var story_id: String = STORY_ORDER[story_index]
		if not cutscene.play(story_id, Content.story(story_id)):
			return _fail("could not play %s" % story_id)
		cutscene.panel_index = REPRESENTATIVE_PANELS[story_index]
		cutscene._show_panel()
		cutscene.dialogue_label.visible_characters = cutscene.full_text.length()
		cutscene.continue_label.text = "A/ENTER  CONTINUE"
	elif scene_frames == 40:
		var image := root.get_texture().get_image()
		if image == null:
			return _fail("viewport texture unavailable")
		var output_dir := ProjectSettings.globalize_path("res://build/captures")
		DirAccess.make_dir_recursive_absolute(output_dir)
		var output_path := output_dir.path_join("inkbound-cutscene-%s.png" % STORY_ORDER[story_index])
		var result := image.save_png(output_path)
		if result != OK:
			return _fail("save_png error %d for %s" % [result, STORY_ORDER[story_index]])
		story_index += 1
		if story_index >= STORY_ORDER.size():
			print("INKBOUND_CUTSCENE_GALLERY_OK captures=7 size=%dx%d" % [image.get_width(), image.get_height()])
			quit(0)
			return true
		cutscene._hide()
		scene_frames = 0
	return false


func _install_actions() -> void:
	for action in ["pause", "options", "upgrade_1", "upgrade_2", "upgrade_3", "upgrade_4", "move_up", "move_down", "move_left", "move_right", "attack", "dash", "special"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _fail(message: String) -> bool:
	push_error("INKBOUND_CUTSCENE_GALLERY_FAIL: %s" % message)
	quit(1)
	return true
