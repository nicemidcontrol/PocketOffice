extends GutTest

# PR-4: ParameterTracker — parameter stat sums, role modifiers, reward tiers.

var pt: Node = null

func before_each() -> void:
	var pt_script: GDScript = preload("res://scripts/managers/ParameterTracker.gd")
	pt = pt_script.new()
	add_child_autofree(pt)

func _make_emp(role: int, stats: Dictionary) -> Employee:
	var emp: Employee = Employee.new()
	emp.role = role
	for stat_name in stats:
		emp.set(str(stat_name), int(stats.get(stat_name, 0)))
	return emp

# ─────────────────────────────────────────
#  STAT SUMS (decoy stats must not leak in)
# ─────────────────────────────────────────
func test_planning_sums_management_and_focus() -> void:
	var pm: Employee = _make_emp(Employee.Role.MANAGEMENT,
		{"management": 100, "focus": 50, "technical": 999, "charm": 999})
	# (100 + 50) * 1.2 specialty
	assert_eq(pt.base_contribution(pm, "PLANNING"), 180)

func test_execution_sums_technical_and_precision() -> void:
	var fo: Employee = _make_emp(Employee.Role.OPERATIONS,
		{"technical": 100, "precision": 60, "management": 999, "logistics": 999})
	# (100 + 60) * 1.2 specialty
	assert_eq(pt.base_contribution(fo, "EXECUTION"), 192)

func test_logistics_sums_procurement_and_logistics() -> void:
	var so: Employee = _make_emp(Employee.Role.PROCUREMENT,
		{"procurement": 80, "logistics": 40, "charm": 999, "focus": 999})
	# (80 + 40) * 1.2 specialty
	assert_eq(pt.base_contribution(so, "LOGISTICS"), 144)

func test_community_sums_charm_and_communication() -> void:
	var emp: Employee = _make_emp(Employee.Role.FINANCE,
		{"charm": 50, "communication": 30, "technical": 999, "management": 999})
	# (50 + 30) * 1.0 — charm above threshold, no role bonus for COMMUNITY
	assert_eq(pt.base_contribution(emp, "COMMUNITY"), 80)

# ─────────────────────────────────────────
#  PLANNING HARD GATE
# ─────────────────────────────────────────
func test_planning_by_non_pm_is_ineligible_and_zero() -> void:
	var fo: Employee = _make_emp(Employee.Role.OPERATIONS,
		{"management": 500, "focus": 500})
	assert_false(pt.is_eligible_for_parameter(fo, "PLANNING"))
	assert_eq(pt.base_contribution(fo, "PLANNING"), 0)

func test_non_planning_parameters_are_open_to_all_roles() -> void:
	var sec: Employee = _make_emp(Employee.Role.SECRETARY, {})
	assert_true(pt.is_eligible_for_parameter(sec, "EXECUTION"))
	assert_true(pt.is_eligible_for_parameter(sec, "LOGISTICS"))
	assert_true(pt.is_eligible_for_parameter(sec, "COMMUNITY"))

# ─────────────────────────────────────────
#  ROLE MODIFIERS
# ─────────────────────────────────────────
func test_specialty_bonus_for_matching_role() -> void:
	var fo: Employee = _make_emp(Employee.Role.OPERATIONS,
		{"technical": 100, "precision": 100})
	assert_eq(pt.base_contribution(fo, "EXECUTION"), 240, "200 * 1.2 specialty")
	var so: Employee = _make_emp(Employee.Role.PROCUREMENT,
		{"procurement": 100, "logistics": 100})
	assert_eq(pt.base_contribution(so, "LOGISTICS"), 240, "200 * 1.2 specialty")

func test_off_role_efficiency_for_execution_and_logistics() -> void:
	var sec: Employee = _make_emp(Employee.Role.SECRETARY,
		{"technical": 100, "precision": 100})
	assert_eq(pt.base_contribution(sec, "EXECUTION"), 140, "200 * 0.7 off-role")
	var fin: Employee = _make_emp(Employee.Role.FINANCE,
		{"procurement": 100, "logistics": 100})
	assert_eq(pt.base_contribution(fin, "LOGISTICS"), 140, "200 * 0.7 off-role")

func test_community_charm_threshold_boundary() -> void:
	var charming: Employee = _make_emp(Employee.Role.OPERATIONS,
		{"charm": 40, "communication": 60})
	assert_eq(pt.base_contribution(charming, "COMMUNITY"), 100, "charm 40 = full rate")
	var shy: Employee = _make_emp(Employee.Role.OPERATIONS,
		{"charm": 39, "communication": 61})
	assert_eq(pt.base_contribution(shy, "COMMUNITY"), 70, "charm 39 = 0.7 rate")

func test_unknown_parameter_is_ineligible_and_zero() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT, {"management": 100})
	assert_false(pt.is_eligible_for_parameter(emp, "VIBES"))
	assert_eq(pt.base_contribution(emp, "VIBES"), 0)

# ─────────────────────────────────────────
#  REWARD TIERS
# ─────────────────────────────────────────
func test_tier_boundaries() -> void:
	assert_eq(pt.tier_for_total(199), 1)
	assert_eq(pt.tier_for_total(200), 2)
	assert_eq(pt.tier_for_total(499), 2)
	assert_eq(pt.tier_for_total(500), 3)
	assert_eq(pt.tier_for_total(1199), 3)
	assert_eq(pt.tier_for_total(1200), 4)
	assert_eq(pt.tier_for_total(2499), 4)
	assert_eq(pt.tier_for_total(2500), 5)

func test_regression_fresh_tier_d_team_lands_tier_1() -> void:
	# NOTES.md PR-0 finding: prototype mapped a fresh Tier D 3-person
	# team (~138 project total) to "S Tier". Tiers are integers and a
	# ~138 total must be Tier 1, never higher.
	assert_eq(pt.tier_for_total(138), 1, "fresh Tier D team total must map to Tier 1")
	assert_eq(pt.tier_for_total(0), 1)
	for sample_total: int in [138, 199, 500, 2500]:
		var tier: Variant = pt.tier_for_total(sample_total)
		assert_true(tier is int, "tiers must be integers, never letter grades")
		assert_between(int(tier), 1, 5)
