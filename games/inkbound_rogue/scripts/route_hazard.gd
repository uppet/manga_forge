extends Node2D

signal cycle_started(route_id: String, hazard_id: String)
signal cycle_resolved(route_id: String, hazard_id: String, resolution: String)

const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")

const ARENA_RECT := Rect2(-640.0, -360.0, 1280.0, 720.0)
const PAPER := Color("efe2c4")
const WHITE := Color("fff8e0")
const CRIMSON := Color("d33037")
const DARK_RED := Color("701820")
const GOLD := Color("f2b344")
const STEEL := Color("96aab0")
const DEEP_INK := Color("08070b")
const BOSS_KINDS := ["editor", "binder", "author"]

var game: Node2D
var target: Node2D
var route_id := ""
var hazard_id := ""
var hazard_name := ""
var phase := "idle"
var cooldown := 999.0
var phase_time := 0.0
var telegraph_total := 1.0
var points: Array[Vector2] = []
var direction := Vector2.RIGHT
var radius := 64.0
var cycles_started := 0
var cycles_resolved := 0
var player_hits := 0
var enemy_hits := 0
var benefits_claimed := 0
var last_resolution := ""
var visual_time := 0.0
var rng := RandomNumberGenerator.new()


func setup(game_target: Node2D, player_target: Node2D) -> Node2D:
	game = game_target
	target = player_target
	return self


func _ready() -> void:
	add_to_group("route_hazards")
	z_index = 3
	rng.randomize()
	queue_redraw()


func reset_run() -> void:
	clear_route()
	cycles_started = 0
	cycles_resolved = 0
	player_hits = 0
	enemy_hits = 0
	benefits_claimed = 0
	last_resolution = ""


func clear_route() -> void:
	route_id = ""
	hazard_id = ""
	hazard_name = ""
	phase = "idle"
	cooldown = 999.0
	phase_time = 0.0
	points.clear()
	queue_redraw()


func set_route(value: String) -> bool:
	var data: Dictionary = Content.route(value)
	var next_hazard := str(data.get("hazard", ""))
	if data.is_empty() or next_hazard.is_empty():
		clear_route()
		return false
	var changed := route_id != value
	route_id = value
	hazard_id = next_hazard
	hazard_name = str(data.get("hazard_name", next_hazard)).to_upper()
	if changed:
		phase = "idle"
		phase_time = 0.0
		points.clear()
		cooldown = 3.4
		last_resolution = ""
	queue_redraw()
	return true


func set_rng_seed(value: int) -> void:
	rng.seed = value


func _simulation_active() -> bool:
	if route_id.is_empty() or not is_instance_valid(game) or not is_instance_valid(target):
		return false
	return bool(game.get("run_started")) and not bool(game.get("game_over")) and not bool(game.get("run_won")) and not bool(game.get("choosing_upgrade")) and not bool(game.get("choosing_event")) and not bool(game.get("manually_paused")) and float(target.get("health")) > 0.0


func _physics_process(delta: float) -> void:
	visual_time += delta
	if not _simulation_active():
		return
	match phase:
		"telegraph":
			phase_time = maxf(0.0, phase_time - delta)
			queue_redraw()
			if phase_time <= 0.0:
				_resolve_cycle()
		"cache":
			phase_time = maxf(0.0, phase_time - delta)
			queue_redraw()
			if not points.is_empty() and target.global_position.distance_to(points[0]) <= 27.0:
				_claim_cache()
			elif phase_time <= 0.0:
				_explode_cache()
		"aftermath":
			phase_time = maxf(0.0, phase_time - delta)
			queue_redraw()
			if phase_time <= 0.0:
				_finish_cycle()
		_:
			cooldown -= delta
			if cooldown <= 0.0:
				_begin_cycle()


func _route_data() -> Dictionary:
	return Content.route(route_id)


func _schedule_next() -> void:
	var interval := maxf(4.0, float(_route_data().get("hazard_interval", 9.0)))
	cooldown = interval * rng.randf_range(0.88, 1.14)


