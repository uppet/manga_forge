extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")
const NAMESPACE := "localization_test"

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
	var font := Localization.ui_theme().default_font
	if font == null or not font.has_char("中".unicode_at(0)):
		return _fail("configured Windows font fallback cannot render Simplified Chinese")

	game.hud.show_title(game._meta_snapshot())
	if game.hud.start_button.text.find("新游戏") < 0 or game.hud.difficulty_button.text.find("标准草稿") < 0:
		return _fail("title shell did not refresh into Chinese")
	game.hud.show_settings()
	var language_row: int = game.hud.SETTINGS_ROWS.find(["language", "LANGUAGE"])
	if language_row < 0 or game.hud.settings_buttons[language_row].text.find("语言") < 0 or game.hud.settings_buttons[language_row].text.find("简体中文") < 0:
		return _fail("Chinese language option is not visible in Settings")
	var last_button: Button = game.hud.settings_buttons[game.hud.settings_buttons.size() - 1]
	if last_button.position.y + last_button.size.y > game.hud.settings_panel.size.y - 22.0:
		return _fail("ninth settings row overlaps the footer")

	game.hud.hide_settings()
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
