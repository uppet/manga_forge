extends CharacterBody2D
class_name InkboundEnemy

const CombatCast = preload("res://scripts/combat_cast.gd")

signal died(enemy: Node, xp_value: int, death_position: Vector2, enemy_kind: String)

const PAPER := Color("efe2c4")
const CRIMSON := Color("d33037")
const DARK_RED := Color("701820")
const DEEP_INK := Color("08070b")
const GOLD := Color("f2b344")
const STEEL := Color("96aab0")
const BOSS_KINDS := ["editor", "binder", "author"]

var enemy_kind := "mask"
var target: Node2D
var max_health := 4.0
var health := 4.0
var speed := 45.0
var contact_damage := 1.0
var xp_value := 1
var contact_cooldown := 0.0
var external_velocity := Vector2.ZERO
var shoot_timer := 2.2
var dash_timer := 0.0
var dash_charge := 0.0
var summon_timer := 5.0
var pattern_phase := 0.0
var dead := false
var is_elite := false
var elite_affix := ""
var sprite: Sprite2D
var ground_shadow_points := PackedVector2Array()
var ground_shadow_scale := Vector2.ONE
var visual_base_scale := Vector2.ONE
var visual_y_offset := -4.0

var bleed_damage := 0.0
var bleed_time := 0.0
var burn_damage := 0.0
var burn_time := 0.0
var slow_amount := 0.0
var slow_time := 0.0
var status_tick := 0.35
var support_timer := 3.0
var teleport_timer := 3.2
var teleport_charge := 0.0
var teleport_pending := false
var teleport_rush := 0.0
var parry_cycle := 2.4
var parry_window := 0.0
var counter_rush := 0.0
var shield_hits := 3
var shield_broken_time := 0.0
var haste_time := 0.0
var facing_direction := Vector2.RIGHT
var source_wave := 1


func configure(kind_value: String, player_target: Node2D, wave: int) -> InkboundEnemy:
	enemy_kind = kind_value
	target = player_target
	source_wave = maxi(1, wave)
	var scale_factor := 1.0 + maxf(0.0, float(wave - 1)) * (0.08 if enemy_kind in BOSS_KINDS else 0.11)
	match enemy_kind:
		"dasher":
			max_health = 3.0 * scale_factor
			speed = 58.0 + wave * 1.8
			xp_value = 2
		"brute":
			max_health = 10.0 * scale_factor
			speed = 27.0 + wave
			contact_damage = 2.0
			xp_value = 4
		"scribe":
			max_health = 4.0 * scale_factor
			speed = 38.0 + wave
			shoot_timer = randf_range(1.0, 1.6) if source_wave <= 3 else randf_range(0.6, 1.3)
			xp_value = 2
		"splitter":
			max_health = 7.0 * scale_factor
			speed = 36.0 + wave
			xp_value = 3
		"leech":
			max_health = 5.0 * scale_factor
			speed = 64.0 + wave * 1.5
			contact_damage = 0.75
			xp_value = 3
		"warden":
			max_health = 15.0 * scale_factor
			speed = 22.0 + wave * 0.7
			contact_damage = 2.0
			shoot_timer = 1.0
			xp_value = 6
		"censor":
			max_health = 9.0 * scale_factor
			speed = 34.0 + wave
			contact_damage = 1.5
			xp_value = 4
		"errata":
			max_health = 5.0 * scale_factor
			speed = 52.0 + wave * 1.2
			contact_damage = 1.25
			teleport_timer = randf_range(1.6, 3.0)
			xp_value = 4
		"archivist":
			max_health = 8.0 * scale_factor
			speed = 31.0 + wave * 0.7
			support_timer = randf_range(1.5, 2.8)
			xp_value = 5
		"blot":
			max_health = 11.0 * scale_factor
			speed = 0.0
			contact_damage = 1.5
			shoot_timer = randf_range(1.4, 2.1) if source_wave <= 3 else randf_range(0.8, 1.5)
			xp_value = 4
		"duelist":
			max_health = 8.0 * scale_factor
			speed = 61.0 + wave
			contact_damage = 1.5
			parry_cycle = randf_range(1.2, 2.4)
			xp_value = 5
		"editor":
			max_health = 42.0 * scale_factor
			speed = 33.0 + wave * 0.65
			contact_damage = 2.0
			shoot_timer = 1.0
			xp_value = 16
		"binder":
			max_health = 68.0 * scale_factor
			speed = 27.0 + wave * 0.5
			contact_damage = 2.0
			shoot_timer = 0.8
			summon_timer = 3.5
			xp_value = 24
		"author":
			# The final encounter must survive complete twelve-upgrade builds long
			# enough for its dash, radial edit, and summon patterns to matter.
			max_health = 150.0 * scale_factor
			speed = 30.0 + wave * 0.45
			contact_damage = 2.5
			shoot_timer = 0.65
			dash_timer = 2.7
			xp_value = 40
		_:
			max_health = 4.0 * scale_factor
			speed = 42.0 + wave * 1.4
			xp_value = 1
	if wave >= 3 and enemy_kind not in BOSS_KINDS and randf() < minf(0.24, 0.08 + wave * 0.009):
		_make_elite()
	health = max_health
	return self


