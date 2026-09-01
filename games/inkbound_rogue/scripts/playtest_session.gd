extends Node

const SCHEMA_VERSION := 1
const SAMPLE_INTERVAL_SECONDS := 1.0
const EVENT_FLUSH_INTERVAL_MSEC := 1000
const MAX_BUFFERED_EVENTS := 24
const CONTEXT_WINDOW_MSEC := 30000
const MAX_CONTEXT_EVENTS := 80
const MARK_CATEGORIES := ["bug", "confusing", "unfair", "delight"]
const OverlayScript = preload("res://scripts/playtest_overlay.gd")

var enabled := false
var finished := false
var session_id := ""
var session_dir := ""
var started_unix := 0
var started_ticks_msec := 0
var participant_code := ""
var event_file: FileAccess
var sample_file: FileAccess
var marker_file: FileAccess
var game_ref: WeakRef
var overlay: CanvasLayer
var sample_accumulator := 0.0
var frame_count := 0
var frame_time_sum_msec := 0.0
var max_frame_time_msec := 0.0
var fps_sum := 0.0
var fps_samples := 0
var min_fps := INF
var peak_memory_bytes := 0.0
var peak_nodes := 0
var peak_enemies := 0
var peak_projectiles := 0
var peak_pickups := 0
var event_counts: Dictionary = {}
var marker_counts: Dictionary = {}
var last_events: Array[Dictionary] = []
var marker_index := 0
var survey_data: Dictionary = {}
var last_game_snapshot: Dictionary = {}
var pending_event_lines := 0
var last_event_flush_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_unhandled_input(false)
	if OS.get_environment("INKBOUND_PLAYTEST") == "1":
		start_session({
			"session_id": OS.get_environment("INKBOUND_PLAYTEST_SESSION"),
			"output_root": OS.get_environment("INKBOUND_PLAYTEST_DIR"),
			"participant_code": OS.get_environment("INKBOUND_PLAYTEST_PARTICIPANT"),
			"build_id": OS.get_environment("INKBOUND_BUILD_ID"),
			"git_commit": OS.get_environment("INKBOUND_GIT_COMMIT"),
		})


func start_session(options: Dictionary = {}) -> bool:
	if enabled:
		return true
	var requested_id := str(options.get("session_id", ""))
	if requested_id.is_empty():
		requested_id = "PT-%d" % int(Time.get_unix_time_from_system())
	session_id = _safe_token(requested_id, 48)
	participant_code = _safe_token(str(options.get("participant_code", "anonymous")), 32)
	if participant_code.is_empty():
		participant_code = "anonymous"
	var output_root := str(options.get("output_root", ""))
	if output_root.is_empty():
		output_root = "user://playtest/sessions"
	var absolute_root := ProjectSettings.globalize_path(output_root) if output_root.contains("://") else output_root
	if DirAccess.make_dir_recursive_absolute(absolute_root) != OK and not DirAccess.dir_exists_absolute(absolute_root):
		push_error("Playtest recorder could not create output root: " + absolute_root)
		return false
	session_dir = absolute_root.path_join(session_id)
	if DirAccess.make_dir_recursive_absolute(session_dir.path_join("screenshots")) != OK and not DirAccess.dir_exists_absolute(session_dir.path_join("screenshots")):
		push_error("Playtest recorder could not create session directory: " + session_dir)
		return false

	event_file = FileAccess.open(session_dir.path_join("events.jsonl"), FileAccess.WRITE)
	sample_file = FileAccess.open(session_dir.path_join("performance.jsonl"), FileAccess.WRITE)
	marker_file = FileAccess.open(session_dir.path_join("markers.jsonl"), FileAccess.WRITE)
	if event_file == null or sample_file == null or marker_file == null:
		push_error("Playtest recorder could not open session streams")
		return false

	started_unix = int(Time.get_unix_time_from_system())
	started_ticks_msec = Time.get_ticks_msec()
	last_event_flush_msec = started_ticks_msec
	enabled = true
	finished = false
	set_process(true)
	set_process_unhandled_input(true)
	_write_json(session_dir.path_join("session.json"), _session_metadata(options))
	_write_text(session_dir.path_join("incomplete.flag"), "Session did not close normally.\n")
	if DisplayServer.get_name() != "headless":
		overlay = OverlayScript.new()
		add_child(overlay)
		overlay.configure(session_id)
		overlay.marker_requested.connect(mark)
		overlay.survey_submitted.connect(submit_survey)
		overlay.survey_skipped.connect(_on_survey_skipped)
	record_event("session_started", {"participant_code": participant_code})
	return true


