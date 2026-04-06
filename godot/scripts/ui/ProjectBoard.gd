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
var _result_panel:       Panel  = null

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
		var assigned_count: int = 0
		for t in task_list:
			assigned_count += t.get("assigned_employee_ids", []).size()
		_team_label.text = "%d employee(s) working" % assigned_count
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

	var task: Dictionary    = _tasks[_current_index]
	var task_status: String = task.get("status", "locked")
	var is_done: bool       = task_status == "completed"
	var is_locked: bool     = task_status == "locked"
	var is_progress: bool   = task_status == "in_progress"
	var progress: float     = task.get("progress", 0.0)
	var ids: Array          = task.get("assigned_employee_ids", [])

	# Lines 1-3: name, subtitle, description
	_item_name_label.text = task.get("name", "Task")
	_subtitle_label.text  = task.get("subtitle", "")
	_desc_label.text      = task.get("description", "")

	# Line 4: Stats
	var primary: String   = task.get("primary_stat", "").capitalize()
	var secondary: String = task.get("secondary_stat", "").capitalize()
	_role_label.text = primary + " + " + secondary

	# Line 5: Duration
	var duration_ticks: int = int(task.get("duration_ticks", task.get("duration", 0)))
	_info_label.text = "%d ticks" % duration_ticks

	# Line 6: Reward
	_reward_label.text = "%s  +%d CP" % [
		_gm.format_cash(int(task.get("reward_cash", 0))),
		int(task.get("reward_cp", 0)),
	]

	# Line 7: Progress bar — only if in_progress
	if is_progress:
		var bar_lbl: Label = Label.new()
		bar_lbl.text = _progress_bar(progress, 12)
		bar_lbl.add_theme_font_size_override("font_size", 11)
		bar_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
		_ot_list.add_child(bar_lbl)

	# Line 8: Assigned employees
	if ids.is_empty():
		_team_label.text = "Unassigned"
		_team_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	else:
		var names: Array[String] = []
		if _gm != null:
			var hired: Array[Employee] = _gm.employees.get_hired_employees()
			for emp in hired:
				if str(emp.id) in ids:
					names.append(str(emp.first_name))
		_team_label.text = "Team: %s  (%d/3)" % [", ".join(names), ids.size()]
		_team_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))

	# Stat preview for assigned employees
	if not ids.is_empty() and not is_done and not is_locked:
		var primary_stat: String = task.get("primary_stat", "technical")
		var secondary_stat: String = task.get("secondary_stat", "focus")
		_add_stat_preview(ids, primary_stat, secondary_stat)

	# Line 9: Status badge + action button
	if is_locked:
		var prereqs: Array  = task.get("requires", task.get("prerequisites", []))
		var prereq_name: String = ""
		if not prereqs.is_empty():
			var prereq_id: String = str(prereqs[0])
			for other in _tasks:
				if other.get("id", "") == prereq_id:
					prereq_name = other.get("name", "")
					break
			if prereq_name == "":
				prereq_name = prereq_id.replace("_", " ").capitalize()
		_status_label.text = "LOCKED"
		_status_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
		if prereq_name != "":
			_team_label.text = "Requires: " + prereq_name
			_team_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
		_action_btn.text     = "LOCKED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	elif is_done:
		_status_label.text = "COMPLETED"
		_status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		_action_btn.text     = "DONE"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	elif not ids.is_empty():
		# Has employees — show START WORK as main action
		_status_label.text = "READY"
		_status_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		var cp_cost: int = _get_round_cp_cost(task)
		var is_first: bool = _gm.total_rounds_played == 0 if _gm else false
		var has_cp: bool = _gm.corp_points >= cp_cost if _gm else false
		if is_first:
			_action_btn.text     = "START WORK (FREE!)"
			_action_btn.disabled = false
			_action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		elif has_cp:
			_action_btn.text     = "START WORK (%d CP)" % cp_cost
			_action_btn.disabled = false
			_action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		else:
			_action_btn.text     = "NEED %d CP" % cp_cost
			_action_btn.disabled = true
			_action_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		# Show round cost info
		var cost_lbl: Label = Label.new()
		if is_first:
			cost_lbl.text = "Round cost: FREE!"
			cost_lbl.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		else:
			cost_lbl.text = "Round cost: %d CP" % cp_cost
			cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
		cost_lbl.add_theme_font_size_override("font_size", 10)
		_ot_list.add_child(cost_lbl)
		# If team not full, add ASSIGN button to add more
		if ids.size() < 3:
			var assign_btn: Button = Button.new()
			assign_btn.text = "ASSIGN (%d/3)" % ids.size()
			assign_btn.custom_minimum_size = Vector2(0, 30)
			assign_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			assign_btn.add_theme_font_size_override("font_size", 12)
			assign_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
			assign_btn.pressed.connect(func() -> void: _open_assign_for_task(task))
			_ot_list.add_child(assign_btn)
	else:
		# available, no employees
		_status_label.text = "AVAILABLE"
		_status_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		_action_btn.text     = "ASSIGN"
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
		if s == "locked" or s == "completed":
			return
		var emp_ids: Array = task.get("assigned_employee_ids", [])
		if emp_ids.is_empty():
			_open_assign_for_task(task)
		else:
			_start_work_round(task)