func _finish_cycle() -> void:
	phase = "idle"
	phase_time = 0.0
	points.clear()
	_schedule_next()
	queue_redraw()


func _begin_cycle() -> bool:
	if hazard_id.is_empty() or not is_instance_valid(target):
		return false
	points.clear()
	direction = Vector2.from_angle(rng.randf_range(0.0, TAU)).normalized()
	radius = 64.0
	telegraph_total = 1.0
	phase = "telegraph"
	match hazard_id:
		"echo-sanctuary":
			radius = 82.0
			telegraph_total = 1.75
			points.append(_random_point_near_target(28.0, 72.0))
		"razor-sweep":
			telegraph_total = 1.05
			direction = Vector2.from_angle(rng.randi_range(0, 5) * PI / 6.0).normalized()
			var predicted := target.global_position + _target_velocity() * 0.25
			points.append(_clamp_point(predicted, 56.0))
		"redaction-stamp":
			radius = 68.0
			telegraph_total = 1.2
			points.append(_clamp_point(target.global_position + _target_velocity() * 0.32, 76.0))
		"chain-cross":
			telegraph_total = 1.15
			direction = Vector2.from_angle(rng.randi_range(0, 7) * PI / 8.0).normalized()
			points.append(_random_point_near_target(0.0, 48.0))
		"canal-surge":
			telegraph_total = 1.0
			direction = Vector2.RIGHT if rng.randf() < 0.5 else Vector2.LEFT
			var lane_y := _nearest_lane_y(target.global_position.y)
			points.append(Vector2(0.0, lane_y))
		"contraband-cache":
			radius = 26.0
			telegraph_total = 5.0
			phase = "cache"
			points.append(_random_point_near_target(92.0, 155.0))
		"white-revision":
			radius = 88.0
			telegraph_total = 1.8
			points.append(_random_point_near_target(34.0, 92.0))
		"press-stamp":
			radius = 50.0
			telegraph_total = 1.15
			var predicted := _clamp_point(target.global_position + _target_velocity() * 0.28, 62.0)
			points.append(predicted)
			points.append(_clamp_point(predicted + Vector2(96.0, 52.0).rotated(rng.randf_range(0.0, TAU)), 62.0))
			points.append(_clamp_point(predicted + Vector2(-92.0, 48.0).rotated(rng.randf_range(0.0, TAU)), 62.0))
		"page-gust":
			telegraph_total = 1.0
			direction = Vector2.from_angle(rng.randi_range(0, 7) * PI / 4.0).normalized()
		_:
			phase = "idle"
			_schedule_next()
			return false
	phase_time = telegraph_total
	cycles_started += 1
	last_resolution = ""
	if game.has_method("play_sound"):
		game.play_sound("boss_warning", 0.82 if hazard_id in ["echo-sanctuary", "white-revision", "contraband-cache"] else 1.08)
	cycle_started.emit(route_id, hazard_id)
	queue_redraw()
	return true


func _resolve_cycle() -> void:
	if phase != "telegraph":
		return
	var resolution := "resolved"
	match hazard_id:
		"echo-sanctuary":
			resolution = _resolve_echo()
		"razor-sweep":
			resolution = _resolve_razor()
		"redaction-stamp":
			resolution = _resolve_redaction()
		"chain-cross":
			resolution = _resolve_chain()
		"canal-surge":
			resolution = _resolve_canal()
		"white-revision":
			resolution = _resolve_white()
		"press-stamp":
			resolution = _resolve_press()
		"page-gust":
			resolution = _resolve_gust()
	phase = "aftermath"
	phase_time = 0.34
	cycles_resolved += 1
	last_resolution = resolution
	cycle_resolved.emit(route_id, hazard_id, resolution)
	queue_redraw()


