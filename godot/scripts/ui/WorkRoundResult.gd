extends RefCounted

# Helper for ProjectBoard — runs a work round and shows the result popup.
# Receives a reference to the ProjectBoard node at setup time and
# accesses its node-refs and state directly.

var _board:              Node   = null
var _result_panel:       Panel  = null
var _locked_task_ids:    Array  = []
var _locked_project_ids: Array  = []
var _unlock_popup:       Object = null
var _is_thinking:        bool   = false
var _thinking_label:     Label  = null
var _grade_lbl:          Label  = null
var _result_scroll:      ScrollContainer = null

func setup(board: Node) -> void:
	_board = board

# ─────────────────────────────────────────
#  WORK ROUND
# ─────────────────────────────────────────
func start_work_round(task: Dictionary) -> void:
	if _board._gm == null:
		return
	# Snapshot which tasks/projects are blocked/locked BEFORE the round changes state.
	# Tasks use "blocked"; projects use "locked".
	_locked_task_ids    = []
	_locked_project_ids = []
	if _board._current_project_id != "":
		for t in _board._gm.projects.get_tasks_for_project(_board._current_project_id):
			if t.get("status", "") == "blocked":
				_locked_task_ids.append(t.get("id", ""))
	for p in _board._gm.projects.get_projects():
		if p.get("status", "") == "locked":
			_locked_project_ids.append(p.get("id", ""))
	print("[WRR] Snapshot before round — blocked tasks: %s  locked projects: %s" % [_locked_task_ids, _locked_project_ids])

	_show_thinking_panel()
	_start_thinking_phase(task)

# ─────────────────────────────────────────
#  RESULT POPUP
# ─────────────────────────────────────────
func _show_thinking_panel() -> void:
	_is_thinking    = true
	_thinking_label = null
	_grade_lbl      = null
	_result_scroll  = null
	if _result_panel != null:
		_result_panel.queue_free()
		_result_panel = null

	var card_vbox: Node = _board.get_node_or_null("Dimmer/Card/VBox")
	if card_vbox:
		card_vbox.visible = false

	var card: Node        = _board.get_node_or_null("Dimmer/Card")
	var parent_node: Node = card if card else _board

	_result_panel = Panel.new()
	_result_panel.anchor_left   = 0.0
	_result_panel.anchor_top    = 0.0
	_result_panel.anchor_right  = 1.0
	_result_panel.anchor_bottom = 1.0
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	_result_panel.mouse_filter    = Control.MOUSE_FILTER_STOP
	_result_panel.z_index         = 10

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color              = Color(0.1, 0.12, 0.18, 1.0)
	style.border_width_left     = 2
	style.border_width_top      = 2
	style.border_width_right    = 2
	style.border_width_bottom   = 2
	style.border_color          = Color(0.18, 0.42, 0.78, 1.0)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left  = 10
	_result_panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_left   = 0.0
	margin.anchor_top    = 0.0
	margin.anchor_right  = 1.0
	margin.anchor_bottom = 1.0
	margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	margin.grow_vertical   = Control.GROW_DIRECTION_BOTH
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_result_panel.add_child(margin)

	_thinking_label = Label.new()
	_thinking_label.text = "Analyzing..."
	_thinking_label.add_theme_font_size_override("font_size", 28)
	_thinking_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1.0))
	_thinking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thinking_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_thinking_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_thinking_label.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	margin.add_child(_thinking_label)

	parent_node.add_child(_result_panel)
	_result_panel.move_to_front()

func _start_thinking_phase(task: Dictionary) -> void:
	var tw: Tween = _board.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: _set_thinking_text("Calculating..."))
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: _set_thinking_text("Evaluating..."))
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: _compute_and_reveal(task))

func _set_thinking_text(text: String) -> void:
	if _thinking_label != null:
		_thinking_label.text = text

func _compute_and_reveal(task: Dictionary) -> void:
	if not is_instance_valid(_result_panel):
		return
	var task_id: String    = task.get("id", "")
	var result: Dictionary = _board._gm.projects.run_work_round(task_id)
	if result.has("error"):
		_is_thinking = false
		if _result_panel != null:
			_result_panel.queue_free()
			_result_panel = null
		var card_vbox: Node = _board.get_node_or_null("Dimmer/Card/VBox")
		if card_vbox:
			card_vbox.visible = true
		_board._status_label.text = str(result.get("error", "Error"))
		_board._status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		return
	_populate_result(result)
	_reveal_result()

