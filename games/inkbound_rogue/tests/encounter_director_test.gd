extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")

var started := false


func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run()
	return false


func _run() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail(null, "main scene did not load")
		return
	if Content.PAGE_DIRECTIVES.size() != 9 or Content.ENCOUNTER_SQUADS.size() != 9:
		_fail(null, "encounter catalog is not three directives and squads per act")
		return
	var kinds := {}
	for directive in Content.PAGE_DIRECTIVES:
		kinds[str(directive.get("kind", ""))] = true
	if kinds.size() != 4 or not kinds.has("kills") or not kinds.has("ink") or not kinds.has("elites") or not kinds.has("hold"):
		_fail(null, "four directive play styles are not represented")
		return
	print("INKBOUND_ENCOUNTERS_STAGE catalog")

	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("encounter_director_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(818181)
	_clear_enemies(game)
	game._on_start_requested("standard", "open-draft")
	if not game.run_started or game.encounter_started_wave != 1 or game.active_directive.is_empty() or game.active_squad_id.is_empty():
		_fail(game, "new run did not begin with a Page Directive and named squad")
		return
	if game.run_directives_started != 1 or not game.hud.directive_panel.visible:
		_fail(game, "directive HUD or run counter did not initialize")
		return
	print("INKBOUND_ENCOUNTERS_STAGE boot")

	for squad_data in Content.ENCOUNTER_SQUADS:
		_clear_enemies(game)
		var spawned: int = game.debug_spawn_squad(str(squad_data["id"]))
		if spawned != squad_data.get("members", []).size() or _enemy_count(game) != spawned:
			_fail(game, "named squad member count is wrong: " + str(squad_data["id"]))
			return
		if _elite_count(game) < int(squad_data.get("elites", 0)):
			_fail(game, "named squad elite composition is wrong: " + str(squad_data["id"]))
			return
		if int(squad_data.get("chapter", 0)) == 1:
			var ranged_members := 0
			for member in squad_data.get("members", []):
				if str(member) in ["scribe", "blot"]:
					ranged_members += 1
			if ranged_members > 2:
				_fail(game, "Act I squad exceeds its two-ranged-enemy onboarding budget: " + str(squad_data["id"]))
				return
	print("INKBOUND_ENCOUNTERS_STAGE squads")
	if not _validate_page_three_ranged_pressure(game):
		return
	print("INKBOUND_ENCOUNTERS_STAGE page3-ranged-pressure")

	_clear_enemies(game)
	var shards_before: int = game.run_shards
	if not game.debug_start_directive("redaction-quota"):
		_fail(game, "kill directive could not start")
		return
	game._advance_page_directive("kills", game.directive_target)
	if not game.directive_completed or game.run_shards < shards_before + 2:
		_fail(game, "kill directive did not complete and grant Memory")
		return
	print("INKBOUND_ENCOUNTERS_STAGE kills")

	var guard_before: float = game.player.guard
	game.debug_start_directive("loose-ink")
	for index in range(10):
		game.on_ink_collected(game.player.global_position)
	if not game.directive_completed or game.player.guard < guard_before + 3.0:
		_fail(game, "Ink recovery directive did not grant its Ward")
		return
	print("INKBOUND_ENCOUNTERS_STAGE ink")

	_clear_enemies(game)
	game.debug_start_directive("censor-cell")
	var elite_victims: Array = []
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game and bool(enemy.get("is_elite")):
			elite_victims.append(enemy)
	if elite_victims.size() < 2:
		_fail(game, "elite hunt did not guarantee enough marked targets")
		return
	elite_victims[0].die()
	elite_victims[1].die()
	if not game.directive_completed:
		_fail(game, "elite deaths did not advance the elite hunt")
		return
	print("INKBOUND_ENCOUNTERS_STAGE elites")

	var hold_guard_before: float = game.player.guard
	game.debug_start_directive("bindery-circle")
	if not is_instance_valid(game.directive_zone):
		_fail(game, "hold directive did not create a visible capture zone")
		return
	game._on_directive_zone_progress(game.directive_target, game.directive_target, true)
	game._on_directive_zone_completed()
	if not game.directive_completed or game.player.guard < hold_guard_before + 4.0:
		_fail(game, "hold directive did not complete and grant Ward")
		return
	print("INKBOUND_ENCOUNTERS_STAGE hold")

	game.debug_start_directive("whisper-circle")
	game._on_directive_zone_progress(3.25, game.directive_target, true)
	var payload: Dictionary = game._checkpoint_payload("encounter-test")
	if str(payload.get("active_directive", {}).get("id", "")) != "whisper-circle" or not is_equal_approx(float(payload.get("directive_progress", 0.0)), 3.25):
		_fail(game, "checkpoint payload omitted active directive progress")
		return
	print("INKBOUND_ENCOUNTERS_STAGE payload")
	var restored = packed.instantiate()
	restored.test_mode = true
	restored.debug_set_save_namespace("encounter_director_restore_test")
	restored.debug_clear_save_files()
	root.add_child(restored)
	if not restored._apply_checkpoint(payload):
		_fail(game, "checkpoint with a Page Directive could not be restored")
		return
	if str(restored.active_directive.get("id", "")) != "whisper-circle" or not is_equal_approx(restored.directive_progress, 3.25) or not is_instance_valid(restored.directive_zone):
		_fail(game, "Continue / Load did not restore directive and capture zone")
		return
	print("INKBOUND_ENCOUNTERS_STAGE restored")

	game.lifetime_directives_completed = 20
	game._evaluate_achievements(false)
	if "first-order" not in game.unlocked_achievements or "field-editor" not in game.unlocked_achievements:
		_fail(game, "persistent directive achievements did not unlock")
		return
	game.debug_start_directive("whisper-circle")
	if not is_instance_valid(game.directive_zone):
		_fail(game, "boss-page boundary setup did not create a directive zone")
		return
	game.encounter_started_wave = 0
	game._start_page_encounter(4)
	if not game.active_directive.is_empty() or game.hud.directive_panel.visible or is_instance_valid(game.directive_zone):
		_fail(game, "boss pages did not clear the previous timed Page Directive")
		return

	print("INKBOUND_ENCOUNTERS_OK directives=9 squads=9 kinds=4 rewards=5 checkpoint=ok achievements=2 boss_pages=clean page3_ranged=17pct projectile_cap=12 hostile_readability=cyan-ring")
	restored.debug_clear_save_files()
	restored.free()
	_cleanup(game, 0)


func _clear_enemies(game: Node) -> void:
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			enemy.free()


func _clear_projectiles(game: Node) -> void:
	for projectile in get_nodes_in_group("hostile_projectiles"):
		if is_instance_valid(projectile) and projectile.get_parent() == game:
			projectile.free()


func _validate_page_three_ranged_pressure(game: Node) -> bool:
	_clear_enemies(game)
	_clear_projectiles(game)
	game.wave = 3
	game.route_enemy_bias.clear()
	game.route_enemy_bias_chance = 0.0
	game.debug_set_rng_seed(330033)
	var counts := {}
	var sample_count := 2000
	for _index in range(sample_count):
		var kind: String = game._roll_enemy_kind()
		counts[kind] = int(counts.get(kind, 0)) + 1
	var ranged_ratio := float(int(counts.get("scribe", 0)) + int(counts.get("blot", 0))) / float(sample_count)
	var mask_ratio := float(int(counts.get("mask", 0))) / float(sample_count)
	if ranged_ratio < 0.13 or ranged_ratio > 0.21:
		_fail(game, "Page 3 ranged share %.3f escaped the 13%%..21%% onboarding band" % ranged_ratio)
		return false
	if mask_ratio < 0.58:
		_fail(game, "Page 3 mask share %.3f no longer anchors the melee roster" % mask_ratio)
		return false
	for forbidden_kind in ["censor", "splitter", "leech", "errata", "warden", "archivist", "duelist"]:
		if int(counts.get(forbidden_kind, 0)) > 0:
			_fail(game, "Page 3 natural roster leaked later enemy %s" % forbidden_kind)
			return false
	game.route_enemy_bias.assign(["scribe", "blot"])
	game.route_enemy_bias_chance = 0.44
	game.debug_set_rng_seed(330044)
	var routed_ranged := 0
	for _index in range(sample_count):
		if game._roll_enemy_kind() in ["scribe", "blot"]:
			routed_ranged += 1
	var routed_ranged_ratio := float(routed_ranged) / float(sample_count)
	if routed_ranged_ratio < 0.27 or routed_ranged_ratio > 0.38:
		_fail(game, "Page 3 ranged-route share %.3f escaped the 27%%..38%% authored band" % routed_ranged_ratio)
		return false
	game.route_enemy_bias.clear()
	game.route_enemy_bias_chance = 0.0

	var cap: int = game.hostile_projectile_limit(3)
	if cap != 12:
		_fail(game, "Page 3 hostile projectile cap drifted from twelve")
		return false
	for index in range(cap + 5):
		game.spawn_projectile(game.player.global_position + Vector2(180, index), Vector2.LEFT, 92.0)
	if game.active_hostile_projectile_count() != cap:
		_fail(game, "Page 3 projectile budget did not stop at twelve")
		return false
	var projectiles := get_nodes_in_group("hostile_projectiles")
	if projectiles.is_empty() or projectiles[0].get_script() != ProjectileScript or projectiles[0].z_index <= 8:
		_fail(game, "hostile projectiles lost their dedicated foreground layer")
		return false
	var texture: Texture2D = load("res://assets/generated/projectile.png")
	var image := texture.get_image()
	var has_cyan := false
	var has_pickup_red := false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			has_cyan = has_cyan or (color.g > 0.72 and color.b > 0.78 and color.r < 0.55)
			has_pickup_red = has_pickup_red or (color.r > 0.7 and color.g < 0.35 and color.b < 0.35)
	if not has_cyan or has_pickup_red:
		_fail(game, "hostile projectile sprite overlaps the crimson pickup color family")
		return false
	_clear_projectiles(game)
	return true


func _enemy_count(game: Node) -> int:
	var count := 0
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game:
			count += 1
	return count


func _elite_count(game: Node) -> int:
	var count := 0
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.get_parent() == game and bool(enemy.get("is_elite")):
			count += 1
	return count


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_ENCOUNTERS_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
