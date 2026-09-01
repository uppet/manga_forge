extends RefCounted
class_name InkboundContent

const STORY := {
	"prologue": {
		"chapter": "PROLOGUE",
		"title": "THE BLANK PAGE",
		"image": "res://assets/cutscenes/prologue.png",
		"panels": [
			{"speaker": "IORI", "text": "Nara... if they take my name, keep the shape of it.", "focus": Vector2(0.72, 0.32), "motion": "pull", "inset": "right", "tone": "cold"},
			{"speaker": "NARA", "text": "I woke beneath the Grand Archive with a blade in my hand and my sister's voice trapped inside it.", "focus": Vector2(0.28, 0.58), "motion": "push", "inset": "left", "tone": "paper"},
			{"speaker": "MORROW, THE MARGINALIA", "text": "The Editors have cut every forbidden memory from the city. Their scraps learned to wear masks.", "focus": Vector2(0.70, 0.42), "motion": "drift_left", "inset": "right", "tone": "gold"},
			{"speaker": "NARA", "text": "Then I will cut a road through the redactions. No page stays blank while I still remember.", "focus": Vector2(0.30, 0.62), "motion": "drift_right", "inset": "left", "tone": "crimson"},
		],
	},
	"act1_reveal": {
		"chapter": "ACT I COMPLETE",
		"title": "WHAT THE MASK HID",
		"image": "res://assets/cutscenes/act1-mask-memory-v2.png",
		"panels": [
			{"speaker": "THE RED EDITOR", "text": "You call them monsters because we spared you their faces.", "focus": Vector2(0.83, 0.17), "motion": "push", "inset": "right", "tone": "crimson"},
			{"speaker": "NARA", "text": "The broken mask held a memory: a baker, laughing with flour on his hands.", "focus": Vector2(0.58, 0.38), "motion": "pull", "inset": "right", "tone": "gold"},
			{"speaker": "MORROW", "text": "Every enemy here was once a life the Archive decided was inconvenient.", "focus": Vector2(0.34, 0.65), "motion": "drift_right", "inset": "left", "tone": "paper"},
			{"speaker": "NARA", "text": "I am not hunting pages anymore. I am bringing people home.", "focus": Vector2(0.31, 0.55), "motion": "push", "inset": "left", "tone": "crimson"},
		],
	},
	"act2_revelation": {
		"chapter": "ACT II COMPLETE",
		"title": "THE FORBIDDEN BINDERY",
		"image": "res://assets/cutscenes/revelation.png",
		"panels": [
			{"speaker": "THE BINDER", "text": "A city survives by forgetting. I merely choose the memories that cost too much.", "focus": Vector2(0.52, 0.43), "motion": "push", "inset": "right", "tone": "crimson"},
			{"speaker": "IORI", "text": "Nara... the masks are dreaming through me. I remember all of them.", "focus": Vector2(0.78, 0.32), "motion": "pull", "inset": "right", "tone": "cold"},
			{"speaker": "NARA", "text": "You erased Iori because she found the first draft of our world.", "focus": Vector2(0.25, 0.50), "motion": "drift_right", "inset": "left", "tone": "crimson"},
			{"speaker": "THE BINDER", "text": "Ask your sword who wrote that draft.", "focus": Vector2(0.52, 0.43), "motion": "drift_left", "inset": "right", "tone": "gold"},
			{"speaker": "MORROW", "text": "I did. Before I became your blade, they called me the First Author.", "focus": Vector2(0.25, 0.76), "motion": "push", "inset": "left", "tone": "gold"},
		],
	},
	"act3_confrontation": {
		"chapter": "ACT III",
		"title": "THE FIRST AUTHOR",
		"image": "res://assets/cutscenes/finale.png",
		"panels": [
			{"speaker": "MORROW", "text": "The thing ahead is the ending I tore away: my hunger to make a flawless world.", "focus": Vector2(0.52, 0.30), "motion": "pull", "inset": "right", "tone": "gold"},
			{"speaker": "IORI", "text": "Perfection is only a page where nobody was allowed to leave a mark.", "focus": Vector2(0.84, 0.43), "motion": "drift_left", "inset": "right", "tone": "cold"},
			{"speaker": "THE FIRST AUTHOR", "text": "Give me the blade, Nara. One clean revision, and no one will ever suffer again.", "focus": Vector2(0.52, 0.27), "motion": "push", "inset": "wide", "tone": "crimson"},
			{"speaker": "NARA", "text": "A painless lie is still an erasure. I choose the messy truth.", "focus": Vector2(0.25, 0.54), "motion": "drift_right", "inset": "left", "tone": "crimson"},
		],
	},
	"ending_choice": {
		"chapter": "FINAL REVISION",
		"title": "WHO OWNS A MEMORY?",
		"image": "res://assets/cutscenes/ending-choice-v2.png",
		"panels": [
			{"speaker": "IORI", "text": "The blank page can restore every stolen memory—or dissolve the Archive forever.", "focus": Vector2(0.68, 0.45), "motion": "pull", "inset": "right", "tone": "cold"},
			{"speaker": "MORROW", "text": "There is no perfect ending. There is only the cost you choose to remember.", "focus": Vector2(0.50, 0.34), "motion": "push", "inset": "wide", "tone": "gold"},
			{"speaker": "NARA", "text": "Then let the final mark be mine.", "focus": Vector2(0.36, 0.47), "motion": "drift_right", "inset": "left", "tone": "crimson"},
		],
		"choices": [
			{"id": "keep", "label": "PRESERVE THE SCARS", "description": "Return the memories and rebuild the Archive."},
			{"id": "rewrite", "label": "BREAK THE BINDING", "description": "Free every memory, even if the old world ends."},
		],
	},
	"ending_keep": {
		"chapter": "ENDING: MARGINS",
		"title": "NOTHING ERASED",
		"image": "res://assets/cutscenes/ending-keep-v2.png",
		"panels": [
			{"speaker": "NARA", "text": "We restored the memories with every stain intact. The city grieved, argued, forgave—and became real again.", "focus": Vector2(0.61, 0.50), "motion": "pull", "inset": "wide", "tone": "gold"},
			{"speaker": "IORI", "text": "The Archive no longer decides what is worthy. Anyone may write in its margins.", "focus": Vector2(0.36, 0.48), "motion": "drift_left", "inset": "left", "tone": "cold"},
			{"speaker": "MORROW", "text": "I became an ordinary sword. It was the kindest ending an author could receive.", "focus": Vector2(0.10, 0.66), "motion": "push", "inset": "left", "tone": "paper"},
			{"speaker": "NARA", "text": "There are still masks beyond the final shelf. Tomorrow, we bring them home too.", "focus": Vector2(0.27, 0.48), "motion": "drift_right", "inset": "left", "tone": "crimson"},
		],
	},
	"ending_rewrite": {
		"chapter": "ENDING: LOOSE LEAVES",
		"title": "A WORLD UNBOUND",
		"image": "res://assets/cutscenes/ending-rewrite-v2.png",
		"panels": [
			{"speaker": "NARA", "text": "I broke the binding. The Archive fell upward in a storm of names, recipes, crimes, lullabies, and unfinished goodbyes.", "focus": Vector2(0.20, 0.30), "motion": "pull", "inset": "left", "tone": "crimson"},
			{"speaker": "IORI", "text": "Without an official history, we had to meet one another and ask what happened.", "focus": Vector2(0.58, 0.53), "motion": "drift_left", "inset": "right", "tone": "cold"},
			{"speaker": "MORROW", "text": "The world became harder to control—and impossible to erase.", "focus": Vector2(0.52, 0.62), "motion": "push", "inset": "left", "tone": "gold"},
			{"speaker": "NARA", "text": "We carried no map into the next draft. For once, that felt like freedom.", "focus": Vector2(0.78, 0.42), "motion": "drift_right", "inset": "wide", "tone": "paper"},
		],
	},
}

