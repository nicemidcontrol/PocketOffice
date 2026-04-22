extends GutTest

var tm: Node = null

func before_each() -> void:
	tm = preload("res://scripts/TrainingManager.gd").new()

func after_each() -> void:
	if tm != null:
		tm.free()
		tm = null

# ─────────────────────────────────────────
#  Basic cost calculation
# ─────────────────────────────────────────

func test_cost_single_employee_default() -> void:
	# cp_cost not in dict -> fallback 7 * 1 = 7
	var training: Dictionary = {}
	assert_eq(tm.get_total_cp_cost(training, 1, [], []), 7)

func test_cost_single_employee_custom() -> void:
	var training: Dictionary = {"cp_cost": 10}
	assert_eq(tm.get_total_cp_cost(training, 1, [], []), 10)

func test_cost_three_employees_custom() -> void:
	var training: Dictionary = {"cp_cost": 10}
	assert_eq(tm.get_total_cp_cost(training, 3, [], []), 30)

func test_cost_zero_employees() -> void:
	var training: Dictionary = {"cp_cost": 10}
	assert_eq(tm.get_total_cp_cost(training, 0, [], []), 0)

func test_cost_missing_key_uses_default() -> void:
	# No "cp_cost" key -> fallback 7 * 3 = 21
	var training: Dictionary = {"name": "Some Training"}
	assert_eq(tm.get_total_cp_cost(training, 3, [], []), 21)

func test_cost_zero_cp_cost() -> void:
	# Explicit 0 should be respected (not fall back to 7)
	var training: Dictionary = {"cp_cost": 0}
	assert_eq(tm.get_total_cp_cost(training, 5, [], []), 0)

# ─────────────────────────────────────────
#  Unused params must not affect output
# ─────────────────────────────────────────

func test_employees_array_does_not_affect_cost() -> void:
	var training: Dictionary = {"cp_cost": 10}
	var cost_empty: int = tm.get_total_cp_cost(training, 2, [], [])
	var cost_with_fake: int = tm.get_total_cp_cost(training, 2, [null, null, null], [])
	assert_eq(cost_empty, cost_with_fake, "employees array must not affect cost after cleanup")

func test_discovered_combos_does_not_affect_cost() -> void:
	var training: Dictionary = {"cp_cost": 10}
	var cost_empty: int = tm.get_total_cp_cost(training, 2, [], [])
	var cost_with_combos: int = tm.get_total_cp_cost(training, 2, [], ["anything", "everything"])
	assert_eq(cost_empty, cost_with_combos, "discovered_combos must not affect cost after cleanup")
