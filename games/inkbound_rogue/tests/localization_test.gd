extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")
const NAMESPACE := "localization_test"

const LOCALIZED_CONTENT_FIELDS := [
	"name",
	"description",
	"chapter",
	"title",
	"speaker",
	"text",
	"label",
	"tagline",
	"card",
	"effect",
	"hazard_name",
	"hazard_hint",
	"role",
	"short",
	"reward_text",
	"mastery",
	"hint",
	"art",
	"bonuses",
]

var game
var frames := 0


func _initialize() -> void:
	game = _new_game()
	game.debug_clear_save_files()
	game.debug_set_language(Localization.LANGUAGE_CHINESE)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		if not _validate_chinese_runtime():
			return true
	elif frames == 6:
		if not _validate_persistence_and_fallback():
			return true
		print("INKBOUND_LOCALIZATION_OK locales=en,zh_CN setting=auto/en/zh_CN persistence=ok content=translated story=translated font=cjk layout=contained runtime_switch=ok")
		_cleanup(0)
		return true
	return false


func _new_game():
	var packed = load("res://scenes/main.tscn")
	var instance = packed.instantiate()
	instance.test_mode = true
	instance.test_force_english = false
	instance.debug_set_save_namespace(NAMESPACE)
	root.add_child(instance)
	return instance


