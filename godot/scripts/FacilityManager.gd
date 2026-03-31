extends Node

signal facilities_updated

const _FACILITY_TEMPLATES: Array = [
	{
		"id": "coffee_machine",
		"name": "Coffee Machine",
		"description": "Keeps the team caffeinated and alert.",
		"cost": 500,
		"category": "break",
		"tile_w": 1,
		"tile_h": 1,
		"stat_buff": {"morale": 3},
		"placed": false
	},
	{
		"id": "ergonomic_desk",
		"name": "Ergonomic Desk",
		"description": "Reduces back pain and boosts focus.",
		"cost": 800,
		"category": "office",
		"tile_w": 1,
		"tile_h": 1,
		"stat_buff": {"focus": 5},
		"placed": false
	},
	{
		"id": "company_library",
		"name": "Company Library",
		"description": "Knowledge at your fingertips.",
		"cost": 1200,
		"category": "office",
		"tile_w": 1,
		"tile_h": 2,
		"stat_buff": {"focus": 8},
		"placed": false
	},
	{
		"id": "meeting_room",
		"name": "Meeting Room",
		"description": "Where decisions get made.",
		"cost": 2000,
		"category": "office",
		"tile_w": 2,
		"tile_h": 2,
		"stat_buff": {"management": 10, "project_speed": 10},
		"placed": false
	},
	{
		"id": "break_room",
		"name": "Break Room",
		"description": "Rest and recharge between tasks.",
		"cost": 1500,
		"category": "break",
		"tile_w": 1,
		"tile_h": 2,
		"stat_buff": {"morale": 8},
		"placed": false
	},
	{
		"id": "server_room",
		"name": "Server Room",
		"description": "Raw computational power for tech projects.",
		"cost": 3000,
		"category": "tech",
		"tile_w": 2,
		"tile_h": 2,
		"stat_buff": {"tech_speed": 20},
		"placed": false
	},
	{
		"id": "training_room",
		"name": "Training Room",
		"description": "Accelerates skill growth across the board.",
		"cost": 2500,
		"category": "office",
		"tile_w": 2,
		"tile_h": 2,
		"stat_buff": {"skill_growth": 15},
		"placed": false
	},
	{
		"id": "hr_office",
		"name": "HR Office",
		"description": "Keeps morale high and drama low.",
		"cost": 1800,
		"category": "office",
		"tile_w": 1,
		"tile_h": 2,
		"stat_buff": {"morale": 5, "drama": -20},
		"placed": false
	},
	{
		"id": "executive_suite",
		"name": "Executive Suite",
		"description": "Commands respect and raises your reputation.",
		"cost": 4000,
		"category": "executive",
		"tile_w": 2,
		"tile_h": 2,
		"stat_buff": {"reputation": 10},
		"placed": false
	},
	{
		"id": "rooftop_terrace",
		"name": "Rooftop Terrace",
		"description": "A view that lifts everyone's spirits.",
		"cost": 6000,
		"category": "break",
		"tile_w": 4,
		"tile_h": 4,
		"stat_buff": {"morale": 20},
		"placed": false
	}
]

const _COMBOS: Array = [
	{
		"id": "gossip_hub",
		"name": "Gossip Hub",
		"requires": ["break_room", "coffee_machine"],
		"bonus_desc": "MOT +5, Charm +3",
		"bonus": {"morale": 5, "charm": 3}
	},
	{
		"id": "focus_zone",
		"name": "Focus Zone",
		"requires": ["company_library", "ergonomic_desk"],
		"bonus_desc": "Focus +8",
		"bonus": {"focus": 8}
	},
	{
		"id": "tech_power",
		"name": "Tech Power",
		"requires": ["server_room", "training_room"],
		"bonus_desc": "Tech Speed +15%",
		"bonus": {"tech_speed": 15}
	},
	{
		"id": "executive_presence",
		"name": "Executive Presence",
		"requires": ["executive_suite", "meeting_room"],
		"bonus_desc": "Reputation +8",
		"bonus": {"reputation": 8}
	},
	{
		"id": "wellness_center",
		"name": "Wellness Center",
		"requires": ["break_room", "rooftop_terrace"],
		"bonus_desc": "MOT +10, Burnout Rate -25%",
		"bonus": {"morale": 10, "burnout_rate": -25}
	}
]

var facilities: Array = []
var active_combos: Array[String] = []

func _ready() -> void:
	for template in _FACILITY_TEMPLATES:
		facilities.append(template.duplicate())

# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────
func place_facility(id: String, gm: Node) -> bool:
	for i in range(facilities.size()):
		var f: Dictionary = facilities[i]
		if f["id"] != id:
			continue
		if f["placed"]:
			return false
		var cost: int = f["cost"]
		if gm.economy.current_cash < cost:
			return false
		var spent: bool = gm.economy.spend(cost, "Facility: " + f["name"])
		if not spent:
			return false
		facilities[i]["placed"] = true
		var buff: Dictionary = f["stat_buff"]
		if buff.has("reputation"):
			var rep: int = gm.company_data.get("reputation", 0)
			gm.company_data["reputation"] = clampi(rep + int(buff["reputation"]), 0, 1000)
		check_combos()
		facilities_updated.emit()
		return true
	return false

func get_active_buffs() -> Dictionary:
	var result: Dictionary = {}
	for f in facilities:
		if not f["placed"]:
			continue
		for key in f["stat_buff"]:
			var val: int = int(f["stat_buff"][key])
			if result.has(key):
				result[key] = int(result[key]) + val
			else:
				result[key] = val
	for combo_id in active_combos:
		for combo in _COMBOS:
			if combo["id"] != combo_id:
				continue
			for key in combo["bonus"]:
				var val: int = int(combo["bonus"][key])
				if result.has(key):
					result[key] = int(result[key]) + val
				else:
					result[key] = val
	return result

func check_combos() -> void:
	active_combos.clear()
	var placed_ids: Array[String] = []
	for f in facilities:
		if f["placed"]:
			placed_ids.append(f["id"])
	for combo in _COMBOS:
		var reqs: Array = combo["requires"]
		var all_placed: bool = true
		for req_id in reqs:
			if not placed_ids.has(req_id):
				all_placed = false
				break
		if all_placed:
			active_combos.append(combo["id"])

func get_combos() -> Array:
	return _COMBOS
