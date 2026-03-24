extends "res://scripts/ui/BaseModal.gd"

# ─────────────────────────────────────────
#  VIEW MODES
# ─────────────────────────────────────────
const MODE_PROJECTS: String = "projects"
const MODE_TASKS:    String = "tasks"

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _cash_label:   Label         = $Dimmer/Card/VBox/CashLabel
@onready var _back_btn:     Button        = $Dimmer/Card/VBox/TabRow/ActiveTab
@onready var _area_label:   Button        = $Dimmer/Card/VBox/TabRow/AvailTab
@onready var _role_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RoleLabel
@onready var _info_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/InfoLabel
@onready var _reward_label: Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RewardLabel
@onready var _team_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/TeamLabel
@onready var _ot_list:      VBoxContainer = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/OtList
@onready var _status_label: Label         = $Dimmer/Card/VBox/StatusLabel
@onready var _assign_panel: Panel         = $AssignPanel
@onready var _assign_title: Label         = $AssignPanel/AssignMargin/AssignVBox/AssignTitle
@onready var _assign_list:  VBoxContainer = $AssignPanel/AssignMargin/AssignVBox/AssignScroll/AssignList

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:                 Node   = null
var _view_mode:          String = MODE_PROJECTS
var _current_project_id: String = ""
var _projects:           Array  = []
var _tasks:              Array  = []
var _desc_label:         Label  = null
var _subtitle_label:     Label  = null

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	super._ready()
	set_title("PROJECTS")
	_gm = get_node_or_null("/root/GameManager")
	if _gm != null:
		_gm.economy.cash_changed.connect(_on_cash_changed)
		_gm.projects.projects_updated.connect(_on_projects_updated)
		_cash_label.text = "$%d" % _gm.economy.current_cash

	# Subtitle label (official name / task stat line) — inserted above desc
	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 10)
	_subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Description label — inserted into VBox after ArrowRow
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.max_lines_visible = 3

	var arrow_row: Node = _item_name_label.get_parent()
	var vbox: Node = arrow_row.get_parent()
	vbox.add_child(_subtitle_label)
	vbox.move_child(_subtitle_label, arrow_row.get_index() + 1)
	vbox.add_child(_desc_label)
	vbox.move_child(_desc_label, arrow_row.get_index() + 2)

	# Configure tab row buttons for new roles
	_back_btn.text    = "BACK"
	_area_label.text  = "Ban Nong Khao"
	_area_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	_area_label.add_theme_font_size_override("font_size", 11)

	_assign_panel.visible = false
	_show_projects_mode()

# ─────────────────────────────────────────
#  MODE SWITCHING
# ─────────────────────────────────────────
func _show_projects_mode() -> void:
	_view_mode       = MODE_PROJECTS
	_current_index   = 0
	_status_label.text = ""
	_back_btn.visible  = false
	_area_label.visible = true
	if _gm != null:
		_projects = _gm.projects.get_projects()
	else:
		_projects = []
	set_items_count(_projects.size())

func _show_tasks_mode(project_id: String) -> void:
	_view_mode          = MODE_TASKS
	_current_project_id = project_id
	_current_index      = 0
	_status_label.text  = ""
	_back_btn.visible   = true
	_area_label.visible = false
	if _gm != null:
		_tasks = _gm.projects.get_tasks_for_project(project_id)
	else:
		_tasks = []
	set_items_count(_tasks.size())

# ─────────────────────────────────────────
#  DISPLAY (BaseModal override)
# ─────────────────────────────────────────
func _refresh_display() -> void:
	if _desc_label == null or _subtitle_label == null:
		return
	_status_label.text = ""
	for child in _ot_list.get_children():
		child.queue_free()

	if _view_mode == MODE_PROJECTS:
		_refresh_projects_display()
	else:
		_refresh_tasks_display()

