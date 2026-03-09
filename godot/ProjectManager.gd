extends Node

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal project_completed(project: Dictionary)
signal projects_updated

# ------------------------------------------
#  TEMPLATES  (10 hardcoded project types)
# ------------------------------------------
# required_role int values match Employee.Role enum:
#   0=DEVELOPER  1=DESIGNER  2=MARKETER  3=HR_SPECIALIST
#   4=ACCOUNTANT  5=MANAGER  6=INTERN
const _TEMPLATES: Array = [
	{"name": "Website Redesign",    "description": "Rebuild the company website.",     "required_role": 0, "duration_ticks": 5, "reward_cash": 4500, "reward_corp_points": 30},
	{"name": "Marketing Campaign",  "description": "Launch a new marketing campaign.", "required_role": 2, "duration_ticks": 4, "reward_cash": 3800, "reward_corp_points": 23},
	{"name": "Annual Report",       "description": "Prepare the annual financial report.", "required_role": 4, "duration_ticks": 6, "reward_cash": 3000, "reward_corp_points": 38},
	{"name": "System Upgrade",      "description": "Upgrade core IT infrastructure.",  "required_role": 0, "duration_ticks": 8, "reward_cash": 7500, "reward_corp_points": 53},
	{"name": "Client Presentation", "description": "Present quarterly results to a key client.", "required_role": 2, "duration_ticks": 3, "reward_cash": 2300, "reward_corp_points": 15},
	{"name": "Budget Planning",     "description": "Plan the next quarter budget.",    "required_role": 4, "duration_ticks": 5, "reward_cash": 3300, "reward_corp_points": 30},
	{"name": "UI/UX Overhaul",      "description": "Redesign the core product interface.", "required_role": 1, "duration_ticks": 7, "reward_cash": 6000, "reward_corp_points": 45},
	{"name": "Brand Identity",      "description": "Create updated brand guidelines.", "required_role": 1, "duration_ticks": 4, "reward_cash": 4200, "reward_corp_points": 27},
	{"name": "Operations Manual",   "description": "Write the office operations manual.", "required_role": 5, "duration_ticks": 6, "reward_cash": 5300, "reward_corp_points": 42},
	{"name": "Intern Onboarding",   "description": "Onboard the new intern cohort.",   "required_role": 6, "duration_ticks": 2, "reward_cash": 1200, "reward_corp_points": 12},
]

# ------------------------------------------
#  STATE
# ------------------------------------------
var _available: Array    = []
var _active: Array       = []
var _pool_indices: Array = []
var _next_id: int        = 0

# ------------------------------------------
#  INIT
# ------------------------------------------
func initialize() -> void:
	_available.clear()
	_active.clear()
	_pool_indices.clear()
	_next_id = 0
	_generate_available(3)
	_connect_clock()

func _connect_clock() -> void:
	var cm: Node = get_node_or_null("/root/ClockManager")
	if cm == null:
		return
	if not cm.work_day_started.is_connected(_on_work_day_started):
		cm.work_day_started.connect(_on_work_day_started)

# ------------------------------------------
#  PUBLIC API
# ------------------------------------------
func accept_project(pid: int) -> bool:
	for i: int in range(_available.size()):
		if _available[i].get("id", -1) == pid:
			var proj: Dictionary = _available[i]
			_available.remove_at(i)
			proj["is_active"] = true
			_active.append(proj)
			projects_updated.emit()
			if _available.is_empty():
				_generate_available(3)
			return true
	return false

func assign_employee(project_id: int, employee_id: String, gm: Node) -> bool:
	for proj in _active:
		if proj.get("id", -1) == project_id:
			var ids: Array = proj.get("assigned_employee_ids", [])
			if employee_id not in ids:
				ids.append(employee_id)
				proj["assigned_employee_ids"] = ids
				for emp in gm.employees.get_hired_employees():
					if emp.id == employee_id:
						emp.is_assigned_to_project = true
						emp.current_project_id = str(project_id)
						break
			projects_updated.emit()
			return true
	return false

func get_available_projects() -> Array:
	return _available.duplicate()

func get_active_projects() -> Array:
	return _active.duplicate()