func _make_elite() -> void:
	is_elite = true
	elite_affix = ["swift", "ironbound", "volatile", "vampiric"].pick_random()
	xp_value *= 2
	match elite_affix:
		"swift":
			speed *= 1.38
			contact_cooldown = 0.2
		"ironbound":
			max_health *= 1.85
		"volatile":
			contact_damage *= 1.35
		"vampiric":
			max_health *= 1.28


func promote_to_elite() -> bool:
	if is_elite or enemy_kind in BOSS_KINDS:
		return false
	_make_elite()
	health = max_health
	if is_instance_valid(sprite):
		sprite.modulate = _elite_color()
	queue_redraw()
	return true


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	ground_shadow_points = CombatCast.ellipse_points(CombatCast.shadow_radii(enemy_kind))

	sprite = Sprite2D.new()
	sprite.texture = CombatCast.texture_for(enemy_kind)
	visual_base_scale = CombatCast.scale_for(enemy_kind)
	visual_y_offset = -7.0 if enemy_kind in BOSS_KINDS else -4.0
	sprite.scale = visual_base_scale
	sprite.position.y = visual_y_offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	if is_elite:
		sprite.modulate = _elite_color()

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	if enemy_kind in BOSS_KINDS:
		shape.radius = 16.0 if enemy_kind != "author" else 19.0
	elif enemy_kind in ["brute", "warden", "censor", "blot"]:
		shape.radius = 11.0
	else:
		shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	z_index = 11 if enemy_kind in BOSS_KINDS else 9
	queue_redraw()


