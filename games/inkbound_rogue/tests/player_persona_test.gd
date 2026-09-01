extends SceneTree

const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PlayerWaveScript = preload("res://scripts/player_wave.gd")
const FxScript = preload("res://scripts/comic_fx.gd")

const SIM_DELTA := 1.0 / 30.0
const TICKS_PER_FRAME := 10
const EXPECTED_ROWS := 48

const DIFFICULTIES := ["story", "standard", "redline"]
const STAGES := [
	{"id": "early", "wave": 1, "seconds": 7.0, "upgrade_count": 0, "enemies": ["mask", "mask", "mask", "dasher", "scribe"]},
	{"id": "page3-ranged", "wave": 3, "seconds": 9.0, "upgrade_count": 2, "enemies": ["mask", "mask", "dasher", "brute", "scribe", "scribe", "blot"]},
	{"id": "mid", "wave": 6, "seconds": 9.0, "upgrade_count": 6, "enemies": ["mask", "dasher", "brute", "scribe", "leech", "censor", "errata", "duelist"]},
	{"id": "late", "wave": 12, "seconds": 12.0, "upgrade_count": 12, "enemies": ["author", "mask", "dasher", "brute", "scribe", "warden", "errata", "blot", "duelist"]},
]

# These are behavioral models, not cosmetic loadouts. Reaction delay, aim error,
# preferred range, action commitment, and defensive timing all change how the
# same combat systems are exercised.
const PERSONAS := [
	{
		"id": "first-timer",
		"label": "FIRST-TIMER",
		"reaction": 0.56,
		"aim_error": 34.0,
		"preferred_range": 25.0,
		"move_efficiency": 0.62,
		"attack_intent": 0.62,
		"dodge_intent": 0.18,
		"art_intent": 0.24,
		"art_targets": 4,
		"upgrades": ["iron-gutter", "wide-panel", "razor-ink", "margin-magnet", "iron-gutter", "wide-panel", "razor-ink", "margin-magnet", "ghost-step", "living-footnote", "blood-annotation", "greatbrush"],
	},
	{
		"id": "blade-rusher",
		"label": "BLADE RUSHER",
		"reaction": 0.19,
		"aim_error": 12.0,
		"preferred_range": 21.0,
		"move_efficiency": 0.94,
		"attack_intent": 0.93,
		"dodge_intent": 0.42,
		"art_intent": 0.48,
		"art_targets": 3,
		"upgrades": ["razor-ink", "razor-ink", "razor-ink", "rapid-stroke", "rapid-stroke", "rapid-stroke", "red-thread", "bleeding-letters", "bleeding-letters", "dash-nova", "crescendo", "twin-stroke"],
	},
	{
		"id": "margin-kiter",
		"label": "MARGIN KITER",
		"reaction": 0.27,
		"aim_error": 9.0,
		"preferred_range": 45.0,
		"move_efficiency": 0.88,
		"attack_intent": 0.78,
		"dodge_intent": 0.76,
		"art_intent": 0.62,
		"art_targets": 3,
		"upgrades": ["razor-ink", "wide-panel", "rapid-stroke", "ghost-step", "ink-wave", "ghost-step", "razor-ink", "wide-panel", "rapid-stroke", "ink-wave", "returning-stroke", "seal-caster"],
	},
	{
		"id": "speedreader",
		"label": "SPEEDREADER",
		"reaction": 0.11,
		"aim_error": 3.5,
		"preferred_range": 34.0,
		"move_efficiency": 1.0,
		"attack_intent": 0.98,
		"dodge_intent": 0.9,
		"art_intent": 0.92,
		"art_targets": 2,
		"upgrades": ["razor-ink", "rapid-stroke", "living-ink", "quickscript", "violent-margin", "red-harvest", "razor-ink", "rapid-stroke", "living-ink", "quickscript", "echoed-panel", "twin-stroke"],
	},
]

var packed: PackedScene
var cases: Array[Dictionary] = []
var case_index := -1
var game: Node
var persona: Dictionary = {}
var difficulty_id := ""
var stage_index := -1
var applied_upgrades := 0
var rows: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

