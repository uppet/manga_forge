extends Node

# Godot 4.2-compatible GameAnalytics Collection API v2 client. The current
# official GDExtension requires a newer Godot runtime, so this deliberately
# small adapter keeps analytics optional and isolated from gameplay.

const SDK_VERSION := "rest api v2"
const FLUSH_INTERVAL_SECONDS := 20.0
const MAX_BATCH_SIZE := 32
const MAX_QUEUED_EVENTS := 500
const RETRY_MIN_SECONDS := 5.0
const RETRY_MAX_SECONDS := 120.0
const DEFAULT_STORAGE_ROOT := "user://gameanalytics"

var consented := false
var active := false
var initialized := false
var dry_run := false
var status := "disabled"
var game_key := ""
var secret_key := ""
var environment := "sandbox"
var storage_root := DEFAULT_STORAGE_ROOT
var user_id := ""
var session_id := ""
var session_num := 0
var session_started_ts := 0
var timestamp_offset := 0
var queue: Array = []
var http: HTTPRequest
var in_flight := false
var request_kind := ""
var sent_count := 0
var flush_elapsed := 0.0
var retry_seconds := RETRY_MIN_SECONDS
var retry_after_msec := 0
var session_ended := false
var current_progression_path := ""
var debug_logging := false
var max_queue_events := MAX_QUEUED_EVENTS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	http = HTTPRequest.new()
	http.timeout = 10.0
	http.request_completed.connect(_on_request_completed)
	add_child(http)
	set_process(false)


func configure_from_environment(allow_collection: bool, runtime_test_mode: bool = false) -> void:
	consented = allow_collection
	if runtime_test_mode:
		_disable_runtime()
		status = "test_mode"
		return
	if not allow_collection:
		_disable_and_clear()
		return
	if OS.get_environment("INKBOUND_GA_ENABLED") == "0":
		status = "environment_disabled"
		return
	var requested_game_key := OS.get_environment("INKBOUND_GA_GAME_KEY").strip_edges().to_lower()
	var requested_secret_key := OS.get_environment("INKBOUND_GA_SECRET_KEY").strip_edges().to_lower()
	var requested_environment := OS.get_environment("INKBOUND_GA_ENVIRONMENT").strip_edges().to_lower()
	if requested_environment.is_empty():
		requested_environment = "sandbox"
	if not _valid_hex_key(requested_game_key, 32) or not _valid_hex_key(requested_secret_key, 40):
		status = "missing_credentials"
		return
	if requested_environment not in ["sandbox", "production"]:
		status = "invalid_environment"
		return
	if active and game_key == requested_game_key and secret_key == requested_secret_key and environment == requested_environment:
		return
	if active:
		_end_session()
	game_key = requested_game_key
	secret_key = requested_secret_key
	environment = requested_environment
	debug_logging = OS.get_environment("INKBOUND_GA_DEBUG") == "1"
	_begin_session()


func debug_configure(test_storage_root: String, maximum_events: int = MAX_QUEUED_EVENTS) -> void:
	_disable_runtime()
	consented = true
	dry_run = true
	storage_root = test_storage_root
	game_key = "0123456789abcdef0123456789abcdef"
	secret_key = "0123456789abcdef0123456789abcdef01234567"
	_begin_session(maximum_events)


