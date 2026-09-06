extends SceneTree

const Localization = preload("res://scripts/localization.gd")
const NAMESPACE := "privacy_consent_test"

var game
var frames := 0
var failed := false


func _initialize() -> void:
	var packed = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	game.test_force_english = false
	game.debug_set_save_namespace(NAMESPACE)
	root.add_child(game)
	game.debug_clear_save_files()


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		_validate_required_choice()
	elif frames == 6 and not failed:
		_validate_privacy_page()
	elif frames == 9 and not failed:
		print("INKBOUND_PRIVACY_CONSENT_OK first_run=explicit default=deny controller=modal settings=withdraw privacy=bilingual queue=local_only")
		_cleanup(0)
	return false


func _validate_required_choice() -> void:
	if not is_instance_valid(game.hud):
		return _fail("HUD was not ready for the consent test")
	game.debug_set_language(Localization.LANGUAGE_CHINESE)
	game.run_started = false
	game.hud.show_title(game._meta_snapshot())
	game.settings["analytics_consent"] = false
	game.settings["analytics_consent_decided"] = false
	game.hud.set_settings(game.settings)
	game.hud.show_analytics_consent_required()
	game.hud.debug_finish_popup_transition(game.hud.analytics_consent_panel)
	if not game.hud.analytics_consent_visible or not game.hud.analytics_consent_required:
		return _fail("first-run consent disclosure did not become mandatory")
	if game.hud.analytics_consent_selected != 0 or game.hud.analytics_consent_deny_button.text != "不发送":
		return _fail("first-run consent did not default to the explicit deny choice")
	if game.hud.analytics_consent_body.text.find("GameAnalytics") < 0 or game.hud.analytics_consent_body.text.find("IP") < 0 or game.hud.analytics_consent_body.text.find("PRIVACY_NOTICE.txt") < 0:
		return _fail("first-run disclosure omitted processor, network, or full-notice information")
	for button in game.hud.title_navigation_buttons:
		if not button.disabled:
			return _fail("title control remained interactive behind required consent")
	game.hud.analytics_consent_deny_button.pressed.emit()
	game.hud.debug_finish_popup_transition(game.hud.analytics_consent_panel)
	if game.hud.analytics_consent_visible or not bool(game.settings.get("analytics_consent_decided", false)) or bool(game.settings.get("analytics_consent", true)):
		return _fail("deny choice was not persisted as a completed decision")
	game.hud.show_analytics_consent_required()
	game.hud.debug_finish_popup_transition(game.hud.analytics_consent_panel)
	game.hud.analytics_consent_selected = 1
	game.hud._refresh_analytics_consent()
	game.hud.analytics_consent_allow_button.pressed.emit()
	game.hud.debug_finish_popup_transition(game.hud.analytics_consent_panel)
	if not bool(game.settings.get("analytics_consent", false)) or not bool(game.settings.get("analytics_consent_decided", false)):
		return _fail("affirmative choice did not enable the optional setting")
	var analytics: Node = game.get_node_or_null("/root/GameAnalyticsClient")
	if analytics != null and bool(analytics.debug_snapshot().get("active", false)):
		return _fail("automated consent test opened a real analytics session")


func _validate_privacy_page() -> void:
	game.hud.show_settings()
	game.hud.debug_finish_popup_transition(game.hud.settings_panel)
	var privacy_row: int = game.hud.SETTINGS_ROWS.find(["privacy", "DATA & PRIVACY"])
	if privacy_row < 0:
		return _fail("Data & Privacy is absent from controller-navigable Settings")
	game.hud.settings_selected = privacy_row
	game.hud._adjust_setting("privacy", 1)
	game.hud.debug_finish_popup_transition(game.hud.privacy_panel)
	if not game.hud.privacy_visible or game.hud._active_modal_panel() != game.hud.privacy_panel:
		return _fail("Data & Privacy did not open as the top modal")
	if game.hud.privacy_body.text.find("不会收到姓名") < 0 or game.hud.privacy_body.text.find("不会自动上传") < 0:
		return _fail("Chinese privacy page omitted collection or local-recorder boundaries")
	if game.hud.privacy_deny_button.text != "不发送" or game.hud.privacy_allow_button.text != "允许发送" or game.hud.privacy_selected != 1:
		return _fail("Data & Privacy did not expose the current consent choice")
	for button in game.hud.settings_buttons:
		if not button.disabled:
			return _fail("Settings control remained interactive behind Data & Privacy")
	var left_event := InputEventAction.new()
	left_event.action = "move_left"
	left_event.pressed = true
	game.hud._unhandled_input(left_event)
	if bool(game.settings.get("analytics_consent", true)) or game.hud.privacy_selected != 0:
		return _fail("left input did not disable optional usage statistics from Data & Privacy")
	var right_event := InputEventAction.new()
	right_event.action = "move_right"
	right_event.pressed = true
	game.hud._unhandled_input(right_event)
	if not bool(game.settings.get("analytics_consent", false)) or game.hud.privacy_selected != 1:
		return _fail("right input did not enable optional usage statistics from Data & Privacy")
	game.hud.hide_privacy_notice()
	game.hud.debug_finish_popup_transition(game.hud.privacy_panel)
	if game.hud.privacy_visible or game.hud._active_modal_panel() != game.hud.settings_panel:
		return _fail("closing Data & Privacy did not restore Settings as the active modal")


func _cleanup(code: int) -> void:
	if is_instance_valid(game):
		game.debug_clear_save_files()
		game.queue_free()
	quit(code)


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("PRIVACY CONSENT TEST FAILED: " + message)
	_cleanup(1)
