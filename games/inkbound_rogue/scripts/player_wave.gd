extends Node2D
class_name InkboundPlayerWave

const PAPER := Color("fff8e0")
const CRIMSON := Color("d33037")
const DEEP_INK := Color("08070b")

var direction := Vector2.RIGHT
var speed := 245.0
var damage := 1.0
var pierce := 0
var split_count := 0
var returning := false
var has_returned := false
var waiting_to_return := false
var age := 0.0
var split_depth := 0
var hit_ids: Dictionary = {}


func setup(at: Vector2, travel_direction: Vector2, amount: float, pierce_count: int, splits: int, does_return: bool, depth: int = 0) -> InkboundPlayerWave:
	global_position = at
	direction = travel_direction.normalized()
	damage = amount
	pierce = pierce_count
	split_count = splits
	returning = does_return
	split_depth = depth
	return self


func _ready() -> void:
	z_index = 18
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	age += delta
	global_position += direction * speed * delta
	rotation = direction.angle()
	if not waiting_to_return:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not (enemy is Node2D) or not enemy.has_method("take_damage"):
				continue
			var instance_id := enemy.get_instance_id()
			if hit_ids.has(instance_id) or global_position.distance_squared_to(enemy.global_position) > 256.0:
				continue
			hit_ids[instance_id] = true
			enemy.take_damage(damage, direction * 105.0, false)
			_split()
			if pierce <= 0:
				if returning and not has_returned:
					waiting_to_return = true
				else:
					queue_free()
					return
			else:
				pierce -= 1
	if returning and not has_returned and age >= 0.62:
		has_returned = true
		waiting_to_return = false
		direction = -direction
		hit_ids.clear()
	if age > (1.5 if returning else 1.05):
		queue_free()


func _split() -> void:
	if split_count <= 0 or split_depth >= 1:
		return
	var game := get_parent()
	if not game.has_method("spawn_player_wave"):
		return
	for angle in [-0.48, 0.48]:
		game.spawn_player_wave(global_position, direction.rotated(angle), damage * 0.55, 0, split_count - 1, false, split_depth + 1)


func _draw() -> void:
	draw_line(Vector2(-12, 0), Vector2(12, 0), DEEP_INK, 7.0)
	draw_line(Vector2(-13, 0), Vector2(13, 0), CRIMSON, 4.0)
	draw_line(Vector2(-9, -2), Vector2(10, -2), PAPER, 1.0)
