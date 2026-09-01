extends SceneTree

const Content = preload("res://scripts/content_db.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PlayerWaveScript = preload("res://scripts/player_wave.gd")
const EXPECTED_ROWS := 432
const MIN_ATTACK_PERIOD := 0.10
const MAX_ATTACK_PERIOD := 0.70
const MIN_ENCOUNTER_TTK := 4.5
const MAX_ENCOUNTER_TTK := 48.0
const MIN_SURVIVAL_HITS := 1.0
const MAX_BUILD_DPS_RATIO := 3.2
const COMBAT_UPTIME := 0.55

const PROFILES := [
	{
		"id": "greatbrush-guard",
		"form": "GREATBRUSH",
		"upgrades": ["razor-ink", "razor-ink", "razor-ink", "razor-ink", "wide-panel", "wide-panel", "rapid-stroke", "rapid-stroke", "overflow", "paper-armor", "paper-armor", "greatbrush"],
		"relics": ["broken-mask", "paper-heart"],
	},
	{
		"id": "needle-critical",
		"form": "NEEDLEPOINT",
		"upgrades": ["razor-ink", "razor-ink", "rapid-stroke", "rapid-stroke", "rapid-stroke", "rapid-stroke", "red-thread", "red-thread", "red-thread", "critical-echo", "critical-echo", "needlepoint"],
		"relics": ["red-pencil", "glass-nib"],
	},
	{
		"id": "seal-wave",
		"form": "SEAL-CASTER",
		"upgrades": ["razor-ink", "razor-ink", "razor-ink", "rapid-stroke", "rapid-stroke", "ink-wave", "ink-wave", "ink-wave", "returning-stroke", "splinter-script", "splinter-script", "seal-caster"],
		"relics": ["wax-seal", "first-draft"],
	},
	{
		"id": "twin-status",
		"form": "TWIN-STROKE",
		"upgrades": ["razor-ink", "razor-ink", "razor-ink", "rapid-stroke", "rapid-stroke", "rapid-stroke", "red-thread", "bleeding-letters", "bleeding-letters", "dash-nova", "crescendo", "twin-stroke"],
		"relics": ["binder-chain", "first-draft"],
	},
]

const DIFFICULTIES := ["story", "standard", "redline"]
const FINAL_ACT_ROUTES := ["white-room", "red-press", "loose-leaves"]
const PROOF_DEPTHS := [0, 10]

var started := false
var packed: PackedScene


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	_run_matrix()
	return false


func _run_matrix() -> void:
	var loaded = load("res://scenes/main.tscn")
	if loaded == null or not (loaded is PackedScene):
		_fail(["main scene did not load"])
		return
	packed = loaded
	var failures: Array[String] = []
	_validate_profiles(failures)
	_validate_returning_wave(failures)
	var rows: Array[Dictionary] = []
	var environment_dps := {}
	var min_ttk := INF
	var max_ttk := 0.0
	var min_survival := INF
	var min_dps := INF
	var max_dps := 0.0

	for proof_depth in PROOF_DEPTHS:
		for difficulty_id in DIFFICULTIES:
			for contract_data in Content.CONTRACTS:
				var contract_id: String = contract_data["id"]
				for route_id in FINAL_ACT_ROUTES:
					var environment_id := "proof%d/%s/%s/%s" % [proof_depth, difficulty_id, contract_id, route_id]
					environment_dps[environment_id] = []
					for profile in PROFILES:
						var row := _measure_row(profile, difficulty_id, contract_id, route_id, proof_depth)
						rows.append(row)
						environment_dps[environment_id].append(float(row["boss_dps"]))
						min_ttk = minf(min_ttk, float(row["encounter_ttk_seconds"]))
						max_ttk = maxf(max_ttk, float(row["encounter_ttk_seconds"]))
						min_survival = minf(min_survival, float(row["survival_hits"]))
						min_dps = minf(min_dps, float(row["boss_dps"]))
						max_dps = maxf(max_dps, float(row["boss_dps"]))
						_validate_row(row, failures)

	var worst_ratio := 0.0
	for environment_id in environment_dps:
		var values: Array = environment_dps[environment_id]
		var environment_min: float = values.min()
		var environment_max: float = values.max()
		var ratio := environment_max / maxf(0.001, environment_min)
		worst_ratio = maxf(worst_ratio, ratio)
		if ratio > MAX_BUILD_DPS_RATIO:
			failures.append("%s build DPS ratio %.2f exceeds %.2f" % [environment_id, ratio, MAX_BUILD_DPS_RATIO])

	if rows.size() != EXPECTED_ROWS:
		failures.append("matrix produced %d rows instead of %d" % [rows.size(), EXPECTED_ROWS])
	if min_ttk < MIN_ENCOUNTER_TTK:
		failures.append("minimum final-boss encounter TTK %.2fs is below %.2fs" % [min_ttk, MIN_ENCOUNTER_TTK])
	if max_ttk > MAX_ENCOUNTER_TTK:
		failures.append("maximum final-boss encounter TTK %.2fs exceeds %.2fs" % [max_ttk, MAX_ENCOUNTER_TTK])
	if min_survival < MIN_SURVIVAL_HITS:
		failures.append("minimum survival %.2f hits is below %.2f" % [min_survival, MIN_SURVIVAL_HITS])

	var report := {
		"schema": 2,
		"profiles": PROFILES.size(),
		"difficulties": DIFFICULTIES.size(),
		"contracts": Content.CONTRACTS.size(),
		"final_act_routes": FINAL_ACT_ROUTES.size(),
		"proof_depths": PROOF_DEPTHS,
		"rows": rows,
		"summary": {
			"min_boss_dps": min_dps,
			"max_boss_dps": max_dps,
			"min_encounter_ttk_seconds": min_ttk,
			"max_encounter_ttk_seconds": max_ttk,
			"min_survival_hits": min_survival,
			"worst_build_dps_ratio": worst_ratio,
		},
		"failures": failures,
	}
	_write_report(report)
	print("INKBOUND_BALANCE_SUMMARY rows=%d dps=%.1f..%.1f ttk=%.2f..%.2f survival_min=%.2f ratio=%.2f" % [rows.size(), min_dps, max_dps, min_ttk, max_ttk, min_survival, worst_ratio])
	if not failures.is_empty():
		_fail(failures)
		return
	print("INKBOUND_BALANCE_OK profiles=%d environments=%d proof=0/10 rows=%d report=res://build/balance/balance-report.json" % [PROFILES.size(), PROOF_DEPTHS.size() * DIFFICULTIES.size() * Content.CONTRACTS.size() * FINAL_ACT_ROUTES.size(), rows.size()])
	paused = false
	quit(0)


func _measure_row(profile: Dictionary, difficulty_id: String, contract_id: String, route_id: String, selected_proof_depth: int) -> Dictionary:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("balance_matrix")
	game.debug_clear_save_files()
	game.max_proof_depth = selected_proof_depth
	root.add_child(game)
	game.debug_set_rng_seed(515151)
	game.lifetime_runs = 10
	game.highest_wave = 12
	game.lifetime_kills = 100
	game.completed_endings.assign(["keep"])
	game.contract_wins = {"open-draft": 1, "quick-edition": 1, "living-margins": 1}
	game._on_start_requested(difficulty_id, contract_id, "marginalia", selected_proof_depth)
	game._activate_route(route_id)
	for upgrade_id in profile["upgrades"]:
		game.player.apply_upgrade(upgrade_id)
	for relic_id in profile["relics"]:
		game.player.apply_relic(relic_id)

	var player = game.player
	var author = EnemyScript.new().configure("author", player, 12)
	author.max_health *= game.difficulty_health * game.contract_enemy_health * game.route_enemy_health * game.proof_enemy_health * game.proof_boss_health
	author.health = author.max_health
	author.contact_damage *= game.difficulty_damage * game.contract_enemy_damage * game.route_enemy_damage * game.proof_enemy_damage
	var critical_chance: float = clampf(player.critical_chance, 0.0, 1.0)
	if player.guaranteed_crit_every > 0:
		critical_chance += (1.0 - critical_chance) / float(player.guaranteed_crit_every)
	var critical_hit_multiplier: float = 2.0 + player.critical_damage_bonus
	var expected_hit_multiplier: float = (1.0 - critical_chance) + critical_chance * critical_hit_multiplier * (1.0 + float(player.critical_echo))
	var form_multiplier: float = 1.55 if player.weapon_form == "TWIN-STROKE" else 1.0
	var combo_speed: float = 1.25 if player.combo_power > 0.0 else 1.0
	var direct_dps: float = player.damage * form_multiplier * (1.0 + player.boss_damage_bonus) * expected_hit_multiplier * combo_speed / player.attack_period
	var wave_dps: float = 0.0
	if player.wave_every > 0:
		var return_multiplier := 2.0 if player.wave_returns else 1.0
		wave_dps = player.damage * player.wave_damage_factor * return_multiplier / (float(player.wave_every) * player.attack_period)
	var attacks_in_bleed_window: float = 3.0 / float(player.attack_period)
	var bleed_dps: float = minf(3.0, player.bleed_power * attacks_in_bleed_window) / 0.35
	var burn_uptime: float = minf(1.0, critical_chance * 2.2 / float(player.attack_period))
	var burn_dps: float = player.burn_power * burn_uptime / 0.35
	var dash_dps: float = player.dash_nova_damage * 0.35 / maxf(0.1, player.dash_cooldown_max)
	var boss_dps: float = direct_dps + wave_dps + bleed_dps + burn_dps + dash_dps
	var encounter_ttk: float = float(author.max_health) / maxf(0.001, boss_dps * COMBAT_UPTIME)
	var incoming_per_hit: float = author.contact_damage * (1.0 - clampf(player.damage_reduction, 0.0, 0.72))
	var survival_hits: float = (player.max_health + player.guard) / maxf(0.001, incoming_per_hit)
	var row := {
		"profile": profile["id"],
		"weapon_form": player.weapon_form,
		"difficulty": difficulty_id,
		"contract": contract_id,
		"route": route_id,
		"proof_depth": selected_proof_depth,
		"damage": player.damage,
		"attack_period": player.attack_period,
		"critical_chance": critical_chance,
		"max_health": player.max_health,
		"damage_reduction": player.damage_reduction,
		"author_health": author.max_health,
		"author_contact_damage": author.contact_damage,
		"direct_dps": direct_dps,
		"wave_dps": wave_dps,
		"status_dps": bleed_dps + burn_dps,
		"dash_dps": dash_dps,
		"boss_dps": boss_dps,
		"encounter_ttk_seconds": encounter_ttk,
		"survival_hits": survival_hits,
	}
	author.free()
	game.free()
	return row


func _validate_profiles(failures: Array[String]) -> void:
	var seen_forms: Array[String] = []
	for profile in PROFILES:
		if profile["upgrades"].size() != 12:
			failures.append("%s does not contain exactly 12 upgrades" % profile["id"])
		var stacks := {}
		for upgrade_id in profile["upgrades"]:
			var upgrade: Dictionary = Content.upgrade(upgrade_id)
			if upgrade.is_empty():
				failures.append("%s references missing upgrade %s" % [profile["id"], upgrade_id])
				continue
			stacks[upgrade_id] = int(stacks.get(upgrade_id, 0)) + 1
			if int(stacks[upgrade_id]) > int(upgrade["max_stacks"]):
				failures.append("%s exceeds max stacks for %s" % [profile["id"], upgrade_id])
		for relic_id in profile["relics"]:
			if Content.relic(relic_id).is_empty():
				failures.append("%s references missing relic %s" % [profile["id"], relic_id])
		seen_forms.append(profile["form"])
	for required_form in ["GREATBRUSH", "NEEDLEPOINT", "SEAL-CASTER", "TWIN-STROKE"]:
		if required_form not in seen_forms:
			failures.append("missing representative profile for %s" % required_form)


func _validate_returning_wave(failures: Array[String]) -> void:
	var game = packed.instantiate()
	game.test_mode = true
	game.debug_set_save_namespace("balance_wave_probe")
	game.debug_clear_save_files()
	root.add_child(game)
	game.debug_set_rng_seed(616161)
	var target_enemy: Node2D
	for candidate in get_nodes_in_group("enemies"):
		if candidate.get_parent() == game:
			target_enemy = candidate
			break
	if not is_instance_valid(target_enemy):
		failures.append("returning-wave probe could not find a target")
		game.free()
		return
	var wave = PlayerWaveScript.new().setup(target_enemy.global_position - Vector2.RIGHT * (245.0 / 60.0), Vector2.RIGHT, 1.0, 0, 0, true)
	game.add_child(wave)
	wave._physics_process(1.0 / 60.0)
	if wave.is_queued_for_deletion() or not wave.waiting_to_return:
		failures.append("returning stroke was destroyed by its outbound hit")
	else:
		wave._physics_process(0.62)
		if not wave.has_returned or wave.waiting_to_return or wave.direction != Vector2.LEFT:
			failures.append("returning stroke did not reverse after its outbound hit")
	game.free()


func _validate_row(row: Dictionary, failures: Array[String]) -> void:
	var row_id := "%s/proof%d/%s/%s/%s" % [row["profile"], int(row["proof_depth"]), row["difficulty"], row["contract"], row["route"]]
	if row["weapon_form"] != _profile_form(str(row["profile"])):
		failures.append("%s did not activate its weapon form" % row_id)
	var attack_period := float(row["attack_period"])
	if attack_period < MIN_ATTACK_PERIOD or attack_period > MAX_ATTACK_PERIOD:
		failures.append("%s attack period %.3f is outside %.2f..%.2f" % [row_id, attack_period, MIN_ATTACK_PERIOD, MAX_ATTACK_PERIOD])
	if float(row["boss_dps"]) <= 0.0 or not is_finite(float(row["boss_dps"])):
		failures.append("%s produced invalid boss DPS" % row_id)
	if float(row["author_health"]) <= 0.0 or float(row["author_contact_damage"]) <= 0.0:
		failures.append("%s produced invalid final boss stats" % row_id)


func _profile_form(profile_id: String) -> String:
	for profile in PROFILES:
		if profile["id"] == profile_id:
			return profile["form"]
	return ""


func _write_report(report: Dictionary) -> void:
	var directory := ProjectSettings.globalize_path("res://build/balance")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open("res://build/balance/balance-report.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.flush()


func _fail(messages: Array[String]) -> void:
	var preview := messages.slice(0, mini(8, messages.size()))
	push_error("INKBOUND_BALANCE_FAIL: " + " | ".join(preview))
	Engine.time_scale = 1.0
	paused = false
	quit(1)