const UPGRADES := [
	{"id": "razor-ink", "name": "RAZOR INK", "description": "+0.75 blade damage", "rarity": "common", "max_stacks": 6, "min_level": 1, "tags": ["blade"]},
	{"id": "wide-panel", "name": "WIDE PANEL", "description": "Longer, wider slash arc", "rarity": "common", "max_stacks": 4, "min_level": 1, "tags": ["blade", "area"]},
	{"id": "rapid-stroke", "name": "RAPID STROKE", "description": "Attack 14% faster", "rarity": "common", "max_stacks": 5, "min_level": 1, "tags": ["speed"]},
	{"id": "red-thread", "name": "RED THREAD", "description": "+9% critical chance", "rarity": "common", "max_stacks": 5, "min_level": 1, "tags": ["critical"]},
	{"id": "ghost-step", "name": "GHOST STEP", "description": "Faster movement and dash", "rarity": "common", "max_stacks": 4, "min_level": 1, "tags": ["dash"]},
	{"id": "iron-gutter", "name": "IRON GUTTER", "description": "+2 max health and heal", "rarity": "common", "max_stacks": 5, "min_level": 1, "tags": ["guard"]},
	{"id": "overflow", "name": "OVERFLOW", "description": "More cleave and knockback", "rarity": "common", "max_stacks": 4, "min_level": 1, "tags": ["blade", "area"]},
	{"id": "paper-armor", "name": "LAMINATED SOUL", "description": "Gain 7% damage reduction", "rarity": "common", "max_stacks": 5, "min_level": 2, "tags": ["guard"]},
	{"id": "margin-magnet", "name": "MARGIN MAGNET", "description": "Pull pickups from farther away", "rarity": "common", "max_stacks": 4, "min_level": 1, "tags": ["economy"]},
	{"id": "scholar-luck", "name": "SCHOLAR'S LUCK", "description": "Better relic and recovery drops", "rarity": "rare", "max_stacks": 4, "min_level": 2, "tags": ["economy"]},
	{"id": "living-footnote", "name": "LIVING FOOTNOTE", "description": "Regenerate slowly after avoiding damage", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["guard"]},
	{"id": "blood-annotation", "name": "BLOOD ANNOTATION", "description": "Heal from every twelfth kill", "rarity": "rare", "max_stacks": 3, "min_level": 2, "tags": ["sustain"]},
	{"id": "ink-wave", "name": "INK WAVE", "description": "Every fourth slash fires a cutting wave", "rarity": "rare", "max_stacks": 3, "min_level": 2, "tags": ["projectile"]},
	{"id": "returning-stroke", "name": "RETURNING STROKE", "description": "Ink waves return and strike twice", "rarity": "epic", "max_stacks": 1, "min_level": 5, "tags": ["projectile"]},
	{"id": "splinter-script", "name": "SPLINTER SCRIPT", "description": "Ink waves split after a hit", "rarity": "rare", "max_stacks": 2, "min_level": 4, "tags": ["projectile", "area"]},
	{"id": "bleeding-letters", "name": "BLEEDING LETTERS", "description": "Slashes stack damaging bleed", "rarity": "rare", "max_stacks": 4, "min_level": 2, "tags": ["status"]},
	{"id": "ember-margin", "name": "EMBER MARGIN", "description": "Critical hits burn nearby masks", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["status", "critical"]},
	{"id": "cold-reading", "name": "COLD READING", "description": "Hits slow enemies; frozen foes shatter", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["status"]},
	{"id": "execution-clause", "name": "EXECUTION CLAUSE", "description": "Execute badly wounded non-boss enemies", "rarity": "epic", "max_stacks": 2, "min_level": 5, "tags": ["blade"]},
	{"id": "critical-echo", "name": "CRITICAL ECHO", "description": "Critical hits repeat at half damage", "rarity": "epic", "max_stacks": 2, "min_level": 5, "tags": ["critical"]},
	{"id": "dash-nova", "name": "DASHING PERIOD", "description": "Dash ends with a damaging ink burst", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["dash", "area"]},
	{"id": "afterimage-cut", "name": "AFTERIMAGE CUT", "description": "Your dash trail damages pursuers", "rarity": "epic", "max_stacks": 2, "min_level": 5, "tags": ["dash"]},
	{"id": "perfect-margin", "name": "PERFECT MARGIN", "description": "Untouched streaks build damage", "rarity": "rare", "max_stacks": 3, "min_level": 4, "tags": ["combo"]},
	{"id": "crescendo", "name": "CRESCENDO", "description": "Repeated hits accelerate your blade", "rarity": "rare", "max_stacks": 3, "min_level": 4, "tags": ["combo", "speed"]},
	{"id": "greatbrush", "name": "GREATBRUSH FORM", "description": "Heavy, enormous strokes with brutal knockback", "rarity": "legendary", "max_stacks": 1, "min_level": 4, "tags": ["weapon"]},
	{"id": "needlepoint", "name": "NEEDLEPOINT FORM", "description": "Fast narrow cuts with extreme critical focus", "rarity": "legendary", "max_stacks": 1, "min_level": 4, "tags": ["weapon"]},
	{"id": "seal-caster", "name": "SEAL-CASTER FORM", "description": "Trade reach for relentless ink waves", "rarity": "legendary", "max_stacks": 1, "min_level": 4, "tags": ["weapon", "projectile"]},
	{"id": "twin-stroke", "name": "TWIN-STROKE FORM", "description": "Each attack follows with a mirrored cut", "rarity": "legendary", "max_stacks": 1, "min_level": 6, "tags": ["weapon", "combo"]},
	{"id": "last-word", "name": "THE LAST WORD", "description": "At one health, damage and dash recovery surge", "rarity": "epic", "max_stacks": 1, "min_level": 6, "tags": ["guard", "blade"]},
	{"id": "open-book", "name": "OPEN BOOK", "description": "+1 upgrade choice and better rarity", "rarity": "legendary", "max_stacks": 1, "min_level": 7, "tags": ["economy"]},
	{"id": "living-ink", "name": "LIVING INK", "description": "Ink Arts deal 25% more damage", "rarity": "common", "max_stacks": 4, "min_level": 2, "tags": ["art"]},
	{"id": "quickscript", "name": "QUICKSCRIPT", "description": "Ink Arts recover 14% faster", "rarity": "common", "max_stacks": 4, "min_level": 2, "tags": ["art", "speed"]},
	{"id": "violent-margin", "name": "VIOLENT MARGIN", "description": "Ink Arts cover a wider area", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["art", "area"]},
	{"id": "red-harvest", "name": "RED HARVEST", "description": "Blade hits recharge your Ink Art", "rarity": "rare", "max_stacks": 3, "min_level": 3, "tags": ["art", "combo"]},
	{"id": "echoed-panel", "name": "ECHOED PANEL", "description": "Ink Arts repeat at 45% power", "rarity": "epic", "max_stacks": 1, "min_level": 5, "tags": ["art", "area"]},
	{"id": "merciful-revision", "name": "MERCIFUL REVISION", "description": "An Ink Art hitting five masks heals 1", "rarity": "epic", "max_stacks": 1, "min_level": 5, "tags": ["art", "sustain"]},
]

