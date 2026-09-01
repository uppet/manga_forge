extends CharacterBody2D
class_name InkboundPlayer

const CombatCast = preload("res://scripts/combat_cast.gd")
const Content = preload("res://scripts/content_db.gd")

signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal leveled_up(level: int)
signal died
signal build_changed(summary: String)
signal build_milestone_unlocked(discipline_id: String, tier: int)
signal ink_art_changed(art_name: String, remaining: float, maximum: float)

const PAPER := Color("fff8e0")
const CRIMSON := Color("d33037")
const ATTACK_BUFFER_SECONDS := 0.13
const DASH_BUFFER_SECONDS := 0.12
const INK_ART_BUFFER_SECONDS := 0.14

var max_health := 8.0
var health := 8.0
var move_speed := 112.0
var damage := 2.0
var attack_reach := 52.0
var attack_arc := 105.0
var attack_period := 0.42
var knockback_power := 150.0
var critical_chance := 0.1
var cleave := 5
var dash_cooldown_max := 1.15

var level := 1
var xp := 0
var xp_needed := 5
var attack_cooldown := 0.0
var dash_cooldown := 0.0
var dash_time := 0.0
var attack_buffer_time := 0.0
var dash_buffer_time := 0.0
var ink_art_buffer_time := 0.0
var invulnerable_time := 0.0
var last_direction := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var dash_trail_timer := 0.0
var controls_enabled := true
var using_gamepad := false
var upgrade_stacks: Dictionary = {}
var build_milestones: Array[String] = []
var relics: Array[String] = []
var weapon_form := "MARGINALIA"

var damage_reduction := 0.0
var critical_damage_bonus := 0.0
var pickup_radius := 100.0
var luck := 0.0
var xp_multiplier := 1.0
var regeneration := 0.0
var time_since_hit := 99.0
var untouched_time := 0.0
var untouched_bonus := 0.0
var kill_heal_every := 0
var kills_since_heal := 0
var attack_counter := 0
var hit_counter := 0
var guaranteed_crit_every := 0
var wave_every := 0
var wave_damage_factor := 0.65
var wave_pierce := 0
var wave_splits := 0
var wave_returns := false
var bleed_power := 0.0
var burn_power := 0.0
var slow_power := 0.0
var execute_threshold := 0.0
var critical_echo := 0.0
var dash_nova_damage := 0.0
var afterimage_damage := 0.0
var combo_power := 0.0
var combo_hits := 0
var combo_timeout := 0.0
var boss_damage_bonus := 0.0
var last_word := false
var death_save_available := false
var upgrade_choice_bonus := 0
var guard := 0.0
var binder_chain := false
var empty_frame := false
var paper_heart := false
var standstill_time := 0.0
var aura_tick := 0.0
var frenzy_time := 0.0
var ink_art_cooldown_max := 8.0
var ink_art_cooldown := 0.0
var ink_art_damage_multiplier := 1.0
var ink_art_radius_bonus := 0.0
var ink_art_hit_refund := 0.0
var ink_art_echo := false
var ink_art_heal := false
var ink_art_uses := 0
var ink_art_last_display_step := -1
var ink_art_last_name := ""

var sprite: Sprite2D
var ground_shadow_points := PackedVector2Array()
var ground_shadow_scale := Vector2.ONE
var visual_base_scale := Vector2.ONE
var attack_pose_time := 0.0
var attack_pose_duration := 0.0
var attack_frame_index := -1
var idle_texture: Texture2D
var attack_textures: Array[Texture2D] = []


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	ground_shadow_points = CombatCast.ellipse_points(CombatCast.shadow_radii("player"))

	sprite = Sprite2D.new()
	idle_texture = CombatCast.texture_for("player")
	for frame_index in range(CombatCast.PLAYER_ATTACK_FRAME_COUNT):
		attack_textures.append(CombatCast.player_attack_texture(frame_index))
	sprite.texture = idle_texture
	visual_base_scale = CombatCast.scale_for("player")
	sprite.scale = visual_base_scale
	sprite.position.y = -5.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 7.0
	shape.height = 20.0
	collision.shape = shape
	add_child(collision)
	z_index = 10