var stage_time := 0.0
var stage_metrics: Dictionary = {}
var tracked_enemy_health: Dictionary = {}
var reaction_timer := 0.0
var move_direction := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var previous_player_health := 0.0
var stage_start_kills := 0


func _initialize() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	packed = loaded
	for selected_difficulty in DIFFICULTIES:
		for selected_persona in PERSONAS:
			cases.append({"difficulty": selected_difficulty, "persona": selected_persona})


func _process(_delta: float) -> bool:
	paused = false
	if game == null:
		_start_next_case()
		if game == null:
			return false
	for _tick in range(TICKS_PER_FRAME):
		if game == null:
			break
		_step_simulation()
	_disable_automatic_processing()
	return false


func _start_next_case() -> void:
	case_index += 1
	if case_index >= cases.size():
		_finish_suite()
		return
	var case_data: Dictionary = cases[case_index]
	persona = case_data["persona"]
	difficulty_id = str(case_data["difficulty"])
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("persona_%s_%s" % [persona["id"], difficulty_id])
	game.debug_clear_save_files()
	root.add_child(game)
	# Keep each persona's random stream identical across difficulty settings so
	# comparisons measure tuning rather than a luckier elite/aim sequence.
	var persona_index := case_index % PERSONAS.size()
	var case_seed := 880000 + persona_index * 7919
	game.debug_set_rng_seed(case_seed)
	rng.seed = case_seed + 313
	game._on_start_requested("standard", "open-draft", "marginalia", 0)
	game._configure_difficulty(difficulty_id)
	game.player.controls_enabled = false
	if game.player.died.is_connected(game._on_player_died):
		game.player.died.disconnect(game._on_player_died)
	if game.player.leveled_up.is_connected(game._on_level_up):
		game.player.leveled_up.disconnect(game._on_level_up)
	game._expire_page_directive()
	_clear_combat_nodes()
	stage_index = -1
	applied_upgrades = 0
	_start_next_stage()


func _start_next_stage() -> void:
	stage_index += 1
	if stage_index >= STAGES.size():
		_finish_case()
		return
	var stage: Dictionary = STAGES[stage_index]
	_clear_combat_nodes()
	if is_instance_valid(game.cutscene) and game.cutscene.active:
		game.cutscene._hide()
	game.choosing_upgrade = false
	game.choosing_relic = false
	game.choosing_event = false
	game.game_over = false
	game.run_won = false
	game.manually_paused = false
	game.wave = int(stage["wave"])
	while applied_upgrades < int(stage["upgrade_count"]):
		game.player.apply_upgrade(str(persona["upgrades"][applied_upgrades]))
		applied_upgrades += 1
	game.player.global_position = Vector2.ZERO
	game.player.velocity = Vector2.ZERO
	game.player.health = game.player.max_health
	game.player.invulnerable_time = 0.0
	game.player.attack_cooldown = 0.0
	game.player.dash_cooldown = 0.0
	game.player.ink_art_cooldown = 0.0
	game.player.health_changed.emit(game.player.health, game.player.max_health)
	stage_time = 0.0
	reaction_timer = 0.0
	move_direction = Vector2.ZERO
	aim_direction = Vector2.RIGHT
	previous_player_health = game.player.health
	stage_start_kills = game.kills
	tracked_enemy_health.clear()
	stage_metrics = {
		"damage_dealt": 0.0,
		"damage_taken": 0.0,
		"attacks": 0,
		"ink_arts": 0,
		"dashes": 0,
		"threat_seconds": 0.0,
		"moving_seconds": 0.0,
		"initial_enemy_health": 0.0,
	}
	_spawn_stage_enemies(stage)
	_track_enemy_damage()
	stage_metrics["initial_enemy_health"] = _tracked_max_health()
	_disable_automatic_processing()