# Run builds are grouped into six readable manuscript disciplines. A technique
# contributes one point per stack to every discipline sharing one of its tags;
# milestones at three and six points grant deterministic, save-safe bonuses.
const BUILD_DISCIPLINES := [
	{
		"id": "ink-edge",
		"name": "INK EDGE",
		"tags": ["blade", "area"],
		"thresholds": [3, 6],
		"bonuses": ["+8 reach and +1 cleave", "+0.5 blade damage, +2 reach, +1 cleave"],
	},
	{
		"id": "red-logic",
		"name": "RED LOGIC",
		"tags": ["critical", "status"],
		"thresholds": [3, 6],
		"bonuses": ["+5% critical chance", "+30% critical damage"],
	},
	{
		"id": "quick-margin",
		"name": "QUICK MARGIN",
		"tags": ["speed", "combo"],
		"thresholds": [3, 6],
		"bonuses": ["Attack 6% faster", "+8 movement and +1 combo power"],
	},
	{
		"id": "ghost-draft",
		"name": "GHOST DRAFT",
		"tags": ["dash"],
		"thresholds": [3, 6],
		"bonuses": ["Dash recovers 10% faster", "Dash gains a nova and cutting afterimage"],
	},
	{
		"id": "living-script",
		"name": "LIVING SCRIPT",
		"tags": ["projectile", "art"],
		"thresholds": [3, 6],
		"bonuses": ["Ink Arts recover 10% faster", "Slashes gain ink waves; Ink Art deals +15%"],
	},
	{
		"id": "bound-page",
		"name": "BOUND PAGE",
		"tags": ["guard", "sustain", "economy"],
		"thresholds": [3, 6],
		"bonuses": ["+1 max health and heal", "Gain recovery, reduction, and 2 Ward"],
	},
]

const RELICS := [
	{"id": "broken-mask", "name": "BROKEN MASK", "description": "+15% damage against elites and bosses"},
	{"id": "iori-ribbon", "name": "IORI'S RIBBON", "description": "The first lethal hit each run leaves you at 1 health"},
	{"id": "red-pencil", "name": "RED PENCIL", "description": "Every tenth hit is guaranteed critical"},
	{"id": "library-card", "name": "FORBIDDEN LIBRARY CARD", "description": "+20% Ink and shard value"},
	{"id": "glass-nib", "name": "GLASS NIB", "description": "+35% critical damage, -10% max health"},
	{"id": "binder-chain", "name": "BROKEN BINDER CHAIN", "description": "Nearby enemies are slowed after a dash"},
	{"id": "black-tea", "name": "MORROW'S BLACK TEA", "description": "Heal at the start of every new page"},
	{"id": "wax-seal", "name": "ROYAL WAX SEAL", "description": "Ink waves grow larger and pierce once"},
	{"id": "misprint", "name": "LUCKY MISPRINT", "description": "Small chance for defeated enemies to drop twice"},
	{"id": "paper-heart", "name": "PAPER HEART", "description": "+4 max health; recovery can overheal into guard"},
	{"id": "empty-frame", "name": "EMPTY FRAME", "description": "Standing still briefly grants a damage aura"},
	{"id": "first-draft", "name": "THE FIRST DRAFT", "description": "+0.5 damage and +5% critical chance"},
]

const STARTING_WEAPONS := [
	{"id": "marginalia", "upgrade_id": "", "name": "MARGINALIA BLADE", "form": "MARGINALIA", "art": "PALIMPSEST RING", "description": "Balanced and flexible; restored transformations remain in the technique pool."},
	{"id": "greatbrush", "upgrade_id": "greatbrush", "name": "GREATBRUSH", "form": "GREATBRUSH", "art": "FINAL PERIOD", "description": "Slow enormous strokes and brutal knockback; locks other forms."},
	{"id": "needlepoint", "upgrade_id": "needlepoint", "name": "NEEDLEPOINT", "form": "NEEDLEPOINT", "art": "RED LINE", "description": "Rapid narrow critical cuts; locks other forms."},
	{"id": "seal-caster", "upgrade_id": "seal-caster", "name": "SEAL-CASTER", "form": "SEAL-CASTER", "art": "SEAL STORM", "description": "Short reach and a wave on every slash; locks other forms."},
	{"id": "twin-stroke", "upgrade_id": "twin-stroke", "name": "TWIN-STROKE", "form": "TWIN-STROKE", "art": "CROSS REVISION", "description": "Measured attacks followed by mirrored cuts; locks other forms."},
]

