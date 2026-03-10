extends Control

signal training_done

# -----------------------------------------
#  NODE REFS
# -----------------------------------------
@onready var _tab_train:     Button          = $TabBar/TrainTab
@onready var _tab_combo:     Button          = $TabBar/ComboTab
@onready var _train_scroll:  ScrollContainer = $TrainScroll
@onready var _slot_hbox:     HBoxContainer   = $TrainScroll/TrainVBox/AnimArea/SlotCenter/SlotHBox
@onready var _prev_btn:      Button          = $TrainScroll/TrainVBox/NavRow/PrevBtn
@onready var _next_btn:      Button          = $TrainScroll/TrainVBox/NavRow/NextBtn
@onready var _card_name:     Label           = $TrainScroll/TrainVBox/CardPanel/CardMargin/CardVBox/CardNameLabel
@onready var _card_tiercost: Label           = $TrainScroll/TrainVBox/CardPanel/CardMargin/CardVBox/CardTierCostLabel
@onready var _card_stats:    Label           = $TrainScroll/TrainVBox/CardPanel/CardMargin/CardVBox/CardStatsLabel
@onready var _card_bonus:    Label           = $TrainScroll/TrainVBox/CardPanel/CardMargin/CardVBox/CardBonusLabel
@onready var _combo_scroll:  ScrollContainer = $ComboScroll
@onready var _combo_list:    VBoxContainer   = $ComboScroll/ComboList
@onready var _run_btn:       Button          = $TrainScroll/TrainVBox/RunBtn
@onready var _result_panel:  Panel           = $ResultPanel
@onready var _result_label:  Label           = $ResultPanel/Margin/ResultLabel
@onready var _result_close:  Button          = $ResultPanel/CloseBtn
@onready var _cp_label:      Label           = $TopBar/CpLabel
@onready var _combo_hint:    Label           = $TrainScroll/TrainVBox/ComboHintLabel
@onready var _cost_label:    Label           = $TrainScroll/TrainVBox/CostLabel
@onready var _back_btn:      Button          = $BottomBtns/BackBtn
@onready var _cancel_btn:    Button          = $BottomBtns/CancelBtn

# -----------------------------------------
#  STATE
# -----------------------------------------
var _gm: Node = null
var _em: Node = null
var _tm: Node = null
var _fm: Node = null
var _selected_training: Dictionary = {}
var _selected_employees: Array = []
var _discovered_combos: Array = []
var _discovered_facility_combos: Array = []

# Slot buttons created at runtime
var _slot_btns: Array = []
# Active picker panel
var _picker_panel: Panel = null
var _active_slot: int = -1

# Arrow navigation
var _training_index: int = 0
var _available_trainings: Array = []

# -----------------------------------------
#  LIFECYCLE
# -----------------------------------------
func _ready() -> void:
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	_em = get_node_or_null("/root/EmployeeManager")
	_fm = get_node_or_null("/root/FacilityManager")
	_tm = load("res://scripts/TrainingManager.gd").new()
	add_child(_tm)
	if _gm != null:
		_discovered_combos = _gm.company_data.get("discovered_training_combos", [])
		_discovered_facility_combos = _gm.company_data.get("discovered_facility_combos", [])
	_back_btn.pressed.connect(_on_back)
	_cancel_btn.pressed.connect(_on_cancel)
	_tab_train.pressed.connect(_show_train_tab)
	_tab_combo.pressed.connect(_show_combo_tab)
	_run_btn.pressed.connect(_on_run_training)
	_prev_btn.pressed.connect(_on_prev_training)
	_next_btn.pressed.connect(_on_next_training)
	_result_close.pressed.connect(func() -> void: _result_panel.visible = false)
	_result_panel.visible = false
	_build_slot_area()
	_show_train_tab()
	_refresh_cp()

# -----------------------------------------
#  TAB SWITCHING
# -----------------------------------------
func _show_train_tab() -> void:
	_train_scroll.visible = true
	_combo_scroll.visible = false
	_tab_train.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_tab_combo.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1))
	_load_available_trainings()
	_refresh_training_card()

func _show_combo_tab() -> void:
	_train_scroll.visible = false
	_combo_scroll.visible = true
	_tab_train.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1))
	_tab_combo.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_build_combo_list()

# -----------------------------------------
#  ARROW NAVIGATION
# -----------------------------------------
func _load_available_trainings() -> void:
	if _gm == null:
		_available_trainings = []
		_selected_training = {}
		return
	_available_trainings = _tm.get_available_trainings(_gm)
	if _available_trainings.is_empty():
		_selected_training = {}
		return
	if _training_index >= _available_trainings.size():
		_training_index = 0
	_selected_training = _available_trainings[_training_index]