func _on_back_pressed() -> void:
	_view_mode = MODE_PROJECTS
	_show_projects_mode()

# Scene signal stubs (TabRow buttons — kept for connection compatibility)
func _on_active_tab() -> void:
	pass

func _on_avail_tab() -> void:
	pass

func _open_assign_for_task(task: Dictionary) -> void:
	_assign_title.text = "Assign to: " + task.get("name", "Task")
	for child in _assign_list.get_children():
		child.queue_free()
	if _gm == null:
		return

	# Collect employee IDs already busy on OTHER tasks
	var busy_ids: Array  = []
	var curr_ids: Array  = task.get("assigned_employee_ids", [])
	var this_id: String  = task.get("id", "")
	for t in _tasks:
		if t.get("id", "") == this_id:
			continue
		for eid in t.get("assigned_employee_ids", []):
			if eid not in busy_ids:
				busy_ids.append(eid)

	var all_emps: Array[Employee] = _gm.employees.get_hired_employees()
	var shown: int      = 0
	for emp in all_emps:
		var eid: String = str(emp.id)
		if eid in busy_ids or eid in curr_ids:
			continue
		var btn: Button = Button.new()
		btn.text = "%s  (%s)" % [emp.full_name(), _role_name(int(emp.role))]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_color_override("font_color", _role_color(int(emp.role)))
		btn.add_theme_font_size_override("font_size", 12)
		var task_id: String = this_id
		btn.pressed.connect(func() -> void: _on_assign_employee(task_id, eid))
		_assign_list.add_child(btn)
		shown += 1

	if shown == 0:
		var lbl: Label = Label.new()
		lbl.text = "No available employees."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
		lbl.add_theme_font_size_override("font_size", 12)
		_assign_list.add_child(lbl)
	_assign_panel.visible = true

func _on_assign_close_pressed() -> void:
	_assign_panel.visible = false

func _on_assign_employee(task_id: String, emp_id: String) -> void:
	if _gm == null:
		return
	_gm.projects.assign_employee_to_task(task_id, emp_id)
	_assign_panel.visible = false
	if _current_project_id != "":
		_tasks = _gm.projects.get_tasks_for_project(_current_project_id)
	_refresh_display()

# ─────────────────────────────────────────
#  WORK ROUND
# ─────────────────────────────────────────
func _start_work_round(task: Dictionary) -> void:
	if _gm == null:
		return
	var task_id: String = task.get("id", "")
	var result: Dictionary = _gm.projects.run_work_round(task_id)
	if result.has("error"):
		_status_label.text = str(result.get("error", "Error"))
		_status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		return
	_show_result_popup(result)

