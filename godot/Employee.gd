class_name Employee
extends Resource

# ─────────────────────────────────────────
#  ENUMS
# ─────────────────────────────────────────
enum Personality {
	NORMAL,
	WORKAHOLIC,
	LAZY,
	GOSSIP,
	PERFECTIONIST,
	TEAM_PLAYER,
	LONE_STAR
}

enum Role {
	OPERATIONS,
	PROCUREMENT,
	SECRETARY,
	MANAGEMENT,
	FINANCE
}

# ─────────────────────────────────────────
#  IDENTITY
# ─────────────────────────────────────────
@export var id: String = ""
@export var first_name: String = ""
@export var last_name: String = ""
@export var personality: int = Personality.NORMAL
@export var role: int = Role.OPERATIONS
@export var tier: String = "F"

func full_name() -> String:
	return first_name + " " + last_name

# ─────────────────────────────────────────
#  CORE STATS  (0–1000)
# ─────────────────────────────────────────
@export var charm: int = 0
@export var technical: int = 0
@export var procurement: int = 0
@export var focus: int = 0
@export var communication: int = 0
@export var management: int = 0
@export var logistics: int = 0
@export var precision: int = 0

# ─────────────────────────────────────────
#  MORALE  (0–100, separate morale/energy stat)
# ─────────────────────────────────────────
@export var morale: int = 50

# ─────────────────────────────────────────
#  CAREER
# ─────────────────────────────────────────
@export var level: int = 1
@export var experience_points: int = 0

func experience_to_next_level() -> int:
	return level * 100

# ─────────────────────────────────────────
#  FINANCIALS
# ─────────────────────────────────────────
@export var monthly_salary: int = 0

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
@export var is_hired: bool = false
@export var is_assigned_to_project: bool = false
@export var current_project_id: String = ""
@export var is_burned_out: bool = false
@export var ot_level: int = 0
@export var stress: int = 0

# Internal problem tracking
@export var ot_months_consecutive: int = 0
@export var low_morale_months: int = 0
@export var idle_months: int = 0

# ─────────────────────────────────────────
#  CONSTRUCTOR
# ─────────────────────────────────────────
static func create(p_first: String, p_last: String, p_role: int, p_personality: int) -> Employee:
	var emp: Employee = Employee.new()
	emp.id = _generate_id()
	emp.first_name = p_first
	emp.last_name = p_last
	emp.role = p_role
	emp.personality = p_personality
	emp.tier = "F"
	emp.morale = 50
	emp.level = 1
	emp.experience_points = 0
	emp.is_hired = false
	emp.is_burned_out = false
	emp.ot_level = 0
	emp.stress = 0
	emp.ot_months_consecutive = 0
	emp.low_morale_months = 0
	emp.idle_months = 0
	emp.generate_stats(emp.tier, p_role)
	emp._apply_personality_bonuses()
	emp.monthly_salary = emp._calculate_base_salary()
	return emp

# ─────────────────────────────────────────
#  STAT GENERATION
# ─────────────────────────────────────────
func generate_stats(p_tier: String, emp_role: int) -> void:
	tier = p_tier
	var base_min: int = 0
	var base_max: int = 0
	var specialty_min: int = 0
	var specialty_max: int = 0

	match p_tier:
		"F": base_min = 30;  base_max = 100;  specialty_min = 50;  specialty_max = 150
		"E": base_min = 50;  base_max = 200;  specialty_min = 200; specialty_max = 400
		"D": base_min = 100; base_max = 300;  specialty_min = 300; specialty_max = 500
		"C": base_min = 200; base_max = 450;  specialty_min = 400; specialty_max = 600
		"B": base_min = 300; base_max = 550;  specialty_min = 500; specialty_max = 700
		"A": base_min = 400; base_max = 650;  specialty_min = 600; specialty_max = 850
		"S": base_min = 600; base_max = 800;  specialty_min = 800; specialty_max = 1000

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	charm         = rng.randi_range(base_min, base_max)
	technical     = rng.randi_range(base_min, base_max)
	procurement   = rng.randi_range(base_min, base_max)
	focus         = rng.randi_range(base_min, base_max)
	communication = rng.randi_range(base_min, base_max)
	management    = rng.randi_range(base_min, base_max)
	logistics     = rng.randi_range(base_min, base_max)
	precision     = rng.randi_range(base_min, base_max)

	match emp_role:
		Role.OPERATIONS:
			technical = rng.randi_range(specialty_min, specialty_max)
			logistics = rng.randi_range(specialty_min, specialty_max)
		Role.PROCUREMENT:
			procurement = rng.randi_range(specialty_min, specialty_max)
			logistics   = rng.randi_range(specialty_min, specialty_max)
		Role.SECRETARY:
			communication = rng.randi_range(specialty_min, specialty_max)
			charm         = rng.randi_range(specialty_min, specialty_max)
		Role.MANAGEMENT:
			management = rng.randi_range(specialty_min, specialty_max)
			charm      = rng.randi_range(specialty_min, specialty_max)
		Role.FINANCE:
			precision = rng.randi_range(specialty_min, specialty_max)
			focus     = rng.randi_range(specialty_min, specialty_max)

# ─────────────────────────────────────────
#  COMPUTED
# ─────────────────────────────────────────
func effective_productivity() -> float:
	if not is_assigned_to_project or is_burned_out:
		return 0.0
	return (float(technical) + float(management) * _personality_multiplier()) / 2.0

