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
		"stats": {"skill": 3, "motivation": 3, "teamwork": 3},
		"double_stat": "",
		"unlock": "start"
	},
	{
		"id": "creative_boost",
		"name": "Creative Boost",
		"tier": 1,
		"cp_cost": 7,
		"stats": {"creativity": 4, "motivation": 4, "teamwork": 2},
		"double_stat": "",
		"unlock": "start"
	},
	{
		"id": "advanced_seminar",
		"name": "Advanced Seminar",
		"tier": 2,
		"cp_cost": 14,
		"stats": {"skill": 5, "creativity": 5, "teamwork": 5},
		"double_stat": "role_primary",
		"unlock": "donor:local_ngo"
	},
	{
		"id": "wellness_retreat",
		"name": "Wellness Retreat",
		"tier": 2,
		"cp_cost": 14,
		"stats": {"motivation": 8, "teamwork": 4, "skill": 3},
		"double_stat": "",
		"unlock": "year:2"
	},
	{
		"id": "leadership_bootcamp",
		"name": "Leadership Bootcamp",
		"tier": 3,
		"cp_cost": 21,
		"stats": {"teamwork": 10, "motivation": 5, "skill": 3},
		"double_stat": "role_primary",
		"unlock": "year:3"
	},
	{
		"id": "executive_program",
		"name": "Executive Program",
		"tier": 3,
		"cp_cost": 21,
		"stats": {"skill": 8, "creativity": 6, "teamwork": 6, "motivation": 6},
		"double_stat": "role_primary",
		"unlock": "donor:government_agency"
	}
]

const TRAINING_COMBOS: Array = [
	{
		"id": "creative_sprint",
		"name": "Creative Sprint",
		"requires_roles": ["DEVELOPER", "DESIGNER", "MARKETER"],
		"bonus_desc": "All stats +2 for all 3 members",
		"bonus": {"all_stats": 2}
	},
	{
		"id": "leadership_circle",
		"name": "Leadership Circle",
		"requires_roles": ["MANAGER", "HR_SPECIALIST", "ACCOUNTANT"],
		"bonus_desc": "+10 EXP for all 3 members",
		"bonus": {"exp": 10}
	},
	{
		"id": "intern_hustle",
		"name": "Intern Hustle",
		"requires_roles": ["INTERN", "INTERN", "INTERN"],
		"bonus_desc": "CP cost reduced by 50%",
		"bonus": {"cp_discount": 50}
	},
	{
		"id": "data_squad",
		"name": "Data Squad",
		"requires_roles": ["ANALYST", "IT_SUPPORT", "DEVELOPER"],
		"bonus_desc": "SKL +5 for all 3 members",
		"bonus": {"skill": 5}
	},
	{
		"id": "public_front",
		"name": "Public Front",
		"requires_roles": ["PR", "MARKETER", "MANAGER"],
		"bonus_desc": "MOT +5 and CRE +3 for all 3 members",
		"bonus": {"motivation": 5, "creativity": 3}
	},
	{
		"id": "compliance_team",
		"name": "Compliance Team",
		"requires_roles": ["LEGAL", "ACCOUNTANT", "MANAGER"],
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
		employees: Array, _discovered_combos: Array) -> int:
	var base: int = training.get("cp_cost", 7) * emp_count
	for combo in TRAINING_COMBOS:
		if _check_combo_match(combo, employees):
			if combo["id"] == "intern_hustle":
				base = base / 2
	return base

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
				"skill":
					emp.skill = mini(100, emp.skill + amount)
				"motivation":
					emp.motivation = mini(100, emp.motivation + amount)
				"teamwork":
					emp.teamwork = mini(100, emp.teamwork + amount)
				"creativity":
					emp.creativity = mini(100, emp.creativity + amount)
			gained[stat_key] = amount
		if not matched_combo.is_empty():
			var bonus: Dictionary = matched_combo.get("bonus", {})
			if bonus.has("all_stats"):
				var b: int = int(bonus["all_stats"])
				emp.skill      = mini(100, emp.skill + b)
				emp.motivation = mini(100, emp.motivation + b)
				emp.teamwork   = mini(100, emp.teamwork + b)
				emp.creativity = mini(100, emp.creativity + b)
				gained["combo_all"] = b
			if bonus.has("skill"):
				var b: int = int(bonus["skill"])
				emp.skill = mini(100, emp.skill + b)
				gained["combo_skill"] = b
			if bonus.has("motivation"):
				var b: int = int(bonus["motivation"])
				emp.motivation = mini(100, emp.motivation + b)
				gained["combo_mot"] = b
			if bonus.has("creativity"):
				var b: int = int(bonus["creativity"])
				emp.creativity = mini(100, emp.creativity + b)
				gained["combo_cre"] = b
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
		"DEVELOPER":     return "skill"
		"DESIGNER":      return "creativity"
		"MARKETER":      return "motivation"
		"MANAGER":       return "teamwork"
		"ACCOUNTANT":    return "skill"
		"HR_SPECIALIST": return "motivation"
		"ANALYST":       return "skill"
		"LEGAL":         return "teamwork"
		"IT_SUPPORT":    return "skill"
		"PR":            return "creativity"
	return ""
