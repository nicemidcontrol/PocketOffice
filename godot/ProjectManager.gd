extends Node

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal project_completed(project: Dictionary)
signal projects_updated
signal complication_triggered(project: Dictionary, complication: Dictionary)

# ------------------------------------------
#  LOCAL AREA PROJECTS  (Economy Bible Tier 1)
# ------------------------------------------
# required_role int values match Employee.Role enum:
#   0=DEVELOPER  1=DESIGNER  2=MARKETER  3=HR_SPECIALIST
#   4=ACCOUNTANT  5=MANAGER  6=INTERN
# duration_ticks maps to Economy Bible months: 3mo=3, 4mo=4, 5mo=5, 6mo=6
const LOCAL_PROJECTS: Array = [
	{
		"name": "Farmer Training Workshop",
		"description": "Run hands-on agricultural training sessions for local farmers.",
		"project_type": "agriculture", "required_role": 3,
		"primary_stat": "community", "secondary_stat": "planning",
		"duration_ticks": 3,
		"reward_cash": 1200, "reward_corp_points": 15, "reward_reputation": 5,
	},
	{
		"name": "Soil Quality Assessment",
		"description": "Conduct technical soil sampling and analysis across the region.",
		"project_type": "agriculture", "required_role": 0,
		"primary_stat": "technical", "secondary_stat": "procurement",
		"duration_ticks": 4,
		"reward_cash": 1800, "reward_corp_points": 20, "reward_reputation": 5,
	},
	{
		"name": "Community Nutrition Survey",
		"description": "Survey households to map nutrition gaps and food security status.",
		"project_type": "agriculture", "required_role": 2,
		"primary_stat": "community", "secondary_stat": "technical",
		"duration_ticks": 4,
		"reward_cash": 1500, "reward_corp_points": 15, "reward_reputation": 10,
	},
	{
		"name": "Seed Distribution Program",
		"description": "Procure and distribute improved seed varieties to smallholder farmers.",
		"project_type": "agriculture", "required_role": 4,
		"primary_stat": "procurement", "secondary_stat": "community",
		"duration_ticks": 5,
		"reward_cash": 2200, "reward_corp_points": 20, "reward_reputation": 5,
	},
	{
		"name": "GIS Land Mapping",
		"description": "Create detailed GIS maps of arable land and water access points.",
		"project_type": "agriculture", "required_role": 0,
		"primary_stat": "technical", "secondary_stat": "planning",
		"duration_ticks": 5,
		"reward_cash": 2500, "reward_corp_points": 25, "reward_reputation": 5,
	},
	{
		"name": "Basic Agricultural Equipment Audit",
		"description": "Audit the condition and distribution of farm equipment in the area.",
		"project_type": "agriculture", "required_role": 4,
		"primary_stat": "procurement", "secondary_stat": "technical",
		"duration_ticks": 4,
		"reward_cash": 2000, "reward_corp_points": 15, "reward_reputation": 3,
	},
	{
		"name": "Crop Rotation Planning",
		"description": "Develop seasonal crop rotation schedules to improve soil health.",
		"project_type": "agriculture", "required_role": 0,
		"primary_stat": "planning", "secondary_stat": "technical",
		"duration_ticks": 5,
		"reward_cash": 2000, "reward_corp_points": 30, "reward_reputation": 3,
	},
	{
		"name": "Water Irrigation Planning",
		"description": "Design efficient irrigation networks for local farmland.",
		"project_type": "agriculture", "required_role": 0,
		"primary_stat": "technical", "secondary_stat": "planning",
		"duration_ticks": 6,
		"reward_cash": 3000, "reward_corp_points": 25, "reward_reputation": 8,
	},
]