func _spawn_stage_enemies(stage: Dictionary) -> void:
	var enemy_ids: Array = stage["enemies"]
	for index in range(enemy_ids.size()):
		var angle := TAU * float(index) / float(enemy_ids.size()) + rng.randf_range(-0.16, 0.16)
		var distance := 72.0 + float((index * 29) % 92)
		if str(enemy_ids[index]) == "author":
			distance = 118.0
		game.debug_spawn_enemy(str(enemy_ids[index]), Vector2.from_angle(angle) * distance)


func _step_simulation() -> void:
	if game == null:
		return
	var stage: Dictionary = STAGES[stage_index]
	if game.player.health <= 0.0 or stage_time >= float(stage["seconds"]) or _live_enemies().is_empty():
		_finish_stage()
		return
	stage_time += SIM_DELTA
	reaction_timer -= SIM_DELTA
	if reaction_timer <= 0.0:
		_make_decision()
	if game.player.dash_time <= 0.0 and move_direction.length_squared() > 0.01:
		game.player.global_position += move_direction * game.player.move_speed * float(persona["move_efficiency"]) * SIM_DELTA
		game.player.global_position = game.clamp_to_arena(game.player.global_position, 18.0)
		stage_metrics["moving_seconds"] = float(stage_metrics["moving_seconds"]) + SIM_DELTA
	game.player._physics_process(SIM_DELTA)
	for enemy in _owned_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion() and not enemy.dead:
			enemy._physics_process(SIM_DELTA)
	for child in game.get_children().duplicate():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		var script = child.get_script()
		if script == ProjectileScript or script == PlayerWaveScript:
			child._physics_process(SIM_DELTA)
		elif script == PickupScript:
			child._process(SIM_DELTA)
	_track_enemy_damage()
	_track_incoming_damage()
	var nearest := _nearest_enemy()
	if is_instance_valid(nearest) and game.player.global_position.distance_to(nearest.global_position) < 42.0:
		stage_metrics["threat_seconds"] = float(stage_metrics["threat_seconds"]) + SIM_DELTA


func _make_decision() -> void:
	reaction_timer = float(persona["reaction"]) * rng.randf_range(0.86, 1.14)
	var enemies := _live_enemies()
	if enemies.is_empty():
		move_direction = Vector2.ZERO
		return
	var target: Node2D = _nearest_enemy()
	if persona["id"] == "first-timer" and enemies.size() > 1 and rng.randf() < 0.28:
		target = enemies[rng.randi_range(0, enemies.size() - 1)]
	var to_target: Vector2 = target.global_position - game.player.global_position
	var distance := to_target.length()
	var toward := to_target.normalized() if distance > 0.01 else Vector2.RIGHT
	var preferred := float(persona["preferred_range"])
	if distance > preferred + 8.0:
		move_direction = toward
	elif distance < preferred - 7.0:
		move_direction = -toward
	else:
		var strafe_sign := -1.0 if (int(stage_time / maxf(0.1, float(persona["reaction"]))) + case_index) % 2 == 0 else 1.0
		move_direction = toward.rotated(PI * 0.5 * strafe_sign)
	if persona["id"] == "first-timer":
		move_direction = move_direction.rotated(rng.randf_range(-0.55, 0.55))
	aim_direction = toward.rotated(deg_to_rad(rng.randf_range(-float(persona["aim_error"]), float(persona["aim_error"]))))
	if distance < 34.0 and rng.randf() < float(persona["dodge_intent"]):
		if game.player.start_dash((-toward + move_direction * 0.35).normalized()):
			stage_metrics["dashes"] = int(stage_metrics["dashes"]) + 1
	if game.player.ink_art_cooldown <= 0.0 and enemies.size() >= int(persona["art_targets"]) and rng.randf() < float(persona["art_intent"]):
		if game.player.perform_ink_art(aim_direction):
			stage_metrics["ink_arts"] = int(stage_metrics["ink_arts"]) + 1
	if distance <= game.player.attack_reach * 1.08 and rng.randf() < float(persona["attack_intent"]):
		if game.player.perform_attack(aim_direction):
			stage_metrics["attacks"] = int(stage_metrics["attacks"]) + 1


