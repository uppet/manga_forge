extends SceneTree

const AnalyticsScript = preload("res://scripts/gameanalytics_client.gd")

var analytics: Node
var storage_root := ""
var failed := false


func _initialize() -> void:
	analytics = AnalyticsScript.new()
	root.add_child(analytics)
	var build_info: Dictionary = analytics.build_credential_info()
	if bool(build_info.get("embedded", true)) or str(build_info.get("config_fingerprint", "")) != "none":
		return _fail("Git-safe source placeholder unexpectedly contains embedded credentials")
	storage_root = "res://build/gameanalytics-test/%d" % Time.get_ticks_msec()
	analytics.debug_configure(storage_root, 12)
	var initial: Dictionary = analytics.debug_snapshot()
	if not bool(initial.get("active", false)) or not bool(initial.get("consented", false)) or not bool(initial.get("dry_run", false)):
		return _fail("dry-run analytics client did not become active")
	if not _valid_uuid(str(initial.get("user_id", ""))) or not _valid_uuid(str(initial.get("session_id", ""))):
		return _fail("anonymous installation/session identifiers are not UUIDs")
	var initial_queue: Array = initial.get("queue", [])
	if initial_queue.size() != 1 or str(initial_queue[0].get("category", "")) != "user":
		return _fail("session-start user event was not first")
	if not _has_required_annotations(initial_queue[0]):
		return _fail("session-start event lacks Collection API annotations")

	var standard_hmac: String = analytics.debug_authorization(
		"The quick brown fox jumps over the lazy dog",
		"key"
	)
	if standard_hmac != "97yD9DBThCSxMpjmqm+xQ+9NWaFJRhdZl0edvC0aPNg=":
		return _fail("HMAC-SHA256 authorization differs from the standard vector")

	analytics.record_game_event("attack", {"position": Vector2(12, 34), "raw_input": "controller-axis"})
	analytics.record_game_event("player_damaged", {"health": 4.0, "source": "projectile"})
	if analytics.debug_snapshot().get("queue", []).size() != 1:
		return _fail("high-frequency combat events entered the remote analytics queue")

	analytics.record_game_event("run_started", {
		"difficulty": "standard",
		"contract": "open-draft",
		"starting_weapon": "marginalia",
		"proof_depth": 2,
		"seed": 987654321,
	})
	analytics.record_game_event("run_continued", {"difficulty": "standard", "contract": "open-draft", "page": 2})
	if _count_event_id(analytics.debug_snapshot().get("queue", []), "Start:Run:standard:open-draft") != 1:
		return _fail("continuing the current draft duplicated its progression start")
	analytics.record_game_event("page_started", {"page": 3, "health": 5.5, "position": Vector2(77, 91)})
	analytics.record_game_event("upgrade_selected", {"upgrade": "arc-sweep", "level": 4})
	analytics.record_game_event("relic_selected", {"relic": "red-thread", "page": 4})
	analytics.record_game_event("story_choice", {"sequence": "act1_arrival", "choice": "keep", "replay": false})
	analytics.record_game_event("run_finalized", {
		"won": true,
		"ending": "keep",
		"score": 4200,
		"memory_earned": 14,
		"duration_seconds": 390,
	})
	var mapped_queue: Array = analytics.debug_snapshot().get("queue", [])
	for expected in [
		"Start:Run:standard:open-draft",
		"run:page:3",
		"choice:upgrade:arc-sweep",
		"choice:relic:red-thread",
		"story:choice:act1_arrival:keep",
		"Complete:Run:standard:open-draft",
		"Source:Memory:run:completion",
		"run:ending:keep",
	]:
		if not _contains_event_id(mapped_queue, expected):
			return _fail("semantic event mapping is missing " + expected)
	var serialized := JSON.stringify(mapped_queue)
	for forbidden in ["987654321", "controller-axis", "position", "raw_input", "participant", "account", "email"]:
		if serialized.find(forbidden) >= 0:
			return _fail("privacy-sensitive or high-cardinality field leaked: " + forbidden)

	for page in range(1, 30):
		analytics.record_game_event("page_started", {"page": page, "health": 4.0})
	var trimmed_queue: Array = analytics.debug_snapshot().get("queue", [])
	if trimmed_queue.size() != 12:
		return _fail("offline queue did not enforce its configured cap")
	if not _contains_category(trimmed_queue, "user"):
		return _fail("queue trimming removed the current session-start event")
	if not FileAccess.file_exists(storage_root.path_join("state.json")) or not FileAccess.file_exists(storage_root.path_join("queue.json")):
		return _fail("offline state and event queue were not persisted")

	analytics.configure_from_environment(false, true)
	if not FileAccess.file_exists(storage_root.path_join("state.json")) or not FileAccess.file_exists(storage_root.path_join("queue.json")):
		return _fail("automated test isolation erased a real analytics queue")
	analytics.debug_opt_out()
	if FileAccess.file_exists(storage_root.path_join("state.json")) or FileAccess.file_exists(storage_root.path_join("queue.json")):
		return _fail("opt-out did not erase anonymous analytics state")
	if bool(analytics.debug_snapshot().get("active", true)):
		return _fail("opt-out left the analytics client active")
	print("INKBOUND_GAMEANALYTICS_OK collection_api=v2 consent=opt-in hmac=verified queue=offline privacy=minimal")
	quit(0)


func _has_required_annotations(event: Dictionary) -> bool:
	for field in ["device", "v", "user_id", "client_ts", "sdk_version", "os_version", "manufacturer", "platform", "session_id", "session_num", "build", "engine_version"]:
		if not event.has(field):
			return false
	return int(event.get("v", 0)) == 2 and str(event.get("sdk_version", "")) == "rest api v2"


func _contains_event_id(events: Array, event_id: String) -> bool:
	for event in events:
		if event is Dictionary and str(event.get("event_id", "")) == event_id:
			return true
	return false


func _count_event_id(events: Array, event_id: String) -> int:
	var count := 0
	for event in events:
		if event is Dictionary and str(event.get("event_id", "")) == event_id:
			count += 1
	return count


func _contains_category(events: Array, category: String) -> bool:
	for event in events:
		if event is Dictionary and str(event.get("category", "")) == category:
			return true
	return false


func _valid_uuid(value: String) -> bool:
	var expression := RegEx.new()
	expression.compile("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	return expression.search(value) != null


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("GAMEANALYTICS TEST FAILED: " + message)
	quit(1)