func attach_game(game: Node) -> void:
	if not enabled or not is_instance_valid(game):
		return
	game_ref = weakref(game)
	record_event("scene_attached", {"scene": str(game.name)})


func record_event(kind: String, data: Dictionary = {}) -> void:
	if not enabled or finished or event_file == null:
		return
	var clean_kind := _safe_token(kind, 48)
	if clean_kind.is_empty():
		return
	var event := {
		"schema": SCHEMA_VERSION,
		"t_ms": _elapsed_msec(),
		"kind": clean_kind,
		"data": _json_safe(data),
	}
	event_file.store_line(JSON.stringify(event))
	pending_event_lines += 1
	event_counts[clean_kind] = int(event_counts.get(clean_kind, 0)) + 1
	last_events.append(event)
	_prune_context_events()
	_flush_event_stream(clean_kind in ["session_started", "session_finished"] or bool(data.get("fatal", false)))


func mark(category: String) -> void:
	if not enabled or finished:
		return
	var clean_category := category if category in MARK_CATEGORIES else "bug"
	marker_index += 1
	var marker := {
		"schema": SCHEMA_VERSION,
		"index": marker_index,
		"t_ms": _elapsed_msec(),
		"category": clean_category,
		"game": _game_snapshot(),
		"context": _recent_context(),
	}
	marker_file.store_line(JSON.stringify(marker))
	marker_file.flush()
	marker_counts[clean_category] = int(marker_counts.get(clean_category, 0)) + 1
	record_event("marker", {"category": clean_category, "index": marker_index})
	_flush_event_stream(true)
	if is_instance_valid(overlay):
		overlay.show_marker(clean_category)
	_capture_marker_screenshot(marker_index, clean_category)


func request_survey(reason: String) -> void:
	if not enabled or finished or not is_instance_valid(overlay) or not survey_data.is_empty():
		return
	record_event("survey_opened", {"reason": reason.left(48)})
	overlay.show_survey(reason.left(48))


func submit_survey(ratings: Dictionary, would_replay: bool, notes: String = "") -> void:
	if not enabled or finished:
		return
	var clean_ratings: Dictionary = {}
	for metric_id in ["controls", "readability", "fairness", "build_clarity", "sound", "music_fatigue"]:
		clean_ratings[metric_id] = clampi(int(ratings.get(metric_id, 3)), 1, 5)
	survey_data = {
		"schema": SCHEMA_VERSION,
		"submitted_t_ms": _elapsed_msec(),
		"ratings": clean_ratings,
		"would_replay": would_replay,
		"notes": notes.left(280),
	}
	_write_json(session_dir.path_join("survey.json"), survey_data)
	record_event("survey_submitted", {"ratings": clean_ratings, "would_replay": would_replay})


func finish_session(reason: String = "normal_exit") -> void:
	if not enabled or finished:
		return
	record_event("session_finished", {"reason": reason.left(48)})
	if is_inside_tree():
		_sample_performance()
	else:
		last_game_snapshot = _game_snapshot()
	finished = true
	_write_json(session_dir.path_join("performance.json"), _performance_summary())
	_write_json(session_dir.path_join("summary.json"), _session_summary(reason))
	if event_file != null:
		event_file.flush()
		event_file = null
	if sample_file != null:
		sample_file.flush()
		sample_file = null
	if marker_file != null:
		marker_file.flush()
		marker_file = null
	DirAccess.remove_absolute(session_dir.path_join("incomplete.flag"))
	set_process(false)
	set_process_unhandled_input(false)


func debug_sample_now() -> void:
	_sample_performance()


