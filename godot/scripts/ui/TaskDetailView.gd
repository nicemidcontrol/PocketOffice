extends RefCounted

# Helper for ProjectBoard — renders task detail card, assign panel, stat preview.
# Receives a reference to the ProjectBoard node at setup time and
# accesses its node-refs and state directly.

var _board:   Node          = null
var _btn_row: HBoxContainer = null

func setup(board: Node) -> void:
	_board = board

# ─────────────────────────────────────────
#  TASK DETAIL DISPLAY
# ─────────────────────────────────────────
func refresh_display(tasks: Array, current_index: int) -> void:
	# Clean up any ASSIGN+BACK row injected into the VBox on the previous call.
	if _btn_row != null and is_instance_valid(_btn_row):
		_btn_row.queue_free()
	_btn_row = null

	# In task mode we own the full button area — hide the scene's ActionBtn and
	# BackBtn and build everything inside OtList so order is fully controlled.
	_board._action_btn.visible = false
	_board._back_btn.visible   = false

	if tasks.is_empty():
		_board._item_name_label.text = "No Tasks"
		_board._page_label.text      = "0 / 0"
		_board._subtitle_label.text  = ""
		_board._desc_label.text      = "This project has no tasks."
		_board._role_label.text      = ""
		_board._info_label.text      = ""
		_board._reward_label.text    = ""
		_board._team_label.text      = ""
		return

	_board._base_refresh()

	var task: Dictionary    = tasks[current_index]
	var task_status: String = task.get("status", "locked")
	var is_done: bool       = task_status == "completed"
	var is_locked: bool     = task_status == "locked"
	var is_progress: bool   = task_status == "in_progress"
	var progress: float     = task.get("progress", 0.0)
	var ids: Array          = task.get("assigned_employee_ids", [])

	# --- Header: name, subtitle, description ---
	_board._item_name_label.text = task.get("name", "Task")
	_board._subtitle_label.text  = task.get("subtitle", "")
	_board._desc_label.text      = task.get("description", "")

	# --- Stats + Duration + Reward ---
	var primary: String   = task.get("primary_stat", "").capitalize()
	var secondary: String = task.get("secondary_stat", "").capitalize()
	_board._role_label.text = primary + " + " + secondary

	var duration_ticks: int = int(task.get("duration_ticks", task.get("duration", 0)))
	_board._info_label.text = "%d ticks | %s  +%d CP" % [
		duration_ticks,
		_board._gm.format_cash(int(task.get("reward_cash", 0))),
		int(task.get("reward_cp", 0)),
	]
	_board._reward_label.text = ""

	# --- Team line ---
	if ids.is_empty():
		_board._team_label.text = "Unassigned"
		_board._team_label.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
	else:
		var names: Array[String] = []
		if _board._gm != null:
			var hired: Array[Employee] = _board._gm.employees.get_hired_employees()
			for emp in hired:
				if str(emp.id) in ids:
					names.append(str(emp.first_name))
		_board._team_label.text = "Team: %s  (%d/3)" % [", ".join(names), ids.size()]
		_board._team_label.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))

	# 12px gap after description / team section
	_add_spacer(12)

	# --- Progress bar ---
	if is_progress or (is_done and progress > 0.0):
		var bar_lbl: Label = Label.new()
		bar_lbl.text = _board._progress_bar(progress, 14)
		bar_lbl.add_theme_font_size_override("font_size", 11)
		bar_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
		_board._ot_list.add_child(bar_lbl)
		_add_spacer(12)  # 12px gap after progress bar

	# --- Stat preview (only if employees assigned and not done/locked) ---
	var est_grade: String = ""
	if not ids.is_empty() and not is_done and not is_locked:
		var primary_stat: String   = task.get("primary_stat", "technical")
		var secondary_stat: String = task.get("secondary_stat", "focus")
		# Stat requirements box: 8px internal padding
		var stat_margin: MarginContainer = MarginContainer.new()
		stat_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_margin.add_theme_constant_override("margin_left",   8)
		stat_margin.add_theme_constant_override("margin_top",    8)
		stat_margin.add_theme_constant_override("margin_right",  8)
		stat_margin.add_theme_constant_override("margin_bottom", 8)
		var stat_vbox: VBoxContainer = VBoxContainer.new()
		stat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_margin.add_child(stat_vbox)
		_board._ot_list.add_child(stat_margin)
		est_grade = _add_stat_preview(ids, primary_stat, secondary_stat, stat_vbox)
		_add_spacer(12)  # 12px gap after stat requirements box

	# ─────────────────────────────────────────
	#  BUTTON SECTION — built entirely in OtList
	# ─────────────────────────────────────────
	if is_locked:
		var prereqs: Array      = task.get("requires", task.get("prerequisites", []))
		var prereq_name: String = ""
		if not prereqs.is_empty():
			var prereq_id: String = str(prereqs[0])
			for other in tasks:
				if other.get("id", "") == prereq_id:
					prereq_name = other.get("name", "")
					break
			if prereq_name == "":
				prereq_name = prereq_id.replace("_", " ").capitalize()
		if prereq_name != "":
			var req_lbl: Label = Label.new()
			req_lbl.text = "Requires: " + prereq_name
			req_lbl.add_theme_font_size_override("font_size", 10)
			req_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
			_board._ot_list.add_child(req_lbl)
		_add_spacer(8)
		_board._ot_list.add_child(_make_btn("LOCKED", Color(0.5, 0.51, 0.62, 1.0), false))

	elif is_done:
		_add_spacer(8)
		_board._ot_list.add_child(_make_btn("DONE", Color(0.4, 0.8, 1.0, 1.0), false))

	elif not ids.is_empty():
		# READY state: team assigned, task not complete
		var cp_cost: int      = _board._get_round_cp_cost(task)
		var is_first: bool    = _board._gm.total_rounds_played == 0 if _board._gm else false
		var has_cp: bool      = _board._gm.corp_points >= cp_cost if _board._gm else false
		var cost_text: String = "FREE!" if is_first else "%d CP" % cp_cost

		# Est. Grade / cost line
		_add_spacer(4)
		var info_line: String = ""
		if est_grade != "":
			info_line = "Est. Grade: %s | Cost: %s" % [est_grade, cost_text]
		else:
			info_line = "Round cost: %s" % cost_text
		var info_lbl: Label = Label.new()
		info_lbl.text = info_line
		info_lbl.add_theme_font_size_override("font_size", 11)
		if not has_cp and not is_first:
			info_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		elif est_grade != "":
			info_lbl.add_theme_color_override("font_color", _board._grade_color(est_grade))
		else:
			info_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
		_board._ot_list.add_child(info_lbl)

		# 8px gap before START WORK button
		_add_spacer(8)

		# [ START WORK ] — full width, calls _on_action_pressed
		var sw_color: Color  = Color(0.22, 0.9, 0.42, 1.0) if (is_first or has_cp) else Color(0.9, 0.3, 0.3, 1.0)
		var sw_text: String  = ""
		var sw_on: bool      = true
		if is_first:
			sw_text = "START WORK (FREE!)"
		elif has_cp:
			sw_text = "START WORK (%d CP)" % cp_cost
		else:
			sw_text = "NEED %d CP" % cp_cost
			sw_on   = false
		var sw_btn: Button = _make_btn(sw_text, sw_color, sw_on)
		sw_btn.pressed.connect(_board._on_action_pressed)
		_board._ot_list.add_child(sw_btn)

		# [ ASSIGN (n/3) ] [ BACK ] — only if team not full.
		# Injected directly into the parent VBox just before CloseBtn so the
		# render order is always: START WORK → ASSIGN+BACK → CLOSE.
		if ids.size() < 3:
			_btn_row = HBoxContainer.new()
			_btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_btn_row.add_theme_constant_override("separation", 4)

			var assign_btn: Button = _make_btn("ASSIGN (%d/3)" % ids.size(), Color(0.4, 0.8, 1.0, 1.0), true)
			assign_btn.add_theme_font_size_override("font_size", 12)
			assign_btn.pressed.connect(func() -> void: open_assign_for_task(task, tasks))
			_btn_row.add_child(assign_btn)

			var back_btn: Button = _make_btn("BACK", Color(0.5, 0.51, 0.62, 1.0), true)
			back_btn.add_theme_font_size_override("font_size", 12)
			back_btn.pressed.connect(_board._on_back_pressed)
			_btn_row.add_child(back_btn)

			var vbox: Node = _board._close_btn.get_parent()
			vbox.add_child(_btn_row)
			vbox.move_child(_btn_row, _board._close_btn.get_index() - 1)

	else:
		# Available state: no employees assigned — full-width ASSIGN
		_add_spacer(8)
		var assign_btn: Button = _make_btn("ASSIGN (0/3)", Color(0.4, 0.8, 1.0, 1.0), true)
		assign_btn.pressed.connect(func() -> void: open_assign_for_task(task, tasks))
		_board._ot_list.add_child(assign_btn)