func _elite_color() -> Color:
	match elite_affix:
		"swift":
			return Color(1.0, 0.52, 0.52, 1.0)
		"ironbound":
			return Color(0.62, 0.76, 0.82, 1.0)
		"volatile":
			return Color(1.0, 0.72, 0.25, 1.0)
		"vampiric":
			return Color(0.72, 0.25, 0.42, 1.0)
	return Color.WHITE


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	shoot_timer -= delta
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_charge = maxf(0.0, dash_charge - delta)
	summon_timer -= delta
	support_timer -= delta
	teleport_timer -= delta
	teleport_charge = maxf(0.0, teleport_charge - delta)
	teleport_rush = maxf(0.0, teleport_rush - delta)
	parry_cycle -= delta
	parry_window = maxf(0.0, parry_window - delta)
	counter_rush = maxf(0.0, counter_rush - delta)
	haste_time = maxf(0.0, haste_time - delta)
	if shield_hits <= 0:
		shield_broken_time = maxf(0.0, shield_broken_time - delta)
		if shield_broken_time <= 0.0:
			shield_hits = 3
	pattern_phase += delta
	_update_status(delta)

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var direction := to_target.normalized() if distance > 0.01 else Vector2.ZERO
	facing_direction = direction if direction.length_squared() > 0.01 else facing_direction
	var movement_speed := speed * (1.0 - slow_amount if slow_time > 0.0 else 1.0) * (1.28 if haste_time > 0.0 else 1.0)
	var desired := direction * movement_speed

	match enemy_kind:
		"dasher":
			desired = _dasher_movement(desired, distance)
		"scribe":
			desired = _ranged_movement(direction, distance, movement_speed, 128.0)
			if shoot_timer <= 0.0:
				shoot_timer = 1.85 if source_wave <= 3 else 1.55
				shoot_projectiles(direction)
		"warden":
			desired = _ranged_movement(direction, distance, movement_speed, 102.0)
			if shoot_timer <= 0.0:
				shoot_timer = 2.35
				shoot_projectiles(direction)
		"censor":
			if shield_hits <= 0:
				desired *= 1.25
		"errata":
			desired = _errata_movement(direction, movement_speed)
		"archivist":
			desired = _ranged_movement(direction, distance, movement_speed, 112.0)
			if support_timer <= 0.0:
				support_timer = 4.4
				_support_pulse()
		"blot":
			desired = Vector2.ZERO
			if shoot_timer <= 0.0:
				shoot_timer = 3.2 if source_wave <= 3 else 2.65
				shoot_projectiles(direction)
		"duelist":
			desired = _duelist_movement(direction, distance, movement_speed)
		"editor":
			if shoot_timer <= 0.0:
				shoot_timer = 1.55
				shoot_projectiles(direction)
		"binder":
			desired = _ranged_movement(direction, distance, movement_speed, 118.0)
			if shoot_timer <= 0.0:
				shoot_timer = 1.8
				shoot_projectiles(direction)
			if summon_timer <= 0.0:
				summon_timer = 5.8
				_summon_masks()
		"author":
			if shoot_timer <= 0.0:
				shoot_timer = maxf(0.48, 1.05 - (1.0 - health / max_health) * 0.4)
				shoot_projectiles(direction)
			if dash_timer <= 0.0:
				dash_timer = 3.1
				dash_charge = 0.28
				var author_game := get_parent()
				if author_game.has_method("play_spatial_sound"):
					author_game.play_spatial_sound("enemy_dash", global_position, 0.72)
			if dash_charge > 0.0:
				desired *= 0.08
				sprite.modulate = CRIMSON if int(dash_charge * 24.0) % 2 == 0 else Color.WHITE
			elif dash_timer > 2.82:
				desired *= 4.6

	var separation := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or not (other is Node2D):
			continue
		var away: Vector2 = global_position - other.global_position
		var distance_sq: float = away.length_squared()
		if distance_sq > 0.01 and distance_sq < 625.0:
			separation += away.normalized() * (25.0 - sqrt(distance_sq)) * 2.0

	velocity = desired + separation + external_velocity
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	move_and_slide()
	var game := get_parent()
	if game.has_method("clamp_to_arena"):
		global_position = game.clamp_to_arena(global_position, 14.0)

	var contact_range := 27.0 if enemy_kind in BOSS_KINDS else (21.0 if enemy_kind in ["brute", "warden", "censor", "blot"] else 18.0)
	if distance < contact_range and contact_cooldown <= 0.0:
		contact_cooldown = 0.72 if enemy_kind == "leech" else 0.86
		if target.has_method("take_damage"):
			var landed: bool = target.take_damage(contact_damage, direction)
			if landed and enemy_kind == "leech":
				health = minf(max_health, health + contact_damage * 1.8)
			if landed and is_elite and elite_affix == "vampiric":
				health = minf(max_health, health + contact_damage * 2.4)
	_update_visual(delta, direction)


func _dasher_movement(desired: Vector2, distance: float) -> Vector2:
	if dash_timer <= 0.0 and dash_charge <= 0.0 and distance < 190.0:
		dash_charge = 0.38
		dash_timer = 2.1
		var game := get_parent()
		if game.has_method("play_spatial_sound"):
			game.play_spatial_sound("enemy_dash", global_position, 1.08)
	if dash_charge > 0.0:
		desired *= 0.12
		sprite.modulate = CRIMSON if int(dash_charge * 18.0) % 2 == 0 else Color.WHITE
	elif dash_timer > 1.72:
		desired *= 4.2
		sprite.modulate = _elite_color() if is_elite else Color.WHITE
	return desired


