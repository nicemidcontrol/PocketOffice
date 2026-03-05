extends Node

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal donor_won(donor_name: String, monthly: int)

# ─────────────────────────────────────────
#  ROLE CONSTANTS  (matches Employee.Role enum)
# ─────────────────────────────────────────
const _ROLE_INT: Dictionary = {
	"DEV": 0,
	"DES": 1,
	"MKT": 2,
	"HR":  3,
	"ACC": 4,
	"MGR": 5,
	"INT": 6,
}

# ─────────────────────────────────────────
#  DONOR DATA
# ─────────────────────────────────────────
const _DONOR_LIST: Array = [
	{
		"id":               "local_ngo",
		"name":             "Local NGO Partner",
		"description":      "A small but reliable local partner. Good starting point.",
		"cp_cost":          50,
		"req_reputation":   20,
		"req_year":         1,
		"req_role":         "",
		"monthly_funding":  2000,
		"one_time_cp":      30,
		"unlocks_hero_conditions": [],
		"unlocks_hero_names":      [],
		"unlocks_projects": ["Intern Onboarding"],
	},
	{
		"id":               "government_agency",
		"name":             "Government Agency",
		"description":      "Bureaucratic but well-funded. Requires management expertise.",
		"cp_cost":          150,
		"req_reputation":   50,
		"req_year":         1,
		"req_role":         "MGR",
		"monthly_funding":  5000,
		"one_time_cp":      80,
		"unlocks_hero_conditions": ["research_government", "donor_unlock"],
		"unlocks_hero_names":      ["Thoksin S.", "Peta L."],
		"unlocks_projects": ["Operations Manual", "Annual Report"],
	},
	{
		"id":               "entertainment_corp",
		"name":             "Entertainment Corporation",
		"description":      "Creative and well-connected. Needs design talent.",
		"cp_cost":          200,
		"req_reputation":   60,
		"req_year":         1,
		"req_role":         "DES",
		"monthly_funding":  4000,
		"one_time_cp":      100,
		"unlocks_hero_conditions": ["donor_entertainment"],
		"unlocks_hero_names":      ["Liza M."],
		"unlocks_projects": ["Brand Identity", "UI/UX Overhaul"],
	},
	{
		"id":               "international_foundation",
		"name":             "International Foundation",
		"description":      "Prestigious global partner. Significant reputation required.",
		"cp_cost":          300,
		"req_reputation":   80,
		"req_year":         2,
		"req_role":         "",
		"monthly_funding":  8000,
		"one_time_cp":      150,
		"unlocks_hero_conditions": [],
		"unlocks_hero_names":      [],
		"unlocks_projects": ["System Upgrade", "Website Redesign"],
	},
	{
		"id":               "un_partner",
		"name":             "UN Partner",
		"description":      "The pinnacle of NGO achievement. Almost impossible to win.",
		"cp_cost":          500,
		"req_reputation":   100,
		"req_year":         3,
		"req_role":         "",
		"monthly_funding":  15000,
		"one_time_cp":      300,
		"unlocks_hero_conditions": [],
		"unlocks_hero_names":      [],
		"unlocks_projects": ["System Upgrade", "Marketing Campaign"],
	},
]

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var donors: Array = []
var won_donors: Array[String] = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	for template in _DONOR_LIST:
		donors.append(template.duplicate())

# ─────────────────────────────────────────
#  LOOKUP
# ─────────────────────────────────────────
func get_donor(id: String) -> Dictionary:
	for d in donors:
		if d["id"] == id:
			return d
	return {}

# ─────────────────────────────────────────
#  REQUIREMENTS CHECK
# ─────────────────────────────────────────
func check_requirements(id: String, gm: Node) -> Dictionary:
	var donor: Dictionary = get_donor(id)
	if donor.is_empty():
		return {"ok": false, "reasons": ["Unknown donor"]}

	var reasons: Array = []

	var rep: int     = int(gm.company_data.get("reputation", 0))
	var req_rep: int = int(donor["req_reputation"])
	if rep < req_rep:
		reasons.append("REP %d needed (have %d)" % [req_rep, rep])

	var current_year: int = int(gm.company_data.get("current_year", 2024))
	var game_year: int    = current_year - 2023
	var req_year: int     = int(donor["req_year"])
	if game_year < req_year:
		reasons.append("Year %d needed (now Year %d)" % [req_year, game_year])

	var req_role: String = donor["req_role"]
	if req_role != "":
		if not _team_has_role(req_role, gm):
			reasons.append("%s required on team" % req_role)

	var cp: int      = int(gm.corp_points)
	var cp_cost: int = int(donor["cp_cost"])
	if cp < cp_cost:
		reasons.append("Need %d CP (have %d)" % [cp_cost, cp])

	return {"ok": reasons.is_empty(), "reasons": reasons}

# ─────────────────────────────────────────
#  WIN DONOR
# ─────────────────────────────────────────
func try_win_donor(id: String, gm: Node) -> bool:
	if won_donors.has(id):
		return false

	var check: Dictionary = check_requirements(id, gm)
	if not bool(check["ok"]):
		return false

	var donor: Dictionary = get_donor(id)
	var cp_cost: int = int(donor["cp_cost"])
	gm.add_corp_points(-cp_cost)
	won_donors.append(id)
	_apply_rewards(donor, gm)
	return true

func _apply_rewards(donor: Dictionary, gm: Node) -> void:
	var bonus_cp: int = int(donor["one_time_cp"])
	gm.add_corp_points(bonus_cp)

	var conditions: Array = donor["unlocks_hero_conditions"]
	for condition in conditions:
		gm.employees.trigger_hero_unlock(condition)

	var monthly: int   = int(donor["monthly_funding"])
	var name: String   = donor["name"]
	donor_won.emit(name, monthly)

# ─────────────────────────────────────────
#  MONTHLY TOTAL
# ─────────────────────────────────────────
func get_monthly_total() -> int:
	var total: int = 0
	for id in won_donors:
		var donor: Dictionary = get_donor(id)
		if not donor.is_empty():
			total += int(donor["monthly_funding"])
	return total

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _team_has_role(role_str: String, gm: Node) -> bool:
	if not _ROLE_INT.has(role_str):
		return false
	var role_int: int = int(_ROLE_INT[role_str])
	var hired: Array  = gm.employees.get_hired_employees()
	for emp in hired:
		if int(emp.role) == role_int:
			return true
	return false

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func to_save_dict() -> Dictionary:
	return {"won_donors": won_donors.duplicate()}

func from_save_dict(d: Dictionary) -> void:
	var saved: Array = d.get("won_donors", [])
	won_donors.clear()
	for id in saved:
		won_donors.append(str(id))
