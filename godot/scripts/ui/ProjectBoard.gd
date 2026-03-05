extends Control

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _cash_label:   Label         = $Header/HdrMargin/HdrHBox/CashLabel
@onready var _active_list:  VBoxContainer = $Body/BodyMargin/BodyVBox/ActiveList
@onready var _avail_list:   VBoxContainer = $Body/BodyMargin/BodyVBox/AvailList
@onready var _assign_popup: Panel         = $AssignPopup
@onready var _popup_title:  Label         = $AssignPopup/PopupVBox/PopupTitle
@onready var _popup_list:   VBoxContainer = $AssignPopup/PopupVBox/PopupScroll/PopupList

# ------------------------------------------
#  STATE
# ------------------------------------------
var _gm: Node            = null
var _selected_pid: int   = -1

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[ProjectBoard] GameManager not found.")
		return
	_gm.economy.cash_changed.connect(_on_cash_changed)
	_gm.projects.projects_updated.connect(_refresh_board)
	_assign_popup.visible = false
	_refresh_cash()
	_refresh_board()

# ------------------------------------------
#  SIGNAL HANDLERS (wired in .tscn)
# ------------------------------------------
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_popup_close_pressed() -> void:
	_assign_popup.visible = false
	_selected_pid = -1

# ------------------------------------------
#  CASH DISPLAY
# ------------------------------------------
func _refresh_cash() -> void:
	_cash_label.text = "$" + _fmt(_gm.economy.current_cash)

func _on_cash_changed(_new_cash: int) -> void:
	_refresh_cash()

func _fmt(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)

# ------------------------------------------
#  BOARD REFRESH
# ------------------------------------------
func _refresh_board() -> void:
	_build_active_section()
	_build_available_section()

func _build_active_section() -> void:
	for child in _active_list.get_children():
		child.queue_free()
	var active: Array = _gm.projects.get_active_projects()
	if active.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No active projects."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
		lbl.add_theme_font_size_override("font_size", 12)
		_active_list.add_child(lbl)
		return
	for proj in active:
		_active_list.add_child(_make_active_card(proj))

func _build_available_section() -> void:
	for child in _avail_list.get_children():
		child.queue_free()
	var avail: Array = _gm.projects.get_available_projects()
	if avail.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No projects available. New projects coming soon!"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
		lbl.add_theme_font_size_override("font_size", 12)
		_avail_list.add_child(lbl)
		return
	for proj in avail:
		_avail_list.add_child(_make_avail_card(proj))