# ------------------------------------------
#  COMPLICATIONS
# ------------------------------------------
const _COMPLICATIONS: Array = [
	{
		"id": "scope_creep",
		"label": "Scope Creep",
		"description": "Requirements expanded mid-project. Progress slows by 25%.",
		"effect_type": "slow",
		"effect_value": 0.75,
		"fix_options": [
			{"label": "Renegotiate Scope (15 CP)", "cost_type": "cp", "cost_value": 15},
			{"label": "Extend Deadline (accept slow)", "cost_type": "none", "cost_value": 0}
		]
	},
	{
		"id": "key_emp_sick",
		"label": "Key Employee Sick",
		"description": "A key team member is out sick. Output drops significantly.",
		"effect_type": "slow",
		"effect_value": 0.5,
		"fix_options": [
			{"label": "Hire Temp Cover ($400)", "cost_type": "cash", "cost_value": 400},
			{"label": "Reassign Staff", "cost_type": "reassign", "cost_value": 0}
		]
	},
	{
		"id": "tool_failure",
		"label": "Tool Failure",
		"description": "Critical software/hardware failed. Project paused until resolved.",
		"effect_type": "pause",
		"effect_value": 0.0,
		"fix_options": [
			{"label": "Emergency IT Fix ($250)", "cost_type": "cash", "cost_value": 250},
			{"label": "Use Backup Tools (slow, free)", "cost_type": "none", "cost_value": 0}
		]
	},
	{
		"id": "budget_overrun",
		"label": "Budget Overrun",
		"description": "Unexpected costs exceeded budget. Reward reduced by $500.",
		"effect_type": "reward_cut",
		"effect_value": 500.0,
		"fix_options": [
			{"label": "Absorb Cost ($500)", "cost_type": "cash", "cost_value": 500},
			{"label": "Accept Reduced Reward", "cost_type": "none", "cost_value": 0}
		]
	},
	{
		"id": "miscommunication",
		"label": "Miscommunication",
		"description": "Team misalignment caused rework. Progress set back 20%.",
		"effect_type": "regress",
		"effect_value": -0.2,
		"fix_options": [
			{"label": "Team Workshop (10 CP)", "cost_type": "cp", "cost_value": 10}
		]
	},
	{
		"id": "stakeholder_change",
		"label": "Stakeholder Change",
		"description": "Key stakeholder changed priorities. Completion bonus halved.",
		"effect_type": "reward_cut",
		"effect_value": 0.5,
		"fix_options": [
			{"label": "PR Push (20 CP)", "cost_type": "cp", "cost_value": 20},
			{"label": "Accept Half Reward", "cost_type": "none", "cost_value": 0}
		]
	},
]

const _COMPLICATION_CHANCE: float = 0.2

# ------------------------------------------
#  STATE
# ------------------------------------------
var _available: Array       = []
var _active: Array          = []
var _completed_names: Array = []
var _next_id: int           = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ------------------------------------------
#  INIT
# ------------------------------------------
func initialize() -> void:
	_available.clear()
	_active.clear()
	_completed_names.clear()
	_next_id = 0
	_rng.randomize()
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
	var bulletin_mgr: Node = get_node_or_null("/root/CHAMPBulletinManager")
	var to_complete: Array = []
	for proj in _active:
		# Skip paused projects (complication or conflict penalty handled below)
		var comp: Dictionary = proj.get("active_complication", {})
		var comp_effect: String = comp.get("effect_type", "")
		if comp_effect == "pause":
			continue
		var base: float        = 1.0 / float(proj.get("duration_ticks", 1))
		var role_mult: float   = 1.5 if _has_role_match(proj, gm) else 1.0
		var ot_mult: float     = _get_ot_multiplier(proj, gm)
		var daily: float       = base * role_mult * ot_mult
		var fever_mult: float  = 2.0 if gm.is_fever_mode else 1.0
		# Bulletin speed multiplier
		var bulletin_mult: float = 1.0
		if bulletin_mgr != null:
			var ptype: String = proj.get("project_type", "")
			bulletin_mult = bulletin_mgr.get_project_speed_multiplier(ptype)
		# Complication slow multiplier
		var comp_mult: float = 1.0
		if comp_effect == "slow":
			comp_mult = comp.get("effect_value", 1.0)
		# Conflict penalty (set by InternalProblemManager)
		var conflict_mult: float = 0.8 if proj.get("conflict_penalty", false) else 1.0
		proj["progress"] = minf(1.0, proj.get("progress", 0.0) + daily * fever_mult * bulletin_mult * comp_mult * conflict_mult)
		# Complication: apply one-shot regress if not yet applied
		if comp_effect == "regress" and not comp.get("_applied", false):
			proj["progress"] = maxf(0.0, proj.get("progress", 0.0) + comp.get("effect_value", 0.0))
			comp["_applied"] = true
		# Try rolling a complication (once per project, only if no active complication)
		if comp.is_empty():
			_try_roll_complication(proj, gm)
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
			_completed_names.append(proj.get("name", ""))
			gm.economy.add_revenue(proj.get("reward_cash", 0), "Project: " + proj.get("name", "Project"))
			gm.add_corp_points(proj.get("reward_corp_points", 0))
			gm.company_data["reputation"] = gm.company_data.get("reputation", 0) + proj.get("reward_reputation", 0)
			var next: Dictionary = _next_from_pool()
			if not next.is_empty():
				_available.append(next)
			print("[Project] %s completed! +$%d +%d CP +%d Rep" % [
				proj.get("name", "Project"), proj.get("reward_cash", 0),
				proj.get("reward_corp_points", 0), proj.get("reward_reputation", 0)
			])
			project_completed.emit(proj)
			return

