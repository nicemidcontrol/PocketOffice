extends Control

const REFRESH_COST: int = 500

# ─────────────────────────────────────────
#  HEADER / FOOTER
# ─────────────────────────────────────────
@onready var _cash_label:  Label          = $Header/HBox/CashLabel
@onready var _refresh_btn: Button         = $Footer/RefreshButton
@onready var _body_vbox:   VBoxContainer  = $Body/VBox

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
var _gm: Node          = null
var _em: GDScript      = null
var _candidates: Array = []
var _hero_cards: Array = []

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
	_add_hero_candidates()

func _add_hero_candidates() -> void:
	for card in _hero_cards:
		if is_instance_valid(card):
			card.queue_free()
	_hero_cards.clear()
	if _gm == null:
		return
	var heroes: Array = _gm.employees.get_available_heroes()
	for template in heroes:
		var hero_emp: Object = _gm.employees.create_hero_employee(template)
		var card: PanelContainer = _make_hero_card(hero_emp)
		_hero_cards.append(card)
		_body_vbox.add_child(card)

func _make_hero_card(hero_emp: Object) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.09, 0.05, 1.0)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(1.0, 0.78, 0.15, 1.0)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", card_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var name_lbl: Label = Label.new()
	name_lbl.text = hero_emp.full_name()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 14)
	top_row.add_child(name_lbl)

	var hero_tag: Label = Label.new()
	hero_tag.text = "HERO"
	hero_tag.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
	hero_tag.add_theme_font_size_override("font_size", 11)
	hero_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(hero_tag)

	var role_lbl: Label = Label.new()
	role_lbl.text = _role_str(hero_emp.role)
	role_lbl.modulate = _role_color(hero_emp.role)
	role_lbl.add_theme_font_size_override("font_size", 12)
	role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(role_lbl)

	var skill_lbl: Label = Label.new()
	skill_lbl.text = "SKL %d  MOT %d" % [hero_emp.skill, hero_emp.motivation]
	skill_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70, 1.0))
	skill_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(skill_lbl)

	var bot_row: HBoxContainer = HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bot_row)

	var salary_lbl: Label = Label.new()
	salary_lbl.text = "$%s / mo" % _fmt(hero_emp.monthly_salary)
	salary_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salary_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90, 1.0))
	salary_lbl.add_theme_font_size_override("font_size", 12)
	salary_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_row.add_child(salary_lbl)

	var hire_btn: Button = Button.new()
	hire_btn.text = "HIRE"
	hire_btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
	hire_btn.add_theme_font_size_override("font_size", 12)
	hire_btn.custom_minimum_size = Vector2(72, 34)
	bot_row.add_child(hire_btn)

	hire_btn.pressed.connect(func() -> void:
		if _gm == null:
			return
		_gm.employees.hire(hero_emp)
		_gm.broadcast("%s has joined the team!" % hero_emp.full_name())
		hire_btn.text = "HIRED"
		hire_btn.disabled = true
	)

	return panel

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
	_hire_btns[idx].text     = "HIRED"
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
