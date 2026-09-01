extends CanvasLayer
class_name InkboundCutscene

const Localization = preload("res://scripts/localization.gd")

signal finished(sequence_id: String)
signal choice_selected(sequence_id: String, choice_id: String)

const INK := Color("08070b")
const PAPER := Color("efe2c4")
const WHITE := Color("fff8e0")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")

var root_panel: Control
var art: TextureRect
var focus_frame: ColorRect
var focus_clip: Control
var focus_art: TextureRect
var shade: ColorRect
var flash: ColorRect
var transition_wipe: ColorRect
var chapter_label: Label
var title_label: Label
var speaker_label: Label
var dialogue_label: Label
var continue_label: Label
var progress_label: Label
var dialogue_panel: ColorRect
var dialogue_accent: ColorRect
var choice_panel: ColorRect
var choice_buttons: Array[Button] = []

var sequence_id := ""
var sequence: Dictionary = {}
var source_sequence: Dictionary = {}
var panels: Array = []
var panel_index := 0
var full_text := ""
var reveal_progress := 0.0
var active := false
var awaiting_choice := false
var input_enabled := true
var camera_tween: Tween
var transition_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	Localization.register_translations()
	_build()
	root_panel.theme = Localization.ui_theme()
	root_panel.visible = false


func _build() -> void:
	root_panel = Control.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_panel)

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(480, 270)
	backdrop.color = INK
	root_panel.add_child(backdrop)

	art = TextureRect.new()
	art.position = Vector2(-14, -8)
	art.size = Vector2(508, 286)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.pivot_offset = art.size * 0.5
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(art)

	shade = ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = Vector2(480, 270)
	shade.color = Color(0.02, 0.015, 0.025, 0.2)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(shade)

	# A second crop of the same illustration behaves like a manga close-up.
	# Moving it independently from the establishing shot creates real layered
	# 2D staging while keeping every generated frame useful as a full backdrop.
	focus_frame = ColorRect.new()
	focus_frame.position = Vector2(296, 58)
	focus_frame.size = Vector2(170, 108)
	focus_frame.color = CRIMSON
	focus_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_frame.visible = false
	root_panel.add_child(focus_frame)
	focus_clip = Control.new()
	focus_clip.position = Vector2(2, 2)
	focus_clip.size = Vector2(166, 104)
	focus_clip.clip_contents = true
	focus_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_frame.add_child(focus_clip)
	focus_art = TextureRect.new()
	focus_art.size = Vector2(720, 405)
	focus_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	focus_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	focus_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	focus_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_clip.add_child(focus_art)

	var top_strip := ColorRect.new()
	top_strip.position = Vector2.ZERO
	top_strip.size = Vector2(480, 48)
	top_strip.color = Color(0.015, 0.012, 0.02, 0.86)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(top_strip)

	chapter_label = _label("PROLOGUE", Vector2(14, 7), Vector2(170, 14), 9, CRIMSON)
	title_label = _label("THE BLANK PAGE", Vector2(14, 19), Vector2(390, 25), 18, WHITE)
	progress_label = _label("1 / 4", Vector2(410, 12), Vector2(56, 18), 9, PAPER)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	dialogue_panel = ColorRect.new()
	dialogue_panel.position = Vector2(12, 176)
	dialogue_panel.size = Vector2(456, 82)
	dialogue_panel.color = Color(0.02, 0.015, 0.025, 0.94)
	root_panel.add_child(dialogue_panel)
	dialogue_accent = ColorRect.new()
	dialogue_accent.position = Vector2.ZERO
	dialogue_accent.size = Vector2(4, 82)
	dialogue_accent.color = CRIMSON
	dialogue_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(dialogue_accent)

	speaker_label = _child_label(dialogue_panel, "NARA", Vector2(14, 7), Vector2(190, 14), 10, GOLD)
	dialogue_label = _child_label(dialogue_panel, "", Vector2(14, 22), Vector2(426, 43), 11, PAPER)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	continue_label = _child_label(dialogue_panel, "A/ENTER  CONTINUE", Vector2(292, 64), Vector2(150, 13), 8, Color(0.75, 0.69, 0.61, 1))
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	choice_panel = ColorRect.new()
	choice_panel.position = Vector2(42, 128)
	choice_panel.size = Vector2(396, 130)
	choice_panel.color = Color(0.018, 0.014, 0.022, 0.98)
	choice_panel.visible = false
	root_panel.add_child(choice_panel)
	var choice_title := _child_label(choice_panel, "MAKE THE FINAL MARK", Vector2(8, 7), Vector2(380, 22), 15, WHITE)
	choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(2):
		var button := Button.new()
		button.position = Vector2(12 + index * 190, 35)
		button.size = Vector2(182, 82)
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", WHITE)
		button.add_theme_color_override("font_pressed_color", GOLD)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose.bind(index))
		choice_panel.add_child(button)
		choice_buttons.append(button)

	transition_wipe = ColorRect.new()
	transition_wipe.position = Vector2.ZERO
	transition_wipe.size = Vector2(480, 270)
	transition_wipe.color = INK
	transition_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_wipe.visible = false
	root_panel.add_child(transition_wipe)

	flash = ColorRect.new()
	flash.position = Vector2.ZERO
	flash.size = Vector2(480, 270)
	flash.color = PAPER
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(flash)


