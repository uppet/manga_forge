extends CanvasLayer
class_name InkboundInkArtCinematic

const Localization = preload("res://scripts/localization.gd")

signal release_requested(form: String, frame_index: int)
signal sequence_finished(form: String)

const FRAME_SIZE := Vector2(216.0, 360.0)
const VOICE_BASE_VOLUME_DB := 2.0
const SPECIALIZED_VOICE_PROBABILITY := 0.1
const COMMON_VOICE := preload("res://assets/audio/voice/nara_ink_art_kiai_jp.wav")
const VOICES := {
	"MARGINALIA": preload("res://assets/audio/voice/nara_ink_art_marginalia_jp.wav"),
	"GREATBRUSH": preload("res://assets/audio/voice/nara_ink_art_greatbrush_jp.wav"),
	"NEEDLEPOINT": preload("res://assets/audio/voice/nara_ink_art_needlepoint_jp.wav"),
	"SEAL-CASTER": preload("res://assets/audio/voice/nara_ink_art_seal_caster_jp.wav"),
	"TWIN-STROKE": preload("res://assets/audio/voice/nara_ink_art_twin_stroke_jp.wav"),
}
const FORM_DATA := {
	"MARGINALIA": {
		"cutin": preload("res://assets/ink_art/marginalia-cutin.png"),
		"startup": preload("res://assets/ink_art/marginalia-startup.png"),
		"cutin_duration": 1.015,
		"frame_durations": [0.0375, 0.0425, 0.05, 0.06, 0.07],
		"release_frame": 3,
		"pose_scale": 0.125,
		"accent": Color("d33037"),
	},
	"GREATBRUSH": {
		"cutin": preload("res://assets/ink_art/greatbrush-cutin.png"),
		"startup": preload("res://assets/ink_art/greatbrush-startup.png"),
		"cutin_duration": 1.14,
		"frame_durations": [0.055, 0.065, 0.08, 0.09, 0.11],
		"release_frame": 4,
		"pose_scale": 0.14,
		"accent": Color("f2b344"),
	},
	"NEEDLEPOINT": {
		"cutin": preload("res://assets/ink_art/needlepoint-cutin.png"),
		"startup": preload("res://assets/ink_art/needlepoint-startup.png"),
		"cutin_duration": 1.1125,
		"frame_durations": [0.0225, 0.025, 0.03, 0.0375, 0.05],
		"release_frame": 2,
		"pose_scale": 0.17,
		"accent": Color("d33037"),
	},
	"SEAL-CASTER": {
		"cutin": preload("res://assets/ink_art/seal-caster-cutin.png"),
		"startup": preload("res://assets/ink_art/seal-caster-startup.png"),
		"cutin_duration": 1.105,
		"frame_durations": [0.04, 0.05, 0.065, 0.115, 0.07],
		"release_frame": 3,
		"pose_scale": 0.155,
		"accent": Color("96aab0"),
	},
	"TWIN-STROKE": {
		"cutin": preload("res://assets/ink_art/twin-stroke-cutin.png"),
		"startup": preload("res://assets/ink_art/twin-stroke-startup.png"),
		"cutin_duration": 1.195,
		"frame_durations": [0.035, 0.045, 0.06, 0.07, 0.065],
		"release_frame": 3,
		"pose_scale": 0.155,
		"accent": Color("fff8e0"),
	},
}

var active := false
var phase := ""
var phase_elapsed := 0.0
var current_form := "MARGINALIA"
var current_direction := Vector2.RIGHT
var current_frame := -1
var frame_elapsed := 0.0
var released := false
var reduced_flashes := false
var frame_history: Array[int] = []
var last_completed_form := ""
var last_sequence_frame_count := 0
var last_voice_form := ""
var last_voice_variant := ""
var debug_voice_roll_override := -1.0
var player: Node
var voice_rng := RandomNumberGenerator.new()

var cutin_root: ColorRect
var cutin_art: TextureRect
var cutin_title: Label
var cutin_rule: ColorRect
var release_flash: ColorRect
var voice_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_build_overlay()
	voice_player = AudioStreamPlayer.new()
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(voice_player)
	voice_rng.randomize()


