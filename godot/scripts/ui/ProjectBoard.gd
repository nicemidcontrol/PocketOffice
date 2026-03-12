extends CanvasLayer

signal screen_closed

# ─────────────────────────────────────────
#  TABS
# ─────────────────────────────────────────
const TAB_ACTIVE: int = 0
const TAB_AVAIL:  int = 1

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _cash_label:   Label         = $Card/VBox/CashLabel
@onready var _item_name:    Label         = $Card/VBox/ArrowRow/ItemNameLabel
@onready var _page_label:   Label         = $Card/VBox/PageLabel
@onready var _active_tab:   Button        = $Card/VBox/TabRow/ActiveTab
@onready var _avail_tab:    Button        = $Card/VBox/TabRow/AvailTab
@onready var _role_label:   Label         = $Card/VBox/DetailCard/Margin/DetailVBox/RoleLabel
@onready var _info_label:   Label         = $Card/VBox/DetailCard/Margin/DetailVBox/InfoLabel
@onready var _reward_label: Label         = $Card/VBox/DetailCard/Margin/DetailVBox/RewardLabel
@onready var _team_label:   Label         = $Card/VBox/DetailCard/Margin/DetailVBox/TeamLabel
@onready var _ot_list:      VBoxContainer = $Card/VBox/DetailCard/Margin/DetailVBox/OtList
@onready var _action_btn:   Button        = $Card/VBox/ActionBtn
@onready var _status_label: Label         = $Card/VBox/StatusLabel
@onready var _assign_panel: Panel         = $AssignPanel
@onready var _assign_title: Label         = $AssignPanel/AssignMargin/AssignVBox/AssignTitle
@onready var _assign_list:  VBoxContainer = $AssignPanel/AssignMargin/AssignVBox/AssignScroll/AssignList

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:            Node  = null
var _tab:           int   = TAB_ACTIVE
var _projects:      Array = []
var current_index:  int   = 0
var _selected_pid:  int   = -1

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Dimmer.gui_input.connect(_on_dimmer_input)
	_gm = get_node_or_null("/root/GameManager")
	if _gm != null:
		_gm.economy.cash_changed.connect(_on_cash_changed)
		_gm.projects.projects_updated.connect(_on_projects_updated)
		_cash_label.text = "$%d" % _gm.economy.current_cash
	_assign_panel.visible = false
	_on_active_tab()

# ─────────────────────────────────────────
#  TABS
# ─────────────────────────────────────────
func _on_active_tab() -> void:
	_tab = TAB_ACTIVE
	current_index = 0
	_status_label.text = ""
	_active_tab.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
	_avail_tab.add_theme_color_override("font_color",  Color(0.6, 0.7, 0.9, 1.0))
	_reload_projects()

func _on_avail_tab() -> void:
	_tab = TAB_AVAIL
	current_index = 0
	_status_label.text = ""
	_active_tab.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 1.0))
	_avail_tab.add_theme_color_override("font_color",  Color(0.2, 0.85, 0.94, 1.0))
	_reload_projects()

func _reload_projects() -> void:
	if _gm == null:
		_projects = []
	elif _tab == TAB_ACTIVE:
		_projects = _gm.projects.get_active_projects()
	else:
		_projects = _gm.projects.get_available_projects()
	if not _projects.is_empty() and current_index >= _projects.size():
		current_index = _projects.size() - 1
	_refresh_display()

# ─────────────────────────────────────────
#  NAVIGATION
# ─────────────────────────────────────────
func _on_prev_pressed() -> void:
	if _projects.is_empty():
		return
	current_index = (current_index - 1 + _projects.size()) % _projects.size()
	_status_label.text = ""
	_refresh_display()

func _on_next_pressed() -> void:
	if _projects.is_empty():
		return
	current_index = (current_index + 1) % _projects.size()
	_status_label.text = ""
	_refresh_display()

# ─────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────
func _refresh_display() -> void:
	for child in _ot_list.get_children():
		child.queue_free()

	if _projects.is_empty():
		_item_name.text     = "None"
		_page_label.text    = "0 / 0"
		_role_label.text    = ""
		_info_label.text    = "No projects in this category."
		_reward_label.text  = ""
		_team_label.text    = ""
		_action_btn.visible = false
		return

	_action_btn.visible = true
	var proj: Dictionary = _projects[current_index]
	var role: int        = int(proj.get("required_role", 0))

	_item_name.text    = proj.get("name", "Project")
	_page_label.text   = "%d / %d" % [current_index + 1, _projects.size()]
	_role_label.text   = _role_name(role)
	_reward_label.text = "$%d  +%d CP" % [int(proj.get("reward_cash", 0)), int(proj.get("reward_corp_points", 0))]

	if _tab == TAB_ACTIVE:
		var progress: float  = float(proj.get("progress", 0.0))
		_info_label.text = "%d%% complete" % int(progress * 100.0)
		var ids: Array = proj.get("assigned_employee_ids", [])
		if ids.is_empty():
			_team_label.text = "No employees assigned"
		else:
			var names: Array[String] = []
			if _gm != null:
				for emp in _gm.employees.get_hired_employees():
					if emp.id in ids:
						names.append(str(emp.first_name))
			_team_label.text = "Team: " + ", ".join(names)
		_build_ot_list(proj)
		_action_btn.text = "ASSIGN"
		_action_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	else:
		var dur: int = int(proj.get("duration_ticks", proj.get("duration_days", 0)))
		_info_label.text = "%d ticks" % dur
		_team_label.text = ""
		_action_btn.text = "ACCEPT"
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

