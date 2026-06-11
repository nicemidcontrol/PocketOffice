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
@onready var _tab_row:      HBoxContainer = $Dimmer/Card/VBox/TabRow
@onready var _back_btn:     Button        = $Dimmer/Card/VBox/BackBtn
@onready var _status_label: Label         = $Dimmer/Card/VBox/StatusLabel
@onready var _role_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RoleLabel
@onready var _info_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/InfoLabel
@onready var _reward_label: Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RewardLabel
@onready var _team_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/TeamLabel
@onready var _ot_list:      VBoxContainer = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/OtList
@onready var _assign_panel: Panel         = $AssignPanel
@onready var _assign_title: Label         = $AssignPanel/AssignMargin/AssignVBox/AssignTitle
@onready var _assign_list:  VBoxContainer = $AssignPanel/AssignMargin/AssignVBox/AssignScroll/AssignList

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:                 Node   = null
var _view_mode:          String = "projects"
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
		_cash_label.text = _gm.format_cash(_gm.economy.current_cash)

	# Hide old TabRow — navigation is now handled by BackBtn at bottom
	_tab_row.visible = false

	# Subtitle label (official name / stat line) — inserted after ArrowRow
	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 11)
	_subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Description label — italic grey
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.max_lines_visible = 2

	var arrow_row: Node = _item_name_label.get_parent()
	var vbox: Node = arrow_row.get_parent()
	vbox.add_child(_subtitle_label)
	vbox.move_child(_subtitle_label, arrow_row.get_index() + 1)
	vbox.add_child(_desc_label)
	vbox.move_child(_desc_label, arrow_row.get_index() + 2)

	_back_btn.pressed.connect(_on_back_pressed)
	_back_btn.visible  = false
	_assign_panel.visible = false

	_show_projects_mode()

# ─────────────────────────────────────────
#  MODE SWITCHING
# ─────────────────────────────────────────
func _show_projects_mode() -> void:
	_view_mode     = MODE_PROJECTS
	_current_index = 0
	set_title("PROJECTS")
	_back_btn.visible = false
	if _gm != null:
		_projects = _gm.projects.get_projects()
	else:
		_projects = []
	set_items_count(_projects.size())

func _show_tasks_mode(project_id: String) -> void:
	_view_mode          = MODE_TASKS
	_current_project_id = project_id
	_current_index      = 0
	_back_btn.visible   = true
	if _gm != null:
		_tasks = _gm.projects.get_tasks_for_project(project_id)
	else:
		_tasks = []
	# Title = project humor name
	for p in _projects:
		if p.get("id", "") == project_id:
			set_title(p.get("name", "TASKS"))
			break
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

	var proj: Dictionary    = _projects[_current_index]
	var proj_id: String     = proj.get("id", "")
	var proj_status: String = proj.get("status", "available")
	var is_locked: bool     = proj_status == "locked"
	var is_done: bool       = proj_status == "completed"
	var is_progress: bool   = proj_status == "in_progress"

	# Lines 1-3: name, subtitle, description
	_item_name_label.text = proj.get("name", "Project")
	_subtitle_label.text  = proj.get("subtitle", "")
	_desc_label.text      = proj.get("description", "")

	# Line 4: Progress — count from task list
	var task_list: Array = []
	if _gm != null and proj_id != "":
		task_list = _gm.projects.get_tasks_for_project(proj_id)
	var total_tasks: int = task_list.size()
	var done_tasks: int  = 0
	for t in task_list:
		if t.get("status", "") == "completed":
			done_tasks += 1
	_role_label.text = ""
	_info_label.text = "%d/%d tasks done" % [done_tasks, total_tasks]

	# Line 5: Reward
	_reward_label.text = "%s  +%d CP  +%d Rep" % [
		_gm.format_cash(int(proj.get("reward_cash", 0))),
		int(proj.get("reward_cp", 0)),
		int(proj.get("reward_rep", 0)),
	]

	# Line 6: Status badge + team info + action button
	if is_locked:
		var unlock: String = proj.get("unlock_condition", "")
		if unlock == "":
			unlock = proj.get("locked_reason", "")
		if unlock == "":
			var donor_id: String = proj.get("unlock_donor_id", "")
			if donor_id != "":
				unlock = donor_id.replace("_", " ").capitalize()
		_status_label.text = "LOCKED"
		_status_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
		var reason: String = "Requires: " + unlock if unlock != "" else "Locked"
		_team_label.text = reason
		_team_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
		_action_btn.text     = "LOCKED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	elif is_done:
		_status_label.text = "COMPLETED"
		_status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		_team_label.text = "Project complete!"
		_team_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		_action_btn.text     = "COMPLETED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	elif is_progress:
		_status_label.text = "IN PROGRESS"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
		_team_label.text = "Work in progress"
		_team_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		_action_btn.text     = "VIEW TASKS"
		_action_btn.disabled = false
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	else:
		# available
		_status_label.text = "AVAILABLE"
		_status_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		_team_label.text = "Ready to start"
		_team_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		_action_btn.text     = "VIEW TASKS"
		_action_btn.disabled = false
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

# ─────────────────────────────────────────
#  READ-ONLY TASK DISPLAY
# ─────────────────────────────────────────
func _refresh_tasks_display() -> void:
	# v1.4 work round flow removed — tasks are shown read-only.
	_action_btn.visible = false
	_back_btn.visible   = true

	if _tasks.is_empty():
		_item_name_label.text = "No Tasks"
		_page_label.text      = "0 / 0"
		_subtitle_label.text  = ""
		_desc_label.text      = "This project has no tasks."
		_role_label.text      = ""
		_info_label.text      = ""
		_reward_label.text    = ""
		_team_label.text      = ""
		return

	super._refresh_display()

	var task: Dictionary    = _tasks[_current_index]
	var task_status: String = task.get("status", "blocked")

	_item_name_label.text = task.get("name", "Task")
	_subtitle_label.text  = task.get("subtitle", "")
	_desc_label.text      = task.get("description", "")

	# Phase list, e.g. "PLANNING > EXECUTION > LOGISTICS"
	var phase_names: Array[String] = []
	for phase in task.get("phases", []):
		phase_names.append(str(phase.get("parameter", "")))
	_role_label.text = " > ".join(phase_names)

	var duration_ticks: int = int(task.get("duration_ticks", task.get("duration", 0)))
	var cash_text: String = "$%d" % int(task.get("reward_cash", 0))
	if _gm != null:
		cash_text = _gm.format_cash(int(task.get("reward_cash", 0)))
	_info_label.text = "%d ticks | %s  +%d CP" % [
		duration_ticks,
		cash_text,
		int(task.get("reward_cp", 0)),
	]
	_reward_label.text = ""

	# Status badge
	_status_label.text = task_status.replace("_", " ").to_upper()
	match task_status:
		"completed":
			_status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		"in_progress":
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
		"available":
			_status_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		_:
			_status_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))

	_team_label.text = ""

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

func _on_back_pressed() -> void:
	_view_mode = MODE_PROJECTS
	_show_projects_mode()

# Scene signal stubs (TabRow buttons — kept for connection compatibility)
func _on_active_tab() -> void:
	pass

func _on_avail_tab() -> void:
	pass

# Delegated from scene signal (AssignPanel close button)
func _on_assign_close_pressed() -> void:
	_assign_panel.visible = false

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(new_cash: int) -> void:
	_cash_label.text = _gm.format_cash(new_cash)

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