func _process(delta: float) -> void:
	if not enabled or finished:
		return
	frame_count += 1
	var frame_msec := delta * 1000.0
	frame_time_sum_msec += frame_msec
	max_frame_time_msec = maxf(max_frame_time_msec, frame_msec)
	sample_accumulator += delta
	if sample_accumulator >= SAMPLE_INTERVAL_SECONDS:
		sample_accumulator = fmod(sample_accumulator, SAMPLE_INTERVAL_SECONDS)
		_sample_performance()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or finished or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var category := ""
	match event.physical_keycode:
		KEY_F6:
			category = "bug"
		KEY_F7:
			category = "confusing"
		KEY_F8:
			category = "unfair"
		KEY_F9:
			category = "delight"
	if category.is_empty():
		return
	mark(category)
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and enabled and not finished:
		finish_session("window_close")


func _exit_tree() -> void:
	if enabled and not finished:
		finish_session("tree_exit")


func _sample_performance() -> void:
	if not enabled or finished or sample_file == null:
		return
	var fps := float(Engine.get_frames_per_second())
	if fps > 0.0:
		fps_sum += fps
		fps_samples += 1
		min_fps = minf(min_fps, fps)
	var memory_bytes := float(Performance.get_monitor(Performance.MEMORY_STATIC))
	peak_memory_bytes = maxf(peak_memory_bytes, memory_bytes)
	var game := _game()
	var nodes := _count_nodes(game) if is_instance_valid(game) else 0
	var enemies := _owned_group_count(game, "enemies")
	var projectiles := _owned_group_count(game, "hostile_projectiles")
	var pickups := _owned_group_count(game, "pickups")
	peak_nodes = maxi(peak_nodes, nodes)
	peak_enemies = maxi(peak_enemies, enemies)
	peak_projectiles = maxi(peak_projectiles, projectiles)
	peak_pickups = maxi(peak_pickups, pickups)
	last_game_snapshot = _game_snapshot()
	var sample := {
		"schema": SCHEMA_VERSION,
		"t_ms": _elapsed_msec(),
		"fps": fps,
		"frame_max_ms": max_frame_time_msec,
		"memory_mb": memory_bytes / 1048576.0,
		"nodes": nodes,
		"enemies": enemies,
		"hostile_projectiles": projectiles,
		"pickups": pickups,
		"game": last_game_snapshot,
	}
	sample_file.store_line(JSON.stringify(sample))
	sample_file.flush()
	_flush_event_stream()


func _flush_event_stream(force: bool = false) -> void:
	if event_file == null or pending_event_lines <= 0:
		return
	var now := Time.get_ticks_msec()
	if not force and pending_event_lines < MAX_BUFFERED_EVENTS and now - last_event_flush_msec < EVENT_FLUSH_INTERVAL_MSEC:
		return
	event_file.flush()
	pending_event_lines = 0
	last_event_flush_msec = now


func _session_metadata(options: Dictionary) -> Dictionary:
	var screen_size := DisplayServer.screen_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	var joypads: Array[String] = []
	for device in Input.get_connected_joypads():
		joypads.append(Input.get_joy_name(device).left(80))
	return {
		"schema": SCHEMA_VERSION,
		"session_id": session_id,
		"participant_code": participant_code,
		"started_unix": started_unix,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "unknown")),
		"build_id": str(options.get("build_id", "unknown")).left(80),
		"git_commit": _safe_token(str(options.get("git_commit", "unknown")), 48),
		"platform": OS.get_name(),
		"os_version": OS.get_version().left(120),
		"locale": OS.get_locale().left(24),
		"renderer": RenderingServer.get_video_adapter_name().left(120),
		"screen": [screen_size.x, screen_size.y],
		"joypads": joypads,
		"privacy": "Local gameplay events only. No account, microphone, camera, or arbitrary typed text is captured.",
	}


func _session_summary(reason: String) -> Dictionary:
	return {
		"schema": SCHEMA_VERSION,
		"session_id": session_id,
		"participant_code": participant_code,
		"started_unix": started_unix,
		"ended_unix": int(Time.get_unix_time_from_system()),
		"duration_seconds": float(_elapsed_msec()) / 1000.0,
		"exit_reason": reason.left(48),
		"complete": true,
		"event_counts": event_counts.duplicate(true),
		"marker_counts": marker_counts.duplicate(true),
		"survey": survey_data.duplicate(true),
		"performance": _performance_summary(),
		"last_game_state": last_game_snapshot.duplicate(true),
	}