func _track_enemy_damage() -> void:
	for enemy in _owned_nodes_in_group("enemies"):
		var instance_id := enemy.get_instance_id()
		var current_health := maxf(0.0, float(enemy.health))
		if not tracked_enemy_health.has(instance_id):
			tracked_enemy_health[instance_id] = {"maximum": float(enemy.max_health), "previous": current_health}
			if not enemy.died.is_connected(_on_sim_enemy_died):
				enemy.died.connect(_on_sim_enemy_died)
			continue
		var tracked: Dictionary = tracked_enemy_health[instance_id]
		var previous := float(tracked["previous"])
		if current_health < previous:
			stage_metrics["damage_dealt"] = float(stage_metrics["damage_dealt"]) + previous - current_health
		tracked["previous"] = current_health
		tracked_enemy_health[instance_id] = tracked


func _on_sim_enemy_died(enemy: Node, _xp_value: int, _death_position: Vector2, _enemy_kind: String) -> void:
	var instance_id := enemy.get_instance_id()
	if not tracked_enemy_health.has(instance_id):
		return
	var tracked: Dictionary = tracked_enemy_health[instance_id]
	var previous := maxf(0.0, float(tracked["previous"]))
	stage_metrics["damage_dealt"] = float(stage_metrics["damage_dealt"]) + previous
	tracked["previous"] = 0.0
	tracked_enemy_health[instance_id] = tracked


func _track_incoming_damage() -> void:
	var current_health: float = float(game.player.health)
	if current_health < previous_player_health:
		stage_metrics["damage_taken"] = float(stage_metrics["damage_taken"]) + previous_player_health - current_health
	previous_player_health = current_health


func _tracked_max_health() -> float:
	var total := 0.0
	for tracked in tracked_enemy_health.values():
		total += float(tracked["maximum"])
	return total


func _finish_stage() -> void:
	_track_enemy_damage()
	_track_incoming_damage()
	var duration := maxf(SIM_DELTA, stage_time)
	var tracked_count := tracked_enemy_health.size()
	var defeated := 0
	for tracked in tracked_enemy_health.values():
		if float(tracked["previous"]) <= 0.01:
			defeated += 1
	var row := {
		"persona": str(persona["id"]),
		"difficulty": difficulty_id,
		"stage": str(STAGES[stage_index]["id"]),
		"wave": int(STAGES[stage_index]["wave"]),
		"simulated_seconds": duration,
		"survived": game.player.health > 0.0,
		"health_remaining_ratio": maxf(0.0, game.player.health) / maxf(1.0, game.player.max_health),
		"damage_dealt": float(stage_metrics["damage_dealt"]),
		"damage_per_second": float(stage_metrics["damage_dealt"]) / duration,
		"damage_taken": float(stage_metrics["damage_taken"]),
		"attacks": int(stage_metrics["attacks"]),
		"ink_arts": int(stage_metrics["ink_arts"]),
		"dashes": int(stage_metrics["dashes"]),
		"kills": game.kills - stage_start_kills,
		"tracked_enemies": tracked_count,
		"clear_ratio": float(defeated) / maxf(1.0, float(tracked_count)),
		"initial_enemy_health": _tracked_max_health(),
		"threat_ratio": float(stage_metrics["threat_seconds"]) / duration,
		"movement_ratio": float(stage_metrics["moving_seconds"]) / duration,
		"weapon_form": game.player.weapon_form,
		"upgrade_count": applied_upgrades,
	}
	rows.append(row)
	_start_next_stage()


func _finish_case() -> void:
	game.debug_clear_save_files()
	game.free()
	game = null


func _live_enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in _owned_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion() and not enemy.dead and enemy.health > 0.0:
			result.append(enemy)
	return result


func _nearest_enemy() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for enemy in _live_enemies():
		var distance: float = game.player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func _owned_nodes_in_group(group_name: StringName) -> Array[Node]:
	var result: Array[Node] = []
	if game == null:
		return result
	for node in get_nodes_in_group(group_name):
		if is_instance_valid(node) and node.get_parent() == game:
			result.append(node)
	return result


