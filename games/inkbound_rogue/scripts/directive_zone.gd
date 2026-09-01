extends Node2D
class_name InkboundDirectiveZone

const Localization = preload("res://scripts/localization.gd")

signal progress_changed(current: float, target: float, occupied: bool)
signal completed

const PAPER := Color("fff8e0")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")
const DEEP_INK := Color("08070b")

var target: Node2D
var required_time := 8.0
var progress := 0.0
var radius := 48.0
var active := true
var occupied := false
var pulse := 0.0
var last_display_step := -1


func setup(at: Vector2, player_target: Node2D, duration: float, restored_progress: float = 0.0) -> InkboundDirectiveZone:
	global_position = at
	target = player_target
	required_time = maxf(1.0, duration)
	progress = clampf(restored_progress, 0.0, required_time)
	return self


func _ready() -> void:
	add_to_group("directive_zones")
	z_index = 4
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	pulse += delta
	occupied = global_position.distance_squared_to(target.global_position) <= radius * radius
	if occupied:
		progress = minf(required_time, progress + delta)
	else:
		progress = maxf(0.0, progress - delta * 0.35)
	var display_step := int(floor(progress * 10.0))
	if display_step != last_display_step:
		last_display_step = display_step
		progress_changed.emit(progress, required_time, occupied)
	queue_redraw()
	if progress >= required_time:
		active = false
		completed.emit()


func _draw() -> void:
	var live_radius := radius + sin(pulse * 4.0) * 2.0
	var fill_color := GOLD if occupied else CRIMSON
	draw_circle(Vector2.ZERO, live_radius, Color(fill_color.r, fill_color.g, fill_color.b, 0.07 if occupied else 0.035))
	draw_arc(Vector2.ZERO, live_radius, 0.0, TAU, 56, DEEP_INK, 7.0, true)
	draw_arc(Vector2.ZERO, live_radius, 0.0, TAU, 56, fill_color, 2.5, true)
	var ratio := clampf(progress / required_time, 0.0, 1.0)
	if ratio > 0.0:
		draw_arc(Vector2.ZERO, live_radius - 5.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, GOLD, 4.0, true)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var inner := Vector2.from_angle(angle) * (live_radius - 8.0)
		var outer := Vector2.from_angle(angle) * (live_radius + 5.0)
		draw_line(inner, outer, fill_color, 1.5)
	var font := Localization.ui_theme().default_font
	draw_string(font, Vector2(-18, 4), Localization.text("HOLD"), HORIZONTAL_ALIGNMENT_CENTER, 36, 9, PAPER)