func _performance_summary() -> Dictionary:
	return {
		"samples": fps_samples,
		"average_reported_fps": fps_sum / float(fps_samples) if fps_samples > 0 else 0.0,
		"minimum_reported_fps": min_fps if fps_samples > 0 else 0.0,
		"average_frame_ms": frame_time_sum_msec / float(frame_count) if frame_count > 0 else 0.0,
		"maximum_frame_ms": max_frame_time_msec,
		"peak_memory_mb": peak_memory_bytes / 1048576.0,
		"peak_nodes": peak_nodes,
		"peak_enemies": peak_enemies,
		"peak_hostile_projectiles": peak_projectiles,
		"peak_pickups": peak_pickups,
	}


func _game_snapshot() -> Dictionary:
	var game := _game()
	if not is_instance_valid(game):
		return {}
	var player = game.get("player")
	return {
		"run_started": bool(game.get("run_started")),
		"wave": int(game.get("wave")),
		"kills": int(game.get("kills")),
		"score": int(game.get("score")),
		"difficulty": str(game.get("difficulty_id")),
		"contract": str(game.get("contract_id")),
		"route": str(game.get("active_route_id")),
		"paused": get_tree().paused if is_inside_tree() else false,
		"input": "gamepad" if bool(game.get("using_gamepad")) else "keyboard_mouse",
		"health": float(player.get("health")) if is_instance_valid(player) else 0.0,
		"max_health": float(player.get("max_health")) if is_instance_valid(player) else 0.0,
		"level": int(player.get("level")) if is_instance_valid(player) else 0,
		"weapon": str(player.get("weapon_form")) if is_instance_valid(player) else "",
	}


func _game() -> Node:
	return game_ref.get_ref() if game_ref != null else null


func _owned_group_count(game: Node, group_name: StringName) -> int:
	if not is_instance_valid(game) or not is_inside_tree():
		return 0
	var count := 0
	for node in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(node) and node.get_parent() == game and not node.is_queued_for_deletion():
			count += 1
	return count


func _count_nodes(node: Node) -> int:
	if not is_instance_valid(node):
		return 0
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _elapsed_msec() -> int:
	return maxi(0, Time.get_ticks_msec() - started_ticks_msec)


func _recent_context() -> Array[Dictionary]:
	_prune_context_events()
	return last_events.duplicate(true)


func _prune_context_events() -> void:
	var cutoff := _elapsed_msec() - CONTEXT_WINDOW_MSEC
	while not last_events.is_empty() and (int(last_events[0].get("t_ms", 0)) < cutoff or last_events.size() > MAX_CONTEXT_EVENTS):
		last_events.pop_front()


func _capture_marker_screenshot(index: int, category: String) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	await RenderingServer.frame_post_draw
	if not enabled or finished:
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return
	var path := session_dir.path_join("screenshots").path_join("%03d_%s.png" % [index, category])
	image.save_png(path)


func _on_survey_skipped() -> void:
	record_event("survey_skipped")


func _safe_token(value: String, maximum: int) -> String:
	var result := ""
	for character in value:
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789-_":
			result += character
		elif character in [" ", "."]:
			result += "-"
	result = result.left(maximum).strip_edges()
	while result.begins_with("-"):
		result = result.trim_prefix("-")
	while result.ends_with("-"):
		result = result.trim_suffix("-")
	return result


func _json_safe(value: Variant, depth: int = 0) -> Variant:
	if depth > 6:
		return "<depth-limit>"
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[str(key).left(64)] = _json_safe(value[key], depth + 1)
		return result
	if value is Array:
		var result: Array = []
		for item in value.slice(0, 96):
			result.append(_json_safe(item, depth + 1))
		return result
	if value is Vector2 or value is Vector2i:
		return [value.x, value.y]
	if value is String:
		return value.left(512)
	if value is bool or value is int or value is float or value == null:
		return value
	return str(value).left(160)


func _write_json(path: String, data: Dictionary) -> bool:
	return _write_text(path, JSON.stringify(data, "  ") + "\n")


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	return true
