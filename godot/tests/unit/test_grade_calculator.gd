extends GutTest

var pm: Node = null

func before_each() -> void:
	pm = preload("res://ProjectManager.gd").new()

func after_each() -> void:
	if pm != null:
		pm.free()
		pm = null

# ─────────────────────────────────────────
#  _grade_from_progress
# ─────────────────────────────────────────

func test_grade_s_at_exact_threshold() -> void:
	assert_eq(pm._grade_from_progress(0.80), "S")

func test_grade_s_well_above() -> void:
	assert_eq(pm._grade_from_progress(1.0), "S")

func test_grade_a_at_exact_threshold() -> void:
	assert_eq(pm._grade_from_progress(0.60), "A")

func test_grade_a_just_below_s() -> void:
	assert_eq(pm._grade_from_progress(0.799), "A")

func test_grade_b_at_exact_threshold() -> void:
	assert_eq(pm._grade_from_progress(0.45), "B")

func test_grade_b_just_below_a() -> void:
	assert_eq(pm._grade_from_progress(0.599), "B")

func test_grade_c_at_exact_threshold() -> void:
	assert_eq(pm._grade_from_progress(0.30), "C")

func test_grade_c_just_below_b() -> void:
	assert_eq(pm._grade_from_progress(0.449), "C")

func test_grade_d_at_exact_threshold() -> void:
	assert_eq(pm._grade_from_progress(0.15), "D")

func test_grade_d_just_below_c() -> void:
	assert_eq(pm._grade_from_progress(0.299), "D")

func test_grade_f_just_below_d() -> void:
	assert_eq(pm._grade_from_progress(0.149), "F")

func test_grade_f_at_zero() -> void:
	assert_eq(pm._grade_from_progress(0.0), "F")

func test_grade_f_at_negative() -> void:
	assert_eq(pm._grade_from_progress(-0.5), "F")

# ─────────────────────────────────────────
#  _employee_contribution
# ─────────────────────────────────────────

func test_contribution_all_zero() -> void:
	assert_eq(pm._employee_contribution(0.0, 0.0, 0.0), 0.0)

func test_contribution_primary_only_max() -> void:
	assert_almost_eq(pm._employee_contribution(1000.0, 0.0, 0.0), 0.60, 0.0001)

func test_contribution_secondary_only_max() -> void:
	assert_almost_eq(pm._employee_contribution(0.0, 1000.0, 0.0), 0.30, 0.0001)

func test_contribution_combo_only() -> void:
	assert_almost_eq(pm._employee_contribution(0.0, 0.0, 0.15), 0.15, 0.0001)

func test_contribution_all_max() -> void:
	assert_almost_eq(pm._employee_contribution(1000.0, 1000.0, 0.25), 1.15, 0.0001)

func test_contribution_realistic_mid() -> void:
	assert_almost_eq(pm._employee_contribution(500.0, 400.0, 0.0), 0.42, 0.0001)