func record_game_event(kind: String, data: Dictionary = {}) -> void:
	if not active or session_ended:
		return
	match kind:
		"run_started":
			if not current_progression_path.is_empty():
				_add_progression("Fail", current_progression_path)
			var difficulty := _segment(data.get("difficulty", "standard"))
			var contract := _segment("daily" if bool(data.get("daily", false)) else data.get("contract", "open-draft"))
			current_progression_path = "Run:%s:%s" % [difficulty, contract]
			_add_progression("Start", current_progression_path)
			_add_design(["run", "loadout", data.get("starting_weapon", "marginalia")], float(data.get("proof_depth", 0)))
		"run_continued":
			var difficulty := _segment(data.get("difficulty", "standard"))
			var contract := _segment(data.get("contract", "continued"))
			var continued_path := "Run:%s:%s" % [difficulty, contract]
			if current_progression_path != continued_path:
				current_progression_path = continued_path
				_add_progression("Start", current_progression_path)
			_add_design(["run", "continued"], float(data.get("page", 1)))
		"page_started":
			_add_design(["run", "page", str(clampi(int(data.get("page", 1)), 1, 99))], float(data.get("health", 0.0)))
		"boss_page_started":
			_add_design(["run", "boss_page", str(clampi(int(data.get("page", 1)), 1, 99))])
		"route_selected":
			_add_design(["choice", "route", data.get("route", "unknown")], float(data.get("chapter", 0)))
		"event_selected":
			_add_design(["choice", "event", data.get("event", "unknown"), data.get("effect", "unknown")], float(data.get("index", 0)))
		"upgrade_selected":
			_add_design(["choice", "upgrade", data.get("upgrade", "unknown")], float(data.get("level", 0)))
		"relic_selected":
			_add_design(["choice", "relic", data.get("relic", "unknown")], float(data.get("page", 0)))
		"story_choice":
			if not bool(data.get("replay", false)):
				_add_design(["story", "choice", data.get("sequence", "unknown"), data.get("choice", "unknown")])
		"save_return":
			_add_design(["run", "save_return"], float(data.get("page", 0)))
		"manual_visibility":
			if bool(data.get("visible", false)):
				_add_design(["ui", "field_manual", "opened"], float(data.get("page", 0)))
		"run_finalized":
			var path := current_progression_path
			if path.is_empty():
				path = "Run:%s:%s" % [_segment(data.get("difficulty", "standard")), _segment(data.get("contract", "unknown"))]
			_add_progression("Complete" if bool(data.get("won", false)) else "Fail", path, int(data.get("score", 0)))
			var memory_earned := float(data.get("memory_earned", 0.0))
			if memory_earned > 0.0:
				_add_resource("Source:Memory:run:completion", memory_earned)
			if bool(data.get("won", false)):
				_add_design(["run", "ending", data.get("ending", "unknown")], float(data.get("duration_seconds", 0)))
			current_progression_path = ""
			flush_now()


func flush_now() -> void:
	flush_elapsed = FLUSH_INTERVAL_SECONDS
	if active and initialized and not dry_run and not in_flight:
		_submit_events()


func debug_snapshot() -> Dictionary:
	return {
		"active": active,
		"consented": consented,
		"dry_run": dry_run,
		"status": status,
		"user_id": user_id,
		"session_id": session_id,
		"session_num": session_num,
		"queue": queue.duplicate(true),
	}


func debug_authorization(body: String, key_override: String = "") -> String:
	return _authorization(body, key_override if not key_override.is_empty() else secret_key)


func debug_opt_out() -> void:
	consented = false
	_disable_and_clear()


func _process(delta: float) -> void:
	if not active or dry_run or in_flight or Time.get_ticks_msec() < retry_after_msec:
		return
	flush_elapsed += delta
	if not initialized:
		_request_init()
	elif not queue.is_empty() and flush_elapsed >= FLUSH_INTERVAL_SECONDS:
		_submit_events()


