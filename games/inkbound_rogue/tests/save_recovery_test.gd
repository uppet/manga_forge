extends SceneTree

const TEST_NAMESPACES := ["save_atomic_test", "save_future_test", "save_corrupt_test", "save_migration_test"]

var started := false
var packed: PackedScene


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_save_test()
	return false


func _run_save_test() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail("main scene did not load")
		return
	packed = loaded
	for profile_name in TEST_NAMESPACES:
		_cleanup_namespace(profile_name)

	var first = _new_test_game("save_atomic_test")
	first.best_score = 111
	first.meta_shards = 7
	first.settings["aim_assist"] = 0.25
	first.settings["reduced_flashes"] = true
	first.settings["ink_art_cutins"] = false
	if not first._save_run() or first.save_generation != 1:
		_fail("first atomic save did not commit generation 1")
		return
	first.best_score = 222
	first.meta_shards = 9
	first.settings["aim_assist"] = 0.0
	first.settings["reduced_flashes"] = false
	first.settings["ink_art_cutins"] = true
	if not first._save_run() or first.save_generation != 2:
		_fail("second atomic save did not commit generation 2")
		return
	var primary: Dictionary = first._read_save_file(first.save_path)
	var backup: Dictionary = first._read_save_file(first.backup_save_path)
	if primary["state"] != "ok" or int(primary["data"].get("best_score", 0)) != 222:
		_fail("primary save did not contain the newest generation")
		return
	if backup["state"] != "ok" or int(backup["data"].get("best_score", 0)) != 111:
		_fail("rolling backup did not preserve the previous generation")
		return
	_write_text(first.save_path, "{ interrupted write")
	first.free()

	var recovered = _new_test_game("save_atomic_test")
	if not recovered.save_recovered or recovered.best_score != 111 or recovered.save_generation != 1:
		_fail("corrupt primary did not recover the validated backup")
		return
	if not is_equal_approx(float(recovered.settings.get("aim_assist", -1.0)), 0.25) or recovered.settings.get("reduced_flashes", false) != true or recovered.settings.get("ink_art_cutins", true) != false:
		_fail("backup recovery did not preserve controller/accessibility settings")
		return
	if not FileAccess.file_exists(recovered.corrupt_save_path):
		_fail("corrupt primary was not quarantined for inspection")
		return
	if recovered._read_save_file(recovered.save_path)["state"] != "ok":
		_fail("recovered backup was not restored to the primary path")
		return
	recovered.best_score = 333
	if not recovered._save_run() or recovered.save_generation != 2:
		_fail("saving after recovery did not resume atomic generations")
		return
	recovered.free()

	var future_payload := _minimal_payload(999, 444)
	var future_probe = _new_unready_game("save_future_test")
	_write_text(future_probe.save_path, JSON.stringify(future_payload))
	future_probe.free()
	var future = _new_test_game("save_future_test")
	var future_text := _read_text(future.save_path)
	if not future.save_incompatible or future.best_score != 0:
		_fail("future-schema save was not protected from downgrade loading")
		return
	future.best_score = 9999
	if future._save_run() or _read_text(future.save_path) != future_text:
		_fail("future-schema save was overwritten by the older runtime")
		return
	future.free()

	var migration_probe = _new_unready_game("save_migration_test")
	_write_text(migration_probe.save_path, JSON.stringify(_minimal_payload(11, 555)))
	migration_probe.free()
	var migrated = _new_test_game("save_migration_test")
	if migrated.save_incompatible or migrated.best_score != 555 or not migrated.recent_runs.is_empty():
		_fail("schema-11 profile did not migrate into the schema-12 runtime")
		return
	if not is_equal_approx(float(migrated.settings.get("aim_assist", -1.0)), 0.45) or migrated.settings.get("reduced_flashes", true) == true or migrated.settings.get("ink_art_cutins", false) != true:
		_fail("older profile did not receive safe defaults for new accessibility settings")
		return
	if not migrated._save_run():
		_fail("migrated schema-11 profile could not be committed as schema 12")
		return
	var migrated_payload: Dictionary = migrated._read_save_file(migrated.save_path)
	if migrated_payload["state"] != "ok" or int(migrated_payload["data"].get("schema_version", 0)) != 12:
		_fail("migrated profile was not rewritten with schema 12")
		return
	migrated.free()

	var corrupt_probe = _new_unready_game("save_corrupt_test")
	_write_text(corrupt_probe.save_path, "not json")
	_write_text(corrupt_probe.backup_save_path, "also not json")
	corrupt_probe.free()
	var corrupt = _new_test_game("save_corrupt_test")
	if not corrupt.save_corrupt_detected:
		_fail("double corruption was not surfaced")
		return
	if not FileAccess.file_exists(corrupt.corrupt_save_path) or not FileAccess.file_exists(corrupt.corrupt_backup_save_path):
		_fail("double corruption was not quarantined without data loss")
		return
	if FileAccess.file_exists(corrupt.save_path) or FileAccess.file_exists(corrupt.backup_save_path):
		_fail("corrupt active files remained in the load path")
		return
	corrupt.free()

	for profile_name in TEST_NAMESPACES:
		_cleanup_namespace(profile_name)
	print("INKBOUND_SAVE_OK atomic=ok backup=ok recovery=ok quarantine=ok future=protected migration=11to12 schema=12 accessibility_settings=preserved/defaulted ink_art_cutins=preserved/default_on")
	paused = false
	quit(0)


func _new_unready_game(profile_name: String) -> Node:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace(profile_name)
	return game


func _new_test_game(profile_name: String) -> Node:
	var game = _new_unready_game(profile_name)
	root.add_child(game)
	return game


func _minimal_payload(schema: int, score: int) -> Dictionary:
	return {
		"schema_version": schema,
		"save_generation": 1,
		"best_score": score,
		"best_kills": 0,
		"meta_shards": 0,
		"lifetime_runs": 0,
		"settings": {},
	}


func _namespace_paths(profile_name: String) -> Array[String]:
	var prefix := "user://inkbound_%s" % profile_name
	return [
		prefix + ".json",
		prefix + ".backup.json",
		prefix + ".corrupt.json",
		prefix + ".backup.corrupt.json",
		prefix + ".tmp.json",
	]


func _cleanup_namespace(profile_name: String) -> void:
	for path in _namespace_paths(profile_name):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("could not write test fixture: " + path)
		return
	file.store_string(text)
	file.flush()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _fail(message: String) -> void:
	push_error("INKBOUND_SAVE_FAIL: " + message)
	for profile_name in TEST_NAMESPACES:
		_cleanup_namespace(profile_name)
	Engine.time_scale = 1.0
	paused = false
	quit(1)
