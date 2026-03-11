extends CanvasLayer

signal screen_closed

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _back_btn:      Button        = $Card/Header/HBox/BackBtn
@onready var _cp_lbl:        Label         = $Card/Header/HBox/CpLabel
@onready var _champ_lbl:     Label         = $Card/ChampPanel/ChampMargin/ChampVBox/ChampText
@onready var _items_vbox:    VBoxContainer = $Card/Body/BodyMargin/BodyVBox/ItemsVBox
@onready var _emp_vbox:      VBoxContainer = $Card/Body/BodyMargin/BodyVBox/EmpVBox
@onready var _feedback_lbl:  Label         = $Card/FeedbackLabel

# ------------------------------------------
#  STATE
# ------------------------------------------
var _gm: Node             = null
var _selected_emp_id: String = ""
var _selected_item: Dictionary = {}

# ------------------------------------------
#  CONSTANTS
# ------------------------------------------
const _CHAMP_GREETINGS: Array = [
	"Welcome to CHAMP's Corner Store!\nYour employees deserve the best.",
	"CHAMP's back! And I brought gifts.\nYour team will thank you.",
	"The only shop in the galaxy with\nCHAMP-certified quality. You're welcome.",
	"Spend wisely. Or spend wildly.\nCHAMP doesn't judge."
]

const _SHOP_ITEMS: Array = [
	{
		"id": "chocolate",
		"name": "Chocolate",
		"cp_cost": 50,
		"stat": "motivation",
		"amount": 15,
		"description": "A quick sugar boost. Raises Motivation."
	},
	{
		"id": "ergo_chair",
		"name": "Ergonomic Chair",
		"cp_cost": 100,
		"stat": "skill",
		"amount": 10,
		"description": "Proper support. Raises Skill."
	},
	{
		"id": "company_manual",
		"name": "Company Manual",
		"cp_cost": 150,
		"stat": "skill_and_creativity",
		"amount": 10,
		"description": "Dense reading, real results. Raises Skill and Creativity."
	}
]

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_champ_lbl.text = _CHAMP_GREETINGS[rng.randi_range(0, _CHAMP_GREETINGS.size() - 1)]
	_feedback_lbl.text = ""
	_back_btn.pressed.connect(_on_back_pressed)
	_refresh_cp()
	_build_items()
	_build_employees()

# ------------------------------------------
#  DISPLAY HELPERS
# ------------------------------------------
func _refresh_cp() -> void:
	if _gm == null:
		_cp_lbl.text = "CP: 0"
		return
	_cp_lbl.text = "CP: %d" % _gm.corp_points

func _build_items() -> void:
	for child in _items_vbox.get_children():
		child.queue_free()
	for item in _SHOP_ITEMS:
		_items_vbox.add_child(_make_item_row(item))

func _make_item_row(item: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)

	var name_lbl: Label = Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	info_vbox.add_child(name_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = item["description"]
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.56, 0.67))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_lbl)

	row.add_child(info_vbox)

	var buy_btn: Button = Button.new()
	buy_btn.text = "%d CP" % item["cp_cost"]
	buy_btn.custom_minimum_size = Vector2(80, 40)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1))
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.10, 0.06)
	s.border_width_left   = 1
	s.border_width_top    = 1
	s.border_width_right  = 1
	s.border_width_bottom = 1
	s.border_color = Color(1.0, 0.82, 0.1, 0.7)
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left  = 4
	buy_btn.add_theme_stylebox_override("normal",  s)
	buy_btn.add_theme_stylebox_override("hover",   s)
	buy_btn.add_theme_stylebox_override("pressed", s)
	buy_btn.pressed.connect(func() -> void: _on_item_selected(item))
	row.add_child(buy_btn)

	return row

func _build_employees() -> void:
	for child in _emp_vbox.get_children():
		child.queue_free()
	if _gm == null:
		return
	var hired: Array = _gm.employees.get_hired_employees()
	if hired.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No employees hired yet."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.51, 0.62))
		lbl.add_theme_font_size_override("font_size", 12)
		_emp_vbox.add_child(lbl)
		return
	for emp in hired:
		_emp_vbox.add_child(_make_emp_card(emp))

func _make_emp_card(emp: Object) -> Control:
	var btn: Button = Button.new()
	btn.text = "%s  |  MOT:%d  SKL:%d  CRE:%d" % [
		emp.first_name + " " + emp.last_name,
		emp.motivation, emp.skill, emp.creativity
	]
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 12)
	var is_selected: bool = (_selected_emp_id == emp.id)
	var bg_col: Color = Color(0.08, 0.22, 0.12) if is_selected else Color(0.06, 0.06, 0.14)
	var border_col: Color = Color(0.22, 0.9, 0.42, 0.9) if is_selected else Color(0.22, 0.42, 0.78, 0.4)
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg_col
	s.border_width_left   = 2 if is_selected else 1
	s.border_width_top    = 2 if is_selected else 1
	s.border_width_right  = 2 if is_selected else 1
	s.border_width_bottom = 2 if is_selected else 1
	s.border_color = border_col
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left  = 4
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color",
		Color(0.22, 0.9, 0.42) if is_selected else Color(0.75, 0.76, 0.87))
	var eid: String = emp.id
	btn.pressed.connect(func() -> void: _on_emp_selected(eid))
	return btn

# ------------------------------------------
#  INTERACTION
# ------------------------------------------
func _on_emp_selected(emp_id: String) -> void:
	_selected_emp_id = emp_id
	_feedback_lbl.text = ""
	_build_employees()

func _on_item_selected(item: Dictionary) -> void:
	if _selected_emp_id == "":
		_feedback_lbl.text = "Select an employee first."
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		return
	if _gm == null:
		return
	var cost: int = item["cp_cost"]
	if _gm.corp_points < cost:
		_feedback_lbl.text = "Not enough CP! Need %d, have %d." % [cost, _gm.corp_points]
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	var emp: Object = _gm.employees.get_employee_by_id(_selected_emp_id)
	if emp == null:
		_feedback_lbl.text = "Employee not found."
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	var amount: int = item["amount"]
	match item["stat"]:
		"motivation":
			emp.motivation = mini(emp.motivation + amount, 100)
		"skill":
			emp.skill = mini(emp.skill + amount, 100)
		"skill_and_creativity":
			emp.skill       = mini(emp.skill + amount, 100)
			emp.creativity  = mini(emp.creativity + amount, 100)
	_gm.corp_points -= cost
	_gm.corp_points_changed.emit(_gm.corp_points)
	_refresh_cp()
	_build_employees()
	_feedback_lbl.text = "%s used on %s!" % [item["name"], emp.first_name]
	_feedback_lbl.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42))

func _on_back_pressed() -> void:
	screen_closed.emit()
	queue_free()