func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	ink_art_cooldown = maxf(0.0, ink_art_cooldown - delta)
	attack_buffer_time = maxf(0.0, attack_buffer_time - delta)
	dash_buffer_time = maxf(0.0, dash_buffer_time - delta)
	ink_art_buffer_time = maxf(0.0, ink_art_buffer_time - delta)
	attack_pose_time = maxf(0.0, attack_pose_time - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	time_since_hit += delta
	untouched_time += delta
	combo_timeout = maxf(0.0, combo_timeout - delta)
	frenzy_time = maxf(0.0, frenzy_time - delta)
	if combo_timeout <= 0.0:
		combo_hits = 0
	if regeneration > 0.0 and time_since_hit > 4.0 and health < max_health:
		heal(regeneration * delta)

	if dash_time > 0.0:
		dash_time -= delta
		velocity = dash_direction * move_speed * 3.25
		dash_trail_timer -= delta
		if dash_trail_timer <= 0.0:
			dash_trail_timer = 0.035
			var game := get_parent()
			if game.has_method("spawn_afterimage"):
				game.spawn_afterimage(global_position)
			if afterimage_damage > 0.0 and game.has_method("damage_nearby"):
				game.damage_nearby(global_position, 18.0, afterimage_damage, dash_direction * 30.0)
		if dash_time <= 0.0 and dash_nova_damage > 0.0:
			var game := get_parent()
			if game.has_method("damage_nearby"):
				game.damage_nearby(global_position, 48.0, dash_nova_damage, dash_direction * 90.0)
			if game.has_method("spawn_word"):
				game.spawn_word(global_position + Vector2(0, -22), "PERIOD!", CRIMSON)
		if dash_time <= 0.0 and binder_chain:
			var chain_game := get_parent()
			if chain_game.has_method("apply_status_nearby"):
				chain_game.apply_status_nearby(global_position, 64.0, 0.0, 0.0, 0.35)
	else:
		var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down") if controls_enabled else Vector2.ZERO
		velocity = Vector2.ZERO
		if input_vector.length_squared() > 0.01:
			standstill_time = 0.0
			last_direction = input_vector.normalized()
			velocity = input_vector.normalized() * move_speed
		else:
			standstill_time += delta
		if empty_frame and standstill_time > 0.8:
			aura_tick -= delta
			if aura_tick <= 0.0:
				aura_tick = 0.65
				var aura_game := get_parent()
				if aura_game.has_method("damage_nearby"):
					aura_game.damage_nearby(global_position, 44.0, damage * 0.28, Vector2.ZERO)
		var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down") if controls_enabled else Vector2.ZERO
		if stick_aim.length_squared() > 0.04:
			last_direction = stick_aim.normalized()

		if controls_enabled:
			if Input.is_action_just_pressed("dash"):
				dash_buffer_time = DASH_BUFFER_SECONDS
			if Input.is_action_just_pressed("attack"):
				attack_buffer_time = ATTACK_BUFFER_SECONDS
			if Input.is_action_just_pressed("special"):
				ink_art_buffer_time = INK_ART_BUFFER_SECONDS
		else:
			attack_buffer_time = 0.0
			dash_buffer_time = 0.0
			ink_art_buffer_time = 0.0

		if controls_enabled and dash_buffer_time > 0.0 and start_dash(input_vector):
			dash_buffer_time = 0.0
		if controls_enabled and (Input.is_action_pressed("attack") or attack_buffer_time > 0.0):
			var aim := stick_aim if using_gamepad else get_global_mouse_position() - global_position
			if perform_attack(aim if aim.length_squared() > 0.04 else last_direction):
				attack_buffer_time = 0.0
		if controls_enabled and ink_art_buffer_time > 0.0:
			var art_aim := stick_aim if using_gamepad else get_global_mouse_position() - global_position
			if perform_ink_art(art_aim if art_aim.length_squared() > 0.04 else last_direction):
				ink_art_buffer_time = 0.0

	var game_parent := get_parent()
	if game_parent.has_method("uses_deterministic_simulation") and game_parent.uses_deterministic_simulation():
		global_position += velocity * delta
	else:
		move_and_slide()
	if game_parent.has_method("clamp_to_arena"):
		global_position = game_parent.clamp_to_arena(global_position, 18.0)
	_update_visual(delta)
	_notify_ink_art_changed()


func _update_visual(delta: float) -> void:
	if last_direction.x != 0.0:
		sprite.flip_h = last_direction.x < 0.0
	var motion_phase := Time.get_ticks_msec() * 0.018
	var active_attack_frame := _current_attack_frame()
	if active_attack_frame != attack_frame_index:
		attack_frame_index = active_attack_frame
		sprite.texture = idle_texture if attack_frame_index < 0 else attack_textures[attack_frame_index]
	var target_scale := CombatCast.PLAYER_ATTACK_SCALE if attack_frame_index >= 0 else visual_base_scale
	if dash_time > 0.0:
		if attack_frame_index >= 0:
			attack_frame_index = -1
			sprite.texture = idle_texture
		target_scale = visual_base_scale
		target_scale *= Vector2(1.24, 0.78)
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2(1.35, 0.72), minf(1.0, delta * 18.0))
	elif attack_pose_time > 0.0:
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2(1.16, 0.88), minf(1.0, delta * 18.0))
	elif velocity.length_squared() > 4.0:
		var stride := sin(motion_phase)
		target_scale *= Vector2(1.0 + absf(stride) * 0.035, 1.0 - absf(stride) * 0.035)
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2(1.0 + absf(stride) * 0.08, 1.0), minf(1.0, delta * 12.0))
	else:
		ground_shadow_scale = ground_shadow_scale.lerp(Vector2.ONE, minf(1.0, delta * 10.0))
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, delta * 18.0))
	if velocity.length_squared() > 4.0 and dash_time <= 0.0:
		sprite.position.y = -5.0 + sin(motion_phase) * 1.0
		sprite.rotation = lerp_angle(sprite.rotation, last_direction.x * 0.055, delta * 12.0)
	else:
		sprite.position.y = -4.0 if attack_frame_index >= 0 else -5.0
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 18.0)
	queue_redraw()