const ROUTES := [
	{"id": "whisper-stacks", "chapter": 1, "name": "WHISPER STACKS", "short": "WHISPER", "tagline": "Soft shelves answer with borrowed voices.", "card": "ENTER ECHO SANCTUARIES\nRANGED MASKS · MORE HEALS\nSCORE ×1.08", "effect": "Echo sanctuaries slow masks and restore Ink Art · ×1.08 score", "hazard": "echo-sanctuary", "hazard_name": "ECHO SANCTUARY", "hazard_hint": "Enter the speaking circle when it resolves.", "hazard_interval": 10.5, "enemy_bias": ["scribe", "blot"], "bias_chance": 0.44, "enemy_speed": 0.94, "recovery": 1.25, "score": 1.08, "shards": 1.08},
	{"id": "razor-gallery", "chapter": 1, "name": "RAZOR GALLERY", "short": "RAZOR", "tagline": "Portrait frames close like sharpened teeth.", "card": "DODGE RAZOR SWEEPS\nCHARGERS · TOUGHER MASKS\nSCORE ×1.12", "effect": "Telegraphed razor lines cut both sides · ×1.12 score", "hazard": "razor-sweep", "hazard_name": "RAZOR SWEEP", "hazard_hint": "Cross the red line before the frame closes.", "hazard_interval": 8.5, "enemy_bias": ["dasher", "brute"], "bias_chance": 0.48, "enemy_health": 1.08, "enemy_speed": 1.05, "score": 1.12, "shards": 1.1},
	{"id": "black-index", "chapter": 1, "name": "BLACK INDEX", "short": "INDEX", "tagline": "Forbidden names bleed through every card.", "card": "EVADE REDACTION STAMPS\nMORE ELITES · FEWER HEALS\nMEMORY ×1.24", "effect": "Redaction stamps erase crowded ground · ×1.15 score", "hazard": "redaction-stamp", "hazard_name": "REDACTION STAMP", "hazard_hint": "Leave the marked card before it turns black.", "hazard_interval": 9.0, "enemy_bias": ["mask", "scribe", "blot"], "bias_chance": 0.4, "elite_bonus": 0.08, "recovery": 0.78, "score": 1.15, "shards": 1.24},
	{"id": "chain-vault", "chapter": 2, "name": "CHAIN VAULT", "short": "CHAIN", "tagline": "Contradictory histories strain against iron thread.", "card": "CROSS ROTATING CHAINS\nCENSORS · SPLITTERS\nARMORED · SCORE ×1.14", "effect": "Crossing chain lines bind player and masks · ×1.14 score", "hazard": "chain-cross", "hazard_name": "BINDING CROSS", "hazard_hint": "Move between the two tightening chain lines.", "hazard_interval": 8.2, "enemy_bias": ["censor", "splitter"], "bias_chance": 0.5, "enemy_health": 1.1, "enemy_speed": 0.94, "score": 1.14, "shards": 1.12},
	{"id": "errata-canals", "chapter": 2, "name": "ERRATA CANALS", "short": "ERRATA", "tagline": "Loose sentences hunt through rivers of wet ink.", "card": "ESCAPE INK SURGES\nTELEPORTERS · LEECHES\nFASTER · SCORE ×1.15", "effect": "Canal surges sweep a telegraphed lane · ×1.15 score", "hazard": "canal-surge", "hazard_name": "ERRATA SURGE", "hazard_hint": "Leave the flashing ink lane or ride its current.", "hazard_interval": 7.8, "enemy_bias": ["errata", "leech"], "bias_chance": 0.54, "enemy_health": 0.94, "enemy_speed": 1.1, "spawn_interval": 0.88, "score": 1.15, "shards": 1.14},
	{"id": "contraband-hall", "chapter": 2, "name": "CONTRABAND HALL", "short": "MARKET", "tagline": "Stolen memories change hands beneath red lanterns.", "card": "CLAIM VOLATILE CACHES\nMORE ELITE TRADERS\nMEMORY ×1.32", "effect": "Claim timed contraband before its lantern burns · ×1.16 score", "hazard": "contraband-cache", "hazard_name": "VOLATILE CACHE", "hazard_hint": "Touch the cache for Memory and Ward before it explodes.", "hazard_interval": 11.0, "enemy_bias": ["splitter", "leech", "censor"], "bias_chance": 0.42, "elite_bonus": 0.11, "recovery": 1.08, "score": 1.16, "shards": 1.32},
	{"id": "white-room", "chapter": 3, "name": "WHITE ROOM", "short": "WHITE", "tagline": "An unwritten chamber tries to erase every wound.", "card": "SHARE REVISION FIELDS\nWARDENS · HEALERS\nDURABLE · SCORE ×1.14", "effect": "White fields heal every body inside them · ×1.14 score", "hazard": "white-revision", "hazard_name": "WHITE REVISION", "hazard_hint": "Take the healing field only after clearing its masks.", "hazard_interval": 10.0, "enemy_bias": ["warden", "archivist"], "bias_chance": 0.52, "enemy_health": 1.12, "spawn_interval": 1.08, "recovery": 1.24, "score": 1.14, "shards": 1.14},
	{"id": "red-press", "chapter": 3, "name": "RED PRESS", "short": "PRESS", "tagline": "The first printing machine stamps verdicts in blood.", "card": "DODGE TRIPLE VERDICTS\nDUELISTS · WARDENS\nDEADLIER · SCORE ×1.18", "effect": "The Red Press stamps three lethal verdicts · ×1.18 score", "hazard": "press-stamp", "hazard_name": "TRIPLE VERDICT", "hazard_hint": "Read all three circles before the press falls.", "hazard_interval": 7.2, "enemy_bias": ["duelist", "warden"], "bias_chance": 0.56, "enemy_damage": 1.08, "enemy_speed": 1.07, "score": 1.18, "shards": 1.2},
	{"id": "loose-leaves", "chapter": 3, "name": "LOOSE LEAVES", "short": "LEAVES", "tagline": "Unbound pages become a storm with no center.", "card": "READ THE PAGE GUSTS\nLARGER RAPID HORDES\nLIGHTER · SCORE ×1.20", "effect": "Page gusts reposition the entire battle · ×1.20 score", "hazard": "page-gust", "hazard_name": "PAGE GUST", "hazard_hint": "Use the arrows to prepare for the coming push.", "hazard_interval": 6.8, "enemy_bias": ["errata", "archivist", "duelist"], "bias_chance": 0.5, "enemy_health": 0.94, "spawn_interval": 0.76, "enemy_cap": 1.28, "score": 1.2, "shards": 1.2},
]

const ENEMIES := {
	"mask": {"name": "Forgotten Mask", "role": "pursuer", "chapter": 1},
	"dasher": {"name": "Red Comma", "role": "telegraphed charger", "chapter": 1},
	"brute": {"name": "Heavy Redaction", "role": "slow tank", "chapter": 1},
	"scribe": {"name": "Margin Scribe", "role": "ranged skirmisher", "chapter": 1},
	"splitter": {"name": "Torn Paragraph", "role": "splits on death", "chapter": 2},
	"leech": {"name": "Name Thief", "role": "fast life-drainer", "chapter": 2},
	"warden": {"name": "Gutter Warden", "role": "area denial", "chapter": 3},
	"censor": {"name": "Iron Censor", "role": "frontal shield; flank or break", "chapter": 2},
	"errata": {"name": "Errata Shade", "role": "teleports behind the player", "chapter": 2},
	"archivist": {"name": "False Archivist", "role": "heals and hastes nearby masks", "chapter": 3},
	"blot": {"name": "Living Inkblot", "role": "stationary radial hazard", "chapter": 1},
	"duelist": {"name": "Margin Duelist", "role": "timed parry and counter-rush", "chapter": 3},
	"editor": {"name": "The Red Editor", "role": "act one boss", "chapter": 1},
	"binder": {"name": "The Binder", "role": "act two boss", "chapter": 2},
	"author": {"name": "The First Author", "role": "final boss", "chapter": 3},
}

const ACHIEVEMENTS := [
	{"id": "first-cut", "steam_id": "FIRST_CUT", "name": "First Cut", "description": "Defeat your first mask.", "metric": "kills", "target": 1},
	{"id": "hundred-redactions", "steam_id": "HUNDRED_REDACTIONS", "name": "Hundred Redactions", "description": "Defeat 100 enemies across all drafts.", "metric": "kills", "target": 100},
	{"id": "thousand-cuts", "steam_id": "THOUSAND_CUTS", "name": "Thousand Cuts", "description": "Defeat 1,000 enemies across all drafts.", "metric": "kills", "target": 1000},
	{"id": "page-turner", "steam_id": "PAGE_TURNER", "name": "Page Turner", "description": "Reach Page 4.", "metric": "wave", "target": 4},
	{"id": "last-page", "steam_id": "LAST_PAGE", "name": "Last Page", "description": "Reach Page 12.", "metric": "wave", "target": 12},
	{"id": "one-true-ending", "steam_id": "ONE_TRUE_ENDING", "name": "One True Ending?", "description": "Complete either ending.", "metric": "endings", "target": 1},
	{"id": "both-margins", "steam_id": "BOTH_MARGINS", "name": "Both Margins", "description": "Complete both endings.", "metric": "endings", "target": 2},
	{"id": "contract-bound", "steam_id": "CONTRACT_BOUND", "name": "Contract Bound", "description": "Clear any contract.", "metric": "contracts", "target": 1},
	{"id": "six-seals", "steam_id": "SIX_SEALS", "name": "Six Seals", "description": "Clear all six challenge contracts.", "metric": "contracts", "target": 6},
	{"id": "relic-keeper", "steam_id": "RELIC_KEEPER", "name": "Relic Keeper", "description": "Discover all twelve relics.", "metric": "relics", "target": 12},
	{"id": "complete-marginalia", "steam_id": "COMPLETE_MARGINALIA", "name": "Complete Marginalia", "description": "Discover all thirty-six techniques.", "metric": "upgrades", "target": 36},
	{"id": "restored-codex", "steam_id": "RESTORED_CODEX", "name": "Restored Codex", "description": "Defeat every enemy archetype.", "metric": "codex", "target": 15},
	{"id": "redline-reader", "steam_id": "REDLINE_READER", "name": "Redline Reader", "description": "Finish a Redline Draft.", "metric": "redline_wins", "target": 1},
	{"id": "living-memory", "steam_id": "LIVING_MEMORY", "name": "Living Memory", "description": "Recover 250 Memory across all drafts.", "metric": "memory", "target": 250},
	{"id": "map-the-margins", "steam_id": "MAP_THE_MARGINS", "name": "Map the Margins", "description": "Discover all nine routes through the Archive.", "metric": "routes", "target": 9},
	{"id": "first-order", "steam_id": "FIRST_ORDER", "name": "Order in the Margins", "description": "Complete your first Page Directive.", "metric": "directives", "target": 1},
	{"id": "field-editor", "steam_id": "FIELD_EDITOR", "name": "Field Editor", "description": "Complete twenty Page Directives.", "metric": "directives", "target": 20},
	{"id": "daily-reader", "steam_id": "DAILY_READER", "name": "Today's Reader", "description": "Clear a Daily Chronicle.", "metric": "daily_clears", "target": 1},
	{"id": "serial-reader", "steam_id": "SERIAL_READER", "name": "Serial Reader", "description": "Build a seven-day Daily Chronicle streak.", "metric": "daily_streak", "target": 7},
]

