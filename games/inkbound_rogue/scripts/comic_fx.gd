extends Node2D
class_name ComicFX

const Localization = preload("res://scripts/localization.gd")

enum FxMode { SLASH, BURST, WORD, AFTERIMAGE, ART_RING, ART_LINE, ENEMY_MELEE, ENEMY_CAST }

const PAPER := Color("fff8e0")
const CRIMSON := Color("d33037")
const INK := Color("141218")

var mode := FxMode.BURST
var lifetime := 0.3
var age := 0.0
var radius := 30.0
var arc_radians := deg_to_rad(100.0)
var word := "KRAK!"
var tint := PAPER
var drift := Vector2.ZERO
var burst_angles: Array[float] = []
var line_end := Vector2.ZERO
var cast_directions: Array[Vector2] = []


func setup_slash(at: Vector2, direction: Vector2, slash_radius: float, arc_degrees: float, critical: bool = false) -> ComicFX:
	mode = FxMode.SLASH
	global_position = at
	rotation = direction.angle()
	radius = slash_radius
	arc_radians = deg_to_rad(arc_degrees)
	tint = CRIMSON if critical else PAPER
	lifetime = 0.18
	z_index = 25
	return self


func setup_burst(at: Vector2, color: Color = CRIMSON, size: float = 28.0) -> ComicFX:
	mode = FxMode.BURST
	global_position = at
	radius = size
	tint = color
	lifetime = 0.32
	z_index = 24
	for i in range(12):
		burst_angles.append((TAU * float(i) / 12.0) + sin(float(i) * 4.71) * 0.12)
	return self


func setup_word(at: Vector2, text_value: String, color: Color = PAPER) -> ComicFX:
	mode = FxMode.WORD
	global_position = at
	word = text_value
	tint = color
	drift = Vector2(0, -18)
	lifetime = 0.55
	z_index = 40
	return self


func setup_afterimage(at: Vector2) -> ComicFX:
	mode = FxMode.AFTERIMAGE
	global_position = at
	lifetime = 0.22
	tint = Color(0.83, 0.19, 0.22, 0.7)
	z_index = 8
	return self


func setup_art_ring(at: Vector2, art_radius: float, color: Color = CRIMSON) -> ComicFX:
	mode = FxMode.ART_RING
	global_position = at
	radius = art_radius
	tint = color
	lifetime = 0.46
	z_index = 28
	for index in range(16):
		burst_angles.append(TAU * float(index) / 16.0 + (0.05 if index % 2 == 0 else -0.04))
	return self


func setup_art_line(from: Vector2, to: Vector2, color: Color = CRIMSON) -> ComicFX:
	mode = FxMode.ART_LINE
	global_position = from
	line_end = to - from
	tint = color
	lifetime = 0.34
	z_index = 29
	return self


func setup_enemy_melee(at: Vector2, direction: Vector2, hit_radius: float, hit_arc_degrees: float) -> ComicFX:
	mode = FxMode.ENEMY_MELEE
	global_position = at
	rotation = direction.angle()
	radius = hit_radius
	arc_radians = deg_to_rad(hit_arc_degrees)
	tint = CRIMSON
	lifetime = 0.28
	z_index = 23
	for index in range(9):
		burst_angles.append(lerpf(-arc_radians * 0.5, arc_radians * 0.5, float(index) / 8.0))
	return self