func _current_attack_frame() -> int:
	if attack_pose_time <= 0.0 or attack_pose_duration <= 0.0 or attack_textures.is_empty():
		return -1
	var progress := clampf(1.0 - attack_pose_time / attack_pose_duration, 0.0, 0.999)
	if progress < 0.17:
		return 0
	if progress < 0.43:
		return 1
	if progress < 0.7:
		return 2
	return 3


func _start_attack_animation(duration: float) -> void:
	attack_pose_duration = maxf(0.12, duration)
	attack_pose_time = attack_pose_duration
	attack_frame_index = 0
	if not attack_textures.is_empty():
		sprite.texture = attack_textures[0]


func _attack_animation_duration() -> float:
	match weapon_form:
		"GREATBRUSH":
			return 0.32
		"NEEDLEPOINT":
			return 0.17
		"SEAL-CASTER":
			return 0.25
		"TWIN-STROKE":
			return 0.2
	return 0.24


func _draw() -> void:
	draw_set_transform(Vector2(0, 12), 0.0, ground_shadow_scale)
	draw_colored_polygon(ground_shadow_points, Color(0.0, 0.0, 0.0, 0.48))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func start_dash(input_vector: Vector2 = Vector2.ZERO) -> bool:
	if dash_cooldown > 0.0 or dash_time > 0.0:
		return false
	dash_direction = input_vector.normalized() if input_vector.length_squared() > 0.01 else last_direction
	dash_time = 0.16
	dash_cooldown = dash_cooldown_max
	invulnerable_time = maxf(invulnerable_time, 0.24)
	dash_trail_timer = 0.0
	var game := get_parent()
	if game.has_method("play_sound"):
		game.play_sound("dash", 0.95 + randf() * 0.1)
	if game.has_method("spawn_word"):
		game.spawn_word(global_position + Vector2(0, -22), "ZIP!", CRIMSON)
	if game.has_method("vibrate"):
		game.vibrate(0.08, 0.18, 0.08)
	if game.has_method("record_playtest_event"):
		game.record_playtest_event("dash", {"direction": dash_direction, "health": health, "weapon": weapon_form})
	return true


func perform_attack(direction: Vector2, force: bool = false) -> bool:
	if direction.length_squared() <= 0.001:
		direction = last_direction
	if attack_cooldown > 0.0 and not force:
		return false
	direction = direction.normalized()
	last_direction = direction
	_start_attack_animation(_attack_animation_duration())
	attack_counter += 1
	var combo_speed := 1.0 + minf(0.45, float(combo_hits) * combo_power * 0.025)
	attack_cooldown = attack_period / (combo_speed * (1.35 if frenzy_time > 0.0 else 1.0))
	var game := get_parent()
	if game.has_method("spawn_slash"):
		game.spawn_slash(global_position, direction, attack_reach, attack_arc)
		if weapon_form == "TWIN-STROKE":
			game.spawn_slash(global_position, direction.rotated(-0.2), attack_reach * 0.92, attack_arc * 0.72)
	if game.has_method("play_sound"):
		var slash_sound := "slash"
		var slash_pitch := 0.97 + randf() * 0.06
		match weapon_form:
			"GREATBRUSH":
				slash_sound = "slash_heavy"
				slash_pitch = 0.94 + randf() * 0.05
			"NEEDLEPOINT":
				slash_sound = "slash_light"
				slash_pitch = 1.0 + randf() * 0.06
			"SEAL-CASTER":
				slash_sound = "seal_cast"
				slash_pitch = 0.97 + randf() * 0.05
			"TWIN-STROKE":
				slash_pitch = 1.02 + randf() * 0.06
		game.play_sound(slash_sound, slash_pitch)
	if wave_every > 0 and attack_counter % wave_every == 0 and game.has_method("spawn_player_wave"):
		game.spawn_player_wave(global_position + direction * 12.0, direction, damage * wave_damage_factor, wave_pierce, wave_splits, wave_returns)

	var hit_count := 0
	var half_arc_cos := cos(deg_to_rad(attack_arc * 0.5))
	var attack_targets := get_tree().get_nodes_in_group("enemies")
	if game.has_method("uses_deterministic_simulation") and game.uses_deterministic_simulation():
		attack_targets.sort_custom(func(left: Node, right: Node) -> bool: return int(left.get("simulation_order")) < int(right.get("simulation_order")))
	for node in attack_targets:
		if not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var offset: Vector2 = node.global_position - global_position
		var distance := offset.length()
		if distance > attack_reach or distance <= 0.001:
			continue
		if direction.dot(offset / distance) < half_arc_cos:
			continue
		hit_counter += 1
		var forced_critical := guaranteed_crit_every > 0 and hit_counter % guaranteed_crit_every == 0
		var critical := forced_critical or randf() < critical_chance
		var streak_multiplier := 1.0 + minf(0.5, untouched_time * untouched_bonus)
		var low_health_multiplier := 1.5 if last_word and health <= 1.0 else 1.0
		var form_multiplier := 1.55 if weapon_form == "TWIN-STROKE" else 1.0
		var dealt := damage * streak_multiplier * low_health_multiplier * form_multiplier * (1.35 if frenzy_time > 0.0 else 1.0)
		if critical:
			dealt *= 2.0 + critical_damage_bonus
		if node.is_in_group("bosses"):
			dealt *= 1.0 + boss_damage_bonus
		if execute_threshold > 0.0 and not node.is_in_group("bosses") and node.health / node.max_health <= execute_threshold:
			dealt = maxf(dealt, node.health + 1.0)
		if node.has_method("apply_status"):
			node.apply_status(bleed_power, burn_power if critical else 0.0, slow_power)
		node.take_damage(dealt, offset.normalized() * knockback_power, critical)
		if ink_art_hit_refund > 0.0:
			ink_art_cooldown = maxf(0.0, ink_art_cooldown - ink_art_hit_refund)
		if critical and critical_echo > 0.0 and is_instance_valid(node) and not node.dead:
			node.take_damage(dealt * critical_echo, offset.normalized() * knockback_power * 0.35, false)
		hit_count += 1
		combo_hits += 1
		combo_timeout = 1.1
		if hit_count >= cleave:
			break
	if game.has_method("record_playtest_event"):
		game.record_playtest_event("attack", {"weapon": weapon_form, "hits": hit_count, "direction": direction, "health": health})
	return true