func _begin_session(maximum_events: int = MAX_QUEUED_EVENTS) -> void:
	max_queue_events = maxi(8, maximum_events)
	_load_queue()
	var state := _read_dictionary(_state_path())
	var collection_id := environment + ":" + game_key
	if not state.is_empty() and str(state.get("collection_id", "")) != collection_id:
		queue.clear()
		state.clear()
	user_id = str(state.get("user_id", ""))
	if not _valid_uuid(user_id):
		user_id = _new_uuid()
	session_num = maxi(0, int(state.get("session_num", 0)))
	timestamp_offset = int(state.get("timestamp_offset", 0))
	_recover_missing_session_end(state.get("open_session", {}))
	session_num += 1
	session_id = _new_uuid()
	session_started_ts = _client_timestamp()
	session_ended = false
	current_progression_path = ""
	active = true
	initialized = dry_run
	status = "dry_run" if dry_run else "initializing"
	state = {
		"collection_id": collection_id,
		"user_id": user_id,
		"session_num": session_num,
		"timestamp_offset": timestamp_offset,
		"open_session": {
			"started_ts": session_started_ts,
			"last_ts": session_started_ts,
			"defaults": _default_annotations(session_started_ts),
		},
	}
	_write_dictionary(_state_path(), state)
	_enqueue_event({"category": "user"}, maximum_events)
	set_process(not dry_run)
	if not dry_run:
		_request_init()


func _end_session() -> void:
	if not active or session_ended:
		return
	session_ended = true
	var length := clampi(_client_timestamp() - session_started_ts, 0, 172800)
	_enqueue_event({"category": "session_end", "length": length})
	var state := _read_dictionary(_state_path())
	state["open_session"] = {}
	state["timestamp_offset"] = timestamp_offset
	_write_dictionary(_state_path(), state)
	flush_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active:
		_save_queue()


func _exit_tree() -> void:
	_end_session()
	_save_queue()


func _disable_and_clear() -> void:
	_disable_runtime()
	queue.clear()
	user_id = ""
	session_id = ""
	for path in [_state_path(), _queue_path(), _state_path() + ".tmp", _queue_path() + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	status = "disabled"


func _disable_runtime() -> void:
	if is_instance_valid(http) and in_flight:
		http.cancel_request()
	active = false
	initialized = false
	in_flight = false
	request_kind = ""
	sent_count = 0
	session_ended = false
	dry_run = false
	set_process(false)


func _request_init() -> void:
	if in_flight or not active or dry_run:
		return
	var body := JSON.stringify({
		"user_id": user_id,
		"platform": _platform(),
		"os_version": _os_version(),
		"sdk_version": SDK_VERSION,
		"build": _build_version(),
	})
	_start_request("init", _base_url() + "/v2/" + game_key + "/init", body)


func _submit_events() -> void:
	if in_flight or not active or not initialized or dry_run or queue.is_empty():
		return
	sent_count = mini(queue.size(), MAX_BATCH_SIZE)
	var batch: Array = []
	for index in range(sent_count):
		batch.append(queue[index])
	var body := JSON.stringify(batch)
	if not _start_request("events", _base_url() + "/v2/" + game_key + "/events", body):
		sent_count = 0


func _start_request(kind: String, url: String, body: String) -> bool:
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: " + _authorization(body, secret_key),
	])
	var error := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_schedule_retry("request_start_%d" % error)
		return false
	in_flight = true
	request_kind = kind
	return true


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var completed_kind := request_kind
	in_flight = false
	request_kind = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_schedule_retry("transport_%d" % result)
		return
	if completed_kind == "init" and response_code in [200, 201]:
		var response := _parse_dictionary(body.get_string_from_utf8())
		if response.has("enabled") and not bool(response.get("enabled", true)):
			status = "server_disabled"
			set_process(false)
			return
		var old_offset := timestamp_offset
		if response.has("server_ts"):
			timestamp_offset = int(response["server_ts"]) - int(Time.get_unix_time_from_system())
		_adjust_current_session_timestamps(timestamp_offset - old_offset)
		initialized = true
		status = "ready"
		_reset_retry()
		flush_elapsed = FLUSH_INTERVAL_SECONDS
		_save_state_offset()
		return
	if completed_kind == "events" and response_code == 200:
		for _index in range(mini(sent_count, queue.size())):
			queue.pop_front()
		sent_count = 0
		flush_elapsed = 0.0
		status = "ready"
		_save_queue()
		_reset_retry()
		if not queue.is_empty():
			flush_elapsed = FLUSH_INTERVAL_SECONDS
		return
	_schedule_retry("http_%d" % response_code)


