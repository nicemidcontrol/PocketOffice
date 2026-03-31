extends "res://scripts/ui/BaseModal.gd"

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _emp_count:    Label = $Dimmer/Card/VBox/EmpCountLabel
@onready var _role_label:   Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RoleLabel
@onready var _pers_label:   Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/PersLabel
@onready var _stats_label:  Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/StatsLabel
@onready var _stress_label: Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/StressLabel
@onready var _salary_label: Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/SalaryLabel

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:        Node  = null
var _employees: Array = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	super._ready()
	set_title("EMPLOYEES")
	_gm = get_node_or_null("/root/GameManager")
	if _gm != null:
		_gm.employees.employee_burnout.connect(_on_employee_burnout)
	_reload_employees()

# ─────────────────────────────────────────
#  DATA RELOAD
# ─────────────────────────────────────────
func _reload_employees() -> void:
	if _gm == null:
		_employees = []
	else:
		_employees = _gm.employees.get_hired_employees()
	_emp_count.text = "%d / 20" % _employees.size()
	if not _employees.is_empty() and _current_index >= _employees.size():
		_current_index = _employees.size() - 1
	set_items_count(_employees.size())

# ─────────────────────────────────────────
#  DISPLAY (BaseModal override)
# ─────────────────────────────────────────
func _refresh_display() -> void:
	if _employees.is_empty():
		_item_name_label.text = "No employees"
		_page_label.text      = "0 / 0"
		_role_label.text      = ""
		_pers_label.text      = "Recruit from HR > Recruit."
		_stats_label.text     = ""
		_stress_label.text    = ""
		_salary_label.text    = ""
		return
	super._refresh_display()
	var emp: Object = _employees[_current_index]
	_item_name_label.text = emp.full_name()

	# Role + status badges
	var badges: Array[String] = [_role_str(int(emp.role))]
	if _gm != null and _gm.employees.is_hero_employee(emp.id):
		badges.append("HERO")
	if bool(emp.is_burned_out):
		badges.append("BURNOUT")
	elif int(emp.ot_level) > 0:
		badges.append(_ot_str(int(emp.ot_level)))
	_role_label.text = "  ".join(badges)

	_pers_label.text  = _pers_str(int(emp.personality))
	_stats_label.text = "TEC %d   FOC %d   MGT %d" % [int(emp.technical), int(emp.focus), int(emp.management)]

	var stress_val: int = int(emp.stress)
	_stress_label.text = "Stress: %d / 100" % stress_val
	if stress_val >= 70:
		_stress_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	elif stress_val >= 40:
		_stress_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1, 1.0))
	else:
		_stress_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

	_salary_label.text = "$%d / mo" % int(emp.monthly_salary)

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_employee_burnout(_emp_name: String) -> void:
	_reload_employees()

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _role_str(role: int) -> String:
	match role:
		0: return "OPS"
		1: return "PRO"
		2: return "SEC"
		3: return "MGT"
		4: return "FIN"
	return "???"

func _ot_str(level: int) -> String:
	match level:
		1: return "OT"
		2: return "HEAVY OT"
		3: return "CRUNCH"
	return ""

func _pers_str(p: int) -> String:
	match p:
		0: return "Normal"
		1: return "Workaholic"
		2: return "Lazy"
		3: return "Gossip"
		4: return "Perfectionist"
		5: return "Team Player"
		6: return "Lone Star"
	return "Unknown"
