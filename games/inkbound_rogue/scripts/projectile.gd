extends Node2D
class_name InkboundProjectile

const HOSTILE_CORE := Color("5be1f5")
const HOSTILE_EDGE := Color("355bbe")
const HOSTILE_INK := Color("08070b")

var direction := Vector2.RIGHT
var speed := 92.0
var damage := 1
var target: Node2D
var life := 0.0
var sprite: Sprite2D


func setup(at: Vector2, travel_direction: Vector2, player_target: Node2D, projectile_speed: float = 92.0) -> InkboundProjectile:
	global_position = at
	direction = travel_direction.normalized()
	target = player_target
	speed = projectile_speed
	return self


func _ready() -> void:
	add_to_group("hostile_projectiles")
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/generated/projectile.png")
	sprite.scale = Vector2(1.35, 1.35)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	z_index = 18
	queue_redraw()


func _physics_process(delta: float) -> void:
	life += delta
	position += direction * speed * delta
	rotation += delta * 5.0
	queue_redraw()
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 13.0:
		if target.has_method("take_damage"):
			target.take_damage(damage, direction)
		queue_free()
	elif life > 8.0 or absf(global_position.x) > 700.0 or absf(global_position.y) > 420.0:
		queue_free()


func _draw() -> void:
	var pulse := 0.5 + sin(life * 15.0) * 0.5
	var radius := 7.0 + pulse * 1.25
	draw_circle(Vector2.ZERO, radius + 1.5, Color(HOSTILE_INK.r, HOSTILE_INK.g, HOSTILE_INK.b, 0.62))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, Color(HOSTILE_CORE.r, HOSTILE_CORE.g, HOSTILE_CORE.b, 0.76 + pulse * 0.2), 1.25)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var outward := Vector2.from_angle(angle)
		draw_line(outward * (radius + 0.5), outward * (radius + 3.0), HOSTILE_EDGE, 1.5)
