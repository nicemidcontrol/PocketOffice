extends Node

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal employee_hired(employee: Employee)
signal employee_fired(employee: Employee)
signal hero_unlocked(hero_name: String)
signal employee_burnout(employee_name: String)

# ─────────────────────────────────────────
#  OT CONSTANTS
# ─────────────────────────────────────────
const OT_NONE: int   = 0
const OT_LIGHT: int  = 1
const OT_HEAVY: int  = 2
const OT_CRUNCH: int = 3

# ─────────────────────────────────────────
#  HERO TEMPLATES  (id, role int, personality int)
#  Role:        OPERATIONS=0 PROCUREMENT=1 SECRETARY=2 MANAGEMENT=3 FINANCE=4
#  Personality: NORMAL=0 WORKAHOLIC=1 LAZY=2 GOSSIP=3
#               PERFECTIONIST=4 TEAM_PLAYER=5 LONE_STAR=6
# ─────────────────────────────────────────
const _HERO_TEMPLATES: Array = [
	{
		"id": "george_b",
		"first_name": "George",
		"last_name": "B.",
		"role": 0,
		"personality": 0,
		"personality_label": "Normal",
		"tier": "D",
		"salary": 2200,
		"description": "Your first field officer. Reliable, practical, and never complains about mud.",
		"unlock_condition": "start",
		"unlock_hint": "Starting employee"
	},
	{
		"id": "erik_v",
		"first_name": "Erik",
		"last_name": "V.",
		"role": 4,
		"personality": 4,
		"personality_label": "Perfectionist",
		"tier": "D",
		"salary": 2400,
		"description": "Your first finance officer. Spreadsheets are his love language.",
		"unlock_condition": "start",
		"unlock_hint": "Starting employee"
	},
	{
		"id": "thoksin_s",
		"first_name": "Thoksin",
		"last_name": "S.",
		"role": 3,
		"personality": 3,
		"personality_label": "Brown-noser",
		"tier": "A",
		"salary": 8500,
		"description": "Former executive with controversial methods but undeniable results.",
		"unlock_condition": "research_government",
		"unlock_hint": "Unlock via Corporate > Research: Government Relations"
	},
	{
		"id": "prayui_c",
		"first_name": "Prayui",
		"last_name": "C.",
		"role": 3,
		"personality": 4,
		"personality_label": "Perfectionist",
		"tier": "A",
		"salary": 9000,
		"description": "Military-trained manager. Everything must be orderly. No exceptions.",
		"unlock_condition": "special_event",
		"unlock_hint": "May appear during a special office event"
	},
	{
		"id": "peta_l",
		"first_name": "Peta",
		"last_name": "L.",
		"role": 3,
		"personality": 5,
		"personality_label": "Team Player",
		"tier": "B",
		"salary": 7500,
		"description": "Young progressive manager loved by the team but feared by old guard.",
		"unlock_condition": "donor_unlock",
		"unlock_hint": "Win a Government Donor to unlock"
	},
	{
		"id": "burapol_k",
		"first_name": "Burapol",
		"last_name": "K.",
		"role": 0,
		"personality": 1,
		"personality_label": "Workaholic",
		"tier": "S",
		"salary": 6000,
		"description": "World-class discipline. Will outwork everyone. Literally everyone.",
		"unlock_condition": "special_event",
		"unlock_hint": "May appear during a special office event"
	},
	{
		"id": "somrak_p",
		"first_name": "Somrak",
		"last_name": "P.",
		"role": 3,
		"personality": 4,
		"personality_label": "Perfectionist",
		"tier": "A",
		"salary": 8000,
		"description": "Olympic-level dedication. Trains the team like champions.",
		"unlock_condition": "special_event",
		"unlock_hint": "May appear during a special office event"
	},
	{
		"id": "liza_m",
		"first_name": "Liza",
		"last_name": "M.",
		"role": 2,
		"personality": 1,
		"personality_label": "Workaholic",
		"tier": "S",
		"salary": 9500,
		"description": "Chart-topping creative. Her designs go viral every time.",
		"unlock_condition": "donor_entertainment",
		"unlock_hint": "Win an Entertainment Donor to unlock"
	},
	{
		"id": "derek_anan",
		"first_name": "Derek Anan",
		"last_name": "Boonphun",
		"role": 3,
		"personality": 6,
		"personality_label": "Legendary",
		"tier": "S",
		"salary": 15000,
		"description": "The one who built everything from nothing. A true legend. Some say he never sleeps.",
		"unlock_condition": "ultimate",
		"unlock_hint": "???"
	}
]

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _all_employees: Array[Employee] = []
var hero_roster: Array = []
var unlocked_heroes: Array[String] = []
var total_hired_ever: int = 0

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	for template in _HERO_TEMPLATES:
		hero_roster.append(template.duplicate())
	var cm: Node = get_node_or_null("/root/ClockManager")
	if cm != null:
		cm.work_day_started.connect(_on_work_day_started)