# ------------------------------------------
#  CARD BUILDERS
# ------------------------------------------
func _make_active_card(proj: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom", 10)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	card.add_child(margin)

	var role: int = proj["required_role"]

	var name_lbl: Label = Label.new()
	name_lbl.text = proj["name"]
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var role_lbl: Label = Label.new()
	role_lbl.text = _role_name(role)
	role_lbl.add_theme_color_override("font_color", _role_color(role))
	role_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(role_lbl)

	var pbar: ProgressBar = ProgressBar.new()
	pbar.min_value = 0.0
	pbar.max_value = 1.0
	pbar.value = proj["progress"]
	pbar.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(pbar)

	var pct_lbl: Label = Label.new()
	pct_lbl.text = "%d%% complete" % int(proj["progress"] * 100.0)
	pct_lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
	pct_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(pct_lbl)

	var ids: Array = proj["assigned_employee_ids"]
	if ids.is_empty():
		var no_emp: Label = Label.new()
		no_emp.text = "No employees assigned"
		no_emp.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
		no_emp.add_theme_font_size_override("font_size", 10)
		vbox.add_child(no_emp)
	else:
		var names: Array = []
		var assigned_emps: Array = []
		for emp in _gm.employees.get_hired_employees():
			if emp.id in ids:
				names.append(emp.first_name + " " + emp.last_name)
				assigned_emps.append(emp)
		var emp_lbl: Label = Label.new()
		emp_lbl.text = "Team: " + ", ".join(names)
		emp_lbl.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42))
		emp_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(emp_lbl)

		var ot_sep: HSeparator = HSeparator.new()
		vbox.add_child(ot_sep)

		var ot_hdr: Label = Label.new()
		ot_hdr.text = "OT:"
		ot_hdr.add_theme_font_size_override("font_size", 10)
		ot_hdr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(ot_hdr)

		for ot_emp in assigned_emps:
			var ot_row: HBoxContainer = HBoxContainer.new()
			ot_row.add_theme_constant_override("separation", 6)
			vbox.add_child(ot_row)

			var n_lbl: Label = Label.new()
			n_lbl.text = ot_emp.first_name
			n_lbl.add_theme_font_size_override("font_size", 10)
			n_lbl.add_theme_color_override("font_color", Color(0.7, 0.71, 0.82))
			n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ot_row.add_child(n_lbl)

			var ot_col: Color = _ot_color(ot_emp.ot_level)
			var border_col: Color = Color(ot_col.r, ot_col.g, ot_col.b, 0.5)
			var ot_btn: Button = Button.new()
			ot_btn.text = _ot_label(ot_emp.ot_level)
			ot_btn.add_theme_font_size_override("font_size", 10)
			ot_btn.add_theme_color_override("font_color", ot_col)
			ot_btn.add_theme_stylebox_override("normal",  _btn_style(Color(0.06, 0.06, 0.14), border_col))
			ot_btn.add_theme_stylebox_override("hover",   _btn_style(Color(0.08, 0.08, 0.18), border_col))
			ot_btn.add_theme_stylebox_override("pressed", _btn_style(Color(0.04, 0.04, 0.10), border_col))
			ot_btn.custom_minimum_size = Vector2(110, 26)
			var eid: String = ot_emp.id
			ot_btn.pressed.connect(func() -> void: _cycle_ot(eid))
			ot_row.add_child(ot_btn)

	var assign_btn: Button = Button.new()
	assign_btn.text = "ASSIGN"
	assign_btn.custom_minimum_size = Vector2(0, 32)
	assign_btn.add_theme_stylebox_override("normal",  _btn_style(Color(0.08, 0.22, 0.36), Color(0.18, 0.42, 0.78, 0.7)))
	assign_btn.add_theme_stylebox_override("hover",   _btn_style(Color(0.10, 0.28, 0.44), Color(0.18, 0.42, 0.78, 0.7)))
	assign_btn.add_theme_stylebox_override("pressed", _btn_style(Color(0.06, 0.16, 0.28), Color(0.18, 0.42, 0.78, 0.7)))
	var pid: int = proj["id"]
	assign_btn.pressed.connect(func() -> void: _open_assign_popup(pid))
	vbox.add_child(assign_btn)

	return card

func _make_avail_card(proj: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom", 10)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	card.add_child(margin)

	var role: int = proj["required_role"]

	var name_lbl: Label = Label.new()
	name_lbl.text = proj["name"]
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var info_lbl: Label = Label.new()
	info_lbl.text = "%s  |  %d ticks" % [_role_name(role), proj["duration_ticks"]]
	info_lbl.add_theme_color_override("font_color", _role_color(role))
	info_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(info_lbl)

	var reward_lbl: Label = Label.new()
	reward_lbl.text = "$%s  +%d CP" % [_fmt(proj["reward_cash"]), proj["reward_corp_points"]]
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1))
	reward_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(reward_lbl)

	var accept_btn: Button = Button.new()
	accept_btn.text = "ACCEPT"
	accept_btn.custom_minimum_size = Vector2(0, 32)
	accept_btn.add_theme_stylebox_override("normal",  _btn_style(Color(0.08, 0.36, 0.17), Color(0.22, 0.9, 0.42, 0.7)))
	accept_btn.add_theme_stylebox_override("hover",   _btn_style(Color(0.10, 0.44, 0.20), Color(0.22, 0.9, 0.42, 0.7)))
	accept_btn.add_theme_stylebox_override("pressed", _btn_style(Color(0.06, 0.28, 0.13), Color(0.22, 0.9, 0.42, 0.7)))
	var pid: int = proj["id"]
	accept_btn.pressed.connect(func() -> void: _on_accept_pressed(pid))
	vbox.add_child(accept_btn)

	return card

