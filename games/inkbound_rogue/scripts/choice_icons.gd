extends RefCounted
class_name InkboundChoiceIcons

const UPGRADE_ATLAS := preload("res://assets/ui/choice_icons/upgrade-icons-v1.png")
const RELIC_ATLAS := preload("res://assets/ui/choice_icons/relic-icons-v1.png")

const UPGRADE_COLUMNS := 4
const UPGRADE_ROWS := 4
const RELIC_COLUMNS := 3
const RELIC_ROWS := 4

# Explicit IDs keep art direction stable even when gameplay tags are rebalanced.
# The cells follow the documented left-to-right, top-to-bottom atlas order.
const UPGRADE_CELLS := {
	"razor-ink": 0,
	"wide-panel": 1,
	"rapid-stroke": 2,
	"red-thread": 3,
	"ghost-step": 4,
	"iron-gutter": 5,
	"overflow": 1,
	"paper-armor": 5,
	"margin-magnet": 13,
	"scholar-luck": 15,
	"living-footnote": 7,
	"blood-annotation": 7,
	"ink-wave": 8,
	"returning-stroke": 8,
	"splinter-script": 8,
	"bleeding-letters": 9,
	"ember-margin": 9,
	"cold-reading": 9,
	"execution-clause": 0,
	"critical-echo": 3,
	"dash-nova": 4,
	"afterimage-cut": 4,
	"perfect-margin": 10,
	"crescendo": 10,
	"greatbrush": 11,
	"needlepoint": 11,
	"seal-caster": 11,
	"twin-stroke": 11,
	"last-word": 5,
	"open-book": 6,
	"living-ink": 12,
	"quickscript": 14,
	"violent-margin": 12,
	"red-harvest": 12,
	"echoed-panel": 12,
	"merciful-revision": 7,
}

const RELIC_CELLS := {
	"broken-mask": 0,
	"iori-ribbon": 1,
	"red-pencil": 2,
	"library-card": 3,
	"glass-nib": 4,
	"binder-chain": 5,
	"black-tea": 6,
	"wax-seal": 7,
	"misprint": 8,
	"paper-heart": 9,
	"empty-frame": 10,
	"first-draft": 11,
}


static func upgrade_icon(upgrade_id: String) -> AtlasTexture:
	return _cell_texture(UPGRADE_ATLAS, int(UPGRADE_CELLS.get(upgrade_id, 0)), UPGRADE_COLUMNS, UPGRADE_ROWS)


static func relic_icon(relic_id: String) -> AtlasTexture:
	return _cell_texture(RELIC_ATLAS, int(RELIC_CELLS.get(relic_id, 0)), RELIC_COLUMNS, RELIC_ROWS)


static func _cell_texture(atlas: Texture2D, cell_index: int, columns: int, rows: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	var cell_size := Vector2(float(atlas.get_width()) / float(columns), float(atlas.get_height()) / float(rows))
	var column := cell_index % columns
	var row := cell_index / columns
	texture.region = Rect2(Vector2(float(column), float(row)) * cell_size, cell_size)
	texture.filter_clip = true
	return texture
