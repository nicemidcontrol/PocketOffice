extends GutTest

# PR-7: StaminaWidget + EmployeePickerCard components.

const WIDGET_SCENE: PackedScene = preload("res://scenes/ui/StaminaWidget.tscn")
const CARD_SCENE: PackedScene = preload("res://scenes/ui/EmployeePickerCard.tscn")

func _make_emp(role: int, stats: Dictionary, sp: int = 5) -> Employee:
	var emp: Employee = Employee.new()
	emp.id = "emp_test_1"
	emp.first_name = "Test"
	emp.last_name = "Subject"
	emp.role = role
	emp.tier = "D"
	emp.sp_current = sp
	emp.sp_max = 5
	for stat_name in stats:
		emp.set(str(stat_name), int(stats.get(stat_name, 0)))
	return emp

func _spawn_card(emp: Employee, parameter: String) -> Panel:
	var card: Panel = CARD_SCENE.instantiate()
	add_child_autofree(card)
	card.setup(emp, parameter)
	return card

func _left_click() -> InputEventMouseButton:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	return ev

func _filled_pip_count(widget: HBoxContainer) -> int:
	var filled: int = 0
	for child in widget.get_children():
		var pip: ColorRect = child
		if pip.color == widget.PIP_FILLED or pip.color == widget.PIP_WARNING:
			filled += 1
	return filled

# ─────────────────────────────────────────
#  STAMINA WIDGET
# ─────────────────────────────────────────
func test_widget_full_sp_shows_five_filled_pips() -> void:
	var widget: HBoxContainer = WIDGET_SCENE.instantiate()
	add_child_autofree(widget)
	widget.set_sp(5, 5)
	assert_eq(widget.get_child_count(), 5, "five pips at 5/5")
	assert_eq(_filled_pip_count(widget), 5, "all five filled")

func test_widget_partial_sp_shows_two_filled_three_empty() -> void:
	var widget: HBoxContainer = WIDGET_SCENE.instantiate()
	add_child_autofree(widget)
	widget.set_sp(2, 5)
	assert_eq(widget.get_child_count(), 5)
	assert_eq(_filled_pip_count(widget), 2, "two filled")
	var empty_count: int = 0
	for child in widget.get_children():
		var pip: ColorRect = child
		if pip.color == widget.PIP_EMPTY:
			empty_count += 1
	assert_eq(empty_count, 3, "three empty")

func test_widget_expands_beyond_five_pips() -> void:
	var widget: HBoxContainer = WIDGET_SCENE.instantiate()
	add_child_autofree(widget)
	widget.set_sp(6, 8)
	assert_eq(widget.get_child_count(), 8, "maximum > 5 shows maximum pips")
	assert_eq(_filled_pip_count(widget), 6)

func test_widget_warning_tints_filled_pips_red() -> void:
	var widget: HBoxContainer = WIDGET_SCENE.instantiate()
	add_child_autofree(widget)
	widget.set_sp(2, 5)
	widget.set_warning(true)
	var first_pip: ColorRect = widget.get_child(0)
	assert_eq(first_pip.color, widget.PIP_WARNING, "filled pip is red in warning mode")

# ─────────────────────────────────────────
#  CARD: SELECTION + SP GATE
# ─────────────────────────────────────────
func test_card_with_full_sp_is_selectable_and_signals_id() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT, {"management": 30, "focus": 25}, 5)
	var card: Panel = _spawn_card(emp, "PLANNING")
	assert_true(card.is_sp_eligible())
	assert_eq(card.modulate.a, 1.0, "eligible card at full opacity")
	watch_signals(card)
	card._on_gui_input(_left_click())
	assert_signal_emitted_with_parameters(card, "card_selected", ["emp_test_1"])

func test_card_with_low_sp_is_not_selectable() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT, {"management": 30, "focus": 25}, 2)
	var card: Panel = _spawn_card(emp, "PLANNING")
	assert_false(card.is_sp_eligible())
	assert_almost_eq(card.modulate.a, 0.4, 0.001, "ineligible card at 40% opacity")
	assert_false(card._needs_sp_label.visible, "SP hint hidden before tap")
	watch_signals(card)
	card._on_gui_input(_left_click())
	assert_signal_emit_count(card, "card_selected", 0, "no signal when SP-ineligible")
	assert_true(card._needs_sp_label.visible, "tap shows the Needs 3 SP hint")

# ─────────────────────────────────────────
#  CARD: TWO-STAT DISPLAY RULE
# ─────────────────────────────────────────
func test_planning_card_shows_management_and_focus_only() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT,
		{"management": 30, "focus": 25, "technical": 999, "charm": 999}, 5)
	var card: Panel = _spawn_card(emp, "PLANNING")
	assert_eq(card._stat1_name.text, "Management")
	assert_eq(card._stat2_name.text, "Focus")
	assert_eq(card._stat1_value.text, "30/200")
	assert_eq(card._stat2_value.text, "25/200")
	assert_string_contains(card._expected_label.text, "PLANNING")
	assert_string_contains(card._expected_label.text, "~55",
		"expected contribution is the raw management+focus sum")
	assert_false(card.is_mismatched(), "PM on PLANNING is not mismatched")
	assert_false(card._mismatch_label.visible)

func test_execution_card_for_pm_is_mismatched() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT,
		{"technical": 40, "precision": 20, "management": 999}, 5)
	var card: Panel = _spawn_card(emp, "EXECUTION")
	assert_true(card.is_mismatched(), "PM on EXECUTION is off-role")
	assert_true(card._mismatch_label.visible)
	assert_string_contains(card._mismatch_label.text, "70% efficiency")
	assert_eq(card._stat1_name.text, "Technical")
	assert_eq(card._stat2_name.text, "Precision")
	assert_string_contains(card._expected_label.text, "~60",
		"expected contribution stays the raw sum - no multiplier shown")

func test_field_officer_on_execution_is_not_mismatched() -> void:
	var emp: Employee = _make_emp(Employee.Role.OPERATIONS, {"technical": 50, "precision": 30}, 5)
	var card: Panel = _spawn_card(emp, "EXECUTION")
	assert_false(card.is_mismatched())
	assert_false(card._mismatch_label.visible)

# ─────────────────────────────────────────
#  CARD: SELECTED STATE
# ─────────────────────────────────────────
func test_set_selected_toggles_state() -> void:
	var emp: Employee = _make_emp(Employee.Role.MANAGEMENT, {"management": 30, "focus": 25}, 5)
	var card: Panel = _spawn_card(emp, "PLANNING")
	assert_false(card.is_selected())
	assert_eq(card.scale, Vector2(1.0, 1.0))

	card.set_selected(true)
	assert_true(card.is_selected())
	assert_eq(card.scale, Vector2(1.05, 1.05), "selected card scales to 1.05")
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	assert_eq(style.border_color, card.BORDER_GOLD, "selected border is gold")
	assert_eq(style.border_width_left, 3, "selected border is 3px")

	card.set_selected(false)
	assert_false(card.is_selected())
	assert_eq(card.scale, Vector2(1.0, 1.0))
	var style2: StyleBoxFlat = card.get_theme_stylebox("panel")
	assert_eq(style2.border_color, card.BORDER_BLUE, "deselected border returns to blue")