func _personality_multiplier() -> float:
	match personality:
		Personality.WORKAHOLIC:    return 1.3
		Personality.LAZY:          return 0.6
		Personality.PERFECTIONIST: return 1.1
		Personality.GOSSIP:        return 0.85
		_:                         return 1.0

# ─────────────────────────────────────────
#  PRIVATE HELPERS
# ─────────────────────────────────────────
func _apply_personality_bonuses() -> void:
	match personality:
		Personality.WORKAHOLIC:
			technical  = mini(1000, technical + 80)
			morale     = clampi(morale + 20, 0, 100)
		Personality.LAZY:
			morale     = clampi(morale - 20, 0, 100)
		Personality.TEAM_PLAYER:
			management = mini(1000, management + 120)
		Personality.PERFECTIONIST:
			precision  = mini(1000, precision + 100)
			focus      = mini(1000, focus + 100)
		Personality.GOSSIP:
			charm      = mini(1000, charm + 50)
			morale     = clampi(morale - 10, 0, 100)

func _calculate_base_salary() -> int:
	var base: int = 0
	match role:
		Role.OPERATIONS:  base = 1100
		Role.PROCUREMENT: base = 1200
		Role.SECRETARY:   base = 900
		Role.MANAGEMENT:  base = 1500
		Role.FINANCE:     base = 1300
		_:                base = 1000
	var total_stats: int = technical + management + precision + focus + charm + communication + logistics + procurement
	return base + (total_stats / 80) + (level * 50)

static func _generate_id() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return str(Time.get_ticks_msec()) + str(rng.randi())

# ─────────────────────────────────────────
#  PUBLIC METHODS
# ─────────────────────────────────────────
func gain_experience(amount: int) -> void:
	experience_points += amount
	while experience_points >= experience_to_next_level():
		experience_points -= experience_to_next_level()
		_level_up()

func _level_up() -> void:
	level += 1
	technical = mini(1000, technical + 25)
	focus     = mini(1000, focus + 15)
	monthly_salary = _calculate_base_salary()
	print("[Employee] %s leveled up to Level %d!" % [full_name(), level])

func adjust_morale(delta: int) -> void:
	morale = clampi(morale + delta, 0, 100)
	is_burned_out = morale <= 10

func role_name() -> String:
	return Role.keys()[role]

func get_display_string() -> String:
	return "%s | %s | Lv.%d | TEC:%d FOC:%d MGT:%d | $%d/mo" % [
		full_name(), Role.keys()[role], level, technical, focus, management, monthly_salary
	]

# ─────────────────────────────────────────
#  SERIALISATION  (for SaveSystem)
# ─────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"id": id, "first_name": first_name, "last_name": last_name,
		"personality": personality, "role": role, "tier": tier,
		"charm": charm, "technical": technical, "procurement": procurement,
		"focus": focus, "communication": communication, "management": management,
		"logistics": logistics, "precision": precision,
		"morale": morale,
		"level": level, "experience_points": experience_points,
		"monthly_salary": monthly_salary,
		"is_hired": is_hired, "is_burned_out": is_burned_out,
		"is_assigned_to_project": is_assigned_to_project,
		"current_project_id": current_project_id,
		"ot_level": ot_level, "stress": stress,
		"ot_months_consecutive": ot_months_consecutive,
		"low_morale_months": low_morale_months,
		"idle_months": idle_months
	}

static func from_dict(d: Dictionary) -> Employee:
	var emp: Employee = Employee.new()
	emp.id                     = d.get("id", "")
	emp.first_name             = d.get("first_name", "")
	emp.last_name              = d.get("last_name", "")
	emp.personality            = d.get("personality", Personality.NORMAL)
	# Clamp role to valid range for backward compat with old 11-role saves
	emp.role                   = clampi(d.get("role", Role.OPERATIONS), 0, Role.size() - 1)
	emp.tier                   = d.get("tier", "F")
	emp.charm                  = d.get("charm", d.get("motivation", 100))
	emp.technical              = d.get("technical", d.get("skill", 100))
	emp.procurement            = d.get("procurement", 100)
	emp.focus                  = d.get("focus", d.get("creativity", 100))
	emp.communication          = d.get("communication", 100)
	emp.management             = d.get("management", d.get("teamwork", 100))
	emp.logistics              = d.get("logistics", 100)
	emp.precision              = d.get("precision", 100)
	emp.morale                 = d.get("morale", d.get("motivation", 50))
	emp.level                  = d.get("level", 1)
	emp.experience_points      = d.get("experience_points", 0)
	emp.monthly_salary         = d.get("monthly_salary", 1500)
	emp.is_hired               = d.get("is_hired", false)
	emp.is_burned_out          = d.get("is_burned_out", false)
	emp.is_assigned_to_project = d.get("is_assigned_to_project", false)
	emp.current_project_id     = d.get("current_project_id", "")
	emp.ot_level               = d.get("ot_level", 0)
	emp.stress                 = d.get("stress", 0)
	emp.ot_months_consecutive  = d.get("ot_months_consecutive", 0)
	emp.low_morale_months      = d.get("low_morale_months", 0)
	emp.idle_months            = d.get("idle_months", 0)
	return emp