func _on_prev_training() -> void:
	if _available_trainings.is_empty():
		return
	_training_index -= 1
	if _training_index < 0:
		_training_index = _available_trainings.size() - 1
	_selected_training = _available_trainings[_training_index]
	_refresh_training_card()
	_refresh_run_btn()
	_refresh_cost()

func _on_next_training() -> void:
	if _available_trainings.is_empty():
		return
	_training_index += 1
	if _training_index >= _available_trainings.size():
		_training_index = 0
	_selected_training = _available_trainings[_training_index]
	_refresh_training_card()
	_refresh_run_btn()
	_refresh_cost()

func _refresh_training_card() -> void:
	if _available_trainings.is_empty():
		_card_name.text = "No trainings available"
		_card_tiercost.text = ""
		_card_stats.text = ""
		_card_bonus.visible = false
		return
	var t: Dictionary = _available_trainings[_training_index]
	var tier: int = t.get("tier", 1)
	match tier:
		1: _card_name.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95, 1))
		2: _card_name.add_theme_color_override("font_color", Color(0.2, 0.85, 0.94, 1))
		_: _card_name.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1, 1))
	_card_name.text = t.get("name", "")
	_card_tiercost.text = "Tier %d  |  %d CP/person" % [tier, t.get("cp_cost", 7)]
	var stats: Dictionary = t.get("stats", {})
	var stat_parts: Array = []
	for k in stats:
		stat_parts.append("%s+%d" % [_stat_short(k), stats[k]])
	_card_stats.text = "  ".join(stat_parts)
	if t.get("double_stat", "") == "role_primary":
		_card_bonus.text = "* Role bonus: doubles primary stat"
		_card_bonus.visible = true
	else:
		_card_bonus.visible = false

# -----------------------------------------
#  COMBO LIST
# -----------------------------------------
func _build_combo_list() -> void:
	for child in _combo_list.get_children():
		child.queue_free()
	var all_combos: Array = _tm.TRAINING_COMBOS.duplicate()
	if _fm != null:
		for fc in _fm.get_combos():
			all_combos.append(fc)
	for combo in all_combos:
		var is_training_combo: bool = false
		for tc in _tm.TRAINING_COMBOS:
			if tc.get("id", "") == combo.get("id", ""):
				is_training_combo = true
				break
		var is_facility_combo: bool = not is_training_combo
		var discovered: bool = false
		if is_training_combo:
			discovered = _discovered_combos.has(combo.get("id", ""))
		else:
			discovered = _discovered_facility_combos.has(combo.get("id", ""))
		var card: PanelContainer = _make_combo_card(combo, discovered)
		_combo_list.add_child(card)

func _make_combo_card(combo: Dictionary, discovered: bool) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.047, 0.047, 0.11, 0.92)
	card_style.border_width_left   = 2
	card_style.border_width_top    = 2
	card_style.border_width_right  = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.18, 0.42, 0.78, 1) if discovered else Color(0.3, 0.3, 0.35, 1)
	card_style.corner_radius_top_left     = 8
	card_style.corner_radius_top_right    = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left  = 8
	card.add_theme_stylebox_override("panel", card_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	card.add_child(vbox)

	var name_lbl: Label = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color",
		Color(0.92, 0.92, 0.95, 1) if discovered else Color(0.4, 0.4, 0.45, 1))
	name_lbl.text = combo.get("name", "???") if discovered else "???"
	vbox.add_child(name_lbl)

	var req_lbl: Label = Label.new()
	req_lbl.add_theme_font_size_override("font_size", 11)
	req_lbl.add_theme_color_override("font_color",
		Color(0.72, 0.72, 0.78, 1) if discovered else Color(0.35, 0.35, 0.38, 1))
	if discovered:
		var roles: Array = combo.get("requires_roles", [])
		req_lbl.text = "  +  ".join(roles)
	else:
		req_lbl.text = "??? + ??? + ???"
	vbox.add_child(req_lbl)

	var bonus_lbl: Label = Label.new()
	bonus_lbl.add_theme_font_size_override("font_size", 11)
	bonus_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.82, 0.1, 1) if discovered else Color(0.35, 0.35, 0.38, 1))
	bonus_lbl.text = combo.get("bonus_desc", "???") if discovered else "???"
	vbox.add_child(bonus_lbl)

	return card

# -----------------------------------------
#  SLOT AREA
# -----------------------------------------
func _build_slot_area() -> void:
	for child in _slot_hbox.get_children():
		child.queue_free()
	_slot_btns.clear()
	for i in range(3):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = "+\nEMPTY"
		btn.add_theme_font_size_override("font_size", 11)
		var slot_idx: int = i
		btn.pressed.connect(func() -> void: _open_picker(slot_idx))
		_slot_hbox.add_child(btn)
		_slot_btns.append(btn)
	_refresh_slots()

