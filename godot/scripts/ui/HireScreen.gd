extends Control

const REFRESH_COST: int = 500

# ─────────────────────────────────────────
#  HEADER / FOOTER
# ─────────────────────────────────────────
@onready var _cash_label: Label   = $Header/HBox/CashLabel
@onready var _refresh_btn: Button = $Footer/RefreshButton

# ─────────────────────────────────────────
#  CARD 0
# ─────────────────────────────────────────
@onready var _name_0: Label        = $Body/VBox/Card0/Margin/VBox/HBoxTop0/NameLabel0
@onready var _role_0: Label        = $Body/VBox/Card0/Margin/VBox/HBoxTop0/RoleLabel0
@onready var _pers_0: Label        = $Body/VBox/Card0/Margin/VBox/PersLabel0
@onready var _skill_0: ProgressBar = $Body/VBox/Card0/Margin/VBox/HBoxSkl0/SkillBar0
@onready var _moral_0: ProgressBar = $Body/VBox/Card0/Margin/VBox/HBoxMot0/MoralBar0
@onready var _salary_0: Label      = $Body/VBox/Card0/Margin/VBox/HBoxBot0/SalaryLabel0
@onready var _hire_0: Button       = $Body/VBox/Card0/Margin/VBox/HBoxBot0/HireButton0

# ─────────────────────────────────────────
#  CARD 1
# ─────────────────────────────────────────
@onready var _name_1: Label        = $Body/VBox/Card1/Margin/VBox/HBoxTop1/NameLabel1
@onready var _role_1: Label        = $Body/VBox/Card1/Margin/VBox/HBoxTop1/RoleLabel1
@onready var _pers_1: Label        = $Body/VBox/Card1/Margin/VBox/PersLabel1
@onready var _skill_1: ProgressBar = $Body/VBox/Card1/Margin/VBox/HBoxSkl1/SkillBar1
@onready var _moral_1: ProgressBar = $Body/VBox/Card1/Margin/VBox/HBoxMot1/MoralBar1
@onready var _salary_1: Label      = $Body/VBox/Card1/Margin/VBox/HBoxBot1/SalaryLabel1
@onready var _hire_1: Button       = $Body/VBox/Card1/Margin/VBox/HBoxBot1/HireButton1

# ─────────────────────────────────────────
#  CARD 2
# ─────────────────────────────────────────
@onready var _name_2: Label        = $Body/VBox/Card2/Margin/VBox/HBoxTop2/NameLabel2
@onready var _role_2: Label        = $Body/VBox/Card2/Margin/VBox/HBoxTop2/RoleLabel2
@onready var _pers_2: Label        = $Body/VBox/Card2/Margin/VBox/PersLabel2
@onready var _skill_2: ProgressBar = $Body/VBox/Card2/Margin/VBox/HBoxSkl2/SkillBar2
@onready var _moral_2: ProgressBar = $Body/VBox/Card2/Margin/VBox/HBoxMot2/MoralBar2
@onready var _salary_2: Label      = $Body/VBox/Card2/Margin/VBox/HBoxBot2/SalaryLabel2
@onready var _hire_2: Button       = $Body/VBox/Card2/Margin/VBox/HBoxBot2/HireButton2

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node       = null
var _em: GDScript   = null
var _candidates: Array = []

