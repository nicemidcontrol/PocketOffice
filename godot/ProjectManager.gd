extends Node

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal task_completed(task: Dictionary)
signal project_completed(project: Dictionary)
signal projects_updated

# Legacy signal kept for external callers
signal complication_triggered(project: Dictionary, complication: Dictionary)

# ─────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────
const PROJECT_COMPLETION_THRESHOLD: float = 0.70
const MAX_EMPLOYEES_PER_TASK: int = 3
const TASK_PROGRESS_PER_TICK: float = 0.12
const TASK_PROGRESS_CAP_PER_TICK: float = 0.15
const DECAY_RATE_PER_MONTH: float = 0.02
const IDLE_MONTHS_BEFORE_DECAY: int = 3

# Maps donor display names to internal ids used in unlock_donor_id
const _DONOR_NAME_MAP: Dictionary = {
	"Local NGO Partner": "local_ngo",
	"Government Agency": "gov_agency",
}

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _area: Dictionary = {}
var _unlocked_donor_ids: Array[String] = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	var clock: Node = get_node_or_null("/root/ClockManager")
	if clock == null:
		print("[PM] ERROR: ClockManager not found at /root/ClockManager")
	elif not clock.has_signal("work_day_started"):
		print("[PM] ERROR: ClockManager has no work_day_started signal")
	else:
		if not clock.work_day_started.is_connected(_on_work_day_started):
			clock.work_day_started.connect(_on_work_day_started)
			print("[PM] Connected to ClockManager.work_day_started")
		else:
			print("[PM] Already connected to ClockManager.work_day_started")
		if not clock.month_changed.is_connected(_on_month_changed):
			clock.month_changed.connect(_on_month_changed)
	var dm: Node = get_node_or_null("/root/DonorManager")
	if dm != null and not dm.donor_won.is_connected(_on_donor_won):
		dm.donor_won.connect(_on_donor_won)

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func initialize() -> void:
	_unlocked_donor_ids.clear()
	_area = _build_area()
	_connect_signals()
	projects_updated.emit()

# ─────────────────────────────────────────
#  AREA / PROJECT / TASK DATA
# ─────────────────────────────────────────
func _build_area() -> Dictionary:
	return {
		"id":       "local",
		"name":     "Ban Nong Khao",
		"projects": [
			_build_project_1(),
			_build_project_2(),
			_build_project_3(),
		]
	}

