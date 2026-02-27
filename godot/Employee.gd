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
	DEVELOPER,
	DESIGNER,
	MARKETER,
	HR_SPECIALIST,
	ACCOUNTANT,
	MANAGER,
	INTERN
}

# ─────────────────────────────────────────
#  IDENTITY
# ─────────────────────────────────────────
@export var id: String = ""
@export var first_name: String = ""
@export var last_name: String = ""
@export var personality: Personality = Personality.NORMAL
@export var role: Role = Role.DEVELOPER

func full_name() -> String:
	return first_name + " " + last_name

# ─────────────────────────────────────────
#  CORE STATS  (1–100)
# ─────────────────────────────────────────
@export var skill: int = 50
@export var motivation: int = 50
@export var teamwork: int = 50
@export var creativity: int = 50

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

# ─────────────────────────────────────────
#  CONSTRUCTOR
# ─────────────────────────────────────────
static func create(p_first: String, p_last: String, p_role: Role, p_personality: Personality) -> Employee:
	var emp := Employee.new()
	emp.id = _generate_id()
	emp.first_name = p_first
	emp.last_name = p_last
	emp.role = p_role
	emp.personality = p_personality
	emp.level = 1
	emp.experience_points = 0
	emp.is_hired = false
	emp.is_burned_out = false

	# Randomise base stats
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	emp.skill      = rng.randi_range(20, 70)
	emp.motivation = rng.randi_range(20, 70)
	emp.teamwork   = rng.randi_range(20, 70)
	emp.creativity = rng.randi_range(20, 70)

	emp._apply_personality_bonuses()
	emp.monthly_salary = emp._calculate_base_salary()
	return emp

# ─────────────────────────────────────────
#  COMPUTED
# ─────────────────────────────────────────
func effective_productivity() -> float:
	if not is_assigned_to_project or is_burned_out:
		return 0.0
	return (skill + motivation * _personality_multiplier()) / 2.0

func _personality_multiplier() -> float:
	match personality:
		Personality.WORKAHOLIC:   return 1.3
		Personality.LAZY:         return 0.6
		Personality.PERFECTIONIST:return 1.1
		Personality.GOSSIP:       return 0.85
		_:                        return 1.0

# ─────────────────────────────────────────
#  PRIVATE HELPERS
# ─────────────────────────────────────────
func _apply_personality_bonuses() -> void:
	match personality:
		Personality.WORKAHOLIC:
			skill      = mini(100, skill + 15)
			motivation = mini(100, motivation + 20)
		Personality.LAZY:
			motivation = maxi(5, motivation - 20)
		Personality.TEAM_PLAYER:
			teamwork   = mini(100, teamwork + 25)
		Personality.PERFECTIONIST:
			skill      = mini(100, skill + 20)
			creativity = maxi(5, creativity - 10)
		Personality.GOSSIP:
			teamwork   = mini(100, teamwork + 10)
			motivation = maxi(5, motivation - 10)

func _calculate_base_salary() -> int:
	var base: int
	match role:
		Role.INTERN:        base = 500
		Role.DEVELOPER:     base = 2000
		Role.DESIGNER:      base = 1800
		Role.MARKETER:      base = 1700
		Role.HR_SPECIALIST: base = 1600
		Role.ACCOUNTANT:    base = 1900
		Role.MANAGER:       base = 2500
		_:                  base = 1500
	return base + (skill * 10) + (level * 100)

static func _generate_id() -> String:
	# Simple unique ID using time + random
	var rng := RandomNumberGenerator.new()
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
	skill      = mini(100, skill + 5)
	motivation = mini(100, motivation + 3)
	monthly_salary = _calculate_base_salary()
	print("[Employee] %s leveled up to Level %d!" % [full_name(), level])

func adjust_motivation(delta: int) -> void:
	motivation  = clampi(motivation + delta, 0, 100)
	is_burned_out = motivation <= 10

func get_display_string() -> String:
	return "%s | %s | Lv.%d | Skill:%d Motivation:%d | $%d/mo" % [
		full_name(), Role.keys()[role], level, skill, motivation, monthly_salary
	]

# ─────────────────────────────────────────
#  SERIALISATION  (for SaveSystem)
# ─────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"id": id, "first_name": first_name, "last_name": last_name,
		"personality": personality, "role": role,
		"skill": skill, "motivation": motivation,
		"teamwork": teamwork, "creativity": creativity,
		"level": level, "experience_points": experience_points,
		"monthly_salary": monthly_salary,
		"is_hired": is_hired, "is_burned_out": is_burned_out,
		"is_assigned_to_project": is_assigned_to_project,
		"current_project_id": current_project_id
	}

static func from_dict(d: Dictionary) -> Employee:
	var emp := Employee.new()
	emp.id                     = d.get("id", "")
	emp.first_name             = d.get("first_name", "")
	emp.last_name              = d.get("last_name", "")
	emp.personality            = d.get("personality", Personality.NORMAL)
	emp.role                   = d.get("role", Role.DEVELOPER)
	emp.skill                  = d.get("skill", 50)
	emp.motivation             = d.get("motivation", 50)
	emp.teamwork               = d.get("teamwork", 50)
	emp.creativity             = d.get("creativity", 50)
	emp.level                  = d.get("level", 1)
	emp.experience_points      = d.get("experience_points", 0)
	emp.monthly_salary         = d.get("monthly_salary", 1500)
	emp.is_hired               = d.get("is_hired", false)
	emp.is_burned_out          = d.get("is_burned_out", false)
	emp.is_assigned_to_project = d.get("is_assigned_to_project", false)
	emp.current_project_id     = d.get("current_project_id", "")
	return emp
