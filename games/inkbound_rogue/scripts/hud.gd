extends CanvasLayer
class_name InkboundHUD

const Content = preload("res://scripts/content_db.gd")
const Localization = preload("res://scripts/localization.gd")

signal upgrade_selected(index: int)
signal relic_selected(index: int)
signal event_selected(index: int)
signal restart_requested
signal return_to_title_requested
signal pause_requested
signal start_requested(difficulty_id: String, contract_id: String, starting_weapon_id: String, proof_depth: int)
signal daily_requested
signal continue_requested
signal save_return_requested
signal story_requested(sequence_id: String)
signal meta_upgrade_requested(upgrade_id: String)
signal setting_adjusted(setting_id: String, direction: int)
signal binding_changed(action_id: String, device_type: String, binding: Dictionary)
signal bindings_reset_requested
signal manual_visibility_changed(visible: bool)
signal quit_confirmation_changed(visible: bool)
signal quit_confirmed
signal ui_sound_requested(sound_id: String)

const DEEP_INK := Color("08070b")
const INK := Color("141218")
const PAPER := Color("efe2c4")
const WHITE := Color("fff8e0")
const CRIMSON := Color("d33037")
const GOLD := Color("f2b344")
const UPGRADE_OPEN_DURATION := 0.24
const UPGRADE_CARD_STAGGER := 0.025
const UPGRADE_CLOSE_DURATION := 0.18
const POPUP_FADE_IN_DURATION := 0.16
const POPUP_FADE_OUT_DURATION := 0.12
const POPUP_START_SCALE := Vector2(0.97, 0.97)
const DEFEAT_FADE_DURATION := 1.25
const DEFEAT_INPUT_DELAY_SECONDS := 1.5
const DEFEAT_RELEASE_ACTIONS := ["restart", "attack", "dash", "special", "pause"]

var hp_bar: ColorRect
var hp_bar_fill: ColorRect
var xp_bar: ColorRect
var xp_bar_fill: ColorRect
var top_panel: ColorRect
var level_label: Label
var wave_label: Label
var score_label: Label
var dash_label: Label
var ink_art_panel: ColorRect
var ink_art_label: Label
var ink_art_state_label: Label
var ink_art_bar: ColorRect
var ink_art_bar_fill: ColorRect
var ink_art_name := "PALIMPSEST RING"
var ink_art_source_name := "PALIMPSEST RING"
var ink_art_remaining := 0.0
var ink_art_maximum := 8.0
var upgrade_panel: ColorRect
var upgrade_title_label: Label
var upgrade_buttons: Array[Button] = []
var upgrade_input_labels: Array[RichTextLabel] = []
var upgrade_name_labels: Array[RichTextLabel] = []
var upgrade_description_labels: Array[RichTextLabel] = []
var upgrade_rarity_labels: Array[RichTextLabel] = []
var relic_draft_panel: ColorRect
var relic_draft_source_label: Label
var relic_draft_buttons: Array[Button] = []
var relic_draft_input_labels: Array[RichTextLabel] = []
var relic_draft_name_labels: Array[RichTextLabel] = []
var relic_draft_description_labels: Array[RichTextLabel] = []
var relic_draft_footer_labels: Array[RichTextLabel] = []
var event_panel: ColorRect
var event_title: Label
var event_body: Label
var event_buttons: Array[Button] = []
var event_visible := false
var current_event: Dictionary = {}
var game_over_backdrop: ColorRect
var game_over_panel: ColorRect
var game_over_title: Label
var game_over_label: Label
var victory_credits_panel: ColorRect
var victory_credits_title: Label
var victory_credits_body: Label
var victory_credits_prompt: Label
var victory_credits_visible := false
var victory_credits_final := false
var victory_credit_page := 0
var victory_credit_pages: Array[Dictionary] = []
var victory_credit_tween: Tween
var pause_panel: ColorRect
var pause_label: Label
var pause_resume_button: Button
var pause_save_return_button: Button
var pause_quit_button: Button
var pause_help_label: Label
var pause_navigation_buttons: Array[Button] = []
var pause_navigation_index := 0
var quit_panel: ColorRect
var quit_title_label: Label
var quit_body_label: Label
var quit_status_label: Label
var quit_cancel_button: Button
var quit_confirm_button: Button
var quit_visible := false
var quit_waiting := false
var quit_from_active_run := false
var quit_navigation_index := 0
var controls_label: Label
var restart_button: Button
var device_notice: Label
var device_notice_tween: Tween
var upgrade_visible := false
var upgrade_transitioning := false
var upgrade_transition_phase := ""
var upgrade_transition_tween: Tween
var pending_upgrade_index := -1
var popup_transitions: Dictionary = {}
var popup_button_states: Dictionary = {}
var popup_modal_stack: Array[Control] = []
var modal_button_states: Dictionary = {}
var relic_draft_visible := false
var game_over_visible := false
var game_over_panel_revealed := false
var game_over_input_ready := false
var game_over_input_deadline_msec := 0
var game_over_sequence := 0
var using_gamepad := false
var input_enabled := true
var ui_gamepad_latches: Dictionary = {}
var current_choices: Array[Dictionary] = []
var current_relic_choices: Array[Dictionary] = []
var shard_label: Label
var relic_label: Label
var shard_amount := 0
var current_relic_ids: Array[String] = []
var objective_label: Label
var build_label: Label
var objective_source := ""
var build_source := ""
var directive_source: Dictionary = {}
var last_result_summary: Dictionary = {}
var boss_bar: ColorRect
var boss_bar_fill: ColorRect
var boss_label: Label
var boss_panel: ColorRect
var directive_panel: ColorRect
var directive_title: RichTextLabel
var directive_progress: RichTextLabel
var directive_reward: RichTextLabel
var directive_bar: ColorRect
var directive_bar_fill: ColorRect
var title_panel: ColorRect
var title_stats_label: Label
var difficulty_button: Button
var contract_button: Button
var contract_description_label: Label
var proof_button: Button
var proof_panel: ColorRect
var proof_buttons: Array[Button] = []
var proof_title_label: Label
var proof_description_label: Label
var proof_visible := false
var proof_selected := 0
var proof_depth := 0
var daily_button: Button
var daily_panel: ColorRect
var daily_title_label: Label
var daily_contract_label: Label
var daily_rules_label: Label
var daily_record_label: Label
var daily_start_button: Button
var daily_visible := false
var restore_title_label: Label
var start_button: Button
var continue_button: Button
var story_button: Button
var settings_button: Button
var title_quit_button: Button
var history_button: Button
var achievements_button: Button
var codex_button: Button
var restoration_open_button: Button
var restoration_panel: ColorRect
var restoration_status_label: Label
var meta_upgrade_buttons: Array[Button] = []
var restoration_visible := false
var restoration_selected := 0
var title_visible := false
var difficulty_index := 1
var difficulty_ids := ["story", "standard", "redline"]
var difficulty_names := ["STORY DRAFT", "STANDARD DRAFT", "REDLINE DRAFT"]
var contract_index := 0
var title_data: Dictionary = {}
var codex_panel: ColorRect
var codex_label: Label
var codex_visible := false
var achievements_panel: ColorRect
var achievements_label: Label
var achievements_visible := false
var history_panel: ColorRect
var history_label: Label
var history_visible := false
var story_panel: ColorRect
var story_buttons: Array[Button] = []
var story_entries: Array[Dictionary] = []
var story_visible := false
var story_selected := 0
var loadout_panel: ColorRect
var loadout_buttons: Array[Button] = []
var loadout_description_label: Label
var loadout_visible := false
var loadout_selected := 0
var new_game_armed := false
var achievement_toast: ColorRect
var achievement_toast_label: Label
var achievement_toast_tween: Tween
var achievement_queue: Array[Dictionary] = []
var pause_options_button: Button
var settings_panel: ColorRect
var settings_buttons: Array[Button] = []
var settings_values: Dictionary = {}
var settings_visible := false
var settings_selected := 0
var bindings_panel: ColorRect
var binding_buttons: Array[Button] = []
var binding_status_label: Label
var bindings_visible := false
var binding_values: Dictionary = {}
var binding_selected_row := 0
var binding_selected_device := 0
var binding_waiting := false
var waiting_action := ""
var waiting_device := ""
var manual_panel: ColorRect
var manual_kicker_label: Label
var manual_body_label: RichTextLabel
var manual_page_label: Label
var manual_prev_button: Button
var manual_close_button: Button
var manual_next_button: Button
var manual_button: Button
var pause_manual_button: Button
var manual_visible := false
var manual_page := 0
var title_navigation_label: Label
var title_navigation_cursor: ColorRect
var title_navigation_buttons: Array[Button] = []
var title_navigation_actions: Array[String] = []
var title_navigation_index := 0

const FIELD_MANUAL_PAGES := [
	{
		"title": "THE FIRST CUT",
		"keyboard": "WASD / ARROWS   MOVE\nMOUSE   AIM\nLEFT MOUSE / J   SLASH\nRIGHT MOUSE / SPACE / K   DASH\nMIDDLE MOUSE / E   INK ART\nESC   PAUSE        F1 / H   MANUAL",
		"gamepad": "LEFT STICK / D-PAD   MOVE\nRIGHT STICK   AIM\nX / RIGHT TRIGGER   SLASH\nA / LEFT BUMPER   DASH\nB   INK ART\nSTART   PAUSE        LEFT TRIGGER   MANUAL",
	},
	{
		"title": "READ THE PAGE",
		"body": "SURVIVE TWELVE TIMED PAGES.\n\nWhite and gold shapes warn attacks; cyan diamonds are hostile shots; crimson ground is danger. Dash during impact to pass through harm. Defeated masks drop Ink, recovery, Memory, and rare combat supplies. Pages 4, 8, and 12 end with an authored boss encounter.",
	},
	{
		"title": "WRITE A BUILD",
		"body": "INK RAISES YOUR LEVEL AND PAUSES THE PAGE.\n\nChoose techniques to write one of six disciplines. At 3 and 6 matching points it awakens a run bonus. Once a discipline has 2 points, every draft includes one RESONANT choice for it. Relics last this draft. Weapon forms replace slash rhythm and Ink Art.",
	},
	{
		"title": "RESTORE AND RETURN",
		"body": "EVERY DRAFT RECOVERS A DIFFERENT MARGIN.\n\nRoutes and Directives change each attempt. Daily Chronicle (T / D-pad down) fixes one dated seed and seals Restoration for comparable drafts. After an ending, P / left-stick click opens the Proof Ledger. Banked Memory buys ranks with M / right-stick click. Save & Return preserves a live draft; Story Archive replays scenes safely.",
	},
	{
		"title": "CREDITS & LEGAL",
		"body": "DESIGN, NARRATIVE, CODE, AND PRODUCTION\nManga Forge project pipeline\n\nENGINE\nGodot Engine - Juan Linietsky, Ariel Manzur, and contributors - MIT License\n\nART & AUDIO\nOriginal project assets; selected narrative illustrations created with OpenAI image tools under project direction. Full notices ship beside the executable in THIRD_PARTY_NOTICES.txt.",
	},
]

const SETTINGS_ROWS := [
	["master", "MASTER VOLUME"],
	["music", "MUSIC VOLUME"],
	["sfx", "SFX VOLUME"],
	["vibration", "GAMEPAD VIBRATION"],
	["aim_assist", "CONTROLLER AIM ASSIST"],
	["screen_shake", "SCREEN SHAKE"],
	["hit_stop", "IMPACT FREEZE"],
	["ink_art_cutins", "INK ART CUT-INS"],
	["reduced_flashes", "REDUCED FLASHES"],
	["fullscreen", "DISPLAY MODE"],
	["language", "LANGUAGE"],
	["analytics_consent", "ANONYMOUS ANALYTICS"],
	["controls", "CONTROL BINDINGS"],
]

const REBIND_ACTIONS := [
	["move_up", "MOVE UP"],
	["move_down", "MOVE DOWN"],
	["move_left", "MOVE LEFT"],
	["move_right", "MOVE RIGHT"],
	["attack", "SLASH"],
	["dash", "DASH"],
	["special", "INK ART"],
	["pause", "PAUSE"],
	["options", "OPTIONS"],
]

const UI_GAMEPAD_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"attack",
	"dash",
	"pause",
	"options",
	"manual",
	"restoration",
	"proof_ledger",
	"daily_chronicle",
	"contract_prev",
	"contract_next",
	"restart",
	"upgrade_1",
	"upgrade_2",
	"upgrade_3",
	"upgrade_4",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Localization.register_translations()
	_build_hud()
	_build_manual()
	_build_settings()
	_build_bindings()
	_apply_ui_theme()
	_wire_button_audio()


func _process(_delta: float) -> void:
	_update_game_over_input_gate()


func _apply_ui_theme() -> void:
	var shared_theme := Localization.ui_theme()
	for child in get_children():
		if child is Control:
			(child as Control).theme = shared_theme


func _wire_button_audio() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		button.button_down.connect(_on_ui_button_down.bind(button))
		button.mouse_entered.connect(_on_ui_button_hovered.bind(button))


func _on_ui_button_down(button: Button) -> void:
	if not button.disabled and _button_is_in_active_modal(button):
		ui_sound_requested.emit("ui_confirm")


func _on_ui_button_hovered(button: Button) -> void:
	if button.visible and not button.disabled and _button_is_in_active_modal(button):
		ui_sound_requested.emit("ui_move")
		var quit_index := [quit_cancel_button, quit_confirm_button].find(button)
		if quit_visible and quit_index >= 0:
			quit_navigation_index = quit_index
			_refresh_quit_confirmation()
			return
		var pause_index := pause_navigation_buttons.find(button)
		if pause_panel.visible and not quit_visible and pause_index >= 0:
			pause_navigation_index = pause_index
			_refresh_pause_navigation()
			return
		var title_index := title_navigation_buttons.find(button)
		if title_visible and not _title_overlay_visible() and title_index >= 0:
			title_navigation_index = title_index
			_refresh_title_navigation()


func _emit_input_ui_sound(event: InputEvent) -> void:
	var in_ui := title_visible or pause_panel.visible or quit_visible or settings_visible or bindings_visible or manual_visible or event_visible or relic_draft_visible or upgrade_visible or game_over_visible or victory_credits_visible
	var gamepad_cancel: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if not in_ui:
		if event.is_action_pressed("manual") or event.is_action_pressed("pause") or event.is_action_pressed("options") or event.is_action_pressed("restoration") or event.is_action_pressed("proof_ledger") or event.is_action_pressed("daily_chronicle"):
			ui_sound_requested.emit("ui_confirm")
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right") or event.is_action_pressed("contract_prev") or event.is_action_pressed("contract_next"):
		ui_sound_requested.emit("ui_move")
	elif (gamepad_cancel and (title_visible or pause_panel.visible or quit_visible or settings_visible or manual_visible)) or event.is_action_pressed("pause") or event.is_action_pressed("options") or (event.is_action_pressed("upgrade_3") and (settings_visible or manual_visible or restoration_visible or proof_visible)):
		ui_sound_requested.emit("ui_cancel")
	elif event.is_action_pressed("restoration") or event.is_action_pressed("proof_ledger") or event.is_action_pressed("daily_chronicle") or event.is_action_pressed("attack") or event.is_action_pressed("dash") or event.is_action_pressed("restart") or event.is_action_pressed("upgrade_1") or event.is_action_pressed("upgrade_2") or event.is_action_pressed("upgrade_3") or event.is_action_pressed("upgrade_4"):
		ui_sound_requested.emit("ui_confirm")


func _consume_repeated_gamepad_ui_event(event: InputEvent) -> bool:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return false
	var repeated := false
	for action in UI_GAMEPAD_ACTIONS:
		if event.is_action_released(action):
			ui_gamepad_latches.erase(action)
		elif event.is_action_pressed(action):
			if bool(ui_gamepad_latches.get(action, false)):
				repeated = true
			else:
				ui_gamepad_latches[action] = true
	return repeated