func _schedule_retry(reason: String) -> void:
	status = "retrying"
	retry_after_msec = Time.get_ticks_msec() + int(retry_seconds * 1000.0)
	retry_seconds = minf(RETRY_MAX_SECONDS, retry_seconds * 2.0)
	if debug_logging:
		print("GameAnalytics retry scheduled: ", reason)


func _reset_retry() -> void:
	retry_seconds = RETRY_MIN_SECONDS
	retry_after_msec = 0


func _add_progression(progression_status: String, path: String, score: int = -1) -> void:
	var event := {"category": "progression", "event_id": progression_status + ":" + path}
	if score >= 0 and progression_status in ["Fail", "Complete"]:
		event["score"] = score
	_enqueue_event(event)


func _add_design(parts: Array, value: float = NAN) -> void:
	var clean_parts: Array[String] = []
	for part in parts.slice(0, 5):
		clean_parts.append(_segment(part))
	var event := {"category": "design", "event_id": ":".join(clean_parts)}
	if not is_nan(value):
		event["value"] = value
	_enqueue_event(event)


func _add_resource(event_id: String, amount: float) -> void:
	_enqueue_event({"category": "resource", "event_id": event_id, "amount": amount})


func _enqueue_event(fields: Dictionary, maximum_events: int = -1) -> void:
	if not active:
		return
	var timestamp := _client_timestamp()
	var event := _default_annotations(timestamp)
	for field in fields:
		event[field] = fields[field]
	queue.append(event)
	_trim_queue(max_queue_events if maximum_events < 0 else maxi(8, maximum_events))
	_save_queue()
	_update_open_session(timestamp, event)


func _trim_queue(maximum_events: int) -> void:
	while queue.size() > maximum_events:
		var remove_index := 0
		if str(queue[0].get("session_id", "")) == session_id and str(queue[0].get("category", "")) == "user" and queue.size() > 1:
			remove_index = 1
		queue.remove_at(remove_index)


func _recover_missing_session_end(open_session_value: Variant) -> void:
	if not (open_session_value is Dictionary):
		return
	var open_session: Dictionary = open_session_value
	var defaults_value: Variant = open_session.get("defaults", {})
	if not (defaults_value is Dictionary) or defaults_value.is_empty():
		return
	var event: Dictionary = defaults_value.duplicate(true)
	var started_ts := int(open_session.get("started_ts", event.get("client_ts", 0)))
	var last_ts := maxi(started_ts, int(open_session.get("last_ts", started_ts)))
	event["client_ts"] = last_ts
	event["category"] = "session_end"
	event["length"] = clampi(last_ts - started_ts, 0, 172800)
	queue.append(event)
	_trim_queue(max_queue_events)
	_save_queue()


func _update_open_session(timestamp: int, event: Dictionary) -> void:
	if str(event.get("category", "")) == "session_end":
		return
	var state := _read_dictionary(_state_path())
	var open_session: Dictionary = state.get("open_session", {})
	if open_session.is_empty():
		return
	open_session["last_ts"] = timestamp
	state["open_session"] = open_session
	_write_dictionary(_state_path(), state)


func _adjust_current_session_timestamps(delta: int) -> void:
	if delta == 0:
		return
	for event in queue:
		if event is Dictionary and str(event.get("session_id", "")) == session_id:
			event["client_ts"] = int(event.get("client_ts", 0)) + delta
	session_started_ts += delta
	_save_queue()


func _save_state_offset() -> void:
	var state := _read_dictionary(_state_path())
	state["timestamp_offset"] = timestamp_offset
	var open_session: Dictionary = state.get("open_session", {})
	if not open_session.is_empty():
		open_session["started_ts"] = session_started_ts
		var defaults: Dictionary = open_session.get("defaults", {})
		defaults["client_ts"] = session_started_ts
		open_session["defaults"] = defaults
		state["open_session"] = open_session
	_write_dictionary(_state_path(), state)