const ARCHIVE_RANK_THRESHOLDS := [0, 25, 60, 110, 180, 270, 380, 510, 660, 830]

const META_RESTORATIONS := [
	{"id": "vital", "name": "HEARTBIND", "description": "+1 MAX HEALTH / RANK", "mastery": "MASTER: START WITH WARD +2", "required_rank": 1, "max_rank": 5, "base_cost": 8, "cost_step": 8},
	{"id": "edge", "name": "HONED NIB", "description": "+0.2 BLADE DAMAGE / RANK", "mastery": "MASTER: +10% BOSS DAMAGE", "required_rank": 1, "max_rank": 5, "base_cost": 8, "cost_step": 8},
	{"id": "fortune", "name": "LUCKY MISPRINT", "description": "+5% LUCK / RANK", "mastery": "MASTER: +10% INK VALUE", "required_rank": 1, "max_rank": 5, "base_cost": 8, "cost_step": 8},
	{"id": "stride", "name": "QUICK MARGIN", "description": "+3 MOVE SPEED / RANK", "mastery": "MASTER: 10% FASTER DASH", "required_rank": 2, "max_rank": 5, "base_cost": 8, "cost_step": 8},
	{"id": "inkwell", "name": "DEEP INKWELL", "description": "4% FASTER INK ART / RANK", "mastery": "MASTER: +15% ART DAMAGE", "required_rank": 4, "max_rank": 5, "base_cost": 8, "cost_step": 8},
	{"id": "thread", "name": "READER'S THREAD", "description": "+18 PICKUP REACH / RANK", "mastery": "MASTER: +45 EXTRA REACH", "required_rank": 6, "max_rank": 5, "base_cost": 8, "cost_step": 8},
]

const PROGRESSION_UNLOCKS := [
	{"id": "contract:open-draft", "kind": "contract", "content_id": "open-draft", "name": "OPEN DRAFT", "metric": "runs", "target": 0, "hint": "Available from the first page."},
	{"id": "weapon:greatbrush", "kind": "weapon", "content_id": "greatbrush", "name": "GREATBRUSH FORM", "metric": "runs", "target": 0, "hint": "Available from the first page."},
	{"id": "difficulty:story", "kind": "difficulty", "content_id": "story", "name": "STORY DRAFT", "metric": "runs", "target": 0, "hint": "Available from the first page."},
	{"id": "difficulty:standard", "kind": "difficulty", "content_id": "standard", "name": "STANDARD DRAFT", "metric": "runs", "target": 0, "hint": "Available from the first page."},
	{"id": "contract:quick-edition", "kind": "contract", "content_id": "quick-edition", "name": "QUICK EDITION", "metric": "runs", "target": 1, "hint": "Complete one draft, win or lose."},
	{"id": "contract:living-margins", "kind": "contract", "content_id": "living-margins", "name": "LIVING MARGINS", "metric": "wave", "target": 4, "hint": "Reach Page 4."},
	{"id": "weapon:needlepoint", "kind": "weapon", "content_id": "needlepoint", "name": "NEEDLEPOINT FORM", "metric": "kills", "target": 25, "hint": "Defeat 25 masks across all drafts."},
	{"id": "contract:sealed-archive", "kind": "contract", "content_id": "sealed-archive", "name": "SEALED ARCHIVE", "metric": "wave", "target": 8, "hint": "Reach Page 8."},
	{"id": "weapon:seal-caster", "kind": "weapon", "content_id": "seal-caster", "name": "SEAL-CASTER FORM", "metric": "wave", "target": 8, "hint": "Reach Page 8."},
	{"id": "contract:glass-script", "kind": "contract", "content_id": "glass-script", "name": "GLASS SCRIPT", "metric": "endings", "target": 1, "hint": "Complete either ending."},
	{"id": "difficulty:redline", "kind": "difficulty", "content_id": "redline", "name": "REDLINE DRAFT", "metric": "endings", "target": 1, "hint": "Complete either ending."},
	{"id": "weapon:twin-stroke", "kind": "weapon", "content_id": "twin-stroke", "name": "TWIN-STROKE FORM", "metric": "endings", "target": 1, "hint": "Complete either ending."},
	{"id": "contract:cursed-ink", "kind": "contract", "content_id": "cursed-ink", "name": "CURSED INK", "metric": "contract_clears", "target": 3, "hint": "Clear three different contracts."},
]

const CONTRACTS := [
	{"id": "open-draft", "name": "OPEN DRAFT", "description": "The intended balance. No special clauses.", "score": 1.0, "shards": 1.0},
	{"id": "quick-edition", "name": "QUICK EDITION", "description": "Pages turn every 32 seconds and enemies move faster. ×1.40 score.", "wave_duration": 32.0, "enemy_speed": 1.14, "score": 1.4, "shards": 1.25},
	{"id": "living-margins", "name": "LIVING MARGINS", "description": "Larger, faster hordes with lighter bodies. ×1.35 score.", "spawn_interval": 0.66, "enemy_cap": 1.45, "enemy_health": 0.86, "score": 1.35, "shards": 1.2},
	{"id": "sealed-archive", "name": "SEALED ARCHIVE", "description": "Recovery drops are sealed; enemies endure longer. ×1.45 score.", "recovery": 0.0, "enemy_health": 1.12, "score": 1.45, "shards": 1.4},
	{"id": "glass-script", "name": "GLASS SCRIPT", "description": "+35% blade damage, fragile body, deadlier masks. ×1.50 score.", "player_damage": 1.35, "player_health": 0.65, "enemy_damage": 1.2, "score": 1.5, "shards": 1.25},
	{"id": "cursed-ink", "name": "CURSED INK", "description": "Far more elite affixes; every victory pays Memory. ×1.55 score.", "elite_bonus": 0.24, "enemy_health": 1.08, "score": 1.55, "shards": 1.5},
]

