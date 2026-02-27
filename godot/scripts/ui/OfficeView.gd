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

# ─── DISPLAY HELPERS ──────────────────────────────────────────────────────────

# Employee.Role: DEVELOPER=0 DESIGNER=1 MARKETER=2 HR_SPECIALIST=3
#               ACCOUNTANT=4 MANAGER=5 INTERN=6
func _role_str(role: int) -> String:
	match role:
		0: return "DEV"
		1: return "DES"
		2: return "MKT"
		3: return "HR"
		4: return "ACC"
		5: return "MGR"
		6: return "INT"
	return "???"

func _role_color(role: int) -> Color:
	match role:
		0: return Color(0.506, 0.780, 0.518, 1.0)  # #81C784 — DEV  green
		1: return Color(0.310, 0.765, 0.969, 1.0)  # #4FC3F7 — DES  cyan
		2: return Color(1.000, 0.718, 0.302, 1.0)  # #FFB74D — MKT  orange
		3: return Color(0.400, 0.800, 1.000, 1.0)  # ~#66CCFF — HR  blue
		4: return Color(0.706, 0.588, 0.882, 1.0)  # ~#B496E1 — ACC lavender
		5: return Color(0.808, 0.576, 0.847, 1.0)  # #CE93D8 — MGR  purple
		6: return Color(0.957, 0.561, 0.694, 1.0)  # #F48FB1 — INT  pink
	return Color.WHITE