func _resolve_echo() -> String:
	if points.is_empty():
		return "empty"
	var center := points[0]
	var benefited := false
	if target.global_position.distance_to(center) <= radius:
		target.recharge_ink_art(2.4)
		target.guard += 1.0
		benefits_claimed += 1
		benefited = true
		game.spawn_word(target.global_position + Vector2(0, -30), "WHISPER ANSWERS · WARD +1", GOLD)
	for enemy in _enemy_nodes():
		if enemy.global_position.distance_to(center) <= radius:
			enemy.slow_amount = maxf(float(enemy.get("slow_amount")), 0.48)
			enemy.slow_time = maxf(float(enemy.get("slow_time")), 3.2)
			enemy_hits += 1
	if game.has_method("play_sound"):
		game.play_sound("relic", 0.9)
	return "sanctuary-claimed" if benefited else "sanctuary-missed"


func _resolve_razor() -> String:
	if points.is_empty():
		return "empty"
	var origin := points[0]
	var hit_any := false
	if _distance_to_line(target.global_position, origin, direction) <= 19.0:
		hit_any = _damage_player(1.0, _line_push_direction(target.global_position, origin, direction)) or hit_any
	for enemy in _enemy_nodes():
		if _distance_to_line(enemy.global_position, origin, direction) <= 22.0:
			_damage_enemy(enemy, 5.0, _line_push_direction(enemy.global_position, origin, direction) * 150.0)
			hit_any = true
	_play_hazard_impact()
	return "razor-hit" if hit_any else "razor-dodged"


func _resolve_redaction() -> String:
	if points.is_empty():
		return "empty"
	var center := points[0]
	var hit_any := false
	if target.global_position.distance_to(center) <= radius:
		hit_any = _damage_player(1.0, _away_from(center, target.global_position)) or hit_any
	for enemy in _enemy_nodes():
		if enemy.global_position.distance_to(center) <= radius:
			_damage_enemy(enemy, 3.5, _away_from(center, enemy.global_position) * 110.0)
			hit_any = true
	_play_hazard_impact()
	return "stamp-hit" if hit_any else "stamp-empty"


func _resolve_chain() -> String:
	if points.is_empty():
		return "empty"
	var origin := points[0]
	var perpendicular := direction.rotated(PI * 0.5)
	var hit_any := false
	var player_distance := minf(_distance_to_line(target.global_position, origin, direction), _distance_to_line(target.global_position, origin, perpendicular))
	if player_distance <= 17.0:
		hit_any = _damage_player(0.75, _away_from(origin, target.global_position)) or hit_any
	for enemy in _enemy_nodes():
		var distance := minf(_distance_to_line(enemy.global_position, origin, direction), _distance_to_line(enemy.global_position, origin, perpendicular))
		if distance <= 20.0:
			enemy.slow_amount = maxf(float(enemy.get("slow_amount")), 0.58)
			enemy.slow_time = maxf(float(enemy.get("slow_time")), 4.0)
			_damage_enemy(enemy, 2.0, _away_from(origin, enemy.global_position) * 70.0)
			hit_any = true
	_play_hazard_impact()
	return "chain-bound" if hit_any else "chain-crossed"


func _resolve_canal() -> String:
	if points.is_empty():
		return "empty"
	var lane_y := points[0].y
	var hit_any := false
	if absf(target.global_position.y - lane_y) <= 30.0:
		hit_any = _damage_player(0.75, direction) or hit_any
		target.global_position = _clamp_point(target.global_position + direction * 58.0, 22.0)
	for enemy in _enemy_nodes():
		if absf(enemy.global_position.y - lane_y) <= 34.0:
			_damage_enemy(enemy, 2.25, direction * 190.0)
			hit_any = true
	_play_hazard_impact()
	return "surge-caught" if hit_any else "surge-cleared"


