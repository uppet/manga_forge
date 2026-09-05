extends SceneTree

var game: Node
var frames := 0
var stage := 0


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("capture_enemy_attacks")
	game.debug_clear_save_files()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	match stage:
		0:
			paused = false
			game.application_focused = true
			game.manually_paused = false
			game.hud._hide_popup_immediate(game.hud.pause_panel)
			_clear_combatants()
			game.player.global_position = Vector2.ZERO
			game.player.controls_enabled = false
			game.player.invulnerable_time = 99.0
			var brute = game.debug_spawn_enemy("brute", Vector2(17, 0))
			brute.speed = 0.0
			brute._begin_contact_attack(Vector2.LEFT)
			brute.contact_windup = 0.0
			brute._land_contact_attack(Vector2.LEFT)
			brute._update_visual(0.08, Vector2.LEFT)
			_seek_attack_fx(0.08)
			game.process_mode = Node.PROCESS_MODE_DISABLED
			stage = 1
		1:
			if not _capture("last-inkwarden-enemy-melee-hitbox.png"):
				return true
			game.process_mode = Node.PROCESS_MODE_PAUSABLE
			_clear_combatants()
			var scribe = game.debug_spawn_enemy("scribe", Vector2(102, 0))
			scribe.speed = 0.0
			scribe._begin_attack_keyframes("cast", Vector2.LEFT)
			scribe.shoot_projectiles(Vector2.LEFT)
			scribe._update_visual(0.08, Vector2.LEFT)
			_seek_attack_fx(0.07)
			game.process_mode = Node.PROCESS_MODE_DISABLED
			stage = 2
		2:
			if not _capture("last-inkwarden-enemy-ranged-release.png"):
				return true
			print("INKBOUND_ENEMY_ATTACK_CAPTURE_OK frames=strike melee_fx=hitbox_arc ranged_fx=projectile_vector size=%dx%d" % [root.get_texture().get_width(), root.get_texture().get_height()])
			_cleanup(0)
			return true
	return false


func _clear_combatants() -> void:
	for node in game.get_children():
		if node.is_in_group("enemies") or node.is_in_group("hostile_projectiles") or node is ComicFX:
			node.free()


func _seek_attack_fx(time_seconds: float) -> void:
	for node in game.get_children():
		if node is ComicFX:
			node.age = minf(time_seconds, node.lifetime * 0.8)
			node.queue_redraw()


func _capture(filename: String) -> bool:
	var output_dir := ProjectSettings.globalize_path("res://build/captures/enemy-attacks")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	if image == null:
		_fail("viewport texture unavailable")
		return false
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		_fail("save_png error %d" % result)
		return false
	return true


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)


func _fail(message: String) -> void:
	push_error("INKBOUND_ENEMY_ATTACK_CAPTURE_FAIL: " + message)
	_cleanup(1)