func _build_overlay() -> void:
	cutin_root = ColorRect.new()
	cutin_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutin_root.color = Color("08070b")
	cutin_root.mouse_filter = Control.MOUSE_FILTER_STOP
	cutin_root.visible = false
	add_child(cutin_root)

	cutin_art = TextureRect.new()
	cutin_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutin_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cutin_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cutin_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cutin_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(cutin_art)

	var lower_shade := ColorRect.new()
	lower_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lower_shade.offset_top = -54.0
	lower_shade.offset_bottom = 0.0
	lower_shade.color = Color(0.02, 0.012, 0.018, 0.76)
	lower_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(lower_shade)

	cutin_rule = ColorRect.new()
	cutin_rule.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cutin_rule.offset_top = -55.0
	cutin_rule.offset_bottom = -52.0
	cutin_rule.color = Color("d33037")
	cutin_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(cutin_rule)

	cutin_title = Label.new()
	cutin_title.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cutin_title.offset_left = 20.0
	cutin_title.offset_top = -50.0
	cutin_title.offset_right = -20.0
	cutin_title.offset_bottom = -8.0
	cutin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cutin_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cutin_title.add_theme_font_size_override("font_size", 18)
	cutin_title.add_theme_color_override("font_color", Color("fff8e0"))
	cutin_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(cutin_title)

	release_flash = ColorRect.new()
	release_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	release_flash.color = Color("fff8e0")
	release_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	release_flash.visible = false
	add_child(release_flash)


func play(form: String, player_node: Node, direction: Vector2, show_cutin: bool, reduce_flashes: bool, voice_volume_linear: float = 0.85) -> bool:
	if active or not is_instance_valid(player_node):
		return false
	current_form = form if FORM_DATA.has(form) else "MARGINALIA"
	current_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	player = player_node
	active = true
	released = false
	reduced_flashes = reduce_flashes
	current_frame = -1
	frame_elapsed = 0.0
	frame_history.clear()
	last_sequence_frame_count = 0
	release_flash.visible = false
	_play_voice(current_form, voice_volume_linear)
	if show_cutin:
		_begin_cutin()
	else:
		_begin_startup()
	return true


func cancel() -> void:
	if is_instance_valid(player) and player.has_method("end_ink_art_cinematic_pose"):
		player.end_ink_art_cinematic_pose()
	active = false
	phase = ""
	cutin_root.visible = false
	release_flash.visible = false
	if is_instance_valid(voice_player):
		voice_player.stop()
	player = null


func _begin_cutin() -> void:
	var data: Dictionary = FORM_DATA[current_form]
	phase = "cutin"
	phase_elapsed = 0.0
	cutin_art.texture = data["cutin"]
	cutin_art.modulate = Color.WHITE
	cutin_art.scale = Vector2(1.035, 1.035)
	cutin_title.text = "%s  ·  %s" % [Localization.text("INK ART"), Localization.text(_art_name(current_form))]
	cutin_rule.color = data["accent"]
	cutin_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cutin_root.visible = true
	_flash(0.48)


func _begin_startup() -> void:
	phase = "startup"
	phase_elapsed = 0.0
	frame_elapsed = 0.0
	cutin_root.visible = false
	if is_instance_valid(player) and player.has_method("begin_ink_art_cinematic_pose"):
		player.begin_ink_art_cinematic_pose(current_direction)
	_set_startup_frame(0)


func _process(delta: float) -> void:
	_update_flash(delta)
	if not active:
		return
	if not is_instance_valid(player):
		cancel()
		return
	if phase == "cutin":
		_update_cutin(delta)
	elif phase == "startup":
		_update_startup(delta)


func _update_cutin(delta: float) -> void:
	phase_elapsed += maxf(0.0, delta)
	var duration := float(FORM_DATA[current_form]["cutin_duration"])
	var fade_in := clampf(phase_elapsed / 0.09, 0.0, 1.0)
	var fade_out := clampf((duration - phase_elapsed) / 0.1, 0.0, 1.0)
	cutin_root.modulate.a = minf(fade_in, fade_out)
	cutin_art.pivot_offset = cutin_art.size * 0.5
	var settle := clampf(phase_elapsed / maxf(0.01, duration), 0.0, 1.0)
	cutin_art.scale = Vector2.ONE * lerpf(1.035, 1.0, settle)
	if phase_elapsed >= duration:
		_flash(0.7)
		_begin_startup()