func _build_project_1() -> Dictionary:
	return {
		"id":                  "local_p1",
		"name":                "Who Needs What?",
		"subtitle":            "Community Needs Assessment",
		"description":         "Your first real assignment. Walk into a village you have never been to, ask 200 strangers what they need, and pretend you are not terrified. Welcome to NGO life.",
		"unlock_type":         "free",
		"unlock_donor_id":     "",
		"reward_cash":         2000,
		"reward_cp":           25,
		"reward_rep":          10,
		"status":              "available",
		"idle_months":         0,
		"completion_percent":  0.0,
		"_had_work_this_month": false,
		"tasks": [
			{
				"id": "local_p1_t1", "name": "Knock Knock, Anyone Home?",
				"subtitle": "Door-to-Door Survey",
				"description": "Knock on 200 doors. 50 will open. 10 will offer you water. 3 will try to sell you chickens.",
				"primary_stat": "charm", "secondary_stat": "communication",
				"duration": 2, "reward_cash": 400, "reward_cp": 5,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p1_t2", "name": "The Chief Remembers Everything",
				"subtitle": "Village Leader Interview",
				"description": "Meet the village chief. He has been chief for 40 years and remembers when the last road was built. It was not.",
				"primary_stat": "charm", "secondary_stat": "management",
				"duration": 1, "reward_cash": 300, "reward_cp": 5,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p1_t3", "name": "Crayon To Excel Pipeline",
				"subtitle": "Data Entry & Analysis",
				"description": "Turn 200 handwritten surveys into a spreadsheet. Half are in pencil. Some are in crayon.",
				"primary_stat": "focus", "secondary_stat": "technical",
				"duration": 2, "reward_cash": 400, "reward_cp": 5,
				"requires": ["local_p1_t1"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p1_t4", "name": "20 Pages Nobody Will Read",
				"subtitle": "Needs Assessment Report",
				"description": "Summarize everything into a 20-page report that your donor will skim in 3 minutes.",
				"primary_stat": "communication", "secondary_stat": "focus",
				"duration": 2, "reward_cash": 500, "reward_cp": 8,
				"requires": ["local_p1_t3"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
		],
	}

func _build_project_2() -> Dictionary:
	return {
		"id":                  "local_p2",
		"name":                "Dirt Don't Lie",
		"subtitle":            "Soil & Crop Restoration",
		"description":         "The soil has not been tested since ever. Farmers have been planting the same rice for three generations and wondering why yields drop every year. Time to play dirt detective.",
		"unlock_type":         "donor",
		"unlock_donor_id":     "local_ngo",
		"reward_cash":         4500,
		"reward_cp":           40,
		"reward_rep":          15,
		"status":              "locked",
		"idle_months":         0,
		"completion_percent":  0.0,
		"_had_work_this_month": false,
		"tasks": [
			{
				"id": "local_p2_t1", "name": "Professional Hole Digger",
				"subtitle": "Soil Sample Collection",
				"description": "Dig 50 holes across the village. Bag the dirt. Label each one. Try not to dig up anyone's ancestor.",
				"primary_stat": "technical", "secondary_stat": "precision",
				"duration": 2, "reward_cash": 500, "reward_cp": 5,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p2_t2", "name": "Still Waiting On The Lab",
				"subtitle": "Lab Analysis Coordination",
				"description": "Send soil to the city lab. The lab says results take 2 weeks. It has been 2 months. Follow up. Again.",
				"primary_stat": "procurement", "secondary_stat": "communication",
				"duration": 3, "reward_cash": 600, "reward_cp": 8,
				"requires": ["local_p2_t1"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p2_t3", "name": "Teaching Grandpa New Tricks",
				"subtitle": "Farmer Training Workshop",
				"description": "Teach crop rotation to farmers who have been farming since before you were born. Bring humility.",
				"primary_stat": "charm", "secondary_stat": "communication",
				"duration": 2, "reward_cash": 500, "reward_cp": 8,
				"requires": ["local_p2_t2"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p2_t4", "name": "Seeds Are Not Snacks",
				"subtitle": "Seed Selection & Distribution",
				"description": "Source quality seeds. Distribute to 80 families. Explain that these are for planting, not eating. Twice.",
				"primary_stat": "procurement", "secondary_stat": "logistics",
				"duration": 3, "reward_cash": 700, "reward_cp": 10,
				"requires": ["local_p2_t2"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p2_t5", "name": "Goat-Proof Monitoring",
				"subtitle": "Crop Monitoring Setup",
				"description": "Install monitoring points across 30 hectares. The goats will eat 4 of them. Budget for 5.",
				"primary_stat": "technical", "secondary_stat": "management",
				"duration": 2, "reward_cash": 600, "reward_cp": 8,
				"requires": ["local_p2_t2"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
		],
	}

func _build_project_3() -> Dictionary:
	return {
		"id":                  "local_p3",
		"name":                "Water Finds a Way",
		"subtitle":            "Village Water & Irrigation",
		"description":         "Three villages, one river, zero infrastructure. The water is technically there. Getting it to the rice fields requires an engineering degree and a miracle.",
		"unlock_type":         "donor",
		"unlock_donor_id":     "gov_agency",
		"reward_cash":         8000,
		"reward_cp":           60,
		"reward_rep":          25,
		"status":              "locked",
		"idle_months":         0,
		"completion_percent":  0.0,
		"_had_work_this_month": false,
		"tasks": [
			{
				"id": "local_p3_t1", "name": "Is That a River or a Myth?",
				"subtitle": "Water Source Survey",
				"description": "Find every water source within 20km. Map them. Discover that 3 are seasonal and 1 is a myth.",
				"primary_stat": "technical", "secondary_stat": "precision",
				"duration": 2, "reward_cash": 600, "reward_cp": 8,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t2", "name": "The Intern Labels Everything Wrong",
				"subtitle": "GIS Land Mapping",
				"description": "Map every hectare with satellite data. The satellite is accurate. Your intern's labeling is not.",
				"primary_stat": "technical", "secondary_stat": "focus",
				"duration": 3, "reward_cash": 800, "reward_cp": 10,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t3", "name": "Someone Brought a Lawyer",
				"subtitle": "Community Consultation",
				"description": "Hold 5 village meetings to discuss water rights. Meeting 1: productive. Meeting 5: someone brought a lawyer.",
				"primary_stat": "charm", "secondary_stat": "management",
				"duration": 2, "reward_cash": 500, "reward_cp": 8,
				"requires": [],
				"status": "available", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t4", "name": "Village 3 Will Still Complain",
				"subtitle": "Irrigation Design Blueprint",
				"description": "Design canals that serve 3 villages equally. Village 3 will still complain they got less.",
				"primary_stat": "technical", "secondary_stat": "management",
				"duration": 3, "reward_cash": 900, "reward_cp": 12,
				"requires": ["local_p3_t1", "local_p3_t2"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t5", "name": "The Excavator Is Late. Again.",
				"subtitle": "Procurement & Materials",
				"description": "Order 2km of PVC pipe, 500 cement bags, and 1 excavator rental. The excavator arrives 3 weeks late. Classic.",
				"primary_stat": "procurement", "secondary_stat": "logistics",
				"duration": 3, "reward_cash": 800, "reward_cp": 8,
				"requires": ["local_p3_t4"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t6", "name": "Noodle Stand Supervisor",
				"subtitle": "Construction Supervision",
				"description": "Supervise 40 workers building canals in 38-degree heat. Motivation tool: cold water and loud music.",
				"primary_stat": "management", "secondary_stat": "technical",
				"duration": 4, "reward_cash": 1200, "reward_cp": 12,
				"requires": ["local_p3_t4", "local_p3_t5"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
			{
				"id": "local_p3_t7", "name": "Pray, Then Turn It On",
				"subtitle": "System Testing & Handover",
				"description": "Turn on the water. Pray. Fix the 3 leaks. Turn it on again. Celebrate when rice fields actually flood.",
				"primary_stat": "technical", "secondary_stat": "communication",
				"duration": 2, "reward_cash": 800, "reward_cp": 10,
				"requires": ["local_p3_t6"],
				"status": "blocked", "progress": 0.0, "assigned_employee_ids": [],
			},
		],
	}

# ─────────────────────────────────────────
#  SIGNAL CONNECTIONS
# ─────────────────────────────────────────
func _connect_signals() -> void:
	var cm: Node = get_node_or_null("/root/ClockManager")
	if cm != null:
		if not cm.work_day_started.is_connected(_on_work_day_started):
			cm.work_day_started.connect(_on_work_day_started)
		if not cm.month_changed.is_connected(_on_month_changed):
			cm.month_changed.connect(_on_month_changed)
	var dm: Node = get_node_or_null("/root/DonorManager")
	if dm != null:
		if not dm.donor_won.is_connected(_on_donor_won):
			dm.donor_won.connect(_on_donor_won)

# ─────────────────────────────────────────
#  PUBLIC API — NEW
# ─────────────────────────────────────────
func get_current_area() -> Dictionary:
	return _area

func get_projects() -> Array:
	return _area.get("projects", [])

func get_tasks_for_project(project_id: String) -> Array:
	for proj in get_projects():
		if proj.get("id", "") == project_id:
			return proj.get("tasks", [])
	return []

func assign_employee_to_task(task_id: String, employee_id: String) -> bool:
	var task: Dictionary = _find_task(task_id)
	if task.is_empty():
		return false
	var cur_status: String = task.get("status", "")
	if cur_status == "blocked" or cur_status == "completed":
		return false
	var ids: Array = task.get("assigned_employee_ids", [])
	if ids.size() >= MAX_EMPLOYEES_PER_TASK:
		return false
	if employee_id in ids:
		return false
	ids.append(employee_id)
	task["assigned_employee_ids"] = ids
	task["status"] = "in_progress"
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		for emp in gm.employees.get_hired_employees():
			if str(emp.id) == employee_id:
				emp.is_assigned_to_project = true
				emp.current_project_id = task_id
				break
	var proj: Dictionary = _find_project_for_task(task_id)
	_update_project_status(proj)
	projects_updated.emit()
	return true

func unassign_employee_from_task(task_id: String, employee_id: String) -> bool:
	var task: Dictionary = _find_task(task_id)
	if task.is_empty():
		return false
	var ids: Array = task.get("assigned_employee_ids", [])
	if employee_id not in ids:
		return false
	ids.erase(employee_id)
	task["assigned_employee_ids"] = ids
	if ids.is_empty() and task.get("status", "") == "in_progress":
		task["status"] = "available"
	if not _is_employee_assigned_anywhere(employee_id):
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			for emp in gm.employees.get_hired_employees():
				if str(emp.id) == employee_id:
					emp.is_assigned_to_project = false
					emp.current_project_id = ""
					break
	var proj: Dictionary = _find_project_for_task(task_id)
	_update_project_status(proj)
	projects_updated.emit()
	return true

func unlock_project(project_id: String) -> void:
	for proj in get_projects():
		if proj.get("id", "") == project_id:
			if proj.get("status", "") == "locked":
				proj["status"] = "available"
				_refresh_task_deps(proj)
				projects_updated.emit()
			return

func is_project_unlocked(project_id: String) -> bool:
	for proj in get_projects():
		if proj.get("id", "") == project_id:
			return proj.get("status", "") != "locked"
	return false

# ─────────────────────────────────────────
#  PUBLIC API — LEGACY (backward compat)
# ─────────────────────────────────────────
func get_active_projects() -> Array:
	var result: Array = []
	for proj in get_projects():
		var s: String = proj.get("status", "")
		if s == "in_progress":
			result.append(proj)
	return result

func get_available_projects() -> Array:
	var result: Array = []
	for proj in get_projects():
		var s: String = proj.get("status", "")
		if s == "available" or s == "in_progress":
			result.append(proj)
	return result

func accept_project(project_id: Variant) -> bool:
	var pid: String = str(project_id)
	for proj in get_projects():
		if proj.get("id", "") == pid:
			if proj.get("status", "") == "available":
				proj["status"] = "in_progress"
				projects_updated.emit()
				return true
	return false

func assign_employee(project_id: Variant, employee_id: String, _gm: Node) -> bool:
	# Legacy bridge: assigns to the first available/in_progress task in project
	var pid: String = str(project_id)
	for task in get_tasks_for_project(pid):
		var s: String = task.get("status", "")
		if s == "available" or s == "in_progress":
			return assign_employee_to_task(task.get("id", ""), employee_id)
	return false

func remove_employee_from_all_projects(emp_id: String, _gm: Node) -> void:
	for proj in get_projects():
		for task in proj.get("tasks", []):
			var ids: Array = task.get("assigned_employee_ids", [])
			if emp_id in ids:
				ids.erase(emp_id)
				task["assigned_employee_ids"] = ids
				if ids.is_empty() and task.get("status", "") == "in_progress":
					task["status"] = "available"
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		for emp in gm.employees.get_hired_employees():
			if str(emp.id) == emp_id:
				emp.is_assigned_to_project = false
				emp.current_project_id = ""
				break
	projects_updated.emit()

func set_project_flag(project_id: Variant, flag: String, value: Variant) -> void:
	var pid: String = str(project_id)
	for proj in get_projects():
		if proj.get("id", "") == pid:
			proj[flag] = value
			return

func tick_projects(_gm: Node) -> void:
	pass  # Ticking is handled by ClockManager signal

func generate_new_projects(_count: int) -> void:
	pass  # No longer needed — project data is fixed

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func to_save_array() -> Array:
	var proj_states: Array = []
	for proj in get_projects():
		var task_states: Array = []
		for task in proj.get("tasks", []):
			task_states.append({
				"id":                    task.get("id", ""),
				"status":                task.get("status", "available"),
				"progress":              task.get("progress", 0.0),
				"assigned_employee_ids": task.get("assigned_employee_ids", []).duplicate(),
			})
		proj_states.append({
			"id":                 proj.get("id", ""),
			"status":             proj.get("status", "available"),
			"idle_months":        proj.get("idle_months", 0),
			"completion_percent": proj.get("completion_percent", 0.0),
			"tasks":              task_states,
		})
	return [{
		"_v":              2,
		"unlocked_donors": _unlocked_donor_ids.duplicate(),
		"projects":        proj_states,
	}]

func load_projects(data: Array) -> void:
	_area = _build_area()
	_connect_signals()
	if data.is_empty():
		projects_updated.emit()
		return
	var entry: Dictionary = data[0]
	if entry.get("_v", 1) != 2:
		# Old save format — start fresh with new data
		projects_updated.emit()
		return
	_unlocked_donor_ids.clear()
	for d in entry.get("unlocked_donors", []):
		_unlocked_donor_ids.append(str(d))
	var saved_projs: Array = entry.get("projects", [])
	for saved_proj in saved_projs:
		var pid: String = saved_proj.get("id", "")
		for proj in get_projects():
			if proj.get("id", "") != pid:
				continue
			proj["status"]             = saved_proj.get("status", "locked")
			proj["idle_months"]        = int(saved_proj.get("idle_months", 0))
			proj["completion_percent"] = float(saved_proj.get("completion_percent", 0.0))
			var saved_tasks: Array = saved_proj.get("tasks", [])
			for saved_task in saved_tasks:
				var tid: String = saved_task.get("id", "")
				for task in proj.get("tasks", []):
					if task.get("id", "") != tid:
						continue
					task["status"]                = saved_task.get("status", "blocked")
					task["progress"]              = float(saved_task.get("progress", 0.0))
					task["assigned_employee_ids"] = saved_task.get("assigned_employee_ids", []).duplicate()
	projects_updated.emit()

# ─────────────────────────────────────────
#  CLOCK TICK — work_day_started
# ─────────────────────────────────────────
func _on_work_day_started() -> void:
	print("[PM] === TICK FIRED ===")
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		print("[PM] ERROR: GameManager not found, skipping tick")
		return
	var projects: Array = get_projects()
	print("[PM-DEBUG] Area has %d projects" % projects.size())
	for proj in projects:
		var proj_status: String = proj.get("status", "")
		if proj_status == "locked" or proj_status == "completed":
			continue
		var proj_tasks: Array = proj.get("tasks", [])
		print("[PM-DEBUG] Project '%s' status=%s tasks=%d" % [proj.get("name", ""), proj_status, proj_tasks.size()])
		# Track whether any task has assigned employees (for idle_months decay)
		var proj_had_work: bool = false
		for task in proj_tasks:
			var task_status: String = task.get("status", "")
			var emp_ids: Array = task.get("assigned_employee_ids", [])
			print("[PM-DEBUG]   Task '%s' status=%s assigned=%d" % [task.get("name", ""), task_status, emp_ids.size()])
			if task_status == "in_progress" and not emp_ids.is_empty():
				proj_had_work = true
		if proj_had_work:
			proj["_had_work_this_month"] = true
		# Refresh dependency unlocks each tick
		_refresh_task_deps(proj)

func _get_employee(gm_or_id: Variant, emp_id_arg: String = "") -> Employee:
	# Supports both legacy call _get_employee(gm, id) and new call _get_employee(id)
	var gm: Node = null
	var emp_id: String = ""
	if gm_or_id is String:
		gm = get_node_or_null("/root/GameManager")
		emp_id = gm_or_id as String
	else:
		gm = gm_or_id as Node
		emp_id = emp_id_arg
	if gm != null and gm.employees != null:
		return gm.employees.get_employee_by_id(emp_id)
	return null

func _get_stat(emp: Employee, stat_name: String) -> int:
	match stat_name:
		"charm":         return emp.charm
		"technical":     return emp.technical
		"procurement":   return emp.procurement
		"focus":         return emp.focus
		"communication": return emp.communication
		"management":    return emp.management
		"logistics":     return emp.logistics
		"precision":     return emp.precision
	return 0

func _add_stat(emp: Employee, stat_name: String, amount: int) -> void:
	match stat_name:
		"charm": emp.charm = mini(emp.charm + amount, 1000)
		"technical": emp.technical = mini(emp.technical + amount, 1000)
		"procurement": emp.procurement = mini(emp.procurement + amount, 1000)
		"focus": emp.focus = mini(emp.focus + amount, 1000)
		"communication": emp.communication = mini(emp.communication + amount, 1000)
		"management": emp.management = mini(emp.management + amount, 1000)
		"logistics": emp.logistics = mini(emp.logistics + amount, 1000)
		"precision": emp.precision = mini(emp.precision + amount, 1000)

# ─────────────────────────────────────────
#  WORK ROUND SYSTEM
# ─────────────────────────────────────────
func run_work_round(task_id: String) -> Dictionary:
	# Find the task
	var task: Dictionary = _find_task(task_id)
	if task.is_empty():
		return {"error": "Task not found"}
	if task.get("status", "") != "in_progress":
		return {"error": "Task not in progress"}

	var emp_ids: Array = task.get("assigned_employee_ids", [])
	if emp_ids.is_empty():
		return {"error": "No employees assigned"}

	# Determine CP cost based on task duration
	var duration: int = int(task.get("duration_ticks", task.get("duration", 2)))
	var cp_cost: int = 3
	if duration >= 5:
		cp_cost = 8
	elif duration >= 3:
		cp_cost = 5

	# First round ever is free
	var gm: Node = get_node_or_null("/root/GameManager")
	var total_rounds: int = gm.total_rounds_played if gm else 0
	var was_free: bool = total_rounds == 0
	var actual_cp_cost: int = 0

	if not was_free:
		if gm and gm.corp_points < cp_cost:
			return {"error": "Not enough CP! Need %d CP (have %d)" % [cp_cost, gm.corp_points]}
		if gm:
			gm.corp_points -= cp_cost
		actual_cp_cost = cp_cost

	# Track total rounds
	if gm:
		gm.total_rounds_played += 1

	# Calculate contributions
	var results: Array[Dictionary] = []
	var total_progress: float = 0.0
	var combo_bonus: float = _calculate_combo(emp_ids, task)

	for emp_id in emp_ids:
		var emp: Employee = _get_employee(emp_id)
		if emp == null:
			continue
		var primary_stat: String = task.get("primary_stat", "technical")
		var secondary_stat: String = task.get("secondary_stat", "focus")
		var primary_val: int = _get_stat(emp, primary_stat)
		var secondary_val: int = _get_stat(emp, secondary_stat)

		var contribution: float = (primary_val / 1000.0) * 0.60 + (secondary_val / 1000.0) * 0.30 + combo_bonus
		total_progress += contribution

		# Stat gains placeholder (set after grade)
		var grade_multiplier: float = 1.0
		var primary_gain: int = 0
		var secondary_gain: int = 0

		results.append({
			"employee_name": emp.full_name(),
			"employee_role": emp.role,
			"primary_stat_name": primary_stat,
			"primary_stat_value": primary_val,
			"secondary_stat_name": secondary_stat,
			"secondary_stat_value": secondary_val,
			"contribution": contribution,
		})

	# Determine grade
	var grade: String = "F"
	var grade_text: String = ""
	if total_progress >= 0.80:
		grade = "S"
		grade_text = "Outstanding! Your donor is crying tears of joy."
	elif total_progress >= 0.60:
		grade = "A"
		grade_text = "Excellent work. The report practically wrote itself."
	elif total_progress >= 0.45:
		grade = "B"
		grade_text = "Solid effort. Nothing caught fire. That's a win."
	elif total_progress >= 0.30:
		grade = "C"
		grade_text = "Adequate. Like a C+ in college. You passed."
	elif total_progress >= 0.15:
		grade = "D"
		grade_text = "Below expectations. HR is 'concerned.'"
	else:
		grade = "F"
		grade_text = "Did anyone actually show up? Asking for a friend."

	# Apply progress
	var old_progress: float = task.get("progress", 0.0)
	task["progress"] = minf(old_progress + total_progress, 1.0)

	# Calculate partial rewards based on grade
	var reward_pct: float = 0.05
	match grade:
		"S": reward_pct = 0.30
		"A": reward_pct = 0.25
		"B": reward_pct = 0.20
		"C": reward_pct = 0.15
		"D": reward_pct = 0.10
		"F": reward_pct = 0.05

	var task_cash: int = task.get("reward_cash", 0)
	var task_cp: int = task.get("reward_cp", 0)
	var round_cash: int = int(task_cash * reward_pct)
	var round_cp: int = int(task_cp * reward_pct)

	# Pay partial reward
	if gm and gm.economy:
		gm.economy.add_revenue(round_cash, "Task round: %s" % task.get("name", ""))
	if gm:
		gm.corp_points = gm.corp_points + round_cp

	# Apply stat gains to employees
	var stat_gains: Array[Dictionary] = []
	for emp_id in emp_ids:
		var emp: Employee = _get_employee(emp_id)
		if emp == null:
			continue
		var primary_gain: int = 0
		var secondary_gain: int = 0
		match grade:
			"S":
				primary_gain = 3
				secondary_gain = 2
			"A":
				primary_gain = 2
				secondary_gain = 1
			"B":
				primary_gain = 2
				secondary_gain = 1
			"C":
				primary_gain = 1
				secondary_gain = 1
			"D":
				primary_gain = 1
				secondary_gain = 0
			"F":
				primary_gain = 0
				secondary_gain = 0

		var ps: String = task.get("primary_stat", "technical")
		var ss: String = task.get("secondary_stat", "focus")
		_add_stat(emp, ps, primary_gain)
		_add_stat(emp, ss, secondary_gain)
		stat_gains.append({
			"name": emp.full_name(),
			"primary_stat": ps,
			"primary_gain": primary_gain,
			"secondary_stat": ss,
			"secondary_gain": secondary_gain,
		})

	# Check task completion
	var task_completed_flag: bool = task.get("progress", 0.0) >= 1.0
	var completion_cp_bonus: int = 0
	if task_completed_flag:
		task["status"] = "completed"
		var task_duration: int = int(task.get("duration_ticks", task.get("duration", 2)))
		completion_cp_bonus = 10
		if task_duration >= 5:
			completion_cp_bonus = 25
		elif task_duration >= 3:
			completion_cp_bonus = 15
		if gm:
			gm.corp_points += completion_cp_bonus
		var proj: Dictionary = _find_project_for_task(task_id)
		_refresh_task_deps(proj)
		if gm:
			_update_project_completion(proj, gm)
		task_completed.emit(task)

	projects_updated.emit()

	# Return full result for UI
	return {
		"task_name": task.get("name", ""),
		"task_subtitle": task.get("subtitle", ""),
		"grade": grade,
		"grade_text": grade_text,
		"total_progress": total_progress,
		"task_progress": task.get("progress", 0.0),
		"task_completed": task_completed_flag,
		"round_cash": round_cash,
		"round_cp": round_cp,
		"cp_cost": actual_cp_cost,
		"was_free": was_free,
		"completion_cp_bonus": completion_cp_bonus,
		"combo_bonus": combo_bonus,
		"combo_name": _get_combo_name(emp_ids),
		"employee_results": results,
		"stat_gains": stat_gains,
	}

func _calculate_combo(emp_ids: Array, task: Dictionary) -> float:
	var roles: Array[int] = []
	for emp_id in emp_ids:
		var emp: Employee = _get_employee(emp_id)
		if emp:
			roles.append(emp.role)
	roles.sort()

	# Full Stack NGO: OPS + PROCUREMENT + MANAGEMENT
	if 0 in roles and 1 in roles and 3 in roles:
		return 0.25
	# Field & Office: OPS + SECRETARY
	if 0 in roles and 2 in roles:
		return 0.15
	# Money Talks: FINANCE + PROCUREMENT
	if 4 in roles and 1 in roles:
		return 0.15
	# The A-Team: OPS + MANAGEMENT
	if 0 in roles and 3 in roles:
		return 0.15
	# Smooth Operators: SECRETARY + MANAGEMENT
	if 2 in roles and 3 in roles:
		return 0.10
	# Dream Team: Any 3 different roles
	var unique_roles: Array = []
	for r in roles:
		if r not in unique_roles:
			unique_roles.append(r)
	if unique_roles.size() >= 3:
		return 0.10
	return 0.0

func _get_combo_name(emp_ids: Array) -> String:
	var roles: Array[int] = []
	for emp_id in emp_ids:
		var emp: Employee = _get_employee(emp_id)
		if emp:
			roles.append(emp.role)
	if 0 in roles and 1 in roles and 3 in roles:
		return "Full Stack NGO"
	if 0 in roles and 2 in roles:
		return "Field & Office"
	if 4 in roles and 1 in roles:
		return "Money Talks"
	if 0 in roles and 3 in roles:
		return "The A-Team"
	if 2 in roles and 3 in roles:
		return "Smooth Operators"
	var unique: Array = []
	for r in roles:
		if r not in unique:
			unique.append(r)
	if unique.size() >= 3:
		return "The Dream Team"
	return ""

# ─────────────────────────────────────────
#  CLOCK TICK — month_changed
# ─────────────────────────────────────────
func _on_month_changed(_month: int, _year: int) -> void:
	var any_changed: bool = false
	for proj in get_projects():
		var proj_status: String = proj.get("status", "")
		if proj_status == "locked" or proj_status == "completed":
			proj["_had_work_this_month"] = false
			continue
		if not proj.get("_had_work_this_month", false):
			var idle: int = int(proj.get("idle_months", 0)) + 1
			proj["idle_months"] = idle
			if idle >= IDLE_MONTHS_BEFORE_DECAY:
				_apply_decay(proj)
				any_changed = true
		proj["_had_work_this_month"] = false
	if any_changed:
		projects_updated.emit()

# ─────────────────────────────────────────
#  DONOR SIGNAL
# ─────────────────────────────────────────
func _on_donor_won(donor_name: String, _monthly: int) -> void:
	var donor_id: String = _DONOR_NAME_MAP.get(donor_name, "")
	if donor_id == "" or donor_id in _unlocked_donor_ids:
		return
	_unlocked_donor_ids.append(donor_id)
	for proj in get_projects():
		if proj.get("unlock_donor_id", "") == donor_id:
			unlock_project(proj.get("id", ""))

# ─────────────────────────────────────────
#  TASK COMPLETION
# ─────────────────────────────────────────
func _complete_task(task_id: String, proj: Dictionary, gm: Node) -> void:
	var task: Dictionary = _find_task(task_id)
	if task.is_empty():
		return
	task["status"]   = "completed"
	task["progress"] = 1.0
	gm.economy.add_revenue(
		task.get("reward_cash", 0),
		"Task: " + task.get("name", "")
	)
	gm.add_corp_points(task.get("reward_cp", 0))
	print("[ProjectManager] Task done: %s  +$%d +%d CP" % [
		task.get("name", ""), task.get("reward_cash", 0), task.get("reward_cp", 0)
	])
	task_completed.emit(task)
	_refresh_task_deps(proj)

func _refresh_task_deps(proj: Dictionary) -> void:
	if proj.get("status", "") == "locked":
		return
	for task in proj.get("tasks", []):
		var cur: String = task.get("status", "")
		if cur not in ["blocked", "available"]:
			continue
		var reqs: Array = task.get("requires", [])
		if reqs.is_empty():
			if cur == "blocked":
				task["status"] = "available"
			continue
		var all_met: bool = true
		for req_id in reqs:
			var req_task: Dictionary = _find_task_in_proj(req_id, proj)
			if req_task.get("status", "") != "completed":
				all_met = false
				break
		if all_met and cur == "blocked":
			task["status"] = "available"
		elif not all_met and cur == "available":
			task["status"] = "blocked"

func _update_project_completion(proj: Dictionary, gm: Node) -> void:
	if proj.get("status", "") == "completed":
		return
	var tasks: Array = proj.get("tasks", [])
	if tasks.is_empty():
		return
	var done_count: int = 0
	for task in tasks:
		if task.get("status", "") == "completed":
			done_count += 1
	var pct: float = float(done_count) / float(tasks.size())
	proj["completion_percent"] = pct
	if pct >= PROJECT_COMPLETION_THRESHOLD:
		proj["status"] = "completed"
		gm.economy.add_revenue(
			proj.get("reward_cash", 0),
			"Project: " + proj.get("name", "")
		)
		gm.add_corp_points(proj.get("reward_cp", 0))
		var rep: int = int(proj.get("reward_rep", 0))
		gm.company_data["reputation"] = gm.company_data.get("reputation", 0) + rep
		print("[ProjectManager] Project done: %s  +$%d +%d CP +%d REP" % [
			proj.get("name", ""), proj.get("reward_cash", 0),
			proj.get("reward_cp", 0), rep
		])
		project_completed.emit(proj)
		projects_updated.emit()

func _update_project_status(proj: Dictionary) -> void:
	if proj.is_empty():
		return
	var s: String = proj.get("status", "")
	if s == "locked" or s == "completed":
		return
	for task in proj.get("tasks", []):
		if task.get("status", "") == "in_progress":
			proj["status"] = "in_progress"
			return
	if s == "in_progress":
		proj["status"] = "available"

func _apply_decay(proj: Dictionary) -> void:
	# Regress the last completed task to simulate month-over-month decay
	var tasks: Array = proj.get("tasks", [])
	for i: int in range(tasks.size() - 1, -1, -1):
		var task: Dictionary = tasks[i]
		if task.get("status", "") == "completed":
			task["status"]   = "in_progress"
			task["progress"] = maxf(0.0, 1.0 - DECAY_RATE_PER_MONTH)
			_refresh_task_deps(proj)
			print("[ProjectManager] Decay: %s task regressed in %s" % [
				task.get("name", ""), proj.get("name", "")
			])
			return

# ─────────────────────────────────────────
#  LOOKUP HELPERS
# ─────────────────────────────────────────
func _find_task(task_id: String) -> Dictionary:
	for proj in get_projects():
		var result: Dictionary = _find_task_in_proj(task_id, proj)
		if not result.is_empty():
			return result
	return {}

func _find_task_in_proj(task_id: String, proj: Dictionary) -> Dictionary:
	for task in proj.get("tasks", []):
		if task.get("id", "") == task_id:
			return task
	return {}

func _find_project_for_task(task_id: String) -> Dictionary:
	for proj in get_projects():
		for task in proj.get("tasks", []):
			if task.get("id", "") == task_id:
				return proj
	return {}

func _is_employee_assigned_anywhere(emp_id: String) -> bool:
	for proj in get_projects():
		for task in proj.get("tasks", []):
			if emp_id in task.get("assigned_employee_ids", []):
				return true
	return false