func _on_work_day_started() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	check_hero_unlocks(gm)

# ─────────────────────────────────────────
#  COMPUTED PROPERTIES
# ─────────────────────────────────────────
func hired_count() -> int:
	return _all_employees.filter(func(e): return e.is_hired).size()

func average_motivation() -> float:
	var hired := _all_employees.filter(func(e): return e.is_hired)
	if hired.is_empty():
		return 0.0
	var total := 0
	for e in hired:
		total += e.motivation
	return float(total) / hired.size()

func get_total_monthly_salary() -> int:
	var total := 0
	for e in _all_employees:
		if e.is_hired:
			total += e.monthly_salary
	return total

# ─────────────────────────────────────────
#  HIRE / FIRE
# ─────────────────────────────────────────
func hire(employee: Employee) -> bool:
	if not _all_employees.has(employee):
		_all_employees.append(employee)
	employee.is_hired = true
	total_hired_ever += 1
	employee_hired.emit(employee)
	print("[EmployeeManager] Hired: %s" % employee.full_name())
	return true

func fire(employee: Employee) -> void:
	employee.is_hired = false
	employee.is_assigned_to_project = false
	employee.current_project_id = ""
	employee_fired.emit(employee)
	print("[EmployeeManager] Fired: %s" % employee.full_name())

# ─────────────────────────────────────────
#  QUERIES
# ─────────────────────────────────────────
func get_available_employees() -> Array[Employee]:
	return _all_employees.filter(
		func(e): return e.is_hired and not e.is_assigned_to_project and not e.is_burned_out
	)

func get_all_employees() -> Array[Employee]:
	return _all_employees.duplicate()

func get_hired_employees() -> Array[Employee]:
	return _all_employees.filter(func(e): return e.is_hired)

func get_employee_by_id(emp_id: String) -> Employee:
	for emp in _all_employees:
		if emp.id == emp_id:
			return emp
	return null

# ─────────────────────────────────────────
#  HERO SYSTEM
# ─────────────────────────────────────────
func check_hero_unlocks(gm: Node) -> void:
	for template in hero_roster:
		var hero_id: String = template["id"]
		if unlocked_heroes.has(hero_id):
			continue
		match template["unlock_condition"]:
			"ultimate":
				var year: int = gm.company_data.get("current_year", 2024)
				var cp: int = gm.corp_points
				if total_hired_ever >= 15 and year >= 2026 and cp >= 500:
					_unlock_hero(hero_id)

func _unlock_hero(hero_id: String) -> void:
	unlocked_heroes.append(hero_id)
	for template in hero_roster:
		if template["id"] == hero_id:
			var name: String = template["first_name"] + " " + template["last_name"]
			hero_unlocked.emit(name)
			return

func trigger_hero_unlock(unlock_condition: String) -> void:
	for template in hero_roster:
		var hero_id: String = template["id"]
		if template["unlock_condition"] == unlock_condition and not unlocked_heroes.has(hero_id):
			_unlock_hero(hero_id)