func _populate_result(result: Dictionary) -> void:
	var margin: MarginContainer = _result_panel.get_child(0) as MarginContainer

	_result_scroll = ScrollContainer.new()
	_result_scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_result_scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	_result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_result_scroll.visible = false
	margin.add_child(_result_scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	_result_scroll.add_child(vbox)

	# --- Header ---
	_add_result_label(vbox, "ROUND COMPLETE!", 18, Color(0.95, 0.95, 0.98), true)
	_add_result_label(vbox, result.get("task_name", ""), 13, Color(0.4, 0.8, 1.0), true)

	# --- Grade ---
	var grade: String = result.get("grade", "F")
	_grade_lbl = _add_result_label(vbox, grade, 48, _board._grade_color(grade), true)

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
	_add_result_label(vbox, _board._progress_bar(task_prog, 16), 11, Color(1.0, 0.85, 0.1), true)

	# --- Rewards ---
	var reward_text: String = "Rewards: +$%d  +%d CP" % [int(result.get("round_cash", 0)), int(result.get("round_cp", 0))]
	_add_result_label(vbox, reward_text, 13, Color(1.0, 0.82, 0.2), true)

	var cp_spent: int = int(result.get("cp_cost", 0))
	if cp_spent > 0:
		_add_result_label(vbox, "-%d CP (round cost)" % cp_spent, 11, Color(0.9, 0.5, 0.3), true)

	if result.get("was_free", false):
		var free_lbl: Label = _add_result_label(vbox, "First round FREE! Next time it'll cost CP.", 11, Color(0.22, 0.9, 0.42), true)
		free_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- Separator ---
	vbox.add_child(HSeparator.new())

	# --- Stat gains ---
	var stat_gains: Array = result.get("stat_gains", [])
	for sg in stat_gains:
		var pg: int  = int(sg.get("primary_gain", 0))
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
	continue_btn.pressed.connect(on_result_continue)
	vbox.add_child(continue_btn)

func _reveal_result() -> void:
	_is_thinking = false
	if _thinking_label != null:
		_thinking_label.visible = false
	if _result_scroll != null:
		_result_scroll.visible = true
	if _grade_lbl == null:
		return
	var tw: Tween = _board.create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(func() -> void: _animate_grade_reveal())

func _animate_grade_reveal() -> void:
	if _grade_lbl == null or not is_instance_valid(_grade_lbl):
		return
	_grade_lbl.pivot_offset = _grade_lbl.size / 2.0
	_grade_lbl.scale = Vector2(0.3, 0.3)
	var tw: Tween = _board.create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_grade_lbl, "scale", Vector2(1.0, 1.0), 0.35)

func _add_result_label(parent: VBoxContainer, text: String, size: int, color: Color, centered: bool = false) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func on_result_continue() -> void:
	_is_thinking    = false
	_thinking_label = null
	_grade_lbl      = null
	_result_scroll  = null
	if _result_panel != null:
		_result_panel.queue_free()
		_result_panel = null
	var card_vbox: Node = _board.get_node_or_null("Dimmer/Card/VBox")
	if card_vbox:
		card_vbox.visible = true
	if _board._current_project_id != "" and _board._gm != null:
		_board._tasks = _board._gm.projects.get_tasks_for_project(_board._current_project_id)

	var unlocked: Array = _gather_unlocked()
	print("[WRR] on_result_continue — unlocked items: %d" % unlocked.size())
	if unlocked.is_empty():
		_board._refresh_display()
	else:
		print("[WRR] Showing UnlockPopup with %d item(s)" % unlocked.size())
		var popup_script: GDScript = load("res://scripts/ui/UnlockPopup.gd")
		_unlock_popup = popup_script.new()
		_unlock_popup.show_unlock(_board, unlocked, func() -> void: _board._refresh_display())

# Returns items that were blocked/locked before the round but are now available.
func _gather_unlocked() -> Array:
	var result: Array = []
	if _board._gm == null:
		return result
	if _board._current_project_id != "":
		for t in _board._gm.projects.get_tasks_for_project(_board._current_project_id):
			var tid: String  = t.get("id", "")
			var tnow: String = t.get("status", "")
			print("[WRR] Task '%s' id=%s was_blocked=%s now=%s" % [t.get("name", ""), tid, str(tid in _locked_task_ids), tnow])
			# Was blocked before round, now available → newly unlocked
			if tid in _locked_task_ids and tnow == "available":
				result.append({"type": "task", "name": t.get("name", tid)})
	for p in _board._gm.projects.get_projects():
		var pid: String  = p.get("id", "")
		var pnow: String = p.get("status", "")
		print("[WRR] Project '%s' id=%s was_locked=%s now=%s" % [p.get("name", ""), pid, str(pid in _locked_project_ids), pnow])
		# Was locked before round, now not locked → newly available
		if pid in _locked_project_ids and pnow != "locked":
			result.append({"type": "project", "name": p.get("name", pid)})
	print("[WRR] _gather_unlocked result: %s" % str(result))
	return result