func _errata_movement(direction: Vector2, movement_speed: float) -> Vector2:
	var game := get_parent()
	if teleport_timer <= 0.0 and not teleport_pending:
		teleport_timer = 4.6
		teleport_charge = 0.48
		teleport_pending = true
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -24), "ERRATA...", STEEL)
		if game.has_method("play_spatial_sound"):
			game.play_spatial_sound("teleport", global_position, 1.0)
	if teleport_pending:
		if teleport_charge > 0.0:
			sprite.modulate = Color(0.55, 0.42, 0.65, 1.0) if int(teleport_charge * 28.0) % 2 == 0 else Color.WHITE
			return Vector2.ZERO
		teleport_pending = false
		var player_facing = target.get("last_direction")
		var facing := Vector2(player_facing) if player_facing is Vector2 else -direction
		var behind := -facing.normalized() if facing.length_squared() > 0.01 else -direction
		global_position = target.global_position + behind * 58.0
		if game.has_method("clamp_to_arena"):
			global_position = game.clamp_to_arena(global_position, 18.0)
		teleport_rush = 0.62
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -24), "BEHIND YOU!", CRIMSON)
	if teleport_rush > 0.0:
		return direction * movement_speed * 2.8
	return direction * movement_speed


func _duelist_movement(direction: Vector2, distance: float, movement_speed: float) -> Vector2:
	var game := get_parent()
	if parry_cycle <= 0.0:
		parry_cycle = 3.4
		parry_window = 0.52
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -24), "PARRY?", STEEL)
		if game.has_method("play_spatial_sound"):
			game.play_spatial_sound("parry", global_position, 0.82)
	if parry_window > 0.0:
		sprite.modulate = STEEL if int(parry_window * 24.0) % 2 == 0 else Color.WHITE
		return direction.rotated(PI * 0.5) * movement_speed * 0.28
	if counter_rush > 0.0:
		return direction * movement_speed * 3.6
	if dash_timer <= 0.0 and distance < 125.0:
		dash_timer = 2.5
		counter_rush = 0.24
	return _ranged_movement(direction, distance, movement_speed, 64.0)


func _support_pulse() -> void:
	var restored := 0
	for ally in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(ally) or ally.get_parent() != get_parent() or ally.dead:
			continue
		if global_position.distance_squared_to(ally.global_position) > 12500.0:
			continue
		ally.health = minf(ally.max_health, ally.health + maxf(1.0, ally.max_health * 0.1))
		ally.haste_time = maxf(ally.haste_time, 2.8)
		ally.queue_redraw()
		restored += 1
	var game := get_parent()
	if game.has_method("spawn_word"):
		game.spawn_word(global_position + Vector2(0, -28), "RESTORE %d!" % restored, GOLD)
	if game.has_method("play_spatial_sound"):
		game.play_spatial_sound("heal", global_position, 1.0)
	queue_redraw()


func _ranged_movement(direction: Vector2, distance: float, movement_speed: float, preferred: float) -> Vector2:
	if distance < preferred * 0.72:
		return -direction * movement_speed
	if distance > preferred * 1.25:
		return direction * movement_speed
	return direction.rotated(PI * 0.5) * movement_speed * 0.72


func _update_status(delta: float) -> void:
	bleed_time = maxf(0.0, bleed_time - delta)
	burn_time = maxf(0.0, burn_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	if slow_time <= 0.0:
		slow_amount = move_toward(slow_amount, 0.0, delta * 2.0)
	status_tick -= delta
	if status_tick > 0.0:
		return
	status_tick = 0.35
	var periodic := 0.0
	if bleed_time > 0.0:
		periodic += bleed_damage
	if burn_time > 0.0:
		periodic += burn_damage
	if periodic > 0.0:
		health -= periodic
		sprite.modulate = CRIMSON
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", _elite_color() if is_elite else Color.WHITE, 0.1)
		if health <= 0.0:
			die()


func apply_status(bleed: float, burn: float, slow: float) -> void:
	if bleed > 0.0:
		bleed_damage = minf(3.0, bleed_damage + bleed)
		bleed_time = 3.0
	if burn > 0.0:
		burn_damage = maxf(burn_damage, burn)
		burn_time = 2.2
	if slow > 0.0:
		slow_amount = maxf(slow_amount, slow)
		slow_time = 1.5


func _update_visual(delta: float, direction: Vector2) -> void:
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0
	var motion_phase := Time.get_ticks_msec() * 0.012 + get_instance_id() * 0.1
	var bob := sin(motion_phase)
	var target_scale := visual_base_scale * Vector2(1.0 + absf(bob) * 0.022, 1.0 - absf(bob) * 0.022)
	if dash_charge > 0.0 or counter_rush > 0.0 or teleport_rush > 0.0:
		target_scale *= Vector2(1.18, 0.84)
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2(1.25, 0.72), minf(1.0, delta * 15.0))
	else:
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2.ONE, minf(1.0, delta * 9.0))
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, delta * 12.0))
	sprite.rotation = lerp_angle(sprite.rotation, direction.x * 0.045, delta * 9.0)
	sprite.position.y = visual_y_offset + bob * (1.0 if enemy_kind in BOSS_KINDS else 0.7)
	queue_redraw()


