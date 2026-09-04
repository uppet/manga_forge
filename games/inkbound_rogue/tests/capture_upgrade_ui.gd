extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const HUD = preload("res://scripts/hud.gd")

var frames := 0
var hud: InkboundHUD
var upgrade_page := 0
var validating_all := true
var validating_gamepad := false

const PAGE_SIZE := 4
const EXPECTED_MIN_VERTICAL_GAP := 10.0
const EXPECTED_MIN_HORIZONTAL_GAP := 8.0


func _initialize() -> void:
	# The production game installs these actions before constructing the HUD.
	# This standalone renderer keeps the same contract so host mouse/gamepad
	# events cannot produce missing-action errors during the full 36-item pass.
	for action in ["pause", "options", "manual", "upgrade_1", "upgrade_2", "upgrade_3", "upgrade_4", "move_up", "move_down", "move_left", "move_right", "attack", "dash", "special"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var background := ColorRect.new()
	background.size = Vector2(480, 270)
	background.color = Color("08070b")
	root.add_child(background)
	hud = HUD.new()
	root.add_child(hud)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		hud.set_input_mode(false)
		hud.show_upgrade(_choices_for_upgrade_page(upgrade_page))
		hud.debug_finish_upgrade_transition()
	elif validating_all and frames % 2 == 0:
		if not _validate_card_regions():
			quit(1)
			return true
		upgrade_page += 1
		if upgrade_page * PAGE_SIZE < Content.UPGRADES.size():
			hud.show_upgrade(_choices_for_upgrade_page(upgrade_page))
			hud.debug_finish_upgrade_transition()
		elif not validating_gamepad:
			# Re-run every production description with the wider gamepad glyphs;
			# this is where the old absolute layout had the least horizontal room.
			validating_gamepad = true
			upgrade_page = 0
			hud.set_input_mode(true)
			hud.show_upgrade(_choices_for_upgrade_page(upgrade_page))
			hud.debug_finish_upgrade_transition()
		else:
			validating_all = false
			hud.show_upgrade([
				_discipline_preview("razor-ink", "ink-edge", 2, 3, true, true),
				_discipline_preview("ember-margin", "red-logic", 5, 6, true, false),
				_discipline_preview("afterimage-cut", "ghost-draft", 3, 6, false, true),
				_discipline_preview("merciful-revision", "bound-page", 4, 6, false, false),
			])
			hud.debug_finish_upgrade_transition()
	elif not validating_all and frames % 2 == 0:
		if not _validate_card_regions():
			quit(1)
			return true
		var output_dir := ProjectSettings.globalize_path("res://build/captures")
		DirAccess.make_dir_recursive_absolute(output_dir)
		var image := root.get_texture().get_image()
		if image == null:
			push_error("INKBOUND_UPGRADE_UI_FAIL: viewport texture unavailable")
			quit(1)
			return true
		var output_path := output_dir.path_join("last-inkwarden-upgrade-gamepad.png")
		var result := image.save_png(output_path)
		if result != OK:
			push_error("INKBOUND_UPGRADE_UI_FAIL: save_png error %d" % result)
			quit(1)
			return true
		print("INKBOUND_UPGRADE_UI_OK layout=2x2 upgrades=%d modes=keyboard+gamepad gaps=11px adaptive=6px-min translucent=0.90 content=contained autowrap=smart size=%dx%d" % [Content.UPGRADES.size(), image.get_width(), image.get_height()])
		quit(0)
		return true
	return false


func _choices_for_upgrade_page(page: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var first := page * PAGE_SIZE
	for index in range(first, mini(first + PAGE_SIZE, Content.UPGRADES.size())):
		choices.append(Content.UPGRADES[index])
	return choices


func _discipline_preview(upgrade_id: String, discipline_id: String, score: int, threshold: int, awakens: bool, resonant: bool) -> Dictionary:
	var choice := Content.upgrade(upgrade_id)
	choice["_discipline_id"] = discipline_id
	choice["_discipline_score"] = score
	choice["_next_threshold"] = threshold
	choice["_awakens"] = awakens
	choice["_resonant"] = resonant
	choice["_draft_discipline_id"] = "ink-edge"
	choice["_draft_score"] = 2
	choice["_draft_tier"] = 0
	choice["_draft_next_threshold"] = 3
	return choice


func _validate_card_regions() -> bool:
	if hud.upgrade_buttons.size() != 4:
		push_error("INKBOUND_UPGRADE_UI_FAIL: expected four cards")
		return false
	for index in range(hud.current_choices.size()):
		var button := hud.upgrade_buttons[index]
		var input_label := hud.upgrade_input_labels[index]
		var name_label := hud.upgrade_name_labels[index]
		var description_label := hud.upgrade_description_labels[index]
		var rarity_label := hud.upgrade_rarity_labels[index]
		if input_label.position.x + input_label.size.x + EXPECTED_MIN_HORIZONTAL_GAP > name_label.position.x:
			push_error("INKBOUND_UPGRADE_UI_FAIL: input prompt overlaps name on card %d" % index)
			return false
		if input_label.position.y + input_label.size.y + EXPECTED_MIN_VERTICAL_GAP > description_label.position.y or name_label.position.y + name_label.size.y + EXPECTED_MIN_VERTICAL_GAP > description_label.position.y:
			push_error("INKBOUND_UPGRADE_UI_FAIL: name overlaps description on card %d" % index)
			return false
		if description_label.position.y + description_label.size.y + EXPECTED_MIN_VERTICAL_GAP > rarity_label.position.y:
			push_error("INKBOUND_UPGRADE_UI_FAIL: description overlaps rarity on card %d" % index)
			return false
		if rarity_label.position.y + rarity_label.size.y > button.size.y:
			push_error("INKBOUND_UPGRADE_UI_FAIL: rarity leaves card bounds on card %d (y=%.1f h=%.1f card=%.1f)" % [index, rarity_label.position.y, rarity_label.size.y, button.size.y])
			return false
		if description_label.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
			push_error("INKBOUND_UPGRADE_UI_FAIL: smart wrapping disabled on card %d" % index)
			return false
		if not button.clip_contents or not description_label.clip_contents:
			push_error("INKBOUND_UPGRADE_UI_FAIL: card copy is not clipped on card %d" % index)
			return false
		if description_label.get_content_height() > description_label.size.y:
			push_error("INKBOUND_UPGRADE_UI_FAIL: rendered description escapes card %d (content=%.1f region=%.1f)" % [index, description_label.get_content_height(), description_label.size.y])
			return false
		if input_label.get_content_width() > input_label.size.x or name_label.get_content_width() > name_label.size.x or name_label.get_content_height() > name_label.size.y or rarity_label.get_content_width() > rarity_label.size.x or rarity_label.get_content_height() > rarity_label.size.y:
			push_error("INKBOUND_UPGRADE_UI_FAIL: rendered heading or rarity escapes card %d" % index)
			return false
	if hud.upgrade_panel.color.a < 0.88 or hud.upgrade_panel.color.a > 0.92:
		push_error("INKBOUND_UPGRADE_UI_FAIL: upgrade modal left its controlled translucent range")
		return false
	return true
