extends GutTest

# PR-3: v1.5.2 phase schema — data structure, save format, totals math.

const VALID_PARAMETERS: Array = ["PLANNING", "EXECUTION", "LOGISTICS", "COMMUNITY"]

var pm: Node = null

func before_each() -> void:
	var pm_script: GDScript = preload("res://ProjectManager.gd")
	pm = pm_script.new()
	add_child_autofree(pm)
	pm.initialize()

func _find_task(tid: String) -> Dictionary:
	return _find_task_in(pm, tid)

func _find_task_in(manager: Node, tid: String) -> Dictionary:
	for proj in manager.get_projects():
		for task in proj.get("tasks", []):
			if task.get("id", "") == tid:
				return task
	return {}

# ─────────────────────────────────────────
#  STATIC PHASE DECLARATIONS
# ─────────────────────────────────────────
func test_every_task_has_2_to_4_phases_and_starts_with_planning() -> void:
	var task_count: int = 0
	for proj in pm.get_projects():
		for task in proj.get("tasks", []):
			task_count += 1
			var phases: Array = task.get("phases", [])
			var tid: String = task.get("id", "")
			assert_between(phases.size(), 2, 4, "%s phase count" % tid)
			assert_eq(str(phases[0].get("parameter", "")), "PLANNING", "%s phase 1 must be PLANNING" % tid)
			for phase in phases:
				assert_has(VALID_PARAMETERS, str(phase.get("parameter", "")), "%s has invalid parameter" % tid)
	assert_eq(task_count, 16, "Local Area must declare 16 tasks")

func test_soil_sample_collection_phase_mapping() -> void:
	var task: Dictionary = _find_task("local_p2_t1")
	assert_eq(task.get("subtitle", ""), "Soil Sample Collection")
	var params: Array = []
	for phase in task.get("phases", []):
		params.append(str(phase.get("parameter", "")))
	assert_eq(params, ["PLANNING", "EXECUTION", "LOGISTICS"])

func test_tasks_carry_no_v14_fields() -> void:
	for proj in pm.get_projects():
		for task in proj.get("tasks", []):
			var tid: String = task.get("id", "")
			assert_false(task.has("primary_stat"), "%s still has primary_stat" % tid)
			assert_false(task.has("secondary_stat"), "%s still has secondary_stat" % tid)
			assert_false(task.has("progress"), "%s still has progress" % tid)
			assert_false(task.has("assigned_employee_ids"), "%s still has assigned_employee_ids" % tid)

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func test_save_load_round_trip_preserves_phase_state() -> void:
	var task: Dictionary = _find_task("local_p2_t1")
	task["status"] = "completed"
	task["phase_results"] = [
		{"parameter": "PLANNING", "employee_id": 1, "total": 120},
		{"parameter": "EXECUTION", "employee_id": 2, "total": 90},
	]
	task["used_employee_ids_this_task"] = [1, 2]
	var saved: Array = pm.to_save_array()
	assert_eq(int(saved[0].get("_v", 0)), 3, "save must be stamped _v 3")

	var pm2_script: GDScript = preload("res://ProjectManager.gd")
	var pm2: Node = pm2_script.new()
	add_child_autofree(pm2)
	pm2.load_projects(saved)

	var loaded: Dictionary = _find_task_in(pm2, "local_p2_t1")
	assert_eq(loaded.get("status", ""), "completed")
	var results: Array = loaded.get("phase_results", [])
	assert_eq(results.size(), 2)
	assert_eq(str(results[0].get("parameter", "")), "PLANNING")
	assert_eq(int(results[0].get("employee_id", 0)), 1)
	assert_eq(int(results[0].get("total", 0)), 120)
	assert_eq(int(results[1].get("total", 0)), 90)
	assert_eq(loaded.get("used_employee_ids_this_task", []), [1, 2])
	assert_eq(loaded.get("phases", []).size(), 3, "static phases must survive load")

func test_v2_save_triggers_clean_wipe() -> void:
	var legacy: Array = [{
		"_v": 2,
		"unlocked_donors": ["local_ngo"],
		"projects": [{
			"id": "local_p1", "status": "completed",
			"idle_months": 2, "completion_percent": 1.0,
			"tasks": [{
				"id": "local_p1_t1", "status": "completed",
				"progress": 1.0, "assigned_employee_ids": ["someone"],
			}],
		}],
	}]
	pm.load_projects(legacy)
	var task: Dictionary = _find_task("local_p1_t1")
	assert_eq(task.get("status", ""), "available", "v2 task state must not be applied")
	assert_eq(task.get("phase_results", []).size(), 0)
	assert_false(task.has("progress"), "wiped task must use phase schema")
	for proj in pm.get_projects():
		if proj.get("id", "") == "local_p1":
			assert_eq(proj.get("status", ""), "available", "v2 project state must not be applied")

func test_game_manager_detects_project_save_version() -> void:
	var gm_script: GDScript = preload("res://GameManager.gd")
	var gm: Node = autofree(gm_script.new())
	assert_eq(gm._project_save_version({"active_projects": [{"_v": 2}]}), 2)
	assert_eq(gm._project_save_version({"active_projects": [{"_v": 3}]}), 3)
	assert_eq(gm._project_save_version({"active_projects": [{}]}), 1, "missing _v counts as v1")
	assert_eq(gm._project_save_version({}), 3, "no project data needs no migration")

# ─────────────────────────────────────────
#  TOTALS MATH
# ─────────────────────────────────────────
func test_task_total_and_project_total() -> void:
	var fixture: Dictionary = {
		"tasks": [
			{"phase_results": [
				{"parameter": "PLANNING", "employee_id": 1, "total": 100},
				{"parameter": "COMMUNITY", "employee_id": 2, "total": 50},
			]},
			{"phase_results": [
				{"parameter": "EXECUTION", "employee_id": 3, "total": 25},
			]},
			{"phase_results": []},
		],
	}
	assert_eq(pm.task_total(fixture.get("tasks", [])[0]), 150)
	assert_eq(pm.task_total(fixture.get("tasks", [])[1]), 25)
	assert_eq(pm.task_total(fixture.get("tasks", [])[2]), 0)
	assert_eq(pm.project_total(fixture), 175)
