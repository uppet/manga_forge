extends Node2D
class_name InkboundArena

const ARENA_RECT := Rect2(-640.0, -360.0, 1280.0, 720.0)
const INK := Color("141218")
const DEEP_INK := Color("08070b")
const PAPER_DIM := Color("3d3840")
const CRIMSON_DIM := Color("4e1820")
const GOLD_DIM := Color("5a4434")
const STEEL_DIM := Color("33444a")

var floor_texture: Texture2D = preload("res://assets/generated/floor.png")
var chapter := 1
var route_id := ""


func _ready() -> void:
	z_index = -100
	queue_redraw()


func _draw() -> void:
	var chapter_tint := INK if chapter == 1 else (Color("17131b") if chapter == 2 else Color("1b1015"))
	draw_rect(ARENA_RECT, chapter_tint, true)
	draw_texture_rect(floor_texture, ARENA_RECT, true)

	for x in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x) + 1, 96):
		draw_line(Vector2(x, ARENA_RECT.position.y), Vector2(x, ARENA_RECT.end.y), PAPER_DIM, 1.0)
	for y in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y) + 1, 96):
		draw_line(Vector2(ARENA_RECT.position.x, y), Vector2(ARENA_RECT.end.x, y), PAPER_DIM, 1.0)

	for x in range(int(ARENA_RECT.position.x) + 24, int(ARENA_RECT.end.x), 48):
		for y in range(int(ARENA_RECT.position.y) + 24, int(ARENA_RECT.end.y), 48):
			if posmod((x / 48) + (y / 48), 3) == 0:
				draw_circle(Vector2(x, y), 1.0, CRIMSON_DIM)

	draw_rect(ARENA_RECT, DEEP_INK, false, 8.0)
	draw_rect(ARENA_RECT.grow(-10.0), Color("efe2c4"), false, 2.0)
	draw_line(Vector2(-320, ARENA_RECT.position.y), Vector2(-210, ARENA_RECT.end.y), DEEP_INK, 5.0)
	draw_line(Vector2(310, ARENA_RECT.position.y), Vector2(220, ARENA_RECT.end.y), DEEP_INK, 5.0)
	_draw_route_motif()
	if chapter == 2:
		for radius in [90.0, 180.0, 270.0]:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color("5a4434"), 3.0)
		for angle in range(0, 360, 30):
			draw_line(Vector2.from_angle(deg_to_rad(angle)) * 70.0, Vector2.from_angle(deg_to_rad(angle)) * 340.0, Color("2b2529"), 2.0)
	elif chapter == 3:
		for x in range(int(ARENA_RECT.position.x) + 40, int(ARENA_RECT.end.x), 120):
			draw_line(Vector2(x, ARENA_RECT.position.y), Vector2(x + 180, ARENA_RECT.end.y), CRIMSON_DIM, 4.0)
		for center in [Vector2(-310, -120), Vector2(320, 140)]:
			draw_arc(center, 68.0, 0.0, TAU, 40, DEEP_INK, 7.0)
			for angle in range(0, 360, 45):
				draw_line(center + Vector2.from_angle(deg_to_rad(angle)) * 48.0, center + Vector2.from_angle(deg_to_rad(angle)) * 82.0, DEEP_INK, 12.0)


func _draw_route_motif() -> void:
	match route_id:
		"whisper-stacks":
			for center in [Vector2(-245, -95), Vector2(250, 120)]:
				for radius in [24.0, 46.0, 68.0]:
					draw_arc(center, radius, -1.0, 1.0, 18, STEEL_DIM, 2.0)
		"razor-gallery":
			for x in range(-560, 561, 140):
				draw_line(Vector2(x, -300), Vector2(x + 210, 300), CRIMSON_DIM, 5.0)
				draw_line(Vector2(x + 18, -300), Vector2(x + 228, 300), DEEP_INK, 2.0)
		"black-index":
			for x in range(-520, 521, 180):
				for y in range(-260, 261, 160):
					draw_rect(Rect2(x, y, 92, 48), DEEP_INK, false, 4.0)
					draw_line(Vector2(x + 12, y + 15), Vector2(x + 76, y + 15), CRIMSON_DIM, 3.0)
		"chain-vault":
			for x in range(-510, 511, 170):
				draw_arc(Vector2(x, 0), 42.0, 0.0, TAU, 20, GOLD_DIM, 5.0)
				draw_line(Vector2(x + 42, 0), Vector2(x + 128, 0), GOLD_DIM, 5.0)
		"errata-canals":
			for y in [-210.0, 0.0, 210.0]:
				for x in range(-600, 561, 40):
					var y0: float = float(y) + sin(float(x) * 0.025) * 18.0
					var y1: float = float(y) + sin(float(x + 40) * 0.025) * 18.0
					draw_line(Vector2(x, y0), Vector2(x + 40, y1), STEEL_DIM, 5.0)
		"contraband-hall":
			for center in [Vector2(-420, -180), Vector2(-140, 190), Vector2(150, -170), Vector2(430, 160)]:
				draw_line(center + Vector2(0, -70), center, GOLD_DIM, 2.0)
				draw_circle(center, 22.0, CRIMSON_DIM)
				draw_circle(center, 12.0, GOLD_DIM)
		"white-room":
			for x in range(-540, 541, 180):
				draw_rect(Rect2(x, -260, 108, 520), Color("6c6662"), false, 3.0)
				draw_rect(Rect2(x + 10, -250, 88, 500), STEEL_DIM, false, 1.0)
		"red-press":
			for center in [Vector2(-360, 0), Vector2.ZERO, Vector2(360, 0)]:
				draw_arc(center, 76.0, 0.0, TAU, 32, CRIMSON_DIM, 10.0)
				draw_arc(center, 42.0, 0.0, TAU, 24, DEEP_INK, 8.0)
		"loose-leaves":
			for x in range(-540, 541, 120):
				var offset := float(posmod(x, 5) * 12)
				draw_line(Vector2(x, -260 + offset), Vector2(x + 82, -170 + offset), PAPER_DIM, 3.0)
				draw_line(Vector2(x + 82, -170 + offset), Vector2(x + 24, -80 + offset), CRIMSON_DIM, 2.0)


func clamp_point(point: Vector2, margin: float = 20.0) -> Vector2:
	return Vector2(
		clampf(point.x, ARENA_RECT.position.x + margin, ARENA_RECT.end.x - margin),
		clampf(point.y, ARENA_RECT.position.y + margin, ARENA_RECT.end.y - margin)
	)


func set_chapter(value: int) -> void:
	chapter = clampi(value, 1, 3)
	queue_redraw()


func set_route(value: String) -> void:
	route_id = value
	queue_redraw()
