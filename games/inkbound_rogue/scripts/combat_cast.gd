extends RefCounted
class_name InkboundCombatCast

## Shared 4x4 combat-cast atlas. Keeping every actor on one texture lets a
## crowded page retain authored silhouettes without multiplying GPU resources.

const ATLAS: Texture2D = preload("res://assets/characters/combat-cast-atlas-v1.png")
const CELL_SIZE := 313.5
const PLAYER_ATTACK_ATLAS: Texture2D = preload("res://assets/characters/nara-slash-atlas-v1.png")
const PLAYER_ATTACK_COLUMNS := 2
const PLAYER_ATTACK_ROWS := 2
const PLAYER_ATTACK_FRAME_COUNT := PLAYER_ATTACK_COLUMNS * PLAYER_ATTACK_ROWS
const PLAYER_ATTACK_CELL_SIZE := 627.0
## The slash figures are crouched and occupy roughly 420 px vertically versus
## the idle cell's 267 px. This scale keeps their on-screen body height within
## one to three pixels of idle while allowing the wider sword silhouettes.
const PLAYER_ATTACK_SCALE := Vector2(0.082, 0.082)

const CELLS := {
	"player": Vector2i(0, 0),
	"mask": Vector2i(1, 0),
	"dasher": Vector2i(2, 0),
	"brute": Vector2i(3, 0),
	"scribe": Vector2i(0, 1),
	"splitter": Vector2i(1, 1),
	"leech": Vector2i(2, 1),
	"warden": Vector2i(3, 1),
	"censor": Vector2i(0, 2),
	"errata": Vector2i(1, 2),
	"archivist": Vector2i(2, 2),
	"blot": Vector2i(3, 2),
	"duelist": Vector2i(0, 3),
	"editor": Vector2i(1, 3),
	"binder": Vector2i(2, 3),
	"author": Vector2i(3, 3),
}

const VISUAL_SCALES := {
	"player": 0.142,
	"mask": 0.118,
	"dasher": 0.122,
	"brute": 0.152,
	"scribe": 0.126,
	"splitter": 0.126,
	"leech": 0.122,
	"warden": 0.15,
	"censor": 0.145,
	"errata": 0.126,
	"archivist": 0.14,
	"blot": 0.142,
	"duelist": 0.132,
	"editor": 0.19,
	"binder": 0.205,
	"author": 0.225,
}


static func character_ids() -> Array[String]:
	var ids: Array[String] = []
	for character_id in CELLS:
		ids.append(str(character_id))
	ids.sort()
	return ids


static func texture_for(character_id: String) -> AtlasTexture:
	var cell: Vector2i = CELLS.get(character_id, CELLS["mask"])
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = Rect2(
		Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE),
		Vector2(CELL_SIZE, CELL_SIZE)
	)
	texture.filter_clip = true
	return texture


static func player_attack_texture(frame_index: int) -> AtlasTexture:
	var safe_index := clampi(frame_index, 0, PLAYER_ATTACK_FRAME_COUNT - 1)
	var column := safe_index % PLAYER_ATTACK_COLUMNS
	var row := int(safe_index / PLAYER_ATTACK_COLUMNS)
	var texture := AtlasTexture.new()
	texture.atlas = PLAYER_ATTACK_ATLAS
	texture.region = Rect2(
		Vector2(float(column) * PLAYER_ATTACK_CELL_SIZE, float(row) * PLAYER_ATTACK_CELL_SIZE),
		Vector2(PLAYER_ATTACK_CELL_SIZE, PLAYER_ATTACK_CELL_SIZE)
	)
	texture.filter_clip = true
	return texture


static func scale_for(character_id: String) -> Vector2:
	var amount := float(VISUAL_SCALES.get(character_id, VISUAL_SCALES["mask"]))
	return Vector2(amount, amount)


static func shadow_radii(character_id: String) -> Vector2:
	if character_id in ["editor", "binder", "author"]:
		return Vector2(24.0, 8.0)
	if character_id in ["brute", "warden", "censor", "blot"]:
		return Vector2(17.0, 6.0)
	return Vector2(13.0, 4.5)


static func ellipse_points(radii: Vector2, point_count: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(8, point_count)):
		var angle := TAU * float(index) / float(maxi(8, point_count))
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