func _show_result_popup(result: Dictionary) -> void:
	if _result_panel != null:
		_result_panel.queue_free()
		_result_panel = null

	# Dark overlay panel
	_result_panel = Panel.new()
	_result_panel.anchors_preset = Control.PRESET_CENTER
	_result_panel.anchor_left = 0.5
	_result_panel.anchor_right = 0.5
	_result_panel.anchor_top = 0.5
	_result_panel.anchor_bottom = 0.5
	_result_panel.offset_left = -170.0
	_result_panel.offset_right = 170.0
	_result_panel.offset_top = -260.0
	_result_panel.offset_bottom = 260.0
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.18, 0.42, 0.78, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	_result_panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.layout_mode = 1
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	margin.grow_vertical = Control.GROW_DIRECTION_BOTH
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_result_panel.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# --- Header ---
	_add_result_label(vbox, "ROUND COMPLETE!", 18, Color(0.95, 0.95, 0.98), true)
	_add_result_label(vbox, result.get("task_name", ""), 13, Color(0.4, 0.8, 1.0), true)

	# --- Grade ---
	var grade: String = result.get("grade", "F")
	_add_result_label(vbox, grade, 48, _grade_color(grade), true)

	var grade_text_lbl: Label = _add_result_label(vbox, result.get("grade_text", ""), 11, Color(0.5, 0.51, 0.62), true)
	grade_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- Separator ---
	vbox.add_child(HSeparator.new())

	# --- Employee contributions ---
	var emp_results: Array = result.get("employee_results", [])
	for er in emp_results:
		var contrib_pct: int = int(er.get("contribution", 0.0) * 100.0)
		_add_result_label(vbox, "%s: +%d%%" % [er.get("employee_name", ""), contrib_pct], 12, Color(0.85, 0.85, 0.92))

	# Combo line
	var combo_name: String = result.get("combo_name", "")
	if combo_name != "":
		var combo_pct: int = int(result.get("combo_bonus", 0.0) * 100.0)
		_add_result_label(vbox, "Combo: %s +%d%%" % [combo_name, combo_pct], 12, Color(1.0, 0.85, 0.0))
	else:
		_add_result_label(vbox, "Combo: None", 11, Color(0.4, 0.4, 0.5))

	# --- Progress ---
	var total_pct: int = int(result.get("total_progress", 0.0) * 100.0)
	_add_result_label(vbox, "Progress: +%d%%" % total_pct, 14, Color(0.22, 0.9, 0.42), true)

	var task_prog: float = result.get("task_progress", 0.0)
	_add_result_label(vbox, _progress_bar(task_prog, 16), 11, Color(1.0, 0.85, 0.1), true)

	# --- Rewards ---
	var reward_text: String = "Rewards: +$%d  +%d CP" % [int(result.get("round_cash", 0)), int(result.get("round_cp", 0))]
	_add_result_label(vbox, reward_text, 13, Color(1.0, 0.82, 0.2), true)

	# CP cost
	var cp_spent: int = int(result.get("cp_cost", 0))
	if cp_spent > 0:
		_add_result_label(vbox, "-%d CP (round cost)" % cp_spent, 11, Color(0.9, 0.5, 0.3), true)

	# Free round message
	if result.get("was_free", false):
		var free_lbl: Label = _add_result_label(vbox, "First round FREE! Next time it'll cost CP.", 11, Color(0.22, 0.9, 0.42), true)
		free_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- Separator ---
	vbox.add_child(HSeparator.new())

	# --- Stat gains ---
	var stat_gains: Array = result.get("stat_gains", [])
	for sg in stat_gains:
		var pg: int = int(sg.get("primary_gain", 0))
		var ssg: int = int(sg.get("secondary_gain", 0))
		var sg_text: String = "%s: %s +%d, %s +%d" % [
			sg.get("name", ""),
			str(sg.get("primary_stat", "")).capitalize(), pg,
			str(sg.get("secondary_stat", "")).capitalize(), ssg,
		]
		_add_result_label(vbox, sg_text, 11, Color(0.4, 0.8, 1.0))

	# --- Task complete banner ---
	if result.get("task_completed", false):
		var bonus_cp: int = int(result.get("completion_cp_bonus", 0))
		_add_result_label(vbox, "TASK COMPLETE!", 20, Color(1.0, 0.85, 0.0), true)
		_add_result_label(vbox, "+%d CP bonus!" % bonus_cp, 14, Color(1.0, 0.85, 0.0), true)

	# --- Continue button ---
	var continue_btn: Button = Button.new()
	continue_btn.text = "CONTINUE"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
	continue_btn.pressed.connect(_on_result_continue)
	vbox.add_child(continue_btn)

	add_child(_result_panel)

func _add_result_label(parent: VBoxContainer, text: String, size: int, color: Color, centered: bool = false) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func _on_result_continue() -> void:
	if _result_panel != null:
		_result_panel.queue_free()
		_result_panel = null
	if _current_project_id != "" and _gm != null:
		_tasks = _gm.projects.get_tasks_for_project(_current_project_id)
	_refresh_display()