func _resolve_white() -> String:
	if points.is_empty():
		return "empty"
	var center := points[0]
	var healed_player := false
	var healed_enemies := 0
	if target.global_position.distance_to(center) <= radius:
		var before := float(target.get("health"))
		var guard_before := float(target.get("guard"))
		target.heal(2.0)
		healed_player = float(target.get("health")) > before or float(target.get("guard")) > guard_before
		if healed_player:
			benefits_claimed += 1
			game.spawn_word(target.global_position + Vector2(0, -30), "WHITE REVISION · RECOVER +2", WHITE)
	for enemy in _enemy_nodes():
		if enemy.global_position.distance_to(center) <= radius and float(enemy.get("health")) < float(enemy.get("max_health")):
			enemy.health = minf(float(enemy.get("max_health")), float(enemy.get("health")) + float(enemy.get("max_health")) * 0.18)
			enemy.haste_time = maxf(float(enemy.get("haste_time")), 3.0)
			healed_enemies += 1
	if game.has_method("play_sound"):
		game.play_sound("relic", 1.08)
	return "revision-shared" if healed_player and healed_enemies > 0 else ("revision-claimed" if healed_player else "revision-fed-masks")


func _resolve_press() -> String:
	var hit_any := false
	for center in points:
		if target.global_position.distance_to(center) <= radius:
			hit_any = _damage_player(1.25, _away_from(center, target.global_position)) or hit_any
		for enemy in _enemy_nodes():
			if is_instance_valid(enemy) and not bool(enemy.get("dead")) and enemy.global_position.distance_to(center) <= radius:
				_damage_enemy(enemy, 4.5, _away_from(center, enemy.global_position) * 135.0)
				hit_any = true
	_play_hazard_impact()
	return "verdict-landed" if hit_any else "verdict-dodged"


func _resolve_gust() -> String:
	var before := target.global_position
	target.global_position = _clamp_point(target.global_position + direction * 54.0, 22.0)
	for enemy in _enemy_nodes():
		enemy.external_velocity += direction * 235.0
		enemy_hits += 1
	if game.has_method("play_sound"):
		game.play_sound("dash", 0.72)
	if before.distance_to(target.global_position) > 1.0:
		game.spawn_word(target.global_position + Vector2(0, -30), "PAGE GUST", PAPER)
	return "gust-shifted"


func _claim_cache() -> void:
	if phase != "cache":
		return
	game.collect_shards(1)
	target.guard += 1.0
	benefits_claimed += 1
	cycles_resolved += 1
	last_resolution = "cache-claimed"
	game.spawn_word(target.global_position + Vector2(0, -30), "CONTRABAND CLAIMED · WARD +1", GOLD)
	phase = "aftermath"
	phase_time = 0.34
	cycle_resolved.emit(route_id, hazard_id, last_resolution)
	queue_redraw()


func _explode_cache() -> void:
	if phase != "cache" or points.is_empty():
		return
	var center := points[0]
	if target.global_position.distance_to(center) <= 78.0:
		_damage_player(1.0, _away_from(center, target.global_position))
	for enemy in _enemy_nodes():
		if enemy.global_position.distance_to(center) <= 78.0:
			_damage_enemy(enemy, 4.0, _away_from(center, enemy.global_position) * 145.0)
	_play_hazard_impact()
	cycles_resolved += 1
	last_resolution = "cache-burned"
	game.spawn_word(center + Vector2(0, -30), "CONTRABAND BURNS", CRIMSON)
	phase = "aftermath"
	phase_time = 0.34
	cycle_resolved.emit(route_id, hazard_id, last_resolution)
	queue_redraw()


func _damage_player(amount: float, push_direction: Vector2) -> bool:
	var landed: bool = target.take_damage(amount, push_direction, "hazard:" + hazard_id)
	if landed:
		player_hits += 1
	return landed


func _damage_enemy(enemy: Node, amount: float, impulse: Vector2) -> void:
	if not is_instance_valid(enemy) or bool(enemy.get("dead")):
		return
	var adjusted := amount * (0.35 if str(enemy.get("enemy_kind")) in BOSS_KINDS else 1.0)
	enemy.take_damage(adjusted, impulse, false)
	enemy_hits += 1


