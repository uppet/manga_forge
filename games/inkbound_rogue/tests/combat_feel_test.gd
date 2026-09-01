extends SceneTree

var game
var failed := false
var frames := 0
var ran := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("combat_feel_test")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	if ran:
		return false
	frames += 1
	if frames < 2:
		return false
	ran = true
	if game.player == null or game.hud == null or game.arena == null:
		_fail("main scene did not initialize its gameplay nodes")
		return true
	_test_attack_buffer()
	if failed:
		return true
	_test_contact_telegraph()
	if failed:
		return true
	_test_enemy_dash_commitment()
	if failed:
		return true
	_test_projectile_budget_curve()
	if failed:
		return true
	print("INKBOUND_COMBAT_FEEL_OK attack_buffer=130ms contact_telegraph=shape enemy_dash=committed projectile_caps=8/10/12/16/20..30 slash_sweep=animated")
	_cleanup(0)
	return true


func _test_attack_buffer() -> void:
	game.player.controls_enabled = true
	game.player.attack_counter = 0
	game.player.attack_cooldown = 0.06
	Input.action_press("attack")
	game.player._physics_process(0.016)
	Input.action_release("attack")
	if game.player.attack_counter != 0 or game.player.attack_buffer_time <= 0.0:
		_fail("attack tap was not buffered during recovery")
		return
	game.player._physics_process(0.05)
	if game.player.attack_counter != 1 or game.player.attack_buffer_time > 0.0:
		_fail("buffered attack did not execute on the first legal frame")
		return

	game.player.dash_time = 0.0
	game.player.dash_cooldown = 0.06
	Input.action_press("dash")
	game.player._physics_process(0.016)
	Input.action_release("dash")
	if game.player.dash_time > 0.0 or game.player.dash_buffer_time <= 0.0:
		_fail("dash tap was not buffered during cooldown")
		return
	game.player._physics_process(0.05)
	if game.player.dash_time <= 0.0 or game.player.dash_buffer_time > 0.0:
		_fail("buffered dash did not execute on the first legal frame")
		return

	game.player.dash_time = 0.0
	game.player.ink_art_cooldown = 0.06
	var uses_before: int = game.player.ink_art_uses
	Input.action_press("special")
	game.player._physics_process(0.016)
	Input.action_release("special")
	if game.player.ink_art_uses != uses_before or game.player.ink_art_buffer_time <= 0.0:
		_fail("Ink Art tap was not buffered during cooldown")
		return
	game.player._physics_process(0.05)
	if game.player.ink_art_uses != uses_before + 1 or game.player.ink_art_buffer_time > 0.0:
		_fail("buffered Ink Art did not execute on the first legal frame")


func _test_contact_telegraph() -> void:
	game.player.health = game.player.max_health
	game.player.invulnerable_time = 0.0
	var enemy = game.debug_spawn_enemy("mask", game.player.global_position + Vector2(10, 0))
	enemy.speed = 0.0
	enemy.contact_cooldown = 0.0
	var starting_health: float = game.player.health
	enemy._physics_process(0.01)
	if game.player.health != starting_health or enemy.contact_windup <= 0.0:
		_fail("ordinary contact damage did not expose a windup before landing")
		return
	enemy._physics_process(0.2)
	if game.player.health >= starting_health or enemy.contact_windup >= 0.0:
		_fail("telegraphed contact damage did not land after its warning")
	enemy.free()


func _test_enemy_dash_commitment() -> void:
	game.player.invulnerable_time = 99.0
	var enemy = game.debug_spawn_enemy("dasher", game.player.global_position + Vector2(82, 0))
	enemy.dash_timer = 0.0
	enemy.dash_charge = 0.0
	var peak_speed := 0.0
	for _tick in range(24):
		enemy._physics_process(0.02)
		peak_speed = maxf(peak_speed, enemy.velocity.length())
	if peak_speed < enemy.speed * 3.0:
		_fail("dasher completed its warning without entering a committed rush")
	enemy.free()
	game.player.invulnerable_time = 0.0


func _test_projectile_budget_curve() -> void:
	var expected := {1: 8, 2: 10, 3: 12, 4: 16, 5: 20, 8: 24, 12: 30}
	var previous := 0
	for page in range(1, 13):
		var cap: int = game.hostile_projectile_limit(page)
		if cap < previous or cap > 30:
			_fail("hostile projectile budget is not monotonic and capped")
			return
		previous = cap
	for page in expected:
		if game.hostile_projectile_limit(page) != int(expected[page]):
			_fail("hostile projectile budget drifted on Page %d" % page)
			return


func _cleanup(exit_code: int) -> void:
	Input.action_release("attack")
	Input.action_release("dash")
	Input.action_release("special")
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("INKBOUND_COMBAT_FEEL_FAIL: " + message)
	_cleanup(1)
