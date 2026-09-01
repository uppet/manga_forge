extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const UNOWNED := ["broken-mask", "glass-nib", "paper-heart"]

var game: Node
var started := false


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run()
	return false


func _run() -> void:
	var loaded: Variant = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	game = loaded.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("relic_draft_test")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(484848)
	game.player.controls_enabled = false
	game.run_started = true
	for relic_data in Content.RELICS:
		var relic_id := str(relic_data.get("id", ""))
		if relic_id not in UNOWNED:
			game.relic_ids.append(relic_id)

	var field_relic = game.spawn_pickup("relic", game.player.global_position, 1)
	field_relic._collect()
	if not _validate_open_draft(3, "FIELD RELIC"):
		return
	var first_choice_id := str(game.current_relic_choices[1].get("id", ""))
	_send_gamepad(JOY_BUTTON_Y)
	if game.choosing_relic or game.hud.relic_draft_visible or paused:
		_fail("gamepad Y did not choose the second relic and resume")
		return
	if first_choice_id not in game.relic_ids or first_choice_id not in game.player.relics or first_choice_id not in game.discovered_relics:
		_fail("selected field relic was not applied and recorded")
		return
	if str(game.checkpoint_data.get("reason", "")) != "relic-" + first_choice_id or first_choice_id not in game.checkpoint_data.get("relic_ids", []):
		_fail("relic selection did not create a post-choice checkpoint")
		return

	game.choosing_event = true
	game._sync_pause_state()
	game._apply_event_effect("relic", 1.0)
	if game.pending_relic_sources.size() != 1 or game.choosing_relic or not paused:
		_fail("event relic was not queued behind the active event modal")
		return
	game.choosing_event = false
	if not game._try_open_pending_relic_draft() or not _validate_open_draft(2, "ARCHIVE CACHE"):
		return
	_send_gamepad(JOY_BUTTON_X)
	if game.choosing_relic or paused or game.relic_ids.size() != 11:
		_fail("queued event relic did not resolve cleanly")
		return

	game.active_directive = Content.directive("final-proof")
	game.directive_completed = false
	game.directive_progress = 0.0
	game.directive_target = float(game.active_directive.get("target", 1.0))
	if not game._complete_page_directive() or not _validate_open_draft(1, "PAGE DIRECTIVE"):
		return
	_send_gamepad(JOY_BUTTON_X)
	if game.choosing_relic or paused or game.relic_ids.size() != Content.RELICS.size():
		_fail("directive relic did not complete the twelve-relic collection (owned=%s player=%s choices=%s pending=%s choosing=%s paused=%s)" % [
			str(game.relic_ids),
			str(game.player.relics),
			str(game.current_relic_choices),
			str(game.pending_relic_sources),
			str(game.choosing_relic),
			str(paused),
		])
		return

	var memory_before: int = game.run_shards
	if game.offer_relic_draft("COMPLETE ARCHIVE") or game.run_shards <= memory_before or game.choosing_relic:
		_fail("complete relic archive did not convert the exhausted draft into Memory")
		return
	game.score = 12000
	game.kills = 90
	game._finalize_run()
	if int(game.last_run_summary.get("relic_count", 0)) != 12 or game.last_run_summary.get("relic_ids", []).size() != 12:
		_fail("run summary did not preserve the completed relic build")
		return
	print("INKBOUND_RELIC_DRAFT_OK choices=3 field=ok event=queued directive=ok pause=modal gamepad=XY checkpoint=ok summary=12 archive=12")
	_cleanup(0)


func _validate_open_draft(expected_choices: int, source_fragment: String) -> bool:
	if not game.choosing_relic or not game.hud.relic_draft_visible or not game.hud.relic_draft_panel.visible or not paused:
		_fail("relic reward did not open a modal paused draft")
		return false
	if game.current_relic_choices.size() != expected_choices or game.hud.current_relic_choices.size() != expected_choices:
		_fail("relic draft did not expose the expected number of unique remaining choices")
		return false
	if game.hud.relic_draft_source_label.text.find(source_fragment) < 0:
		_fail("relic draft omitted its reward source")
		return false
	var ids: Array[String] = []
	for entry in game.current_relic_choices:
		var relic_id := str(entry.get("id", ""))
		if relic_id.is_empty() or relic_id in ids or relic_id in game.relic_ids:
			_fail("relic draft contains an empty, duplicate, or already-owned choice")
			return false
		ids.append(relic_id)
	for index in range(expected_choices):
		var button: Button = game.hud.relic_draft_buttons[index]
		var input_label: RichTextLabel = game.hud.relic_draft_input_labels[index]
		var name_label: RichTextLabel = game.hud.relic_draft_name_labels[index]
		var description_label: RichTextLabel = game.hud.relic_draft_description_labels[index]
		var footer_label: RichTextLabel = game.hud.relic_draft_footer_labels[index]
		if input_label.position.y + input_label.size.y > name_label.position.y:
			_fail("relic input prompt overlaps its name")
			return false
		if name_label.position.y + name_label.size.y > description_label.position.y:
			_fail("relic name overlaps its description")
			return false
		if description_label.position.y + description_label.size.y > footer_label.position.y:
			_fail("relic description overlaps its footer")
			return false
		if footer_label.position.y + footer_label.size.y > button.size.y:
			_fail("relic footer escapes its card")
			return false
		if name_label.get_content_height() > name_label.size.y or description_label.get_content_height() > description_label.size.y:
			_fail("rendered relic copy escapes its assigned text region")
			return false
	return true


func _send_gamepad(button_index: int) -> void:
	var pressed_event := InputEventJoypadButton.new()
	pressed_event.button_index = button_index
	pressed_event.pressed = true
	game.hud._unhandled_input(pressed_event)
	var released_event := InputEventJoypadButton.new()
	released_event.button_index = button_index
	released_event.pressed = false
	game.hud._unhandled_input(released_event)


func _fail(message: String) -> void:
	push_error("INKBOUND_RELIC_DRAFT_FAIL: " + message)
	_cleanup(1)


func _cleanup(exit_code: int) -> void:
	Engine.time_scale = 1.0
	paused = false
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	quit(exit_code)
