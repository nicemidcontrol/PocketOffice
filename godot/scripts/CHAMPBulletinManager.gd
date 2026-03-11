extends Node

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal bulletin_fired(bulletin_data: Dictionary)
signal bulletin_expired(bulletin_id: String)

# ------------------------------------------
#  BULLETIN DEFINITIONS  (10 events)
# ------------------------------------------
const BULLETINS: Array = [
	{
		"id": "low_rainfall",
		"headline": "CHAMP AgriWeather: Rainfall 60% below average this season",
		"category": "weather",
		"effect_type": "project_slow",
		"effect_value": 0.8,
		"affected_project_types": ["soil", "crop"],
		"duration_months": 2,
		"has_mitigation": true,
		"mitigation_options": [
			{
				"label": "Emergency Irrigation ($500)",
				"cost_type": "cash",
				"cost_value": 500,
				"effect_reduction_percent": 50
			}
		]
	},
	{
		"id": "flash_flood",
		"headline": "CHAMP DisasterWatch: Flash flooding forces project suspension",
		"category": "flood",
		"effect_type": "project_pause",
		"effect_value": 0.0,
		"affected_project_types": [],
		"duration_months": 1,
		"has_mitigation": true,
		"mitigation_options": [
			{
				"label": "Emergency Reroute (loses 2 weeks progress)",
				"cost_type": "progress",
				"cost_value": 0.25,
				"effect_reduction_percent": 100
			}
		]
	},
	{
		"id": "severe_drought",
		"headline": "CHAMP ClimateAlert: Severe drought conditions reduce irrigation by 30%",
		"category": "drought",
		"effect_type": "project_slow",
		"effect_value": 0.7,
		"affected_project_types": ["irrigation"],
		"duration_months": 3,
		"has_mitigation": false,
		"mitigation_options": []
	},
	{
		"id": "armed_conflict",
		"headline": "CHAMP SecurityAlert: Armed conflict disrupts field operations",
		"category": "conflict",
		"effect_type": "project_slow",
		"effect_value": 0.5,
		"affected_project_types": [],
		"duration_months": 2,
		"has_mitigation": true,
		"mitigation_options": [
			{
				"label": "Reroute Team (loses 2 weeks progress)",
				"cost_type": "progress",
				"cost_value": 0.25,
				"effect_reduction_percent": 100
			}
		]
	},
	{
		"id": "locust_swarm",
		"headline": "CHAMP AgriAlert: Locust swarm threatens crop projects",
		"category": "pest",
		"effect_type": "project_regress",
		"effect_value": -0.1,
		"affected_project_types": ["crop"],
		"duration_months": 1,
		"has_mitigation": false,
		"mitigation_options": []
	},
	{
		"id": "bridge_collapse",
		"headline": "CHAMP Infrastructure: Bridge collapse impacts logistics operations",
		"category": "infrastructure",
		"effect_type": "project_slow",
		"effect_value": 0.75,
		"affected_project_types": ["logistics"],
		"duration_months": 2,
		"has_mitigation": false,
		"mitigation_options": []
	},
	{
		"id": "disease_outbreak",
		"headline": "CHAMP HealthWatch: Disease outbreak affects field personnel",
		"category": "disease",
		"effect_type": "project_slow",
		"effect_value": 0.85,
		"affected_project_types": ["charm"],
		"duration_months": 2,
		"has_mitigation": true,
		"mitigation_options": [
			{
				"label": "Hire Temp Contractor ($300)",
				"cost_type": "cash",
				"cost_value": 300,
				"effect_reduction_percent": 100
			}
		]
	},
	{
		"id": "funding_freeze",
		"headline": "CHAMP FinanceAlert: Donor funding freeze suspends cash income",
		"category": "funding",
		"effect_type": "cash_freeze",
		"effect_value": 0.0,
		"affected_project_types": [],
		"duration_months": 1,
		"has_mitigation": false,
		"mitigation_options": []
	},
	{
		"id": "unexpected_rains",
		"headline": "CHAMP AgriWeather: Unexpected rainfall boosts crop project yields",
		"category": "positive_weather",
		"effect_type": "project_boost",
		"effect_value": 1.1,
		"affected_project_types": ["crop"],
		"duration_months": 1,
		"has_mitigation": false,
		"mitigation_options": []
	},
	{
		"id": "pr_coverage",
		"headline": "CHAMP MediaWatch: Major PR coverage boosts organization reputation",
		"category": "positive_pr",
		"effect_type": "reputation_gain",
		"effect_value": 15.0,
		"affected_project_types": [],
		"duration_months": 1,
		"has_mitigation": false,
		"mitigation_options": []
	}
]

const _SEVERE_CATEGORIES: Array   = ["flood", "conflict", "drought"]
const _POSITIVE_CATEGORIES: Array = ["positive_weather", "positive_pr"]

# ------------------------------------------
#  STATE
# ------------------------------------------
var active_bulletins: Array           = []
var _rng: RandomNumberGenerator       = RandomNumberGenerator.new()
var _severe_count_this_quarter: int   = 0
var _current_quarter: int             = -1

# ------------------------------------------
#  INIT
# ------------------------------------------
func _ready() -> void:
	_rng.randomize()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.month_passed.connect(_on_month_passed)