func _refresh_projects_display() -> void:
	if _projects.is_empty():
		_item_name_label.text = "No Projects"
		_page_label.text      = "0 / 0"
		_subtitle_label.text  = ""
		_desc_label.text      = "No project data available."
		_role_label.text      = ""
		_info_label.text      = ""
		_reward_label.text    = ""
		_team_label.text      = ""
		_action_btn.visible   = false
		return

	super._refresh_display()
	_action_btn.visible = true

	var proj: Dictionary = _projects[_current_index]
	var proj_status: String = proj.get("status", "available")
	var is_locked: bool = proj_status == "locked"
	var is_done: bool   = proj_status == "completed"

	# Name row: humor title
	_item_name_label.text = proj.get("name", "Project")
	_subtitle_label.text  = proj.get("subtitle", "")
	_desc_label.text      = proj.get("description", "")

	# Progress
	var pct: float         = proj.get("completion_percent", 0.0)
	var tasks: Array       = proj.get("tasks", [])
	var total_tasks: int   = tasks.size()
	var done_tasks: int    = 0
	for t in tasks:
		if t.get("status", "") == "completed":
			done_tasks += 1
	var bar: String = _progress_bar(pct, 12)
	_info_label.text   = "%s  (%d / %d tasks)" % [bar, done_tasks, total_tasks]
	_role_label.text   = ""
	_reward_label.text = "Reward: $%d  +%d CP  +%d REP" % [
		int(proj.get("reward_cash", 0)),
		int(proj.get("reward_cp", 0)),
		int(proj.get("reward_rep", 0)),
	]

	if is_locked:
		var donor_id: String = proj.get("unlock_donor_id", "")
		_team_label.text = "Locked — win donor to unlock"
		if donor_id != "":
			_status_label.text = "Requires donor: " + donor_id.replace("_", " ").capitalize()
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.1, 1.0))
		_action_btn.text = "LOCKED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	elif is_done:
		_team_label.text = "Project complete!"
		_action_btn.text = "COMPLETED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
	else:
		# Count assigned employees across all tasks
		var assigned_count: int = 0
		for t in tasks:
			assigned_count += t.get("assigned_employee_ids", []).size()
		if assigned_count == 0:
			_team_label.text = "No employees assigned"
		else:
			_team_label.text = "%d employee(s) working" % assigned_count
		_action_btn.text = "VIEW TASKS"
		_action_btn.disabled = false
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

func _refresh_tasks_display() -> void:
	if _tasks.is_empty():
		_item_name_label.text = "No Tasks"
		_page_label.text      = "0 / 0"
		_subtitle_label.text  = ""
		_desc_label.text      = "This project has no tasks."
		_role_label.text      = ""
		_info_label.text      = ""
		_reward_label.text    = ""
		_team_label.text      = ""
		_action_btn.visible   = false
		return

	super._refresh_display()
	_action_btn.visible = true

	var task: Dictionary     = _tasks[_current_index]
	var task_status: String  = task.get("status", "blocked")
	var is_done: bool        = task_status == "completed"
	var is_blocked: bool     = task_status == "blocked"
	var progress: float      = task.get("progress", 0.0)
	var ids: Array           = task.get("assigned_employee_ids", [])

	# Name row
	_item_name_label.text = task.get("name", "Task")
	_subtitle_label.text  = task.get("subtitle", "")
	_desc_label.text      = task.get("description", "")

	# Stats
	var primary: String   = task.get("primary_stat", "").capitalize()
	var secondary: String = task.get("secondary_stat", "").capitalize()
	_role_label.text = "%s / %s" % [primary, secondary]

	# Progress bar
	var bar: String = _progress_bar(progress, 12)
	_info_label.text = bar

	_reward_label.text = "+$%d  +%d CP  |  Duration: %d month(s)" % [
		int(task.get("reward_cash", 0)),
		int(task.get("reward_cp", 0)),
		int(task.get("duration", 1)),
	]

	# Team
	if ids.is_empty():
		_team_label.text = "No one assigned  (max 3)"
	else:
		var names: Array[String] = []
		if _gm != null:
			for emp in _gm.employees.get_hired_employees():
				if str(emp.id) in ids:
					names.append(str(emp.first_name))
		_team_label.text = "Team: %s  (%d/3)" % [", ".join(names), ids.size()]

	# Dependency hint
	if is_blocked:
		var reqs: Array = task.get("requires", [])
		_status_label.text = "Waiting for: " + ", ".join(reqs)
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.1, 1.0))

	# Action button
	if is_done:
		_action_btn.text = "DONE"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
	elif is_blocked:
		_action_btn.text = "BLOCKED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	elif ids.size() >= 3:
		_action_btn.text = "FULL (3/3)"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	else:
		_action_btn.text = "ASSIGN"
		_action_btn.disabled = false
		_action_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))