func get_available_heroes() -> Array:
	var result: Array = []
	for template in hero_roster:
		var hero_id: String = template["id"]
		if not unlocked_heroes.has(hero_id):
			continue
		var already_hired: bool = false
		for emp in _all_employees:
			if emp.id == hero_id and emp.is_hired:
				already_hired = true
				break
		if not already_hired:
			result.append(template)
	return result

func is_hero_employee(emp_id: String) -> bool:
	for h in hero_roster:
		if h["id"] == emp_id:
			return true
	return false

func get_hero_template(emp_id: String) -> Dictionary:
	for h in hero_roster:
		if h["id"] == emp_id:
			return h
	return {}

func create_hero_employee(template: Dictionary) -> Employee:
	var emp: Employee = Employee.new()
	emp.id = template["id"]
	emp.first_name = template["first_name"]
	emp.last_name = template["last_name"]
	emp.role = int(template["role"])
	emp.personality = int(template["personality"])
	emp.monthly_salary = int(template["salary"])
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
	emp.current_project_id = ""
	emp.is_assigned_to_project = false
	emp.generate_stats(template.get("tier", "F"), emp.role)
	emp._apply_personality_bonuses()
	return emp

# Hire George and Erik at the start of a new game.
func hire_starting_team() -> void:
	for template in _HERO_TEMPLATES:
		if template.get("unlock_condition", "") == "start":
			var emp: Employee = create_hero_employee(template)
			hire(emp)

# ─────────────────────────────────────────
#  DAILY TICK  (called by GameManager)
# ─────────────────────────────────────────
func tick_motivation() -> void:
	for emp in _all_employees:
		if not emp.is_hired:
			continue
		var was_burnout: bool = emp.is_burned_out
		if emp.is_burned_out:
			if emp.ot_level == 0:
				emp.adjust_morale(5)
				emp.stress = clampi(emp.stress - 5, 0, 100)
			else:
				emp.adjust_morale(-5)
				emp.stress = clampi(emp.stress + 5, 0, 100)
		elif emp.ot_level > 0:
			var mot_cost: int = 0
			match emp.ot_level:
				OT_LIGHT:  mot_cost = 5
				OT_HEAVY:  mot_cost = 15
				OT_CRUNCH: mot_cost = 30
			emp.adjust_morale(-mot_cost)
			emp.stress = clampi(emp.stress + emp.ot_level * 10, 0, 100)
			if emp.stress >= 90:
				emp.adjust_morale(-20)
		elif emp.personality == Employee.Personality.WORKAHOLIC:
			emp.adjust_morale(-1)
			emp.stress = clampi(emp.stress - 5, 0, 100)
		else:
			emp.adjust_morale(3)
			emp.stress = clampi(emp.stress - 10, 0, 100)
		if emp.is_burned_out and not was_burnout:
			employee_burnout.emit(emp.full_name())

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func load_employees(data_array: Array) -> void:
	_all_employees.clear()
	for d in data_array:
		_all_employees.append(Employee.from_dict(d))

func to_save_array() -> Array:
	var out := []
	for e in _all_employees:
		out.append(e.to_dict())
	return out

# ─────────────────────────────────────────
#  RANDOM GENERATION  (for hiring screen)
# ─────────────────────────────────────────
static func generate_random_candidate() -> Employee:
	var first_names := ["Alice","Bob","Carlos","Diana","Erik","Fiona","George","Helen","Ivan","Jess"]
	var last_names  := ["Smith","Tanaka","Patel","Nguyen","Rossi","Kim","Okafor","Hernandez","Lee","Johansson"]
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var role        := rng.randi_range(0, Employee.Role.size() - 1) as Employee.Role
	var personality := rng.randi_range(0, Employee.Personality.size() - 1) as Employee.Personality
	var first: String = first_names[rng.randi_range(0, first_names.size() - 1)]
	var last: String  = last_names[rng.randi_range(0, last_names.size() - 1)]

	return Employee.create(first, last, role, personality)
