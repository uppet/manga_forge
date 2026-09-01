extends CanvasLayer

signal marker_requested(category: String)
signal survey_submitted(ratings: Dictionary, would_replay: bool, notes: String)
signal survey_skipped

const PAPER := Color("fff8e0")
const INK := Color("17121c")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")
const METRICS := [
	["controls", "CONTROLS / 操作响应"],
	["readability", "READABILITY / 战斗可读性"],
	["fairness", "FAIRNESS / 难度公平性"],
	["build_clarity", "BUILD CLARITY / 构筑理解"],
	["sound", "SOUND / 音效质量"],
	["music_fatigue", "MUSIC FATIGUE / 音乐疲劳"],
]

var badge: Label
var toast: Label
var survey_backdrop: ColorRect
var survey_panel: Panel
var survey_reason: Label
var rating_sliders: Dictionary = {}
var replay_check: CheckButton
var notes_edit: LineEdit
var submit_button: Button
var skip_button: Button


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_badge()
	_build_survey()


func configure(session_id: String) -> void:
	badge.text = "PLAYTEST %s  ·  F6 BUG  F7 ?  F8 !  F9 +" % session_id.right(8)


func show_marker(category: String) -> void:
	var display: String = str({
		"bug": "BUG MARKED / 已标记错误",
		"confusing": "CONFUSING MARKED / 已标记困惑",
		"unfair": "UNFAIR MARKED / 已标记不公平",
		"delight": "DELIGHT MARKED / 已标记亮点",
	}.get(category, "MOMENT MARKED"))
	toast.text = display
	toast.modulate = Color.WHITE
	toast.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(1.0)
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_callback(func() -> void: toast.visible = false)


func show_survey(reason: String) -> void:
	if survey_backdrop.visible:
		return
	survey_reason.text = "RUN COMPLETE · %s\nPlease rate this build / 请评价本次试玩" % reason.to_upper()
	for slider in rating_sliders.values():
		slider.value = 3
	replay_check.button_pressed = true
	notes_edit.text = ""
	survey_backdrop.visible = true
	get_viewport().gui_release_focus()
	if not rating_sliders.is_empty():
		var first_slider: HSlider = rating_sliders["controls"]
		first_slider.grab_focus()


func hide_survey() -> void:
	survey_backdrop.visible = false
	get_viewport().gui_release_focus()


func is_survey_visible() -> bool:
	return survey_backdrop != null and survey_backdrop.visible


func _build_badge() -> void:
	badge = Label.new()
	badge.position = Vector2(4, 3)
	badge.size = Vector2(310, 12)
	badge.add_theme_font_size_override("font_size", 7)
	badge.add_theme_color_override("font_color", Color(1, 1, 1, 0.62))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)

	toast = Label.new()
	toast.position = Vector2(100, 18)
	toast.size = Vector2(280, 20)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 10)
	toast.add_theme_color_override("font_color", GOLD)
	toast.visible = false
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast)


func _build_survey() -> void:
	survey_backdrop = ColorRect.new()
	survey_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	survey_backdrop.color = Color(0.02, 0.015, 0.025, 0.94)
	survey_backdrop.process_mode = Node.PROCESS_MODE_ALWAYS
	survey_backdrop.visible = false
	add_child(survey_backdrop)

	survey_panel = Panel.new()
	survey_panel.position = Vector2(35, 10)
	survey_panel.size = Vector2(410, 250)
	survey_backdrop.add_child(survey_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = INK
	panel_style.border_color = Color(CRIMSON, 0.82)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	survey_panel.add_theme_stylebox_override("panel", panel_style)

	var title := Label.new()
	title.position = Vector2(12, 8)
	title.size = Vector2(386, 28)
	title.text = "PLAYTEST NOTES / 试玩反馈"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", GOLD)
	survey_panel.add_child(title)

	survey_reason = Label.new()
	survey_reason.position = Vector2(12, 34)
	survey_reason.size = Vector2(386, 26)
	survey_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	survey_reason.add_theme_font_size_override("font_size", 8)
	survey_reason.add_theme_color_override("font_color", PAPER)
	survey_panel.add_child(survey_reason)

	for index in range(METRICS.size()):
		var metric: Array = METRICS[index]
		var row_y := 63.0 + float(index) * 20.0
		var label := Label.new()
		label.position = Vector2(14, row_y)
		label.size = Vector2(224, 16)
		label.text = str(metric[1])
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", PAPER)
		survey_panel.add_child(label)

		var slider := HSlider.new()
		slider.position = Vector2(242, row_y - 2)
		slider.size = Vector2(148, 18)
		slider.min_value = 1
		slider.max_value = 5
		slider.step = 1
		slider.value = 3
		slider.tick_count = 5
		slider.ticks_on_borders = true
		slider.focus_mode = Control.FOCUS_ALL
		slider.tooltip_text = "1 = low / 低，5 = high / 高"
		survey_panel.add_child(slider)
		rating_sliders[str(metric[0])] = slider

	replay_check = CheckButton.new()
	replay_check.position = Vector2(14, 184)
	replay_check.size = Vector2(186, 22)
	replay_check.text = "PLAY AGAIN? / 愿意再玩"
	replay_check.button_pressed = true
	replay_check.add_theme_font_size_override("font_size", 8)
	survey_panel.add_child(replay_check)

	notes_edit = LineEdit.new()
	notes_edit.position = Vector2(202, 184)
	notes_edit.size = Vector2(188, 22)
	notes_edit.placeholder_text = "Optional note / 可选备注"
	notes_edit.max_length = 280
	notes_edit.add_theme_font_size_override("font_size", 8)
	survey_panel.add_child(notes_edit)

	submit_button = Button.new()
	submit_button.position = Vector2(52, 214)
	submit_button.size = Vector2(145, 25)
	submit_button.text = "SUBMIT / 提交"
	submit_button.add_theme_font_size_override("font_size", 9)
	submit_button.pressed.connect(_submit_survey)
	survey_panel.add_child(submit_button)

	skip_button = Button.new()
	skip_button.position = Vector2(213, 214)
	skip_button.size = Vector2(145, 25)
	skip_button.text = "SKIP / 跳过"
	skip_button.add_theme_font_size_override("font_size", 9)
	skip_button.pressed.connect(_skip_survey)
	survey_panel.add_child(skip_button)

	_wire_focus_chain()


func _wire_focus_chain() -> void:
	var controls: Array[Control] = []
	for metric in METRICS:
		controls.append(rating_sliders[str(metric[0])])
	controls.append(replay_check)
	controls.append(notes_edit)
	controls.append(submit_button)
	controls.append(skip_button)
	for index in range(controls.size()):
		var current := controls[index]
		var previous := controls[posmod(index - 1, controls.size())]
		var next := controls[(index + 1) % controls.size()]
		current.focus_neighbor_top = previous.get_path()
		current.focus_neighbor_bottom = next.get_path()


func _submit_survey() -> void:
	var ratings: Dictionary = {}
	for metric_id in rating_sliders:
		ratings[metric_id] = int(rating_sliders[metric_id].value)
	survey_submitted.emit(ratings, replay_check.button_pressed, notes_edit.text.strip_edges())
	hide_survey()


func _skip_survey() -> void:
	survey_skipped.emit()
	hide_survey()
