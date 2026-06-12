extends Panel

# EmployeePickerCard (PR-7) — per UI_SYSTEMS_BIBLE Employee Picker Card.
# Component only: the picker modal (PR-8) owns list, sorting, filtering,
# and the "hidden" state. Interim BaseModal palette; art re-skin later.

signal card_selected(employee_id: String)

const TRACKER_SCRIPT: GDScript = preload("res://scripts/managers/ParameterTracker.gd")
const STAMINA_SCRIPT: GDScript = preload("res://scripts/managers/StaminaManager.gd")

# Mirrors CharacterCustomization.PORTRAIT_COLORS (PR-5) — placeholder
# swatches until portrait art exists.
const PORTRAIT_COLORS: Array[Color] = [
	Color(0.75, 0.35, 0.30, 1.0),
	Color(0.85, 0.65, 0.25, 1.0),
	Color(0.30, 0.65, 0.40, 1.0),
	Color(0.25, 0.55, 0.80, 1.0),
	Color(0.55, 0.40, 0.75, 1.0),
	Color(0.80, 0.45, 0.65, 1.0),
]

const BORDER_BLUE: Color = Color(0.18, 0.42, 0.78, 1.0)
const BORDER_GOLD: Color = Color(1.0, 0.82, 0.1, 1.0)
const BORDER_YELLOW: Color = Color(0.95, 0.8, 0.2, 1.0)
const CARD_BG: Color = Color(0.047, 0.047, 0.11, 0.97)

@onready var _portrait: ColorRect = $Margin/HBox/Portrait
@onready var _name_label: Label = $Margin/HBox/InfoVBox/NameLabel
@onready var _role_tier_label: Label = $Margin/HBox/InfoVBox/RoleTierLabel
@onready var _stamina_widget: HBoxContainer = $Margin/HBox/InfoVBox/SpRow/StaminaWidget
@onready var _needs_sp_label: Label = $Margin/HBox/InfoVBox/SpRow/NeedsSpLabel
@onready var _stat1_name: Label = $Margin/HBox/InfoVBox/Stat1Row/Stat1Name
@onready var _stat1_bar: ProgressBar = $Margin/HBox/InfoVBox/Stat1Row/Stat1Bar
@onready var _stat1_value: Label = $Margin/HBox/InfoVBox/Stat1Row/Stat1Value
@onready var _stat2_name: Label = $Margin/HBox/InfoVBox/Stat2Row/Stat2Name
@onready var _stat2_bar: ProgressBar = $Margin/HBox/InfoVBox/Stat2Row/Stat2Bar
@onready var _stat2_value: Label = $Margin/HBox/InfoVBox/Stat2Row/Stat2Value
@onready var _mismatch_label: Label = $Margin/HBox/InfoVBox/MismatchLabel
@onready var _expected_label: Label = $Margin/HBox/InfoVBox/ExpectedLabel

var _emp: Employee = null
var _parameter: String = ""
var _selected: bool = false
var _sp_eligible: bool = true
var _mismatched: bool = false
var _stamina: Node = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)

# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────
func setup(emp: Employee, parameter: String) -> void:
	_emp = emp
	_parameter = parameter

	_name_label.text = emp.full_name()
	_role_tier_label.text = "%s - TIER %s" % [_role_title(int(emp.role)), emp.tier]
	_portrait.color = _portrait_color(emp)

	_stamina_widget.set_sp(emp.sp_current, emp.sp_max)
	_sp_eligible = _get_stamina().is_eligible(emp)

	var primary_role: int = int(TRACKER_SCRIPT.PARAMETER_PRIMARY_ROLE.get(parameter, -1))
	_mismatched = primary_role != -1 and int(emp.role) != primary_role

	# Two-stat display rule: only the parameter's stat pair, never the
	# other six.
	var stat_keys: Array = TRACKER_SCRIPT.PARAMETER_STATS.get(parameter, [])
	var stat1_key: String = str(stat_keys[0]) if stat_keys.size() > 0 else ""
	var stat2_key: String = str(stat_keys[1]) if stat_keys.size() > 1 else ""
	_fill_stat_row(_stat1_name, _stat1_bar, _stat1_value, stat1_key)
	_fill_stat_row(_stat2_name, _stat2_bar, _stat2_value, stat2_key)

	# Expected contribution shows the RAW stat sum — no multiplier.
	var stat_sum: int = _stat_value(stat1_key) + _stat_value(stat2_key)
	_expected_label.text = "Expected %s contribution: ~%d" % [parameter, stat_sum]

	_needs_sp_label.visible = false
	_apply_state()

