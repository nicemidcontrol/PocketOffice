extends Node

# ─────────────────────────────────────────
#  SIGNALS  (replaces C# static events)
# ─────────────────────────────────────────
signal employee_hired(employee: Employee)
signal employee_fired(employee: Employee)

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _all_employees: Array[Employee] = []

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

# ─────────────────────────────────────────
#  DAILY TICK  (called by GameManager)
# ─────────────────────────────────────────
func tick_motivation() -> void:
	for emp in _all_employees:
		if not emp.is_hired:
			continue
		if emp.is_burned_out:
			emp.adjust_motivation(2)   # slow recovery
		elif emp.personality == Employee.Personality.WORKAHOLIC:
			emp.adjust_motivation(-1)  # overwork decay

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
	var first       := first_names[rng.randi_range(0, first_names.size() - 1)]
	var last        := last_names[rng.randi_range(0, last_names.size() - 1)]

	return Employee.create(first, last, role, personality)
