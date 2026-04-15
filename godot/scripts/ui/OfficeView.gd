extends Control

# ─── SLOT REFS ────────────────────────────────────────────────────────────────
@onready var _slot_0: Panel = $VBox/CenterContainer/Grid/Slot0
@onready var _slot_1: Panel = $VBox/CenterContainer/Grid/Slot1
@onready var _slot_2: Panel = $VBox/CenterContainer/Grid/Slot2
@onready var _slot_3: Panel = $VBox/CenterContainer/Grid/Slot3
@onready var _slot_4: Panel = $VBox/CenterContainer/Grid/Slot4
@onready var _slot_5: Panel = $VBox/CenterContainer/Grid/Slot5
@onready var _slot_6: Panel = $VBox/CenterContainer/Grid/Slot6
@onready var _slot_7: Panel = $VBox/CenterContainer/Grid/Slot7

# ─── STATE ────────────────────────────────────────────────────────────────────
var _gm: Node             = null
var _slots: Array[Panel]  = []

# Styles created once in _init_styles(), reused across all slots
var _style_empty:    StyleBoxFlat = StyleBoxFlat.new()
var _style_occupied: StyleBoxFlat = StyleBoxFlat.new()

# ─── LIFECYCLE ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_slots = [_slot_0, _slot_1, _slot_2, _slot_3, _slot_4, _slot_5, _slot_6, _slot_7]
	_init_styles()

	# Style all slots as vacant before GameManager is ready
	for slot: Panel in _slots:
		slot.add_theme_stylebox_override("panel", _style_empty)

	await get_tree().process_frame

	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[OfficeView] GameManager autoload not found.")
		return

	_gm.employees.employee_hired.connect(_on_employee_hired)
	refresh_office()

	var clock: Node = get_node_or_null("/root/ClockManager")
	if clock != null:
		clock.work_day_started.connect(_on_work_day_started)

func _init_styles() -> void:
	_style_empty.bg_color            = Color(0.07, 0.07, 0.15, 1.0)
	_style_empty.border_width_left   = 1
	_style_empty.border_width_top    = 1
	_style_empty.border_width_right  = 1
	_style_empty.border_width_bottom = 1
	_style_empty.border_color        = Color(0.18, 0.22, 0.38, 1.0)

	_style_occupied.bg_color            = Color(0.10, 0.11, 0.24, 1.0)
	_style_occupied.border_width_left   = 1
	_style_occupied.border_width_top    = 1
	_style_occupied.border_width_right  = 1
	_style_occupied.border_width_bottom = 1
	_style_occupied.border_color        = Color(0.30, 0.46, 0.72, 0.9)

# ─── REFRESH ──────────────────────────────────────────────────────────────────
func refresh_office() -> void:
	if _gm == null:
		return
	var hired: Array = _gm.employees.get_hired_employees()
	for i: int in range(8):
		if i < hired.size():
			_fill_slot(_slots[i], hired[i])
		else:
			_fill_vacant(_slots[i])

# ─── SLOT BUILDERS ────────────────────────────────────────────────────────────
func _fill_vacant(slot: Panel) -> void:
	_clear_slot(slot)
	slot.add_theme_stylebox_override("panel", _style_empty)

	var lbl: Label = Label.new()
	lbl.text = "VACANT"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.33, 0.36, 0.50, 1.0))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(lbl)

func _fill_slot(slot: Panel, emp: Object) -> void:
	_clear_slot(slot)
	slot.add_theme_stylebox_override("panel", _style_occupied)

	# VBox fills the entire slot Panel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)

	# Colored square avatar, centred horizontally
	var cc: CenterContainer = CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(cc)

	var avatar: ColorRect = ColorRect.new()
	avatar.color = _role_color(emp.role)
	avatar.custom_minimum_size = Vector2(24, 24)
	cc.add_child(avatar)

	# First name only (small font)
	var name_lbl: Label = Label.new()
	name_lbl.text = emp.first_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	vbox.add_child(name_lbl)

	# Role abbreviation (tinted with role color)
	var role_lbl: Label = Label.new()
	role_lbl.text = _role_str(emp.role)
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 8)
	role_lbl.add_theme_color_override("font_color", _role_color(emp.role))
	vbox.add_child(role_lbl)

func _clear_slot(slot: Panel) -> void:
	for child: Node in slot.get_children():
		child.free()

# ─── SIGNAL HANDLERS ──────────────────────────────────────────────────────────
func _on_employee_hired(_emp: Object) -> void:
	refresh_office()

func _on_work_day_started() -> void:
	if _gm == null:
		return
	# Mirror the idle logic from ProjectManager: employees not assigned to any
	# in_progress task are "at their desks" and earn 1 CP — show the popup.
	var busy_ids: Array = []
	for proj in _gm.projects.get_projects():
		for task in proj.get("tasks", []):
			if task.get("status", "") == "in_progress":
				for eid in task.get("assigned_employee_ids", []):
					if eid not in busy_ids:
						busy_ids.append(eid)
	var hired: Array = _gm.employees.get_hired_employees()
	for i: int in range(min(hired.size(), _slots.size())):
		var emp: Object = hired[i]
		if str(emp.id) not in busy_ids:
			_show_cp_popup(_slots[i])

# ─── FLOATING +1 CP POPUP ─────────────────────────────────────────────────────
func _show_cp_popup(slot: Panel) -> void:
	if slot.size.y == 0.0:
		return  # layout not ready yet (e.g. startup emission)
	var lbl: Label            = Label.new()
	lbl.text                  = "+1 CP"
	lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	lbl.size                  = Vector2(slot.size.x, 14.0)
	lbl.position              = Vector2(0.0, slot.size.y * 0.25)
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color.GREEN)
	slot.add_child(lbl)

	var end_y: float = lbl.position.y - 20.0
	var tw: Tween    = slot.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", end_y, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.finished.connect(func() -> void: lbl.queue_free())

# ─── DISPLAY HELPERS ──────────────────────────────────────────────────────────

# Employee.Role: OPERATIONS=0 PROCUREMENT=1 SECRETARY=2 MANAGEMENT=3 FINANCE=4
func _role_str(role: int) -> String:
	match role:
		0: return "OPS"
		1: return "PRO"
		2: return "SEC"
		3: return "MGT"
		4: return "FIN"
	return "???"

func _role_color(role: int) -> Color:
	match role:
		0: return Color(0.506, 0.780, 0.518, 1.0)  # green   — OPS
		1: return Color(1.000, 0.718, 0.302, 1.0)  # orange  — PRO
		2: return Color(0.310, 0.765, 0.969, 1.0)  # cyan    — SEC
		3: return Color(0.808, 0.576, 0.847, 1.0)  # purple  — MGT
		4: return Color(0.502, 0.796, 0.769, 1.0)  # teal    — FIN
	return Color.WHITE