func ink_art_profile() -> Dictionary:
	match weapon_form:
		"GREATBRUSH":
			return {"id": "final-period", "name": "FINAL PERIOD", "cooldown": 1.18, "damage": 3.5, "radius": 104.0}
		"NEEDLEPOINT":
			return {"id": "red-line", "name": "RED LINE", "cooldown": 0.78, "damage": 3.15, "radius": 24.0}
		"SEAL-CASTER":
			return {"id": "seal-storm", "name": "SEAL STORM", "cooldown": 1.05, "damage": 1.18, "radius": 82.0}
		"TWIN-STROKE":
			return {"id": "cross-revision", "name": "CROSS REVISION", "cooldown": 0.92, "damage": 2.65, "radius": 92.0}
	return {"id": "palimpsest-ring", "name": "PALIMPSEST RING", "cooldown": 1.0, "damage": 2.55, "radius": 78.0}


func ink_art_cooldown_total() -> float:
	return ink_art_cooldown_max * float(ink_art_profile().get("cooldown", 1.0))


func perform_ink_art(direction: Vector2, force: bool = false) -> bool:
	if ink_art_cooldown > 0.0 and not force:
		return false
	if direction.length_squared() <= 0.001:
		direction = last_direction
	direction = direction.normalized()
	last_direction = direction
	_start_attack_animation(0.3)
	var profile := ink_art_profile()
	var game := get_parent()
	if not game.has_method("execute_ink_art"):
		return false
	ink_art_cooldown = ink_art_cooldown_total()
	ink_art_uses += 1
	var art_damage := damage * float(profile.get("damage", 2.5)) * ink_art_damage_multiplier
	var art_radius := float(profile.get("radius", 78.0)) + ink_art_radius_bonus
	var hit_count: int = game.execute_ink_art(str(profile["id"]), global_position, direction, art_damage, art_radius, false)
	if game.has_method("play_sound"):
		var art_pitch: float = float({"GREATBRUSH": 0.78, "NEEDLEPOINT": 1.28, "SEAL-CASTER": 1.05, "TWIN-STROKE": 1.14}.get(weapon_form, 0.94))
		game.play_sound("ink_art", art_pitch)
	if game.has_method("vibrate"):
		game.vibrate(0.28, 0.62, 0.16)
	if ink_art_heal and hit_count >= 5:
		heal(1.0)
		if game.has_method("spawn_word"):
			game.spawn_word(global_position + Vector2(0, -30), "MERCY +1", PAPER)
	if ink_art_echo and game.has_method("queue_ink_art_echo"):
		game.queue_ink_art_echo(str(profile["id"]), global_position, direction, art_damage * 0.45, art_radius * 0.92)
	if game.has_method("record_playtest_event"):
		game.record_playtest_event("ink_art", {"art": str(profile["id"]), "weapon": weapon_form, "hits": hit_count, "health": health})
	_notify_ink_art_changed(true)
	return true


func recharge_ink_art(amount: float) -> void:
	ink_art_cooldown = maxf(0.0, ink_art_cooldown - maxf(0.0, amount))
	_notify_ink_art_changed(true)


func _notify_ink_art_changed(force: bool = false) -> void:
	var profile := ink_art_profile()
	var art_name := str(profile.get("name", "INK ART"))
	var display_step := int(ceil(ink_art_cooldown * 10.0))
	if force or display_step != ink_art_last_display_step or art_name != ink_art_last_name:
		ink_art_last_display_step = display_step
		ink_art_last_name = art_name
		ink_art_changed.emit(art_name, ink_art_cooldown, ink_art_cooldown_total())


