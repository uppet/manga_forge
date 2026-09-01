extends Node2D
class_name InkPickup

const Localization = preload("res://scripts/localization.gd")

const TEXTURES := {
	"xp": preload("res://assets/generated/ink_orb.png"),
	"heal": preload("res://assets/generated/health.png"),
	"shard": preload("res://assets/generated/shard.png"),
	"relic": preload("res://assets/generated/relic.png"),
	"bomb": preload("res://assets/generated/bomb.png"),
	"magnet": preload("res://assets/generated/magnet.png"),
	"frenzy": preload("res://assets/generated/frenzy.png"),
	"ward": preload("res://assets/generated/ward.png"),
	"hourglass": preload("res://assets/generated/hourglass.png"),
}

var target: Node2D
var value := 1
var pickup_kind := "xp"
var age := 0.0
var sprite: Sprite2D
var callout: Label
var base_scale_value := 1.5


func setup(at: Vector2, player_target: Node2D, amount: int = 1, kind: String = "xp") -> InkPickup:
	global_position = at
	target = player_target
	value = amount
	pickup_kind = kind
	return self


func _ready() -> void:
	add_to_group("pickups")
	sprite = Sprite2D.new()
	sprite.texture = TEXTURES.get(pickup_kind, TEXTURES["xp"])
	base_scale_value = 2.15 if pickup_kind == "bomb" else (1.8 if pickup_kind in ["relic", "magnet", "frenzy", "ward", "hourglass"] else (1.72 if pickup_kind == "heal" else 1.5))
	sprite.scale = Vector2.ONE * base_scale_value
	add_child(sprite)
	if pickup_kind in ["bomb", "heal"]:
		callout = Label.new()
		callout.text = Localization.text("AOE" if pickup_kind == "bomb" else "+HP")
		callout.theme = Localization.ui_theme()
		callout.position = Vector2(-16, -25)
		callout.size = Vector2(32, 12)
		callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		callout.add_theme_font_size_override("font_size", 8)
		callout.add_theme_color_override("font_color", Color("f2b344") if pickup_kind == "bomb" else Color("fff8e0"))
		callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(callout)
	z_index = 8 if pickup_kind in ["relic", "bomb", "heal"] else 6
	queue_redraw()


func _draw() -> void:
	if pickup_kind not in ["bomb", "heal"]:
		return
	var color := Color("d33037") if pickup_kind == "bomb" else Color("fff8e0")
	var radius := 12.0 + sin(age * 5.0) * 2.0
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.13))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.82), 1.5)


func _process(delta: float) -> void:
	age += delta
	rotation = sin(age * 4.0 + get_instance_id()) * 0.12
	if pickup_kind in ["bomb", "heal"]:
		queue_redraw()
	if is_instance_valid(sprite):
		sprite.position.y = sin(age * 5.0) * 1.5
		sprite.scale = Vector2.ONE * base_scale_value * (1.0 + sin(age * 6.0) * 0.06)
	if is_instance_valid(callout):
		callout.modulate.a = 0.72 + sin(age * 6.0) * 0.22
	if not is_instance_valid(target):
		return
	var distance := global_position.distance_to(target.global_position)
	var pickup_radius_value = target.get("pickup_radius")
	var magnet_radius := float(pickup_radius_value) if pickup_radius_value != null else 100.0
	if pickup_kind == "relic":
		magnet_radius += 45.0
	if distance < magnet_radius:
		var pull := lerpf(72.0, 260.0, 1.0 - distance / magnet_radius)
		global_position = global_position.move_toward(target.global_position, pull * delta)
	if distance < 13.0:
		_collect()


func _collect() -> void:
	var game := get_parent()
	match pickup_kind:
		"heal":
			if target.has_method("heal"):
				target.heal(float(value))
			if game.has_method("spawn_word"):
				game.spawn_word(global_position + Vector2(0, -12), "MEND+", Color("efe2c4"))
			if game.has_method("play_sound"):
				game.play_sound("heal", 1.16)
		"shard":
			if game.has_method("collect_shards"):
				game.collect_shards(value)
		"relic":
			if game.has_method("offer_relic_draft"):
				game.offer_relic_draft("FIELD RELIC · CHOOSE ONE MEMORY")
			elif game.has_method("grant_random_relic"):
				game.grant_random_relic()
		"bomb", "magnet", "frenzy", "ward", "hourglass":
			if game.has_method("activate_combat_pickup"):
				game.activate_combat_pickup(pickup_kind)
		_:
			if target.has_method("gain_xp"):
				target.gain_xp(value)
			if game.has_method("on_ink_collected"):
				game.on_ink_collected(global_position)
	queue_free()
