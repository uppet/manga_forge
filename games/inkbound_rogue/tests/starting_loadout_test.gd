extends SceneTree

const Content = preload("res://scripts/content_db.gd")

var started := false
var packed: PackedScene


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run()
	return false


func _run() -> void:
	var loaded: Variant = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail(null, "main scene did not load")
		return
	packed = loaded
	if Content.STARTING_WEAPONS.size() != 5:
		_fail(null, "Armory does not contain exactly five starting forms")
		return
	var ids: Array[String] = []
	for entry in Content.STARTING_WEAPONS:
		var weapon_id := str(entry.get("id", ""))
		if weapon_id.is_empty() or weapon_id in ids or str(entry.get("name", "")).is_empty() or str(entry.get("art", "")).is_empty() or str(entry.get("description", "")).is_empty():
			_fail(null, "starting form metadata is missing or duplicated")
			return
		ids.append(weapon_id)
	if ids != ["marginalia", "greatbrush", "needlepoint", "seal-caster", "twin-stroke"]:
		_fail(null, "starting forms are not in their stable UI order")
		return

	var fresh: Node = _new_game("fresh")
	fresh.run_started = false
	fresh._sync_pause_state()
	fresh.hud.show_title(fresh._meta_snapshot())
	fresh.hud._start_from_title()
	fresh.hud.debug_finish_popup_transition()
	if not fresh.hud.loadout_visible or not fresh.hud.loadout_panel.visible or fresh.hud.loadout_buttons.size() != 5:
		_fail(fresh, "New Game did not open the five-form Armory")
		return
	if fresh.hud.loadout_buttons[0].disabled or fresh.hud.loadout_buttons[1].disabled:
		_fail(fresh, "fresh profile did not expose Marginalia and Greatbrush")
		return
	for locked_index in range(2, 5):
		if not fresh.hud.loadout_buttons[locked_index].disabled or fresh.hud.loadout_buttons[locked_index].text.find("LOCKED") < 0:
			_fail(fresh, "fresh Armory exposed a progression-locked form")
			return
	for index in range(4):
		if fresh.hud.loadout_buttons[index].position.y + fresh.hud.loadout_buttons[index].size.y > fresh.hud.loadout_buttons[index + 1].position.y:
			_fail(fresh, "Armory rows overlap")
			return
	if fresh.hud.loadout_buttons[4].position.y + fresh.hud.loadout_buttons[4].size.y > fresh.hud.loadout_description_label.position.y:
		_fail(fresh, "Armory description overlaps its last weapon row")
		return
	if fresh.hud.loadout_description_label.position.y + fresh.hud.loadout_description_label.size.y > fresh.hud.loadout_panel.size.y:
		_fail(fresh, "Armory description escapes the panel boundary")
		return
	var locked_before: int = fresh.hud.loadout_selected
	fresh.hud._choose_loadout(4)
	if not fresh.hud.loadout_visible or fresh.hud.loadout_selected != locked_before:
		_fail(fresh, "locked Twin-Stroke could be selected")
		return

	var down := InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_DPAD_DOWN
	down.pressed = true
	fresh.hud._unhandled_input(down)
	if fresh.hud.loadout_selected != 1:
		_fail(fresh, "D-pad did not move Armory selection to Greatbrush")
		return
	var confirm := InputEventJoypadButton.new()
	confirm.button_index = JOY_BUTTON_A
	confirm.pressed = true
	fresh.hud._unhandled_input(confirm)
	fresh.hud.debug_finish_popup_transition()
	if fresh.hud.loadout_visible or fresh.hud.title_visible or not fresh.run_started:
		_fail(fresh, "gamepad confirmation did not leave Armory and start the run")
		return
	if fresh.starting_weapon_id != "greatbrush" or fresh.player.weapon_form != "GREATBRUSH" or int(fresh.player.upgrade_stacks.get("greatbrush", 0)) != 1:
		_fail(fresh, "Greatbrush starting form did not become the live player build")
		return
	if str(fresh.player.ink_art_profile().get("name", "")) != "FINAL PERIOD" or "greatbrush" not in fresh.discovered_upgrades:
		_fail(fresh, "starting form did not activate its Ink Art or discovery record")
		return
	var locked_form_pool: Array[Dictionary] = Content.available_upgrades(fresh.player.upgrade_stacks, 10, fresh._unlocked_content_ids("weapon"))
	for entry in locked_form_pool:
		if "weapon" in entry.get("tags", []):
			_fail(fresh, "transformed start left mutually exclusive weapon forms in the draft pool")
			return
	var checkpoint: Dictionary = fresh._checkpoint_payload("loadout-test")
	if str(checkpoint.get("starting_weapon_id", "")) != "greatbrush" or not fresh._is_valid_checkpoint_payload(checkpoint):
		_fail(fresh, "checkpoint omitted or rejected the starting form")
		return
	fresh.free()
	paused = false

	var restored: Node = _new_game("restored")
	if not restored._apply_checkpoint(checkpoint) or restored.starting_weapon_id != "greatbrush" or restored.player.weapon_form != "GREATBRUSH":
		_fail(restored, "Continue did not restore the chosen starting form")
		return
	restored.score = 9000
	restored.kills = 60
	restored._finalize_run()
	if str(restored.last_run_summary.get("starting_weapon", "")) != "greatbrush" or str(restored.last_run_summary.get("weapon_form", "")) != "GREATBRUSH":
		_fail(restored, "run history omitted the starting and finishing form")
		return
	if not restored._save_run():
		_fail(restored, "loadout run history could not save")
		return
	restored.free()
	paused = false
	var history: Node = _new_game("restored", false)
	if history.recent_runs.is_empty() or str(history.recent_runs[0].get("starting_weapon", "")) != "greatbrush":
		_fail(history, "starting form did not survive run-history reload")
		return
	history.debug_clear_save_files()
	history.free()
	paused = false

	var replacement: Node = _new_game("replacement")
	replacement.run_started = false
	replacement.checkpoint_data = {
		"checkpoint_schema": replacement.CHECKPOINT_SCHEMA,
		"wave": 5,
		"kills": 20,
		"score": 3000,
		"difficulty_id": "standard",
		"contract_id": "open-draft",
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"player": {"level": 7},
	}
	replacement._sync_pause_state()
	replacement.hud.show_title(replacement._meta_snapshot())
	replacement.hud._start_from_title()
	if not replacement.hud.new_game_armed or replacement.hud.loadout_visible:
		_fail(replacement, "saved draft did not require New Game confirmation before Armory")
		return
	replacement.hud._start_from_title()
	if not replacement.hud.loadout_visible or replacement.checkpoint_data.is_empty():
		_fail(replacement, "opening Armory erased the saved draft before a weapon was confirmed")
		return
	replacement.hud.debug_finish_popup_transition()
	var cancel := InputEventJoypadButton.new()
	cancel.button_index = JOY_BUTTON_B
	cancel.pressed = true
	replacement.hud._unhandled_input(cancel)
	replacement.hud.debug_finish_popup_transition()
	if replacement.hud.loadout_visible or not replacement.hud.title_visible or replacement.checkpoint_data.is_empty():
		_fail(replacement, "gamepad cancel did not return from Armory with the saved draft intact")
		return
	replacement.free()
	paused = false

	var locked_runtime: Node = _new_game("locked_runtime")
	locked_runtime._on_start_requested("standard", "open-draft", "twin-stroke")
	if locked_runtime.starting_weapon_id != "marginalia" or locked_runtime.player.weapon_form != "MARGINALIA":
		_fail(locked_runtime, "runtime accepted a forged locked starting form")
		return
	var flexible_pool: Array[Dictionary] = Content.available_upgrades(locked_runtime.player.upgrade_stacks, 10, locked_runtime._unlocked_content_ids("weapon"))
	if not _pool_has(flexible_pool, "greatbrush"):
		_fail(locked_runtime, "Marginalia start did not preserve restored transformations in the draft pool")
		return
	locked_runtime.free()
	paused = false

	var veteran: Node = _new_game("veteran")
	veteran.lifetime_runs = 2
	veteran.lifetime_kills = 30
	veteran.highest_wave = 12
	veteran.completed_endings.assign(["keep"])
	veteran.run_started = false
	veteran._sync_pause_state()
	veteran.hud.show_title(veteran._meta_snapshot())
	veteran.hud._start_from_title()
	veteran.hud.debug_finish_popup_transition()
	for button in veteran.hud.loadout_buttons:
		if button.disabled:
			_fail(veteran, "veteran Armory did not expose all five restored forms")
			return
	veteran.hud._choose_loadout(4)
	veteran.hud.debug_finish_popup_transition()
	if veteran.starting_weapon_id != "twin-stroke" or veteran.player.weapon_form != "TWIN-STROKE" or str(veteran.player.ink_art_profile().get("name", "")) != "CROSS REVISION":
		_fail(veteran, "Twin-Stroke did not start with its distinct form and Ink Art")
		return

	print("INKBOUND_LOADOUT_OK forms=5 fresh=2 locked=3 gamepad=ok checkpoint=ok history=ok veteran=5")
	_cleanup(veteran, 0)


func _new_game(suffix: String, clear_files: bool = true) -> Node:
	var game: Node = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("starting_loadout_test_" + suffix)
	if clear_files:
		game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(939393)
	return game


func _pool_has(pool: Array[Dictionary], upgrade_id: String) -> bool:
	for entry in pool:
		if str(entry.get("id", "")) == upgrade_id:
			return true
	return false


func _fail(game: Node, message: String) -> void:
	push_error("INKBOUND_LOADOUT_FAIL: " + message)
	_cleanup(game, 1)


func _cleanup(game: Node, exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