func set_selected(on: bool) -> void:
	_selected = on
	_apply_state()

func is_selected() -> bool:
	return _selected

func is_sp_eligible() -> bool:
	return _sp_eligible

func is_mismatched() -> bool:
	return _mismatched

# ─────────────────────────────────────────
#  STATE / VISUALS
# ─────────────────────────────────────────
func _apply_state() -> void:
	modulate.a = 1.0 if _sp_eligible else 0.4
	_stamina_widget.set_warning(not _sp_eligible)
	_mismatch_label.visible = _mismatched

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	var border_width: int = 2
	var border_color: Color = BORDER_BLUE
	if _selected:
		border_width = 3
		border_color = BORDER_GOLD
	elif _mismatched:
		border_color = BORDER_YELLOW
	style.border_width_left   = border_width
	style.border_width_top    = border_width
	style.border_width_right  = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left  = 8
	add_theme_stylebox_override("panel", style)

	pivot_offset = size / 2.0
	scale = Vector2(1.05, 1.05) if _selected else Vector2(1.0, 1.0)

func _fill_stat_row(name_label: Label, bar: ProgressBar, value_label: Label, stat_key: String) -> void:
	var row_visible: bool = stat_key != ""
	name_label.get_parent().visible = row_visible
	if not row_visible:
		return
	var value: int = _stat_value(stat_key)
	var ceiling: int = _stat_ceiling(_emp, stat_key)
	name_label.text = stat_key.capitalize()
	bar.max_value = float(ceiling)
	bar.value = float(value)
	value_label.text = "%d/%d" % [value, ceiling]

func _stat_value(stat_key: String) -> int:
	if _emp == null or stat_key == "":
		return 0
	return int(_emp.get(stat_key))

func _stat_ceiling(_emp_arg: Employee, _stat_key: String) -> int:
	# TODO(PR-16 Tier Promotion): replace with role-profile ceilings.
	return 200

func _portrait_color(emp: Employee) -> Color:
	if str(emp.id) == "protagonist":
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			var protagonist: Dictionary = gm.company_data.get("protagonist", {})
			var portrait_id: int = int(protagonist.get("portrait_id", -1))
			if portrait_id >= 0 and portrait_id < PORTRAIT_COLORS.size():
				return PORTRAIT_COLORS[portrait_id]
	return _role_color(int(emp.role))

func _role_title(role: int) -> String:
	match role:
		Employee.Role.MANAGEMENT:  return "PROJECT MANAGER"
		Employee.Role.OPERATIONS:  return "FIELD OFFICER"
		Employee.Role.PROCUREMENT: return "SUPPLY OFFICER"
		Employee.Role.SECRETARY:   return "ADMIN OFFICER"
		Employee.Role.FINANCE:     return "BUDGET OFFICER"
	return "UNKNOWN"

func _role_color(role: int) -> Color:
	match role:
		Employee.Role.OPERATIONS:  return Color(0.22, 0.9, 0.42, 1.0)
		Employee.Role.PROCUREMENT: return Color(0.94, 0.47, 0.20, 1.0)
		Employee.Role.SECRETARY:   return Color(0.20, 0.85, 0.94, 1.0)
		Employee.Role.MANAGEMENT:  return Color(0.78, 0.22, 0.90, 1.0)
		Employee.Role.FINANCE:     return Color(1.00, 0.82, 0.10, 1.0)
	return Color(0.5, 0.51, 0.62, 1.0)

# ─────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_tapped()

func _on_tapped() -> void:
	if _emp == null:
		return
	if _sp_eligible:
		card_selected.emit(str(_emp.id))
	else:
		# Ineligible: never selects, never signals — show the SP hint.
		_needs_sp_label.visible = true

# ─────────────────────────────────────────
#  MANAGER RESOLUTION
# ─────────────────────────────────────────
func _get_stamina() -> Node:
	if _stamina == null:
		_stamina = get_node_or_null("/root/StaminaManager")
	if _stamina == null:
		# Local fallback keeps the component functional outside the
		# autoload environment (e.g. isolated unit tests).
		_stamina = STAMINA_SCRIPT.new()
		add_child(_stamina)
	return _stamina