func _play_hazard_impact() -> void:
	if game.has_method("play_sound"):
		game.play_sound("hit", 0.72)
	if game.has_method("vibrate"):
		game.vibrate(0.12, 0.3, 0.09)


func _enemy_nodes() -> Array:
	var result: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game and not bool(enemy.get("dead")):
			result.append(enemy)
	return result


func _random_point_near_target(minimum: float, maximum: float) -> Vector2:
	var offset := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(minimum, maximum)
	return _clamp_point(target.global_position + offset, 72.0)


func _clamp_point(point: Vector2, margin: float) -> Vector2:
	if is_instance_valid(game) and game.has_method("clamp_to_arena"):
		return game.clamp_to_arena(point, margin)
	return Vector2(clampf(point.x, ARENA_RECT.position.x + margin, ARENA_RECT.end.x - margin), clampf(point.y, ARENA_RECT.position.y + margin, ARENA_RECT.end.y - margin))


func _target_velocity() -> Vector2:
	var value: Variant = target.get("velocity") if is_instance_valid(target) else Vector2.ZERO
	return value if value is Vector2 else Vector2.ZERO


func _nearest_lane_y(y_value: float) -> float:
	var selected := -220.0
	var best_distance := INF
	for lane in [-220.0, 0.0, 220.0]:
		var distance := absf(y_value - lane)
		if distance < best_distance:
			best_distance = distance
			selected = lane
	return selected


func _distance_to_line(point: Vector2, origin: Vector2, line_direction: Vector2) -> float:
	return absf((point - origin).cross(line_direction.normalized()))


func _line_push_direction(point: Vector2, origin: Vector2, line_direction: Vector2) -> Vector2:
	var perpendicular := line_direction.rotated(PI * 0.5).normalized()
	return perpendicular if (point - origin).dot(perpendicular) >= 0.0 else -perpendicular


func _away_from(origin: Vector2, point: Vector2) -> Vector2:
	var away := point - origin
	return away.normalized() if away.length_squared() > 0.001 else direction.rotated(PI * 0.5).normalized()


func get_state() -> Dictionary:
	var serialized_points: Array = []
	for point in points:
		serialized_points.append([point.x, point.y])
	return {
		"route_id": route_id,
		"phase": phase,
		"cooldown": cooldown,
		"phase_time": phase_time,
		"telegraph_total": telegraph_total,
		"points": serialized_points,
		"direction": [direction.x, direction.y],
		"radius": radius,
		"cycles_started": cycles_started,
		"cycles_resolved": cycles_resolved,
		"player_hits": player_hits,
		"enemy_hits": enemy_hits,
		"benefits_claimed": benefits_claimed,
		"last_resolution": last_resolution,
		"rng_state": str(rng.state),
	}


func apply_state(state: Dictionary) -> bool:
	var saved_route := str(state.get("route_id", ""))
	if Content.route(saved_route).is_empty() or not set_route(saved_route):
		return false
	var saved_phase := str(state.get("phase", "idle"))
	phase = saved_phase if saved_phase in ["idle", "telegraph", "cache", "aftermath"] else "idle"
	cooldown = clampf(float(state.get("cooldown", 3.4)), 0.0, 60.0)
	phase_time = clampf(float(state.get("phase_time", 0.0)), 0.0, 10.0)
	telegraph_total = clampf(float(state.get("telegraph_total", 1.0)), 0.2, 10.0)
	radius = clampf(float(state.get("radius", 64.0)), 16.0, 180.0)
	points.clear()
	var raw_points: Variant = state.get("points", [])
	if raw_points is Array:
		for point_data in raw_points:
			if point_data is Array and point_data.size() >= 2:
				points.append(_clamp_point(Vector2(float(point_data[0]), float(point_data[1])), 16.0))
			if points.size() >= 4:
				break
	var direction_data: Variant = state.get("direction", [1.0, 0.0])
	if direction_data is Array and direction_data.size() >= 2:
		direction = Vector2(float(direction_data[0]), float(direction_data[1])).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	cycles_started = maxi(0, int(state.get("cycles_started", 0)))
	cycles_resolved = clampi(int(state.get("cycles_resolved", 0)), 0, cycles_started)
	player_hits = maxi(0, int(state.get("player_hits", 0)))
	enemy_hits = maxi(0, int(state.get("enemy_hits", 0)))
	benefits_claimed = maxi(0, int(state.get("benefits_claimed", 0)))
	last_resolution = str(state.get("last_resolution", "")).left(32)
	var saved_rng_state := str(state.get("rng_state", ""))
	if saved_rng_state.is_valid_int():
		rng.state = int(saved_rng_state)
	if phase in ["telegraph", "cache"] and hazard_id != "page-gust" and points.is_empty():
		phase = "idle"
		_schedule_next()
	queue_redraw()
	return true