func shoot_projectiles(direction: Vector2) -> void:
	var game := get_parent()
	if not game.has_method("spawn_projectile"):
		return
	if game.has_method("available_hostile_projectile_slots") and game.available_hostile_projectile_slots() <= 0:
		return
	if game.has_method("play_spatial_sound"):
		var cast_pitch: float = float({"scribe": 1.18, "warden": 0.82, "blot": 0.68, "editor": 0.76, "binder": 0.64, "author": 0.56}.get(enemy_kind, 1.0))
		game.play_spatial_sound("enemy_cast", global_position, cast_pitch)
	match enemy_kind:
		"scribe":
			game.spawn_projectile(global_position, direction, 126.0)
			game.spawn_word(global_position + Vector2(0, -22), "SCRIBE!", GOLD)
		"warden":
			for index in range(8):
				game.spawn_projectile(global_position, Vector2.from_angle(TAU * float(index) / 8.0 + pattern_phase * 0.2), 82.0)
			game.spawn_word(global_position + Vector2(0, -28), "SEAL!", STEEL)
		"blot":
			for index in range(6):
				game.spawn_projectile(global_position, Vector2.from_angle(TAU * float(index) / 6.0 + pattern_phase * 0.16), 58.0)
			game.spawn_word(global_position + Vector2(0, -26), "SPILL!", CRIMSON)
		"binder":
			for index in range(10):
				game.spawn_projectile(global_position, Vector2.from_angle(TAU * float(index) / 10.0 + pattern_phase * 0.35), 92.0)
			game.spawn_word(global_position + Vector2(0, -34), "BIND!", GOLD)
		"author":
			for index in range(5):
				var angle := pattern_phase * 0.9 + TAU * float(index) / 5.0
				game.spawn_projectile(global_position, Vector2.from_angle(angle), 112.0 + index * 5.0)
			game.spawn_word(global_position + Vector2(0, -40), "REVISE!", CRIMSON)
		_:
			for offset_angle in [-0.36, 0.0, 0.36]:
				game.spawn_projectile(global_position, direction.rotated(offset_angle), 104.0)
			game.spawn_word(global_position + Vector2(0, -30), "EDIT!", CRIMSON)


func _summon_masks() -> void:
	var game := get_parent()
	if not game.has_method("spawn_enemy"):
		return
	for angle in [-0.8, 0.8]:
		game.spawn_enemy("scribe" if randf() < 0.35 else "mask", global_position + Vector2.from_angle(angle + pattern_phase) * 42.0)
	game.spawn_word(global_position + Vector2(0, -34), "APPEND!", GOLD)


