extends RefCounted
class_name InkboundStartupState

const Content = preload("res://scripts/content_db.gd")

const SCHEMA := 1
const ENVIRONMENT_PATH := "INKBOUND_STARTUP_STATE"
const ARGUMENT_PREFIX := "--startup-state="
const DIFFICULTY_IDS := ["story", "standard", "redline"]
const BOSS_IDS := ["editor", "binder", "author"]
const WEAPON_UPGRADE_IDS := ["greatbrush", "needlepoint", "seal-caster", "twin-stroke"]
const LANGUAGE_IDS := ["auto", "en", "zh_CN"]


static func requested_path() -> String:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		var argument := str(arguments[index])
		if argument.begins_with(ARGUMENT_PREFIX):
			return argument.trim_prefix(ARGUMENT_PREFIX).strip_edges()
		if argument == "--startup-state" and index + 1 < arguments.size():
			return str(arguments[index + 1]).strip_edges()
	return OS.get_environment(ENVIRONMENT_PATH).strip_edges()


static func load_requested() -> Dictionary:
	var path := requested_path()
	if path.is_empty():
		return _result(false, false, "", {}, [], [])
	var loaded := load_file(path)
	loaded["requested"] = true
	return loaded


static func load_file(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return _result(true, false, path, {}, ["startup-state JSON does not exist"], [])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(true, false, path, {}, ["startup-state JSON could not be opened"], [])
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		return _result(true, false, path, {}, ["invalid JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()]], [])
	return parse_document(parser.data, path)


static func parse_document(document: Variant, source: String = "<memory>") -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if not (document is Dictionary):
		return _result(true, false, source, {}, ["root must be a JSON object"], [])
	var raw: Dictionary = document
	if int(raw.get("schema", 0)) != SCHEMA:
		errors.append("schema must be %d" % SCHEMA)
	var enabled_value: Variant = raw.get("enabled", false)
	if not (enabled_value is bool):
		errors.append("enabled must be true or false")
	var enabled: bool = enabled_value == true
	var profile := _safe_profile(str(raw.get("profile", "startup-state")))
	var seed_value := _read_int(raw, "seed", 424242, 1, 2147483647, "seed", errors, warnings)

	var settings_raw := _read_object(raw, "settings", "settings", errors)
	var settings := {
		"language": str(settings_raw.get("language", "auto")),
		"ink_art_cutins": _read_bool(settings_raw, "ink_art_cutins", true, "settings.ink_art_cutins", errors),
		"hit_stop": _read_bool(settings_raw, "hit_stop", true, "settings.hit_stop", errors),
		"reduced_flashes": _read_bool(settings_raw, "reduced_flashes", false, "settings.reduced_flashes", errors),
	}
	if settings["language"] not in LANGUAGE_IDS:
		errors.append("settings.language must be auto, en, or zh_CN")

	var run_raw := _read_object(raw, "run", "run", errors)
	var page := _read_int(run_raw, "page", 1, 1, 12, "run.page", errors, warnings)
	var difficulty := str(run_raw.get("difficulty", "standard"))
	if difficulty not in DIFFICULTY_IDS:
		errors.append("run.difficulty is unknown: %s" % difficulty)
	var contract := str(run_raw.get("contract", "open-draft"))
	if not _has_id(Content.CONTRACTS, contract):
		errors.append("run.contract is unknown: %s" % contract)
	var starting_weapon := str(run_raw.get("starting_weapon", "marginalia"))
	if Content.starting_weapon(starting_weapon).is_empty():
		errors.append("run.starting_weapon is unknown: %s" % starting_weapon)
	var route := str(run_raw.get("route", ""))
	if not route.is_empty() and Content.route(route).is_empty():
		errors.append("run.route is unknown: %s" % route)
	var boss := str(run_raw.get("boss", "auto"))
	if boss not in ["auto", "none"] and boss not in BOSS_IDS:
		errors.append("run.boss must be auto, none, editor, binder, or author")
	var run := {
		"page": page,
		"page_progress": _read_float(run_raw, "page_progress", 0.04, 0.0, 0.95, "run.page_progress", errors, warnings),
		"difficulty": difficulty,
		"contract": contract,
		"proof_depth": _read_int(run_raw, "proof_depth", 0, 0, Content.PROOF_LEVELS.size() - 1, "run.proof_depth", errors, warnings),
		"starting_weapon": starting_weapon,
		"route": route,
		"spawn_page_content": _read_bool(run_raw, "spawn_page_content", true, "run.spawn_page_content", errors),
		"ambient_spawning": _read_bool(run_raw, "ambient_spawning", true, "run.ambient_spawning", errors),
		"page_timer": _read_bool(run_raw, "page_timer", true, "run.page_timer", errors),
		"clear_existing_enemies": _read_bool(run_raw, "clear_existing_enemies", true, "run.clear_existing_enemies", errors),
		"boss": boss,
		"boss_intro": _read_bool(run_raw, "boss_intro", true, "run.boss_intro", errors),
		"boss_position": _read_vector(run_raw, "boss_position", [150.0, 0.0], "run.boss_position", errors),
		"memory": _read_int(run_raw, "memory", 0, 0, 999999, "run.memory", errors, warnings),
		"kills": _read_int(run_raw, "kills", 0, 0, 999999, "run.kills", errors, warnings),
	}

	var player_raw := _read_object(raw, "player", "player", errors)
	var level := _read_int(player_raw, "level", maxi(1, page + 2), 1, 100, "player.level", errors, warnings)
	var upgrades := _read_upgrades(player_raw.get("upgrades", []), level, errors, warnings)
	var random_upgrades_raw := _read_object(player_raw, "random_upgrades", "player.random_upgrades", errors)
	var random_upgrade_tags := _read_string_array(random_upgrades_raw, "tags", "player.random_upgrades.tags", errors)
	for tag in random_upgrade_tags:
		if not _known_upgrade_tag(tag):
			errors.append("player.random_upgrades.tags contains unknown tag: %s" % tag)
	var random_upgrade_exclude := _read_string_array(random_upgrades_raw, "exclude", "player.random_upgrades.exclude", errors)
	for upgrade_id in random_upgrade_exclude:
		if Content.upgrade(upgrade_id).is_empty():
			errors.append("player.random_upgrades.exclude contains unknown upgrade: %s" % upgrade_id)
	var relics := _read_relics(player_raw.get("relics", []), "player.relics", errors, warnings)
	var random_relics_raw := _read_object(player_raw, "random_relics", "player.random_relics", errors)
	var random_relic_exclude := _read_string_array(random_relics_raw, "exclude", "player.random_relics.exclude", errors)
	for relic_id in random_relic_exclude:
		if Content.relic(relic_id).is_empty():
			errors.append("player.random_relics.exclude contains unknown relic: %s" % relic_id)
	var player := {
		"level": level,
		"xp": _read_int(player_raw, "xp", 0, 0, 9999, "player.xp", errors, warnings),
		"health_ratio": _read_float(player_raw, "health_ratio", 1.0, 0.01, 1.0, "player.health_ratio", errors, warnings),
		"guard": _read_float(player_raw, "guard", 0.0, 0.0, 100.0, "player.guard", errors, warnings),
		"ink_art_ready": _read_bool(player_raw, "ink_art_ready", true, "player.ink_art_ready", errors),
		"position": _read_vector(player_raw, "position", [0.0, 0.0], "player.position", errors),
		"upgrades": upgrades,
		"random_upgrades": {
			"count": _read_int(random_upgrades_raw, "count", 0, 0, 100, "player.random_upgrades.count", errors, warnings),
			"max_stacks_per_upgrade": _read_int(random_upgrades_raw, "max_stacks_per_upgrade", 2, 1, 6, "player.random_upgrades.max_stacks_per_upgrade", errors, warnings),
			"allow_weapon_forms": _read_bool(random_upgrades_raw, "allow_weapon_forms", false, "player.random_upgrades.allow_weapon_forms", errors),
			"tags": random_upgrade_tags,
			"exclude": random_upgrade_exclude,
		},
		"relics": relics,
		"random_relics": {
			"count": _read_int(random_relics_raw, "count", 0, 0, Content.RELICS.size(), "player.random_relics.count", errors, warnings),
			"exclude": random_relic_exclude,
		},
	}
	_validate_weapon_conflicts(starting_weapon, upgrades, errors)

	var enemies_raw: Variant = raw.get("enemies", [])
	var enemies: Array = []
	if not (enemies_raw is Array):
		errors.append("enemies must be an array")
	else:
		for index in range(enemies_raw.size()):
			var entry_value: Variant = enemies_raw[index]
			if not (entry_value is Dictionary):
				errors.append("enemies[%d] must be an object" % index)
				continue
			var entry: Dictionary = entry_value
			var kind := str(entry.get("kind", "mask"))
			if not Content.ENEMIES.has(kind):
				errors.append("enemies[%d].kind is unknown: %s" % [index, kind])
				continue
			enemies.append({
				"kind": kind,
				"position": _read_vector(entry, "position", [100.0, 0.0], "enemies[%d].position" % index, errors),
				"relative_to_player": _read_bool(entry, "relative_to_player", true, "enemies[%d].relative_to_player" % index, errors),
				"elite": _read_bool(entry, "elite", false, "enemies[%d].elite" % index, errors),
				"health_ratio": _read_float(entry, "health_ratio", 1.0, 0.01, 1.0, "enemies[%d].health_ratio" % index, errors, warnings),
			})

	var config := {
		"schema": SCHEMA,
		"enabled": enabled,
		"profile": profile,
		"seed": seed_value,
		"settings": settings,
		"run": run,
		"player": player,
		"enemies": enemies,
	}
	return _result(true, enabled and errors.is_empty(), source, config, errors, warnings)


static func _read_object(container: Dictionary, key: String, path: String, errors: Array[String]) -> Dictionary:
	var value: Variant = container.get(key, {})
	if value is Dictionary:
		return value
	errors.append("%s must be an object" % path)
	return {}


static func _read_bool(container: Dictionary, key: String, default_value: bool, path: String, errors: Array[String]) -> bool:
	if not container.has(key):
		return default_value
	var value: Variant = container[key]
	if value is bool:
		return value
	errors.append("%s must be true or false" % path)
	return default_value


static func _read_int(container: Dictionary, key: String, default_value: int, minimum: int, maximum: int, path: String, errors: Array[String], warnings: Array[String]) -> int:
	if not container.has(key):
		return default_value
	var value: Variant = container[key]
	if not (value is int or value is float):
		errors.append("%s must be a number" % path)
		return default_value
	var numeric := int(value)
	var clamped := clampi(numeric, minimum, maximum)
	if clamped != numeric:
		warnings.append("%s was clamped to %d" % [path, clamped])
	return clamped


static func _read_float(container: Dictionary, key: String, default_value: float, minimum: float, maximum: float, path: String, errors: Array[String], warnings: Array[String]) -> float:
	if not container.has(key):
		return default_value
	var value: Variant = container[key]
	if not (value is int or value is float):
		errors.append("%s must be a number" % path)
		return default_value
	var numeric := float(value)
	var clamped := clampf(numeric, minimum, maximum)
	if not is_equal_approx(clamped, numeric):
		warnings.append("%s was clamped to %.3f" % [path, clamped])
	return clamped


static func _read_vector(container: Dictionary, key: String, default_value: Array, path: String, errors: Array[String]) -> Array:
	if not container.has(key):
		return default_value.duplicate()
	var value: Variant = container[key]
	if not (value is Array) or value.size() != 2 or not (value[0] is int or value[0] is float) or not (value[1] is int or value[1] is float):
		errors.append("%s must be a two-number array [x, y]" % path)
		return default_value.duplicate()
	return [clampf(float(value[0]), -1000.0, 1000.0), clampf(float(value[1]), -1000.0, 1000.0)]


static func _read_string_array(container: Dictionary, key: String, path: String, errors: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var value: Variant = container.get(key, [])
	if not (value is Array):
		errors.append("%s must be an array of strings" % path)
		return result
	for item in value:
		if not (item is String):
			errors.append("%s must contain only strings" % path)
			continue
		var clean := str(item).strip_edges()
		if not clean.is_empty() and clean not in result:
			result.append(clean)
	return result


static func _read_upgrades(value: Variant, level: int, errors: Array[String], warnings: Array[String]) -> Array:
	var totals := {}
	if not (value is Array):
		errors.append("player.upgrades must be an array")
		return []
	for index in range(value.size()):
		var upgrade_id := ""
		var stacks := 1
		if value[index] is String:
			upgrade_id = str(value[index])
		elif value[index] is Dictionary:
			upgrade_id = str(value[index].get("id", ""))
			stacks = _read_int(value[index], "stacks", 1, 1, 100, "player.upgrades[%d].stacks" % index, errors, warnings)
		else:
			errors.append("player.upgrades[%d] must be an id string or object" % index)
			continue
		var definition := Content.upgrade(upgrade_id)
		if definition.is_empty():
			errors.append("player.upgrades[%d] is unknown: %s" % [index, upgrade_id])
			continue
		if level < int(definition.get("min_level", 1)):
			errors.append("player.upgrades[%d] requires level %d" % [index, int(definition.get("min_level", 1))])
		totals[upgrade_id] = int(totals.get(upgrade_id, 0)) + stacks
	var result: Array = []
	for definition in Content.UPGRADES:
		var upgrade_id := str(definition["id"])
		if not totals.has(upgrade_id):
			continue
		var stacks := int(totals[upgrade_id])
		var maximum := int(definition.get("max_stacks", 1))
		if stacks > maximum:
			errors.append("player.upgrades %s requests %d stacks; maximum is %d" % [upgrade_id, stacks, maximum])
			stacks = maximum
		result.append({"id": upgrade_id, "stacks": stacks})
	return result


static func _read_relics(value: Variant, path: String, errors: Array[String], warnings: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		errors.append("%s must be an array of relic ids" % path)
		return result
	for relic_value in value:
		if not (relic_value is String):
			errors.append("%s must contain only strings" % path)
			continue
		var relic_id := str(relic_value)
		if Content.relic(relic_id).is_empty():
			errors.append("%s contains unknown relic: %s" % [path, relic_id])
		elif relic_id in result:
			warnings.append("%s ignored duplicate relic: %s" % [path, relic_id])
		else:
			result.append(relic_id)
	return result


static func _validate_weapon_conflicts(starting_weapon: String, upgrades: Array, errors: Array[String]) -> void:
	var forms: Array[String] = []
	if starting_weapon in WEAPON_UPGRADE_IDS:
		forms.append(starting_weapon)
	for entry in upgrades:
		var upgrade_id := str(entry.get("id", ""))
		if upgrade_id in WEAPON_UPGRADE_IDS and upgrade_id not in forms:
			forms.append(upgrade_id)
	if forms.size() > 1:
		errors.append("only one weapon form may be active: %s" % ", ".join(forms))


static func _known_upgrade_tag(tag: String) -> bool:
	for definition in Content.UPGRADES:
		if tag in definition.get("tags", []):
			return true
	return false


static func _has_id(entries: Array, requested_id: String) -> bool:
	for entry in entries:
		if str(entry.get("id", "")) == requested_id:
			return true
	return false


static func _safe_profile(value: String) -> String:
	var result := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			result += character.to_lower()
		elif not result.ends_with("-"):
			result += "-"
	result = result.trim_prefix("-").trim_suffix("-").left(40)
	return result if not result.is_empty() else "startup-state"


static func _result(requested: bool, active: bool, source: String, config: Dictionary, errors: Array, warnings: Array) -> Dictionary:
	return {
		"requested": requested,
		"active": active,
		"source": source,
		"config": config,
		"errors": errors,
		"warnings": warnings,
	}
