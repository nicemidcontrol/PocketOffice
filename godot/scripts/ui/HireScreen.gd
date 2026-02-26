extends Control

# ─────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────
const REFRESH_COST := 500
const CARD_COUNT   := 3

# ─────────────────────────────────────────
#  NODE REFS  (static)
# ─────────────────────────────────────────
@onready var _cash_label:  Label  = $Header/Margin/HBox/CashLabel
@onready var _refresh_btn: Button = $BottomBar/Margin/RefreshBtn

# Per-card refs — collected at runtime to avoid 21 individual @onready lines
var _name_labels:   Array[Label]       = []
var _role_chips:    Array[Label]       = []
var _pers_labels:   Array[Label]       = []
var _skill_bars:    Array[ProgressBar] = []
var _mot_bars:      Array[ProgressBar] = []
var _salary_labels: Array[Label]       = []
var _hire_btns:     Array[Button]      = []

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node      = null
var _em_script             # loaded via load() — no class_name reference
var _candidates: Array = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_em_script = load("res://EmployeeManager.gd")
	_collect_card_refs()

	# GameManager is an Autoload — wait one frame to ensure it is ready.
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[HireScreen] GameManager autoload not found.")
		return

	_gm.economy.cash_changed.connect(_on_cash_changed)
	_on_cash_changed(_gm.economy.current_cash)
	_generate_candidates()

# Populate per-card ref arrays and wire Hire button signals.
func _collect_card_refs() -> void:
	for i in CARD_COUNT:
		var base: String = "Body/Margin/Cards/Card%d/Margin/VBox" % i
		_name_labels.append(get_node(base + "/TopRow/NameLabel"))
		_role_chips.append(get_node(base + "/TopRow/RoleChip"))
		_pers_labels.append(get_node(base + "/PersLabel"))
		_skill_bars.append(get_node(base + "/SkillRow/SkillBar"))
		_mot_bars.append(get_node(base + "/MotRow/MotBar"))
		_salary_labels.append(get_node(base + "/BottomRow/SalaryLabel"))
		_hire_btns.append(get_node(base + "/BottomRow/HireBtn"))

		var idx := i  # capture for closure
		_hire_btns[i].pressed.connect(_on_hire_pressed.bind(idx))

# ─────────────────────────────────────────
#  CANDIDATE GENERATION
# ─────────────────────────────────────────
func _generate_candidates() -> void:
	_candidates.clear()
	for i in CARD_COUNT:
		var emp = _em_script.generate_random_candidate()
		_candidates.append(emp)
		_populate_card(i, emp)

func _populate_card(i: int, emp) -> void:
	_name_labels[i].text    = emp.full_name()
	_role_chips[i].text     = _role_str(emp.role)
	_role_chips[i].modulate = _role_color(emp.role)
	_pers_labels[i].text    = _personality_str(emp.personality)
	_skill_bars[i].value    = emp.skill
	_mot_bars[i].value      = emp.motivation
	_salary_labels[i].text  = "$%s / mo" % _fmt(emp.monthly_salary)
	_hire_btns[i].text      = "HIRE"
	_hire_btns[i].disabled  = false
	_hire_btns[i].modulate  = Color.WHITE

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(amount: int) -> void:
	_cash_label.text      = "$" + _fmt(amount)
	_refresh_btn.disabled = amount < REFRESH_COST

func _on_hire_pressed(idx: int) -> void:
	if _gm == null or idx >= _candidates.size():
		return
	var emp = _candidates[idx]
	_gm.employees.hire(emp)
	_gm.broadcast("%s joined the team!" % emp.full_name())
	_hire_btns[idx].text     = "✓ HIRED"
	_hire_btns[idx].disabled = true
	_hire_btns[idx].modulate = Color(0.42, 0.42, 0.42, 1.0)

func _on_refresh_pressed() -> void:
	if _gm == null:
		return
	if not _gm.economy.spend(REFRESH_COST, "Recruitment Agency Fee"):
		_gm.broadcast("Not enough cash to refresh candidates. (Need $%d)" % REFRESH_COST)
		return
	_generate_candidates()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ─────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────

# Must match Employee.Role enum order: DEVELOPER=0 DESIGNER=1 MARKETER=2
# HR_SPECIALIST=3 ACCOUNTANT=4 MANAGER=5 INTERN=6
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

# Must match Employee.Personality enum order: NORMAL=0 WORKAHOLIC=1 LAZY=2
# GOSSIP=3 PERFECTIONIST=4 TEAM_PLAYER=5 LONE_STAR=6
func _personality_str(p: int) -> String:
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