const DAILY_CLEAR_BONUS := 12

const PROOF_LEVELS := [
	{"depth": 0, "name": "OPEN PROOF", "description": "The restored baseline. No cumulative proof clauses."},
	{"depth": 1, "name": "BLOOD INK", "description": "Masks deal 4% more damage.", "enemy_damage": 1.04, "score": 1.08, "shards": 1.05},
	{"depth": 2, "name": "HEAVY STOCK", "description": "Masks have 6% more health.", "enemy_health": 1.06, "score": 1.08, "shards": 1.05},
	{"depth": 3, "name": "CROWDED MARGINS", "description": "Hordes arrive 6% faster and hold 8% more masks.", "spawn_interval": 0.94, "enemy_cap": 1.08, "score": 1.08, "shards": 1.05},
	{"depth": 4, "name": "MARKED COPIES", "description": "Elite affixes appear 8% more often.", "elite_bonus": 0.08, "score": 1.08, "shards": 1.05},
	{"depth": 5, "name": "SEALED REMEDIES", "description": "Recovery drops are 15% scarcer.", "recovery": 0.85, "score": 1.08, "shards": 1.05},
	{"depth": 6, "name": "RUNNING TYPE", "description": "Masks move 6% faster.", "enemy_speed": 1.06, "score": 1.08, "shards": 1.05},
	{"depth": 7, "name": "THE RED PEN", "description": "Bosses carry 12% more health.", "boss_health": 1.12, "score": 1.08, "shards": 1.05},
	{"depth": 8, "name": "BROKEN GUTTER", "description": "Nara's dash recovers 10% slower.", "dash_cooldown": 1.10, "score": 1.08, "shards": 1.05},
	{"depth": 9, "name": "LAST DEADLINE", "description": "Pages turn 8% sooner.", "wave_duration": 0.92, "score": 1.08, "shards": 1.05},
	{"depth": 10, "name": "AUTHOR'S PROOF", "description": "Masks gain 6% health and 4% damage; bosses gain another 8% health.", "enemy_health": 1.06, "enemy_damage": 1.04, "boss_health": 1.08, "score": 1.08, "shards": 1.05},
]

const EVENTS := [
	{"id": "forgotten-shrine", "chapter": 1, "title": "THE FORGOTTEN SHRINE", "text": "Names scratched into the stone answer when Nara touches the blade.", "options": [
		{"label": "OFFER A HEARTBEAT", "description": "Lose 1 max health; gain a relic.", "effect": "relic_cost_health", "amount": 1.0},
		{"label": "READ EVERY NAME", "description": "Recover 5 Memory shards.", "effect": "shards", "amount": 5},
		{"label": "REST IN THE MARGIN", "description": "Recover 3 health.", "effect": "heal", "amount": 3.0},
	]},
	{"id": "bleeding-index", "chapter": 1, "title": "THE BLEEDING INDEX", "text": "A catalogue points toward books the Editors were ordered to destroy.", "options": [
		{"label": "FOLLOW THE RED LINE", "description": "Gain a random technique.", "effect": "upgrade", "amount": 1},
		{"label": "CUT OUT THE ENTRY", "description": "+0.5 damage; lose 1 max health.", "effect": "damage_health", "amount": 0.5},
		{"label": "SEAL THE DRAWER", "description": "Gain 3 guard for the next battle.", "effect": "guard", "amount": 3.0},
	]},
	{"id": "maskless-child", "chapter": 1, "title": "THE MASKLESS CHILD", "text": "A recovered memory asks whether being forgotten still counts as being alive.", "options": [
		{"label": "PROMISE TO RETURN", "description": "+1 max health and heal.", "effect": "max_health", "amount": 1.0},
		{"label": "SHARE IORI'S RIBBON", "description": "+6% critical chance.", "effect": "critical", "amount": 0.06},
		{"label": "LEAVE A MAP", "description": "+8 movement speed.", "effect": "speed", "amount": 8.0},
	]},
	{"id": "contraband-teahouse", "chapter": 2, "title": "CONTRABAND TEAHOUSE", "text": "Morrow remembers a room where banned stories were once traded over black tea.", "options": [
		{"label": "DRINK THE LAST CUP", "description": "Fully heal and gain 2 guard.", "effect": "cleanse", "amount": 2.0},
		{"label": "TRADE A TRUE STORY", "description": "Gain a relic; lose 2 health.", "effect": "relic_cost_health", "amount": 0.0},
		{"label": "SEARCH THE CELLAR", "description": "Ambush by 3 elites; gain 5 Memory now.", "effect": "elite_ambush", "amount": 3},
	]},
	{"id": "unbound-footnote", "chapter": 2, "title": "THE UNBOUND FOOTNOTE", "text": "A sentence crawls free of its page and begs Nara to choose its ending.", "options": [
		{"label": "MAKE IT A WEAPON", "description": "+0.4 damage.", "effect": "damage", "amount": 0.4},
		{"label": "MAKE IT A SHELTER", "description": "+2 max health.", "effect": "max_health", "amount": 2.0},
		{"label": "LET IT STAY UNFINISHED", "description": "+15% luck this run.", "effect": "luck", "amount": 0.15},
	]},
	{"id": "red-market", "chapter": 2, "title": "THE RED MARKET", "text": "Masked merchants sell memories whose owners have not forgotten losing them.", "options": [
		{"label": "BUY THE SEALED BOX", "description": "Gain a random relic.", "effect": "relic", "amount": 1},
		{"label": "STEAL BACK THE NAMES", "description": "Fight 4 elites; gain 8 Memory now.", "effect": "elite_ambush", "amount": 4},
		{"label": "BURN THE LEDGER", "description": "+10% attack speed.", "effect": "attack_speed", "amount": 0.1},
	]},
	{"id": "author-shadow", "chapter": 3, "title": "THE AUTHOR'S SHADOW", "text": "Morrow's discarded shadow still knows how to improve a killing sentence.", "options": [
		{"label": "ACCEPT THE REVISION", "description": "Gain a random technique and 2 guard.", "effect": "upgrade_guard", "amount": 2.0},
		{"label": "REJECT PERFECTION", "description": "+0.5 damage and +5% critical chance.", "effect": "defiance", "amount": 0.5},
		{"label": "ASK ABOUT IORI", "description": "Recover 9 Memory shards.", "effect": "shards", "amount": 9},
	]},
	{"id": "white-room", "chapter": 3, "title": "THE WHITE ROOM", "text": "Nothing has ever been written here. Even wounds briefly forget their names.", "options": [
		{"label": "WRITE YOUR SCARS", "description": "Fully heal; +1 max health.", "effect": "full_heal_health", "amount": 1.0},
		{"label": "WRITE YOUR ANGER", "description": "+0.75 damage; lose 2 health.", "effect": "blood_damage", "amount": 0.75},
		{"label": "LEAVE IT BLANK", "description": "Gain 5 guard.", "effect": "guard", "amount": 5.0},
	]},
	{"id": "last-reader", "chapter": 3, "title": "THE LAST READER", "text": "An old reader has waited decades to learn whether the world survives its ending.", "options": [
		{"label": "TELL THE TRUTH", "description": "+20% critical damage.", "effect": "critical_damage", "amount": 0.2},
		{"label": "TELL A KIND LIE", "description": "Recover 4 health and 4 Memory.", "effect": "heal_shards", "amount": 4},
		{"label": "HAND OVER THE BLADE", "description": "Gain a relic; summon 2 elites.", "effect": "relic_ambush", "amount": 2},
	]},
]