func _build_hud() -> void:
	var frame := ColorRect.new()
	frame.position = Vector2(4, 4)
	frame.size = Vector2(472, 262)
	frame.color = Color(0.0, 0.0, 0.0, 0.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	top_panel = ColorRect.new()
	top_panel.position = Vector2(8, 7)
	top_panel.size = Vector2(464, 37)
	top_panel.color = Color(0.03, 0.025, 0.04, 0.72)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_panel)

	hp_bar = _make_pixel_bar(Vector2(15, 14), Vector2(132, 8), CRIMSON)
	hp_bar_fill = hp_bar.get_child(0) as ColorRect
	xp_bar = _make_pixel_bar(Vector2(15, 31), Vector2(132, 3), GOLD)
	xp_bar_fill = xp_bar.get_child(0) as ColorRect
	level_label = _make_label("LV 1", Vector2(153, 10), Vector2(48, 16), 11, PAPER)
	wave_label = _make_label("PAGE 1", Vector2(210, 10), Vector2(80, 16), 12, WHITE)
	score_label = _make_label("INK 000000", Vector2(303, 10), Vector2(100, 16), 11, PAPER)
	dash_label = _make_label("DASH READY", Vector2(383, 27), Vector2(82, 12), 8, GOLD)
	shard_label = _make_label("MEM 000", Vector2(395, 10), Vector2(70, 13), 8, GOLD)
	objective_label = _make_label("FIND IORI BEYOND THE REDACTIONS", Vector2(130, 44), Vector2(340, 14), 8, Color(0.82, 0.77, 0.68, 0.9))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	relic_label = _make_label("RELICS —", Vector2(12, 231), Vector2(225, 13), 8, GOLD)
	build_label = _make_label("MARGINALIA", Vector2(243, 231), Vector2(225, 13), 8, PAPER)
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ink_art_panel = ColorRect.new()
	ink_art_panel.position = Vector2(300, 201)
	ink_art_panel.size = Vector2(168, 29)
	ink_art_panel.color = Color(0.025, 0.02, 0.03, 0.78)
	ink_art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink_art_panel)
	ink_art_label = _make_child_label(ink_art_panel, "E  ART · PALIMPSEST RING", Vector2(6, 0), Vector2(156, 13), 7, GOLD)
	ink_art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ink_art_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ink_art_label.clip_text = true
	ink_art_state_label = _make_child_label(ink_art_panel, "READY", Vector2(6, 11), Vector2(156, 10), 6, GOLD)
	ink_art_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ink_art_state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ink_art_state_label.clip_text = true
	ink_art_bar = ColorRect.new()
	ink_art_bar.position = Vector2(6, 23)
	ink_art_bar.size = Vector2(156, 3)
	ink_art_bar.color = Color(0.12, 0.1, 0.13, 1)
	ink_art_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_art_panel.add_child(ink_art_bar)
	ink_art_bar_fill = ColorRect.new()
	ink_art_bar_fill.size = ink_art_bar.size
	ink_art_bar_fill.color = GOLD
	ink_art_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_art_bar.add_child(ink_art_bar_fill)

	# Boss information belongs at the upper-right edge instead of floating across
	# the centre of the playfield. This keeps telegraphs and the player readable.
	boss_panel = ColorRect.new()
	boss_panel.position = Vector2(334, 58)
	boss_panel.size = Vector2(134, 27)
	boss_panel.color = Color(0.025, 0.02, 0.03, 0.82)
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.visible = false
	add_child(boss_panel)
	boss_label = _make_child_label(boss_panel, "", Vector2(5, 1), Vector2(124, 13), 7, WHITE)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss_label.clip_text = true
	boss_bar = ColorRect.new()
	boss_bar.position = Vector2(5, 17)
	boss_bar.size = Vector2(124, 5)
	boss_bar.color = Color(0.12, 0.1, 0.13, 1)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_child(boss_bar)
	boss_bar_fill = ColorRect.new()
	boss_bar_fill.size = boss_bar.size
	boss_bar_fill.color = CRIMSON
	boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_child(boss_bar_fill)

	directive_panel = ColorRect.new()
	directive_panel.position = Vector2(10, 51)
	directive_panel.size = Vector2(136, 52)
	directive_panel.color = Color(0.025, 0.02, 0.03, 0.78)
	directive_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	directive_panel.clip_contents = true
	directive_panel.visible = false
	add_child(directive_panel)
	directive_title = _make_card_text(directive_panel, "PAGE DIRECTIVE", Vector2(6, 3), Vector2(124, 11), 7, CRIMSON, false, false)
	directive_progress = _make_card_text(directive_panel, "MASKS 0 / 10", Vector2(6, 15), Vector2(124, 13), 8, WHITE, false, false)
	directive_bar = ColorRect.new()
	directive_bar.position = Vector2(6, 29)
	directive_bar.size = Vector2(124, 4)
	directive_bar.color = Color(0.12, 0.1, 0.13, 1)
	directive_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	directive_panel.add_child(directive_bar)
	directive_bar_fill = ColorRect.new()
	directive_bar_fill.size = Vector2(0, 4)
	directive_bar_fill.color = GOLD
	directive_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	directive_bar.add_child(directive_bar_fill)
	directive_reward = _make_card_text(directive_panel, "REWARD  MEMORY +2", Vector2(6, 36), Vector2(124, 11), 6, GOLD, false, false)

	controls_label = _make_label("WASD MOVE  ·  MOUSE/J SLASH  ·  SPACE/K DASH  ·  E ART  ·  ESC PAUSE", Vector2(10, 250), Vector2(460, 13), 8, Color(0.74, 0.69, 0.62, 0.9))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Transient notices deliberately borrow the objective row. Keeping the two
	# labels mutually exclusive prevents route/save messages from overprinting it.
	device_notice = _make_label("", Vector2(130, 44), Vector2(340, 14), 8, GOLD)
	device_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	device_notice.visible = false

	upgrade_panel = ColorRect.new()
	upgrade_panel.position = Vector2(6, 6)
	upgrade_panel.size = Vector2(468, 258)
	# The simulation is paused while this is visible, so the frozen battle can
	# remain as context without competing with the isolated card text regions.
	upgrade_panel.color = Color(0.035, 0.03, 0.045, 0.9)
	upgrade_panel.clip_contents = true
	upgrade_panel.pivot_offset = upgrade_panel.size * 0.5
	upgrade_panel.visible = false
	add_child(upgrade_panel)
	upgrade_title_label = _make_child_label(upgrade_panel, "CHOOSE THE NEXT STROKE", Vector2(8, 2), Vector2(452, 24), 14, WHITE)
	upgrade_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(4):
		var button := Button.new()
		var column := i % 2
		var row := i / 2
		button.position = Vector2(6 + column * 230, 29 + row * 113)
		button.size = Vector2(226, 108)
		button.text = ""
		button.clip_contents = true
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", WHITE)
		button.add_theme_color_override("font_pressed_color", GOLD)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose_upgrade.bind(i))
		upgrade_panel.add_child(button)
		upgrade_buttons.append(button)
		# Each copy element owns a non-overlapping vertical band. Long text is
		# fitted again when a choice is assigned, so a wider fallback font or a
		# future localized string cannot spill into the next band.
		var input_label := _make_card_text(button, "%d" % (i + 1), Vector2(8, 7), Vector2(38, 16), 8, GOLD)
		upgrade_input_labels.append(input_label)
		var name_label := _make_card_text(button, "TECHNIQUE", Vector2(54, 5), Vector2(164, 20), 9, WHITE)
		upgrade_name_labels.append(name_label)
		var divider := ColorRect.new()
		divider.position = Vector2(10, 29)
		divider.size = Vector2(206, 1)
		divider.color = Color(0.42, 0.36, 0.31, 0.55)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(divider)
		var description_label := _make_card_text(button, "Choose a stroke to continue.", Vector2(12, 37), Vector2(202, 41), 8, PAPER, true, false)
		description_label.add_theme_constant_override("line_separation", 1)
		upgrade_description_labels.append(description_label)
		var rarity_label := _make_card_text(button, "COMMON", Vector2(10, 89), Vector2(206, 14), 7, Color(0.66, 0.62, 0.56, 1))
		upgrade_rarity_labels.append(rarity_label)

	relic_draft_panel = ColorRect.new()
	relic_draft_panel.position = Vector2(10, 22)
	relic_draft_panel.size = Vector2(460, 226)
	relic_draft_panel.color = Color(0.025, 0.018, 0.03, 0.9)
	relic_draft_panel.visible = false
	add_child(relic_draft_panel)
	var relic_draft_title := _make_child_label(relic_draft_panel, "RESTORE ONE RELIC", Vector2(8, 4), Vector2(444, 25), 16, WHITE)
	relic_draft_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_draft_source_label = _make_child_label(relic_draft_panel, "FOUND IN THE MARGIN", Vector2(10, 28), Vector2(440, 14), 8, GOLD)
	relic_draft_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(3):
		var relic_button := Button.new()
		relic_button.position = Vector2(8 + i * 148, 48)
		relic_button.size = Vector2(140, 160)
		relic_button.text = ""
		relic_button.clip_contents = true
		relic_button.focus_mode = Control.FOCUS_NONE
		relic_button.pressed.connect(_choose_relic.bind(i))
		relic_draft_panel.add_child(relic_button)
		relic_draft_buttons.append(relic_button)
		var relic_input := _make_card_text(relic_button, "%d" % (i + 1), Vector2(8, 5), Vector2(124, 16), 8, GOLD)
		relic_draft_input_labels.append(relic_input)
		var relic_name := _make_card_text(relic_button, "RELIC", Vector2(8, 24), Vector2(124, 31), 8, WHITE, true)
		relic_draft_name_labels.append(relic_name)
		var relic_description := _make_card_text(relic_button, "Choose a memory to bind into this draft.", Vector2(8, 62), Vector2(124, 62), 7, PAPER, true)
		relic_draft_description_labels.append(relic_description)
		var relic_footer := _make_card_text(relic_button, "RUN RELIC", Vector2(8, 136), Vector2(124, 16), 7, GOLD)
		relic_draft_footer_labels.append(relic_footer)
	var relic_help := _make_child_label(relic_draft_panel, "X / Y / B  OR  1 / 2 / 3  ·  CHOICE IS PERMANENT FOR THIS DRAFT", Vector2(8, 209), Vector2(444, 13), 7, Color(0.72, 0.67, 0.61, 1))
	relic_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	event_panel = ColorRect.new()
	event_panel.position = Vector2(30, 42)
	event_panel.size = Vector2(420, 188)
	event_panel.color = Color(0.025, 0.018, 0.03, 0.88)
	event_panel.visible = false
	add_child(event_panel)
	event_title = _make_child_label(event_panel, "A MEMORY IN THE MARGIN", Vector2(12, 8), Vector2(396, 25), 16, WHITE)
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_body = _make_child_label(event_panel, "", Vector2(24, 34), Vector2(372, 35), 9, PAPER)
	event_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(3):
		var event_button := Button.new()
		event_button.position = Vector2(8 + i * 136, 78)
		event_button.size = Vector2(132, 94)
		event_button.add_theme_font_size_override("font_size", 9)
		event_button.add_theme_color_override("font_color", PAPER)
		event_button.add_theme_color_override("font_hover_color", WHITE)
		event_button.add_theme_color_override("font_pressed_color", GOLD)
		event_button.focus_mode = Control.FOCUS_NONE
		event_button.pressed.connect(_choose_event.bind(i))
		event_panel.add_child(event_button)
		event_buttons.append(event_button)

	game_over_backdrop = ColorRect.new()
	game_over_backdrop.position = Vector2.ZERO
	game_over_backdrop.size = Vector2(480, 270)
	game_over_backdrop.color = Color(0.01, 0.008, 0.015, 0.86)
	game_over_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_backdrop.visible = false
	add_child(game_over_backdrop)

	game_over_panel = ColorRect.new()
	game_over_panel.position = Vector2(60, 32)
	game_over_panel.size = Vector2(360, 206)
	game_over_panel.color = Color(0.025, 0.02, 0.03, 0.98)
	game_over_panel.visible = false
	add_child(game_over_panel)
	game_over_title = _make_child_label(game_over_panel, "THE PAGE GOES BLACK", Vector2(8, 10), Vector2(344, 30), 20, CRIMSON)
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label = _make_child_label(game_over_panel, "", Vector2(16, 45), Vector2(328, 112), 9, PAPER)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_button = Button.new()
	restart_button.position = Vector2(100, 166)
	restart_button.size = Vector2(160, 30)
	restart_button.text = "R  REWRITE THE PAGE"
	restart_button.add_theme_font_size_override("font_size", 10)
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.pressed.connect(_request_game_over_restart)
	game_over_panel.add_child(restart_button)

	victory_credits_panel = ColorRect.new()
	victory_credits_panel.position = Vector2.ZERO
	victory_credits_panel.size = Vector2(480, 270)
	victory_credits_panel.color = Color(0.01, 0.008, 0.015, 0.965)
	victory_credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_credits_panel.visible = false
	add_child(victory_credits_panel)
	victory_credits_title = _make_child_label(victory_credits_panel, "THE PAGE REMEMBERS", Vector2(24, 22), Vector2(432, 42), 24, GOLD)
	victory_credits_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_credits_body = _make_child_label(victory_credits_panel, "", Vector2(34, 67), Vector2(412, 142), 10, PAPER)
	victory_credits_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_credits_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_credits_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	victory_credits_prompt = _make_child_label(victory_credits_panel, "CREDITS BEGIN…", Vector2(30, 226), Vector2(420, 24), 9, GOLD)
	victory_credits_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	pause_panel = ColorRect.new()
	pause_panel.position = Vector2(132, 22)
	pause_panel.size = Vector2(216, 226)
	pause_panel.color = Color(0.025, 0.02, 0.03, 0.88)
	pause_panel.visible = false
	add_child(pause_panel)
	pause_label = _make_child_label(pause_panel, "PANEL PAUSED", Vector2(8, 7), Vector2(200, 34), 16, PAPER)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_resume_button = Button.new()
	pause_resume_button.position = Vector2(18, 45)
	pause_resume_button.size = Vector2(180, 27)
	pause_resume_button.text = "CONTINUE"
	pause_resume_button.add_theme_font_size_override("font_size", 9)
	pause_resume_button.focus_mode = Control.FOCUS_NONE
	pause_resume_button.pressed.connect(func() -> void: pause_requested.emit())
	pause_panel.add_child(pause_resume_button)
	pause_options_button = Button.new()
	pause_options_button.position = Vector2(18, 77)
	pause_options_button.size = Vector2(180, 27)
	pause_options_button.text = "O / VIEW  OPTIONS"
	pause_options_button.add_theme_font_size_override("font_size", 9)
	pause_options_button.focus_mode = Control.FOCUS_NONE
	pause_options_button.pressed.connect(show_settings)
	pause_panel.add_child(pause_options_button)
	pause_manual_button = Button.new()
	pause_manual_button.position = Vector2(18, 109)
	pause_manual_button.size = Vector2(180, 27)
	pause_manual_button.text = "F1 / LT  FIELD MANUAL"
	pause_manual_button.add_theme_font_size_override("font_size", 9)
	pause_manual_button.focus_mode = Control.FOCUS_NONE
	pause_manual_button.pressed.connect(show_manual)
	pause_panel.add_child(pause_manual_button)
	pause_save_return_button = Button.new()
	pause_save_return_button.position = Vector2(18, 141)
	pause_save_return_button.size = Vector2(180, 27)
	pause_save_return_button.text = "1 / X  SAVE & RETURN"
	pause_save_return_button.add_theme_font_size_override("font_size", 9)
	pause_save_return_button.focus_mode = Control.FOCUS_NONE
	pause_save_return_button.pressed.connect(func() -> void: save_return_requested.emit())
	pause_panel.add_child(pause_save_return_button)
	pause_quit_button = Button.new()
	pause_quit_button.position = Vector2(18, 173)
	pause_quit_button.size = Vector2(180, 27)
	pause_quit_button.text = "QUIT TO DESKTOP"
	pause_quit_button.add_theme_font_size_override("font_size", 9)
	pause_quit_button.focus_mode = Control.FOCUS_NONE
	pause_quit_button.pressed.connect(show_quit_confirmation.bind(true))
	pause_panel.add_child(pause_quit_button)
	pause_navigation_buttons = [pause_resume_button, pause_options_button, pause_manual_button, pause_save_return_button, pause_quit_button]
	pause_help_label = _make_child_label(pause_panel, "↑↓ SELECT  ·  A/ENTER CONFIRM  ·  B/ESC BACK", Vector2(10, 204), Vector2(196, 14), 7, GOLD)
	pause_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_title()
	_build_achievement_toast()
	_build_quit_confirmation()


func _build_title() -> void:
	title_panel = ColorRect.new()
	title_panel.position = Vector2.ZERO
	title_panel.size = Vector2(480, 270)
	title_panel.color = DEEP_INK
	title_panel.visible = false
	add_child(title_panel)

	var title_art := TextureRect.new()
	title_art.position = Vector2.ZERO
	title_art.size = Vector2(480, 270)
	title_art.texture = preload("res://assets/cutscenes/prologue.png")
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_art.modulate = Color(0.46, 0.46, 0.46, 1)
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(title_art)
	var title_shade := ColorRect.new()
	title_shade.position = Vector2.ZERO
	title_shade.size = Vector2(480, 270)
	title_shade.color = Color(0.015, 0.01, 0.02, 0.66)
	title_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(title_shade)

	var logo := _make_child_label(title_panel, "INKBOUND", Vector2(18, 17), Vector2(220, 42), 32, WHITE)
	var subtitle := _make_child_label(title_panel, "BLADE OF THE BLANK PAGE", Vector2(21, 54), Vector2(220, 20), 11, CRIMSON)
	title_stats_label = _make_child_label(title_panel, "RANK 01  ·  MEM 000  ·  BEST 000000", Vector2(22, 81), Vector2(220, 18), 8, PAPER)

	start_button = Button.new()
	start_button.position = Vector2(22, 108)
	start_button.size = Vector2(96, 38)
	start_button.text = "NEW GAME"
	start_button.add_theme_font_size_override("font_size", 10)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(_start_from_title)
	title_panel.add_child(start_button)

	continue_button = Button.new()
	continue_button.position = Vector2(122, 108)
	continue_button.size = Vector2(104, 38)
	continue_button.text = "CONTINUE / LOAD"
	continue_button.add_theme_font_size_override("font_size", 8)
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(_continue_from_title)
	title_panel.add_child(continue_button)

	difficulty_button = Button.new()
	difficulty_button.position = Vector2(230, 108)
	difficulty_button.size = Vector2(110, 38)
	difficulty_button.text = "‹  STANDARD DRAFT  ›"
	difficulty_button.add_theme_font_size_override("font_size", 11)
	difficulty_button.focus_mode = Control.FOCUS_NONE
	difficulty_button.pressed.connect(_cycle_difficulty.bind(1))
	title_panel.add_child(difficulty_button)

	contract_button = Button.new()
	contract_button.position = Vector2(344, 108)
	contract_button.size = Vector2(112, 38)
	contract_button.text = "LB/RB\nOPEN DRAFT"
	contract_button.add_theme_font_size_override("font_size", 8)
	contract_button.focus_mode = Control.FOCUS_NONE
	contract_button.pressed.connect(_cycle_contract.bind(1))
	title_panel.add_child(contract_button)

	contract_description_label = _make_child_label(title_panel, "NO SPECIAL CLAUSES", Vector2(22, 147), Vector2(308, 29), 7, PAPER)
	contract_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	proof_button = Button.new()
	proof_button.position = Vector2(336, 147)
	proof_button.size = Vector2(120, 29)
	proof_button.text = "P / LS  PROOF 0/0"
	proof_button.add_theme_font_size_override("font_size", 7)
	proof_button.focus_mode = Control.FOCUS_NONE
	proof_button.pressed.connect(_show_proof_ledger)
	title_panel.add_child(proof_button)

	restore_title_label = _make_child_label(title_panel, "RESTORE THE ARCHIVE  ·  PERMANENT MEMORIES", Vector2(22, 179), Vector2(434, 14), 7, GOLD)
	restore_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_button = Button.new()
	daily_button.position = Vector2(22, 196)
	daily_button.size = Vector2(210, 53)
	daily_button.text = "T / DOWN  DAILY CHRONICLE"
	daily_button.add_theme_font_size_override("font_size", 7)
	daily_button.focus_mode = Control.FOCUS_NONE
	daily_button.pressed.connect(_show_daily)
	title_panel.add_child(daily_button)
	restoration_open_button = Button.new()
	restoration_open_button.position = Vector2(238, 196)
	restoration_open_button.size = Vector2(218, 53)
	restoration_open_button.text = "M / RS  OPEN RESTORATION BOARD"
	restoration_open_button.add_theme_font_size_override("font_size", 9)
	restoration_open_button.focus_mode = Control.FOCUS_NONE
	restoration_open_button.pressed.connect(_show_restoration)
	title_panel.add_child(restoration_open_button)

	codex_button = Button.new()
	codex_button.position = Vector2(350, 68)
	codex_button.size = Vector2(65, 28)
	codex_button.text = "CODEX"
	codex_button.add_theme_font_size_override("font_size", 8)
	codex_button.focus_mode = Control.FOCUS_NONE
	codex_button.pressed.connect(_toggle_codex)
	title_panel.add_child(codex_button)

	achievements_button = Button.new()
	achievements_button.position = Vector2(246, 68)
	achievements_button.size = Vector2(100, 28)
	achievements_button.text = "ACHIEVEMENTS"
	achievements_button.add_theme_font_size_override("font_size", 7)
	achievements_button.focus_mode = Control.FOCUS_NONE
	achievements_button.pressed.connect(_toggle_achievements)
	title_panel.add_child(achievements_button)

	title_quit_button = Button.new()
	title_quit_button.position = Vector2(419, 68)
	title_quit_button.size = Vector2(37, 28)
	title_quit_button.text = "QUIT"
	title_quit_button.add_theme_font_size_override("font_size", 7)
	title_quit_button.focus_mode = Control.FOCUS_NONE
	title_quit_button.pressed.connect(show_quit_confirmation.bind(false))
	title_panel.add_child(title_quit_button)

	story_button = Button.new()
	story_button.position = Vector2(246, 8)
	story_button.size = Vector2(104, 26)
	story_button.text = "STORY ARCHIVE"
	story_button.add_theme_font_size_override("font_size", 8)
	story_button.focus_mode = Control.FOCUS_NONE
	story_button.pressed.connect(_toggle_story)
	title_panel.add_child(story_button)

	settings_button = Button.new()
	settings_button.position = Vector2(356, 8)
	settings_button.size = Vector2(100, 26)
	settings_button.text = "OPTIONS"
	settings_button.add_theme_font_size_override("font_size", 8)
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.pressed.connect(show_settings)
	title_panel.add_child(settings_button)

	history_button = Button.new()
	history_button.position = Vector2(246, 38)
	history_button.size = Vector2(104, 26)
	history_button.text = "HISTORY"
	history_button.add_theme_font_size_override("font_size", 8)
	history_button.focus_mode = Control.FOCUS_NONE
	history_button.pressed.connect(_toggle_history)
	title_panel.add_child(history_button)

	manual_button = Button.new()
	manual_button.position = Vector2(356, 38)
	manual_button.size = Vector2(100, 26)
	manual_button.text = "FIELD MANUAL"
	manual_button.add_theme_font_size_override("font_size", 8)
	manual_button.focus_mode = Control.FOCUS_NONE
	manual_button.pressed.connect(show_manual)
	title_panel.add_child(manual_button)

	title_navigation_label = _make_child_label(title_panel, "D-PAD  NAVIGATE  ·  A  SELECT  ·  B  BACK", Vector2(20, 252), Vector2(440, 14), 7, GOLD)
	title_navigation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_navigation_cursor = ColorRect.new()
	title_navigation_cursor.color = GOLD
	title_navigation_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(title_navigation_cursor)
	title_navigation_buttons = [
		start_button,
		continue_button,
		difficulty_button,
		contract_button,
		proof_button,
		daily_button,
		restoration_open_button,
		story_button,
		settings_button,
		history_button,
		manual_button,
		achievements_button,
		codex_button,
		title_quit_button,
	]
	title_navigation_actions = [
		"new_game",
		"continue",
		"difficulty",
		"contract",
		"proof",
		"daily",
		"restoration",
		"story",
		"settings",
		"history",
		"manual",
		"achievements",
		"codex",
		"quit",
	]

	codex_panel = ColorRect.new()
	codex_panel.position = Vector2(24, 24)
	codex_panel.size = Vector2(432, 222)
	codex_panel.color = Color(0.015, 0.012, 0.02, 0.985)
	codex_panel.visible = false
	title_panel.add_child(codex_panel)
	var codex_title := _make_child_label(codex_panel, "ARCHIVE CODEX", Vector2(12, 8), Vector2(408, 24), 17, WHITE)
	codex_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	codex_label = _make_child_label(codex_panel, "", Vector2(20, 35), Vector2(392, 166), 7, PAPER)
	codex_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var codex_close := _make_child_label(codex_panel, "Y/△ OR ESC  CLOSE", Vector2(220, 201), Vector2(196, 14), 8, GOLD)
	codex_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	achievements_panel = ColorRect.new()
	achievements_panel.position = Vector2(24, 24)
	achievements_panel.size = Vector2(432, 222)
	achievements_panel.color = Color(0.015, 0.012, 0.02, 0.985)
	achievements_panel.visible = false
	title_panel.add_child(achievements_panel)
	var achievements_title := _make_child_label(achievements_panel, "RESTORED ACHIEVEMENTS", Vector2(12, 8), Vector2(408, 24), 17, WHITE)
	achievements_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievements_label = _make_child_label(achievements_panel, "", Vector2(16, 34), Vector2(400, 166), 7, PAPER)
	achievements_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var achievements_close := _make_child_label(achievements_panel, "B/○ OR ESC  CLOSE", Vector2(220, 201), Vector2(196, 14), 8, GOLD)
	achievements_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	history_panel = ColorRect.new()
	history_panel.position = Vector2(24, 24)
	history_panel.size = Vector2(432, 222)
	history_panel.color = Color(0.015, 0.012, 0.02, 0.985)
	history_panel.visible = false
	title_panel.add_child(history_panel)
	var history_title := _make_child_label(history_panel, "RECENT DRAFTS", Vector2(12, 8), Vector2(408, 24), 17, WHITE)
	history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_label = _make_child_label(history_panel, "NO DRAFTS RECORDED", Vector2(16, 36), Vector2(400, 160), 8, PAPER)
	history_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var history_close := _make_child_label(history_panel, "X/□ OR ESC  CLOSE", Vector2(220, 201), Vector2(196, 14), 8, GOLD)
	history_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	story_panel = ColorRect.new()
	story_panel.position = Vector2(24, 24)
	story_panel.size = Vector2(432, 222)
	story_panel.color = Color(0.015, 0.012, 0.02, 0.985)
	story_panel.visible = false
	title_panel.add_child(story_panel)
	var story_title := _make_child_label(story_panel, "STORY ARCHIVE", Vector2(12, 7), Vector2(408, 24), 17, WHITE)
	story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(7):
		var story_entry_button := Button.new()
		story_entry_button.position = Vector2(28, 34 + index * 22)
		story_entry_button.size = Vector2(376, 20)
		story_entry_button.add_theme_font_size_override("font_size", 8)
		story_entry_button.focus_mode = Control.FOCUS_NONE
		story_entry_button.pressed.connect(_play_story_entry.bind(index))
		story_panel.add_child(story_entry_button)
		story_buttons.append(story_entry_button)
	var story_close := _make_child_label(story_panel, "↑↓ SELECT  ·  A/ENTER PLAY  ·  RT/ESC CLOSE", Vector2(72, 199), Vector2(344, 14), 8, GOLD)
	story_close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	loadout_panel = ColorRect.new()
	loadout_panel.position = Vector2(10, 8)
	loadout_panel.size = Vector2(460, 246)
	loadout_panel.color = Color(0.015, 0.012, 0.02, 0.99)
	loadout_panel.visible = false
	title_panel.add_child(loadout_panel)
	var loadout_title := _make_child_label(loadout_panel, "CHOOSE A STARTING BLADE", Vector2(12, 7), Vector2(436, 24), 17, WHITE)
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(Content.STARTING_WEAPONS.size()):
		var loadout_button := Button.new()
		loadout_button.position = Vector2(18, 34 + index * 32)
		loadout_button.size = Vector2(424, 30)
		loadout_button.add_theme_font_size_override("font_size", 8)
		loadout_button.focus_mode = Control.FOCUS_NONE
		loadout_button.pressed.connect(_choose_loadout.bind(index))
		loadout_panel.add_child(loadout_button)
		loadout_buttons.append(loadout_button)
	loadout_description_label = _make_child_label(loadout_panel, "", Vector2(18, 196), Vector2(424, 40), 7, GOLD)
	loadout_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loadout_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_description_label.clip_text = true
	_build_restoration_board()
	_build_proof_ledger()
	_build_daily_chronicle()