# ------------------------------------------
#  ACCEPT / ASSIGN FLOW
# ------------------------------------------
func _on_accept_pressed(pid: int) -> void:
	_gm.projects.accept_project(pid)

func _open_assign_popup(project_id: int) -> void:
	_selected_pid = project_id
	for proj in _gm.projects.get_active_projects():
		if proj["id"] == project_id:
			_popup_title.text = "Assign to: " + proj["name"]
			break
	for child in _popup_list.get_children():
		child.queue_free()
	var available: Array = _gm.employees.get_available_employees()
	if available.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No available employees."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
		lbl.add_theme_font_size_override("font_size", 12)
		_popup_list.add_child(lbl)
	else:
		for emp in available:
			var btn: Button = Button.new()
			btn.text = "%s  (%s)" % [emp.full_name(), _role_name(emp.role)]
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_color_override("font_color", _role_color(emp.role))
			btn.add_theme_font_size_override("font_size", 12)
			var eid: String = emp.id
			btn.pressed.connect(func() -> void: _on_assign_employee(eid))
			_popup_list.add_child(btn)
	_assign_popup.visible = true

func _on_assign_employee(employee_id: String) -> void:
	_gm.projects.assign_employee(_selected_pid, employee_id, _gm)
	_assign_popup.visible = false
	_selected_pid = -1

# ------------------------------------------
#  STYLE HELPERS
# ------------------------------------------
func _card_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.078, 0.078, 0.172)
	s.border_width_left   = 1
	s.border_width_top    = 1
	s.border_width_right  = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.18, 0.42, 0.78, 0.55)
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left  = 6
	return s

func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = 1
	s.border_width_top    = 1
	s.border_width_right  = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left  = 4
	s.content_margin_left   = 8.0
	s.content_margin_top    = 4.0
	s.content_margin_right  = 8.0
	s.content_margin_bottom = 4.0
	return s

# ------------------------------------------
#  OT HELPERS
# ------------------------------------------
func _ot_label(level: int) -> String:
	match level:
		1: return "Light OT +2h"
		2: return "Heavy OT +4h"
		3: return "CRUNCH +8h"
		_: return "No OT"

func _ot_color(level: int) -> Color:
	match level:
		1: return Color(1.0, 0.9, 0.2)
		2: return Color(1.0, 0.55, 0.1)
		3: return Color(1.0, 0.2, 0.2)
		_: return Color(0.5, 0.51, 0.62)

func _cycle_ot(emp_id: String) -> void:
	for emp in _gm.employees.get_hired_employees():
		if emp.id == emp_id:
			emp.ot_level = (emp.ot_level + 1) % 4
			_refresh_board()
			return

# ------------------------------------------
#  ROLE HELPERS
# ------------------------------------------
func _role_name(role: int) -> String:
	match role:
		0: return "Developer"
		1: return "Designer"
		2: return "Marketer"
		3: return "HR"
		4: return "Accountant"
		5: return "Manager"
		6: return "Intern"
		_: return "Unknown"

func _role_color(role: int) -> Color:
	match role:
		0: return Color(0.22, 0.9,  0.42)
		1: return Color(0.94, 0.47, 0.20)
		2: return Color(0.20, 0.85, 0.94)
		3: return Color(0.90, 0.22, 0.42)
		4: return Color(1.00, 0.82, 0.10)
		5: return Color(0.78, 0.22, 0.90)
		_: return Color(0.50, 0.51, 0.62)