# Indexed arrays built from @onready refs — used by populate_candidates()
var _name_labels:   Array[Label]       = []
var _role_labels:   Array[Label]       = []
var _pers_labels:   Array[Label]       = []
var _skill_bars:    Array[ProgressBar] = []
var _moral_bars:    Array[ProgressBar] = []
var _salary_labels: Array[Label]       = []
var _hire_btns:     Array[Button]      = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_em = load("res://EmployeeManager.gd") as GDScript

	# Build typed indexed arrays from @onready refs
	_name_labels   = [_name_0,   _name_1,   _name_2]
	_role_labels   = [_role_0,   _role_1,   _role_2]
	_pers_labels   = [_pers_0,   _pers_1,   _pers_2]
	_skill_bars    = [_skill_0,  _skill_1,  _skill_2]
	_moral_bars    = [_moral_0,  _moral_1,  _moral_2]
	_salary_labels = [_salary_0, _salary_1, _salary_2]
	_hire_btns     = [_hire_0,   _hire_1,   _hire_2]

	# Wire hire button signals with index
	for i: int in range(3):
		var idx: int = i
		_hire_btns[i].pressed.connect(_on_hire_pressed.bind(idx))

	# GameManager is an Autoload — wait one frame to ensure it is ready.
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[HireScreen] GameManager autoload not found.")
		return

	_gm.economy.cash_changed.connect(_on_cash_changed)
	_on_cash_changed(_gm.economy.current_cash)
	populate_candidates()

# ─────────────────────────────────────────
#  CANDIDATE POPULATION
# ─────────────────────────────────────────
func populate_candidates() -> void:
	_candidates.clear()
	for i: int in range(3):
		_candidates.append(_em.generate_random_candidate())
	for i: int in range(3):
		_fill_card(i, _candidates[i])

func _fill_card(idx: int, emp: Object) -> void:
	_name_labels[idx].text     = emp.full_name()
	_role_labels[idx].text     = _role_str(emp.role)
	_role_labels[idx].modulate = _role_color(emp.role)
	_pers_labels[idx].text     = _pers_str(emp.personality)
	_skill_bars[idx].value     = float(emp.skill)
	_moral_bars[idx].value     = float(emp.motivation)
	_salary_labels[idx].text   = "$%s / mo" % _fmt(emp.monthly_salary)
	_hire_btns[idx].text       = "HIRE"
	_hire_btns[idx].disabled   = false
	_hire_btns[idx].modulate   = Color.WHITE

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(amount: int) -> void:
	_cash_label.text      = "$" + _fmt(amount)
	_refresh_btn.disabled = amount < REFRESH_COST

func _on_hire_pressed(idx: int) -> void:
	if _gm == null or idx >= _candidates.size():
		return
	var emp: Object = _candidates[idx]
	_gm.employees.hire(emp)
	_gm.broadcast("%s joined the team!" % emp.full_name())
	_hire_btns[idx].text     = "✓ HIRED"
	_hire_btns[idx].disabled = true
	_hire_btns[idx].modulate = Color(0.4, 0.4, 0.4, 1.0)

func _on_refresh_pressed() -> void:
	if _gm == null:
		return
	if not _gm.economy.spend(REFRESH_COST, "Recruitment Agency Fee"):
		_gm.broadcast("Not enough cash to refresh. (Need $%d)" % REFRESH_COST)
		return
	populate_candidates()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ─────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────

# Employee.Role: DEVELOPER=0 DESIGNER=1 MARKETER=2 HR_SPECIALIST=3
#                ACCOUNTANT=4 MANAGER=5 INTERN=6
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
		0: return Color(0.40, 0.80, 1.00, 1.0)  # blue   — Developer
		1: return Color(1.00, 0.60, 0.90, 1.0)  # pink   — Designer
		2: return Color(1.00, 0.85, 0.30, 1.0)  # gold   — Marketer
		3: return Color(0.50, 1.00, 0.60, 1.0)  # green  — HR
		4: return Color(0.80, 0.70, 1.00, 1.0)  # purple — Accountant
		5: return Color(1.00, 0.50, 0.30, 1.0)  # orange — Manager
		6: return Color(0.65, 0.65, 0.65, 1.0)  # gray   — Intern
	return Color.WHITE

# Employee.Personality: NORMAL=0 WORKAHOLIC=1 LAZY=2 GOSSIP=3
#                       PERFECTIONIST=4 TEAM_PLAYER=5 LONE_STAR=6
func _pers_str(p: int) -> String:
	match p:
		0: return "Normal"
		1: return "Workaholic"
		2: return "Lazy"
		3: return "Gossip"
		4: return "Perfectionist"
		5: return "Team Player"
		6: return "Lone Star"
	return "Unknown"

func _fmt(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