# ─────────────────────────────────────────
#  ASSIGN PANEL
# ─────────────────────────────────────────
func open_assign_for_task(task: Dictionary, tasks: Array) -> void:
	_board._assign_title.text = "Assign to: " + task.get("name", "Task")
	for child in _board._assign_list.get_children():
		child.queue_free()
	if _board._gm == null:
		return

	var busy_ids: Array = []
	var curr_ids: Array = task.get("assigned_employee_ids", [])
	var this_id: String = task.get("id", "")
	for t in tasks:
		if t.get("id", "") == this_id:
			continue
		for eid in t.get("assigned_employee_ids", []):
			if eid not in busy_ids:
				busy_ids.append(eid)

	var all_emps: Array[Employee] = _board._gm.employees.get_hired_employees()
	var shown: int = 0
	for emp in all_emps:
		var eid: String = str(emp.id)
		if eid in busy_ids or eid in curr_ids:
			continue
		var btn: Button = Button.new()
		btn.text = "%s  (%s)" % [emp.full_name(), _board._role_name(int(emp.role))]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_color_override("font_color", _board._role_color(int(emp.role)))
		btn.add_theme_font_size_override("font_size", 12)
		var task_id: String = this_id
		btn.pressed.connect(func() -> void: on_assign_employee(task_id, eid))
		_board._assign_list.add_child(btn)
		shown += 1

	if shown == 0:
		var lbl: Label = Label.new()
		lbl.text = "No available employees."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))
		lbl.add_theme_font_size_override("font_size", 12)
		_board._assign_list.add_child(lbl)
	_board._assign_panel.visible = true