func debug_force_cycle() -> bool:
	phase = "idle"
	cooldown = 0.0
	return _begin_cycle()


func debug_resolve_cycle() -> void:
	if phase == "telegraph":
		_resolve_cycle()
	elif phase == "cache":
		_claim_cache()


func debug_expire_cache() -> void:
	if phase == "cache":
		_explode_cache()


func debug_set_primary_point(at: Vector2) -> void:
	if points.is_empty():
		points.append(_clamp_point(at, 16.0))
	else:
		points[0] = _clamp_point(at, 16.0)
	queue_redraw()


func _draw() -> void:
	if route_id.is_empty() or phase == "idle":
		return
	var color := _hazard_color()
	var progress := 1.0 - clampf(phase_time / maxf(0.01, telegraph_total), 0.0, 1.0)
	var pulse := 0.65 + sin(visual_time * 8.0) * 0.2
	var line_color := Color(color.r, color.g, color.b, 0.55 + progress * 0.35)
	var fill_color := Color(color.r, color.g, color.b, (0.055 + progress * 0.11) * pulse)
	if phase == "aftermath":
		line_color = Color(color.r, color.g, color.b, 0.9)
		fill_color = Color(color.r, color.g, color.b, 0.2)
	match hazard_id:
		"echo-sanctuary", "white-revision":
			if not points.is_empty():
				_draw_circle_hazard(points[0], radius, line_color, fill_color, hazard_name)
		"razor-sweep":
			if not points.is_empty():
				_draw_line_hazard(points[0], direction, line_color, fill_color, "RAZOR")
		"redaction-stamp":
			if not points.is_empty():
				_draw_redaction_stamp(points[0], line_color, fill_color)
		"chain-cross":
			if not points.is_empty():
				_draw_line_hazard(points[0], direction, line_color, fill_color, "BIND")
				_draw_line_hazard(points[0], direction.rotated(PI * 0.5), line_color, fill_color, "")
		"canal-surge":
			if not points.is_empty():
				_draw_canal(points[0].y, direction, line_color, fill_color)
		"contraband-cache":
			if not points.is_empty():
				_draw_cache(points[0], line_color, fill_color)
		"press-stamp":
			for index in range(points.size()):
				_draw_circle_hazard(points[index], radius, line_color, fill_color, ["I", "II", "III"][mini(index, 2)])
		"page-gust":
			_draw_gust(direction, line_color)


func _hazard_color() -> Color:
	match hazard_id:
		"echo-sanctuary", "white-revision":
			return WHITE
		"chain-cross", "contraband-cache":
			return GOLD
		"canal-surge":
			return STEEL
		"page-gust":
			return PAPER
	return CRIMSON


func _draw_circle_hazard(center: Vector2, size: float, line_color: Color, fill_color: Color, label: String) -> void:
	draw_circle(center, size, fill_color)
	draw_arc(center, size, 0.0, TAU, 48, line_color, 3.0, true)
	draw_arc(center, maxf(4.0, size - 7.0), -PI * 0.5, -PI * 0.5 + TAU * (1.0 - clampf(phase_time / maxf(0.01, telegraph_total), 0.0, 1.0)), 40, line_color, 2.0, true)
	if not label.is_empty():
		draw_string(Localization.ui_theme().default_font, center + Vector2(-size, 4), Localization.text(label), HORIZONTAL_ALIGNMENT_CENTER, size * 2.0, 8, PAPER)