func _validate_chinese_runtime() -> bool:
	if TranslationServer.get_locale() != Localization.LANGUAGE_CHINESE:
		return _fail("explicit Simplified Chinese locale was not applied")
	if str(game.settings.get("language", "")) != Localization.LANGUAGE_CHINESE:
		return _fail("language setting did not retain its persisted identifier")
	if Localization.text("NEW GAME") != "新游戏" or Localization.text("RAZOR INK") != "锋刃墨":
		return _fail("shell or content translation catalogue is incomplete")
	if not _validate_content_catalog():
		return true
	if Localization.gameplay_text("PAGE 5") != "第 5 页" or Localization.gameplay_text("MEMORY +7") != "记忆 +7" or Localization.gameplay_text("FINAL PERIOD!  6") != "终焉句点！  6":
		return _fail("dynamic gameplay callouts were not localized")
	var font := Localization.ui_theme().default_font
	if font == null or not font.has_char("中".unicode_at(0)):
		return _fail("configured Windows font fallback cannot render Simplified Chinese")

	game.hud.show_title(game._meta_snapshot())
	if game.hud.start_button.text.find("新游戏") < 0 or game.hud.difficulty_button.text.find("标准草稿") < 0:
		return _fail("title shell did not refresh into Chinese")
	game.hud.set_input_mode(true)
	var right_trigger := _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	game.hud._unhandled_input(right_trigger)
	if not game.hud.story_visible:
		return _fail("right trigger did not open the Story Archive")
	game.hud._unhandled_input(right_trigger)
	if not game.hud.story_visible:
		return _fail("held right trigger repeatedly toggled the Story Archive")
	game.hud._unhandled_input(_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	game.hud._unhandled_input(right_trigger)
	if game.hud.story_visible:
		return _fail("right trigger did not re-arm after returning to neutral")
	game.hud._unhandled_input(_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	game.hud.show_settings()
	game.hud.settings_selected = 0
	var stick_down := _joy_axis(JOY_AXIS_LEFT_Y, 1.0)
	game.hud._unhandled_input(stick_down)
	game.hud._unhandled_input(stick_down)
	if game.hud.settings_selected != 1:
		return _fail("held left stick advanced more than one Settings row")
	game.hud._unhandled_input(_joy_axis(JOY_AXIS_LEFT_Y, 0.0))
	var language_row: int = game.hud.SETTINGS_ROWS.find(["language", "LANGUAGE"])
	if language_row < 0 or game.hud.settings_buttons[language_row].text.find("语言") < 0 or game.hud.settings_buttons[language_row].text.find("简体中文") < 0:
		return _fail("Chinese language option is not visible in Settings")
	var last_button: Button = game.hud.settings_buttons[game.hud.settings_buttons.size() - 1]
	if last_button.position.y + last_button.size.y > game.hud.settings_panel.size.y - 22.0:
		return _fail("ninth settings row overlaps the footer")

	game.hud.hide_settings()
	game.hud.set_xp(2, 5, 3)
	if game.hud.level_label.text != "等级 3":
		return _fail("level HUD remained in English")
	game.hud.set_ink_art("PALIMPSEST RING", 4.0, 8.0)
	if game.hud.ink_art_label.text.find("B/○") < 0 or game.hud.ink_art_label.text.find("墨术") < 0 or game.hud.ink_art_state_label.text.find("冷却") < 0 or game.hud.ink_art_state_label.text.find("50%") < 0 or not is_equal_approx(game.hud.ink_art_bar_fill.size.x, game.hud.ink_art_bar.size.x * 0.5):
		return _fail("gamepad Ink Art identity or cooldown progress is not explicit")
	game.hud.set_ink_art("PALIMPSEST RING", 0.0, 8.0)
	if game.hud.ink_art_state_label.text.find("就绪") < 0 or not is_equal_approx(game.hud.ink_art_bar_fill.size.x, game.hud.ink_art_bar.size.x):
		return _fail("ready Ink Art state is not explicit")
	game.hud.set_boss("THE RED EDITOR", 75.0, 100.0)
	if not game.hud.boss_panel.visible or game.hud.boss_panel.position.x < 300.0 or game.hud.boss_panel.position.y + game.hud.boss_panel.size.y > 100.0 or game.hud.boss_bar.size.y > 5.0 or not is_equal_approx(game.hud.boss_bar_fill.size.x, game.hud.boss_bar.size.x * 0.75) or game.hud.boss_label.text.find("赤红编辑") < 0:
		return _fail("boss status is not localized and anchored at the upper-right edge")
	game.hud.set_boss("", 0.0, 0.0)
	var resonant_choice := Content.upgrade("razor-ink")
	resonant_choice["_discipline_id"] = "ink-edge"
	resonant_choice["_discipline_score"] = 2
	resonant_choice["_next_threshold"] = 3
	resonant_choice["_awakens"] = true
	resonant_choice["_resonant"] = true
	resonant_choice["_draft_discipline_id"] = "ink-edge"
	resonant_choice["_draft_score"] = 2
	resonant_choice["_draft_tier"] = 0
	resonant_choice["_draft_next_threshold"] = 3
	var upgrade_choices: Array[Dictionary] = [resonant_choice, Content.upgrade("ink-wave"), Content.upgrade("merciful-revision")]
	game.hud.show_upgrade(upgrade_choices)
	if game.hud.upgrade_name_labels[0].text.find("锋刃墨") < 0 or game.hud.upgrade_description_labels[2].text.find("恢复") < 0:
		return _fail("technique cards were not localized")
	if game.hud.upgrade_title_label.text.find("当前构筑") < 0 or game.hud.upgrade_rarity_labels[0].text.find("即将觉醒") < 0 or game.hud.upgrade_rarity_labels[0].text.find("墨锋") < 0:
		return _fail("discipline identity, milestone preview, or Resonant draft copy was not localized")
	for index in range(3):
		if game.hud.upgrade_description_labels[index].get_content_height() > game.hud.upgrade_description_labels[index].size.y + 1.0:
			return _fail("Chinese technique copy overflows card %d" % index)
	game.hud.upgrade_visible = false
	game.hud.upgrade_panel.visible = false

	game.hud.show_event(Content.event("forgotten-shrine"))
	if game.hud.event_title.text.find("遗忘神龛") < 0 or game.hud.event_buttons[0].text.find("献出一次心跳") < 0:
		return _fail("event choices were not localized")
	game.hud.event_visible = false
	game.hud.event_panel.visible = false
	if not game.debug_play_story("prologue"):
		return _fail("localized prologue did not start")
	if game.cutscene.title_label.text.find("空白之页") < 0 or game.cutscene.dialogue_label.text.find("名字") < 0:
		return _fail("story title or subtitle remained untranslated")
	game.cutscene._hide()
	return true


func _validate_content_catalog() -> bool:
	var missing := PackedStringArray()
	var catalogs: Array = [
		Content.STORY,
		Content.UPGRADES,
		Content.BUILD_DISCIPLINES,
		Content.RELICS,
		Content.STARTING_WEAPONS,
		Content.ROUTES,
		Content.ENEMIES,
		Content.ACHIEVEMENTS,
		Content.META_RESTORATIONS,
		Content.PROGRESSION_UNLOCKS,
		Content.CONTRACTS,
		Content.PROOF_LEVELS,
		Content.EVENTS,
		Content.PAGE_DIRECTIVES,
		Content.ENCOUNTER_SQUADS,
	]
	for catalog in catalogs:
		_collect_missing_localizations(catalog, "", missing)
	if not missing.is_empty():
		return not _fail("visible content strings lack zh_CN entries: %s" % ", ".join(missing.slice(0, 8)))
	return true


func _collect_missing_localizations(value: Variant, field_name: String, missing: PackedStringArray) -> void:
	if value is Dictionary:
		for key in value:
			_collect_missing_localizations(value[key], str(key), missing)
		return
	if value is Array:
		for entry in value:
			_collect_missing_localizations(entry, field_name, missing)
		return
	if not (value is String or value is StringName) or field_name not in LOCALIZED_CONTENT_FIELDS:
		return
	var source := str(value)
	if source.is_empty():
		return
	if field_name == "effect" and source.to_lower() == source and not source.contains(" "):
		return
	if not Localization.ZH_CN.has(source) and source not in missing:
		missing.append(source)


func _joy_axis(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _validate_persistence_and_fallback() -> bool:
	if not game._save_run():
		return _fail("Chinese preference could not be saved")
	game.free()
	game = _new_game()
	if str(game.settings.get("language", "")) != Localization.LANGUAGE_CHINESE or TranslationServer.get_locale() != Localization.LANGUAGE_CHINESE:
		return _fail("Chinese preference did not survive a full boot")
	game.debug_set_language(Localization.LANGUAGE_ENGLISH)
	game.hud.show_title(game._meta_snapshot())
	if TranslationServer.get_locale() != Localization.LANGUAGE_ENGLISH or game.hud.start_button.text.find("NEW GAME") < 0:
		return _fail("runtime switch back to English did not refresh the shell")
	var payload: Dictionary = game._save_payload(game.save_generation + 1)
	payload["settings"].erase("language")
	game.settings["language"] = "invalid"
	game._apply_save_payload(payload)
	if str(game.settings.get("language", "")) != Localization.LANGUAGE_AUTO:
		return _fail("older profiles without a language field do not fall back to Auto")
	return true


func _fail(message: String) -> bool:
	push_error("INKBOUND_LOCALIZATION_FAIL: %s" % message)
	_cleanup(1)
	return true


func _cleanup(exit_code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.free()
	TranslationServer.set_locale(Localization.LANGUAGE_ENGLISH)
	paused = false
	quit(exit_code)