func on_assign_close_pressed() -> void:
	_board._assign_panel.visible = false

func on_assign_employee(task_id: String, emp_id: String) -> void:
	if _board._gm == null:
		return
	_board._gm.projects.assign_employee_to_task(task_id, emp_id)
	_board._assign_panel.visible = false
	if _board._current_project_id != "":
		_board._tasks = _board._gm.projects.get_tasks_for_project(_board._current_project_id)
	_board._refresh_display()

# ─────────────────────────────────────────
#  STAT PREVIEW HELPERS
# ─────────────────────────────────────────
func _add_stat_preview(emp_ids: Array, primary_stat: String, secondary_stat: String, parent: VBoxContainer) -> String:
	if _board._gm == null:
		return "F"
	var est_progress: float = 0.0
	for emp_id in emp_ids:
		var emp: Employee = null
		for e in _board._gm.employees.get_hired_employees():
			if str(e.id) == str(emp_id):
				emp = e
				break
		if emp == null:
			continue
		var pv: int = _get_emp_stat(emp, primary_stat)
		var sv: int = _get_emp_stat(emp, secondary_stat)
		est_progress += (pv / 1000.0) * 0.60 + (sv / 1000.0) * 0.30
		var stars: String = _star_rating(pv) + " " + primary_stat.capitalize() + "  " + _star_rating(sv) + " " + secondary_stat.capitalize()
		var preview_lbl: Label = Label.new()
		preview_lbl.text = "%s: %s" % [str(emp.first_name), stars]
		preview_lbl.add_theme_font_size_override("font_size", 12)
		preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1.0))
		parent.add_child(preview_lbl)
	return _estimate_grade(est_progress)

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

# ─────────────────────────────────────────
#  LAYOUT HELPERS
# ─────────────────────────────────────────
func _add_spacer(height: int) -> void:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	_board._ot_list.add_child(spacer)

func _make_btn(txt: String, color: Color, enabled: bool) -> Button:
	var btn: Button = Button.new()
	btn.text = txt
	btn.custom_minimum_size   = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", color)
	btn.disabled = not enabled
	return btn