func _build_ot_list(proj: Dictionary) -> void:
	var ids: Array = proj.get("assigned_employee_ids", [])
	if ids.is_empty() or _gm == null:
		return
	var hdr: Label = Label.new()
	hdr.text = "OT:"
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 1.0))
	_ot_list.add_child(hdr)
	for emp in _gm.employees.get_hired_employees():
		if not (emp.id in ids):
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_ot_list.add_child(row)
		var n_lbl: Label = Label.new()
		n_lbl.text = str(emp.first_name)
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.add_theme_font_size_override("font_size", 10)
		n_lbl.add_theme_color_override("font_color", Color(0.7, 0.71, 0.82, 1.0))
		n_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(n_lbl)
		var ot_btn: Button = Button.new()
		ot_btn.text = _ot_label(int(emp.ot_level))
		ot_btn.add_theme_font_size_override("font_size", 9)
		ot_btn.add_theme_color_override("font_color", _ot_color(int(emp.ot_level)))
		ot_btn.custom_minimum_size = Vector2(100, 22)
		var eid: String = str(emp.id)
		ot_btn.pressed.connect(func() -> void: _cycle_ot(eid))
		row.add_child(ot_btn)

# ─────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────
func _on_action_pressed() -> void:
	if _projects.is_empty() or _gm == null:
		return
	var proj: Dictionary = _projects[current_index]
	var pid: int         = int(proj.get("id", -1))
	if _tab == TAB_ACTIVE:
		_open_assign(pid, proj.get("name", "Project"))
	else:
		_gm.projects.accept_project(pid)
		_status_label.text = "Project accepted!"
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

func _open_assign(pid: int, proj_name: String) -> void:
	_selected_pid = pid
	_assign_title.text = "Assign to: " + proj_name
	for child in _assign_list.get_children():
		child.queue_free()
	if _gm == null:
		return
	var avail: Array = _gm.employees.get_available_employees()
	if avail.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No available employees."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
		lbl.add_theme_font_size_override("font_size", 12)
		_assign_list.add_child(lbl)
	else:
		for emp in avail:
			var btn: Button = Button.new()
			btn.text = "%s  (%s)" % [emp.full_name(), _role_name(int(emp.role))]
			btn.custom_minimum_size = Vector2(0, 36)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_color_override("font_color", _role_color(int(emp.role)))
			btn.add_theme_font_size_override("font_size", 12)
			var eid: String = str(emp.id)
			btn.pressed.connect(func() -> void: _on_assign_employee(eid))
			_assign_list.add_child(btn)
	_assign_panel.visible = true

func _on_assign_close_pressed() -> void:
	_assign_panel.visible = false
	_selected_pid = -1

func _on_assign_employee(emp_id: String) -> void:
	if _gm == null:
		return
	_gm.projects.assign_employee(_selected_pid, emp_id, _gm)
	_assign_panel.visible = false
	_selected_pid = -1
	_reload_projects()

func _cycle_ot(emp_id: String) -> void:
	if _gm == null:
		return
	for emp in _gm.employees.get_hired_employees():
		if str(emp.id) == emp_id:
			emp.ot_level = (int(emp.ot_level) + 1) % 4
			_refresh_display()
			return

func _on_close_pressed() -> void:
	screen_closed.emit()
	queue_free()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(new_cash: int) -> void:
	_cash_label.text = "$%d" % new_cash

func _on_projects_updated() -> void:
	_reload_projects()

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _ot_label(level: int) -> String:
	match level:
		1: return "Light OT +2h"
		2: return "Heavy OT +4h"
		3: return "CRUNCH +8h"
	return "No OT"

func _ot_color(level: int) -> Color:
	match level:
		1: return Color(1.0, 0.9, 0.2, 1.0)
		2: return Color(1.0, 0.55, 0.1, 1.0)
		3: return Color(1.0, 0.2, 0.2, 1.0)
	return Color(0.5, 0.51, 0.62, 1.0)

func _role_name(role: int) -> String:
	match role:
		0: return "Developer"
		1: return "Designer"
		2: return "Marketer"
		3: return "HR"
		4: return "Accountant"
		5: return "Manager"
		6: return "Intern"
	return "Unknown"

func _role_color(role: int) -> Color:
	match role:
		0: return Color(0.22, 0.9,  0.42, 1.0)
		1: return Color(0.94, 0.47, 0.20, 1.0)
		2: return Color(0.20, 0.85, 0.94, 1.0)
		3: return Color(0.90, 0.22, 0.42, 1.0)
		4: return Color(1.00, 0.82, 0.10, 1.0)
		5: return Color(0.78, 0.22, 0.90, 1.0)
	return Color(0.50, 0.51, 0.62, 1.0)