func take_damage(amount: float, source_direction: Vector2 = Vector2.ZERO, source_id: String = "unknown") -> bool:
	if invulnerable_time > 0.0 or health <= 0.0:
		return false
	var health_before := health
	var guard_before := guard
	var incoming := amount * (1.0 - clampf(damage_reduction, 0.0, 0.72))
	if guard > 0.0:
		var absorbed := minf(guard, incoming)
		guard -= absorbed
		incoming -= absorbed
	if incoming <= 0.0:
		return false
	if health - incoming <= 0.0 and death_save_available:
		death_save_available = false
		health = 1.0
	else:
		health = maxf(0.0, health - incoming)
	invulnerable_time = 0.68
	time_since_hit = 0.0
	untouched_time = 0.0
	combo_hits = 0
	velocity += source_direction.normalized() * 120.0
	health_changed.emit(health, max_health)
	var game := get_parent()
	if game.has_method("record_playtest_event"):
		game.record_playtest_event("player_damaged", {
			"source": source_id.left(64),
			"raw_amount": amount,
			"health_before": health_before,
			"health_after": health,
			"guard_before": guard_before,
			"guard_after": guard,
			"fatal": health <= 0.0,
		})
	if game.has_method("play_sound"):
		game.play_sound("hurt", 0.9 + randf() * 0.12)
	if game.has_method("impact"):
		game.impact(global_position, false, "HIT!", 4.0)
	if game.has_method("vibrate"):
		game.vibrate(0.42, 0.75, 0.14)
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(sprite, "modulate", CRIMSON, 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.06)
	if health <= 0.0:
		died.emit()
	return true


func gain_xp(amount: int) -> void:
	xp += maxi(1, int(round(float(amount) * xp_multiplier)))
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 4 + level * 3
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed, level)


func heal(amount: float) -> void:
	var health_before := health
	var next_health := health + amount
	if paper_heart and next_health > max_health:
		guard = minf(max_health * 0.5, guard + next_health - max_health)
	health = minf(max_health, next_health)
	health_changed.emit(health, max_health)
	var game := get_parent()
	if game.has_method("record_playtest_event") and health > health_before:
		game.record_playtest_event("player_healed", {"amount": health - health_before, "health_before": health_before, "health_after": health})


func activate_frenzy(duration: float = 8.0) -> void:
	frenzy_time = maxf(frenzy_time, duration)


func apply_upgrade(upgrade_id: String) -> void:
	upgrade_stacks[upgrade_id] = int(upgrade_stacks.get(upgrade_id, 0)) + 1
	match upgrade_id:
		"razor-ink":
			damage += 0.75
		"wide-panel":
			attack_reach += 8.0
			attack_arc = minf(170.0, attack_arc + 12.0)
		"rapid-stroke":
			attack_period = maxf(0.16, attack_period * 0.86)
		"red-thread":
			critical_chance = minf(0.65, critical_chance + 0.09)
		"ghost-step":
			dash_cooldown_max = maxf(0.45, dash_cooldown_max * 0.84)
			move_speed += 6.0
		"iron-gutter":
			max_health += 2.0
			heal(2.0)
		"overflow":
			cleave += 2
			knockback_power += 18.0
		"paper-armor":
			damage_reduction = 1.0 - (1.0 - damage_reduction) * 0.93
		"margin-magnet":
			pickup_radius += 36.0
		"scholar-luck":
			luck += 0.12
		"living-footnote":
			regeneration += 0.12
		"blood-annotation":
			kill_heal_every = maxi(5, 13 - int(upgrade_stacks[upgrade_id]) * 2)
		"ink-wave":
			wave_every = maxi(2, 5 - int(upgrade_stacks[upgrade_id]))
			wave_damage_factor += 0.12
		"returning-stroke":
			wave_returns = true
		"splinter-script":
			wave_splits += 1
		"bleeding-letters":
			bleed_power += 0.32
		"ember-margin":
			burn_power += 0.45
		"cold-reading":
			slow_power = minf(0.55, slow_power + 0.14)
		"execution-clause":
			execute_threshold += 0.08
		"critical-echo":
			critical_echo += 0.22
		"dash-nova":
			dash_nova_damage += damage * 0.7
		"afterimage-cut":
			afterimage_damage += damage * 0.11
		"perfect-margin":
			untouched_bonus += 0.012
		"crescendo":
			combo_power += 1.0
		"greatbrush":
			weapon_form = "GREATBRUSH"
			damage *= 1.55
			attack_reach += 22.0
			attack_arc += 20.0
			attack_period *= 1.28
			knockback_power += 100.0
		"needlepoint":
			weapon_form = "NEEDLEPOINT"
			damage *= 0.78
			attack_period *= 0.62
			attack_arc = maxf(48.0, attack_arc - 30.0)
			critical_chance += 0.22
		"seal-caster":
			weapon_form = "SEAL-CASTER"
			attack_reach = maxf(34.0, attack_reach - 10.0)
			attack_period *= 0.86
			wave_every = 1
			wave_damage_factor += 0.15
		"twin-stroke":
			weapon_form = "TWIN-STROKE"
			attack_period *= 1.1
		"last-word":
			last_word = true
		"open-book":
			upgrade_choice_bonus = 1
			luck += 0.12
		"living-ink":
			ink_art_damage_multiplier += 0.25
		"quickscript":
			ink_art_cooldown_max = maxf(3.5, ink_art_cooldown_max * 0.86)
			ink_art_cooldown = minf(ink_art_cooldown, ink_art_cooldown_total())
		"violent-margin":
			ink_art_radius_bonus += 18.0
		"red-harvest":
			ink_art_hit_refund += 0.12
		"echoed-panel":
			ink_art_echo = true
		"merciful-revision":
			ink_art_heal = true
	_check_build_milestones(true)
	xp_changed.emit(xp, xp_needed, level)
	build_changed.emit(get_build_summary())
	_notify_ink_art_changed(true)


