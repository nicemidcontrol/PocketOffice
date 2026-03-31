extends "res://scripts/ui/BaseModal.gd"

# ------------------------------------------
#  NODE REFS (ShopScreen-specific)
# ------------------------------------------
@onready var _champ_text:    Label = $Dimmer/Card/VBox/ChampText
@onready var _item_desc_lbl: Label = $Dimmer/Card/VBox/ItemDescLabel
@onready var _item_cost_lbl: Label = $Dimmer/Card/VBox/ItemCostLabel
@onready var _item_stat_lbl: Label = $Dimmer/Card/VBox/ItemStatLabel
@onready var _emp_name_lbl:  Label = $Dimmer/Card/VBox/EmpArrowRow/EmpNameLabel
@onready var _emp_stats_lbl: Label = $Dimmer/Card/VBox/EmpStatsLabel
@onready var _feedback_lbl:  Label = $Dimmer/Card/VBox/FeedbackLabel
@onready var _emp_prev_btn:  Button = $Dimmer/Card/VBox/EmpArrowRow/EmpPrevBtn
@onready var _emp_next_btn:  Button = $Dimmer/Card/VBox/EmpArrowRow/EmpNextBtn

# ------------------------------------------
#  STATE
# ------------------------------------------
var _gm:        Node  = null
var _emp_index: int   = 0
var _hired:     Array = []

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
		"stat": "morale",
		"amount": 15,
		"description": "A quick sugar boost. Raises Morale."
	},
	{
		"id": "ergo_chair",
		"name": "Ergonomic Chair",
		"cp_cost": 100,
		"stat": "technical",
		"amount": 100,
		"description": "Proper support. Raises Technical."
	},
	{
		"id": "company_manual",
		"name": "Company Manual",
		"cp_cost": 150,
		"stat": "technical_and_focus",
		"amount": 80,
		"description": "Dense reading, real results. Raises Technical and Focus."
	}
]

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	super._ready()
	set_title("SHOP")
	_total_items = _SHOP_ITEMS.size()
	_emp_prev_btn.pressed.connect(_on_emp_prev_pressed)
	_emp_next_btn.pressed.connect(_on_emp_next_pressed)
	_action_btn.pressed.connect(_on_buy_pressed)
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
func _refresh_display() -> void:
	_refresh_item_display()

func _refresh_item_display() -> void:
	var item: Dictionary = _SHOP_ITEMS[_current_index]
	_item_name_label.text = item["name"]
	_item_desc_lbl.text = item["description"]
	_item_cost_lbl.text = "%d CP" % item["cp_cost"]
	match item["stat"]:
		"morale":
			_item_stat_lbl.text = "MRL +%d" % item["amount"]
		"technical":
			_item_stat_lbl.text = "TEC +%d" % item["amount"]
		"technical_and_focus":
			_item_stat_lbl.text = "TEC +%d  FOC +%d" % [item["amount"], item["amount"]]

func _refresh_emp_display() -> void:
	if _hired.is_empty():
		_emp_name_lbl.text = "No employees hired"
		_emp_stats_lbl.text = ""
		return
	var emp: Object = _hired[_emp_index]
	_emp_name_lbl.text = emp.first_name + " " + emp.last_name
	_emp_stats_lbl.text = "TEC:%d  FOC:%d  MGT:%d  MRL:%d" % [emp.technical, emp.focus, emp.management, emp.morale]

# ------------------------------------------
#  ARROW NAVIGATION (employee row only)
# ------------------------------------------
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
	var item: Dictionary = _SHOP_ITEMS[_current_index]
	var cost: int = item["cp_cost"]
	if _gm.corp_points < cost:
		_feedback_lbl.text = "Not enough CP! Need %d, have %d." % [cost, _gm.corp_points]
		_feedback_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	var emp: Object = _hired[_emp_index]
	var amount: int = item["amount"]
	match item["stat"]:
		"morale":
			emp.morale = mini(emp.morale + amount, 100)
		"technical":
			emp.technical = mini(emp.technical + amount, 1000)
		"technical_and_focus":
			emp.technical = mini(emp.technical + amount, 1000)
			emp.focus     = mini(emp.focus + amount, 1000)
	_gm.corp_points -= cost
	_gm.corp_points_changed.emit(_gm.corp_points)
	_hired = _gm.employees.get_hired_employees()
	_refresh_emp_display()
	_feedback_lbl.text = "%s used on %s!" % [item["name"], emp.first_name]
	_feedback_lbl.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42))