func _draw_line_hazard(origin: Vector2, line_direction: Vector2, line_color: Color, fill_color: Color, label: String) -> void:
	var start := origin - line_direction * 780.0
	var finish := origin + line_direction * 780.0
	draw_line(start, finish, fill_color, 18.0, true)
	draw_line(start, finish, line_color, 3.0, true)
	for offset in [-420.0, -140.0, 140.0, 420.0]:
		var point: Vector2 = origin + line_direction * float(offset)
		var normal: Vector2 = line_direction.rotated(PI * 0.5)
		draw_line(point - normal * 10.0, point + normal * 10.0, line_color, 2.0)
	if not label.is_empty():
		draw_string(Localization.ui_theme().default_font, origin + Vector2(-38, -8), Localization.text(label), HORIZONTAL_ALIGNMENT_CENTER, 76, 8, PAPER)


func _draw_redaction_stamp(center: Vector2, line_color: Color, fill_color: Color) -> void:
	var rect := Rect2(center - Vector2(radius, radius * 0.66), Vector2(radius * 2.0, radius * 1.32))
	draw_rect(rect, fill_color, true)
	draw_rect(rect, line_color, false, 3.0)
	draw_line(rect.position + Vector2(10, 15), Vector2(rect.end.x - 10, rect.position.y + 15), line_color, 3.0)
	draw_line(rect.position + Vector2(10, 31), Vector2(rect.end.x - 24, rect.position.y + 31), line_color, 3.0)
	draw_string(Localization.ui_theme().default_font, center + Vector2(-radius, 12), Localization.text("REDACT"), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 8, PAPER)


func _draw_canal(lane_y: float, flow_direction: Vector2, line_color: Color, fill_color: Color) -> void:
	var rect := Rect2(Vector2(ARENA_RECT.position.x, lane_y - 30.0), Vector2(ARENA_RECT.size.x, 60.0))
	draw_rect(rect, fill_color, true)
	draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), line_color, 3.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y), line_color, 3.0)
	for x in range(-580, 581, 80):
		var center := Vector2(x, lane_y)
		draw_line(center - flow_direction * 18.0, center + flow_direction * 18.0, line_color, 2.0)
		var wing := flow_direction.rotated(PI * 0.72) * 9.0
		draw_line(center + flow_direction * 18.0, center + flow_direction * 18.0 + wing, line_color, 2.0)


func _draw_cache(center: Vector2, line_color: Color, fill_color: Color) -> void:
	draw_circle(center, 28.0, fill_color)
	draw_arc(center, 28.0, 0.0, TAU, 28, line_color, 3.0)
	for index in range(8):
		var angle := visual_time * 1.8 + TAU * float(index) / 8.0
		draw_line(center + Vector2.from_angle(angle) * 18.0, center + Vector2.from_angle(angle) * 33.0, line_color, 2.0)
	draw_string(Localization.ui_theme().default_font, center + Vector2(-38, 4), Localization.text("CACHE"), HORIZONTAL_ALIGNMENT_CENTER, 76, 8, PAPER)


func _draw_gust(flow_direction: Vector2, line_color: Color) -> void:
	for x in range(-520, 521, 130):
		for y in range(-260, 261, 130):
			var center := Vector2(x, y)
			var start := center - flow_direction * 24.0
			var finish := center + flow_direction * 24.0
			draw_line(start, finish, line_color, 2.0)
			var wing_a := -flow_direction.rotated(0.65) * 10.0
			var wing_b := -flow_direction.rotated(-0.65) * 10.0
			draw_line(finish, finish + wing_a, line_color, 2.0)
			draw_line(finish, finish + wing_b, line_color, 2.0)
