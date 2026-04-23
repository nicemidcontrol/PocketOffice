extends Node

# ─────────────────────────────────────────
#  TRAINING DATA
# ─────────────────────────────────────────
const TRAININGS: Array = [
	{
		"id": "basic_workshop",
		"name": "Basic Workshop",
		"tier": 1,
		"cp_cost": 7,
		"stats": {"technical": 30, "morale": 3, "management": 30},
		"double_stat": "",
		"unlock": "start"
	},
	{
		"id": "focus_training",
		"name": "Focus Training",
		"tier": 1,
		"cp_cost": 7,
		"stats": {"focus": 40, "morale": 4, "management": 20},
		"double_stat": "",
		"unlock": "start"
	},
	{
		"id": "advanced_seminar",
		"name": "Advanced Seminar",
		"tier": 2,
		"cp_cost": 14,
		"stats": {"technical": 50, "focus": 50, "management": 50},
		"double_stat": "role_primary",
		"unlock": "donor:local_ngo"
	},
	{
		"id": "wellness_retreat",
		"name": "Wellness Retreat",
		"tier": 2,
		"cp_cost": 14,
		"stats": {"morale": 8, "management": 40, "technical": 30},
		"double_stat": "",
		"unlock": "year:2"
	},
	{
		"id": "leadership_bootcamp",
		"name": "Leadership Bootcamp",
		"tier": 3,
		"cp_cost": 21,
		"stats": {"management": 100, "morale": 5, "technical": 30},
		"double_stat": "role_primary",
		"unlock": "year:3"
	},
	{
		"id": "executive_program",
		"name": "Executive Program",
		"tier": 3,
		"cp_cost": 21,
		"stats": {"technical": 80, "focus": 60, "management": 60, "morale": 6},
		"double_stat": "role_primary",
		"unlock": "donor:government_agency"
	}
]

const TRAINING_COMBOS: Array = [
	{
		"id": "field_team",
		"name": "Field Team",
		"requires_roles": ["OPERATIONS", "PROCUREMENT", "OPERATIONS"],
		"bonus_desc": "Logistics +50 for all 3 members",
		"bonus": {"logistics": 50}
	},
	{
		"id": "office_core",
		"name": "Office Core",
		"requires_roles": ["MANAGEMENT", "FINANCE", "SECRETARY"],
		"bonus_desc": "+10 EXP for all 3 members",
		"bonus": {"exp": 10}
	},
	{
		"id": "all_hands",
		"name": "All Hands",
		"requires_roles": ["OPERATIONS", "FINANCE", "MANAGEMENT"],
		"bonus_desc": "Technical +20, Focus +20 for all 3 members",
		"bonus": {"technical": 20, "focus": 20}
	},
	{
		"id": "data_squad",
		"name": "Data Squad",
		"requires_roles": ["FINANCE", "OPERATIONS", "PROCUREMENT"],
		"bonus_desc": "Technical +50 for all 3 members",
		"bonus": {"technical": 50}
	},
	{
		"id": "comms_front",
		"name": "Comms Front",
		"requires_roles": ["SECRETARY", "MANAGEMENT", "OPERATIONS"],
		"bonus_desc": "Morale +5 and Focus +30 for all 3 members",
		"bonus": {"morale": 5, "focus": 30}
	},
	{
		"id": "compliance_team",
		"name": "Compliance Team",
		"requires_roles": ["FINANCE", "PROCUREMENT", "MANAGEMENT"],
		"bonus_desc": "Reputation +5 for company",
		"bonus": {"reputation": 5}
	}
]

# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────
func get_available_trainings(gm: Node) -> Array:
	var result: Array = []
	var dm: Node = gm.get_node_or_null("/root/DonorManager")
	var game_year: int = gm.game_year
	for t in TRAININGS:
		var unlock: String = t.get("unlock", "start")
		if unlock == "start":
			result.append(t)
		elif unlock.begins_with("donor:"):
			var donor_id: String = unlock.substr(6)
			if dm != null and dm.won_donors.has(donor_id):
				result.append(t)
		elif unlock.begins_with("year:"):
			var req_year: int = int(unlock.substr(5))
			if game_year >= req_year:
				result.append(t)
	return result