func _add_stat_preview(emp_ids: Array, primary_stat: String, secondary_stat: String) -> void:
	if _gm == null:
		return
	var total_primary: float = 0.0
	var total_secondary: float = 0.0
	for emp_id in emp_ids:
		var emp: Employee = null
		for e in _gm.employees.get_hired_employees():
			if str(e.id) == str(emp_id):
				emp = e
				break
		if emp == null:
			continue
		var pv: int = _get_emp_stat(emp, primary_stat)
		var sv: int = _get_emp_stat(emp, secondary_stat)
		total_primary += pv
		total_secondary += sv
		var stars: String = _star_rating(pv) + " " + primary_stat.capitalize() + "  " + _star_rating(sv) + " " + secondary_stat.capitalize()
		var preview_lbl: Label = Label.new()
		preview_lbl.text = "%s: %s" % [str(emp.first_name), stars]
		preview_lbl.add_theme_font_size_override("font_size", 10)
		preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1.0))
		_ot_list.add_child(preview_lbl)

	# Estimated grade
	var avg_primary: float = total_primary / float(emp_ids.size()) if emp_ids.size() > 0 else 0.0
	var avg_secondary: float = total_secondary / float(emp_ids.size()) if emp_ids.size() > 0 else 0.0
	var est_progress: float = 0.0
	for emp_id in emp_ids:
		var emp: Employee = null
		for e in _gm.employees.get_hired_employees():
			if str(e.id) == str(emp_id):
				emp = e
				break
		if emp == null:
			continue
		var pv: int = _get_emp_stat(emp, primary_stat)
		var sv: int = _get_emp_stat(emp, secondary_stat)
		est_progress += (pv / 1000.0) * 0.60 + (sv / 1000.0) * 0.30
	var est_grade: String = _estimate_grade(est_progress)
	var est_lbl: Label = Label.new()
	est_lbl.text = "Est. Grade: %s" % est_grade
	est_lbl.add_theme_font_size_override("font_size", 11)
	est_lbl.add_theme_color_override("font_color", _grade_color(est_grade))
	_ot_list.add_child(est_lbl)

func _get_emp_stat(emp: Employee, stat_name: String) -> int:
	match stat_name:
		"charm":         return int(emp.charm)
		"technical":     return int(emp.technical)
		"procurement":   return int(emp.procurement)
		"focus":         return int(emp.focus)
		"communication": return int(emp.communication)
		"management":    return int(emp.management)
		"logistics":     return int(emp.logistics)
		"precision":     return int(emp.precision)
	return 0

func _star_rating(stat_val: int) -> String:
	if stat_val >= 400:
		return "***"
	elif stat_val >= 200:
		return "**-"
	elif stat_val >= 100:
		return "*--"
	return "---"

func _estimate_grade(progress: float) -> String:
	if progress >= 0.80:
		return "S"
	elif progress >= 0.60:
		return "A"
	elif progress >= 0.45:
		return "B"
	elif progress >= 0.30:
		return "C"
	elif progress >= 0.15:
		return "D"
	return "F"

func _get_round_cp_cost(task: Dictionary) -> int:
	var duration: int = int(task.get("duration_ticks", task.get("duration", 2)))
	if duration >= 5:
		return 8
	elif duration >= 3:
		return 5
	return 3

func _grade_color(grade: String) -> Color:
	match grade:
		"S": return Color(1.0, 0.85, 0.0, 1.0)
		"A": return Color(0.3, 0.9, 0.3, 1.0)
		"B": return Color(0.4, 0.6, 1.0, 1.0)
		"C": return Color(1.0, 1.0, 0.3, 1.0)
		"D": return Color(1.0, 0.6, 0.2, 1.0)
		"F": return Color(0.9, 0.3, 0.3, 1.0)
	return Color(0.5, 0.51, 0.62, 1.0)

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
		0: return "Operations"
		1: return "Procurement"
		2: return "Secretary"
		3: return "Management"
		4: return "Finance"
	return "Unknown"

func _role_color(role: int) -> Color:
	match role:
		0: return Color(0.22, 0.9,  0.42, 1.0)  # green  — OPS
		1: return Color(0.94, 0.47, 0.20, 1.0)  # orange — PRO
		2: return Color(0.20, 0.85, 0.94, 1.0)  # cyan   — SEC
		3: return Color(0.78, 0.22, 0.90, 1.0)  # purple — MGT
		4: return Color(1.00, 0.82, 0.10, 1.0)  # yellow — FIN
	return Color(0.50, 0.51, 0.62, 1.0)