const PAGE_DIRECTIVES := [
	{"id": "redaction-quota", "chapter": 1, "kind": "kills", "title": "REDACTION QUOTA", "description": "Cut down ten masks before the page turns.", "target": 10.0, "reward": "shards", "reward_amount": 2.0, "reward_text": "MEMORY +2"},
	{"id": "loose-ink", "chapter": 1, "kind": "ink", "title": "GATHER LOOSE INK", "description": "Recover ten scattered Ink marks.", "target": 10.0, "reward": "guard", "reward_amount": 3.0, "reward_text": "WARD +3"},
	{"id": "whisper-circle", "chapter": 1, "kind": "hold", "title": "HOLD THE WHISPER", "description": "Stand inside the speaking margin for seven seconds.", "target": 7.0, "reward": "heal", "reward_amount": 2.0, "reward_text": "RECOVER +2"},
	{"id": "torn-sentence", "chapter": 2, "kind": "kills", "title": "FINISH THE SENTENCE", "description": "Defeat fourteen Bindery masks.", "target": 14.0, "reward": "shards", "reward_amount": 3.0, "reward_text": "MEMORY +3"},
	{"id": "censor-cell", "chapter": 2, "kind": "elites", "title": "BREAK THE CENSOR CELL", "description": "Defeat two marked elite masks.", "target": 2.0, "reward": "upgrade", "reward_amount": 1.0, "reward_text": "FREE TECHNIQUE"},
	{"id": "bindery-circle", "chapter": 2, "kind": "hold", "title": "READ AGAINST THE BINDING", "description": "Hold the forbidden circle for nine seconds.", "target": 9.0, "reward": "guard", "reward_amount": 4.0, "reward_text": "WARD +4"},
	{"id": "press-deadline", "chapter": 3, "kind": "kills", "title": "BEAT THE PRESS", "description": "Defeat eighteen masks before the verdict lands.", "target": 18.0, "reward": "art", "reward_amount": 1.0, "reward_text": "INK ART RESTORED"},
	{"id": "final-proof", "chapter": 3, "kind": "elites", "title": "REJECT THE FINAL PROOF", "description": "Defeat three elite proofreaders.", "target": 3.0, "reward": "relic", "reward_amount": 1.0, "reward_text": "RELIC RESTORED"},
	{"id": "living-testimony", "chapter": 3, "kind": "ink", "title": "RECOVER TESTIMONY", "description": "Gather sixteen living Ink marks.", "target": 16.0, "reward": "heal_shards", "reward_amount": 3.0, "reward_text": "RECOVER +3 · MEMORY +3"},
]

const ENCOUNTER_SQUADS := [
	{"id": "comma-rush", "chapter": 1, "name": "THE COMMA RUSH", "formation": "ring", "members": ["dasher", "dasher", "dasher", "mask", "mask"], "elites": 0},
	{"id": "scriptorium-line", "chapter": 1, "name": "SCRIPTORIUM FIRING LINE", "formation": "line", "members": ["scribe", "scribe", "mask", "brute"], "elites": 0},
	{"id": "black-index-cell", "chapter": 1, "name": "BLACK INDEX CELL", "formation": "wedge", "members": ["brute", "blot", "mask", "mask", "dasher"], "elites": 1},
	{"id": "bound-sentence", "chapter": 2, "name": "THE BOUND SENTENCE", "formation": "wedge", "members": ["censor", "splitter", "splitter", "scribe"], "elites": 1},
	{"id": "name-thief-cabal", "chapter": 2, "name": "NAME-THIEF CABAL", "formation": "ring", "members": ["leech", "leech", "errata", "errata"], "elites": 1},
	{"id": "censor-escort", "chapter": 2, "name": "IRON CENSOR ESCORT", "formation": "line", "members": ["censor", "censor", "scribe", "splitter", "brute"], "elites": 1},
	{"id": "press-guard", "chapter": 3, "name": "THE RED PRESS GUARD", "formation": "wedge", "members": ["warden", "warden", "duelist", "scribe"], "elites": 1},
	{"id": "false-catalogue", "chapter": 3, "name": "FALSE CATALOGUE", "formation": "line", "members": ["archivist", "censor", "errata", "leech", "scribe"], "elites": 1},
	{"id": "final-margins", "chapter": 3, "name": "THE FINAL MARGINS", "formation": "ring", "members": ["duelist", "duelist", "warden", "blot", "archivist"], "elites": 2},
]


static func story(sequence_id: String) -> Dictionary:
	return STORY.get(sequence_id, {}).duplicate(true)


static func upgrade(upgrade_id: String) -> Dictionary:
	for entry in UPGRADES:
		if entry["id"] == upgrade_id:
			return entry.duplicate(true)
	return {}


static func build_discipline(discipline_id: String) -> Dictionary:
	for entry in BUILD_DISCIPLINES:
		if entry["id"] == discipline_id:
			return entry.duplicate(true)
	return {}


static func build_discipline_scores(stacks: Dictionary) -> Dictionary:
	var scores := {}
	for discipline in BUILD_DISCIPLINES:
		scores[discipline["id"]] = 0
	for upgrade_data in UPGRADES:
		var stack_count := maxi(0, int(stacks.get(upgrade_data["id"], 0)))
		if stack_count <= 0:
			continue
		for discipline in BUILD_DISCIPLINES:
			if _upgrade_matches_discipline(upgrade_data, discipline):
				scores[discipline["id"]] = int(scores[discipline["id"]]) + stack_count
	return scores


static func dominant_build_discipline(stacks: Dictionary, minimum_score: int = 1) -> Dictionary:
	var scores := build_discipline_scores(stacks)
	var best: Dictionary = {}
	var best_score := minimum_score - 1
	for discipline in BUILD_DISCIPLINES:
		var score := int(scores.get(discipline["id"], 0))
		if score > best_score:
			best = discipline.duplicate(true)
			best_score = score
	if best.is_empty():
		return {}
	best["score"] = best_score
	best["tier"] = build_discipline_tier(best, best_score)
	best["next_threshold"] = next_build_threshold(best, best_score)
	return best


static func discipline_for_upgrade(upgrade_data: Dictionary, stacks: Dictionary = {}) -> Dictionary:
	var scores := build_discipline_scores(stacks)
	var best: Dictionary = {}
	var best_score := -1
	for discipline in BUILD_DISCIPLINES:
		if not _upgrade_matches_discipline(upgrade_data, discipline):
			continue
		var score := int(scores.get(discipline["id"], 0))
		if score > best_score:
			best = discipline.duplicate(true)
			best_score = score
	if not best.is_empty():
		best["score"] = maxi(0, best_score)
		best["tier"] = build_discipline_tier(best, maxi(0, best_score))
		best["next_threshold"] = next_build_threshold(best, maxi(0, best_score))
	return best


static func upgrade_supports_discipline(upgrade_data: Dictionary, discipline_id: String) -> bool:
	var discipline := build_discipline(discipline_id)
	return not discipline.is_empty() and _upgrade_matches_discipline(upgrade_data, discipline)


