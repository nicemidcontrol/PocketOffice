class_name ProjectManager
extends Node

# ─────────────────────────────────────────
#  ENUMS
# ─────────────────────────────────────────
enum ProjectStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED }

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal project_completed(project: Dictionary)
signal project_failed(project: Dictionary)
signal new_project_available(project: Dictionary)

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _projects: Array[Dictionary] = []

# Template pools
const CLIENT_NAMES  := ["Acme Corp","TechNova","MegaDeal Ltd","PixelBrand","CloudFirst Inc"]
const PROJECT_TITLES := ["Website Revamp","App Development","Brand Campaign","Data Migration","Office System"]

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func initialize() -> void:
	_projects.clear()

# ─────────────────────────────────────────
#  GENERATION
# ─────────────────────────────────────────
func generate_new_projects(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in range(count):
		var proj := {
			"id":                  str(Time.get_ticks_msec()) + str(rng.randi()),
			"client_name":         CLIENT_NAMES[rng.randi_range(0, CLIENT_NAMES.size() - 1)],
			"project_title":       PROJECT_TITLES[rng.randi_range(0, PROJECT_TITLES.size() - 1)],
			"required_skill_pts":  rng.randi_range(100, 500),
			"deadline_days":       rng.randi_range(10, 30),
			"days_elapsed":        0,
			"reward_money":        rng.randi_range(2000, 20000),
			"reward_reputation":   rng.randi_range(5, 25),
			"penalty_reputation":  rng.randi_range(5, 15),
			"status":              ProjectStatus.AVAILABLE,
			"assigned_employee_ids": [],
			"daily_output":        0.0,
		}
		_projects.append(proj)
		new_project_available.emit(proj)
		print("[ProjectManager] New project: %s from %s" % [proj["project_title"], proj["client_name"]])

# ─────────────────────────────────────────
#  ASSIGNMENT
# ─────────────────────────────────────────
func assign_employees(project_id: String, employees: Array[Employee]) -> bool:
	var proj := _find_project(project_id)
	if proj.is_empty() or proj["status"] != ProjectStatus.AVAILABLE:
		return false

	proj["status"] = ProjectStatus.ACTIVE
	proj["assigned_employee_ids"] = employees.map(func(e): return e.id)
	proj["daily_output"] = employees.reduce(
		func(acc, e): return acc + e.effective_productivity(), 0.0
	)

	for emp in employees:
		emp.is_assigned_to_project = true
		emp.current_project_id = project_id

	print("[ProjectManager] Project '%s' started with %d employees." % [
		proj["project_title"], employees.size()
	])
	return true

# ─────────────────────────────────────────
#  DAILY TICK
# ─────────────────────────────────────────
func tick_projects(gm: GameManager) -> void:
	for proj in _projects:
		if proj["status"] != ProjectStatus.ACTIVE:
			continue

		proj["days_elapsed"] += 1
		var progress := _get_progress(proj)

		if progress >= 1.0:
			_complete_project(proj, gm)
		elif proj["days_elapsed"] >= proj["deadline_days"]:
			_fail_project(proj, gm)

func _get_progress(proj: Dictionary) -> float:
	var required: int = proj["required_skill_pts"]
	if required <= 0:
		return 1.0
	return clampf(float(proj["days_elapsed"]) * float(proj["daily_output"]) / required, 0.0, 1.0)

# ─────────────────────────────────────────
#  COMPLETE / FAIL
# ─────────────────────────────────────────
func _complete_project(proj: Dictionary, gm: GameManager) -> void:
	proj["status"] = ProjectStatus.COMPLETED
	gm.economy.add_revenue(proj["reward_money"], "Project: " + proj["project_title"])
	gm.company_data.reputation = mini(1000, gm.company_data.reputation + proj["reward_reputation"])
	_free_employees(proj, gm, true)
	project_completed.emit(proj)
	gm.broadcast("✅ Project '%s' completed! +$%d" % [proj["project_title"], proj["reward_money"]])

func _fail_project(proj: Dictionary, gm: GameManager) -> void:
	proj["status"] = ProjectStatus.FAILED
	gm.company_data.reputation = maxi(0, gm.company_data.reputation - proj["penalty_reputation"])
	_free_employees(proj, gm, false)
	project_failed.emit(proj)
	gm.broadcast("❌ Project '%s' failed. -%d reputation" % [
		proj["project_title"], proj["penalty_reputation"]
	])

func _free_employees(proj: Dictionary, gm: GameManager, success: bool) -> void:
	var ids: Array = proj["assigned_employee_ids"]
	for emp in gm.employees.get_all_employees():
		if emp.id in ids:
			emp.is_assigned_to_project = false
			emp.current_project_id = ""
			emp.gain_experience(50)
			emp.adjust_motivation(10 if success else -15)

# ─────────────────────────────────────────
#  QUERIES
# ─────────────────────────────────────────
func get_available_projects() -> Array[Dictionary]:
	return _projects.filter(func(p): return p["status"] == ProjectStatus.AVAILABLE)

func get_active_projects() -> Array[Dictionary]:
	return _projects.filter(func(p): return p["status"] == ProjectStatus.ACTIVE)

func _find_project(project_id: String) -> Dictionary:
	for p in _projects:
		if p["id"] == project_id:
			return p
	return {}

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func to_save_array() -> Array:
	return _projects.duplicate(true)

func load_projects(data: Array) -> void:
	_projects.clear()
	for d in data:
		_projects.append(d)