func _build_restoration_board() -> void:
	restoration_panel = ColorRect.new()
	restoration_panel.position = Vector2(14, 12)
	restoration_panel.size = Vector2(452, 246)
	restoration_panel.color = Color(0.012, 0.009, 0.017, 0.998)
	restoration_panel.clip_contents = true
	restoration_panel.visible = false
	title_panel.add_child(restoration_panel)
	var title := _make_child_label(restoration_panel, "RESTORATION BOARD", Vector2(12, 5), Vector2(428, 24), 17, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restoration_status_label = _make_child_label(restoration_panel, "ARCHIVE RANK 01  ·  MEMORY 000  ·  0/30 RESTORED", Vector2(12, 28), Vector2(428, 15), 8, GOLD)
	restoration_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(Content.META_RESTORATIONS.size()):
		var definition: Dictionary = Content.META_RESTORATIONS[index]
		var button := Button.new()
		var column := index % 2
		var row := index / 2
		button.position = Vector2(12 + column * 214, 47 + row * 55)
		button.size = Vector2(202, 50)
		button.add_theme_font_size_override("font_size", 7)
		button.add_theme_color_override("font_disabled_color", Color(0.46, 0.43, 0.40, 1.0))
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.pressed.connect(_buy_meta_upgrade.bind(str(definition["id"])))
		button.mouse_entered.connect(_select_restoration.bind(index))
		restoration_panel.add_child(button)
		meta_upgrade_buttons.append(button)
	var footer := _make_child_label(restoration_panel, "D-PAD / ARROWS  SELECT  ·  A / ENTER  RESTORE  ·  B / ESC  CLOSE", Vector2(12, 216), Vector2(428, 18), 7, PAPER)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_proof_ledger() -> void:
	proof_panel = ColorRect.new()
	proof_panel.position = Vector2(24, 24)
	proof_panel.size = Vector2(432, 222)
	proof_panel.color = Color(0.012, 0.009, 0.017, 0.998)
	proof_panel.clip_contents = true
	proof_panel.visible = false
	title_panel.add_child(proof_panel)
	proof_title_label = _make_child_label(proof_panel, "THE PROOF LEDGER", Vector2(12, 5), Vector2(408, 24), 17, WHITE)
	proof_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(Content.PROOF_LEVELS.size()):
		var button := Button.new()
		var column := 0 if index <= 5 else 1
		var row := index if index <= 5 else index - 6
		button.position = Vector2(12 + column * 204, 34 + row * 24)
		button.size = Vector2(196, 22)
		button.add_theme_font_size_override("font_size", 7)
		button.add_theme_color_override("font_disabled_color", Color(0.42, 0.39, 0.38, 1.0))
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.pressed.connect(_commit_proof.bind(index))
		button.mouse_entered.connect(_select_proof.bind(index))
		proof_panel.add_child(button)
		proof_buttons.append(button)
	proof_description_label = _make_child_label(proof_panel, "OPEN PROOF · NO CUMULATIVE CLAUSES", Vector2(12, 176), Vector2(408, 24), 7, GOLD)
	proof_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	proof_description_label.clip_text = true
	var footer := _make_child_label(proof_panel, "D-PAD / ARROWS  SELECT  ·  A / ENTER  USE  ·  B / ESC  CLOSE", Vector2(12, 201), Vector2(408, 14), 7, PAPER)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_daily_chronicle() -> void:
	daily_panel = ColorRect.new()
	daily_panel.position = Vector2(24, 24)
	daily_panel.size = Vector2(432, 222)
	daily_panel.color = Color(0.012, 0.009, 0.017, 0.998)
	daily_panel.clip_contents = true
	daily_panel.visible = false
	title_panel.add_child(daily_panel)
	daily_title_label = _make_child_label(daily_panel, "DAILY CHRONICLE", Vector2(12, 5), Vector2(408, 24), 17, WHITE)
	daily_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kicker := _make_child_label(daily_panel, "ONE DATE · ONE SEED · ONE SHARED DRAFT", Vector2(12, 30), Vector2(408, 14), 7, GOLD)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_contract_label = _make_child_label(daily_panel, "TODAY · OPEN DRAFT", Vector2(18, 47), Vector2(396, 28), 12, WHITE)
	daily_contract_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_rules_label = _make_child_label(daily_panel, "STANDARD · MARGINALIA · PROOF 0", Vector2(28, 76), Vector2(376, 54), 8, PAPER)
	daily_rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_rules_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	daily_rules_label.clip_text = true
	daily_record_label = _make_child_label(daily_panel, "ATTEMPTS 0 · BEST 000000 · STREAK 0", Vector2(18, 133), Vector2(396, 16), 8, GOLD)
	daily_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_start_button = Button.new()
	daily_start_button.position = Vector2(82, 158)
	daily_start_button.size = Vector2(268, 38)
	daily_start_button.text = "A / ENTER  BEGIN TODAY'S DRAFT"
	daily_start_button.add_theme_font_size_override("font_size", 9)
	daily_start_button.focus_mode = Control.FOCUS_NONE
	daily_start_button.pressed.connect(_begin_daily)
	daily_panel.add_child(daily_start_button)
	var footer := _make_child_label(daily_panel, "T / DOWN  OPEN OR CLOSE  ·  B / ESC  BACK", Vector2(12, 202), Vector2(408, 14), 7, PAPER)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_quit_confirmation() -> void:
	quit_panel = ColorRect.new()
	quit_panel.position = Vector2.ZERO
	quit_panel.size = Vector2(480, 270)
	quit_panel.color = Color(0.008, 0.006, 0.012, 0.88)
	quit_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	quit_panel.visible = false
	add_child(quit_panel)
	var card := ColorRect.new()
	card.position = Vector2(82, 61)
	card.size = Vector2(316, 148)
	card.color = Color(0.035, 0.027, 0.042, 0.985)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	quit_panel.add_child(card)
	quit_title_label = _make_child_label(card, "LEAVE THE ARCHIVE?", Vector2(14, 8), Vector2(288, 27), 17, WHITE)
	quit_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_body_label = _make_child_label(card, "Your progress and latest safe draft will be preserved.", Vector2(20, 38), Vector2(276, 39), 9, PAPER)
	quit_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_status_label = _make_child_label(card, "Analytics will be given a moment to finish sending.", Vector2(20, 76), Vector2(276, 15), 7, GOLD)
	quit_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_cancel_button = Button.new()
	quit_cancel_button.position = Vector2(20, 102)
	quit_cancel_button.size = Vector2(132, 32)
	quit_cancel_button.text = "CANCEL"
	quit_cancel_button.add_theme_font_size_override("font_size", 10)
	quit_cancel_button.focus_mode = Control.FOCUS_NONE
	quit_cancel_button.pressed.connect(hide_quit_confirmation)
	card.add_child(quit_cancel_button)
	quit_confirm_button = Button.new()
	quit_confirm_button.position = Vector2(164, 102)
	quit_confirm_button.size = Vector2(132, 32)
	quit_confirm_button.text = "SAVE & QUIT"
	quit_confirm_button.add_theme_font_size_override("font_size", 10)
	quit_confirm_button.focus_mode = Control.FOCUS_NONE
	quit_confirm_button.pressed.connect(_confirm_quit)
	card.add_child(quit_confirm_button)


func show_quit_confirmation(from_active_run: bool = false) -> void:
	if quit_waiting or _popup_transition_active(quit_panel):
		return
	if quit_visible:
		quit_panel.move_to_front()
		return
	quit_from_active_run = from_active_run
	quit_visible = true
	quit_waiting = false
	quit_navigation_index = 0
	quit_panel.move_to_front()
	_refresh_quit_confirmation()
	_show_popup(quit_panel, false)
	quit_confirmation_changed.emit(true)


func hide_quit_confirmation() -> void:
	if not quit_visible or quit_waiting or _popup_transition_active(quit_panel):
		return
	_hide_popup(quit_panel, _finish_hide_quit_confirmation, false)


func _finish_hide_quit_confirmation() -> void:
	quit_visible = false
	quit_confirmation_changed.emit(false)
	if title_visible:
		_refresh_title_navigation()
	elif pause_panel.visible:
		_refresh_pause_navigation()


func set_quit_waiting() -> void:
	if not quit_visible:
		return
	quit_waiting = true
	_refresh_quit_confirmation()


func _move_quit_navigation(direction: int) -> void:
	if not quit_visible or quit_waiting:
		return
	quit_navigation_index = posmod(quit_navigation_index + direction, 2)
	_refresh_quit_confirmation()


func _confirm_quit() -> void:
	if not quit_visible or quit_waiting:
		return
	quit_waiting = true
	_refresh_quit_confirmation()
	quit_confirmed.emit()


func _activate_quit_navigation() -> void:
	if quit_navigation_index == 0:
		hide_quit_confirmation()
	else:
		_confirm_quit()


func _refresh_quit_confirmation() -> void:
	if quit_panel == null:
		return
	var chinese := TranslationServer.get_locale().begins_with("zh")
	quit_title_label.text = "退出游戏？" if chinese else "LEAVE THE ARCHIVE?"
	quit_body_label.text = (
		"当前进度与最近的安全草稿会先保存。" if quit_from_active_run
		else "结束当前会话并返回桌面。"
	) if chinese else (
		"Your progress and latest safe draft will be preserved." if quit_from_active_run
		else "End this session and return to the desktop."
	)
	quit_status_label.text = ("正在保存并发送匿名数据…" if chinese else "SAVING · FINISHING ANALYTICS…") if quit_waiting else ("退出前会短暂等待发送完成。" if chinese else "Analytics gets a brief moment to finish sending.")
	quit_cancel_button.text = "取消" if chinese else "CANCEL"
	quit_confirm_button.text = "保存并退出" if chinese and quit_from_active_run else ("退出" if chinese else ("SAVE & QUIT" if quit_from_active_run else "QUIT"))
	quit_cancel_button.disabled = quit_waiting
	quit_confirm_button.disabled = quit_waiting
	quit_cancel_button.modulate = GOLD if not quit_waiting and quit_navigation_index == 0 else Color.WHITE
	quit_confirm_button.modulate = CRIMSON.lightened(0.18) if not quit_waiting and quit_navigation_index == 1 else Color.WHITE


func _build_achievement_toast() -> void:
	achievement_toast = ColorRect.new()
	achievement_toast.position = Vector2(96, 76)
	achievement_toast.size = Vector2(288, 46)
	achievement_toast.color = Color(0.02, 0.015, 0.025, 0.88)
	achievement_toast.visible = false
	add_child(achievement_toast)
	achievement_toast_label = _make_child_label(achievement_toast, "ACHIEVEMENT RESTORED", Vector2(8, 5), Vector2(272, 36), 9, GOLD)
	achievement_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_manual() -> void:
	manual_panel = ColorRect.new()
	manual_panel.position = Vector2(20, 14)
	manual_panel.size = Vector2(440, 242)
	manual_panel.color = Color(0.012, 0.01, 0.018, 0.995)
	manual_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	manual_panel.visible = false
	add_child(manual_panel)
	var title := _make_child_label(manual_panel, "FIELD MANUAL", Vector2(12, 7), Vector2(416, 26), 17, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_page_label = _make_child_label(manual_panel, "1 / 5", Vector2(352, 10), Vector2(68, 18), 8, PAPER)
	manual_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	manual_kicker_label = _make_child_label(manual_panel, "THE FIRST CUT", Vector2(20, 38), Vector2(400, 18), 11, GOLD)
	manual_kicker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_body_label = _make_card_text(manual_panel, "", Vector2(20, 59), Vector2(400, 132), 8, PAPER, true, false)
	manual_body_label.add_theme_constant_override("line_separation", 1)
	manual_prev_button = Button.new()
	manual_prev_button.position = Vector2(18, 201)
	manual_prev_button.size = Vector2(120, 29)
	manual_prev_button.text = "LB / LEFT  PREV"
	manual_prev_button.add_theme_font_size_override("font_size", 8)
	manual_prev_button.focus_mode = Control.FOCUS_NONE
	manual_prev_button.pressed.connect(_move_manual_page.bind(-1))
	manual_panel.add_child(manual_prev_button)
	manual_close_button = Button.new()
	manual_close_button.position = Vector2(145, 201)
	manual_close_button.size = Vector2(128, 29)
	manual_close_button.text = "B / ESC  CLOSE"
	manual_close_button.add_theme_font_size_override("font_size", 8)
	manual_close_button.focus_mode = Control.FOCUS_NONE
	manual_close_button.pressed.connect(hide_manual)
	manual_panel.add_child(manual_close_button)
	manual_next_button = Button.new()
	manual_next_button.position = Vector2(280, 201)
	manual_next_button.size = Vector2(142, 29)
	manual_next_button.text = "NEXT  RIGHT / RB"
	manual_next_button.add_theme_font_size_override("font_size", 8)
	manual_next_button.focus_mode = Control.FOCUS_NONE
	manual_next_button.pressed.connect(_move_manual_page.bind(1))
	manual_panel.add_child(manual_next_button)
	_refresh_manual()


func show_manual(page_value: int = 0) -> void:
	if _popup_transition_active(manual_panel):
		return
	manual_page = clampi(page_value, 0, FIELD_MANUAL_PAGES.size() - 1)
	manual_visible = true
	manual_panel.move_to_front()
	_refresh_manual()
	_show_popup(manual_panel)
	manual_visibility_changed.emit(true)


func hide_manual() -> void:
	if not manual_visible or _popup_transition_active(manual_panel):
		return
	_hide_popup(manual_panel, _finish_hide_manual)


func _finish_hide_manual() -> void:
	manual_visible = false
	manual_visibility_changed.emit(false)


func _move_manual_page(direction: int) -> void:
	if not manual_visible:
		return
	manual_page = clampi(manual_page + signi(direction), 0, FIELD_MANUAL_PAGES.size() - 1)
	_refresh_manual()


func _refresh_manual() -> void:
	if manual_body_label == null:
		return
	var page_data: Dictionary = Localization.localized(FIELD_MANUAL_PAGES[manual_page])
	manual_kicker_label.text = str(page_data.get("title", "FIELD NOTES"))
	manual_page_label.text = "%d / %d" % [manual_page + 1, FIELD_MANUAL_PAGES.size()]
	var body := str(page_data.get("body", ""))
	if manual_page == 0:
		body = str(page_data.get("gamepad" if using_gamepad else "keyboard", ""))
	elif manual_page == FIELD_MANUAL_PAGES.size() - 1:
		body += "\n\n%s %s" % [Localization.text("BUILD"), str(ProjectSettings.get_setting("application/config/version", "DEVELOPMENT"))]
	manual_body_label.text = "[left]%s[/left]" % body
	manual_prev_button.disabled = manual_page <= 0
	manual_next_button.disabled = manual_page >= FIELD_MANUAL_PAGES.size() - 1
	if using_gamepad:
		manual_prev_button.text = "LB  %s" % Localization.text("PREVIOUS")
		manual_close_button.text = "B  %s" % Localization.text("CLOSE")
		manual_next_button.text = "%s  RB" % Localization.text("NEXT")
	else:
		manual_prev_button.text = "LEFT  %s" % Localization.text("PREVIOUS")
		manual_close_button.text = "ESC  %s" % Localization.text("CLOSE")
		manual_next_button.text = "%s  RIGHT" % Localization.text("NEXT")


func _build_settings() -> void:
	settings_panel = ColorRect.new()
	settings_panel.position = Vector2(36, 2)
	settings_panel.size = Vector2(408, 266)
	settings_panel.color = Color(0.015, 0.012, 0.02, 0.992)
	settings_panel.visible = false
	add_child(settings_panel)
	var title := _make_child_label(settings_panel, "OPTIONS & ACCESSIBILITY", Vector2(12, 2), Vector2(384, 22), 15, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _make_child_label(settings_panel, "D-PAD / ARROWS SELECT   LEFT/RIGHT ADJUST", Vector2(12, 23), Vector2(384, 12), 8, GOLD)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(SETTINGS_ROWS.size()):
		var button := Button.new()
		button.position = Vector2(24, 35 + index * 15)
		button.size = Vector2(360, 15)
		button.add_theme_font_size_override("font_size", 8)
		button.add_theme_stylebox_override("normal", _compact_settings_button_style(Color(0.08, 0.065, 0.09, 0.58), Color(0.32, 0.27, 0.34, 0.72)))
		button.add_theme_stylebox_override("hover", _compact_settings_button_style(Color(0.18, 0.125, 0.13, 0.82), GOLD.darkened(0.38)))
		button.add_theme_stylebox_override("pressed", _compact_settings_button_style(Color(0.25, 0.11, 0.12, 0.92), CRIMSON.darkened(0.2)))
		button.add_theme_stylebox_override("disabled", _compact_settings_button_style(Color(0.04, 0.035, 0.05, 0.42), Color(0.16, 0.14, 0.18, 0.45)))
		# Apply the authored compact size after the style overrides: assigning it
		# against Godot's default Button style first would clamp every row to the
		# default 32 px minimum before the compact style is installed.
		button.size = Vector2(360, 15)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_adjust_setting.bind(SETTINGS_ROWS[index][0], 1))
		settings_panel.add_child(button)
		settings_buttons.append(button)
	var close := _make_child_label(settings_panel, "B/○  ·  START/ESC  BACK", Vector2(154, 248), Vector2(230, 14), 8, PAPER)
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _compact_settings_button_style(background: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = edge
	style.border_width_bottom = 1
	style.content_margin_left = 4.0
	style.content_margin_top = 1.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 1.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _build_bindings() -> void:
	bindings_panel = ColorRect.new()
	bindings_panel.position = Vector2(20, 8)
	bindings_panel.size = Vector2(440, 254)
	bindings_panel.color = Color(0.012, 0.01, 0.018, 0.995)
	bindings_panel.visible = false
	add_child(bindings_panel)
	var title := _make_child_label(bindings_panel, "CONTROL BINDINGS", Vector2(12, 5), Vector2(416, 25), 17, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var headers := _make_child_label(bindings_panel, "ACTION                         KEYBOARD / MOUSE                         GAMEPAD", Vector2(14, 29), Vector2(412, 14), 8, GOLD)
	headers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for row in range(REBIND_ACTIONS.size()):
		var y := 42 + row * 20
		var action_label := _make_child_label(bindings_panel, REBIND_ACTIONS[row][1], Vector2(14, y), Vector2(100, 19), 9, PAPER)
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		for device_index in range(2):
			var button := Button.new()
			button.position = Vector2(116 if device_index == 0 else 258, y)
			button.size = Vector2(136 if device_index == 0 else 166, 19)
			button.add_theme_font_size_override("font_size", 8)
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(_begin_rebind.bind(REBIND_ACTIONS[row][0], "keyboard" if device_index == 0 else "gamepad"))
			bindings_panel.add_child(button)
			binding_buttons.append(button)
	binding_status_label = _make_child_label(bindings_panel, "A/ENTER REBIND  ·  Y RESET DEFAULTS  ·  B/ESC BACK", Vector2(14, 228), Vector2(412, 18), 8, GOLD)
	binding_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _make_pixel_bar(at: Vector2, bar_size: Vector2, fill: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.position = at
	bar.size = bar_size
	bar.color = Color(0.12, 0.1, 0.13, 0.9)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var foreground := ColorRect.new()
	foreground.size = bar_size
	foreground.color = fill
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(foreground)
	add_child(bar)
	return bar


func _make_label(text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _make_child_label(parent: Control, text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _make_card_text(parent: Control, text_value: String, at: Vector2, label_size: Vector2, font_size: int, color: Color, wrap: bool = false, centered: bool = true) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.position = at
	label.size = label_size
	label.bbcode_enabled = true
	label.text = ("[center]%s[/center]" if centered else "[left]%s[/left]") % text_value
	label.fit_content = false
	label.clip_contents = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("normal_font_size", font_size)
	if wrap:
		label.add_theme_constant_override("line_separation", 1)
	label.add_theme_color_override("default_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _show_intro() -> void:
	var intro := ColorRect.new()
	intro.position = Vector2(54, 82)
	intro.size = Vector2(372, 102)
	intro.color = Color(0.025, 0.02, 0.03, 0.78)
	add_child(intro)
	var title := _make_child_label(intro, "INKBOUND", Vector2(8, 10), Vector2(356, 36), 26, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _make_child_label(intro, "BLADE OF THE BLANK PAGE", Vector2(8, 48), Vector2(356, 22), 12, CRIMSON)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var prompt := _make_child_label(intro, "SURVIVE. CUT. REWRITE.", Vector2(8, 73), Vector2(356, 18), 9, PAPER)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tween := create_tween()
	tween.tween_interval(1.3)
	tween.tween_property(intro, "modulate:a", 0.0, 0.45)
	tween.tween_callback(intro.queue_free)


func show_run_intro() -> void:
	_show_intro()


func set_health(current: float, maximum: float) -> void:
	var ratio := clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	hp_bar_fill.size.x = hp_bar.size.x * ratio


func set_xp(current: int, needed: int, level: int) -> void:
	var ratio := clampf(float(current) / float(needed), 0.0, 1.0) if needed > 0 else 0.0
	xp_bar_fill.size.x = xp_bar.size.x * ratio
	level_label.text = ("等级 %d" if TranslationServer.get_locale().begins_with("zh") else "LV %d") % level


func set_run_stats(wave: int, score: int, dash_ready: bool) -> void:
	var chinese := TranslationServer.get_locale().begins_with("zh")
	wave_label.text = "第 %d 页" % wave if chinese else "PAGE %d" % wave
	score_label.text = "墨迹 %06d" % score if chinese else "INK %06d" % score
	dash_label.text = ("冲刺就绪" if dash_ready else "冲刺冷却…") if chinese else ("DASH READY" if dash_ready else "DASH ...")
	dash_label.modulate = GOLD if dash_ready else Color(0.5, 0.45, 0.42, 1)


func set_ink_art(art_name_value: String, remaining: float, maximum: float) -> void:
	ink_art_source_name = art_name_value
	ink_art_name = Localization.text(art_name_value).to_upper()
	ink_art_remaining = maxf(0.0, remaining)
	ink_art_maximum = maxf(0.1, maximum)
	var prompt := "B/○" if using_gamepad else "E"
	var chinese := TranslationServer.get_locale().begins_with("zh")
	var charge_ratio := clampf((ink_art_maximum - ink_art_remaining) / ink_art_maximum, 0.0, 1.0)
	ink_art_bar_fill.size.x = ink_art_bar.size.x * charge_ratio
	ink_art_label.text = ("%s  墨术 · %s" if chinese else "%s  ART · %s") % [prompt, ink_art_name]
	if ink_art_remaining <= 0.01:
		ink_art_state_label.text = Localization.text("READY")
		ink_art_state_label.modulate = GOLD
	else:
		var charge_percent := int(round(charge_ratio * 100.0))
		ink_art_state_label.text = ("冷却 %.1f 秒 · %d%%" if chinese else "COOLDOWN %.1fs · %d%%") % [ink_art_remaining, charge_percent]
		ink_art_state_label.modulate = Color(0.72, 0.68, 0.62, 1)


func show_upgrade(choices: Array[Dictionary]) -> void:
	_cancel_upgrade_transition()
	upgrade_visible = true
	upgrade_transitioning = true
	upgrade_transition_phase = "opening"
	pending_upgrade_index = -1
	upgrade_panel.visible = true
	upgrade_panel.move_to_front()
	upgrade_panel.pivot_offset = upgrade_panel.size * 0.5
	upgrade_panel.scale = Vector2(0.84, 0.84)
	upgrade_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	current_choices.clear()
	for choice in choices:
		current_choices.append(choice)
	_refresh_upgrade_buttons()
	for index in range(upgrade_buttons.size()):
		var button := upgrade_buttons[index]
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(0.88, 0.88)
		button.modulate = Color(1.0, 1.0, 1.0, 0.68)
	_start_upgrade_open_animation()


func _start_upgrade_open_animation() -> void:
	upgrade_transition_tween = create_tween()
	upgrade_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	upgrade_transition_tween.set_parallel(true)
	upgrade_transition_tween.tween_property(upgrade_panel, "scale", Vector2.ONE, UPGRADE_OPEN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	upgrade_transition_tween.tween_property(upgrade_panel, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for index in range(upgrade_buttons.size()):
		if not upgrade_buttons[index].visible:
			continue
		var delay := 0.035 + float(index) * UPGRADE_CARD_STAGGER
		upgrade_transition_tween.tween_property(upgrade_buttons[index], "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		upgrade_transition_tween.tween_property(upgrade_buttons[index], "modulate", Color.WHITE, 0.12).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	upgrade_transition_tween.finished.connect(_finish_upgrade_open)


func _finish_upgrade_open() -> void:
	if upgrade_transition_phase != "opening":
		return
	upgrade_transition_tween = null
	upgrade_transition_phase = ""
	upgrade_transitioning = false
	upgrade_panel.scale = Vector2.ONE
	upgrade_panel.modulate = Color.WHITE
	for index in range(upgrade_buttons.size()):
		upgrade_buttons[index].scale = Vector2.ONE
		upgrade_buttons[index].modulate = Color.WHITE
		upgrade_buttons[index].disabled = index >= current_choices.size()


func _refresh_upgrade_buttons() -> void:
	_refresh_upgrade_title()
	var prefixes := ["1", "2", "3", "4"]
	if using_gamepad:
		prefixes = ["X/□", "Y/△", "B/○", "RT"]
	for i in range(upgrade_buttons.size()):
		var has_choice := i < current_choices.size()
		upgrade_buttons[i].visible = has_choice
		upgrade_buttons[i].disabled = upgrade_transitioning or not has_choice
		if not has_choice:
			continue
		var choice: Dictionary = Localization.localized(current_choices[i])
		var rarity := str(choice.get("rarity", "common"))
		upgrade_input_labels[i].text = "[center]%s[/center]" % prefixes[i]
		upgrade_name_labels[i].text = "[center]%s[/center]" % str(choice.get("name", "TECHNIQUE"))
		upgrade_description_labels[i].text = "[left]%s[/left]" % str(choice.get("description", ""))
		upgrade_rarity_labels[i].text = "[center]%s[/center]" % _upgrade_card_footer(current_choices[i], rarity)
		upgrade_rarity_labels[i].add_theme_color_override("default_color", _upgrade_rarity_color(rarity))
		_fit_upgrade_card_copy(i)


func _refresh_upgrade_title() -> void:
	upgrade_title_label.text = Localization.text("CHOOSE THE NEXT STROKE")
	upgrade_title_label.add_theme_font_size_override("font_size", 14)
	if current_choices.is_empty():
		return
	var first_choice := current_choices[0]
	var discipline_id := str(first_choice.get("_draft_discipline_id", ""))
	var discipline := Content.build_discipline(discipline_id)
	if discipline.is_empty():
		return
	var tier := clampi(int(first_choice.get("_draft_tier", 0)), 0, 2)
	var score := int(first_choice.get("_draft_score", 0))
	var threshold := int(first_choice.get("_draft_next_threshold", maxi(1, score)))
	var tier_mark: String = ["", " I", " II"][tier]
	upgrade_title_label.text = "%s  ·  %s%s  %d/%d" % [Localization.text("CURRENT DRAFT"), Localization.text(discipline.get("name", "DRAFT")), tier_mark, mini(score, threshold), threshold]
	upgrade_title_label.add_theme_font_size_override("font_size", 12 if TranslationServer.get_locale().begins_with("zh") else 11)


func _upgrade_card_footer(choice: Dictionary, rarity: String) -> String:
	var parts := PackedStringArray([Localization.text(rarity.to_upper())])
	var discipline := Content.build_discipline(str(choice.get("_discipline_id", "")))
	if discipline.is_empty():
		return "  ·  ".join(parts)
	if bool(choice.get("_awakens", false)):
		parts.append(Localization.text("AWAKENS"))
	elif bool(choice.get("_resonant", false)):
		parts.append(Localization.text("RESONANT"))
	var score := int(choice.get("_discipline_score", 0))
	var threshold := int(choice.get("_next_threshold", maxi(1, score + 1)))
	parts.append("%s %d/%d" % [Localization.text(discipline.get("name", "DRAFT")), mini(score + 1, threshold), threshold])
	return "  ·  ".join(parts)


func _fit_upgrade_card_copy(index: int) -> void:
	_fit_rich_text(upgrade_input_labels[index], 8, 7, true)
	_fit_rich_text(upgrade_name_labels[index], 9, 7, true)
	_fit_rich_text(upgrade_description_labels[index], 8, 6, false)
	_fit_rich_text(upgrade_rarity_labels[index], 7, 6, true)


func _fit_rich_text(label: RichTextLabel, preferred_size: int, minimum_size: int, fit_width: bool) -> void:
	for font_size in range(preferred_size, minimum_size - 1, -1):
		label.add_theme_font_size_override("normal_font_size", font_size)
		var height_fits := float(label.get_content_height()) <= label.size.y + 0.5
		var width_fits := not fit_width or float(label.get_content_width()) <= label.size.x + 0.5
		if height_fits and width_fits:
			return


func _upgrade_rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return GOLD
		"epic":
			return Color("d99cff")
		"rare":
			return Color("8fc7ff")
	return Color(0.66, 0.62, 0.56, 1)


func _choose_upgrade(index: int) -> void:
	if not upgrade_visible or upgrade_transitioning or index < 0 or index >= current_choices.size():
		return
	upgrade_transitioning = true
	upgrade_transition_phase = "closing"
	pending_upgrade_index = index
	for button in upgrade_buttons:
		button.disabled = true
	upgrade_buttons[index].modulate = Color(1.08, 0.94, 0.64, 1.0)
	upgrade_transition_tween = create_tween()
	upgrade_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	upgrade_transition_tween.set_parallel(true)
	# BACK/EASE_IN briefly pulls the panel outward before it snaps toward the
	# centre, making dismissal feel like a physical release instead of a cut.
	upgrade_transition_tween.tween_property(upgrade_panel, "scale", Vector2(0.84, 0.84), UPGRADE_CLOSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	upgrade_transition_tween.tween_property(upgrade_panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.14).set_delay(0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	upgrade_transition_tween.finished.connect(_finish_upgrade_close)


func _finish_upgrade_close() -> void:
	if upgrade_transition_phase != "closing":
		return
	var selected_index := pending_upgrade_index
	upgrade_transition_tween = null
	upgrade_transition_phase = ""
	pending_upgrade_index = -1
	upgrade_transitioning = false
	upgrade_visible = false
	upgrade_panel.visible = false
	upgrade_panel.scale = Vector2.ONE
	upgrade_panel.modulate = Color.WHITE
	for button in upgrade_buttons:
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
	current_choices.clear()
	upgrade_selected.emit(selected_index)


func _cancel_upgrade_transition() -> void:
	if upgrade_transition_tween != null and upgrade_transition_tween.is_valid():
		upgrade_transition_tween.kill()
	upgrade_transition_tween = null
	upgrade_transition_phase = ""
	upgrade_transitioning = false
	pending_upgrade_index = -1


func debug_finish_upgrade_transition() -> void:
	# Deterministic render/smoke tests can settle the real transition without
	# weakening production input locking or depending on host frame rate.
	var phase := upgrade_transition_phase
	if phase.is_empty():
		return
	if upgrade_transition_tween != null and upgrade_transition_tween.is_valid():
		upgrade_transition_tween.kill()
	upgrade_transition_tween = null
	if phase == "opening":
		_finish_upgrade_open()
	elif phase == "closing":
		_finish_upgrade_close()


func _show_popup(panel: Control, scale_effect: bool = true, fade_duration: float = POPUP_FADE_IN_DURATION) -> void:
	if not is_instance_valid(panel):
		return
	_cancel_popup_transition(panel)
	var panel_id := panel.get_instance_id()
	panel.visible = true
	# A popup is modal for every input device, not only for events routed through
	# _unhandled_input. Explicitly stop pointer propagation and disable every
	# Button outside the top popup so exposed margins cannot click or hover the
	# title/pause UI behind it.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_push_modal_panel(panel)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = POPUP_START_SCALE if scale_effect else Vector2.ONE
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_lock_popup_buttons(panel)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color.WHITE, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if scale_effect:
		tween.tween_property(panel, "scale", Vector2.ONE, fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	popup_transitions[panel_id] = {
		"panel": panel,
		"phase": "in",
		"tween": tween,
		"callback": Callable(),
	}
	tween.finished.connect(_finish_popup_transition.bind(panel_id))


func _hide_popup(panel: Control, callback: Callable = Callable(), scale_effect: bool = true) -> void:
	if not is_instance_valid(panel):
		if callback.is_valid():
			callback.call()
		return
	if not panel.visible:
		_pop_modal_panel(panel)
		if callback.is_valid():
			callback.call()
		return
	_cancel_popup_transition(panel)
	var panel_id := panel.get_instance_id()
	_lock_popup_buttons(panel)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 0.0), POPUP_FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if scale_effect:
		tween.tween_property(panel, "scale", POPUP_START_SCALE, POPUP_FADE_OUT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	popup_transitions[panel_id] = {
		"panel": panel,
		"phase": "out",
		"tween": tween,
		"callback": callback,
	}
	tween.finished.connect(_finish_popup_transition.bind(panel_id))


func _finish_popup_transition(panel_id: int) -> void:
	var transition: Dictionary = popup_transitions.get(panel_id, {})
	if transition.is_empty():
		return
	var panel: Control = transition.get("panel")
	var phase := str(transition.get("phase", ""))
	var callback: Callable = transition.get("callback", Callable())
	popup_transitions.erase(panel_id)
	if is_instance_valid(panel):
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		if phase == "out":
			panel.visible = false
	_unlock_popup_buttons(panel_id)
	if phase == "out" and is_instance_valid(panel):
		_pop_modal_panel(panel)
	if phase == "out" and callback.is_valid():
		callback.call()


func _cancel_popup_transition(panel: Control) -> void:
	var panel_id := panel.get_instance_id()
	var transition: Dictionary = popup_transitions.get(panel_id, {})
	if transition.is_empty():
		return
	var tween: Tween = transition.get("tween")
	if tween != null and tween.is_valid():
		tween.kill()
	popup_transitions.erase(panel_id)
	panel.scale = Vector2.ONE
	panel.modulate = Color.WHITE
	_unlock_popup_buttons(panel_id)
	_apply_modal_input_isolation()


func _lock_popup_buttons(panel: Control) -> void:
	var panel_id := panel.get_instance_id()
	if popup_button_states.has(panel_id):
		return
	var states: Array[Dictionary] = []
	for node in panel.find_children("*", "Button", true, false):
		var button := node as Button
		states.append({"button": button, "disabled": button.disabled})
		button.disabled = true
	popup_button_states[panel_id] = states


func _unlock_popup_buttons(panel_id: int) -> void:
	var states: Array = popup_button_states.get(panel_id, [])
	popup_button_states.erase(panel_id)
	for state_value in states:
		var state: Dictionary = state_value
		var button: Button = state.get("button")
		if is_instance_valid(button):
			button.disabled = bool(state.get("disabled", false))


func _popup_transition_active(panel: Control) -> bool:
	return is_instance_valid(panel) and popup_transitions.has(panel.get_instance_id())


func _popup_transition_phase(panel: Control) -> String:
	if not is_instance_valid(panel):
		return ""
	return str(popup_transitions.get(panel.get_instance_id(), {}).get("phase", ""))


func _push_modal_panel(panel: Control) -> void:
	_prune_modal_panels()
	popup_modal_stack.erase(panel)
	popup_modal_stack.append(panel)
	_capture_modal_button_states()
	_apply_modal_input_isolation()


func _pop_modal_panel(panel: Control) -> void:
	popup_modal_stack.erase(panel)
	_apply_modal_input_isolation()


func _prune_modal_panels() -> void:
	for index in range(popup_modal_stack.size() - 1, -1, -1):
		if not is_instance_valid(popup_modal_stack[index]):
			popup_modal_stack.remove_at(index)


func _active_modal_panel() -> Control:
	_prune_modal_panels()
	for index in range(popup_modal_stack.size() - 1, -1, -1):
		var panel := popup_modal_stack[index]
		if panel.visible:
			return panel
	return null


func _capture_modal_button_states() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		var button_id := button.get_instance_id()
		if not modal_button_states.has(button_id):
			modal_button_states[button_id] = {
				"button": button,
				"disabled": button.disabled,
			}


func _apply_modal_input_isolation() -> void:
	_prune_modal_panels()
	var active_panel := _active_modal_panel()
	if active_panel == null:
		for state_value in modal_button_states.values():
			var state: Dictionary = state_value
			var button: Button = state.get("button")
			if is_instance_valid(button):
				button.disabled = bool(state.get("disabled", false))
		modal_button_states.clear()
		return
	_capture_modal_button_states()
	for state_value in modal_button_states.values():
		var state: Dictionary = state_value
		var button: Button = state.get("button")
		if is_instance_valid(button):
			button.disabled = bool(state.get("disabled", false)) or not active_panel.is_ancestor_of(button)
	# Transition locks are stricter than modal ownership. Reapply them after the
	# baseline pass so a newly stacked popup cannot unlock a button mid-fade.
	for locked_states_value in popup_button_states.values():
		var locked_states: Array = locked_states_value
		for locked_state_value in locked_states:
			var locked_state: Dictionary = locked_state_value
			var locked_button: Button = locked_state.get("button")
			if is_instance_valid(locked_button):
				locked_button.disabled = true


func _button_is_in_active_modal(button: Button) -> bool:
	var active_panel := _active_modal_panel()
	return active_panel == null or active_panel.is_ancestor_of(button)


func _hide_popup_immediate(panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	_cancel_popup_transition(panel)
	panel.visible = false
	panel.scale = Vector2.ONE
	panel.modulate = Color.WHITE
	_pop_modal_panel(panel)


func debug_finish_popup_transition(panel: Control = null) -> void:
	if panel != null:
		var panel_id := panel.get_instance_id()
		var transition: Dictionary = popup_transitions.get(panel_id, {})
		if transition.is_empty():
			return
		var tween: Tween = transition.get("tween")
		if tween != null and tween.is_valid():
			tween.kill()
		_finish_popup_transition(panel_id)
		return
	# Some close callbacks intentionally open the parent panel (bindings back to
	# settings). Drain those chained transitions as well for deterministic tests.
	var guard := 0
	while not popup_transitions.is_empty() and guard < 8:
		guard += 1
		for panel_id_value in popup_transitions.keys():
			var panel_id := int(panel_id_value)
			var transition: Dictionary = popup_transitions.get(panel_id, {})
			if transition.is_empty():
				continue
			var tween: Tween = transition.get("tween")
			if tween != null and tween.is_valid():
				tween.kill()
			_finish_popup_transition(panel_id)


func show_relic_draft(choices: Array[Dictionary], source: String = "FOUND IN THE MARGIN") -> void:
	relic_draft_visible = true
	relic_draft_panel.move_to_front()
	current_relic_choices.clear()
	for choice in choices:
		current_relic_choices.append(choice)
	relic_draft_source_label.text = Localization.text(source.to_upper())
	_refresh_relic_draft_buttons()
	_show_popup(relic_draft_panel)


func _refresh_relic_draft_buttons() -> void:
	var prefixes := ["1", "2", "3"]
	if using_gamepad:
		prefixes = ["X/□", "Y/△", "B/○"]
	for index in range(relic_draft_buttons.size()):
		var has_choice := index < current_relic_choices.size()
		relic_draft_buttons[index].visible = has_choice
		if not has_choice:
			continue
		var choice: Dictionary = Localization.localized(current_relic_choices[index])
		relic_draft_input_labels[index].text = "[center]%s[/center]" % prefixes[index]
		relic_draft_name_labels[index].text = "[center]%s[/center]" % str(choice.get("name", "RELIC"))
		relic_draft_description_labels[index].text = "[center]%s[/center]" % str(choice.get("description", ""))
		relic_draft_footer_labels[index].text = "[center]%s  ·  %d/%d[/center]" % ["本局遗物" if TranslationServer.get_locale().begins_with("zh") else "RUN RELIC", index + 1, current_relic_choices.size()]


func _choose_relic(index: int) -> void:
	if not relic_draft_visible or _popup_transition_active(relic_draft_panel) or index < 0 or index >= current_relic_choices.size():
		return
	_hide_popup(relic_draft_panel, _finish_relic_choice.bind(index))


func _finish_relic_choice(index: int) -> void:
	relic_draft_visible = false
	current_relic_choices.clear()
	relic_selected.emit(index)


func show_event(event_data: Dictionary) -> void:
	event_visible = true
	current_event = event_data.duplicate(true)
	event_panel.move_to_front()
	var localized_event: Dictionary = Localization.localized(event_data)
	event_title.text = str(localized_event.get("title", Localization.text("A MEMORY IN THE MARGIN")))
	event_body.text = str(localized_event.get("text", ""))
	var options: Array = localized_event.get("options", [])
	var prefixes := ["1 / X/□", "2 / Y/△", "3 / B/○"]
	var is_route_choice := str(event_data.get("id", "")).begins_with("route-choice-")
	for index in range(event_buttons.size()):
		if index < options.size():
			var option: Dictionary = options[index]
			event_buttons[index].visible = true
			event_buttons[index].add_theme_font_size_override("font_size", 8 if is_route_choice else 9)
			event_buttons[index].text = "%s\n%s\n\n%s" % [prefixes[index], option.get("label", "CHOICE"), option.get("description", "")]
		else:
			event_buttons[index].visible = false
	_show_popup(event_panel)


func _choose_event(index: int) -> void:
	if not event_visible or _popup_transition_active(event_panel):
		return
	var options: Array = current_event.get("options", [])
	if index < 0 or index >= options.size():
		return
	_hide_popup(event_panel, _finish_event_choice.bind(index))


func _finish_event_choice(index: int) -> void:
	event_visible = false
	current_event.clear()
	event_selected.emit(index)


func show_game_over(summary: Dictionary) -> void:
	hide_victory_credits()
	last_result_summary = summary.duplicate(true)
	game_over_visible = true
	game_over_panel_revealed = false
	game_over_input_ready = false
	game_over_input_deadline_msec = 0
	game_over_sequence += 1
	_hide_popup_immediate(game_over_backdrop)
	_hide_popup_immediate(game_over_panel)
	game_over_backdrop.move_to_front()
	game_over_panel.move_to_front()
	game_over_title.text = "此页归于黑暗" if TranslationServer.get_locale().begins_with("zh") else "THE PAGE GOES BLACK"
	game_over_title.add_theme_color_override("font_color", CRIMSON)
	game_over_label.text = _run_result_text(summary)
	_refresh_game_over_restart_button()
	_show_popup(game_over_backdrop, false, DEFEAT_FADE_DURATION)
	_continue_game_over_sequence(game_over_sequence)


func _continue_game_over_sequence(sequence_id: int) -> void:
	await get_tree().create_timer(DEFEAT_FADE_DURATION, true, false, true).timeout
	_reveal_game_over_panel(sequence_id)


func _reveal_game_over_panel(sequence_id: int) -> void:
	if sequence_id != game_over_sequence or not game_over_visible or game_over_panel_revealed:
		return
	if _popup_transition_active(game_over_backdrop):
		debug_finish_popup_transition(game_over_backdrop)
	game_over_panel_revealed = true
	_show_popup(game_over_panel)
	game_over_input_deadline_msec = Time.get_ticks_msec() + int(ceil((POPUP_FADE_IN_DURATION + DEFEAT_INPUT_DELAY_SECONDS) * 1000.0))
	_refresh_game_over_restart_button()


func _update_game_over_input_gate() -> void:
	if not game_over_visible or not game_over_panel_revealed or game_over_input_ready:
		return
	if Time.get_ticks_msec() < game_over_input_deadline_msec or _popup_transition_active(game_over_panel):
		_refresh_game_over_restart_button()
		return
	for action in DEFEAT_RELEASE_ACTIONS:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			_refresh_game_over_restart_button()
			return
	game_over_input_ready = true
	_refresh_game_over_restart_button()


func _refresh_game_over_restart_button() -> void:
	if not is_instance_valid(restart_button):
		return
	var chinese := TranslationServer.get_locale().begins_with("zh")
	restart_button.disabled = not game_over_input_ready
	if not game_over_input_ready:
		restart_button.text = "墨迹尚未干透……" if chinese else "THE INK IS STILL SETTLING..."
	elif using_gamepad:
		restart_button.text = "A/× 或 START  重写" if chinese else "A/× OR START  REWRITE"
	else:
		restart_button.text = "R  重写此页" if chinese else "R  REWRITE THE PAGE"


func debug_finish_game_over_transition(unlock_input: bool = false) -> void:
	# Regression tests can settle the real paused transition without waiting on
	# wall-clock animation, while production still requires the full delay and a
	# release edge before restart.
	if not game_over_visible:
		return
	game_over_sequence += 1
	if _popup_transition_active(game_over_backdrop):
		debug_finish_popup_transition(game_over_backdrop)
	_reveal_game_over_panel(game_over_sequence)
	if _popup_transition_active(game_over_panel):
		debug_finish_popup_transition(game_over_panel)
	if unlock_input:
		game_over_input_deadline_msec = 0
		_update_game_over_input_gate()


func _request_game_over_restart() -> void:
	if not game_over_visible or not game_over_input_ready or _popup_transition_active(game_over_panel):
		return
	game_over_input_ready = false
	game_over_sequence += 1
	_hide_popup(game_over_backdrop, Callable(), false)
	_hide_popup(game_over_panel, func() -> void: restart_requested.emit())


func show_victory(summary: Dictionary) -> void:
	last_result_summary = summary.duplicate(true)
	game_over_visible = false
	game_over_panel_revealed = false
	game_over_input_ready = false
	game_over_sequence += 1
	_hide_popup(game_over_backdrop, Callable(), false)
	_hide_popup(game_over_panel)
	victory_credit_pages = _victory_credit_page_data(summary)
	victory_credit_page = 0
	victory_credits_visible = true
	victory_credits_panel.move_to_front()
	_show_victory_credit_page()
	_show_popup(victory_credits_panel, false)


func _victory_credit_page_data(summary: Dictionary) -> Array[Dictionary]:
	var chinese := TranslationServer.get_locale().begins_with("zh")
	if chinese:
		return [
			{"title": "此页铭记于心", "body": _run_result_text_zh(summary), "duration": 4.2},
			{"title": "制作人员", "body": "设计 · 叙事 · 程序 · 制作\nMANGA FORGE 项目流水线", "duration": 3.0},
			{"title": "美术与声音", "body": "原创项目资产与人工指导下的视觉制作\n\n引擎\nGODOT ENGINE 与开源贡献者", "duration": 3.0},
			{"title": "试玩玩家", "body": "感谢每一位在页边留下意见的玩家。\n你们发现的问题，让下一份草稿变得更好。", "duration": 3.0},
			{"title": "感谢游玩", "body": "NARA 的故事会在下一份草稿中继续。", "final": true},
		]
	return [
		{"title": "THE PAGE REMEMBERS", "body": _run_result_text(summary), "duration": 4.2},
		{"title": "STAFF", "body": "DESIGN · NARRATIVE · CODE · PRODUCTION\nMANGA FORGE PROJECT PIPELINE", "duration": 3.0},
		{"title": "ART & AUDIO", "body": "ORIGINAL PROJECT ASSETS AND DIRECTED VISUAL PRODUCTION\n\nENGINE\nGODOT ENGINE AND OPEN-SOURCE CONTRIBUTORS", "duration": 3.0},
		{"title": "PLAYTESTERS", "body": "THANK YOU TO EVERY PLAYER WHO LEFT A NOTE IN THE MARGIN.\nYOUR FEEDBACK MADE THE NEXT DRAFT BETTER.", "duration": 3.0},
		{"title": "THANK YOU FOR PLAYING", "body": "NARA'S STORY CONTINUES IN THE NEXT DRAFT.", "final": true},
	]


func _show_victory_credit_page() -> void:
	if victory_credit_pages.is_empty() or not victory_credits_visible:
		return
	if victory_credit_tween != null and victory_credit_tween.is_valid():
		victory_credit_tween.kill()
	victory_credit_page = clampi(victory_credit_page, 0, victory_credit_pages.size() - 1)
	var page: Dictionary = victory_credit_pages[victory_credit_page]
	victory_credits_title.text = str(page.get("title", "THANK YOU FOR PLAYING"))
	victory_credits_body.text = str(page.get("body", ""))
	victory_credits_final = bool(page.get("final", false))
	var chinese := TranslationServer.get_locale().begins_with("zh")
	if victory_credits_final:
		victory_credits_prompt.text = "按任意键返回开始菜单" if chinese else "PRESS ANY BUTTON TO RETURN TO THE TITLE"
		return
	victory_credits_prompt.text = "制作人员名单即将继续 · 按任意键跳至鸣谢" if chinese else "CREDITS CONTINUE · PRESS ANY BUTTON TO SKIP TO THANKS"
	victory_credit_tween = create_tween()
	victory_credit_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	victory_credit_tween.tween_interval(float(page.get("duration", 3.0)))
	victory_credit_tween.tween_callback(_advance_victory_credit_page)


func _advance_victory_credit_page() -> void:
	if not victory_credits_visible or victory_credits_final:
		return
	victory_credit_page = mini(victory_credit_page + 1, victory_credit_pages.size() - 1)
	_show_victory_credit_page()


func _skip_victory_credits_to_thanks() -> void:
	if victory_credit_pages.is_empty():
		return
	victory_credit_page = victory_credit_pages.size() - 1
	_show_victory_credit_page()


func hide_victory_credits(callback: Callable = Callable()) -> void:
	if victory_credit_tween != null and victory_credit_tween.is_valid():
		victory_credit_tween.kill()
	victory_credit_tween = null
	victory_credit_pages.clear()
	victory_credits_visible = false
	victory_credits_final = false
	_hide_popup(victory_credits_panel, callback, false)


func _run_result_text(summary: Dictionary) -> String:
	if TranslationServer.get_locale().begins_with("zh"):
		return _run_result_text_zh(summary)
	var duration := maxi(0, int(summary.get("duration_seconds", 0)))
	var minutes := duration / 60
	var seconds := duration % 60
	var is_daily := bool(summary.get("daily_run", false))
	var outcome := "DRAFT LOST"
	if bool(summary.get("won", false)):
		outcome = "%s ENDING" % str(summary.get("ending", "")).to_upper()
	if is_daily:
		outcome = "DAILY CLEAR · %s" % outcome if bool(summary.get("won", false)) else "DAILY DRAFT LOST"
	var difficulty := str(summary.get("difficulty", "standard")).replace("-", " ").to_upper()
	var unlocks: Array = summary.get("new_unlocks", [])
	var unlock_line := "NEW  " + " · ".join(unlocks) if not unlocks.is_empty() else "NEXT DRAFT AWAITS"
	var route_names := PackedStringArray()
	for route_id in summary.get("route_ids", []):
		var route_data: Dictionary = Content.route(str(route_id))
		if not route_data.is_empty():
			route_names.append(str(route_data.get("short", route_data["name"])))
	var route_line := "ROUTES  " + " › ".join(route_names) if not route_names.is_empty() else "ROUTES  UNCHARTED"
	var draft_line := "DAILY %s / %s / SEED %08d" % [str(summary.get("daily_id", "")), str(summary.get("contract_name", "OPEN DRAFT")), int(summary.get("run_seed", 0))] if is_daily else "%s / %s / PROOF %02d" % [difficulty, str(summary.get("contract_name", "OPEN DRAFT")), int(summary.get("proof_depth", 0))]
	return "%s  ·  PAGE %d  ·  LV %d\nINK %06d  ·  MASKS %03d  ·  BEST %06d\nMEMORY +%d  ·  ARCHIVE RANK %d  ·  %02d:%02d\n%s\nFORM  %s  ·  RELICS %d\nORDERS  %d / %d COMPLETE\n%s\n%s" % [
		outcome,
		int(summary.get("wave", 1)),
		int(summary.get("level", 1)),
		int(summary.get("score", 0)),
		int(summary.get("kills", 0)),
		int(summary.get("best_score", 0)),
		int(summary.get("memory_earned", 0)),
		int(summary.get("archive_rank", 1)),
		minutes,
		seconds,
		draft_line,
		str(summary.get("weapon_form", "MARGINALIA")),
		int(summary.get("relic_count", summary.get("relic_ids", []).size())),
		int(summary.get("directives_completed", 0)),
		int(summary.get("directives_started", 0)),
		route_line,
		unlock_line,
	]


func _run_result_text_zh(summary: Dictionary) -> String:
	var duration := maxi(0, int(summary.get("duration_seconds", 0)))
	var is_daily := bool(summary.get("daily_run", false))
	var outcome := "每日草稿失败" if is_daily else "草稿失败"
	if bool(summary.get("won", false)):
		var ending_name := "页边" if str(summary.get("ending", "")) == "keep" else "散页"
		outcome = ("每日通关 · " if is_daily else "") + ending_name + "结局"
	var difficulty_names_zh := {"story": "故事", "standard": "标准", "redline": "红线"}
	var difficulty := str(difficulty_names_zh.get(summary.get("difficulty", "standard"), "标准"))
	var unlock_names := PackedStringArray()
	for unlock_name in summary.get("new_unlocks", []):
		unlock_names.append(Localization.text(unlock_name))
	var unlock_line := "新解锁  " + " · ".join(unlock_names) if not unlock_names.is_empty() else "下一份草稿正在等待"
	var route_names := PackedStringArray()
	for route_id in summary.get("route_ids", []):
		var route_data: Dictionary = Content.route(str(route_id))
		if not route_data.is_empty():
			route_names.append(Localization.text(route_data.get("short", route_data["name"])))
	var route_line := "路线  " + " › ".join(route_names) if not route_names.is_empty() else "路线  尚未探索"
	var contract_name := Localization.text(summary.get("contract_name", "OPEN DRAFT"))
	var draft_line := "每日 %s / %s / 种子 %08d" % [str(summary.get("daily_id", "")), contract_name, int(summary.get("run_seed", 0))] if is_daily else "%s / %s / 校样 %02d" % [difficulty, contract_name, int(summary.get("proof_depth", 0))]
	return "%s  ·  第 %d 页  ·  等级 %d\n墨迹 %06d  ·  面具 %03d  ·  最佳 %06d\n记忆 +%d  ·  档案等级 %d  ·  %02d:%02d\n%s\n形态  %s  ·  遗物 %d\n指令  %d / %d 完成\n%s\n%s" % [
		outcome,
		int(summary.get("wave", 1)),
		int(summary.get("level", 1)),
		int(summary.get("score", 0)),
		int(summary.get("kills", 0)),
		int(summary.get("best_score", 0)),
		int(summary.get("memory_earned", 0)),
		int(summary.get("archive_rank", 1)),
		duration / 60,
		duration % 60,
		draft_line,
		Localization.text(summary.get("weapon_form", "MARGINALIA")),
		int(summary.get("relic_count", summary.get("relic_ids", []).size())),
		int(summary.get("directives_completed", 0)),
		int(summary.get("directives_started", 0)),
		route_line,
		unlock_line,
	]


func set_paused(paused: bool) -> void:
	var should_show := paused and not manual_visible and not upgrade_visible and not relic_draft_visible and not event_visible and not game_over_visible
	if should_show and (not pause_panel.visible or _popup_transition_phase(pause_panel) == "out"):
		pause_navigation_index = 0
		_refresh_pause_navigation()
		_show_popup(pause_panel)
	elif not should_show and pause_panel.visible and _popup_transition_phase(pause_panel) != "out":
		_hide_popup(pause_panel)
	if not paused and settings_visible and not title_visible:
		hide_settings()


func _move_pause_navigation(direction: int) -> void:
	if not pause_panel.visible or quit_visible:
		return
	pause_navigation_index = posmod(pause_navigation_index + direction, pause_navigation_buttons.size())
	_refresh_pause_navigation()


func _activate_pause_navigation() -> void:
	match pause_navigation_index:
		0:
			pause_requested.emit()
		1:
			show_settings()
		2:
			show_manual()
		3:
			save_return_requested.emit()
		4:
			show_quit_confirmation(true)


func _refresh_pause_navigation() -> void:
	if pause_navigation_buttons.is_empty():
		return
	var chinese := TranslationServer.get_locale().begins_with("zh")
	pause_navigation_index = clampi(pause_navigation_index, 0, pause_navigation_buttons.size() - 1)
	pause_label.text = "战场已暂停" if chinese else "PANEL PAUSED"
	if using_gamepad:
		pause_resume_button.text = "A  继续" if chinese else "A  CONTINUE"
		pause_options_button.text = "VIEW  选项" if chinese else "VIEW  OPTIONS"
		pause_manual_button.text = "LT  战地手册" if chinese else "LT  FIELD MANUAL"
		pause_save_return_button.text = "X  保存并返回" if chinese else "X  SAVE & RETURN"
		pause_quit_button.text = "退出到桌面" if chinese else "QUIT TO DESKTOP"
		pause_help_label.text = "↑↓ 选择  ·  A 确认  ·  B/START 返回" if chinese else "↑↓ SELECT  ·  A CONFIRM  ·  B/START BACK"
	else:
		pause_resume_button.text = "回车  继续" if chinese else "ENTER  CONTINUE"
		pause_options_button.text = "O / F10  选项" if chinese else "O / F10  OPTIONS"
		pause_manual_button.text = "F1 / H  战地手册" if chinese else "F1 / H  FIELD MANUAL"
		pause_save_return_button.text = "1  保存并返回" if chinese else "1  SAVE & RETURN"
		pause_quit_button.text = "退出到桌面" if chinese else "QUIT TO DESKTOP"
		pause_help_label.text = "↑↓ 选择  ·  回车确认  ·  ESC 返回" if chinese else "↑↓ SELECT  ·  ENTER CONFIRM  ·  ESC BACK"
	for index in range(pause_navigation_buttons.size()):
		pause_navigation_buttons[index].modulate = GOLD if index == pause_navigation_index else Color.WHITE


func set_input_mode(gamepad_active: bool) -> void:
	using_gamepad = gamepad_active
	var chinese := TranslationServer.get_locale().begins_with("zh")
	if gamepad_active:
		controls_label.text = "左摇杆移动  ·  右摇杆瞄准  ·  X/RT 斩击  ·  A/LB 冲刺  ·  B 墨术  ·  START 暂停" if chinese else "LS MOVE  ·  RS AIM  ·  X/RT SLASH  ·  A/LB DASH  ·  B ART  ·  START PAUSE"
		pause_label.text = "战场已暂停\n按 START 继续" if chinese else "PANEL PAUSED\nSTART TO CONTINUE"
		pause_options_button.text = "VIEW  选项" if chinese else "VIEW  OPTIONS"
		pause_manual_button.text = "LT  战地手册" if chinese else "LT  FIELD MANUAL"
		manual_button.text = "战地手册" if chinese else "FIELD MANUAL"
	else:
		controls_label.text = "WASD 移动  ·  鼠标/J 斩击  ·  空格/K 冲刺  ·  E 墨术  ·  ESC 暂停" if chinese else "WASD MOVE  ·  MOUSE/J SLASH  ·  SPACE/K DASH  ·  E ART  ·  ESC PAUSE"
		pause_label.text = "战场已暂停\n按 ESC 继续" if chinese else "PANEL PAUSED\nESC TO CONTINUE"
		pause_options_button.text = "O / F10  选项" if chinese else "O / F10  OPTIONS"
		pause_manual_button.text = "F1 / H  战地手册" if chinese else "F1 / H  FIELD MANUAL"
		manual_button.text = "战地手册" if chinese else "FIELD MANUAL"
	_refresh_game_over_restart_button()
	_refresh_pause_navigation()
	_refresh_quit_confirmation()
	_refresh_manual()
	set_ink_art(ink_art_source_name, ink_art_remaining, ink_art_maximum)
	if upgrade_visible:
		_refresh_upgrade_buttons()
	if relic_draft_visible:
		_refresh_relic_draft_buttons()
	_refresh_title_navigation()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		ui_gamepad_latches.clear()
	if title_visible:
		_refresh_daily_chronicle()


func set_shards(amount: int) -> void:
	shard_amount = amount
	shard_label.text = ("记忆 %03d" if TranslationServer.get_locale().begins_with("zh") else "MEM %03d") % amount


func set_relics(relic_ids: Array[String]) -> void:
	current_relic_ids.clear()
	current_relic_ids.assign(relic_ids)
	var recent_names := PackedStringArray()
	for relic_id in relic_ids.slice(maxi(0, relic_ids.size() - 2)):
		var definition := Content.relic(str(relic_id))
		recent_names.append(Localization.text(definition.get("name", relic_id)))
	relic_label.text = (("遗物 %d  ·  %s") if TranslationServer.get_locale().begins_with("zh") else "RELICS %d  ·  %s") % [relic_ids.size(), "  ".join(recent_names)]


func set_objective(text_value: String) -> void:
	objective_source = text_value
	objective_label.text = Localization.gameplay_text(text_value).to_upper()


func set_page_directive(title: String, kind: String, current: float, target: float, reward_text: String, completed: bool = false, occupied: bool = false) -> void:
	directive_source = {"title": title, "kind": kind, "current": current, "target": target, "reward": reward_text, "completed": completed, "occupied": occupied}
	directive_panel.visible = true
	directive_title.text = "[left]%s[/left]" % Localization.text("DIRECTIVE COMPLETE" if completed else title.to_upper()).left(26)
	directive_title.add_theme_color_override("default_color", GOLD if completed else CRIMSON)
	var ratio := 1.0 if completed else clampf(current / maxf(0.01, target), 0.0, 1.0)
	directive_bar_fill.size = Vector2(124.0 * ratio, 4.0)
	directive_bar_fill.color = GOLD if completed or occupied else CRIMSON
	if completed:
		directive_progress.text = "[left]%s[/left]" % ("指令已完成" if TranslationServer.get_locale().begins_with("zh") else "ORDER FULFILLED")
	else:
		var chinese := TranslationServer.get_locale().begins_with("zh")
		match kind:
			"ink":
				directive_progress.text = "[left]%s  %d / %d[/left]" % ["墨迹" if chinese else "INK", int(current), int(target)]
			"elites":
				directive_progress.text = "[left]%s  %d / %d[/left]" % ["精英" if chinese else "ELITES", int(current), int(target)]
			"hold":
				directive_progress.text = "[left]%s  %.1f / %.1f[/left]" % [("坚守" if occupied else "进入") if chinese else ("HOLD" if occupied else "ENTER"), current, target]
			_:
				directive_progress.text = "[left]%s  %d / %d[/left]" % ["面具" if chinese else "MASKS", int(current), int(target)]
	directive_reward.text = "[left]%s  %s[/left]" % ["奖励" if TranslationServer.get_locale().begins_with("zh") else "REWARD", Localization.text(reward_text.to_upper())]


func hide_page_directive() -> void:
	directive_panel.visible = false
	directive_source.clear()


func set_build(summary: String) -> void:
	build_source = summary
	build_label.text = _localized_build_summary(summary).left(46).to_upper()


func _localized_build_summary(summary: String) -> String:
	var sections := summary.split("  ·  ", false, 1)
	var result := Localization.text(sections[0])
	if sections.size() < 2 or sections[1].is_empty():
		return result
	for discipline in Content.BUILD_DISCIPLINES:
		var discipline_name := str(discipline.get("name", ""))
		if sections[1].begins_with(discipline_name):
			return "%s  ·  %s%s" % [result, Localization.text(discipline_name), sections[1].trim_prefix(discipline_name)]
	if not TranslationServer.get_locale().begins_with("zh"):
		return summary
	var techniques := PackedStringArray()
	for stack_text in sections[1].split(", "):
		var fields := stack_text.rsplit(" x", true, 1)
		var definition := Content.upgrade(fields[0])
		var display_name := Localization.text(definition.get("name", fields[0]))
		techniques.append("%s ×%s" % [display_name, fields[1] if fields.size() > 1 else "1"])
	return "%s  ·  %s" % [result, "，".join(techniques)]


func set_boss(name: String, current: float, maximum: float) -> void:
	var visible_now := not name.is_empty() and maximum > 0.0
	boss_panel.visible = visible_now
	if not visible_now:
		return
	boss_bar_fill.size.x = boss_bar.size.x * clampf(current / maximum, 0.0, 1.0)
	boss_label.text = Localization.text(name).to_upper()


func show_title(meta: Dictionary) -> void:
	title_data = meta.duplicate(true)
	title_visible = true
	proof_depth = clampi(int(title_data.get("preferred_proof_depth", 0)), 0, int(title_data.get("max_proof_depth", 0)))
	proof_selected = proof_depth
	proof_visible = false
	_hide_popup_immediate(proof_panel)
	daily_visible = false
	_hide_popup_immediate(daily_panel)
	restoration_visible = false
	_hide_popup_immediate(restoration_panel)
	loadout_visible = false
	_hide_popup_immediate(loadout_panel)
	new_game_armed = false
	title_panel.visible = true
	_ensure_title_selections_unlocked()
	_refresh_title()
	title_navigation_index = 1 if not continue_button.disabled else 0
	_refresh_title_navigation()


func hide_title() -> void:
	title_visible = false
	title_panel.visible = false
	proof_visible = false
	_hide_popup_immediate(proof_panel)
	daily_visible = false
	_hide_popup_immediate(daily_panel)
	restoration_visible = false
	_hide_popup_immediate(restoration_panel)
	codex_visible = false
	_hide_popup_immediate(codex_panel)
	achievements_visible = false
	_hide_popup_immediate(achievements_panel)
	history_visible = false
	_hide_popup_immediate(history_panel)
	story_visible = false
	_hide_popup_immediate(story_panel)
	loadout_visible = false
	_hide_popup_immediate(loadout_panel)
	title_navigation_cursor.visible = false


func refresh_title_meta(meta: Dictionary) -> void:
	title_data = meta.duplicate(true)
	_ensure_title_selections_unlocked()
	_refresh_title()


func _refresh_title() -> void:
	var chinese := TranslationServer.get_locale().begins_with("zh")
	title_quit_button.text = "退出" if chinese else "QUIT"
	var memories := int(title_data.get("meta_shards", 0))
	var rank_data: Dictionary = title_data.get("archive_rank", {})
	var archive_rank := int(rank_data.get("rank", 1))
	title_stats_label.text = ("档案等级 %02d  ·  记忆 %03d  ·  最佳 %06d" if chinese else "RANK %02d  ·  MEM %03d  ·  BEST %06d") % [archive_rank, memories, int(title_data.get("best_score", 0))]
	var unlocked_difficulties: Array = title_data.get("unlocked_difficulties", ["story", "standard"])
	difficulty_button.text = "‹  %s  %d/%d  ›" % [Localization.text(difficulty_names[difficulty_index]), unlocked_difficulties.size(), difficulty_ids.size()]
	var contract_data: Dictionary = Localization.localized(Content.CONTRACTS[contract_index])
	var contract_id: String = contract_data["id"]
	var contract_wins: Dictionary = title_data.get("contract_wins", {})
	var unlocked_contracts: Array = title_data.get("unlocked_contracts", ["open-draft"])
	contract_button.text = "LB/RB  %d/%d\n%s" % [unlocked_contracts.size(), Content.CONTRACTS.size(), contract_data["name"]]
	contract_description_label.text = ("%s  ·  已通关 %d" if chinese else "%s  ·  CLEARED %d") % [str(contract_data["description"]).to_upper(), int(contract_wins.get(contract_id, 0))]
	var checkpoint: Dictionary = title_data.get("checkpoint", {})
	if not new_game_armed:
		start_button.text = Localization.text("NEW GAME")
	continue_button.disabled = checkpoint.is_empty()
	if checkpoint.is_empty():
		continue_button.text = "继续 / 读取\n没有已保存的草稿" if chinese else "CONTINUE / LOAD\nNO SAVED DRAFT"
	else:
		continue_button.text = ("START / C  继续\n第 %d 页 · 等级%d · 校样%d" if chinese else "START / C  CONTINUE\nPAGE %d · LV%d · D%d") % [int(checkpoint.get("wave", 1)), int(checkpoint.get("level", 1)), int(checkpoint.get("proof_depth", 0))]
	var max_depth := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	proof_depth = clampi(proof_depth, 0, max_depth)
	proof_selected = clampi(proof_selected, 0, max_depth)
	var proof_data: Dictionary = Localization.localized(Content.proof_level(proof_depth))
	var proof_modifiers := Content.proof_modifiers(proof_depth)
	proof_button.text = ("P / LS  校样 %d/%d\n%s  ·  ×%.2f / ×%.2f" if chinese else "P / LS  PROOF %d/%d\n%s  ·  ×%.2f / ×%.2f") % [proof_depth, max_depth, proof_data.get("name", "OPEN PROOF"), float(proof_modifiers["score"]), float(proof_modifiers["shards"])]
	_refresh_proof_ledger()
	var next_unlock: Dictionary = Localization.localized(title_data.get("next_unlock", {}))
	if next_unlock.is_empty():
		restore_title_label.text = ("档案等级 %d/%d  ·  所有草稿均已修复" if chinese else "ARCHIVE RANK %d/%d  ·  EVERY DRAFT RESTORED") % [archive_rank, int(rank_data.get("maximum", archive_rank))]
	else:
		restore_title_label.text = ("等级 %d  ·  下一个：%s %d/%d  ·  %s" if chinese else "RANK %d  ·  NEXT: %s %d/%d  ·  %s") % [archive_rank, next_unlock.get("name", "MEMORY"), int(next_unlock.get("current", 0)), int(next_unlock.get("target", 1)), next_unlock.get("hint", "")]
	var ranks: Dictionary = title_data.get("meta_upgrades", {})
	var restored_ranks := 0
	var available_branches := 0
	for definition in Content.META_RESTORATIONS:
		restored_ranks += int(ranks.get(definition["id"], 0))
		if archive_rank >= int(definition["required_rank"]):
			available_branches += 1
	restoration_open_button.text = ("M / RS  修复\n%d/30 等级  ·  %d/%d 分支" if chinese else "M / RS  RESTORATION\n%d/30 RANKS  ·  %d/%d BRANCHES") % [restored_ranks, available_branches, Content.META_RESTORATIONS.size()]
	_refresh_daily_chronicle()
	_refresh_restoration_board()
	_refresh_codex()
	_refresh_achievements()
	_refresh_history()
	_refresh_story()
	_refresh_loadout()
	_refresh_title_navigation()


func _title_overlay_visible() -> bool:
	return daily_visible or proof_visible or restoration_visible or loadout_visible or codex_visible or achievements_visible or history_visible or story_visible or settings_visible or bindings_visible or manual_visible or quit_visible


func _refresh_title_navigation() -> void:
	if title_navigation_buttons.is_empty() or title_navigation_cursor == null:
		return
	title_navigation_index = clampi(title_navigation_index, 0, title_navigation_buttons.size() - 1)
	if title_navigation_buttons[title_navigation_index].disabled or not title_navigation_buttons[title_navigation_index].visible:
		for index in range(title_navigation_buttons.size()):
			if not title_navigation_buttons[index].disabled and title_navigation_buttons[index].visible:
				title_navigation_index = index
				break
	for index in range(title_navigation_buttons.size()):
		var button := title_navigation_buttons[index]
		button.modulate = Color(1.0, 0.82, 0.42, 1.0) if index == title_navigation_index and not button.disabled else Color.WHITE
	var selected := title_navigation_buttons[title_navigation_index]
	title_navigation_cursor.position = selected.position + Vector2(-5, 4)
	title_navigation_cursor.size = Vector2(3, maxf(8.0, selected.size.y - 8.0))
	title_navigation_cursor.visible = title_visible and not _title_overlay_visible() and not selected.disabled
	if using_gamepad:
		title_navigation_label.text = "十字键/左摇杆  选择  ·  A/×  确认  ·  B/○  返回" if TranslationServer.get_locale().begins_with("zh") else "D-PAD / LEFT STICK  NAVIGATE  ·  A/CROSS  SELECT  ·  B/CIRCLE  BACK"
	else:
		title_navigation_label.text = "方向键  选择  ·  回车  确认  ·  ESC  返回" if TranslationServer.get_locale().begins_with("zh") else "ARROWS  NAVIGATE  ·  ENTER  SELECT  ·  ESC  BACK"


func _move_title_navigation(direction: Vector2) -> void:
	if title_navigation_buttons.is_empty() or direction == Vector2.ZERO:
		return
	var current := title_navigation_buttons[title_navigation_index]
	var current_center := current.position + current.size * 0.5
	var best_index := -1
	var best_score := INF
	for index in range(title_navigation_buttons.size()):
		if index == title_navigation_index:
			continue
		var candidate := title_navigation_buttons[index]
		if candidate.disabled or not candidate.visible:
			continue
		var offset := candidate.position + candidate.size * 0.5 - current_center
		var forward := offset.dot(direction)
		if forward <= 1.0:
			continue
		var cross_distance := absf(offset.cross(direction))
		var score_value := forward + cross_distance * 1.75
		if score_value < best_score:
			best_score = score_value
			best_index = index
	if best_index >= 0:
		title_navigation_index = best_index
		_refresh_title_navigation()


func _activate_title_navigation() -> void:
	if title_navigation_index < 0 or title_navigation_index >= title_navigation_actions.size():
		return
	match title_navigation_actions[title_navigation_index]:
		"new_game":
			_start_from_title()
		"continue":
			_continue_from_title()
		"difficulty":
			_cycle_difficulty(1)
		"contract":
			_cycle_contract(1)
		"proof":
			_show_proof_ledger()
		"daily":
			_show_daily()
		"restoration":
			_show_restoration()
		"story":
			_toggle_story()
		"settings":
			show_settings()
		"history":
			_toggle_history()
		"manual":
			show_manual()
		"achievements":
			_toggle_achievements()
		"codex":
			_toggle_codex()
		"quit":
			show_quit_confirmation(false)
	_refresh_title_navigation()


func _title_accept_pressed(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_A
	if event is InputEventKey:
		return event.pressed and event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]
	return false


func _any_button_pressed(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false


func _refresh_daily_chronicle() -> void:
	if daily_button == null or daily_panel == null:
		return
	var data: Dictionary = title_data.get("daily", {})
	var chinese := TranslationServer.get_locale().begins_with("zh")
	var date_id := str(data.get("id", "TODAY"))
	var contract_name := Localization.text(data.get("contract_name", "OPEN DRAFT"))
	var cleared_mark := ("已通关" if chinese else "CLEARED") if bool(data.get("cleared", false)) else ("开放" if chinese else "OPEN")
	daily_button.text = ("每日编年史 · %s\n%s · 最佳 %06d" if chinese else "DAILY CHRONICLE · %s\n%s · BEST %06d") % [cleared_mark, contract_name, int(data.get("best_score", 0))]
	daily_title_label.text = ("每日编年史 · %s" if chinese else "DAILY CHRONICLE · %s") % date_id
	daily_contract_label.text = ("%s · 种子 %08d" if chinese else "%s · SEED %08d") % [contract_name, int(data.get("seed", 1))]
	var reward_text := ("首次通关奖励已领取" if chinese else "FIRST CLEAR CLAIMED") if bool(data.get("cleared", false)) else (("首次通关 +%d 记忆" if chinese else "FIRST CLEAR +%d MEMORY") % int(data.get("first_clear_bonus", Content.DAILY_CLEAR_BONUS)))
	daily_rules_label.text = ("标准 · 页边之刃 · 校样 0 · 修复加成封印\n事件、小队、技巧、掉落和危险均使用相同种子\n%s" if chinese else "STANDARD · MARGINALIA · PROOF 0 · RESTORATIONS SEALED\nSAME EVENTS, SQUADS, TECHNIQUES, DROPS, AND HAZARDS\n%s") % reward_text
	daily_record_label.text = ("尝试 %d · 胜利 %d · 最佳 %06d · 连胜 %d / %d" if chinese else "ATTEMPTS %d · WINS %d · BEST %06d · STREAK %d / %d") % [
		int(data.get("attempts", 0)),
		int(data.get("wins", 0)),
		int(data.get("best_score", 0)),
		int(data.get("current_streak", 0)),
		int(data.get("best_streak", 0)),
	]
	var checkpoint: Dictionary = title_data.get("checkpoint", {})
	if using_gamepad:
		daily_start_button.text = ("A/×  覆盖存档并开始" if chinese else "A/×  REPLACE SAVE & BEGIN") if not checkpoint.is_empty() else ("A/×  开始今日草稿" if chinese else "A/×  BEGIN TODAY'S DRAFT")
	else:
		daily_start_button.text = ("回车  覆盖存档并开始" if chinese else "ENTER  REPLACE SAVE & BEGIN") if not checkpoint.is_empty() else ("回车  开始今日草稿" if chinese else "ENTER  BEGIN TODAY'S DRAFT")


func _show_daily() -> void:
	if not title_visible:
		return
	codex_visible = false
	_hide_popup(codex_panel)
	achievements_visible = false
	_hide_popup(achievements_panel)
	history_visible = false
	_hide_popup(history_panel)
	story_visible = false
	_hide_popup(story_panel)
	loadout_visible = false
	_hide_popup(loadout_panel)
	proof_visible = false
	_hide_popup(proof_panel)
	restoration_visible = false
	_hide_popup(restoration_panel)
	daily_visible = true
	daily_panel.move_to_front()
	_refresh_daily_chronicle()
	_show_popup(daily_panel)


func _hide_daily() -> void:
	daily_visible = false
	_hide_popup(daily_panel)


func _begin_daily() -> void:
	if not title_visible or not daily_visible:
		return
	_hide_daily()
	daily_requested.emit()


func _ensure_title_selections_unlocked() -> void:
	var unlocked_contracts: Array = title_data.get("unlocked_contracts", ["open-draft"])
	if Content.CONTRACTS[contract_index]["id"] not in unlocked_contracts:
		for index in range(Content.CONTRACTS.size()):
			if Content.CONTRACTS[index]["id"] in unlocked_contracts:
				contract_index = index
				break
	var unlocked_difficulties: Array = title_data.get("unlocked_difficulties", ["story", "standard"])
	if difficulty_ids[difficulty_index] not in unlocked_difficulties:
		difficulty_index = difficulty_ids.find("standard")
	var unlocked_loadouts := _unlocked_loadout_ids()
	if Content.STARTING_WEAPONS[loadout_selected]["id"] not in unlocked_loadouts:
		loadout_selected = 0


func _unlocked_loadout_ids() -> Array[String]:
	var result: Array[String] = ["marginalia"]
	for weapon_id in title_data.get("unlocked_weapon_forms", []):
		var clean_id := str(weapon_id)
		if not Content.starting_weapon(clean_id).is_empty() and clean_id not in result:
			result.append(clean_id)
	return result


func _weapon_unlock_hint(weapon_id: String) -> String:
	for entry in Content.PROGRESSION_UNLOCKS:
		if str(entry.get("kind", "")) == "weapon" and str(entry.get("content_id", "")) == weapon_id:
			return Localization.text(entry.get("hint", "LOCKED")).to_upper()
	return Localization.text("LOCKED")


func _refresh_loadout() -> void:
	if loadout_buttons.is_empty():
		return
	var unlocked := _unlocked_loadout_ids()
	var chinese := TranslationServer.get_locale().begins_with("zh")
	if Content.STARTING_WEAPONS[loadout_selected]["id"] not in unlocked:
		loadout_selected = 0
	for index in range(Content.STARTING_WEAPONS.size()):
		var entry: Dictionary = Localization.localized(Content.STARTING_WEAPONS[index])
		var weapon_id := str(entry["id"])
		var available := weapon_id in unlocked
		var prefix := "▶  " if index == loadout_selected else "    "
		loadout_buttons[index].disabled = not available
		loadout_buttons[index].text = (("%s%s  ·  墨术：%s" if chinese else "%s%s  ·  INK ART: %s") % [prefix, str(entry["name"]), str(entry["art"])]) if available else (("未解锁  ·  %s  ·  %s" if chinese else "LOCKED  ·  %s  ·  %s") % [str(entry["name"]), _weapon_unlock_hint(weapon_id)])
		loadout_buttons[index].add_theme_color_override("font_color", GOLD if index == loadout_selected else PAPER)
	var selected: Dictionary = Localization.localized(Content.STARTING_WEAPONS[loadout_selected])
	loadout_description_label.text = ("%s\n%d/%d 已解锁  ·  ↑↓ 选择  ·  A/回车 确认  ·  B/ESC 返回" if chinese else "%s\n%d/%d UNLOCKED  ·  ↑↓ SELECT  ·  A/ENTER CONFIRM  ·  B/ESC BACK") % [str(selected["description"]).to_upper(), unlocked.size(), Content.STARTING_WEAPONS.size()]


func _show_loadout() -> void:
	if not title_visible:
		return
	codex_visible = false
	_hide_popup(codex_panel)
	achievements_visible = false
	_hide_popup(achievements_panel)
	history_visible = false
	_hide_popup(history_panel)
	story_visible = false
	_hide_popup(story_panel)
	proof_visible = false
	_hide_popup(proof_panel)
	daily_visible = false
	_hide_popup(daily_panel)
	loadout_visible = true
	_refresh_loadout()
	_show_popup(loadout_panel)


func _move_loadout_selection(direction: int) -> void:
	var unlocked := _unlocked_loadout_ids()
	for _step in range(Content.STARTING_WEAPONS.size()):
		loadout_selected = posmod(loadout_selected + direction, Content.STARTING_WEAPONS.size())
		if str(Content.STARTING_WEAPONS[loadout_selected]["id"]) in unlocked:
			break
	_refresh_loadout()


func _choose_loadout(index: int) -> void:
	if not loadout_visible or _popup_transition_active(loadout_panel) or index < 0 or index >= Content.STARTING_WEAPONS.size():
		return
	var weapon_id := str(Content.STARTING_WEAPONS[index]["id"])
	if weapon_id not in _unlocked_loadout_ids():
		show_device_notice("STARTING BLADE STILL LOCKED")
		return
	loadout_selected = index
	_hide_popup(loadout_panel, _finish_loadout_choice.bind(weapon_id))


func _finish_loadout_choice(weapon_id: String) -> void:
	loadout_visible = false
	new_game_armed = false
	hide_title()
	start_requested.emit(difficulty_ids[difficulty_index], Content.CONTRACTS[contract_index]["id"], weapon_id, proof_depth)


func _cancel_loadout() -> void:
	if _popup_transition_active(loadout_panel):
		return
	loadout_visible = false
	_hide_popup(loadout_panel)
	new_game_armed = false
	_refresh_title()


func _refresh_codex() -> void:
	var kills: Dictionary = title_data.get("codex_kills", {})
	var lines := PackedStringArray()
	var chinese := TranslationServer.get_locale().begins_with("zh")
	for enemy_id in Content.ENEMIES:
		var count := int(kills.get(enemy_id, 0))
		var entry: Dictionary = Localization.localized(Content.ENEMIES[enemy_id])
		if count > 0:
			lines.append(("%s  ·  %s  ·  击败 %d" if chinese else "%s  ·  %s  ·  DEFEATED %d") % [entry["name"].to_upper(), entry["role"], count])
		else:
			lines.append("????????  ·  未回收记忆" if chinese else "????????  ·  UNRECOVERED MEMORY")
	codex_label.text = "\n".join(lines)


func _toggle_codex() -> void:
	if not title_visible or _popup_transition_active(codex_panel):
		return
	codex_visible = not codex_visible
	if codex_visible:
		_show_popup(codex_panel)
	else:
		_hide_popup(codex_panel)
	if codex_visible:
		daily_visible = false
		_hide_popup(daily_panel)
		achievements_visible = false
		_hide_popup(achievements_panel)
		history_visible = false
		_hide_popup(history_panel)
		story_visible = false
		_hide_popup(story_panel)


func _refresh_achievements() -> void:
	var unlocked: Array = title_data.get("unlocked_achievements", [])
	var progress: Dictionary = title_data.get("achievement_progress", {})
	var lines := PackedStringArray()
	for raw_achievement in Content.ACHIEVEMENTS:
		var achievement: Dictionary = Localization.localized(raw_achievement)
		var achievement_id: String = achievement["id"]
		var current := mini(int(progress.get(achievement_id, 0)), int(achievement["target"]))
		var state := "✓" if achievement_id in unlocked else "·"
		lines.append("%s  %s  %d/%d  ·  %s" % [state, str(achievement["name"]).to_upper(), current, int(achievement["target"]), achievement["description"]])
	achievements_label.text = "\n".join(lines)


func _toggle_achievements() -> void:
	if not title_visible or _popup_transition_active(achievements_panel):
		return
	achievements_visible = not achievements_visible
	if achievements_visible:
		_show_popup(achievements_panel)
	else:
		_hide_popup(achievements_panel)
	if achievements_visible:
		daily_visible = false
		_hide_popup(daily_panel)
		codex_visible = false
		_hide_popup(codex_panel)
		history_visible = false
		_hide_popup(history_panel)
		story_visible = false
		_hide_popup(story_panel)


func _refresh_history() -> void:
	var runs: Array = title_data.get("recent_runs", [])
	if runs.is_empty():
		history_label.text = "NO DRAFTS RECORDED\n\nCOMPLETE A RUN TO BEGIN THE ARCHIVE LEDGER."
		return
	var lines := PackedStringArray()
	var chinese := TranslationServer.get_locale().begins_with("zh")
	for run_data in runs:
		var state := ("胜利" if chinese else "WIN") if bool(run_data.get("won", false)) else ("失败" if chinese else "LOST")
		var raw_mode := "DAILY" if bool(run_data.get("daily_run", false)) else str(run_data.get("difficulty", "standard")).to_upper()
		var mode := Localization.text(raw_mode)
		var contract_name := Localization.text(run_data.get("contract_name", "OPEN DRAFT"))
		lines.append(("#%02d  %-4s  页%02d 级%02d  %-8s  校%02d  %-11s  %06d  +%02d" if chinese else "#%02d  %-4s  P%02d L%02d  %-8s  D%02d  %-11s  %06d  +%02d") % [
			int(run_data.get("run_number", 0)),
			state,
			int(run_data.get("wave", 1)),
			int(run_data.get("level", 1)),
			mode,
			int(run_data.get("proof_depth", 0)),
			contract_name.left(11),
			int(run_data.get("score", 0)),
			int(run_data.get("memory_earned", 0)),
		])
	history_label.text = "\n".join(lines)


func _toggle_history() -> void:
	if not title_visible or _popup_transition_active(history_panel):
		return
	history_visible = not history_visible
	if history_visible:
		_show_popup(history_panel)
	else:
		_hide_popup(history_panel)
	if history_visible:
		daily_visible = false
		_hide_popup(daily_panel)
		codex_visible = false
		_hide_popup(codex_panel)
		achievements_visible = false
		_hide_popup(achievements_panel)
		story_visible = false
		_hide_popup(story_panel)


func _story_archive_entries() -> Array[Dictionary]:
	var order: Array[String] = ["prologue", "act1_reveal", "act2_revelation", "act3_confrontation", "ending_choice", "ending_keep", "ending_rewrite"]
	var completed: Array = title_data.get("completed_endings", [])
	var highest := int(title_data.get("highest_wave", 1))
	var entries: Array[Dictionary] = []
	for sequence_id in order:
		var data: Dictionary = Localization.localized(Content.story(sequence_id))
		var unlocked: bool = sequence_id == "prologue"
		match sequence_id:
			"act1_reveal":
				unlocked = highest >= 4
			"act2_revelation":
				unlocked = highest >= 8
			"act3_confrontation", "ending_choice":
				unlocked = highest >= 12
			"ending_keep":
				unlocked = "keep" in completed
			"ending_rewrite":
				unlocked = "rewrite" in completed
		entries.append({
			"id": sequence_id,
			"chapter": str(data.get("chapter", "MEMORY")),
			"title": str(data.get("title", sequence_id.to_upper())),
			"unlocked": unlocked,
		})
	return entries


func _refresh_story() -> void:
	story_entries = _story_archive_entries()
	if story_selected < 0 or story_selected >= story_entries.size() or not bool(story_entries[story_selected].get("unlocked", false)):
		story_selected = 0
	for index in range(story_buttons.size()):
		var entry: Dictionary = story_entries[index]
		var unlocked := bool(entry.get("unlocked", false))
		var marker := "▶" if story_visible and index == story_selected else " "
		story_buttons[index].text = "%s %02d  %-20s  ·  %s" % [marker, index + 1, str(entry.get("chapter", Localization.text("MEMORY"))).left(20), str(entry.get("title", Localization.text("LOCKED"))) if unlocked else ("未解锁记忆" if TranslationServer.get_locale().begins_with("zh") else "LOCKED MEMORY")]
		story_buttons[index].disabled = not unlocked


func _toggle_story() -> void:
	if not title_visible or _popup_transition_active(story_panel):
		return
	story_visible = not story_visible
	if story_visible:
		_show_popup(story_panel)
	else:
		_hide_popup(story_panel)
	if story_visible:
		daily_visible = false
		_hide_popup(daily_panel)
		codex_visible = false
		_hide_popup(codex_panel)
		achievements_visible = false
		_hide_popup(achievements_panel)
		history_visible = false
		_hide_popup(history_panel)
	_refresh_story()


func _move_story_selection(direction: int) -> void:
	if story_entries.is_empty():
		return
	for _step in range(story_entries.size()):
		story_selected = posmod(story_selected + direction, story_entries.size())
		if bool(story_entries[story_selected].get("unlocked", false)):
			break
	_refresh_story()


func _play_story_entry(index: int) -> void:
	if not story_visible or index < 0 or index >= story_entries.size():
		return
	var entry: Dictionary = story_entries[index]
	if not bool(entry.get("unlocked", false)):
		return
	story_requested.emit(str(entry.get("id", "")))


func _continue_from_title() -> void:
	if not title_visible or continue_button.disabled:
		return
	new_game_armed = false
	continue_requested.emit()


func show_achievement(achievement_name: String, description: String) -> void:
	achievement_queue.append({"name": Localization.text(achievement_name), "description": Localization.text(description)})
	if not achievement_toast.visible:
		_show_next_achievement()


func _show_next_achievement() -> void:
	if achievement_queue.is_empty():
		achievement_toast.visible = false
		return
	var entry: Dictionary = achievement_queue.pop_front()
	achievement_toast_label.text = "%s  ·  %s\n%s" % [Localization.text("ACHIEVEMENT RESTORED"), str(entry["name"]).to_upper(), entry["description"]]
	achievement_toast.modulate.a = 1.0
	achievement_toast.visible = true
	if achievement_toast_tween != null and achievement_toast_tween.is_valid():
		achievement_toast_tween.kill()
	achievement_toast_tween = create_tween()
	achievement_toast_tween.tween_interval(2.2)
	achievement_toast_tween.tween_property(achievement_toast, "modulate:a", 0.0, 0.35)
	achievement_toast_tween.tween_callback(func() -> void:
		achievement_toast.visible = false
		_show_next_achievement()
	)


func set_settings(data: Dictionary) -> void:
	settings_values = data.duplicate(true)
	_refresh_settings()


func refresh_localization() -> void:
	_apply_ui_theme()
	_refresh_manual()
	_refresh_settings()
	_refresh_bindings()
	set_input_mode(using_gamepad)
	set_shards(shard_amount)
	set_relics(current_relic_ids)
	if not objective_source.is_empty():
		set_objective(objective_source)
	if not build_source.is_empty():
		set_build(build_source)
	if directive_panel.visible and not directive_source.is_empty():
		set_page_directive(
			str(directive_source.get("title", "PAGE DIRECTIVE")),
			str(directive_source.get("kind", "kills")),
			float(directive_source.get("current", 0.0)),
			float(directive_source.get("target", 1.0)),
			str(directive_source.get("reward", "")),
			bool(directive_source.get("completed", false)),
			bool(directive_source.get("occupied", false))
		)
	if game_over_visible and not last_result_summary.is_empty():
		game_over_label.text = _run_result_text(last_result_summary)
	if upgrade_visible:
		_refresh_upgrade_buttons()
	if relic_draft_visible:
		_refresh_relic_draft_buttons()
	if event_visible and not current_event.is_empty():
		show_event(current_event)
	if title_visible and not title_data.is_empty():
		_refresh_title()


func show_settings() -> void:
	if _popup_transition_active(settings_panel):
		return
	settings_visible = true
	settings_selected = 0
	_refresh_settings()
	_show_popup(settings_panel)


func hide_settings() -> void:
	if not settings_visible or _popup_transition_active(settings_panel):
		return
	_hide_popup(settings_panel, _finish_hide_settings)


func _finish_hide_settings() -> void:
	settings_visible = false


func _adjust_setting(setting_id: String, direction: int) -> void:
	if setting_id == "controls":
		show_bindings()
		return
	setting_adjusted.emit(setting_id, direction)


func _refresh_settings() -> void:
	if settings_buttons.is_empty():
		return
	for index in range(SETTINGS_ROWS.size()):
		var setting_id: String = SETTINGS_ROWS[index][0]
		var label := Localization.text(SETTINGS_ROWS[index][1])
		var value_text := "—"
		match setting_id:
			"master", "music", "sfx":
				value_text = "%d%%" % int(round(float(settings_values.get(setting_id, 1.0)) * 100.0))
			"vibration", "hit_stop", "ink_art_cutins", "reduced_flashes", "analytics_consent":
				value_text = Localization.text("ON" if bool(settings_values.get(setting_id, true)) else "OFF")
			"aim_assist":
				var strength := float(settings_values.get(setting_id, 0.45))
				value_text = Localization.text("STANDARD" if strength > 0.35 else ("GENTLE" if strength > 0.1 else "OFF"))
			"screen_shake":
				var strength := float(settings_values.get(setting_id, 1.0))
				value_text = Localization.text("FULL" if strength > 0.75 else ("HALF" if strength > 0.1 else "OFF"))
			"fullscreen":
				value_text = Localization.text("FULLSCREEN" if bool(settings_values.get(setting_id, false)) else "WINDOWED")
			"language":
				value_text = Localization.language_display_name(str(settings_values.get(setting_id, Localization.LANGUAGE_AUTO)))
			"controls":
				value_text = Localization.text("OPEN")
		settings_buttons[index].text = "‹   %s     %s   ›" % [label, value_text] if TranslationServer.get_locale().begins_with("zh") else "‹   %-24s %12s   ›" % [label, value_text]
		settings_buttons[index].modulate = GOLD if index == settings_selected else Color.WHITE


func set_bindings(data: Dictionary) -> void:
	binding_values = data.duplicate(true)
	_refresh_bindings()


func show_bindings() -> void:
	settings_visible = false
	_hide_popup(settings_panel)
	bindings_visible = true
	binding_waiting = false
	binding_selected_row = 0
	binding_selected_device = 0
	binding_status_label.text = "A/ENTER REBIND  ·  Y RESET DEFAULTS  ·  B/ESC BACK"
	_refresh_bindings()
	_show_popup(bindings_panel)


func hide_bindings() -> void:
	if not bindings_visible or _popup_transition_active(bindings_panel):
		return
	_hide_popup(bindings_panel, _finish_hide_bindings)


func _finish_hide_bindings() -> void:
	bindings_visible = false
	binding_waiting = false
	waiting_action = ""
	waiting_device = ""
	settings_visible = true
	_refresh_settings()
	_show_popup(settings_panel)


func _begin_rebind(action_id: String, device_type: String) -> void:
	if not bindings_visible:
		return
	binding_waiting = true
	waiting_action = action_id
	waiting_device = device_type
	if TranslationServer.get_locale().begins_with("zh"):
		binding_status_label.text = "按下一个%s输入以绑定%s  ·  ESC 取消" % ["键盘/鼠标" if device_type == "keyboard" else "手柄", _action_display_name(action_id)]
	else:
		binding_status_label.text = "PRESS A %s INPUT FOR %s  ·  ESC CANCELS" % [device_type.to_upper(), _action_display_name(action_id)]


func _refresh_bindings() -> void:
	if binding_buttons.is_empty():
		return
	for row in range(REBIND_ACTIONS.size()):
		var action_id: String = REBIND_ACTIONS[row][0]
		var action_bindings: Dictionary = binding_values.get(action_id, {})
		for device_index in range(2):
			var device_type := "keyboard" if device_index == 0 else "gamepad"
			var button_index := row * 2 + device_index
			binding_buttons[button_index].text = _binding_display(action_bindings.get(device_type, {}))
			binding_buttons[button_index].modulate = GOLD if row == binding_selected_row and device_index == binding_selected_device else Color.WHITE


func _binding_display(binding: Dictionary) -> String:
	match str(binding.get("type", "")):
		"key":
			return OS.get_keycode_string(int(binding.get("physical_keycode", 0))).to_upper()
		"mouse":
			return ("鼠标 %d" if TranslationServer.get_locale().begins_with("zh") else "MOUSE %d") % int(binding.get("button_index", 1))
		"joy_button":
			return _joy_button_name(int(binding.get("button_index", -1)))
	return "未绑定" if TranslationServer.get_locale().begins_with("zh") else "UNBOUND"


func _joy_button_name(button: int) -> String:
	return Localization.text({
		JOY_BUTTON_A: "A / CROSS",
		JOY_BUTTON_B: "B / CIRCLE",
		JOY_BUTTON_X: "X / SQUARE",
		JOY_BUTTON_Y: "Y / TRIANGLE",
		JOY_BUTTON_BACK: "VIEW / BACK",
		JOY_BUTTON_START: "START / OPTIONS",
		JOY_BUTTON_LEFT_SHOULDER: "LEFT SHOULDER",
		JOY_BUTTON_RIGHT_SHOULDER: "RIGHT SHOULDER",
		JOY_BUTTON_DPAD_UP: "D-PAD UP",
		JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN",
		JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT",
		JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT",
	}.get(button, "BUTTON %d" % button))


func _action_display_name(action_id: String) -> String:
	for row in REBIND_ACTIONS:
		if row[0] == action_id:
			return Localization.text(row[1])
	return action_id.to_upper()


func _cycle_difficulty(direction: int) -> void:
	var unlocked: Array = title_data.get("unlocked_difficulties", ["story", "standard"])
	for _step in range(difficulty_ids.size()):
		difficulty_index = posmod(difficulty_index + direction, difficulty_ids.size())
		if difficulty_ids[difficulty_index] in unlocked:
			break
	_refresh_title()


func _cycle_contract(direction: int) -> void:
	var unlocked: Array = title_data.get("unlocked_contracts", ["open-draft"])
	for _step in range(Content.CONTRACTS.size()):
		contract_index = posmod(contract_index + direction, Content.CONTRACTS.size())
		if Content.CONTRACTS[contract_index]["id"] in unlocked:
			break
	_refresh_title()


func _start_from_title() -> void:
	if not title_visible:
		return
	if not title_data.get("checkpoint", {}).is_empty() and not new_game_armed:
		new_game_armed = true
		start_button.text = Localization.text("PRESS AGAIN\nERASE DRAFT")
		show_device_notice("NEW GAME WILL REPLACE THE SAVED DRAFT")
		return
	_show_loadout()


func _buy_meta_upgrade(upgrade_id: String) -> void:
	if title_visible:
		meta_upgrade_requested.emit(upgrade_id)


func _show_restoration() -> void:
	if not title_visible:
		return
	codex_visible = false
	_hide_popup(codex_panel)
	achievements_visible = false
	_hide_popup(achievements_panel)
	history_visible = false
	_hide_popup(history_panel)
	story_visible = false
	_hide_popup(story_panel)
	loadout_visible = false
	_hide_popup(loadout_panel)
	proof_visible = false
	_hide_popup(proof_panel)
	daily_visible = false
	_hide_popup(daily_panel)
	restoration_visible = true
	restoration_panel.move_to_front()
	restoration_selected = clampi(restoration_selected, 0, Content.META_RESTORATIONS.size() - 1)
	_refresh_restoration_board()
	_show_popup(restoration_panel)


func _show_proof_ledger() -> void:
	if not title_visible:
		return
	codex_visible = false
	_hide_popup(codex_panel)
	achievements_visible = false
	_hide_popup(achievements_panel)
	history_visible = false
	_hide_popup(history_panel)
	story_visible = false
	_hide_popup(story_panel)
	loadout_visible = false
	_hide_popup(loadout_panel)
	restoration_visible = false
	_hide_popup(restoration_panel)
	daily_visible = false
	_hide_popup(daily_panel)
	proof_visible = true
	proof_panel.move_to_front()
	proof_selected = proof_depth
	_refresh_proof_ledger()
	_show_popup(proof_panel)


func _hide_proof_ledger() -> void:
	if _popup_transition_active(proof_panel):
		return
	proof_visible = false
	_hide_popup(proof_panel)


func _select_proof(index: int) -> void:
	var maximum := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	if not proof_visible or index < 0 or index > maximum:
		return
	proof_selected = index
	_refresh_proof_ledger()


func _move_proof(delta: int) -> void:
	if not proof_visible:
		return
	var maximum := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	proof_selected = posmod(proof_selected + delta, maximum + 1)
	_refresh_proof_ledger()


func _jump_proof_columns(direction: int) -> void:
	if not proof_visible:
		return
	var maximum := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	proof_selected = clampi(proof_selected + direction * 6, 0, maximum)
	_refresh_proof_ledger()


func _commit_proof(index: int = -1) -> void:
	var maximum := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	var candidate := proof_selected if index < 0 else index
	if not proof_visible or candidate < 0 or candidate > maximum:
		return
	proof_depth = candidate
	proof_selected = candidate
	_hide_proof_ledger()
	_refresh_title()


func _refresh_proof_ledger() -> void:
	if proof_description_label == null or proof_buttons.size() != Content.PROOF_LEVELS.size():
		return
	var maximum := clampi(int(title_data.get("max_proof_depth", 0)), 0, Content.PROOF_LEVELS.size() - 1)
	var chinese := TranslationServer.get_locale().begins_with("zh")
	proof_selected = clampi(proof_selected, 0, maximum)
	var highest_cleared := clampi(int(title_data.get("highest_proof_cleared", -1)), -1, Content.PROOF_LEVELS.size() - 1)
	proof_title_label.text = ("校样账簿  ·  已通关 %d/10" if chinese else "THE PROOF LEDGER  ·  CLEARED %d/10") % maxi(0, highest_cleared)
	for index in range(Content.PROOF_LEVELS.size()):
		var definition: Dictionary = Localization.localized(Content.PROOF_LEVELS[index])
		var selected_prefix := "▶ " if index == proof_selected else "   "
		var active_suffix := (" · 当前" if chinese else " · ACTIVE") if index == proof_depth else ""
		proof_buttons[index].text = "%s%02d  %s%s" % [selected_prefix, index, definition["name"], active_suffix] if index <= maximum else (("   未解锁 %02d  ·  %s" if chinese else "   LOCKED %02d  ·  %s") % [index, definition["name"]])
		proof_buttons[index].disabled = index > maximum
		proof_buttons[index].add_theme_color_override("font_color", GOLD if index == proof_selected else PAPER)
		proof_buttons[index].add_theme_color_override("font_disabled_color", Color(0.46, 0.43, 0.40, 1.0))
	var selected_data: Dictionary = Localization.localized(Content.proof_level(proof_selected))
	var modifiers := Content.proof_modifiers(proof_selected)
	var unlock_hint := (("  ·  通关后解锁 %02d" if chinese else "  ·  CLEAR TO UNLOCK %02d") % (maximum + 1)) if proof_selected == maximum and maximum < Content.PROOF_LEVELS.size() - 1 else ""
	proof_description_label.text = ("%s  ·  %s\n奖励  ×%.2f 得分  ·  ×%.2f 记忆%s" if chinese else "%s  ·  %s\nREWARD  ×%.2f SCORE  ·  ×%.2f MEMORY%s") % [selected_data["name"], selected_data["description"], float(modifiers["score"]), float(modifiers["shards"]), unlock_hint]


func _hide_restoration() -> void:
	if _popup_transition_active(restoration_panel):
		return
	restoration_visible = false
	_hide_popup(restoration_panel)


func _select_restoration(index: int) -> void:
	if not restoration_visible or index < 0 or index >= Content.META_RESTORATIONS.size():
		return
	restoration_selected = index
	_refresh_restoration_board()


func _move_restoration(horizontal: int, vertical: int) -> void:
	if not restoration_visible:
		return
	var column := restoration_selected % 2
	var row := restoration_selected / 2
	column = posmod(column + horizontal, 2)
	row = posmod(row + vertical, 3)
	restoration_selected = row * 2 + column
	_refresh_restoration_board()


func _purchase_selected_restoration() -> void:
	if not restoration_visible or restoration_selected < 0 or restoration_selected >= Content.META_RESTORATIONS.size():
		return
	_buy_meta_upgrade(str(Content.META_RESTORATIONS[restoration_selected]["id"]))


func _refresh_restoration_board() -> void:
	if restoration_status_label == null or meta_upgrade_buttons.size() != Content.META_RESTORATIONS.size():
		return
	var memories := int(title_data.get("meta_shards", 0))
	var rank_data: Dictionary = title_data.get("archive_rank", {})
	var archive_rank := int(rank_data.get("rank", 1))
	var chinese := TranslationServer.get_locale().begins_with("zh")
	var ranks: Dictionary = title_data.get("meta_upgrades", {})
	var restored_ranks := 0
	for definition in Content.META_RESTORATIONS:
		restored_ranks += int(ranks.get(definition["id"], 0))
	restoration_status_label.text = ("档案等级 %02d  ·  记忆 %03d  ·  已修复 %d/30" if chinese else "ARCHIVE RANK %02d  ·  MEMORY %03d  ·  %d/30 RESTORED") % [archive_rank, memories, restored_ranks]
	for index in range(Content.META_RESTORATIONS.size()):
		var definition: Dictionary = Localization.localized(Content.META_RESTORATIONS[index])
		var upgrade_id := str(definition["id"])
		var rank := clampi(int(ranks.get(upgrade_id, 0)), 0, int(definition["max_rank"]))
		var required_rank := int(definition["required_rank"])
		var unlocked := archive_rank >= required_rank
		var mastered := rank >= int(definition["max_rank"])
		var cost := Content.meta_restoration_cost(upgrade_id, rank)
		var prefix := "▶ " if index == restoration_selected else "   "
		var button := meta_upgrade_buttons[index]
		if not unlocked:
			button.text = ("%s未解锁 · 档案等级 %d\n%s\n%s" if chinese else "%sLOCKED · ARCHIVE RANK %d\n%s\n%s") % [prefix, required_rank, definition["name"], definition["description"]]
		elif mastered:
			button.text = ("%s%s  5/5 · 已精通\n%s\n%s" if chinese else "%s%s  5/5 · MASTERED\n%s\n%s") % [prefix, definition["name"], definition["description"], definition["mastery"]]
		else:
			button.text = ("%s%s  %d/5 · 花费 %d\n%s\n%s" if chinese else "%s%s  %d/5 · COST %d\n%s\n%s") % [prefix, definition["name"], rank, cost, definition["description"], definition["mastery"]]
		button.disabled = not unlocked or mastered or memories < cost
		var selected_color := GOLD if index == restoration_selected else PAPER
		button.add_theme_color_override("font_color", selected_color)
		button.add_theme_color_override("font_hover_color", WHITE)
		button.add_theme_color_override("font_disabled_color", Color(0.72, 0.54, 0.28, 1.0) if index == restoration_selected else Color(0.46, 0.43, 0.40, 1.0))


func show_device_notice(message: String) -> void:
	if device_notice_tween != null and device_notice_tween.is_valid():
		device_notice_tween.kill()
	objective_label.visible = false
	device_notice.text = Localization.text(message)
	device_notice.modulate.a = 1.0
	device_notice.visible = true
	device_notice_tween = create_tween()
	device_notice_tween.tween_interval(0.85)
	device_notice_tween.tween_property(device_notice, "modulate:a", 0.0, 0.35)
	device_notice_tween.tween_callback(hide_device_notice)


func hide_device_notice() -> void:
	device_notice.visible = false
	objective_label.visible = true


func _handle_bindings_input(event: InputEvent) -> void:
	if binding_waiting:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				binding_waiting = false
				binding_status_label.text = "REBIND CANCELLED  ·  A/ENTER TO TRY AGAIN"
			elif waiting_device == "keyboard":
				_commit_binding({"type": "key", "physical_keycode": int(event.physical_keycode)})
		elif event is InputEventMouseButton and event.pressed and waiting_device == "keyboard":
			_commit_binding({"type": "mouse", "button_index": int(event.button_index)})
		elif event is InputEventJoypadButton and event.pressed and waiting_device == "gamepad":
			_commit_binding({"type": "joy_button", "button_index": int(event.button_index)})
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			hide_bindings()
			return
		if event.physical_keycode == KEY_BACKSPACE:
			bindings_reset_requested.emit()
			binding_status_label.text = "DEFAULT BINDINGS RESTORED"
			return
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_begin_selected_rebind()
			return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B:
			hide_bindings()
			return
		if event.button_index == JOY_BUTTON_Y:
			bindings_reset_requested.emit()
			binding_status_label.text = "DEFAULT BINDINGS RESTORED"
			return
	if event.is_action_pressed("move_up"):
		binding_selected_row = posmod(binding_selected_row - 1, REBIND_ACTIONS.size())
		_refresh_bindings()
	elif event.is_action_pressed("move_down"):
		binding_selected_row = posmod(binding_selected_row + 1, REBIND_ACTIONS.size())
		_refresh_bindings()
	elif event.is_action_pressed("move_left"):
		binding_selected_device = 0
		_refresh_bindings()
	elif event.is_action_pressed("move_right"):
		binding_selected_device = 1
		_refresh_bindings()
	elif event.is_action_pressed("attack") or event.is_action_pressed("dash"):
		_begin_selected_rebind()


func _begin_selected_rebind() -> void:
	_begin_rebind(REBIND_ACTIONS[binding_selected_row][0], "keyboard" if binding_selected_device == 0 else "gamepad")


func _commit_binding(binding: Dictionary) -> void:
	var action_id := waiting_action
	var device_type := waiting_device
	binding_waiting = false
	waiting_action = ""
	waiting_device = ""
	binding_changed.emit(action_id, device_type, binding)
	if TranslationServer.get_locale().begins_with("zh"):
		binding_status_label.text = "%s %s 已重新绑定  ·  更改已保存" % [_action_display_name(action_id), "键盘/鼠标" if device_type == "keyboard" else "手柄"]
	else:
		binding_status_label.text = "%s %s REBOUND  ·  CHANGE SAVED" % [_action_display_name(action_id), device_type.to_upper()]


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventKey and event.echo:
		return
	# Analogue triggers and sticks emit motion repeatedly while held. UI actions
	# are edge-triggered here and re-arm only after the physical control returns
	# to neutral, preventing story/pause panels and selections from oscillating.
	if _consume_repeated_gamepad_ui_event(event):
		return
	# Opening and closing animation frames are part of the modal. Swallow all
	# selection edges during them so button mashing cannot choose twice or leak
	# into gameplay when the closing callback resumes the tree.
	if (upgrade_visible and upgrade_transitioning) or not popup_transitions.is_empty():
		return
	if game_over_visible:
		if game_over_input_ready and event.is_action_pressed("restart"):
			_emit_input_ui_sound(event)
			_request_game_over_restart()
		return
	_emit_input_ui_sound(event)
	if quit_visible:
		if quit_waiting:
			return
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			_move_quit_navigation(-1)
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			_move_quit_navigation(1)
		elif _title_accept_pressed(event):
			_activate_quit_navigation()
		elif event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
			hide_quit_confirmation()
		return
	if victory_credits_visible:
		if _any_button_pressed(event):
			if victory_credits_final:
				hide_victory_credits(func() -> void: return_to_title_requested.emit())
			else:
				_skip_victory_credits_to_thanks()
		return
	if bindings_visible:
		_handle_bindings_input(event)
		return
	if manual_visible:
		if event.is_action_pressed("manual") or event.is_action_pressed("pause") or event.is_action_pressed("upgrade_3"):
			hide_manual()
		elif event.is_action_pressed("move_left") or event.is_action_pressed("move_up") or event.is_action_pressed("contract_prev"):
			_move_manual_page(-1)
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down") or event.is_action_pressed("contract_next") or event.is_action_pressed("attack") or event.is_action_pressed("dash"):
			_move_manual_page(1)
		return
	if settings_visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("options") or event.is_action_pressed("upgrade_3"):
			hide_settings()
		elif event.is_action_pressed("move_up"):
			settings_selected = posmod(settings_selected - 1, SETTINGS_ROWS.size())
			_refresh_settings()
		elif event.is_action_pressed("move_down"):
			settings_selected = posmod(settings_selected + 1, SETTINGS_ROWS.size())
			_refresh_settings()
		elif event.is_action_pressed("move_left"):
			_adjust_setting(SETTINGS_ROWS[settings_selected][0], -1)
		elif event.is_action_pressed("move_right") or event.is_action_pressed("attack") or event.is_action_pressed("dash"):
			_adjust_setting(SETTINGS_ROWS[settings_selected][0], 1)
		return
	if event.is_action_pressed("manual"):
		show_manual()
		return
	if title_visible:
		if daily_visible:
			if event.is_action_pressed("daily_chronicle") or event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
				_hide_daily()
			elif _title_accept_pressed(event):
				_begin_daily()
			return
		if proof_visible:
			if event.is_action_pressed("proof_ledger") or event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
				_hide_proof_ledger()
			elif event.is_action_pressed("move_up"):
				_move_proof(-1)
			elif event.is_action_pressed("move_down"):
				_move_proof(1)
			elif event.is_action_pressed("move_left"):
				_jump_proof_columns(-1)
			elif event.is_action_pressed("move_right"):
				_jump_proof_columns(1)
			elif _title_accept_pressed(event):
				_commit_proof()
			return
		if restoration_visible:
			if event.is_action_pressed("restoration") or event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
				_hide_restoration()
			elif event.is_action_pressed("move_up"):
				_move_restoration(0, -1)
			elif event.is_action_pressed("move_down"):
				_move_restoration(0, 1)
			elif event.is_action_pressed("move_left"):
				_move_restoration(-1, 0)
			elif event.is_action_pressed("move_right"):
				_move_restoration(1, 0)
			elif _title_accept_pressed(event):
				_purchase_selected_restoration()
			return
		if loadout_visible:
			if event is InputEventKey and event.pressed and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5:
				_choose_loadout(int(event.physical_keycode - KEY_1))
			elif event.is_action_pressed("move_up"):
				_move_loadout_selection(-1)
			elif event.is_action_pressed("move_down"):
				_move_loadout_selection(1)
			elif _title_accept_pressed(event):
				_choose_loadout(loadout_selected)
			elif event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
				_cancel_loadout()
			return
		if story_visible:
			if event.is_action_pressed("pause") or event.is_action_pressed("upgrade_4") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
				_toggle_story()
			elif event.is_action_pressed("move_up"):
				_move_story_selection(-1)
			elif event.is_action_pressed("move_down"):
				_move_story_selection(1)
			elif _title_accept_pressed(event):
				_play_story_entry(story_selected)
			return
		if codex_visible or achievements_visible or history_visible:
			if event.is_action_pressed("pause") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
				codex_visible = false
				_hide_popup(codex_panel)
				achievements_visible = false
				_hide_popup(achievements_panel)
				history_visible = false
				_hide_popup(history_panel)
				_refresh_title_navigation()
			return
		if event.is_action_pressed("move_up"):
			_move_title_navigation(Vector2.UP)
		elif event.is_action_pressed("move_down"):
			_move_title_navigation(Vector2.DOWN)
		elif event.is_action_pressed("move_left"):
			_move_title_navigation(Vector2.LEFT)
		elif event.is_action_pressed("move_right"):
			_move_title_navigation(Vector2.RIGHT)
		elif _title_accept_pressed(event):
			_activate_title_navigation()
		elif (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B) or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
			if new_game_armed:
				new_game_armed = false
				_refresh_title()
			else:
				show_quit_confirmation(false)
		elif event.is_action_pressed("daily_chronicle"):
			_show_daily()
		elif event.is_action_pressed("proof_ledger"):
			_show_proof_ledger()
		elif event.is_action_pressed("restoration"):
			_show_restoration()
		elif event.is_action_pressed("options"):
			show_settings()
		elif event.is_action_pressed("manual"):
			show_manual()
		elif event.is_action_pressed("upgrade_4"):
			_toggle_story()
		elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_C:
			_continue_from_title()
		elif event.is_action_pressed("contract_prev"):
			_cycle_contract(-1)
		elif event.is_action_pressed("contract_next"):
			_cycle_contract(1)
		elif event.is_action_pressed("pause"):
			if continue_button.disabled:
				_start_from_title()
			else:
				_continue_from_title()
		return
	if pause_panel.visible:
		if event.is_action_pressed("move_up"):
			_move_pause_navigation(-1)
		elif event.is_action_pressed("move_down"):
			_move_pause_navigation(1)
		elif _title_accept_pressed(event):
			_activate_pause_navigation()
		elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
			pause_requested.emit()
		elif event.is_action_pressed("options"):
			show_settings()
		elif event.is_action_pressed("upgrade_1"):
			save_return_requested.emit()
		elif event.is_action_pressed("pause"):
			pause_requested.emit()
		return
	if event_visible:
		if event.is_action_pressed("upgrade_1"):
			_choose_event(0)
		elif event.is_action_pressed("upgrade_2"):
			_choose_event(1)
		elif event.is_action_pressed("upgrade_3"):
			_choose_event(2)
		return
	if relic_draft_visible:
		if event.is_action_pressed("upgrade_1"):
			_choose_relic(0)
		elif event.is_action_pressed("upgrade_2"):
			_choose_relic(1)
		elif event.is_action_pressed("upgrade_3"):
			_choose_relic(2)
		return
	if upgrade_visible:
		if event.is_action_pressed("upgrade_1"):
			_choose_upgrade(0)
		elif event.is_action_pressed("upgrade_2"):
			_choose_upgrade(1)
		elif event.is_action_pressed("upgrade_3"):
			_choose_upgrade(2)
		elif event.is_action_pressed("upgrade_4"):
			_choose_upgrade(3)
		return
	if event.is_action_pressed("pause"):
		pause_requested.emit()