func _update_startup(delta: float) -> void:
	frame_elapsed += maxf(0.0, delta)
	var durations: Array = FORM_DATA[current_form]["frame_durations"]
	while active and current_frame >= 0 and current_frame < durations.size() and frame_elapsed >= float(durations[current_frame]):
		frame_elapsed -= float(durations[current_frame])
		var next_frame := current_frame + 1
		if next_frame >= durations.size():
			_finish_sequence()
			return
		_set_startup_frame(next_frame)


func _set_startup_frame(frame_index: int) -> void:
	current_frame = clampi(frame_index, 0, 4)
	frame_history.append(current_frame)
	var data: Dictionary = FORM_DATA[current_form]
	var texture := AtlasTexture.new()
	texture.atlas = data["startup"]
	texture.region = Rect2(Vector2(FRAME_SIZE.x * current_frame, 0.0), FRAME_SIZE)
	texture.filter_clip = true
	if is_instance_valid(player) and player.has_method("set_ink_art_cinematic_frame"):
		player.set_ink_art_cinematic_frame(texture, float(data["pose_scale"]), Vector2(0.0, -12.0), current_direction)
	if not released and current_frame == int(data["release_frame"]):
		released = true
		_flash(0.82 if current_form in ["GREATBRUSH", "TWIN-STROKE"] else 0.6)
		release_requested.emit(current_form, current_frame)


func _finish_sequence() -> void:
	if not active:
		return
	if not released:
		released = true
		release_requested.emit(current_form, current_frame)
	if is_instance_valid(player) and player.has_method("end_ink_art_cinematic_pose"):
		player.end_ink_art_cinematic_pose()
	last_completed_form = current_form
	last_sequence_frame_count = frame_history.size()
	active = false
	phase = ""
	cutin_root.visible = false
	# The common kiai resolves inside the cut-in. Rare specialized lines are
	# intentionally allowed to finish over resumed combat instead of extending
	# the time stop or being cut off at the end of the five-frame startup.
	player = null
	sequence_finished.emit(current_form)


func _play_voice(form: String, volume_linear: float) -> void:
	if not is_instance_valid(voice_player) or not VOICES.has(form):
		return
	var roll := debug_voice_roll_override if debug_voice_roll_override >= 0.0 else voice_rng.randf()
	var specialized := roll < SPECIALIZED_VOICE_PROBABILITY
	voice_player.stop()
	voice_player.stream = VOICES[form] if specialized else COMMON_VOICE
	voice_player.volume_db = VOICE_BASE_VOLUME_DB + linear_to_db(maxf(0.001, volume_linear))
	last_voice_form = form
	last_voice_variant = "specialized" if specialized else "common"
	voice_player.play()


func debug_set_voice_roll(roll: float) -> void:
	debug_voice_roll_override = roll


func _flash(strength: float) -> void:
	if reduced_flashes:
		strength *= 0.24
	var accent: Color = FORM_DATA[current_form]["accent"]
	release_flash.color = accent
	release_flash.modulate.a = clampf(strength, 0.0, 0.9)
	release_flash.visible = release_flash.modulate.a > 0.001


func _update_flash(delta: float) -> void:
	if not release_flash.visible:
		return
	release_flash.modulate.a = maxf(0.0, release_flash.modulate.a - delta * (12.0 if reduced_flashes else 7.5))
	if release_flash.modulate.a <= 0.001:
		release_flash.visible = false


func _art_name(form: String) -> String:
	return {
		"GREATBRUSH": "FINAL PERIOD",
		"NEEDLEPOINT": "RED LINE",
		"SEAL-CASTER": "SEAL STORM",
		"TWIN-STROKE": "CROSS REVISION",
	}.get(form, "PALIMPSEST RING")


func debug_advance_to_startup() -> void:
	if active and phase == "cutin":
		_update_cutin(float(FORM_DATA[current_form]["cutin_duration"]) + 0.01)


func debug_advance_to_release() -> void:
	debug_advance_to_startup()
	var guard := 0
	while active and not released and guard < 8:
		guard += 1
		var durations: Array = FORM_DATA[current_form]["frame_durations"]
		_update_startup(float(durations[current_frame]) + 0.001)


func debug_finish_sequence() -> void:
	var guard := 0
	while active and guard < 12:
		guard += 1
		if phase == "cutin":
			debug_advance_to_startup()
		elif phase == "startup":
			var durations: Array = FORM_DATA[current_form]["frame_durations"]
			_update_startup(float(durations[current_frame]) + 0.001)