# ------------------------------------------
#  LEGACY STUBS (called by GameManager)
# ------------------------------------------
func tick_projects(_gm: Node) -> void:
	pass

func generate_new_projects(_count: int) -> void:
	pass

# ------------------------------------------
#  CLOCK TICK
# ------------------------------------------
func _on_work_day_started() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var to_complete: Array = []
	for proj in _active:
		var base: float        = 1.0 / float(proj.get("duration_ticks", 1))
		var role_mult: float   = 1.5 if _has_role_match(proj, gm) else 1.0
		var ot_mult: float     = _get_ot_multiplier(proj, gm)
		var daily: float       = base * role_mult * ot_mult
		var fever_mult: float  = 2.0 if gm.is_fever_mode else 1.0
		proj["progress"] = minf(1.0, proj.get("progress", 0.0) + daily * fever_mult)
		if proj["progress"] >= 1.0:
			to_complete.append(proj.get("id", -1))
	var any_completed: bool = not to_complete.is_empty()
	for pid in to_complete:
		_complete_by_id(pid, gm)
	if any_completed:
		projects_updated.emit()

func _get_ot_multiplier(proj: Dictionary, gm: Node) -> float:
	var ids: Array = proj.get("assigned_employee_ids", [])
	if ids.is_empty():
		return 1.0
	var total_mult: float = 0.0
	var count: int = 0
	for emp in gm.employees.get_hired_employees():
		if emp.id not in ids:
			continue
		count += 1
		if emp.is_burned_out:
			total_mult += 0.2
		else:
			match emp.ot_level:
				1: total_mult += 1.3
				2: total_mult += 1.5
				3: total_mult += 1.7
				_: total_mult += 1.0
	if count == 0:
		return 1.0
	return total_mult / float(count)

func _has_role_match(proj: Dictionary, gm: Node) -> bool:
	var ids: Array = proj.get("assigned_employee_ids", [])
	if ids.is_empty():
		return false
	for emp in gm.employees.get_hired_employees():
		if emp.id in ids and emp.role == proj.get("required_role", 0):
			return true
	return false

func _complete_by_id(pid: int, gm: Node) -> void:
	for i: int in range(_active.size()):
		if _active[i].get("id", -1) == pid:
			var proj: Dictionary = _active[i]
			_active.remove_at(i)
			proj["is_complete"] = true
			proj["is_active"]   = false
			gm.economy.add_revenue(proj.get("reward_cash", 0), "Project: " + proj.get("name", "Project"))
			gm.add_corp_points(proj.get("reward_corp_points", 0))
			_available.append(_next_from_pool())
			print("[Project] %s completed! +$%d +%d CP" % [
				proj.get("name", "Project"), proj.get("reward_cash", 0), proj.get("reward_corp_points", 0)
			])
			project_completed.emit(proj)
			return

# ------------------------------------------
#  GENERATION HELPERS
# ------------------------------------------
func _generate_available(count: int) -> void:
	for _i: int in range(count):
		_available.append(_next_from_pool())
	projects_updated.emit()

func _next_from_pool() -> Dictionary:
	if _pool_indices.is_empty():
		for i: int in range(_TEMPLATES.size()):
			_pool_indices.append(i)
		_pool_indices.shuffle()
	var idx: int = _pool_indices.pop_back()
	var proj: Dictionary = _TEMPLATES[idx].duplicate()
	proj["id"]                    = _next_id
	proj["progress"]              = 0.0
	proj["assigned_employee_ids"] = []
	proj["is_active"]             = false
	proj["is_complete"]           = false
	_next_id += 1
	return proj

# ------------------------------------------
#  SAVE / LOAD
# ------------------------------------------
func to_save_array() -> Array:
	var out: Array = []
	for p in _available:
		out.append(p.duplicate())
	for p in _active:
		out.append(p.duplicate())
	return out

func load_projects(data: Array) -> void:
	_available.clear()
	_active.clear()
	for d in data:
		if not d.has("required_role"):
			continue
		if d.get("is_active", false) and not d.get("is_complete", false):
			_active.append(d)
		elif not d.get("is_active", false) and not d.get("is_complete", false):
			_available.append(d)
	if _available.is_empty() and _active.is_empty():
		_generate_available(3)
	_connect_clock()
