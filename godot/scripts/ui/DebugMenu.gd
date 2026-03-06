extends CanvasLayer

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _root:              Control = $Root
@onready var _cash_btn:          Button  = $Root/Panel/Margin/VBox/CashBtn
@onready var _cp_btn:            Button  = $Root/Panel/Margin/VBox/CpBtn
@onready var _rep_btn:           Button  = $Root/Panel/Margin/VBox/RepBtn
@onready var _skip_month_btn:    Button  = $Root/Panel/Margin/VBox/SkipMonthBtn
@onready var _skip_year_btn:     Button  = $Root/Panel/Margin/VBox/SkipYearBtn
@onready var _burnout_btn:       Button  = $Root/Panel/Margin/VBox/BurnoutBtn
@onready var _reset_tutorial_btn: Button = $Root/Panel/Margin/VBox/ResetTutorialBtn
@onready var _close_btn:         Button  = $Root/Panel/Margin/VBox/CloseBtn
@onready var _feedback_lbl:      Label   = $Root/Panel/Margin/VBox/FeedbackLabel

# ------------------------------------------
#  STATE
# ------------------------------------------
var _gm: Node = null

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	layer = 20
	_root.visible = false
	_gm = get_node_or_null("/root/GameManager")
	set_process_input(true)
	_cash_btn.pressed.connect(_on_cash_btn_pressed)
	_cp_btn.pressed.connect(_on_cp_btn_pressed)
	_rep_btn.pressed.connect(_on_rep_btn_pressed)
	_skip_month_btn.pressed.connect(_on_skip_month_btn_pressed)
	_skip_year_btn.pressed.connect(_on_skip_year_btn_pressed)
	_burnout_btn.pressed.connect(_on_burnout_btn_pressed)
	_reset_tutorial_btn.pressed.connect(_on_reset_tutorial_btn_pressed)
	_close_btn.pressed.connect(_on_close_btn_pressed)

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var kb: InputEventKey = event as InputEventKey
	if kb == null or not kb.pressed:
		return
	if kb.keycode == KEY_D and kb.ctrl_pressed and kb.shift_pressed:
		_root.visible = not _root.visible

# ------------------------------------------
#  BUTTON HANDLERS
# ------------------------------------------
func _on_cash_btn_pressed() -> void:
	if _gm == null:
		return
	_gm.economy.add_revenue(10000, "Debug injection")
	_show_feedback("+$10,000 injected")

func _on_cp_btn_pressed() -> void:
	if _gm == null:
		return
	_gm.corp_points += 100
	_gm.corp_points_changed.emit(_gm.corp_points)
	_show_feedback("+100 CP injected")

func _on_rep_btn_pressed() -> void:
	if _gm == null:
		return
	_gm.company_data["reputation"] += 20
	_show_feedback("+20 Reputation injected")

func _on_skip_month_btn_pressed() -> void:
	if _gm == null:
		return
	_gm._advance_month()
	_show_feedback("Skipped 1 month")

func _on_skip_year_btn_pressed() -> void:
	if _gm == null:
		return
	for _i: int in range(12):
		_gm._advance_month()
	_show_feedback("Skipped 1 full year")

func _on_burnout_btn_pressed() -> void:
	if _gm == null:
		return
	var hired: Array = _gm.employees.get_hired_employees()
	if hired.is_empty():
		_show_feedback("No employees to burn out")
		return
	hired[0].is_burned_out = true
	_show_feedback(hired[0].first_name + " burned out!")

func _on_reset_tutorial_btn_pressed() -> void:
	var path: String = "user://pocketoffice_prefs.json"
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string("{\"tutorial_seen\": false}")
		f.close()
	_show_feedback("Tutorial reset - restart game")

func _on_close_btn_pressed() -> void:
	_root.visible = false

# ------------------------------------------
#  FEEDBACK
# ------------------------------------------
func _show_feedback(msg: String) -> void:
	_feedback_lbl.text = msg