func _refresh_slots() -> void:
	for i in range(3):
		var btn: Button = _slot_btns[i]
		var emp: Object = null
		if i < _selected_employees.size():
			emp = _selected_employees[i]
		var slot_style: StyleBoxFlat = StyleBoxFlat.new()
		slot_style.corner_radius_top_left     = 6
		slot_style.corner_radius_top_right    = 6
		slot_style.corner_radius_bottom_right = 6
		slot_style.corner_radius_bottom_left  = 6
		slot_style.border_width_left   = 2
		slot_style.border_width_top    = 2
		slot_style.border_width_right  = 2
		slot_style.border_width_bottom = 2
		if emp == null or not emp.has_method("role_name"):
			btn.text = "+\nEMPTY"
			slot_style.bg_color = Color(0.047, 0.047, 0.11, 0.92)
			slot_style.border_color = Color(0.18, 0.42, 0.78, 1)
		else:
			var rc: Color = _role_color(emp)
			btn.text = "%s\n%s" % [emp.first_name, emp.role_name().left(3)]
			slot_style.bg_color = Color(rc.r * 0.3, rc.g * 0.3, rc.b * 0.3, 0.95)
			slot_style.border_color = rc
		btn.add_theme_stylebox_override("normal", slot_style)
		btn.add_theme_stylebox_override("hover", slot_style)
		btn.add_theme_stylebox_override("pressed", slot_style)
	_refresh_combo_hint()
	_refresh_run_btn()

func _role_color(emp: Object) -> Color:
	var rn: String = emp.role_name()
	match rn:
		"DEVELOPER":     return Color(0.2, 0.6, 1.0)
		"DESIGNER":      return Color(0.4, 0.9, 0.6)
		"MANAGER":       return Color(0.9, 0.5, 0.8)
		"INTERN":        return Color(0.9, 0.4, 0.4)
		"MARKETER":      return Color(1.0, 0.7, 0.3)
		"HR_SPECIALIST": return Color(0.5, 0.8, 0.9)
		"ACCOUNTANT":    return Color(0.7, 0.7, 0.3)
		"ANALYST":       return Color(0.5, 0.7, 0.9)
		"LEGAL":         return Color(0.8, 0.6, 0.4)
		"IT_SUPPORT":    return Color(0.4, 0.8, 0.5)
		"PR":            return Color(0.9, 0.6, 0.7)
	return Color(0.5, 0.5, 0.5)

func _refresh_combo_hint() -> void:
	var valid_emps: Array = _valid_employees()
	if valid_emps.size() == 3:
		var combo: Dictionary = _tm.check_combo(valid_emps)
		if not combo.is_empty():
			_combo_hint.text = "COMBO: %s" % combo.get("name", "")
			return
	_combo_hint.text = ""
	_refresh_cost()

func _refresh_cost() -> void:
	var valid_emps: Array = _valid_employees()
	if _selected_training.is_empty() or valid_emps.is_empty():
		_cost_label.text = "Cost: 0 CP"
		return
	var cost: int = _tm.get_total_cp_cost(
		_selected_training, valid_emps.size(),
		valid_emps, _discovered_combos)
	_cost_label.text = "Cost: %d CP" % cost

func _refresh_run_btn() -> void:
	_run_btn.disabled = _selected_training.is_empty() or _valid_employees().is_empty()

func _valid_employees() -> Array:
	var result: Array = []
	for e in _selected_employees:
		if e != null and e.has_method("role_name"):
			result.append(e)
	return result

# -----------------------------------------
#  EMPLOYEE PICKER
# -----------------------------------------
func _open_picker(slot_idx: int) -> void:
	_active_slot = slot_idx
	if _picker_panel != null:
		_picker_panel.queue_free()
	_picker_panel = Panel.new()
	var ps: StyleBoxFlat = StyleBoxFlat.new()
	ps.bg_color = Color(0.047, 0.047, 0.11, 0.97)
	ps.border_width_left   = 2
	ps.border_width_top    = 2
	ps.border_width_right  = 2
	ps.border_width_bottom = 2
	ps.border_color = Color(0.18, 0.42, 0.78, 1)
	ps.corner_radius_top_left     = 8
	ps.corner_radius_top_right    = 8
	ps.corner_radius_bottom_right = 8
	ps.corner_radius_bottom_left  = 8
	_picker_panel.add_theme_stylebox_override("panel", ps)
	_picker_panel.set_anchors_preset(Control.PRESET_CENTER)
	_picker_panel.custom_minimum_size = Vector2(260, 320)
	add_child(_picker_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	_picker_panel.add_child(vbox)

	var hdr: Label = Label.new()
	hdr.text = "  Select Employee  "
	hdr.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95, 1))
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var hired: Array = []
	if _gm != null:
		hired = _gm.employees.get_hired_employees()

	for emp in hired:
		var already_in_slot: bool = false
		for j in range(_selected_employees.size()):
			if j != slot_idx and _selected_employees[j] == emp:
				already_in_slot = true
				break
		var emp_btn: Button = Button.new()
		emp_btn.text = "%s  %s  Sk%d" % [emp.full_name(), emp.role_name(), emp.skill]
		emp_btn.add_theme_font_size_override("font_size", 11)
		emp_btn.disabled = already_in_slot
		var emp_ref: Object = emp
		emp_btn.pressed.connect(func() -> void: _on_emp_picked(emp_ref))
		list.add_child(emp_btn)

	var cancel_btn: Button = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.pressed.connect(func() -> void:
		_picker_panel.queue_free()
		_picker_panel = null
	)
	vbox.add_child(cancel_btn)

