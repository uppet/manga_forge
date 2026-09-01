extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Cutscene = preload("res://scripts/cutscene.gd")

const STORY_ORDER := ["prologue", "act1_reveal", "act2_revelation", "act3_confrontation", "ending_choice", "ending_keep", "ending_rewrite"]
const MOTIONS := ["push", "pull", "drift_left", "drift_right"]
const INSETS := ["left", "right", "wide", "none"]
const TONES := ["paper", "crimson", "gold", "cold"]

var cutscene: InkboundCutscene
var frames := 0
var story_index := 0
var choice_result := ""


func _initialize() -> void:
	_install_actions()
	var background := ColorRect.new()
	background.size = Vector2(480, 270)
	background.color = Color("08070b")
	root.add_child(background)
	cutscene = Cutscene.new()
	cutscene.choice_selected.connect(func(_sequence_id: String, choice_id: String) -> void: choice_result = choice_id)
	root.add_child(cutscene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		if not _validate_story_schema():
			quit(1)
			return true
		cutscene.play(STORY_ORDER[0], Content.story(STORY_ORDER[0]))
	elif frames == 5:
		if not _validate_live_scene(STORY_ORDER[story_index]):
			quit(1)
			return true
		if story_index == 0:
			_send_action("attack")
			if cutscene.dialogue_label.visible_characters != cutscene.full_text.length():
				return _fail("gamepad-style advance did not reveal the current line")
			_send_action("attack")
			if cutscene.panel_index != 1:
				return _fail("gamepad-style advance did not move to the next panel")
		cutscene.debug_complete()
		if STORY_ORDER[story_index] == "ending_choice":
			if not cutscene.awaiting_choice:
				return _fail("ending choice did not enter its decision state")
			_send_action("upgrade_1")
			if choice_result != "keep" or cutscene.active:
				return _fail("gamepad-style ending choice did not emit KEEP and close")
		story_index += 1
		if story_index >= STORY_ORDER.size():
			print("INKBOUND_CUTSCENE_OK stories=7 unique_images=7 panels=28 shots=layered transitions=wipe keyboard_gamepad=ok ending_choice=ok")
			quit(0)
			return true
		cutscene.play(STORY_ORDER[story_index], Content.story(STORY_ORDER[story_index]))
		frames = 2
	return false


func _validate_story_schema() -> bool:
	if Content.STORY.size() != STORY_ORDER.size():
		return _schema_fail("expected seven story sequences")
	var seen_images := {}
	var panel_count := 0
	for story_id in STORY_ORDER:
		var data: Dictionary = Content.story(story_id)
		var image_path := str(data.get("image", ""))
		if image_path.is_empty() or not ResourceLoader.exists(image_path):
			return _schema_fail("%s references a missing cutscene image" % story_id)
		if seen_images.has(image_path):
			return _schema_fail("%s reuses %s from %s" % [story_id, image_path, seen_images[image_path]])
		seen_images[image_path] = story_id
		var panels: Array = data.get("panels", [])
		if panels.is_empty():
			return _schema_fail("%s has no panels" % story_id)
		for panel in panels:
			panel_count += 1
			if not panel.has("speaker") or str(panel.get("text", "")).is_empty():
				return _schema_fail("%s has incomplete dialogue" % story_id)
			var focus = panel.get("focus")
			if not (focus is Vector2) or focus.x < 0.0 or focus.x > 1.0 or focus.y < 0.0 or focus.y > 1.0:
				return _schema_fail("%s has an invalid normalized focus" % story_id)
			if str(panel.get("motion", "")) not in MOTIONS:
				return _schema_fail("%s has an invalid camera motion" % story_id)
			if str(panel.get("inset", "")) not in INSETS:
				return _schema_fail("%s has an invalid manga inset" % story_id)
			if str(panel.get("tone", "")) not in TONES:
				return _schema_fail("%s has an invalid emotional tone" % story_id)
	if seen_images.size() != STORY_ORDER.size() or panel_count != 28:
		return _schema_fail("story image or panel coverage is incomplete")
	return true


func _validate_live_scene(story_id: String) -> bool:
	if not cutscene.active or not cutscene.root_panel.visible:
		return _schema_fail("%s did not become active" % story_id)
	if cutscene.art.texture == null or cutscene.focus_art.texture == null:
		return _schema_fail("%s did not load both art layers" % story_id)
	if cutscene.art.texture != cutscene.focus_art.texture:
		return _schema_fail("%s foreground crop does not match its scene art" % story_id)
	if not cutscene.focus_frame.visible or cutscene.focus_frame.size.x < 160.0:
		return _schema_fail("%s did not render its manga focus layer" % story_id)
	if cutscene.camera_tween == null or not cutscene.camera_tween.is_valid():
		return _schema_fail("%s has no active layered camera tween" % story_id)
	if cutscene.transition_tween == null or not cutscene.transition_tween.is_valid():
		return _schema_fail("%s has no manga wipe transition" % story_id)
	if cutscene.dialogue_accent.color == Color.TRANSPARENT:
		return _schema_fail("%s did not apply its speaker tone" % story_id)
	return true


func _install_actions() -> void:
	for action in ["pause", "options", "upgrade_1", "upgrade_2", "upgrade_3", "upgrade_4", "move_up", "move_down", "move_left", "move_right", "attack", "dash", "special"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _send_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	cutscene._unhandled_input(event)


func _schema_fail(message: String) -> bool:
	push_error("INKBOUND_CUTSCENE_FAIL: %s" % message)
	return false


func _fail(message: String) -> bool:
	push_error("INKBOUND_CUTSCENE_FAIL: %s" % message)
	quit(1)
	return true