func setup_enemy_cast(at: Vector2, directions: Array[Vector2], projectile_radius: float = 7.0) -> ComicFX:
	mode = FxMode.ENEMY_CAST
	global_position = at
	radius = projectile_radius
	tint = Color("5be1f5")
	lifetime = 0.24
	z_index = 22
	for direction in directions:
		if direction.length_squared() > 0.001:
			cast_directions.append(direction.normalized())
	return self


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	position += drift * delta
	var progress := clampf(age / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - progress
	# Enemy attack effects visualize authoritative hit geometry. They must not
	# inherit the decorative overscale used by impact bursts.
	scale = Vector2.ONE if mode in [FxMode.ENEMY_MELEE, FxMode.ENEMY_CAST] else Vector2.ONE * (1.0 + progress * 0.15)
	queue_redraw()
	if age >= lifetime:
		queue_free()


func _draw() -> void:
	match mode:
		FxMode.SLASH:
			var progress := clampf(age / lifetime, 0.0, 1.0)
			var sweep := minf(1.0, progress * 2.8)
			var arc_start := -arc_radians * 0.5
			var leading_edge := lerpf(arc_start + 0.035, arc_radians * 0.5, sweep)
			var live_span := arc_radians * lerpf(0.16, 0.68, minf(1.0, progress * 3.5))
			var trailing_edge := maxf(arc_start, leading_edge - live_span)
			var live_radius := radius * lerpf(0.58, 0.76, minf(1.0, progress * 2.4))
			var contact_pulse := sin(PI * minf(1.0, progress * 1.9))
			draw_arc(Vector2.ZERO, live_radius, trailing_edge, leading_edge, 18, INK, 7.0 + contact_pulse * 2.0, true)
			draw_arc(Vector2.ZERO, live_radius, trailing_edge, leading_edge, 18, tint, 3.2 + contact_pulse * 1.8, true)
			draw_arc(Vector2.ZERO, live_radius * 0.72, trailing_edge + 0.05, leading_edge, 14, tint.lightened(0.24), 1.0, true)
			var edge_direction := Vector2.from_angle(leading_edge)
			draw_line(edge_direction * live_radius * 0.48, edge_direction * live_radius * 1.04, PAPER, 1.5)
		FxMode.BURST:
			for angle in burst_angles:
				var inner := Vector2.from_angle(angle) * radius * 0.2
				var outer := Vector2.from_angle(angle) * radius
				draw_line(inner, outer, tint, 2.0)
			draw_circle(Vector2.ZERO, maxf(1.0, radius * (1.0 - age / lifetime) * 0.18), tint)
		FxMode.WORD:
			var font := Localization.ui_theme().default_font
			draw_string(font, Vector2(-word.length() * 4.0, 0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
			draw_string(font, Vector2(-word.length() * 4.0 + 1, -1), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)
		FxMode.AFTERIMAGE:
			draw_rect(Rect2(-7, -11, 14, 22), tint, true)
			draw_rect(Rect2(-10, -3, 20, 6), tint.darkened(0.25), true)
		FxMode.ART_RING:
			var progress := clampf(age / lifetime, 0.0, 1.0)
			var live_radius := radius * lerpf(0.2, 1.0, minf(1.0, progress * 2.6))
			draw_circle(Vector2.ZERO, live_radius, Color(tint.r, tint.g, tint.b, 0.08))
			draw_arc(Vector2.ZERO, live_radius, 0.0, TAU, 64, INK, 7.0, true)
			draw_arc(Vector2.ZERO, live_radius, 0.0, TAU, 64, tint, 3.0, true)
			draw_arc(Vector2.ZERO, live_radius * 0.72, 0.0, TAU, 48, tint.lightened(0.25), 1.0, true)
			for angle in burst_angles:
				var inner := Vector2.from_angle(angle) * live_radius * 0.72
				var outer := Vector2.from_angle(angle) * live_radius * 1.08
				draw_line(inner, outer, tint, 1.5)
		FxMode.ART_LINE:
			var normal := line_end.normalized().rotated(PI * 0.5)
			draw_line(-line_end.normalized() * 8.0, line_end + line_end.normalized() * 8.0, INK, 11.0, true)
			draw_line(Vector2.ZERO, line_end, tint, 5.0, true)
			draw_line(normal * 4.0, line_end + normal * 4.0, tint.lightened(0.32), 1.5, true)
			draw_line(-normal * 5.0, line_end - normal * 5.0, tint.darkened(0.2), 2.0, true)
		FxMode.ENEMY_MELEE:
			var progress := clampf(age / lifetime, 0.0, 1.0)
			var reveal := minf(1.0, progress * 3.4)
			var start_angle := -arc_radians * 0.5
			var end_angle := lerpf(start_angle, arc_radians * 0.5, reveal)
			var wedge := PackedVector2Array([Vector2.ZERO])
			for index in range(15):
				var angle := lerpf(start_angle, end_angle, float(index) / 14.0)
				wedge.append(Vector2.from_angle(angle) * radius)
			draw_colored_polygon(wedge, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, 0.12))
			draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 24, INK, 6.0, true)
			draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 24, CRIMSON, 2.4, true)
			draw_arc(Vector2.ZERO, radius * 0.62, start_angle, end_angle, 18, PAPER, 1.0, true)
			for index in range(burst_angles.size()):
				var angle := burst_angles[index]
				if angle > end_angle:
					continue
				var particle_direction := Vector2.from_angle(angle)
				var inner := radius * (0.28 + float(index % 3) * 0.09)
				var outer := minf(radius, inner + radius * (0.2 + progress * 0.24))
				draw_line(particle_direction * inner, particle_direction * outer, PAPER if index % 2 == 0 else CRIMSON, 1.5)
		FxMode.ENEMY_CAST:
			var progress := clampf(age / lifetime, 0.0, 1.0)
			draw_circle(Vector2.ZERO, radius + 3.0, Color(INK.r, INK.g, INK.b, 0.82))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, tint, 2.0, true)
			for direction in cast_directions:
				var normal := direction.rotated(PI * 0.5)
				var tip := direction * lerpf(9.0, 26.0, minf(1.0, progress * 2.2))
				draw_line(direction * 3.0, tip, INK, 5.0, true)
				draw_line(direction * 5.0, tip, tint, 1.8, true)
				draw_line(normal * 2.0 + direction * 7.0, tip - direction * 5.0, tint.lightened(0.18), 1.0, true)
