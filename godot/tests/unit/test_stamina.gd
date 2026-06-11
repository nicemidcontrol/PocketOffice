extends GutTest

var sm: Node = null

func before_each() -> void:
	var sm_script: GDScript = preload("res://scripts/managers/StaminaManager.gd")
	sm = sm_script.new()
	add_child_autofree(sm)

func _make_emp(sp: int, sp_cap: int = 5) -> Employee:
	var emp: Employee = Employee.new()
	emp.id = "test_emp"
	emp.first_name = "Test"
	emp.last_name = "Subject"
	emp.sp_max = sp_cap
	emp.sp_current = sp
	return emp

# ─────────────────────────────────────────
#  ELIGIBILITY
# ─────────────────────────────────────────
func test_eligible_at_three_sp() -> void:
	assert_true(sm.is_eligible(_make_emp(3)))

func test_not_eligible_below_three_sp() -> void:
	assert_false(sm.is_eligible(_make_emp(2)))

# ─────────────────────────────────────────
#  SPENDING
# ─────────────────────────────────────────
func test_spend_reduces_five_to_two() -> void:
	var emp: Employee = _make_emp(5)
	var spent: bool = sm.spend_phase(emp)
	assert_true(spent, "spend at 5 SP should succeed")
	assert_eq(emp.sp_current, 2)

func test_second_spend_rejected_at_two_sp() -> void:
	var emp: Employee = _make_emp(5)
	sm.spend_phase(emp)
	var spent_again: bool = sm.spend_phase(emp)
	assert_false(spent_again, "spend at 2 SP should be rejected")
	assert_eq(emp.sp_current, 2, "rejected spend must not change SP")

# ─────────────────────────────────────────
#  RECOVERY
# ─────────────────────────────────────────
func test_weekly_recovery_raises_two_to_three() -> void:
	var emp: Employee = _make_emp(2)
	sm.weekly_recovery([emp])
	assert_eq(emp.sp_current, 3)

func test_recovery_caps_at_sp_max() -> void:
	var emp: Employee = _make_emp(5, 5)
	sm.weekly_recovery([emp])
	assert_eq(emp.sp_current, 5, "recovery must not exceed sp_max")

# ─────────────────────────────────────────
#  SERIALISATION
# ─────────────────────────────────────────
func test_dict_round_trip_preserves_sp() -> void:
	var emp: Employee = _make_emp(2, 7)
	var d: Dictionary = emp.to_dict()
	var loaded: Employee = Employee.from_dict(d)
	assert_eq(loaded.sp_current, 2)
	assert_eq(loaded.sp_max, 7)

func test_from_dict_legacy_defaults_to_full_sp() -> void:
	var legacy: Dictionary = {"id": "legacy", "first_name": "Old", "last_name": "Save"}
	var emp: Employee = Employee.from_dict(legacy)
	assert_eq(emp.sp_current, 5)
	assert_eq(emp.sp_max, 5)
