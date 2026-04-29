extends RefCounted

# Helper for ProjectBoard — runs a work round and animates the result in-place.
# Receives a reference to the ProjectBoard node at setup time.
# VBox stays visible throughout; only ArtworkPanel content and DetailCard labels change.

var _board:              Node   = null
var _locked_task_ids:    Array  = []
var _locked_project_ids: Array  = []
var _unlock_popup:       Object = null
var _round_active:       bool   = false
var _awaiting_continue:  bool   = false
var _anim_label:         Label  = null
var _art_label:          Label  = null
var _dots_tween:         Tween  = null
var _dot_step:           int    = 0

func setup(board: Node) -> void:
	_board = board

func is_awaiting_continue() -> bool:
	return _awaiting_continue

func is_round_active() -> bool:
	return _round_active

# ─────────────────────────────────────────
#  WORK ROUND ENTRY
# ─────────────────────────────────────────
func start_work_round(task: Dictionary) -> void:
	if _board._gm == null:
		return

	# Snapshot blocked/locked state BEFORE the round modifies anything.
	_locked_task_ids    = []
	_locked_project_ids = []
	if _board._current_project_id != "":
		for t in _board._gm.projects.get_tasks_for_project(_board._current_project_id):
			if t.get("status", "") == "blocked":
				_locked_task_ids.append(t.get("id", ""))
	for p in _board._gm.projects.get_projects():
		if p.get("status", "") == "locked":
			_locked_project_ids.append(p.get("id", ""))

	_round_active      = true
	_awaiting_continue = false

	# Clear OtList — removes the START WORK button and stat preview.
	for child in _board._ot_list.get_children():
		child.queue_free()

	# Hide the ASSIGN+BACK row TaskDetailView may have injected into VBox.
	var task_detail: Object = _board._task_detail
	if task_detail != null:
		var btn_row: HBoxContainer = task_detail.get("_btn_row") as HBoxContainer
		if btn_row != null and is_instance_valid(btn_row):
			btn_row.visible = false

	# Lock navigation for the duration of the round.
	_board._prev_btn.disabled = true
	_board._next_btn.disabled = true
	_board._back_btn.visible  = false

	# Show CONTINUE button (disabled until grade is revealed).
	_board._action_btn.text     = "CONTINUE"
	_board._action_btn.disabled = true
	_board._action_btn.visible  = true
	_board._action_btn.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62, 1.0))

	# Animate ArtworkPanel.
	var art_panel: Panel = _board.get_node("Dimmer/Card/VBox/ArtworkPanel") as Panel
	_art_label = art_panel.get_node("ArtLabel") as Label
	_art_label.visible = false

	_anim_label = Label.new()
	_anim_label.text = "Analyzing"
	_anim_label.add_theme_font_size_override("font_size", 28)
	_anim_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1.0))
	_anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anim_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_anim_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_anim_label.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_anim_label.anchor_left   = 0.0
	_anim_label.anchor_top    = 0.0
	_anim_label.anchor_right  = 1.0
	_anim_label.anchor_bottom = 1.0
	_anim_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_anim_label.grow_vertical   = Control.GROW_DIRECTION_BOTH
	art_panel.add_child(_anim_label)

	# Dots tween: cycles "Analyzing" → "Analyzing." → ".." → "..." every 0.3 s.
	_dot_step   = 0
	_dots_tween = _board.create_tween()
	_dots_tween.set_loops()
	_dots_tween.tween_interval(0.3)
	_dots_tween.tween_callback(func() -> void: _cycle_dots())

	# After 1.5 s, stop animation and run the actual computation.
	var delay_tw: Tween = _board.create_tween()
	delay_tw.tween_interval(1.5)
	delay_tw.tween_callback(func() -> void: _compute_and_reveal(task))

func _cycle_dots() -> void:
	if _anim_label == null or not is_instance_valid(_anim_label):
		return
	_dot_step = (_dot_step + 1) % 4
	match _dot_step:
		0: _anim_label.text = "Analyzing"
		1: _anim_label.text = "Analyzing."
		2: _anim_label.text = "Analyzing.."
		3: _anim_label.text = "Analyzing..."

# ─────────────────────────────────────────
#  COMPUTE AND REVEAL
# ─────────────────────────────────────────
func _compute_and_reveal(task: Dictionary) -> void:
	if not is_instance_valid(_board):
		return
	if _board._gm == null:
		return

	if _dots_tween != null:
		_dots_tween.kill()
		_dots_tween = null

	var task_id: String    = task.get("id", "")
	var result: Dictionary = _board._gm.projects.run_work_round(task_id)

	if result.has("error"):
		_restore_on_error()
		_board._status_label.text = str(result.get("error", "Error"))
		_board._status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		return

	_populate_detail_card(result)

	var grade: String      = result.get("grade", "F")
	var grade_color: Color = _grade_to_color(grade)

	if _anim_label == null or not is_instance_valid(_anim_label):
		return
	var fade_tw: Tween = _board.create_tween()
	fade_tw.tween_property(_anim_label, "modulate:a", 0.0, 0.2)
	fade_tw.tween_callback(func() -> void: _show_grade(grade, grade_color))

func _show_grade(grade: String, grade_color: Color) -> void:
	if _anim_label == null or not is_instance_valid(_anim_label):
		return
	_anim_label.text = "GRADE: " + grade
	_anim_label.add_theme_color_override("font_color", grade_color)
	_anim_label.modulate.a = 0.0
	var tw: Tween = _board.create_tween()
	tw.tween_property(_anim_label, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func() -> void: _on_grade_revealed())