func apply_relic(relic_id: String) -> bool:
	if relic_id in relics:
		return false
	relics.append(relic_id)
	match relic_id:
		"broken-mask":
			boss_damage_bonus += 0.15
		"iori-ribbon":
			death_save_available = true
		"red-pencil":
			guaranteed_crit_every = 10
		"library-card":
			xp_multiplier += 0.2
		"glass-nib":
			critical_damage_bonus += 0.35
			max_health = maxf(2.0, max_health * 0.9)
			health = minf(health, max_health)
		"wax-seal":
			wave_pierce += 1
			wave_damage_factor += 0.2
		"binder-chain":
			binder_chain = true
		"paper-heart":
			paper_heart = true
			max_health += 4.0
			health += 4.0
		"empty-frame":
			empty_frame = true
		"first-draft":
			damage += 0.5
			critical_chance += 0.05
	health_changed.emit(health, max_health)
	build_changed.emit(get_build_summary())
	return true


func on_enemy_killed(_enemy_kind: String) -> void:
	if ink_art_hit_refund > 0.0:
		recharge_ink_art(ink_art_hit_refund * 2.5)
	if kill_heal_every > 0:
		kills_since_heal += 1
		if kills_since_heal >= kill_heal_every:
			kills_since_heal = 0
			heal(1.0)
			var game := get_parent()
			if game.has_method("spawn_word"):
				game.spawn_word(global_position + Vector2(0, -22), "MENDED", PAPER)


func on_new_wave() -> void:
	if "black-tea" in relics:
		heal(1.0)


func get_build_summary() -> String:
	var discipline := Content.dominant_build_discipline(upgrade_stacks)
	if discipline.is_empty():
		return weapon_form
	var score := int(discipline.get("score", 0))
	var tier := int(discipline.get("tier", 0))
	var threshold := int(discipline.get("next_threshold", maxi(1, score)))
	var tier_mark: String = ["", " I", " II"][clampi(tier, 0, 2)]
	return "%s  ·  %s%s %d/%d" % [weapon_form, discipline.get("name", "DRAFT"), tier_mark, mini(score, threshold), threshold]


func _check_build_milestones(announce: bool) -> void:
	var scores := Content.build_discipline_scores(upgrade_stacks)
	for discipline in Content.BUILD_DISCIPLINES:
		var discipline_id := str(discipline.get("id", ""))
		var score := int(scores.get(discipline_id, 0))
		var thresholds: Array = discipline.get("thresholds", [])
		for index in range(thresholds.size()):
			var tier := index + 1
			var milestone_id := "%s:%d" % [discipline_id, tier]
			if score < int(thresholds[index]) or milestone_id in build_milestones:
				continue
			build_milestones.append(milestone_id)
			_apply_build_milestone_effect(discipline_id, tier)
			if announce:
				build_milestone_unlocked.emit(discipline_id, tier)


func _apply_build_milestone_effect(discipline_id: String, tier: int) -> void:
	match "%s:%d" % [discipline_id, tier]:
		"ink-edge:1":
			attack_reach += 8.0
			cleave += 1
		"ink-edge:2":
			damage += 0.5
			attack_reach += 2.0
			cleave += 1
		"red-logic:1":
			critical_chance = minf(0.95, critical_chance + 0.05)
		"red-logic:2":
			critical_damage_bonus += 0.3
		"quick-margin:1":
			attack_period = maxf(0.16, attack_period * 0.94)
		"quick-margin:2":
			move_speed += 8.0
			combo_power += 1.0
		"ghost-draft:1":
			dash_cooldown_max = maxf(0.45, dash_cooldown_max * 0.9)
		"ghost-draft:2":
			dash_nova_damage += maxf(1.0, damage * 0.5)
			afterimage_damage += maxf(0.4, damage * 0.12)
		"living-script:1":
			ink_art_cooldown_max = maxf(3.5, ink_art_cooldown_max * 0.9)
			ink_art_cooldown = minf(ink_art_cooldown, ink_art_cooldown_total())
		"living-script:2":
			wave_every = 5 if wave_every <= 0 else wave_every
			ink_art_damage_multiplier += 0.15
		"bound-page:1":
			max_health += 1.0
			heal(1.0)
		"bound-page:2":
			damage_reduction = 1.0 - (1.0 - damage_reduction) * 0.95
			regeneration += 0.06
			guard += 2.0


