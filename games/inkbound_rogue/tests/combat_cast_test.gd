extends SceneTree

const CombatCast = preload("res://scripts/combat_cast.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

const EXPECTED_CELLS := {
	"player": Vector2i(0, 0), "mask": Vector2i(1, 0), "dasher": Vector2i(2, 0), "brute": Vector2i(3, 0),
	"scribe": Vector2i(0, 1), "splitter": Vector2i(1, 1), "leech": Vector2i(2, 1), "warden": Vector2i(3, 1),
	"censor": Vector2i(0, 2), "errata": Vector2i(1, 2), "archivist": Vector2i(2, 2), "blot": Vector2i(3, 2),
	"duelist": Vector2i(0, 3), "editor": Vector2i(1, 3), "binder": Vector2i(2, 3), "author": Vector2i(3, 3),
}

var player
var enemies: Array = []
var frames := 0


func _initialize() -> void:
	player = PlayerScript.new()
	player.controls_enabled = false
	root.add_child(player)
	player.set_physics_process(false)
	for character_id in EXPECTED_CELLS:
		if character_id == "player":
			continue
		var enemy = EnemyScript.new().configure(character_id, player, 1)
		root.add_child(enemy)
		enemy.set_physics_process(false)
		enemies.append(enemy)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if not _validate_atlas() or not _validate_runtime_nodes():
		return true
	print("INKBOUND_CAST_OK atlas=1254x1254 cells=16 alpha=transparent player=authored slash_frames=4 enemies=12 bosses=3 shadows=grounded poses=keyframed shared_texture=ok")
	_cleanup(0)
	return true


func _validate_atlas() -> bool:
	if CombatCast.ATLAS.get_width() != 1254 or CombatCast.ATLAS.get_height() != 1254:
		return _fail("combat atlas dimensions changed")
	var image := CombatCast.ATLAS.get_image()
	if image == null or image.get_pixel(0, 0).a > 0.01:
		return _fail("combat atlas lost its transparent background")
	if CombatCast.character_ids().size() != 16:
		return _fail("combat atlas does not expose exactly sixteen cast members")
	if CombatCast.PLAYER_ATTACK_ATLAS.get_width() != 1254 or CombatCast.PLAYER_ATTACK_ATLAS.get_height() != 1254:
		return _fail("Nara attack atlas dimensions changed")
	var attack_image := CombatCast.PLAYER_ATTACK_ATLAS.get_image()
	if attack_image == null or attack_image.get_pixel(0, 0).a > 0.01:
		return _fail("Nara attack atlas lost its transparent background")
	var attack_regions: Array[Rect2] = []
	for frame_index in range(CombatCast.PLAYER_ATTACK_FRAME_COUNT):
		var attack_texture := CombatCast.player_attack_texture(frame_index)
		if attack_texture.atlas != CombatCast.PLAYER_ATTACK_ATLAS or not attack_texture.filter_clip:
			return _fail("attack frame %d does not use the clipped keyframe atlas" % frame_index)
		if attack_texture.region.size != Vector2(627.0, 627.0):
			return _fail("attack frame %d uses the wrong cell size" % frame_index)
		if attack_texture.region in attack_regions:
			return _fail("two attack keyframes share one atlas region")
		attack_regions.append(attack_texture.region)
	var used_regions: Array[Rect2] = []
	for character_id in EXPECTED_CELLS:
		if not CombatCast.CELLS.has(character_id) or CombatCast.CELLS[character_id] != EXPECTED_CELLS[character_id]:
			return _fail("atlas cell mapping drifted for %s" % character_id)
		var texture := CombatCast.texture_for(character_id)
		if texture.atlas != CombatCast.ATLAS or not texture.filter_clip:
			return _fail("%s does not use the clipped shared atlas" % character_id)
		if texture.region.position.x < 0.0 or texture.region.position.y < 0.0 or texture.region.end.x > 1254.01 or texture.region.end.y > 1254.01:
			return _fail("%s atlas region leaves texture bounds" % character_id)
		for used_region in used_regions:
			if texture.region.intersects(used_region):
				return _fail("two cast members share an overlapping atlas region")
		used_regions.append(texture.region)
	return true


func _validate_runtime_nodes() -> bool:
	if not (player.sprite.texture is AtlasTexture) or player.ground_shadow_points.size() < 16 or player.visual_base_scale.x <= 0.1:
		return _fail("player did not adopt the authored cast sprite and ground shadow")
	if player.attack_textures.size() != 4:
		return _fail("player did not cache all four slash keyframes")
	player.weapon_form = "MARGINALIA"
	player._start_attack_animation(player._attack_animation_duration())
	var seen_attack_regions: Array[Rect2] = []
	for remaining_ratio in [1.0, 0.7, 0.45, 0.1]:
		player.attack_pose_time = player.attack_pose_duration * remaining_ratio
		player._update_visual(0.016)
		if not (player.sprite.texture is AtlasTexture) or player.attack_frame_index < 0:
			return _fail("player slash animation returned to idle before recovery")
		var current_region: Rect2 = player.sprite.texture.region
		if current_region not in seen_attack_regions:
			seen_attack_regions.append(current_region)
	if seen_attack_regions.size() != 4:
		return _fail("player slash animation does not visit four distinct texture frames")
	player.attack_pose_time = 0.0
	player._update_visual(0.016)
	if player.sprite.texture != player.idle_texture or player.attack_frame_index != -1:
		return _fail("player slash recovery did not restore the idle silhouette")
	var seen_regions: Array[Rect2] = []
	for enemy in enemies:
		if not (enemy.sprite.texture is AtlasTexture) or enemy.ground_shadow_points.size() < 16:
			return _fail("%s did not adopt its authored sprite and shadow" % enemy.enemy_kind)
		var expected_region := CombatCast.texture_for(enemy.enemy_kind).region
		if enemy.sprite.texture.region != expected_region:
			return _fail("%s uses the wrong atlas cell" % enemy.enemy_kind)
		if expected_region in seen_regions:
			return _fail("enemy silhouettes are not unique")
		seen_regions.append(expected_region)
		enemy._update_visual(0.016, Vector2.RIGHT)
		if enemy.sprite.scale.x <= 0.1 or enemy.ground_shadow_scale.x <= 0.0:
			return _fail("%s visual pose collapsed" % enemy.enemy_kind)
	if CombatCast.scale_for("author").x <= CombatCast.scale_for("mask").x * 1.7:
		return _fail("boss hierarchy is not visually distinct")
	return true


func _fail(message: String) -> bool:
	push_error("INKBOUND_CAST_FAIL: %s" % message)
	_cleanup(1)
	return false


func _cleanup(exit_code: int) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.free()
	if is_instance_valid(player):
		player.free()
	quit(exit_code)