func _label(text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(label)
	return label


func _child_label(parent: Control, text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func play(id: String, data: Dictionary) -> bool:
	if data.is_empty() or not data.has("panels"):
		return false
	sequence_id = id
	source_sequence = data.duplicate(true)
	sequence = Localization.localized(source_sequence)
	panels = sequence["panels"]
	panel_index = 0
	active = true
	awaiting_choice = false
	choice_panel.visible = false
	root_panel.visible = true
	chapter_label.text = sequence.get("chapter", "CHAPTER")
	title_label.text = sequence.get("title", id.to_upper())
	var texture_path: String = sequence.get("image", "")
	var scene_texture: Texture2D = load(texture_path) if not texture_path.is_empty() and ResourceLoader.exists(texture_path) else null
	art.texture = scene_texture
	focus_art.texture = scene_texture
	_show_panel()
	return true


func _show_panel() -> void:
	if panel_index < 0 or panel_index >= panels.size():
		_show_choices_or_finish()
		return
	var panel: Dictionary = panels[panel_index]
	speaker_label.text = panel.get("speaker", "NARRATOR")
	var tone_color := _tone_color(str(panel.get("tone", "paper")))
	speaker_label.add_theme_color_override("font_color", tone_color)
	dialogue_accent.color = tone_color
	full_text = panel.get("text", "")
	dialogue_label.text = full_text
	dialogue_label.visible_characters = 0
	reveal_progress = 0.0
	progress_label.text = "%d / %d" % [panel_index + 1, panels.size()]
	continue_label.text = "A/ENTER  %s" % Localization.text("REVEAL")
	_animate_panel()


func _animate_panel() -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	var panel: Dictionary = panels[panel_index]
	var focus: Vector2 = panel.get("focus", Vector2(0.5, 0.45))
	focus.x = clampf(focus.x, 0.0, 1.0)
	focus.y = clampf(focus.y, 0.0, 1.0)
	var motion := str(panel.get("motion", "push"))
	var duration := float(panel.get("duration", 6.0))
	var start_position := Vector2(-14, -8)
	var end_position := Vector2(-14, -8)
	var start_scale := 1.035
	var end_scale := 1.105
	match motion:
		"pull":
			start_position += Vector2(-7, -4)
			end_position += Vector2(3, 2)
			start_scale = 1.12
			end_scale = 1.045
		"drift_left":
			start_position += Vector2(9, -3)
			end_position += Vector2(-8, 3)
			start_scale = 1.07
			end_scale = 1.09
		"drift_right":
			start_position += Vector2(-9, 3)
			end_position += Vector2(8, -3)
			start_scale = 1.07
			end_scale = 1.09
		_:
			start_position += Vector2(5, 3)
			end_position += Vector2(-5, -3)
	art.pivot_offset = art.size * focus
	art.position = start_position
	art.scale = Vector2.ONE * start_scale
	art.modulate = Color(0.86, 0.86, 0.86, 1)
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(art, "position", end_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(art, "scale", Vector2.ONE * end_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(art, "modulate", Color.WHITE, 0.35)
	_layout_focus_inset(str(panel.get("inset", "right")), focus, _tone_color(str(panel.get("tone", "paper"))))
	if focus_frame.visible:
		var target_position := focus_frame.position
		var entrance := Vector2(-18, 0) if str(panel.get("inset", "right")) == "left" else Vector2(18, 0)
		if str(panel.get("inset", "right")) == "wide":
			entrance = Vector2(0, -10)
		focus_frame.position = target_position + entrance
		focus_frame.modulate.a = 0.0
		camera_tween.tween_property(focus_frame, "position", target_position, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		camera_tween.tween_property(focus_frame, "modulate:a", 1.0, 0.32)
		camera_tween.tween_property(focus_art, "position", focus_art.position + _focus_drift(motion), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	title_label.position.x = 19.0
	title_label.modulate.a = 0.55
	camera_tween.tween_property(title_label, "position:x", 14.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(title_label, "modulate:a", 1.0, 0.32)
	_run_panel_transition(_tone_color(str(panel.get("tone", "paper"))))
	flash.modulate.a = 0.22
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.28)


func _layout_focus_inset(mode: String, focus: Vector2, tone_color: Color) -> void:
	if mode == "none" or focus_art.texture == null:
		focus_frame.visible = false
		return
	var frame_size := Vector2(170, 108)
	var frame_position := Vector2(296, 58)
	match mode:
		"left":
			frame_position = Vector2(14, 58)
		"wide":
			frame_position = Vector2(90, 58)
			frame_size = Vector2(300, 108)
		_:
			frame_position = Vector2(296, 58)
	focus_frame.position = frame_position
	focus_frame.size = frame_size
	focus_frame.color = tone_color
	focus_frame.visible = true
	focus_clip.position = Vector2(2, 2)
	focus_clip.size = frame_size - Vector2(4, 4)
	focus_art.size = Vector2(720, 405)
	focus_art.scale = Vector2.ONE
	focus_art.modulate = Color.WHITE
	var desired := focus_clip.size * 0.5 - Vector2(focus.x * focus_art.size.x, focus.y * focus_art.size.y)
	desired.x = clampf(desired.x, focus_clip.size.x - focus_art.size.x, 0.0)
	desired.y = clampf(desired.y, focus_clip.size.y - focus_art.size.y, 0.0)
	focus_art.position = desired


func _focus_drift(motion: String) -> Vector2:
	match motion:
		"pull":
			return Vector2(5, 3)
		"drift_left":
			return Vector2(-7, 2)
		"drift_right":
			return Vector2(7, -2)
	return Vector2(-4, -3)


func _tone_color(tone: String) -> Color:
	match tone:
		"crimson":
			return CRIMSON
		"gold":
			return GOLD
		"cold":
			return Color("8fc7ff")
	return PAPER


func _run_panel_transition(tone_color: Color) -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_wipe.visible = true
	transition_wipe.position = Vector2.ZERO
	transition_wipe.color = INK.lerp(tone_color, 0.12)
	transition_wipe.modulate.a = 0.96
	transition_tween = create_tween()
	transition_tween.tween_property(transition_wipe, "position:x", 480.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	transition_tween.tween_callback(func() -> void: transition_wipe.visible = false)


func _process(delta: float) -> void:
	if not active or awaiting_choice or dialogue_label.visible_characters >= full_text.length():
		return
	reveal_progress += delta * 54.0
	dialogue_label.visible_characters = mini(full_text.length(), int(reveal_progress))
	if dialogue_label.visible_characters >= full_text.length():
		continue_label.text = "A/ENTER  %s" % Localization.text("CONTINUE")


func advance() -> void:
	if not active or awaiting_choice:
		return
	if dialogue_label.visible_characters < full_text.length():
		dialogue_label.visible_characters = full_text.length()
		reveal_progress = float(full_text.length())
		continue_label.text = "A/ENTER  %s" % Localization.text("CONTINUE")
		return
	panel_index += 1
	_show_panel()


func _show_choices_or_finish() -> void:
	var choices: Array = sequence.get("choices", [])
	if choices.is_empty():
		_finish()
		return
	awaiting_choice = true
	focus_frame.visible = false
	choice_panel.visible = true
	for index in range(mini(choices.size(), choice_buttons.size())):
		var choice: Dictionary = choices[index]
		var prefix := "X/LEFT" if index == 0 else "B/RIGHT"
		choice_buttons[index].text = "%s\n%s\n\n%s" % [prefix, choice.get("label", "CHOICE"), choice.get("description", "")]


func _choose(index: int) -> void:
	if not active or not awaiting_choice:
		return
	var choices: Array = sequence.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var completed_id := sequence_id
	_hide()
	choice_selected.emit(completed_id, choice.get("id", ""))


func _finish() -> void:
	var completed_id := sequence_id
	_hide()
	finished.emit(completed_id)


func _hide() -> void:
	active = false
	awaiting_choice = false
	root_panel.visible = false
	choice_panel.visible = false
	focus_frame.visible = false
	transition_wipe.visible = false
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not active:
		return
	if event is InputEventKey and event.echo:
		return
	if awaiting_choice:
		if event.is_action_pressed("upgrade_1") or event.is_action_pressed("move_left"):
			_choose(0)
		elif event.is_action_pressed("upgrade_3") or event.is_action_pressed("move_right"):
			_choose(1)
		return
	if event.is_action_pressed("attack") or event.is_action_pressed("dash") or event.is_action_pressed("pause"):
		advance()
	elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_ENTER, KEY_E]:
		advance()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func refresh_localization() -> void:
	root_panel.theme = Localization.ui_theme()
	if not active or source_sequence.is_empty():
		return
	var was_revealed := dialogue_label.visible_characters >= full_text.length()
	sequence = Localization.localized(source_sequence)
	panels = sequence.get("panels", [])
	chapter_label.text = sequence.get("chapter", "CHAPTER")
	title_label.text = sequence.get("title", sequence_id.to_upper())
	if awaiting_choice:
		_show_choices_or_finish()
		return
	if panel_index < 0 or panel_index >= panels.size():
		return
	var panel: Dictionary = panels[panel_index]
	speaker_label.text = panel.get("speaker", "NARRATOR")
	full_text = panel.get("text", "")
	dialogue_label.text = full_text
	dialogue_label.visible_characters = full_text.length() if was_revealed else mini(dialogue_label.visible_characters, full_text.length())
	continue_label.text = "A/ENTER  %s" % Localization.text("CONTINUE" if was_revealed else "REVEAL")


func debug_complete() -> void:
	if not active:
		return
	panel_index = panels.size()
	if sequence.get("choices", []).is_empty():
		_finish()
	else:
		_show_choices_or_finish()