func get_session_state() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"move_speed": move_speed,
		"damage": damage,
		"attack_reach": attack_reach,
		"attack_arc": attack_arc,
		"attack_period": attack_period,
		"knockback_power": knockback_power,
		"critical_chance": critical_chance,
		"cleave": cleave,
		"dash_cooldown_max": dash_cooldown_max,
		"level": level,
		"xp": xp,
		"xp_needed": xp_needed,
		"upgrade_stacks": upgrade_stacks.duplicate(true),
		"build_milestones": build_milestones.duplicate(),
		"relics": relics.duplicate(),
		"weapon_form": weapon_form,
		"damage_reduction": damage_reduction,
		"critical_damage_bonus": critical_damage_bonus,
		"pickup_radius": pickup_radius,
		"luck": luck,
		"xp_multiplier": xp_multiplier,
		"regeneration": regeneration,
		"time_since_hit": time_since_hit,
		"untouched_time": untouched_time,
		"untouched_bonus": untouched_bonus,
		"kill_heal_every": kill_heal_every,
		"kills_since_heal": kills_since_heal,
		"attack_counter": attack_counter,
		"hit_counter": hit_counter,
		"guaranteed_crit_every": guaranteed_crit_every,
		"wave_every": wave_every,
		"wave_damage_factor": wave_damage_factor,
		"wave_pierce": wave_pierce,
		"wave_splits": wave_splits,
		"wave_returns": wave_returns,
		"bleed_power": bleed_power,
		"burn_power": burn_power,
		"slow_power": slow_power,
		"execute_threshold": execute_threshold,
		"critical_echo": critical_echo,
		"dash_nova_damage": dash_nova_damage,
		"afterimage_damage": afterimage_damage,
		"combo_power": combo_power,
		"boss_damage_bonus": boss_damage_bonus,
		"last_word": last_word,
		"death_save_available": death_save_available,
		"upgrade_choice_bonus": upgrade_choice_bonus,
		"guard": guard,
		"binder_chain": binder_chain,
		"empty_frame": empty_frame,
		"paper_heart": paper_heart,
		"frenzy_time": frenzy_time,
		"ink_art_cooldown_max": ink_art_cooldown_max,
		"ink_art_cooldown": ink_art_cooldown,
		"ink_art_damage_multiplier": ink_art_damage_multiplier,
		"ink_art_radius_bonus": ink_art_radius_bonus,
		"ink_art_hit_refund": ink_art_hit_refund,
		"ink_art_echo": ink_art_echo,
		"ink_art_heal": ink_art_heal,
		"ink_art_uses": ink_art_uses,
	}