# ─────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────
func _on_action_pressed() -> void:
	if _gm == null:
		return
	if _view_mode == MODE_PROJECTS:
		if _projects.is_empty():
			return
		var proj: Dictionary = _projects[_current_index]
		var s: String = proj.get("status", "")
		if s != "locked" and s != "completed":
			_show_tasks_mode(proj.get("id", ""))
	else:
		if _tasks.is_empty():
			return
		var task: Dictionary = _tasks[_current_index]
		var s: String = task.get("status", "")
		if s != "blocked" and s != "completed":
			_open_assign_for_task(task)

# Called by ActiveTab (repurposed as BACK button)
func _on_active_tab() -> void:
	if _view_mode == MODE_TASKS:
		_show_projects_mode()

# Called by AvailTab — area label, no action needed
func _on_avail_tab() -> void:
	pass

func _open_assign_for_task(task: Dictionary) -> void:
	_assign_title.text = "Assign to: " + task.get("name", "Task")
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
		var task_id: String = task.get("id", "")
		for emp in avail:
			var btn: Button = Button.new()
			btn.text = "%s  (%s)" % [emp.full_name(), _role_name(int(emp.role))]
			btn.custom_minimum_size = Vector2(0, 36)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_color_override("font_color", _role_color(int(emp.role)))
			btn.add_theme_font_size_override("font_size", 12)
			var eid: String = str(emp.id)
			btn.pressed.connect(func() -> void: _on_assign_employee(task_id, eid))
			_assign_list.add_child(btn)
	_assign_panel.visible = true

func _on_assign_close_pressed() -> void:
	_assign_panel.visible = false

func _on_assign_employee(task_id: String, emp_id: String) -> void:
	if _gm == null:
		return
	_gm.projects.assign_employee_to_task(task_id, emp_id)
	_assign_panel.visible = false
	# Refresh task list so changes are visible
	if _gm != null and _current_project_id != "":
		_tasks = _gm.projects.get_tasks_for_project(_current_project_id)
	_refresh_display()

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(new_cash: int) -> void:
	_cash_label.text = "$%d" % new_cash

func _on_projects_updated() -> void:
	if _view_mode == MODE_PROJECTS:
		if _gm != null:
			_projects = _gm.projects.get_projects()
		if not _projects.is_empty() and _current_index >= _projects.size():
			_current_index = _projects.size() - 1
		set_items_count(_projects.size())
	else:
		if _gm != null and _current_project_id != "":
			_tasks = _gm.projects.get_tasks_for_project(_current_project_id)
		if not _tasks.is_empty() and _current_index >= _tasks.size():
			_current_index = _tasks.size() - 1
		set_items_count(_tasks.size())

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _progress_bar(pct: float, width: int) -> String:
	var filled: int = int(round(pct * float(width)))
	var bar: String = ""
	for i: int in range(width):
		if i < filled:
			bar += "#"
		else:
			bar += "-"
	return "[%s] %d%%" % [bar, int(pct * 100.0)]

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