func _clear_combat_nodes() -> void:
	if game == null:
		return
	for child in game.get_children().duplicate():
		if not is_instance_valid(child):
			continue
		var script = child.get_script()
		if child.is_in_group("enemies") or child.is_in_group("pickups") or script == ProjectileScript or script == PlayerWaveScript or script == FxScript:
			child.free()


func _disable_automatic_processing() -> void:
	if game == null:
		return
	_disable_branch(game)


func _disable_branch(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		_disable_branch(child)


func _finish_suite() -> void:
	var failures: Array[String] = []
	if rows.size() != EXPECTED_ROWS:
		failures.append("produced %d rows instead of %d" % [rows.size(), EXPECTED_ROWS])
	for row in rows:
		if not is_finite(float(row["damage_per_second"])) or float(row["damage_dealt"]) <= 0.0:
			failures.append("%s/%s/%s dealt no valid damage" % [row["persona"], row["difficulty"], row["stage"]])
		if float(row["simulated_seconds"]) <= 0.0 or int(row["tracked_enemies"]) <= 0:
			failures.append("%s/%s/%s did not simulate an encounter" % [row["persona"], row["difficulty"], row["stage"]])
	for selected_persona in PERSONAS:
		var persona_attacks := 0
		for row in rows:
			if row["persona"] == selected_persona["id"]:
				persona_attacks += int(row["attacks"])
		if persona_attacks <= 0:
			failures.append("%s never attacked" % selected_persona["id"])
	var page3_standard_survivors := 0
	var page3_first_timer_survived := false
	for row in rows:
		if row["stage"] != "page3-ranged" or row["difficulty"] != "standard":
			continue
		if bool(row["survived"]):
			page3_standard_survivors += 1
		if row["persona"] == "first-timer":
			page3_first_timer_survived = bool(row["survived"])
	if page3_standard_survivors < 3:
		failures.append("Page 3 ranged pressure defeats more than one Standard persona")
	if not page3_first_timer_survived:
		failures.append("first-timer persona does not survive Standard Page 3 ranged pressure")
	var report := {
		"schema": 1,
		"model": "accelerated behavior personas driving live Godot combat nodes",
		"limitations": "Measures decision patterns and balance pressure; it does not replace human controller feel, readability, accessibility, or enjoyment testing.",
		"personas": _persona_report(),
		"difficulties": DIFFICULTIES,
		"stages": STAGES.map(func(stage): return {"id": stage["id"], "wave": stage["wave"], "seconds": stage["seconds"], "upgrade_count": stage["upgrade_count"]}),
		"rows": rows,
		"summary": _summary_report(),
		"observations": _observations(),
		"failures": failures,
	}
	_write_report(report)
	var standard_summary: Dictionary = report["summary"]["difficulty"]["standard"]
	var page3_summary: Dictionary = report["summary"]["stage"]["page3-ranged"]
	print("INKBOUND_PERSONA_SUMMARY rows=%d standard_clear=%.2f standard_survival=%.2f standard_dps=%.2f page3_survival=%.2f observations=%d" % [rows.size(), float(standard_summary["clear_ratio"]), float(standard_summary["survival_ratio"]), float(standard_summary["damage_per_second"]), float(page3_summary["survival_ratio"]), report["observations"].size()])
	if not failures.is_empty():
		_fail(" | ".join(failures.slice(0, mini(8, failures.size()))))
		return
	print("INKBOUND_PERSONA_OK personas=4 difficulties=3 stages=%d rows=%d report=res://build/playtest/player-persona-report.json" % [STAGES.size(), rows.size()])
	paused = false
	quit(0)


func _persona_report() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in PERSONAS:
		result.append({
			"id": entry["id"],
			"label": entry["label"],
			"reaction_seconds": entry["reaction"],
			"aim_error_degrees": entry["aim_error"],
			"preferred_range": entry["preferred_range"],
			"move_efficiency": entry["move_efficiency"],
			"attack_intent": entry["attack_intent"],
			"dodge_intent": entry["dodge_intent"],
			"ink_art_intent": entry["art_intent"],
			"build": entry["upgrades"],
		})
	return result


func _summary_report() -> Dictionary:
	var summary := {"persona": {}, "difficulty": {}, "stage": {}, "growth": {}}
	for entry in PERSONAS:
		summary["persona"][entry["id"]] = _aggregate_rows("persona", str(entry["id"]))
	for selected_difficulty in DIFFICULTIES:
		summary["difficulty"][selected_difficulty] = _aggregate_rows("difficulty", selected_difficulty)
	for stage in STAGES:
		summary["stage"][stage["id"]] = _aggregate_rows("stage", str(stage["id"]))
	for entry in PERSONAS:
		var persona_id := str(entry["id"])
		var early_dps := _row_value(persona_id, "standard", "early", "damage_per_second")
		var late_dps := _row_value(persona_id, "standard", "late", "damage_per_second")
		summary["growth"][persona_id] = late_dps / maxf(0.001, early_dps)
	return summary


func _aggregate_rows(field: String, value: String) -> Dictionary:
	var count := 0
	var clear_total := 0.0
	var survival_total := 0.0
	var dps_total := 0.0
	var damage_taken_total := 0.0
	for row in rows:
		if str(row[field]) != value:
			continue
		count += 1
		clear_total += float(row["clear_ratio"])
		survival_total += 1.0 if bool(row["survived"]) else 0.0
		dps_total += float(row["damage_per_second"])
		damage_taken_total += float(row["damage_taken"])
	return {
		"samples": count,
		"clear_ratio": clear_total / maxf(1.0, float(count)),
		"survival_ratio": survival_total / maxf(1.0, float(count)),
		"damage_per_second": dps_total / maxf(1.0, float(count)),
		"damage_taken": damage_taken_total / maxf(1.0, float(count)),
	}


func _row_value(persona_id: String, selected_difficulty: String, stage_id: String, field: String) -> float:
	for row in rows:
		if row["persona"] == persona_id and row["difficulty"] == selected_difficulty and row["stage"] == stage_id:
			return float(row[field])
	return 0.0


func _observations() -> Array[String]:
	var result: Array[String] = []
	var summary := _summary_report()
	for entry in PERSONAS:
		var persona_id := str(entry["id"])
		var growth := float(summary["growth"][persona_id])
		if growth < 1.15:
			result.append("%s late-game DPS growth is only %.2fx; inspect upgrade comprehension or synergy." % [persona_id, growth])
		var persona_summary: Dictionary = summary["persona"][persona_id]
		if float(persona_summary["survival_ratio"]) < 0.67:
			result.append("%s survival is below 67%%; its preferred engagement pattern is too brittle." % persona_id)
		if float(persona_summary["clear_ratio"]) < 0.55:
			result.append("%s clears under 55%% of encounter health; review reach, guidance, or build readability." % persona_id)
	var story: Dictionary = summary["difficulty"]["story"]
	var standard: Dictionary = summary["difficulty"]["standard"]
	var redline: Dictionary = summary["difficulty"]["redline"]
	if float(story["survival_ratio"]) < 0.75:
		result.append("Story survival is below 75%% across personas; onboarding pressure may be too high.")
	if float(redline["clear_ratio"]) >= float(story["clear_ratio"]):
		result.append("Redline clear ratio is not below Story; encounter duration or avoidance may mask difficulty pressure.")
	if float(standard["damage_taken"]) > float(story["damage_taken"]) * 1.8:
		result.append("Standard incoming damage jumps sharply from Story; review the first difficulty step.")
	if result.is_empty():
		result.append("No automated balance warning crossed the current broad persona thresholds.")
	return result


func _write_report(report: Dictionary) -> void:
	var directory := ProjectSettings.globalize_path("res://build/playtest")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open("res://build/playtest/player-persona-report.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.flush()


func _fail(message: String) -> void:
	push_error("INKBOUND_PERSONA_FAIL: " + message)
	Engine.time_scale = 1.0
	paused = false
	if game != null and is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(1)