func apply_session_state(state: Dictionary) -> bool:
	if state.is_empty() or not (state.get("upgrade_stacks", {}) is Dictionary) or not (state.get("relics", []) is Array):
		return false
	max_health = clampf(float(state.get("max_health", 8.0)), 2.0, 100.0)
	health = clampf(float(state.get("health", max_health)), 0.25, max_health)
	move_speed = clampf(float(state.get("move_speed", 112.0)), 40.0, 400.0)
	damage = clampf(float(state.get("damage", 2.0)), 0.1, 250.0)
	attack_reach = clampf(float(state.get("attack_reach", 52.0)), 12.0, 240.0)
	attack_arc = clampf(float(state.get("attack_arc", 105.0)), 20.0, 260.0)
	attack_period = clampf(float(state.get("attack_period", 0.42)), 0.08, 3.0)
	knockback_power = clampf(float(state.get("knockback_power", 150.0)), 0.0, 1000.0)
	critical_chance = clampf(float(state.get("critical_chance", 0.1)), 0.0, 0.95)
	cleave = clampi(int(state.get("cleave", 5)), 1, 100)
	dash_cooldown_max = clampf(float(state.get("dash_cooldown_max", 1.15)), 0.2, 8.0)
	level = clampi(int(state.get("level", 1)), 1, 100)
	xp_needed = clampi(int(state.get("xp_needed", 5)), 1, 10000)
	xp = clampi(int(state.get("xp", 0)), 0, xp_needed - 1)
	upgrade_stacks = state.get("upgrade_stacks", {}).duplicate(true)
	build_milestones.clear()
	var restored_milestones: Variant = state.get("build_milestones", [])
	if restored_milestones is Array:
		for milestone_value in restored_milestones:
			var milestone_id := str(milestone_value)
			if milestone_id not in build_milestones:
				build_milestones.append(milestone_id)
	relics.clear()
	for relic_id in state.get("relics", []):
		var clean_id := str(relic_id)
		if not clean_id.is_empty() and clean_id not in relics:
			relics.append(clean_id)
	weapon_form = str(state.get("weapon_form", "MARGINALIA")).left(24)
	damage_reduction = clampf(float(state.get("damage_reduction", 0.0)), 0.0, 0.72)
	critical_damage_bonus = clampf(float(state.get("critical_damage_bonus", 0.0)), 0.0, 5.0)
	pickup_radius = clampf(float(state.get("pickup_radius", 100.0)), 20.0, 800.0)
	luck = clampf(float(state.get("luck", 0.0)), 0.0, 3.0)
	xp_multiplier = clampf(float(state.get("xp_multiplier", 1.0)), 0.1, 10.0)
	regeneration = clampf(float(state.get("regeneration", 0.0)), 0.0, 10.0)
	time_since_hit = maxf(0.0, float(state.get("time_since_hit", 99.0)))
	untouched_time = maxf(0.0, float(state.get("untouched_time", 0.0)))
	untouched_bonus = clampf(float(state.get("untouched_bonus", 0.0)), 0.0, 1.0)
	kill_heal_every = clampi(int(state.get("kill_heal_every", 0)), 0, 100)
	kills_since_heal = clampi(int(state.get("kills_since_heal", 0)), 0, 100)
	attack_counter = maxi(0, int(state.get("attack_counter", 0)))
	hit_counter = maxi(0, int(state.get("hit_counter", 0)))
	guaranteed_crit_every = clampi(int(state.get("guaranteed_crit_every", 0)), 0, 100)
	wave_every = clampi(int(state.get("wave_every", 0)), 0, 100)
	wave_damage_factor = clampf(float(state.get("wave_damage_factor", 0.65)), 0.0, 20.0)
	wave_pierce = clampi(int(state.get("wave_pierce", 0)), 0, 20)
	wave_splits = clampi(int(state.get("wave_splits", 0)), 0, 10)
	wave_returns = bool(state.get("wave_returns", false))
	bleed_power = clampf(float(state.get("bleed_power", 0.0)), 0.0, 20.0)
	burn_power = clampf(float(state.get("burn_power", 0.0)), 0.0, 20.0)
	slow_power = clampf(float(state.get("slow_power", 0.0)), 0.0, 0.9)
	execute_threshold = clampf(float(state.get("execute_threshold", 0.0)), 0.0, 0.8)
	critical_echo = clampf(float(state.get("critical_echo", 0.0)), 0.0, 5.0)
	dash_nova_damage = clampf(float(state.get("dash_nova_damage", 0.0)), 0.0, 1000.0)
	afterimage_damage = clampf(float(state.get("afterimage_damage", 0.0)), 0.0, 1000.0)
	combo_power = clampf(float(state.get("combo_power", 0.0)), 0.0, 20.0)
	boss_damage_bonus = clampf(float(state.get("boss_damage_bonus", 0.0)), 0.0, 5.0)
	last_word = bool(state.get("last_word", false))
	death_save_available = bool(state.get("death_save_available", false))
	upgrade_choice_bonus = clampi(int(state.get("upgrade_choice_bonus", 0)), 0, 1)
	guard = clampf(float(state.get("guard", 0.0)), 0.0, 100.0)
	binder_chain = bool(state.get("binder_chain", false))
	empty_frame = bool(state.get("empty_frame", false))
	paper_heart = bool(state.get("paper_heart", false))
	frenzy_time = clampf(float(state.get("frenzy_time", 0.0)), 0.0, 30.0)
	ink_art_cooldown_max = clampf(float(state.get("ink_art_cooldown_max", 8.0)), 3.5, 30.0)
	ink_art_cooldown = clampf(float(state.get("ink_art_cooldown", 0.0)), 0.0, 40.0)
	ink_art_damage_multiplier = clampf(float(state.get("ink_art_damage_multiplier", 1.0)), 0.1, 10.0)
	ink_art_radius_bonus = clampf(float(state.get("ink_art_radius_bonus", 0.0)), 0.0, 180.0)
	ink_art_hit_refund = clampf(float(state.get("ink_art_hit_refund", 0.0)), 0.0, 3.0)
	ink_art_echo = bool(state.get("ink_art_echo", false))
	ink_art_heal = bool(state.get("ink_art_heal", false))
	ink_art_uses = maxi(0, int(state.get("ink_art_uses", 0)))
	# Older checkpoints have the technique stacks but no milestone ledger. Apply
	# the missing deterministic bonuses once, then persist their stable IDs.
	_check_build_milestones(false)
	attack_cooldown = 0.0
	dash_cooldown = 0.0
	dash_time = 0.0
	invulnerable_time = 1.2
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_needed, level)
	build_changed.emit(get_build_summary())
	_notify_ink_art_changed(true)
	return true


func debug_attack(direction: Vector2) -> bool:
	attack_cooldown = 0.0
	return perform_attack(direction, true)


func debug_ink_art(direction: Vector2) -> bool:
	ink_art_cooldown = 0.0
	return perform_ink_art(direction, true)