func _on_grade_revealed() -> void:
	_awaiting_continue = true
	_board._action_btn.disabled = false
	_board._action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))

func _restore_on_error() -> void:
	_round_active      = false
	_awaiting_continue = false
	if _anim_label != null and is_instance_valid(_anim_label):
		_anim_label.visible = false
		_anim_label.queue_free()
	_anim_label = null
	if _art_label != null and is_instance_valid(_art_label):
		_art_label.visible = true
	_art_label = null
	_board._prev_btn.disabled  = false
	_board._next_btn.disabled  = false
	_board._action_btn.visible = false
	_board._refresh_display()

# ─────────────────────────────────────────
#  DETAIL CARD POPULATION
# ─────────────────────────────────────────
func _populate_detail_card(result: Dictionary) -> void:
	for child in _board._ot_list.get_children():
		child.queue_free()

	# Reward line (reuse RewardLabel — yellow).
	var round_cash: int = int(result.get("round_cash", 0))
	var round_cp: int   = int(result.get("round_cp", 0))
	var rep_gain: int   = int(result.get("reputation_gain", 0))
	var reward_str: String = "+$%d  +%d CP" % [round_cash, round_cp]
	if rep_gain > 0:
		reward_str += "  +%d REP" % rep_gain
	_board._reward_label.text = reward_str

	# Grade flavor text (reuse InfoLabel — grey).
	_board._info_label.text = result.get("grade_text", "")

	# Progress bar in OtList.
	var task_prog: float = result.get("task_progress", 0.0)
	var bar_lbl: Label = Label.new()
	bar_lbl.text = _board._progress_bar(task_prog, 16)
	bar_lbl.add_theme_font_size_override("font_size", 11)
	bar_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	_board._ot_list.add_child(bar_lbl)

	# Per-employee stat gains in OtList.
	var stat_gains: Array = result.get("stat_gains", [])
	for sg in stat_gains:
		var pg: int  = int(sg.get("primary_gain", 0))
		var ssg: int = int(sg.get("secondary_gain", 0))
		var sg_text: String = "%s: %s +%d, %s +%d" % [
			sg.get("name", ""),
			str(sg.get("primary_stat", "")).capitalize(), pg,
			str(sg.get("secondary_stat", "")).capitalize(), ssg,
		]
		var lbl: Label = Label.new()
		lbl.text = sg_text
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_board._ot_list.add_child(lbl)

	# Task completion bonus (if applicable).
	if result.get("task_completed", false):
		var bonus_cp: int = int(result.get("completion_cp_bonus", 0))
		var comp_lbl: Label = Label.new()
		comp_lbl.text = "Task complete! +%d CP bonus" % bonus_cp
		comp_lbl.add_theme_font_size_override("font_size", 11)
		comp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
		comp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_board._ot_list.add_child(comp_lbl)

func _grade_to_color(grade: String) -> Color:
	match grade:
		"S": return Color(1.0,   0.843, 0.0)
		"A": return Color(0.298, 0.686, 0.314)
		"B": return Color(0.149, 0.651, 0.604)
		"C": return Color(0.259, 0.647, 0.961)
		"D": return Color(1.0,   0.596, 0.0)
		"F": return Color(0.898, 0.224, 0.208)
	return Color(0.5, 0.51, 0.62, 1.0)

# ─────────────────────────────────────────
#  CONTINUE HANDLER
# ─────────────────────────────────────────
func on_result_continue() -> void:
	_round_active      = false
	_awaiting_continue = false

	if _anim_label != null and is_instance_valid(_anim_label):
		_anim_label.visible = false
		_anim_label.queue_free()
	_anim_label = null

	if _art_label != null and is_instance_valid(_art_label):
		_art_label.visible = true
	_art_label = null

	_board._prev_btn.disabled = false
	_board._next_btn.disabled = false

	var unlocked: Array = _gather_unlocked()
	print("[WRR] on_result_continue — unlocked items: %d" % unlocked.size())
	if unlocked.is_empty():
		_board._refresh_display()
	else:
		print("[WRR] Showing UnlockPopup with %d item(s)" % unlocked.size())
		var popup_script: GDScript = load("res://scripts/ui/UnlockPopup.gd")
		_unlock_popup = popup_script.new()
		_unlock_popup.show_unlock(_board, unlocked, func() -> void: _board._refresh_display())

# ─────────────────────────────────────────
#  UNLOCK DETECTION
# ─────────────────────────────────────────
func _gather_unlocked() -> Array:
	var result: Array = []
	if _board._gm == null:
		return result
	if _board._current_project_id != "":
		for t in _board._gm.projects.get_tasks_for_project(_board._current_project_id):
			var tid: String  = t.get("id", "")
			var tnow: String = t.get("status", "")
			print("[WRR] Task '%s' id=%s was_blocked=%s now=%s" % [t.get("name", ""), tid, str(tid in _locked_task_ids), tnow])
			if tid in _locked_task_ids and tnow == "available":
				result.append({"type": "task", "name": t.get("name", tid)})
	for p in _board._gm.projects.get_projects():
		var pid: String  = p.get("id", "")
		var pnow: String = p.get("status", "")
		print("[WRR] Project '%s' id=%s was_locked=%s now=%s" % [p.get("name", ""), pid, str(pid in _locked_project_ids), pnow])
		if pid in _locked_project_ids and pnow != "locked":
			result.append({"type": "project", "name": p.get("name", pid)})
	print("[WRR] _gather_unlocked result: %s" % str(result))
	return result
