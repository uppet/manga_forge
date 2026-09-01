extends SceneTree

const RecorderScript = preload("res://scripts/playtest_session.gd")

class FakePlayer extends Node:
	var health := 7.0
	var max_health := 10.0
	var level := 3
	var weapon_form := "GREATBRUSH"


class FakeGame extends Node:
	var run_started := true
	var wave := 4
	var kills := 19
	var score := 2460
	var difficulty_id := "standard"
	var contract_id := "open-draft"
	var active_route_id := "public-archive"
	var using_gamepad := true
	var player: FakePlayer

	func _init() -> void:
		player = FakePlayer.new()
		add_child(player)


var recorder: Node
var game: Node
var session_path := ""
var failed := false


func _initialize() -> void:
	recorder = RecorderScript.new()
	root.add_child(recorder)
	game = FakeGame.new()
	root.add_child(game)
	var session_id := "recorder-test-%d" % Time.get_ticks_msec()
	var output_root := ProjectSettings.globalize_path("res://build/playtest-recorder-test")
	if not recorder.start_session({
		"session_id": session_id,
		"output_root": output_root,
		"participant_code": "P-001",
		"build_id": "test-build",
		"git_commit": "abcdef123456",
	}):
		_fail("recorder did not start")
		return
	recorder.attach_game(game)
	session_path = recorder.session_dir
	recorder.record_event("run_started", {"seed": 42, "position": Vector2(4, 8)})
	recorder.record_event("player_damaged", {"source": "projectile:scribe", "health_after": 6.0})
	recorder.mark("confusing")
	recorder.submit_survey({
		"controls": 4,
		"readability": 2,
		"fairness": 3,
		"build_clarity": 4,
		"sound": 5,
		"music_fatigue": 2,
	}, true, "Useful note")
	recorder.debug_sample_now()
	recorder.finish_session("test_complete")
	_validate_output()


func _validate_output() -> void:
	for filename in ["session.json", "events.jsonl", "performance.jsonl", "performance.json", "markers.jsonl", "survey.json", "summary.json"]:
		if not FileAccess.file_exists(session_path.path_join(filename)):
			_fail("missing playtest artifact " + filename)
			return
	if FileAccess.file_exists(session_path.path_join("incomplete.flag")):
		_fail("normal finish left incomplete marker")
		return
	var session := _read_json(session_path.path_join("session.json"))
	var summary := _read_json(session_path.path_join("summary.json"))
	var survey := _read_json(session_path.path_join("survey.json"))
	if int(session.get("schema", 0)) != 1 or str(session.get("participant_code", "")) != "P-001":
		_fail("session metadata lost schema or participant code")
		return
	if not bool(summary.get("complete", false)) or str(summary.get("exit_reason", "")) != "test_complete":
		_fail("summary did not close normally")
		return
	if int(summary.get("event_counts", {}).get("player_damaged", 0)) != 1:
		_fail("event counts did not preserve damage source")
		return
	if int(summary.get("marker_counts", {}).get("confusing", 0)) != 1:
		_fail("marker count was not recorded")
		return
	if int(survey.get("ratings", {}).get("readability", 0)) != 2 or not bool(survey.get("would_replay", false)):
		_fail("survey data was not preserved")
		return
	var events_text := _read_text(session_path.path_join("events.jsonl"))
	if events_text.find("projectile:scribe") < 0 or events_text.find("[4,8]") < 0:
		_fail("JSONL stream lost source or vector normalization")
		return
	for forbidden_key in ["username", "user_name", "account_id", "home_directory", "microphone_capture", "camera_capture"]:
		if session.has(forbidden_key):
			_fail("privacy-sensitive field leaked into metadata: " + forbidden_key)
			return
	print("INKBOUND_PLAYTEST_RECORDER_OK schema=1 events=ok markers=ok survey=ok performance=ok privacy=local")
	quit(0)


func _read_json(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(_read_text(path)) != OK or not (parser.data is Dictionary):
		return {}
	return parser.data


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("PLAYTEST RECORDER TEST FAILED: " + message)
	quit(1)