func _default_annotations(timestamp: int) -> Dictionary:
	return {
		"device": _device_name(),
		"v": 2,
		"user_id": user_id,
		"client_ts": timestamp,
		"sdk_version": SDK_VERSION,
		"os_version": _os_version(),
		"manufacturer": "unknown",
		"platform": _platform(),
		"session_id": session_id,
		"session_num": session_num,
		"build": _build_version(),
		"engine_version": _engine_version(),
	}


func _client_timestamp() -> int:
	return int(Time.get_unix_time_from_system()) + timestamp_offset


func _base_url() -> String:
	return "https://api.gameanalytics.com" if environment == "production" else "https://sandbox-api.gameanalytics.com"


func _authorization(body: String, key: String) -> String:
	var digest := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, key.to_utf8_buffer(), body.to_utf8_buffer())
	return Marshalls.raw_to_base64(digest)


func _platform() -> String:
	match OS.get_name():
		"Windows": return "windows"
		"macOS": return "mac_osx"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD": return "linux"
		_: return "windows"


func _os_version() -> String:
	var expression := RegEx.new()
	expression.compile("[0-9]+(?:\\.[0-9]+){0,2}")
	var match_result := expression.search(OS.get_version())
	return "%s %s" % [_platform(), match_result.get_string() if match_result != null else "0"]


func _engine_version() -> String:
	var info := Engine.get_version_info()
	return "godot %d.%d.%d" % [int(info.get("major", 4)), int(info.get("minor", 2)), int(info.get("patch", 0))]


func _build_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "development")).left(32)


func _device_name() -> String:
	var model := OS.get_model_name().strip_edges()
	return ("unknown" if model.is_empty() or model.to_lower() == "genericdevice" else model).left(64)


func _segment(value: Variant) -> String:
	var expression := RegEx.new()
	expression.compile("[^A-Za-z0-9 _\\-\\.\\(\\)\\!\\?]")
	var clean := expression.sub(str(value).strip_edges(), "_", true).left(64)
	return clean if not clean.is_empty() else "unknown"


func _valid_hex_key(value: String, expected_length: int) -> bool:
	if value.length() != expected_length:
		return false
	var expression := RegEx.new()
	expression.compile("^[a-f0-9]+$")
	return expression.search(value) != null


func _valid_uuid(value: String) -> bool:
	var expression := RegEx.new()
	expression.compile("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	return expression.search(value) != null


func _new_uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var encoded := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [encoded.substr(0, 8), encoded.substr(8, 4), encoded.substr(12, 4), encoded.substr(16, 4), encoded.substr(20, 12)]


func _state_path() -> String:
	return storage_root.path_join("state.json")


func _queue_path() -> String:
	return storage_root.path_join("queue.json")


func _load_queue() -> void:
	queue.clear()
	var parsed := _read_array(_queue_path())
	for event in parsed:
		if event is Dictionary:
			queue.append(event)
	_trim_queue(max_queue_events)


func _save_queue() -> void:
	if not consented:
		return
	_write_json(_queue_path(), queue)


func _read_dictionary(path: String) -> Dictionary:
	var parsed: Variant = _read_json(path)
	return parsed if parsed is Dictionary else {}


func _read_array(path: String) -> Array:
	var parsed: Variant = _read_json(path)
	return parsed if parsed is Array else []


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	return parser.data if parser.parse(file.get_as_text()) == OK else null


func _parse_dictionary(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not (parser.data is Dictionary):
		return {}
	return parser.data


func _write_dictionary(path: String, value: Dictionary) -> void:
	if consented:
		_write_json(path, value)


func _write_json(path: String, value: Variant) -> void:
	var absolute_root := ProjectSettings.globalize_path(storage_root)
	if DirAccess.make_dir_recursive_absolute(absolute_root) != OK and not DirAccess.dir_exists_absolute(absolute_root):
		return
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(value))
	file.flush()
	file = null
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)
	DirAccess.rename_absolute(absolute_temp, absolute_path)
