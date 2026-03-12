extends CanvasLayer

signal screen_closed

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _champ_text:    Label = $Card/VBox/ChampText
@onready var _item_name_lbl: Label = $Card/VBox/ItemArrowRow/ItemNameLabel
@onready var _item_desc_lbl: Label = $Card/VBox/ItemDescLabel
@onready var _item_cost_lbl: Label = $Card/VBox/ItemCostLabel
@onready var _item_stat_lbl: Label = $Card/VBox/ItemStatLabel
@onready var _emp_name_lbl:  Label = $Card/VBox/EmpArrowRow/EmpNameLabel
@onready var _emp_stats_lbl: Label = $Card/VBox/EmpStatsLabel
@onready var _feedback_lbl:  Label = $Card/VBox/FeedbackLabel

# ------------------------------------------
#  STATE
# ------------------------------------------
var _gm:         Node  = null
var _item_index: int   = 0
var _emp_index:  int   = 0
var _hired:      Array = []

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
	$Dimmer.gui_input.connect(_on_dimmer_input)
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_champ_text.text = _CHAMP_GREETINGS[rng.randi_range(0, _CHAMP_GREETINGS.size() - 1)]
	_feedback_lbl.text = ""
	if _gm != null:
		_hired = _gm.employees.get_hired_employees()
	_refresh_item_display()
	_refresh_emp_display()

# ------------------------------------------
#  DISPLAY HELPERS
# ------------------------------------------
func _refresh_item_display() -> void:
	var item: Dictionary = _SHOP_ITEMS[_item_index]
	_item_name_lbl.text = item["name"]
	_item_desc_lbl.text = item["description"]
	_item_cost_lbl.text = "%d CP" % item["cp_cost"]
	match item["stat"]:
		"motivation":
			_item_stat_lbl.text = "MOT +%d" % item["amount"]
		"skill":
			_item_stat_lbl.text = "SKL +%d" % item["amount"]
		"skill_and_creativity":
			_item_stat_lbl.text = "SKL +%d  CRE +%d" % [item["amount"], item["amount"]]

func _refresh_emp_display() -> void:
	if _hired.is_empty():
		_emp_name_lbl.text = "No employees hired"
		_emp_stats_lbl.text = ""
		return
	var emp: Object = _hired[_emp_index]
	_emp_name_lbl.text = emp.first_name + " " + emp.last_name
	_emp_stats_lbl.text = "MOT:%d  SKL:%d  CRE:%d" % [emp.motivation, emp.skill, emp.creativity]

# ------------------------------------------
#  ARROW NAVIGATION
# ------------------------------------------
func _on_item_prev_pressed() -> void:
	_item_index = (_item_index - 1 + _SHOP_ITEMS.size()) % _SHOP_ITEMS.size()
	_refresh_item_display()

func _on_item_next_pressed() -> void:
	_item_index = (_item_index + 1) % _SHOP_ITEMS.size()
	_refresh_item_display()

func _on_emp_prev_pressed() -> void:
	if _hired.is_empty():
		return
	_emp_index = (_emp_index - 1 + _hired.size()) % _hired.size()
	_refresh_emp_display()

func _on_emp_next_pressed() -> void:
	if _hired.is_empty():
		return
	_emp_index = (_emp_index + 1) % _hired.size()
	_refresh_emp_display()

# ------------------------------------------
#  PURCHASE
# ------------------------------------------
func _on_buy_pressed() -> void:
	if _hired.is_empty():
		_feedback_lbl.text = "No employees to buy for."
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		return
	if _gm == null:
		return
	var item: Dictionary = _SHOP_ITEMS[_item_index]
	var cost: int = item["cp_cost"]
	if _gm.corp_points < cost:
		_feedback_lbl.text = "Not enough CP! Need %d, have %d." % [cost, _gm.corp_points]
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	var emp: Object = _hired[_emp_index]
	var amount: int = item["amount"]
	match item["stat"]:
		"motivation":
			emp.motivation = mini(emp.motivation + amount, 100)
		"skill":
			emp.skill = mini(emp.skill + amount, 100)
		"skill_and_creativity":
			emp.skill      = mini(emp.skill + amount, 100)
			emp.creativity = mini(emp.creativity + amount, 100)
	_gm.corp_points -= cost
	_gm.corp_points_changed.emit(_gm.corp_points)
	_hired = _gm.employees.get_hired_employees()
	_refresh_emp_display()
	_feedback_lbl.text = "%s used on %s!" % [item["name"], emp.first_name]
	_feedback_lbl.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42))

func _on_close_pressed() -> void:
	queue_free()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()