func take_damage(amount: float, impulse: Vector2, critical: bool = false) -> void:
	if dead:
		return
	if _try_defend(amount, impulse):
		return
	health -= amount
	external_velocity += impulse
	queue_redraw()
	var game := get_parent()
	if game.has_method("impact"):
		game.impact(global_position, critical, "CRIT!" if critical else "KRAK!", 7.0 if critical else 4.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", CRIMSON if critical else PAPER, 0.025)
	tween.tween_property(sprite, "modulate", _elite_color() if is_elite else Color.WHITE, 0.08)
	if health <= 0.0:
		die()


func _try_defend(amount: float, impulse: Vector2) -> bool:
	if impulse.length_squared() <= 0.01:
		return false
	var game := get_parent()
	if enemy_kind == "duelist" and parry_window > 0.0:
		parry_window = 0.0
		counter_rush = 0.58
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -24), "PARRY!", STEEL)
		if game.has_method("play_spatial_sound"):
			game.play_spatial_sound("parry", global_position, 1.18)
		queue_redraw()
		return true
	if enemy_kind == "censor" and shield_hits > 0 and is_instance_valid(target):
		var toward_attacker := (target.global_position - global_position).normalized()
		var attack_origin_direction := -impulse.normalized()
		if toward_attacker.dot(attack_origin_direction) > 0.25:
			shield_hits -= 1
			health -= amount * 0.12
			if shield_hits <= 0:
				shield_broken_time = 4.2
				if game.has_method("spawn_word"):
					game.spawn_word(global_position + Vector2(0, -26), "SHIELD BROKEN!", GOLD)
			elif game.has_method("spawn_word"):
				game.spawn_word(global_position + Vector2(0, -24), "CENSORED!", STEEL)
			if game.has_method("play_spatial_sound"):
				game.play_spatial_sound("shield", global_position, 0.88 if shield_hits > 0 else 0.68)
			queue_redraw()
			if health <= 0.0:
				die()
			return true
	return false


func die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemies")
	var game := get_parent()
	if enemy_kind == "splitter" and game.has_method("spawn_enemy"):
		game.spawn_enemy("mask", global_position + Vector2(-13, 0))
		game.spawn_enemy("mask", global_position + Vector2(13, 0))
	if enemy_kind == "blot" and game.has_method("spawn_projectile"):
		for index in range(8):
			game.spawn_projectile(global_position, Vector2.from_angle(TAU * float(index) / 8.0), 74.0)
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -22), "SPLAT!", CRIMSON)
	if is_elite and elite_affix == "volatile" and is_instance_valid(target) and global_position.distance_to(target.global_position) < 62.0:
		target.take_damage(1.5, (target.global_position - global_position).normalized())
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -18), "BOOM!", GOLD)
	died.emit(self, xp_value, global_position, enemy_kind)
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2(0, 16 if enemy_kind in BOSS_KINDS else 12), 0.0, ground_shadow_scale)
	draw_colored_polygon(ground_shadow_points, Color(0.0, 0.0, 0.0, 0.58 if enemy_kind in BOSS_KINDS else 0.46))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if enemy_kind == "censor" and shield_hits > 0 and not dead:
		var shield_angle := facing_direction.angle()
		draw_arc(Vector2.ZERO, 17.0, shield_angle - 0.9, shield_angle + 0.9, 14, STEEL, 2.5)
	if enemy_kind == "duelist" and parry_window > 0.0 and not dead:
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, STEEL, 2.0)
	if enemy_kind == "archivist" and support_timer < 0.65 and not dead:
		draw_arc(Vector2.ZERO, 19.0 + (0.65 - support_timer) * 5.0, 0.0, TAU, 24, GOLD, 1.5)
	if enemy_kind == "blot" and not dead:
		draw_arc(Vector2.ZERO, 13.0 + sin(pattern_phase * 3.0) * 2.0, 0.0, TAU, 18, CRIMSON, 1.0)
	if is_elite and not dead:
		draw_arc(Vector2.ZERO, 14.0 if enemy_kind not in ["brute", "warden", "censor", "blot"] else 18.0, 0.0, TAU, 20, _elite_color(), 1.5)
	if health >= max_health or dead:
		return
	var width := 46.0 if enemy_kind in BOSS_KINDS else (30.0 if enemy_kind in ["brute", "warden", "censor", "blot"] else 24.0)
	var y := -32.0 if enemy_kind in BOSS_KINDS else (-24.0 if enemy_kind in ["brute", "warden", "censor", "blot"] else -20.0)
	draw_rect(Rect2(-width * 0.5, y, width, 3), DEEP_INK, true)
	draw_rect(Rect2(-width * 0.5 + 1, y + 1, (width - 2.0) * clampf(health / max_health, 0.0, 1.0), 1), CRIMSON, true)