# ------------------------------------------
#  GENERATION HELPERS
# ------------------------------------------
func _generate_available(count: int) -> void:
	for _i: int in range(count):
		var proj: Dictionary = _next_from_pool()
		if proj.is_empty():
			break
		_available.append(proj)
	projects_updated.emit()

func _next_from_pool() -> Dictionary:
	var used_names: Array = _completed_names.duplicate()
	for p in _available:
		used_names.append(p.get("name", ""))
	for p in _active:
		used_names.append(p.get("name", ""))
	var candidates: Array = []
	for proj in LOCAL_PROJECTS:
		if proj.get("name", "") not in used_names:
			candidates.append(proj)
	if candidates.is_empty():
		return {}
	candidates.shuffle()
	var proj: Dictionary = candidates[0].duplicate()
	proj["id"]                    = _next_id
	proj["progress"]              = 0.0
	proj["assigned_employee_ids"] = []
	proj["is_active"]             = false
	proj["is_complete"]           = false
	proj["active_complication"]   = {}
	proj["conflict_penalty"]      = false
	_next_id += 1
	return proj

# ------------------------------------------
#  COMPLICATIONS
# ------------------------------------------
func _try_roll_complication(proj: Dictionary, gm: Node) -> void:
	if _rng.randf() > _COMPLICATION_CHANCE:
		return
	var chosen: Dictionary = _COMPLICATIONS[_rng.randi() % _COMPLICATIONS.size()].duplicate(true)
	_apply_complication(proj, chosen, gm)

func _apply_complication(proj: Dictionary, comp: Dictionary, gm: Node) -> void:
	var etype: String = comp.get("effect_type", "")
	if etype == "reward_cut":
		var cut: float = comp.get("effect_value", 0.0)
		# If effect_value is between 0 and 1, treat as multiplier; else as flat cut
		if cut <= 1.0 and cut > 0.0:
			proj["reward_cash"] = int(proj.get("reward_cash", 0) * cut)
		else:
			proj["reward_cash"] = maxi(0, proj.get("reward_cash", 0) - int(cut))
		# Reward cuts resolve immediately
		comp["_applied"] = true
	proj["active_complication"] = comp
	print("[ProjectManager] Complication triggered on %s: %s" % [proj.get("name", "Project"), comp.get("label", "")])
	complication_triggered.emit(proj, comp)
	projects_updated.emit()

func resolve_complication(project_id: int, fix_idx: int, gm: Node) -> bool:
	for proj in _active:
		if proj.get("id", -1) != project_id:
			continue
		var comp: Dictionary = proj.get("active_complication", {})
		if comp.is_empty():
			return false
		var fixes: Array = comp.get("fix_options", [])
		if fix_idx >= fixes.size():
			return false
		var fix: Dictionary = fixes[fix_idx]
		var cost_type: String = fix.get("cost_type", "none")
		var cost_val: int = int(fix.get("cost_value", 0))
		match cost_type:
			"cash":
				gm.economy.spend(cost_val, "Project Complication Fix")
			"cp":
				if gm.corp_points < cost_val:
					return false
				gm.corp_points -= cost_val
				gm.corp_points_changed.emit(gm.corp_points)
			"reassign", "none":
				pass
		proj["active_complication"] = {}
		projects_updated.emit()
		return true
	return false

# ------------------------------------------
#  PUBLIC HELPERS (used by InternalProblemManager)
# ------------------------------------------
func remove_employee_from_all_projects(emp_id: String, gm: Node) -> void:
	for proj in _active:
		var ids: Array = proj.get("assigned_employee_ids", [])
		if emp_id in ids:
			ids.erase(emp_id)
			proj["assigned_employee_ids"] = ids
	for emp in gm.employees.get_hired_employees():
		if emp.id == emp_id:
			emp.is_assigned_to_project = false
			emp.current_project_id = ""
			break
	projects_updated.emit()

func set_project_flag(project_id: int, flag: String, value: Variant) -> void:
	for proj in _active:
		if proj.get("id", -1) == project_id:
			proj[flag] = value
			return

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
