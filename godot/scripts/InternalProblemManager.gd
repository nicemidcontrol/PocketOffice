extends Node

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal warning_issued(warning: Dictionary)
signal problem_escalated(warning: Dictionary)
signal employee_resigned(emp_id: String, emp_name: String)
signal employee_burned_out(emp_id: String, emp_name: String)

# ------------------------------------------
#  STATE
# ------------------------------------------
var active_warnings: Array = []

# ------------------------------------------
#  INIT
# ------------------------------------------
func _ready() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.month_passed.connect(_on_month_passed)

# ------------------------------------------
#  MONTHLY UPDATE
# ------------------------------------------
func _on_month_passed(_month: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	_check_burnout(gm)
	_check_team_conflict(gm)
	_check_resignation(gm)
	_check_overcrowding(gm)
	_check_idle_staff(gm)

# ------------------------------------------
#  CHECK 1 — BURNOUT
# ------------------------------------------
func _check_burnout(gm: Node) -> void:
	for emp in gm.employees.get_hired_employees():
		if emp.ot_level > 0:
			emp.ot_months_consecutive += 1
		else:
			emp.ot_months_consecutive = 0
		if emp.ot_months_consecutive >= 3 and not emp.is_burned_out:
			emp.is_burned_out = true
			emp.motivation = 0
			emp.ot_months_consecutive = 0
			# Remove from all projects
			if gm.projects != null:
				gm.projects.remove_employee_from_all_projects(emp.id, gm)
			emp.is_assigned_to_project = false
			emp.current_project_id = ""
			var w: Dictionary = {
				"type": "burnout",
				"emp_id": emp.id,
				"emp_name": emp.full_name(),
				"message": emp.full_name() + " has burned out from sustained overtime.",
				"escalated": true
			}
			active_warnings.append(w)
			employee_burned_out.emit(emp.id, emp.full_name())
			problem_escalated.emit(w)

# ------------------------------------------
#  CHECK 2 — TEAM CONFLICT
# ------------------------------------------
func _check_team_conflict(gm: Node) -> void:
	if gm.projects == null:
		return
	var active: Array = gm.projects.get_active_projects()
	for proj in active:
		var ids: Array = proj.get("assigned_employee_ids", [])
		var has_gossip: bool = false
		var has_workaholic: bool = false
		for emp in gm.employees.get_hired_employees():
			if emp.id not in ids:
				continue
			if emp.personality == 3:   # GOSSIP
				has_gossip = true
			if emp.personality == 1:   # WORKAHOLIC
				has_workaholic = true
		if not (has_gossip and has_workaholic):
			continue
		var pid: int = proj.get("id", -1)
		var key: String = "conflict_" + str(pid)
		if _has_warning(key):
			var w: Dictionary = _get_warning(key)
			w["escalated"] = true
			problem_escalated.emit(w)
			gm.projects.set_project_flag(pid, "conflict_penalty", true)
		else:
			var w: Dictionary = {
				"type": "team_conflict",
				"key": key,
				"project_id": pid,
				"project_name": proj.get("name", "Project"),
				"message": "Team friction detected on " + proj.get("name", "Project") + ". Gossip and Workaholic personalities clashing.",
				"escalated": false
			}
			active_warnings.append(w)
			warning_issued.emit(w)

# ------------------------------------------
#  CHECK 3 — RESIGNATION
# ------------------------------------------
func _check_resignation(gm: Node) -> void:
	var to_fire: Array = []
	for emp in gm.employees.get_hired_employees():
		if emp.motivation <= 10:
			emp.low_morale_months += 1
		else:
			emp.low_morale_months = 0
		if emp.low_morale_months >= 2:
			to_fire.append(emp)
	for emp in to_fire:
		var key: String = "resign_" + emp.id
		var name: String = emp.full_name()
		var emp_id: String = emp.id
		if _has_warning(key):
			_remove_warning(key)
			gm.employees.fire(emp)
			if gm.projects != null:
				gm.projects.remove_employee_from_all_projects(emp_id, gm)
			var w: Dictionary = {
				"type": "resignation",
				"emp_id": emp_id,
				"emp_name": name,
				"message": name + " has resigned due to sustained low morale.",
				"escalated": true
			}
			active_warnings.append(w)
			employee_resigned.emit(emp_id, name)
			problem_escalated.emit(w)
		else:
			var w: Dictionary = {
				"type": "low_morale",
				"key": key,
				"emp_id": emp.id,
				"emp_name": emp.full_name(),
				"message": emp.full_name() + " has critically low morale and may resign.",
				"escalated": false
			}
			active_warnings.append(w)
			warning_issued.emit(w)

# ------------------------------------------
#  CHECK 4 — OVERCROWDING
# ------------------------------------------
func _check_overcrowding(gm: Node) -> void:
	var hired: Array = gm.employees.get_hired_employees()
	if hired.size() <= 8:
		return
	for emp in hired:
		emp.adjust_motivation(-5)
	var key: String = "overcrowding"
	if _has_warning(key):
		var w: Dictionary = _get_warning(key)
		w["escalated"] = true
		problem_escalated.emit(w)
	else:
		var w: Dictionary = {
			"type": "overcrowding",
			"key": key,
			"message": "Office is overcrowded (" + str(hired.size()) + " employees). Morale is declining.",
			"escalated": false
		}
		active_warnings.append(w)
		warning_issued.emit(w)

# ------------------------------------------
#  CHECK 5 — IDLE STAFF
# ------------------------------------------
func _check_idle_staff(gm: Node) -> void:
	for emp in gm.employees.get_hired_employees():
		if not emp.is_assigned_to_project:
			emp.idle_months += 1
		else:
			emp.idle_months = 0
		if emp.idle_months >= 2:
			emp.adjust_motivation(-5)
			var key: String = "idle_" + emp.id
			if _has_warning(key):
				var w: Dictionary = _get_warning(key)
				w["escalated"] = true
				problem_escalated.emit(w)
			else:
				var w: Dictionary = {
					"type": "idle_staff",
					"key": key,
					"emp_id": emp.id,
					"emp_name": emp.full_name(),
					"message": emp.full_name() + " has been idle for " + str(emp.idle_months) + " months.",
					"escalated": false
				}
				active_warnings.append(w)
				warning_issued.emit(w)

# ------------------------------------------
#  WARNING HELPERS
# ------------------------------------------
func _has_warning(key: String) -> bool:
	for w in active_warnings:
		if w.get("key", "") == key:
			return true
	return false

func _get_warning(key: String) -> Dictionary:
	for w in active_warnings:
		if w.get("key", "") == key:
			return w
	return {}

func _remove_warning(key: String) -> void:
	for i: int in range(active_warnings.size() - 1, -1, -1):
		if active_warnings[i].get("key", "") == key:
			active_warnings.remove_at(i)
			return

# ------------------------------------------
#  PUBLIC API
# ------------------------------------------
func get_active_warnings() -> Array:
	return active_warnings.duplicate(true)

func has_active_warnings() -> bool:
	return not active_warnings.is_empty()

func dismiss_warning(key: String) -> void:
	_remove_warning(key)
