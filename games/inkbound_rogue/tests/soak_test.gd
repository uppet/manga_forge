extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const TARGET_FRAMES := 1200
const MAX_STRESS_ENEMIES := 72
const MAX_SCENE_NODES := 1400
const MIN_AVERAGE_FPS := 90.0

var game: Node
var frames := 0
var peak_enemies := 0
var peak_pickups := 0
var peak_nodes := 0
var peak_memory_bytes := 0.0
var started_at_msec := 0
var failed := false
var configured := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("soak_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(12001200)


func _configure_run() -> void:
	game.run_started = true
	game.player.controls_enabled = false
	game.player.max_health = 999.0
	game.player.health = 999.0
	game.story_seen["act3_confrontation"] = true
	game._configure_contract("living-margins")
	game._activate_route("loose-leaves")
	for upgrade_id in ["razor-ink", "wide-panel", "rapid-stroke", "ink-wave", "crescendo", "afterimage-cut"]:
		game.debug_apply_upgrade(upgrade_id)
	started_at_msec = Time.get_ticks_msec()


func _process(_delta: float) -> bool:
	if failed or not is_instance_valid(game):
		return true
	if not configured:
		if not is_instance_valid(game.player):
			return false
		configured = true
		_configure_run()
		return false
	frames += 1
	_resolve_modal_state()
	if frames % 90 == 0 and game.wave < 13:
		game.elapsed = game.contract_wave_duration * float(game.wave) + 0.05
	if frames % 5 == 0:
		_stress_spawn()
	if frames % 8 == 0:
		_attack_nearest()
	if frames % 36 == 0:
		game.activate_combat_pickup("bomb")
	if frames % 120 == 0:
		game.activate_combat_pickup("magnet")
	elif frames % 120 == 30:
		game.activate_combat_pickup("hourglass")
	elif frames % 120 == 60:
		game.activate_combat_pickup("frenzy")

	var enemy_count := _owned_group_count("enemies")
	var pickup_count := _owned_group_count("pickups")
	peak_enemies = maxi(peak_enemies, enemy_count)
	peak_pickups = maxi(peak_pickups, pickup_count)
	peak_nodes = maxi(peak_nodes, _count_nodes(game))
	peak_memory_bytes = maxf(peak_memory_bytes, float(Performance.get_monitor(Performance.MEMORY_STATIC)))
	if enemy_count > MAX_STRESS_ENEMIES + 8:
		_fail("enemy population escaped the stress budget: %d" % enemy_count)
		return true
	if pickup_count > 260:
		_fail("uncollected drops escaped the stress budget")
		return true
	if frames >= TARGET_FRAMES:
		_finish()
		return true
	return false


func _resolve_modal_state() -> void:
	if game.choosing_relic:
		game.hud._choose_relic(0)
	elif game.choosing_upgrade:
		game.hud._choose_upgrade(0)
	elif game.choosing_event:
		game.hud._choose_event(1)
	elif paused:
		paused = false


func _stress_spawn() -> void:
	if _owned_group_count("enemies") >= MAX_STRESS_ENEMIES:
		return
	var kinds := ["mask", "dasher", "brute", "scribe", "splitter", "leech", "warden", "censor", "errata", "archivist", "blot", "duelist"]
	var kind: String = kinds[int(frames / 5) % kinds.size()]
	var angle := float(frames) * 0.47
	var distance := 82.0 + float((frames * 17) % 118)
	game.debug_spawn_enemy(kind, game.clamp_to_arena(game.player.global_position + Vector2.from_angle(angle) * distance, 24.0))


func _attack_nearest() -> void:
	var nearest: Node2D
	var nearest_distance := INF
	for enemy in get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get_parent() != game or not (enemy is Node2D):
			continue
		var distance: float = game.player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if is_instance_valid(nearest):
		game.player.debug_attack(nearest.global_position - game.player.global_position)


func _owned_group_count(group_name: StringName) -> int:
	var count := 0
	for node in get_nodes_in_group(group_name):
		if is_instance_valid(node) and node.get_parent() == game:
			count += 1
	return count


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _finish() -> void:
	_resolve_modal_state()
	var wall_seconds := maxf(0.001, float(Time.get_ticks_msec() - started_at_msec) / 1000.0)
	var average_fps := float(frames) / wall_seconds
	if game.wave < 12:
		_fail("accelerated run did not reach the final act")
		return
	if peak_enemies < 30:
		_fail("stress run never reached a representative horde")
		return
	if peak_nodes > MAX_SCENE_NODES:
		_fail("scene node population exceeded the soak budget: %d" % peak_nodes)
		return
	if peak_memory_bytes > 1024.0 * 1024.0 * 1024.0:
		_fail("static memory exceeded 1 GiB")
		return
	if average_fps < MIN_AVERAGE_FPS:
		_fail("average processing rate fell below %.0f fps: %.1f" % [MIN_AVERAGE_FPS, average_fps])
		return
	print("INKBOUND_SOAK_OK route=loose-leaves frames=%d wall=%.2fs avg_fps=%.1f peak_enemies=%d peak_pickups=%d peak_nodes=%d memory_mb=%.1f wave=%d kills=%d" % [frames, wall_seconds, average_fps, peak_enemies, peak_pickups, peak_nodes, peak_memory_bytes / 1048576.0, game.wave, game.kills])
	Engine.time_scale = 1.0
	paused = false
	game.debug_clear_save_files()
	game.free()
	quit(0)


func _fail(message: String) -> void:
	failed = true
	push_error("INKBOUND_SOAK_FAIL: " + message)
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(1)