func _on_emp_picked(emp: Object) -> void:
	while _selected_employees.size() <= _active_slot:
		_selected_employees.append(null)
	_selected_employees[_active_slot] = emp
	# Strip trailing nulls
	while not _selected_employees.is_empty() and _selected_employees.back() == null:
		_selected_employees.pop_back()
	if _picker_panel != null:
		_picker_panel.queue_free()
		_picker_panel = null
	_refresh_slots()
	_refresh_cost()

# -----------------------------------------
#  RUN TRAINING
# -----------------------------------------
func _on_run_training() -> void:
	if _selected_training.is_empty() or _valid_employees().is_empty():
		return
	if _gm == null:
		return
	var valid_emps: Array = _valid_employees()
	if valid_emps.is_empty():
		return
	var total_cost: int = _tm.get_total_cp_cost(
		_selected_training, valid_emps.size(), valid_emps, _discovered_combos)
	if _gm.corp_points < total_cost:
		_result_label.text = "Not enough CP!\nNeed %d CP, have %d CP." % [
			total_cost, _gm.corp_points]
		_result_panel.visible = true
		return
	print("[Training] cost=%d cp=%d" % [total_cost, _gm.corp_points])
	_gm.corp_points -= total_cost
	_gm.corp_points_changed.emit(_gm.corp_points)
	_cp_label.text = "[CP] %d" % _gm.corp_points
	var results: Array = _tm.apply_training(
		_selected_training, valid_emps, _gm, _discovered_combos)

	# Discover combo if new
	var matched_combo: Dictionary = _tm.check_combo(valid_emps)
	if not matched_combo.is_empty():
		var combo_id: String = matched_combo.get("id", "")
		if not _discovered_combos.has(combo_id):
			_discovered_combos.append(combo_id)
			_gm.company_data["discovered_training_combos"] = _discovered_combos

	# Build result text
	var lines: Array = []
	for entry in results:
		var emp: Object = entry["emp"]
		var gained: Dictionary = entry["gained"]
		var emp_line: String = "%s (%s)" % [emp.full_name(), emp.role_name().left(3)]
		var stat_parts: Array = []
		var double_key: String = ""
		if _selected_training.get("double_stat", "") == "role_primary":
			double_key = _tm._role_primary_stat(emp)
		for sk in ["skill", "motivation", "teamwork", "creativity"]:
			if gained.has(sk):
				var suffix: String = " (doubled!)" if sk == double_key and double_key != "" else ""
				stat_parts.append("  %s +%d%s" % [_stat_short(sk), gained[sk], suffix])
		for combo_key in ["combo_all", "combo_skill", "combo_mot", "combo_cre", "combo_exp", "combo_rep"]:
			if gained.has(combo_key):
				stat_parts.append("  [combo] +%d" % gained[combo_key])
		lines.append(emp_line + "\n" + "\n".join(stat_parts))

	if not matched_combo.is_empty():
		lines.append("\nCOMBO: %s!" % matched_combo.get("name", ""))

	_result_label.text = "\n\n".join(lines)
	_result_panel.visible = true
	_refresh_cp()
	_selected_employees.clear()
	_selected_training = {}
	_training_index = 0
	_load_available_trainings()
	_refresh_training_card()
	_refresh_slots()
	_refresh_run_btn()

# -----------------------------------------
#  HELPERS
# -----------------------------------------
func _stat_short(key: String) -> String:
	match key:
		"skill":      return "SKL"
		"motivation": return "MOT"
		"teamwork":   return "TWK"
		"creativity": return "CRE"
	return key.to_upper().left(3)

func _refresh_cp() -> void:
	if _gm != null:
		_cp_label.text = "[CP] %d" % _gm.corp_points

func _on_back() -> void:
	training_done.emit()
	queue_free()

func _on_cancel() -> void:
	queue_free()