static func build_discipline_tier(discipline: Dictionary, score: int) -> int:
	var tier := 0
	for threshold in discipline.get("thresholds", []):
		if score >= int(threshold):
			tier += 1
	return tier


static func next_build_threshold(discipline: Dictionary, score: int) -> int:
	for threshold in discipline.get("thresholds", []):
		if score < int(threshold):
			return int(threshold)
	return int(discipline.get("thresholds", [score])[-1]) if not discipline.get("thresholds", []).is_empty() else score


static func _upgrade_matches_discipline(upgrade_data: Dictionary, discipline: Dictionary) -> bool:
	for tag in upgrade_data.get("tags", []):
		if tag in discipline.get("tags", []):
			return true
	return false


static func relic(relic_id: String) -> Dictionary:
	for entry in RELICS:
		if entry["id"] == relic_id:
			return entry.duplicate(true)
	return {}


static func starting_weapon(weapon_id: String) -> Dictionary:
	for entry in STARTING_WEAPONS:
		if entry["id"] == weapon_id:
			return entry.duplicate(true)
	return {}


static func route(route_id: String) -> Dictionary:
	for entry in ROUTES:
		if entry["id"] == route_id:
			return entry.duplicate(true)
	return {}


static func routes_for_chapter(chapter: int) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for entry in ROUTES:
		if int(entry["chapter"]) == chapter:
			available.append(entry.duplicate(true))
	return available


static func achievement(achievement_id: String) -> Dictionary:
	for entry in ACHIEVEMENTS:
		if entry["id"] == achievement_id:
			return entry.duplicate(true)
	return {}


static func meta_restoration(restoration_id: String) -> Dictionary:
	for entry in META_RESTORATIONS:
		if entry["id"] == restoration_id:
			return entry.duplicate(true)
	return {}


static func meta_restoration_cost(restoration_id: String, current_rank: int) -> int:
	var entry := meta_restoration(restoration_id)
	if entry.is_empty() or current_rank < 0 or current_rank >= int(entry["max_rank"]):
		return 0
	return int(entry["base_cost"]) + current_rank * int(entry["cost_step"])


static func contract(contract_id: String) -> Dictionary:
	for entry in CONTRACTS:
		if entry["id"] == contract_id:
			return entry.duplicate(true)
	return CONTRACTS[0].duplicate(true)


static func proof_level(depth: int) -> Dictionary:
	if depth < 0 or depth >= PROOF_LEVELS.size():
		return {}
	return PROOF_LEVELS[depth].duplicate(true)


static func proof_modifiers(depth: int) -> Dictionary:
	var result := {
		"enemy_health": 1.0,
		"enemy_damage": 1.0,
		"enemy_speed": 1.0,
		"player_health": 1.0,
		"dash_cooldown": 1.0,
		"spawn_interval": 1.0,
		"enemy_cap": 1.0,
		"recovery": 1.0,
		"elite_bonus": 0.0,
		"boss_health": 1.0,
		"wave_duration": 1.0,
		"score": 1.0,
		"shards": 1.0,
	}
	for level in range(1, clampi(depth, 0, PROOF_LEVELS.size() - 1) + 1):
		var clause: Dictionary = PROOF_LEVELS[level]
		for key in ["enemy_health", "enemy_damage", "enemy_speed", "player_health", "dash_cooldown", "spawn_interval", "enemy_cap", "recovery", "boss_health", "wave_duration", "score", "shards"]:
			result[key] = float(result[key]) * float(clause.get(key, 1.0))
		result["elite_bonus"] = float(result["elite_bonus"]) + float(clause.get("elite_bonus", 0.0))
	return result


static func valid_daily_id(date_id: String) -> bool:
	if date_id.length() != 10 or date_id[4] != "-" or date_id[7] != "-":
		return false
	var digits := date_id.replace("-", "")
	if not digits.is_valid_int():
		return false
	var year := int(date_id.substr(0, 4))
	var month := int(date_id.substr(5, 2))
	var day := int(date_id.substr(8, 2))
	return year >= 2020 and month >= 1 and month <= 12 and day >= 1 and day <= 31


static func daily_seed(date_id: String) -> int:
	if not valid_daily_id(date_id):
		return 1
	var hash_value := 2166136261
	for index in range(date_id.length()):
		hash_value = ((hash_value ^ date_id.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(1, hash_value)


static func daily_recipe(date_id: String) -> Dictionary:
	var clean_id := date_id if valid_daily_id(date_id) else "2020-01-01"
	var seed_value := daily_seed(clean_id)
	var contract_data: Dictionary = CONTRACTS[seed_value % CONTRACTS.size()]
	return {
		"id": clean_id,
		"seed": seed_value,
		"contract_id": str(contract_data["id"]),
		"contract_name": str(contract_data["name"]),
		"contract_description": str(contract_data["description"]),
		"difficulty": "standard",
		"starting_weapon": "marginalia",
		"proof_depth": 0,
		"first_clear_bonus": DAILY_CLEAR_BONUS,
	}


static func progression_unlock(unlock_id: String) -> Dictionary:
	for entry in PROGRESSION_UNLOCKS:
		if entry["id"] == unlock_id:
			return entry.duplicate(true)
	return {}


static func event(event_id: String) -> Dictionary:
	for entry in EVENTS:
		if entry["id"] == event_id:
			return entry.duplicate(true)
	return {}


static func directive(directive_id: String) -> Dictionary:
	for entry in PAGE_DIRECTIVES:
		if entry["id"] == directive_id:
			return entry.duplicate(true)
	return {}


static func squad(squad_id: String) -> Dictionary:
	for entry in ENCOUNTER_SQUADS:
		if entry["id"] == squad_id:
			return entry.duplicate(true)
	return {}


static func events_for_chapter(chapter: int, excluded: Array[String] = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for entry in EVENTS:
		if int(entry["chapter"]) == chapter and entry["id"] not in excluded:
			available.append(entry.duplicate(true))
	return available


static func directives_for_chapter(chapter: int, excluded: Array[String] = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for entry in PAGE_DIRECTIVES:
		if int(entry["chapter"]) == chapter and entry["id"] not in excluded:
			available.append(entry.duplicate(true))
	return available


static func squads_for_chapter(chapter: int, excluded: Array[String] = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for entry in ENCOUNTER_SQUADS:
		if int(entry["chapter"]) == chapter and entry["id"] not in excluded:
			available.append(entry.duplicate(true))
	return available


static func available_upgrades(stacks: Dictionary, level: int, unlocked_weapon_forms: Array[String]) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var owns_weapon_form := false
	for weapon_id in ["greatbrush", "needlepoint", "seal-caster", "twin-stroke"]:
		if int(stacks.get(weapon_id, 0)) > 0:
			owns_weapon_form = true
	for entry in UPGRADES:
		var current := int(stacks.get(entry["id"], 0))
		var is_locked_weapon: bool = owns_weapon_form and "weapon" in entry["tags"]
		var is_progression_locked: bool = "weapon" in entry["tags"] and entry["id"] not in unlocked_weapon_forms
		if not is_locked_weapon and not is_progression_locked and current < int(entry["max_stacks"]) and level >= int(entry["min_level"]):
			available.append(entry.duplicate(true))
	return available
