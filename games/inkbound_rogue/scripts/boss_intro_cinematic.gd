extends CanvasLayer
class_name InkboundBossIntroCinematic

const Localization = preload("res://scripts/localization.gd")

signal sequence_finished(boss_kind: String)

const DEEP_INK := Color("08070b")
const PAPER := Color("efe2c4")
const WHITE := Color("fff8e0")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")
const DURATION := 1.72
const ENTER_DURATION := 0.22
const EXIT_DURATION := 0.24
const PORTRAITS := {
	"editor": preload("res://assets/boss_intro/editor-cutin-v1.png"),
	"binder": preload("res://assets/boss_intro/binder-cutin-v1.png"),
	"author": preload("res://assets/boss_intro/author-cutin-v1.png"),
}
const TITLES := {
	"editor": "THE RED EDITOR",
	"binder": "THE BINDER",
	"author": "THE FIRST AUTHOR",
}
const SUBTITLES := {
	"editor": "EVERY MEMORY CAN BE DELETED",
	"binder": "EVERY PAGE MUST BE BOUND",
	"author": "EVERY ENDING BELONGS TO ME",
}

var active := false
var elapsed := 0.0
var current_boss_kind := ""
var last_completed_kind := ""

var backdrop: ColorRect
var band: ColorRect
var portrait: TextureRect
var shade: ColorRect
var chapter_label: Label
var title_label: Label
var subtitle_label: Label
var top_rule: ColorRect
var bottom_rule: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 76
	_build_overlay()


func _build_overlay() -> void:
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.008, 0.015, 0.76)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.visible = false
	backdrop.theme = Localization.ui_theme()
	add_child(backdrop)

	band = ColorRect.new()
	band.position = Vector2(0, 50)
	band.size = Vector2(480, 170)
	band.color = DEEP_INK
	band.clip_contents = true
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(band)

	portrait = TextureRect.new()
	# The source art reserves its own quiet left third. Constraining it to the
	# right half keeps every boss face in frame instead of vertically cropping a
	# 3:2 portrait into the much wider 480x170 manga band.
	portrait.position = Vector2(196, 0)
	portrait.size = Vector2(284, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.pivot_offset = portrait.size * 0.5
	band.add_child(portrait)

	shade = ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = Vector2(244, band.size.y)
	shade.color = Color(0.015, 0.01, 0.02, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(shade)

	for index in range(7):
		var speed_line := ColorRect.new()
		speed_line.position = Vector2(13 + index * 27, 24 + (index % 3) * 34)
		speed_line.size = Vector2(118 - index * 7, 1 if index % 2 == 0 else 2)
		speed_line.rotation = -0.17
		speed_line.color = Color(PAPER.r, PAPER.g, PAPER.b, 0.16 + index * 0.025)
		speed_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(speed_line)

	chapter_label = _make_label("PAGE IV  ·  AUTHORITY I", Vector2(20, 18), Vector2(204, 17), 8, GOLD)
	title_label = _make_label("THE RED EDITOR", Vector2(20, 55), Vector2(216, 43), 21, WHITE)
	subtitle_label = _make_label("EVERY MEMORY CAN BE DELETED", Vector2(20, 109), Vector2(210, 35), 8, PAPER)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	band.add_child(chapter_label)
	band.add_child(title_label)
	band.add_child(subtitle_label)

	top_rule = ColorRect.new()
	top_rule.position = Vector2(0, 48)
	top_rule.size = Vector2(480, 3)
	top_rule.color = CRIMSON
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(top_rule)
	bottom_rule = ColorRect.new()
	bottom_rule.position = Vector2(0, 220)
	bottom_rule.size = Vector2(480, 2)
	bottom_rule.color = GOLD
	bottom_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(bottom_rule)


func _make_label(text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func play(boss_kind: String, page: int) -> bool:
	if active or not PORTRAITS.has(boss_kind):
		return false
	current_boss_kind = boss_kind
	elapsed = 0.0
	active = true
	portrait.texture = PORTRAITS[boss_kind]
	var chinese := TranslationServer.get_locale().begins_with("zh")
	title_label.text = Localization.text(TITLES[boss_kind])
	subtitle_label.text = Localization.text(SUBTITLES[boss_kind])
	chapter_label.text = ("第 %d 页  ·  权威 %d" if chinese else "PAGE %d  ·  AUTHORITY %d") % [page, ["editor", "binder", "author"].find(boss_kind) + 1]
	backdrop.visible = true
	_apply_frame()
	return true


func cancel() -> void:
	active = false
	elapsed = 0.0
	current_boss_kind = ""
	if is_instance_valid(backdrop):
		backdrop.visible = false


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += maxf(0.0, delta)
	_apply_frame()
	if elapsed >= DURATION:
		_finish()


func _apply_frame() -> void:
	var enter_amount := clampf(elapsed / ENTER_DURATION, 0.0, 1.0)
	var exit_amount := clampf((DURATION - elapsed) / EXIT_DURATION, 0.0, 1.0)
	var visibility := minf(_ease_out_back(enter_amount), exit_amount)
	backdrop.modulate.a = clampf(visibility, 0.0, 1.0)
	band.position.x = lerpf(34.0, 0.0, _ease_out_back(enter_amount))
	portrait.scale = Vector2.ONE * lerpf(1.075, 1.0, enter_amount)
	shade.position.x = lerpf(-52.0, 0.0, _ease_out_back(enter_amount))
	title_label.position.x = lerpf(-30.0, 20.0, _ease_out_back(enter_amount))
	subtitle_label.position.x = lerpf(-18.0, 20.0, enter_amount)


func _ease_out_back(value: float) -> float:
	var shifted := value - 1.0
	return 1.0 + shifted * shifted * (2.70158 * shifted + 1.70158)


func _finish() -> void:
	if not active:
		return
	var finished_kind := current_boss_kind
	last_completed_kind = finished_kind
	active = false
	current_boss_kind = ""
	backdrop.visible = false
	sequence_finished.emit(finished_kind)


func debug_complete() -> void:
	if active:
		elapsed = DURATION
		_apply_frame()
		_finish()


func debug_seek(time_seconds: float) -> void:
	if active:
		elapsed = clampf(time_seconds, 0.0, DURATION - 0.001)
		_apply_frame()