# ------------------------------------------
#  MONTHLY UPDATE
# ------------------------------------------
func _on_month_passed(month: int) -> void:
	# Reset severe quota at the start of each quarter
	var new_quarter: int = (month - 1) / 3
	if new_quarter != _current_quarter:
		_current_quarter = new_quarter
		_severe_count_this_quarter = 0

	# Decrement durations, expire finished bulletins
	var i: int = active_bulletins.size() - 1
	while i >= 0:
		active_bulletins[i]["months_remaining"] = active_bulletins[i].get("months_remaining", 1) - 1
		if active_bulletins[i].get("months_remaining", 0) <= 0:
			var bid: String = active_bulletins[i].get("id", "")
			active_bulletins.remove_at(i)
			bulletin_expired.emit(bid)
		i -= 1

	# Fire 1-2 new bulletins this month
	var count: int = _rng.randi_range(1, 2)
	for _n: int in range(count):
		_try_fire_bulletin()

	# Apply instant effects (reputation_gain, morale_drop)
	_apply_instant_effects()

func _try_fire_bulletin() -> void:
	var want_positive: bool = _rng.randf() < 0.2
	var pool: Array = []
	for b in BULLETINS:
		var cat: String = b.get("category", "")
		var is_positive: bool = cat in _POSITIVE_CATEGORIES
		if is_positive != want_positive:
			continue
		# Enforce severe-per-quarter cap
		var is_severe: bool = cat in _SEVERE_CATEGORIES
		if is_severe and _severe_count_this_quarter >= 1:
			continue
		# No duplicate active bulletins
		var already: bool = false
		for ab in active_bulletins:
			if ab.get("id", "") == b.get("id", ""):
				already = true
				break
		if not already:
			pool.append(b)
	if pool.is_empty():
		return
	var chosen: Dictionary = pool[_rng.randi() % pool.size()]
	var inst: Dictionary = chosen.duplicate(true)
	inst["months_remaining"] = chosen.get("duration_months", 1)
	inst["_instant_applied"] = false
	active_bulletins.append(inst)
	if chosen.get("category", "") in _SEVERE_CATEGORIES:
		_severe_count_this_quarter += 1
	bulletin_fired.emit(inst)

func _apply_instant_effects() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	for b in active_bulletins:
		if b.get("_instant_applied", false):
			continue
		match b.get("effect_type", ""):
			"reputation_gain":
				var rep: int = gm.company_data.get("reputation", 0)
				gm.company_data["reputation"] = clampi(rep + int(b.get("effect_value", 0.0)), 0, 1000)
				b["_instant_applied"] = true
			"morale_drop":
				for emp in gm.employees.get_hired_employees():
					emp.adjust_motivation(-int(b.get("effect_value", 0.0)))
				b["_instant_applied"] = true

# ------------------------------------------
#  PUBLIC QUERY API (used by ProjectManager)
# ------------------------------------------
func get_active_bulletins() -> Array:
	return active_bulletins.duplicate(true)

# Returns the combined speed multiplier for a given project type.
# project_regress effect_value is negative (e.g. -0.1 => 0.9x speed).
func get_project_speed_multiplier(project_type: String) -> float:
	var mult: float = 1.0
	for b in active_bulletins:
		var affected: Array = b.get("affected_project_types", [])
		if not affected.is_empty() and project_type not in affected:
			continue
		match b.get("effect_type", ""):
			"project_slow":
				mult *= b.get("effect_value", 1.0)
			"project_boost":
				mult *= b.get("effect_value", 1.0)
			"project_regress":
				mult *= (1.0 + b.get("effect_value", 0.0))
			"project_pause":
				return 0.0
	return mult

# Returns the headline of the first bulletin currently pausing this project type,
# or an empty string if no pause is active.
func get_pause_headline(project_type: String) -> String:
	for b in active_bulletins:
		if b.get("effect_type", "") != "project_pause":
			continue
		var affected: Array = b.get("affected_project_types", [])
		if affected.is_empty() or project_type in affected:
			return b.get("headline", "PAUSED")
	return ""

# Returns true if a funding_freeze bulletin is currently active.
func is_cash_frozen() -> bool:
	for b in active_bulletins:
		if b.get("effect_type", "") == "cash_freeze":
			return true
	return false

# ------------------------------------------
#  MITIGATION
# ------------------------------------------
func apply_mitigation(bulletin_id: String, mitigation_idx: int) -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return false
	for b in active_bulletins:
		if b.get("id", "") != bulletin_id:
			continue
		if not b.get("has_mitigation", false):
			return false
		var opts: Array = b.get("mitigation_options", [])
		if mitigation_idx >= opts.size():
			return false
		var opt: Dictionary = opts[mitigation_idx]
		var cost_type: String = opt.get("cost_type", "cash")
		var cost_val: int     = int(opt.get("cost_value", 0))
		var reduction: float  = opt.get("effect_reduction_percent", 0.0)
		match cost_type:
			"cash":
				gm.economy.spend(cost_val, "CHAMP Bulletin Mitigation")
			"cp":
				if gm.corp_points < cost_val:
					return false
				gm.corp_points -= cost_val
				gm.corp_points_changed.emit(gm.corp_points)
			"progress":
				# Progress cost is applied project-side; nothing to spend here
				pass
		# Reduce effect severity
		var eff: float = b.get("effect_value", 1.0)
		var new_eff: float
		if b.get("effect_type", "") == "project_pause":
			# Full mitigation: change to a mild slow instead of pause
			b["effect_type"] = "project_slow"
			new_eff = 1.0 - (1.0 - 0.75) * (1.0 - reduction / 100.0)
		else:
			new_eff = eff + (1.0 - eff) * (reduction / 100.0)
		b["effect_value"]   = new_eff
		b["has_mitigation"] = false
		return true
	return false
