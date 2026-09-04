extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var started := false


func _process(_delta: float) -> bool:
	if not started:
		started = true
		_run_smoke_test()
	return false


func _fail(message: String) -> void:
	push_error("INKBOUND_SMOKE_FAIL: " + message)
	Engine.time_scale = 1.0
	paused = false
	quit(1)


func _run_smoke_test() -> void:
	var packed = load("res://scenes/main.tscn")
	if packed == null or not (packed is PackedScene):
		_fail("main scene did not load")
		return
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("smoke_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(424242)
	if game.player == null or game.hud == null or game.arena == null:
		_fail("core runtime nodes are missing")
		return
	if game.hud.xp_bar.size.y > 3.0 or game.hud.hp_bar.size.y > 8.0:
		_fail("pixel HUD bars exceed their readability budget (HP %.1f px, XP %.1f px)" % [game.hud.hp_bar.size.y, game.hud.xp_bar.size.y])
		return
	if game.hud.top_panel.color.a > 0.75 or game.hud.ink_art_panel.color.a > 0.8 or game.hud.directive_panel.color.a > 0.8 or game.hud.upgrade_panel.color.a > 0.92:
		_fail("combat HUD or paused choice panels lost their translucent treatment")
		return
	game._on_bindings_reset_requested()

	var gamepad_actions := [
		"move_left", "move_right", "move_up", "move_down",
		"aim_left", "aim_right", "aim_up", "aim_down",
		"attack", "dash", "special", "pause", "options", "restart",
		"manual", "restoration", "proof_ledger", "daily_chronicle",
		"contract_prev", "contract_next",
		"upgrade_1", "upgrade_2", "upgrade_3", "upgrade_4",
	]
	var input_event_counts := {}
	for action in gamepad_actions:
		if not _has_gamepad_event(action):
			_fail("gamepad binding missing for " + action)
			return
		input_event_counts[action] = InputMap.action_get_events(action).size()
	game._ensure_input_actions()
	for action in gamepad_actions:
		if InputMap.action_get_events(action).size() != input_event_counts[action]:
			_fail("input setup duplicated events for " + action)
			return
	if not _has_gamepad_button("attack", JOY_BUTTON_X) or not _has_gamepad_axis("attack", JOY_AXIS_TRIGGER_RIGHT, 1.0):
		_fail("slash is not mapped to X/Square and right trigger")
		return
	if not _has_gamepad_button("dash", JOY_BUTTON_A) or not _has_gamepad_button("dash", JOY_BUTTON_LEFT_SHOULDER):
		_fail("dash is not mapped to A/Cross and left shoulder")
		return
	if not _has_gamepad_button("special", JOY_BUTTON_B) or not _has_keyboard_key("special", KEY_E):
		_fail("Ink Art is not mapped to E and B/Circle")
		return
	if not _has_gamepad_axis("manual", JOY_AXIS_TRIGGER_LEFT, 1.0) or not _has_keyboard_key("manual", KEY_F1):
		_fail("Field Manual is not mapped to F1 and the left trigger")
		return
	if not _has_gamepad_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0) or not _has_gamepad_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0):
		_fail("right-stick aim axes are incomplete")
		return
	if not _has_gamepad_axis("upgrade_4", JOY_AXIS_TRIGGER_RIGHT, 1.0):
		_fail("fourth upgrade choice is not mapped to right trigger")
		return
	if not _has_gamepad_button("options", JOY_BUTTON_BACK):
		_fail("options are not mapped to the gamepad View/Back button")
		return
	if not _has_gamepad_button("contract_prev", JOY_BUTTON_LEFT_SHOULDER) or not _has_gamepad_button("contract_next", JOY_BUTTON_RIGHT_SHOULDER):
		_fail("contract selection is not mapped to both shoulder buttons")
		return
	if not _has_gamepad_button("restoration", JOY_BUTTON_RIGHT_STICK) or not _has_keyboard_key("restoration", KEY_M):
		_fail("Restoration Board is not mapped to M and right-stick click")
		return
	if not _has_gamepad_button("proof_ledger", JOY_BUTTON_LEFT_STICK) or not _has_keyboard_key("proof_ledger", KEY_P):
		_fail("Proof Ledger is not mapped to P and left-stick click")
		return
	if not _has_gamepad_button("daily_chronicle", JOY_BUTTON_DPAD_DOWN) or not _has_keyboard_key("daily_chronicle", KEY_T):
		_fail("Daily Chronicle is not mapped to T and D-pad Down")
		return
	game._set_input_mode(true)
	if not game.using_gamepad or not game.player.using_gamepad or not game.hud.using_gamepad:
		_fail("gamepad mode did not propagate to runtime nodes")
		return
	var start_event := InputEventJoypadButton.new()
	start_event.button_index = JOY_BUTTON_START
	start_event.pressed = true
	game.hud._unhandled_input(start_event)
	if not game.manually_paused or not paused:
		_fail("Start did not pause the run")
		return
	if game.can_process() or game.player.can_process():
		_fail("manual pause left the gameplay root or player processing")
		return
	for paused_enemy in game.get_tree().get_nodes_in_group("enemies"):
		if paused_enemy.can_process():
			_fail("manual pause left an enemy processing")
			return
	if not game.hud.can_process():
		_fail("manual pause also disabled the always-responsive HUD")
		return
	game.hud.debug_finish_popup_transition()
	var start_release := InputEventJoypadButton.new()
	start_release.button_index = JOY_BUTTON_START
	start_release.pressed = false
	game.hud._unhandled_input(start_release)
	game.hud._unhandled_input(start_event)
	if game.manually_paused or paused:
		_fail("Start did not resume the run")
		return
	game.hud._unhandled_input(start_release)
	game.hud.show_manual(4)
	game.hud.debug_finish_popup_transition()
	if not game.manual_open or not game.hud.manual_visible or not paused or game.hud.FIELD_MANUAL_PAGES.size() != 5:
		_fail("Field Manual did not enter its paused five-page modal state")
		return
	if game.hud.manual_body_label.text.find("Godot Engine") < 0 or game.hud.manual_body_label.text.find("THIRD_PARTY_NOTICES.txt") < 0:
		_fail("in-game credits and legal summary are missing")
		return
	game.hud.hide_manual()
	game.hud.debug_finish_popup_transition()
	if game.manual_open or paused:
		_fail("closing the Field Manual did not resume gameplay")
		return
	game._on_level_up(game.player.level)
	if not game.choosing_upgrade or not paused or not game.hud.upgrade_visible:
		_fail("level-up choice did not enter its paused selection state")
		return
	if not game.hud.upgrade_transitioning or game.hud.upgrade_transition_phase != "opening" or game.hud.upgrade_panel.scale.x >= 1.0 or game.hud.upgrade_panel.modulate.a >= 1.0:
		_fail("upgrade panel did not begin its elastic fade-in")
		return
	if not game.hud.upgrade_buttons[0].disabled:
		_fail("upgrade input was not locked during the opening transition")
		return
	game.hud.debug_finish_upgrade_transition()
	if game.hud.upgrade_transitioning or not game.hud.upgrade_panel.scale.is_equal_approx(Vector2.ONE) or not is_equal_approx(game.hud.upgrade_panel.modulate.a, 1.0) or game.hud.upgrade_buttons[0].disabled:
		_fail("upgrade opening transition did not settle into an interactive modal")
		return
	if game.hud.upgrade_input_labels.size() != 4 or game.hud.upgrade_name_labels.size() != 4 or game.hud.upgrade_description_labels.size() != 4 or game.hud.upgrade_rarity_labels.size() != 4:
		_fail("upgrade cards are missing their isolated text regions")
		return
	if not game.hud.upgrade_buttons[0].visible or game.hud.upgrade_buttons[3].visible:
		_fail("three-choice upgrade draft did not hide the unused fourth card")
		return
	if game.hud.upgrade_buttons[0].position.y != game.hud.upgrade_buttons[1].position.y or game.hud.upgrade_buttons[2].position.y != game.hud.upgrade_buttons[3].position.y or game.hud.upgrade_buttons[0].position.y >= game.hud.upgrade_buttons[2].position.y:
		_fail("upgrade cards are not arranged as two readable rows")
		return
	for card_index in range(4):
		var card: Button = game.hud.upgrade_buttons[card_index]
		var name_label: RichTextLabel = game.hud.upgrade_name_labels[card_index]
		var description_label: RichTextLabel = game.hud.upgrade_description_labels[card_index]
		var rarity_label: RichTextLabel = game.hud.upgrade_rarity_labels[card_index]
		if not card.clip_contents or description_label.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
			_fail("upgrade description is not bounded with smart wrapping")
			return
		if name_label.position.y + name_label.size.y > description_label.position.y or description_label.position.y + description_label.size.y > rarity_label.position.y or rarity_label.position.y + rarity_label.size.y > card.size.y:
			_fail("upgrade regions overlap on card %d: name=(%.1f,%.1f) description=(%.1f,%.1f) rarity=(%.1f,%.1f) card=%.1f" % [card_index, name_label.position.y, name_label.size.y, description_label.position.y, description_label.size.y, rarity_label.position.y, rarity_label.size.y, card.size.y])
			return
	if game.can_process() or game.player.can_process():
		_fail("upgrade selection left the gameplay root or player processing")
		return
	for paused_enemy in game.get_tree().get_nodes_in_group("enemies"):
		if paused_enemy.can_process():
			_fail("upgrade selection left an enemy processing")
			return
	game.hud._choose_upgrade(0)
	if not game.choosing_upgrade or not paused or not game.hud.upgrade_visible or not game.hud.upgrade_transitioning or game.hud.upgrade_transition_phase != "closing":
		_fail("upgrade choice did not retain modal pause for its elastic close")
		return
	game.hud.debug_finish_upgrade_transition()
	if game.choosing_upgrade or paused or game.hud.upgrade_visible:
		_fail("upgrade selection did not resume gameplay after choosing")
		return
	game._set_input_mode(false)
	var vibration_before := bool(game.settings["vibration"])
	game.hud.show_settings()
	game.hud.debug_finish_popup_transition()
	if not game.hud.settings_visible or game.hud.settings_buttons.size() != game.hud.SETTINGS_ROWS.size():
		_fail("controller-accessible settings panel did not open")
		return
	var assist_before := float(game.settings["aim_assist"])
	game.hud._adjust_setting("aim_assist", 1)
	if is_equal_approx(float(game.settings["aim_assist"]), assist_before):
		_fail("controller aim-assist adjustment did not propagate")
		return
	game.hud._adjust_setting("aim_assist", -1)
	game.hud._adjust_setting("vibration", 1)
	if bool(game.settings["vibration"]) == vibration_before:
		_fail("settings adjustment did not propagate to the game runtime")
		return
	game.hud._adjust_setting("vibration", 1)
	game.hud.hide_settings()
	game.hud.debug_finish_popup_transition()
	game.hud.show_bindings()
	game.hud.debug_finish_popup_transition()
	if not game.hud.bindings_visible or game.hud.binding_buttons.size() != 18:
		_fail("runtime binding editor did not open with keyboard and gamepad slots")
		return
	game.hud._begin_rebind("attack", "keyboard")
	var remap_key := InputEventKey.new()
	remap_key.physical_keycode = KEY_L
	remap_key.pressed = true
	game.hud._unhandled_input(remap_key)
	if not _has_keyboard_key("attack", KEY_L) or not game.custom_bindings.has("attack"):
		_fail("keyboard rebind capture did not update InputMap and persistent data")
		return
	game.hud._begin_rebind("dash", "gamepad")
	var remap_button := InputEventJoypadButton.new()
	remap_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	remap_button.pressed = true
	game.hud._unhandled_input(remap_button)
	if not _has_gamepad_button("dash", JOY_BUTTON_RIGHT_SHOULDER):
		_fail("gamepad rebind capture did not update InputMap")
		return
	game._on_bindings_reset_requested()
	if not _has_keyboard_key("attack", KEY_J) or not _has_gamepad_button("dash", JOY_BUTTON_A) or not _has_keyboard_key("special", KEY_E) or not _has_gamepad_button("special", JOY_BUTTON_B) or not game.custom_bindings.is_empty():
		_fail("reset bindings did not restore the complete default layout")
		return
	game.hud.hide_bindings()
	game.hud.debug_finish_popup_transition()
	game.hud.hide_settings()
	game.hud.debug_finish_popup_transition()

	if Content.STORY.size() < 7 or Content.UPGRADES.size() < 36 or Content.RELICS.size() < 12 or Content.STARTING_WEAPONS.size() != 5 or Content.ENEMIES.size() < 15 or Content.CONTRACTS.size() < 6 or Content.EVENTS.size() < 9 or Content.ROUTES.size() < 9 or Content.ACHIEVEMENTS.size() < 19 or Content.PROGRESSION_UNLOCKS.size() < 13 or Content.PAGE_DIRECTIVES.size() < 9 or Content.ENCOUNTER_SQUADS.size() < 9 or Content.PROOF_LEVELS.size() != 11:
		_fail("release content database is below the minimum narrative/build variety")
		return
	var version_file := FileAccess.open("res://release/version.json", FileAccess.READ)
	var version_data = JSON.parse_string(version_file.get_as_text()) if version_file != null else null
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not (version_data is Dictionary) or str(version_data.get("version", "")) != project_version or int(version_data.get("save_schema", -1)) != game.SAVE_SCHEMA or int(version_data.get("checkpoint_schema", -1)) != game.CHECKPOINT_SCHEMA:
		_fail("project, release, and save-schema version identities do not match")
		return
	var export_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	var export_text := export_file.get_as_text() if export_file != null else ""
	if export_text.find('application/product_version="%s"' % project_version) < 0:
		_fail("Windows export product version does not match the project version")
		return
	var steam_ids := {}
	for achievement in Content.ACHIEVEMENTS:
		var steam_id: String = achievement.get("steam_id", "")
		if steam_id.is_empty() or steam_ids.has(steam_id) or int(achievement.get("target", 0)) <= 0:
			_fail("achievement metadata has a missing/duplicate Steam ID or invalid target")
			return
		steam_ids[steam_id] = true
	for event_data in Content.EVENTS:
		if event_data.get("options", []).size() != 3:
			_fail("chapter event does not provide three risk/reward choices")
			return
	for chapter in range(1, 4):
		if Content.routes_for_chapter(chapter).size() != 3:
			_fail("chapter route draft does not provide three paths")
			return
	var smoke_hazards := {}
	for route_data in Content.ROUTES:
		var smoke_hazard_id := str(route_data.get("hazard", ""))
		if smoke_hazard_id.is_empty() or smoke_hazards.has(smoke_hazard_id) or str(route_data.get("hazard_hint", "")).is_empty():
			_fail("route battlefield rule metadata is missing or duplicated")
			return
		smoke_hazards[smoke_hazard_id] = true
	if smoke_hazards.size() != 9 or not is_instance_valid(game.route_hazard):
		_fail("route hazard runtime does not cover all nine paths")
		return
	game._configure_contract("living-margins")
	if game.contract_spawn_interval >= 1.0 or game.contract_enemy_cap <= 1.0 or game.contract_score_multiplier <= 1.0:
		_fail("challenge contract did not configure its run modifiers")
		return
	game._configure_contract("open-draft")
	var story_panel_count := 0
	var story_images := {}
	for sequence in Content.STORY.values():
		story_panel_count += sequence["panels"].size()
		var image_path := str(sequence.get("image", ""))
		if image_path.is_empty() or story_images.has(image_path) or not FileAccess.file_exists(image_path):
			_fail("cutscene art is missing or reused: " + image_path)
			return
		story_images[image_path] = true
	if story_panel_count != 28 or story_images.size() != 7 or Content.STORY["ending_choice"].get("choices", []).size() != 2:
		_fail("complete branching story content is missing panels or endings")
		return
	if not game.debug_play_story("prologue") or not game.cutscene.active or game.cutscene.art.texture == null or game.cutscene.focus_art.texture == null:
		_fail("2D cutscene runtime did not start with its project-bound art")
		return
	game.cutscene.debug_complete()
	if game.cutscene.active:
		_fail("cutscene runtime did not complete")
		return
	game.lifetime_runs = 1
	game.highest_wave = 4
	game.hud.show_title(game._meta_snapshot())
	if not game.hud.title_visible or game.hud.title_stats_label.text.is_empty():
		_fail("title and persistent progression presentation did not open")
		return
	if game.hud.title_navigation_buttons.size() != game.hud.title_navigation_actions.size() or game.hud.title_navigation_buttons.size() < 12 or not game.hud.title_navigation_cursor.visible:
		_fail("title screen is missing its visible controller navigation model")
		return
	var title_navigation_before: int = game.hud.title_navigation_index
	var title_down := InputEventJoypadButton.new()
	title_down.button_index = JOY_BUTTON_DPAD_DOWN
	title_down.pressed = true
	game.hud._unhandled_input(title_down)
	var title_down_release := InputEventJoypadButton.new()
	title_down_release.button_index = JOY_BUTTON_DPAD_DOWN
	title_down_release.pressed = false
	game.hud._unhandled_input(title_down_release)
	if game.hud.title_navigation_index == title_navigation_before or game.hud.daily_visible:
		_fail("D-pad Down opened a shortcut instead of browsing the title menu")
		return
	game.hud.title_navigation_index = game.hud.title_navigation_actions.find("daily")
	game.hud._refresh_title_navigation()
	var title_accept := InputEventJoypadButton.new()
	title_accept.button_index = JOY_BUTTON_A
	title_accept.pressed = true
	game.hud._unhandled_input(title_accept)
	var title_accept_release := InputEventJoypadButton.new()
	title_accept_release.button_index = JOY_BUTTON_A
	title_accept_release.pressed = false
	game.hud._unhandled_input(title_accept_release)
	if not game.hud.daily_visible:
		_fail("A/Cross did not activate the highlighted title item")
		return
	game.hud.debug_finish_popup_transition()
	var title_back := InputEventJoypadButton.new()
	title_back.button_index = JOY_BUTTON_B
	title_back.pressed = true
	game.hud._unhandled_input(title_back)
	var title_back_release := InputEventJoypadButton.new()
	title_back_release.button_index = JOY_BUTTON_B
	title_back_release.pressed = false
	game.hud._unhandled_input(title_back_release)
	game.hud.debug_finish_popup_transition()
	if game.hud.daily_visible:
		_fail("B/Circle did not return from a title submenu")
		return
	game.run_won = true
	game.hud.show_victory({"won": true, "ending": "keep", "wave": 12, "level": 10, "score": 12345, "kills": 120, "best_score": 12345, "memory_earned": 12, "archive_rank": 2})
	game.hud.debug_finish_popup_transition()
	if not game.hud.victory_credits_visible or game.hud.game_over_visible or game.hud.victory_credit_pages.size() < 5:
		_fail("victory did not begin the automatic staff carousel")
		return
	game.hud._skip_victory_credits_to_thanks()
	if not game.hud.victory_credits_final or game.hud.victory_credits_title.text.find("THANK YOU") < 0:
		_fail("victory credits did not stop on the thank-you page")
		return
	game.hud._unhandled_input(title_accept)
	game.hud.debug_finish_popup_transition()
	game.hud._unhandled_input(title_accept_release)
	if game.hud.victory_credits_visible or not game.hud.title_visible or game.run_won:
		_fail("any button on the final thank-you page did not return to the title")
		return
	game.hud._toggle_achievements()
	game.hud.debug_finish_popup_transition()
	if not game.hud.achievements_visible or game.hud.achievements_label.text.is_empty():
		_fail("achievement gallery did not open from the title screen")
		return
	game.hud._toggle_achievements()
	game.hud.debug_finish_popup_transition()
	game.hud.show_achievement("Smoke Test", "Queued toast validation.")
	if not game.hud.achievement_toast.visible or game.hud.achievement_toast_label.text.find("SMOKE TEST") < 0:
		_fail("achievement unlock toast did not enter its visible queue state")
		return
	if game.hud.achievement_toast_tween != null and game.hud.achievement_toast_tween.is_valid():
		game.hud.achievement_toast_tween.kill()
	game.hud.achievement_toast.visible = false
	game.hud.achievement_queue.clear()
	var old_contract_index: int = game.hud.contract_index
	game.hud._cycle_contract(1)
	if game.hud.contract_index == old_contract_index or game.hud.contract_button.text.is_empty():
		_fail("title contract selector did not cycle and refresh")
		return
	game.hud.hide_title()
	game.run_started = true
	game._sync_pause_state()
	var event_shards_before: int = game.run_shards
	if not game.debug_offer_event("forgotten-shrine") or not game.choosing_event or not paused or not game.hud.event_visible:
		_fail("chapter event did not open its paused choice state")
		return
	game.hud.debug_finish_popup_transition()
	if game.can_process() or game.player.can_process():
		_fail("chapter event left gameplay processing while its choice was open")
		return
	game.hud._choose_event(1)
	game.hud.debug_finish_popup_transition()
	if game.choosing_event or paused or game.hud.event_visible or game.run_shards <= event_shards_before:
		_fail("chapter event choice did not apply its reward and resume")
		return
	if not game._offer_route(2) or not paused or not game.hud.event_visible:
		_fail("route draft did not open as a paused three-choice modal")
		return
	game.hud.debug_finish_popup_transition()
	game.hud._choose_event(0)
	game.hud.debug_finish_popup_transition()
	if paused or game.active_route_id != "chain-vault" or game.arena.route_id != "chain-vault":
		_fail("route choice did not configure gameplay, arena presentation, and resume")
		return
	if not game.hud.device_notice.visible or game.hud.objective_label.visible:
		_fail("route notice did not temporarily replace the objective row")
		return
	game.hud.hide_device_notice()
	if game.hud.device_notice.visible or not game.hud.objective_label.visible:
		_fail("objective row did not return after the route notice")
		return

	for enemy_kind in ["scribe", "splitter", "leech", "warden", "censor", "errata", "archivist", "blot", "duelist", "editor", "binder", "author"]:
		var variant = game.debug_spawn_enemy(enemy_kind, Vector2(260 + enemy_kind.length() * 3, 120))
		if variant.enemy_kind != enemy_kind or variant.health <= 0.0:
			_fail("enemy archetype failed to configure: " + enemy_kind)
			return

	var censor = game.debug_spawn_enemy("censor", game.player.global_position + Vector2(70, 0))
	var censor_health: float = censor.health
	censor.take_damage(10.0, Vector2.RIGHT * 80.0, false)
	if censor.shield_hits != 2 or censor.health <= censor_health - 5.0:
		_fail("Iron Censor frontal shield did not mitigate and consume a shield mark")
		return
	var duelist = game.debug_spawn_enemy("duelist", game.player.global_position + Vector2(80, 20))
	duelist.parry_window = 0.5
	var duelist_health: float = duelist.health
	duelist.take_damage(10.0, Vector2.RIGHT * 80.0, false)
	if duelist.health != duelist_health or duelist.counter_rush <= 0.0:
		_fail("Margin Duelist did not parry and arm its counter-rush")
		return
	var archivist = game.debug_spawn_enemy("archivist", game.player.global_position + Vector2(110, 40))
	var wounded_ally = game.debug_spawn_enemy("brute", archivist.global_position + Vector2(22, 0))
	wounded_ally.health = 1.0
	archivist._support_pulse()
	if wounded_ally.health <= 1.0 or wounded_ally.haste_time <= 0.0:
		_fail("False Archivist did not heal and haste a nearby ally")
		return
	var errata = game.debug_spawn_enemy("errata", game.player.global_position + Vector2(130, 0))
	errata.teleport_timer = 0.0
	errata._physics_process(0.01)
	if not errata.teleport_pending:
		_fail("Errata Shade did not begin its teleport telegraph")
		return
	errata.teleport_charge = 0.0
	errata._physics_process(0.01)
	if errata.teleport_pending or errata.global_position.distance_to(game.player.global_position) > 75.0:
		_fail("Errata Shade did not complete its behind-player teleport")
		return
	var blot = game.debug_spawn_enemy("blot", game.player.global_position + Vector2(145, 20))
	var children_before_blot: int = game.get_child_count()
	blot.shoot_projectiles(Vector2.LEFT)
	if game.get_child_count() < children_before_blot + 6:
		_fail("Living Inkblot did not emit its radial projectile pattern")
		return

	var enemy = game.debug_spawn_enemy("mask", game.player.global_position + Vector2(34, 0))
	var enemy_health: float = enemy.health
	if not game.player.debug_attack(Vector2.RIGHT):
		_fail("player attack did not execute")
		return
	if enemy.health >= enemy_health:
		_fail("melee arc did not damage a target")
		return

	var old_damage: float = game.player.damage
	game.debug_apply_upgrade("razor-ink")
	if game.player.damage <= old_damage:
		_fail("upgrade did not change player stats")
		return
	game.debug_apply_upgrade("ink-wave")
	if game.player.wave_every <= 0 or int(game.player.upgrade_stacks.get("ink-wave", 0)) != 1:
		_fail("build upgrade did not activate its combat mechanic")
		return
	var reach_before_milestone: float = game.player.attack_reach
	game.debug_apply_upgrade("razor-ink")
	game.debug_apply_upgrade("razor-ink")
	if "ink-edge:1" not in game.player.build_milestones or game.player.attack_reach < reach_before_milestone + 7.99 or game.player.cleave < 6:
		_fail("three-point Ink Edge milestone did not grant its one-time build bonus")
		return
	var milestone_reach: float = game.player.attack_reach
	var discipline_state: Dictionary = game.player.get_session_state()
	if not game.player.apply_session_state(discipline_state) or not is_equal_approx(game.player.attack_reach, milestone_reach):
		_fail("checkpoint restore reapplied an already-recorded build milestone")
		return
	var legacy_discipline_state := discipline_state.duplicate(true)
	legacy_discipline_state.erase("build_milestones")
	legacy_discipline_state["attack_reach"] = milestone_reach - 8.0
	legacy_discipline_state["cleave"] = int(discipline_state["cleave"]) - 1
	if not game.player.apply_session_state(legacy_discipline_state) or "ink-edge:1" not in game.player.build_milestones or not is_equal_approx(game.player.attack_reach, milestone_reach):
		_fail("older checkpoint did not migrate its earned build milestone exactly once")
		return
	if not game.player.apply_relic("red-pencil") or game.player.guaranteed_crit_every != 10:
		_fail("relic did not activate its combat mechanic")
		return
	game.player.apply_relic("paper-heart")
	game.player.health = game.player.max_health
	game.player.heal(2.0)
	if game.player.guard <= 0.0:
		_fail("paper-heart relic did not convert overheal into guard")
		return
	game.player.guard = 0.0
	var offered: Array = game._pick_upgrades(4)
	if offered.size() != 4:
		_fail("four-choice upgrade draft did not return four techniques")
		return
	var found_resonant := false
	for offered_choice in offered:
		if bool(offered_choice.get("_resonant", false)):
			found_resonant = Content.upgrade_supports_discipline(offered_choice, "ink-edge")
	if not found_resonant:
		_fail("established build did not receive one valid resonant upgrade choice")
		return
	var old_shards: int = game.run_shards
	game.collect_shards(2)
	if game.run_shards <= old_shards:
		_fail("memory shard economy did not increase run currency")
		return
	var guard_before: float = game.player.guard
	game.activate_combat_pickup("ward")
	if game.player.guard < guard_before + 5.0:
		_fail("ward combat pickup did not grant guard")
		return
	game.activate_combat_pickup("frenzy")
	if game.player.frenzy_time < 8.5:
		_fail("frenzy combat pickup did not activate its timed combat buff")
		return
	var slow_target = game.debug_spawn_enemy("brute", game.player.global_position + Vector2(96, 0))
	game.activate_combat_pickup("hourglass")
	if slow_target.slow_time < 5.5 or slow_target.slow_amount < 0.6:
		_fail("hourglass combat pickup did not slow active enemies")
		return
	var distant_pickup = game.spawn_pickup("xp", game.player.global_position + Vector2(180, 0), 1)
	game.activate_combat_pickup("magnet")
	if distant_pickup.global_position.distance_to(game.player.global_position) > 1.0:
		_fail("magnet combat pickup did not vacuum arena drops")
		return
	var bomb_target = game.debug_spawn_enemy("warden", game.player.global_position + Vector2(60, 0))
	var bomb_health: float = bomb_target.health
	game.activate_combat_pickup("bomb")
	if is_instance_valid(bomb_target) and bomb_target.health >= bomb_health:
		_fail("ink bomb combat pickup did not damage nearby enemies")
		return

	game.player.guard = 0.0
	var old_health: float = game.player.health
	game.player.invulnerable_time = 0.0
	game.player.take_damage(1.0, Vector2.LEFT)
	if game.player.health >= old_health:
		_fail("player damage path did not change health")
		return

	if not FileAccess.file_exists("res://asset-manifest.json"):
		_fail("generated asset manifest is missing")
		return
	var manifest_file := FileAccess.open("res://asset-manifest.json", FileAccess.READ)
	var manifest_data = JSON.parse_string(manifest_file.get_as_text()) if manifest_file != null else null
	if not (manifest_data is Dictionary) or int(manifest_data.get("schema_version", 0)) != 3 or int(manifest_data.get("asset_count", 0)) != 108:
		_fail("asset provenance manifest identity or coverage count drifted")
		return
	var ai_asset_count := 0
	var live_ai_asset_count := 0
	for asset_value in manifest_data.get("assets", []):
		if not (asset_value is Dictionary):
			_fail("asset provenance manifest contains a malformed entry")
			return
		var asset_entry: Dictionary = asset_value
		for field in ["runtime_path", "sha256", "creation_method", "generative_ai", "live_generation", "provenance_record", "rights_review_status"]:
			if not asset_entry.has(field) or str(asset_entry[field]).is_empty():
				_fail("asset provenance entry lacks " + field)
				return
		ai_asset_count += 1 if asset_entry.get("generative_ai", false) == true else 0
		live_ai_asset_count += 1 if asset_entry.get("live_generation", false) == true else 0
	if ai_asset_count != 44 or live_ai_asset_count != 0:
		_fail("pre-generated/live AI asset inventory drifted")
		return
	for runtime_asset in [
		"res://assets/audio/music_menu_hai_mian.ogg",
		"res://assets/audio/music_battle_hai_mian.ogg",
		"res://assets/audio/music_story_hai_mian.ogg",
		"res://assets/audio/music_ending_keep_hai_mian.ogg",
		"res://assets/audio/music_ending_rewrite_hai_mian.ogg",
		"res://assets/audio/voice/nara_ink_art_marginalia_jp.wav",
		"res://assets/audio/voice/nara_ink_art_greatbrush_jp.wav",
		"res://assets/audio/voice/nara_ink_art_needlepoint_jp.wav",
		"res://assets/audio/voice/nara_ink_art_seal_caster_jp.wav",
		"res://assets/audio/voice/nara_ink_art_twin_stroke_jp.wav",
		"res://assets/audio/voice/nara_ink_art_kiai_jp.wav",
		"res://assets/audio/voice/combat/nara_hit_light_01.wav",
		"res://assets/audio/voice/combat/nara_hit_light_02.wav",
		"res://assets/audio/voice/combat/nara_hit_light_03.wav",
		"res://assets/audio/voice/combat/nara_hit_heavy_01.wav",
		"res://assets/audio/voice/combat/nara_hit_heavy_02.wav",
		"res://assets/audio/voice/combat/nara_death_b_jp.wav",
		"res://assets/audio/voice/combat/enemy_mask_hit_01.wav",
		"res://assets/audio/voice/combat/enemy_mask_hit_02.wav",
		"res://assets/audio/voice/combat/enemy_mask_hit_03.wav",
		"res://assets/audio/voice/combat/enemy_mask_death_b.wav",
		"res://assets/audio/voice/combat/enemy_ink_hit_01.wav",
		"res://assets/audio/voice/combat/enemy_ink_hit_02.wav",
		"res://assets/audio/voice/combat/enemy_ink_hit_03.wav",
		"res://assets/audio/voice/combat/enemy_ink_death_b.wav",
		"res://assets/audio/music_archive.wav",
		"res://assets/audio/music_bindery.wav",
		"res://assets/audio/music_finale.wav",
		"res://assets/generated/censor.png",
		"res://assets/generated/errata.png",
		"res://assets/generated/archivist.png",
		"res://assets/generated/blot.png",
		"res://assets/generated/duelist.png",
		"res://assets/generated/bomb.png",
		"res://assets/generated/magnet.png",
		"res://assets/generated/frenzy.png",
		"res://assets/generated/ward.png",
		"res://assets/generated/hourglass.png",
	]:
		if not FileAccess.file_exists(runtime_asset):
			_fail("runtime asset is missing: " + runtime_asset)
			return

	game.lifetime_kills = 1000
	game.lifetime_memory_earned = 250
	game.highest_wave = 12
	game.completed_endings.assign(["keep", "rewrite"])
	game.redline_wins = 1
	game.lifetime_directives_completed = 20
	game.lifetime_daily_clears = 1
	game.daily_best_streak = 7
	game.discovered_relics.clear()
	for relic_data in Content.RELICS:
		game.discovered_relics.append(relic_data["id"])
	game.discovered_upgrades.clear()
	for upgrade_data in Content.UPGRADES:
		game.discovered_upgrades.append(upgrade_data["id"])
	for contract_data in Content.CONTRACTS:
		game.contract_wins[contract_data["id"]] = 1
	for enemy_id in Content.ENEMIES:
		game.codex_kills[enemy_id] = maxi(1, int(game.codex_kills.get(enemy_id, 0)))
	for route_data in Content.ROUTES:
		if str(route_data["id"]) not in game.discovered_routes:
			game.discovered_routes.append(str(route_data["id"]))
	game._evaluate_achievements(false)
	if game.unlocked_achievements.size() != Content.ACHIEVEMENTS.size():
		_fail("persistent achievement evaluator did not unlock the complete catalog")
		return
	var achievement_snapshot: Dictionary = game._meta_snapshot()
	if achievement_snapshot.get("achievement_progress", {}).size() != Content.ACHIEVEMENTS.size():
		_fail("title metadata did not expose achievement progress")
		return

	for existing_boss in game.get_tree().get_nodes_in_group("bosses"):
		if existing_boss.get_parent() == game:
			existing_boss.free()
	var long_game = packed.instantiate()
	long_game.test_mode = true
	long_game.debug_set_save_namespace("smoke_long_test")
	long_game.debug_clear_save_files()
	root.add_child(long_game)
	long_game.debug_set_rng_seed(121212)
	long_game.lifetime_runs = 1
	long_game._on_start_requested("standard", "quick-edition")
	for target_wave in [3, 4, 7, 8, 10, 12]:
		if target_wave == 12:
			long_game.story_seen["act3_confrontation"] = true
		long_game.elapsed = long_game.contract_wave_duration * float(target_wave - 1) + 0.1
		long_game._process(0.0)
		if target_wave in [3, 7, 10]:
			if not long_game.choosing_event or not paused:
				_fail("forced full-run state machine missed event on page %d" % target_wave)
				return
			long_game.hud.debug_finish_popup_transition()
			long_game.hud._choose_event(1)
			long_game.hud.debug_finish_popup_transition()
			if long_game.choosing_relic:
				long_game.hud.debug_finish_popup_transition()
				long_game.hud._choose_relic(0)
				long_game.hud.debug_finish_popup_transition()
		else:
			var expected_boss: String = {4: "editor", 8: "binder", 12: "author"}[target_wave]
			if not _has_boss_kind(long_game, expected_boss):
				_fail("forced full-run state machine missed %s on page %d" % [expected_boss, target_wave])
				return
			for boss in long_game.get_tree().get_nodes_in_group("bosses"):
				if boss.get_parent() == long_game:
					boss.free()
	if long_game.wave != 12 or long_game.seen_events.size() != 3:
		_fail("forced full-run state machine did not reach page 12 with three events")
		return
	long_game.debug_clear_save_files()
	long_game.free()

	print("INKBOUND_SMOKE_OK player=%s enemy=%s upgrade=%s gamepad=ok bindings=ok pause=ok powerups=5 routes=%d directives=%d squads=%d achievements=%d contracts=%d events=%d story=%d upgrades=%d relics=%d enemies=%d" % [game.player.name, enemy.enemy_kind, game.player.damage, Content.ROUTES.size(), Content.PAGE_DIRECTIVES.size(), Content.ENCOUNTER_SQUADS.size(), Content.ACHIEVEMENTS.size(), Content.CONTRACTS.size(), Content.EVENTS.size(), Content.STORY.size(), Content.UPGRADES.size(), Content.RELICS.size(), Content.ENEMIES.size()])
	Engine.time_scale = 1.0
	paused = false
	game.debug_clear_save_files()
	game.free()
	quit(0)


func _has_gamepad_event(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _has_gamepad_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _has_keyboard_key(action: StringName, physical_keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and int(event.physical_keycode) == physical_keycode:
			return true
	return false


func _has_gamepad_axis(action: StringName, axis: int, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _has_boss_kind(game: Node, enemy_kind: String) -> bool:
	for boss in game.get_tree().get_nodes_in_group("bosses"):
		if boss.get_parent() == game and str(boss.enemy_kind) == enemy_kind:
			return true
	return false