func get_total_cp_cost(training: Dictionary, emp_count: int,
		_employees: Array, _discovered_combos: Array) -> int:
	return training.get("cp_cost", 7) * emp_count

func check_combo(employees: Array) -> Dictionary:
	for combo in TRAINING_COMBOS:
		if _check_combo_match(combo, employees):
			return combo
	return {}

func apply_training(training: Dictionary, employees: Array,
		gm: Node, discovered_combos: Array) -> Array:
	var results: Array = []
	var matched_combo: Dictionary = check_combo(employees)
	for emp in employees:
		var gained: Dictionary = {}
		var stats: Dictionary = training.get("stats", {})
		var double_key: String = ""
		if training.get("double_stat", "") == "role_primary":
			double_key = _role_primary_stat(emp)
		for stat_key in stats:
			var amount: int = stats[stat_key]
			if stat_key == double_key and double_key != "":
				amount = amount * 2
			match stat_key:
				"technical":
					emp.technical = mini(1000, emp.technical + amount)
				"procurement":
					emp.procurement = mini(1000, emp.procurement + amount)
				"focus":
					emp.focus = mini(1000, emp.focus + amount)
				"communication":
					emp.communication = mini(1000, emp.communication + amount)
				"management":
					emp.management = mini(1000, emp.management + amount)
				"logistics":
					emp.logistics = mini(1000, emp.logistics + amount)
				"precision":
					emp.precision = mini(1000, emp.precision + amount)
				"charm":
					emp.charm = mini(1000, emp.charm + amount)
				"morale":
					emp.morale = mini(100, emp.morale + amount)
			gained[stat_key] = amount
		if not matched_combo.is_empty():
			var bonus: Dictionary = matched_combo.get("bonus", {})
			if bonus.has("technical"):
				var b: int = int(bonus["technical"])
				emp.technical = mini(1000, emp.technical + b)
				gained["combo_technical"] = b
			if bonus.has("focus"):
				var b: int = int(bonus["focus"])
				emp.focus = mini(1000, emp.focus + b)
				gained["combo_focus"] = b
			if bonus.has("logistics"):
				var b: int = int(bonus["logistics"])
				emp.logistics = mini(1000, emp.logistics + b)
				gained["combo_logistics"] = b
			if bonus.has("morale"):
				var b: int = int(bonus["morale"])
				emp.morale = mini(100, emp.morale + b)
				gained["combo_morale"] = b
			if bonus.has("exp"):
				var b: int = int(bonus["exp"])
				emp.experience_points += b
				gained["combo_exp"] = b
			if bonus.has("reputation"):
				var rep_node: Node = get_node_or_null("/root/GameManager")
				if rep_node != null:
					rep_node.company_data["reputation"] = \
						rep_node.company_data.get("reputation", 0) + int(bonus["reputation"])
				gained["combo_rep"] = int(bonus["reputation"])
		results.append({"emp": emp, "gained": gained})
	return results

# ─────────────────────────────────────────
#  PRIVATE HELPERS
# ─────────────────────────────────────────
func _check_combo_match(combo: Dictionary, employees: Array) -> bool:
	var required: Array = combo.get("requires_roles", [])
	if employees.size() != required.size():
		return false
	var emp_roles: Array = []
	for e in employees:
		emp_roles.append(e.role_name())
	var req_copy: Array = required.duplicate()
	for er in emp_roles:
		var idx: int = req_copy.find(er)
		if idx == -1:
			return false
		req_copy.remove_at(idx)
	return true

func _role_primary_stat(emp: Object) -> String:
	var rn: String = emp.role_name()
	match rn:
		"OPERATIONS":  return "technical"
		"PROCUREMENT": return "procurement"
		"SECRETARY":   return "communication"
		"MANAGEMENT":  return "management"
		"FINANCE":     return "precision"
	return ""
