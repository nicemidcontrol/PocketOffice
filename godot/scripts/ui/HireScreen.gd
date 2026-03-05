extends Control

# ─────────────────────────────────────────
#  NODES
# ─────────────────────────────────────────
@onready var _cash_label:     Label         = $Header/HBox/CashLabel
@onready var _title_label:    Label         = $Header/HBox/TitleLabel
@onready var _ad_layer:       Control       = $AdSelectLayer
@onready var _ad_vbox:        VBoxContainer = $AdSelectLayer/Scroll/VBox
@onready var _champ_layer:    Control       = $ChampDialogLayer
@onready var _champ_dialogue: Label         = $ChampDialogLayer/ChampPanel/Margin/VBox/ChampDialogue
@onready var _champ_dots:     Label         = $ChampDialogLayer/ChampPanel/Margin/VBox/ChampDots
@onready var _champ_continue: Button        = $ChampDialogLayer/ChampPanel/Margin/VBox/ContinueBtn
@onready var _champ_timer:    Timer         = $ChampDialogLayer/ChampTimer
@onready var _cand_layer:     Control       = $CandidateLayer
@onready var _cand_vbox:      VBoxContainer = $CandidateLayer/Scroll/VBox

# ─────────────────────────────────────────
#  AD CONFIG
# ─────────────────────────────────────────
const AD_DATA: Array = [
	{"name": "Milk Carton",    "cost": 300,  "tier": 0, "count": 2, "desc": "Desperate times..."},
	{"name": "Newspaper",      "cost": 600,  "tier": 1, "count": 3, "desc": "Old school but reliable."},
	{"name": "Radio",          "cost": 1000, "tier": 2, "count": 3, "desc": "Reaches more ears."},
	{"name": "Television",     "cost": 1800, "tier": 3, "count": 4, "desc": "Prime time exposure."},
	{"name": "Online Ad",      "cost": 2200, "tier": 4, "count": 4, "desc": "Targeted and effective."},
	{"name": "CHAMP's Agency", "cost": 3500, "tier": 5, "count": 3, "desc": "The best. Period."},
]

const TIER_NAMES: Array = ["E", "D", "C", "B", "A", "S"]

const TIER_SKILL_MIN: Array = [10, 25, 40, 55, 70, 85]
const TIER_SKILL_MAX: Array = [25, 40, 55, 70, 85, 100]
const TIER_MOT_MIN: Array   = [10, 25, 40, 55, 70, 85]
const TIER_MOT_MAX: Array   = [30, 45, 60, 75, 90, 100]

const CHAMP_LINES: Array = [
	"Hey hey hey! CHAMP here! Leave the recruiting to the BEST in the business. Stand by...",
	"You want the best? You came to the right place. CHAMP delivers. Always.",
	"CHAMP's Guarantee: If you're not satisfied... well, no refunds. But you WILL be satisfied.",
	"Top talent incoming. CHAMP has never failed a client. Today is no exception.",
]
const CHAMP_HERO_LINE: String = "Even I'm surprised by this one. Truly special. You're welcome."

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node     = null
var _em: GDScript = null

var current_screen: int    = 0   # 0=ad_select  1=champ_dialogue  2=candidates
var selected_tier: int     = 0
var current_candidates: Array = []
var _hero_templates: Array    = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_em = load("res://EmployeeManager.gd") as GDScript

	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[HireScreen] GameManager autoload not found.")
		return

	_gm.economy.cash_changed.connect(_on_cash_changed)
	_on_cash_changed(_gm.economy.current_cash)
	_show_ad_select()

# ─────────────────────────────────────────
#  SCREEN TRANSITIONS
# ─────────────────────────────────────────
func _show_ad_select() -> void:
	current_screen = 0
	_title_label.text = "RECRUIT"
	_ad_layer.visible    = true
	_champ_layer.visible = false
	_cand_layer.visible  = false
	_build_ad_cards()

func _show_champ_dialogue() -> void:
	current_screen = 1
	_ad_layer.visible    = false
	_champ_layer.visible = true
	_cand_layer.visible  = false

	_champ_continue.visible = false
	_champ_dots.visible     = true

	if not _hero_templates.is_empty():
		_champ_dialogue.text = CHAMP_HERO_LINE
	else:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		_champ_dialogue.text = CHAMP_LINES[rng.randi_range(0, CHAMP_LINES.size() - 1)]

	_champ_timer.start()

func _show_candidates() -> void:
	current_screen = 2
	_title_label.text = "TIER %s CANDIDATES" % TIER_NAMES[selected_tier]
	_ad_layer.visible    = false
	_champ_layer.visible = false
	_cand_layer.visible  = true
	_build_candidate_cards()

# ─────────────────────────────────────────
#  AD CARD BUILDER
# ─────────────────────────────────────────
func _build_ad_cards() -> void:
	for child in _ad_vbox.get_children():
		child.queue_free()

	var cash: int = 0
	if _gm != null:
		cash = _gm.economy.current_cash

	for i: int in range(AD_DATA.size()):
		var ad: Dictionary  = AD_DATA[i]
		var can_afford: bool = cash >= int(ad["cost"])
		var is_champ: bool   = int(ad["tier"]) == 5
		var card: PanelContainer = _make_ad_card(ad, can_afford, is_champ)
		_ad_vbox.add_child(card)

func _make_ad_card(ad: Dictionary, can_afford: bool, is_champ: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	if is_champ:
		card_style.bg_color         = Color(0.10, 0.09, 0.03, 1.0)
		card_style.border_width_left   = 2
		card_style.border_width_top    = 2
		card_style.border_width_right  = 2
		card_style.border_width_bottom = 2
		card_style.border_color     = Color(1.0, 0.78, 0.15, 1.0)
	else:
		card_style.bg_color         = Color(0.078, 0.078, 0.172, 1.0)
		card_style.border_width_left   = 1
		card_style.border_width_top    = 1
		card_style.border_width_right  = 1
		card_style.border_width_bottom = 1
		card_style.border_color     = Color(0.18, 0.42, 0.78, 0.55)
	card_style.corner_radius_top_left     = 6
	card_style.corner_radius_top_right    = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left  = 6
	panel.add_theme_stylebox_override("panel", card_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Top row: ad name + tier badge (+ S-tier guarantee badge)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)

	var name_lbl: Label = Label.new()
	name_lbl.text = ad["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 14)
	top_row.add_child(name_lbl)

	var tier_idx: int = int(ad["tier"])
	var tier_badge: Label = Label.new()
	tier_badge.text = "TIER %s" % TIER_NAMES[tier_idx]
	tier_badge.add_theme_color_override("font_color", _tier_color(tier_idx))
	tier_badge.add_theme_font_size_override("font_size", 11)
	tier_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(tier_badge)

	if is_champ:
		var guar_lbl: Label = Label.new()
		guar_lbl.text = "GUARANTEED S-TIER"
		guar_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
		guar_lbl.add_theme_font_size_override("font_size", 10)
		guar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		top_row.add_child(guar_lbl)

	# Mid row: cost + candidate count
	var mid_row: HBoxContainer = HBoxContainer.new()
	mid_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mid_row)

	var cost_lbl: Label = Label.new()
	cost_lbl.text = "$%d" % int(ad["cost"])
	cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20, 1.0))
	cost_lbl.add_theme_font_size_override("font_size", 13)
	mid_row.add_child(cost_lbl)

	var count_lbl: Label = Label.new()
	count_lbl.text = "%d candidates" % int(ad["count"])
	count_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80, 1.0))
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid_row.add_child(count_lbl)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = ad["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.50, 0.52, 0.62, 1.0))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)

	# SELECT / TOO POOR button
	var select_btn: Button = Button.new()
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.corner_radius_top_left     = 4
	btn_style.corner_radius_top_right    = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left  = 4
	btn_style.border_width_left   = 1
	btn_style.border_width_top    = 1
	btn_style.border_width_right  = 1
	btn_style.border_width_bottom = 1

	if can_afford:
		select_btn.text = "SELECT"
		select_btn.add_theme_color_override("font_color", Color(0.9, 0.98, 0.92, 1.0))
		btn_style.bg_color     = Color(0.08, 0.36, 0.17, 1.0)
		btn_style.border_color = Color(0.22, 0.9, 0.42, 0.7)
	else:
		select_btn.text     = "TOO POOR"
		select_btn.disabled = true
		select_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3, 1.0))
		btn_style.bg_color     = Color(0.15, 0.06, 0.06, 1.0)
		btn_style.border_color = Color(0.5, 0.2, 0.2, 0.7)

	select_btn.add_theme_stylebox_override("normal", btn_style)

	var tier_val: int  = int(ad["tier"])
	var cost_val: int  = int(ad["cost"])
	var count_val: int = int(ad["count"])
	select_btn.pressed.connect(func() -> void: _on_ad_selected(tier_val, cost_val, count_val))
	vbox.add_child(select_btn)

	return panel

# ─────────────────────────────────────────
#  CANDIDATE CARD BUILDER
# ─────────────────────────────────────────
func _build_candidate_cards() -> void:
	for child in _cand_vbox.get_children():
		child.queue_free()

	var tier_lbl: Label = Label.new()
	tier_lbl.text = "TIER %s CANDIDATES" % TIER_NAMES[selected_tier]
	tier_lbl.add_theme_color_override("font_color", _tier_color(selected_tier))
	tier_lbl.add_theme_font_size_override("font_size", 12)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cand_vbox.add_child(tier_lbl)

	for emp in current_candidates:
		var is_hero: bool = _is_hero_candidate(emp)
		var card: PanelContainer = _make_candidate_card(emp, is_hero)
		_cand_vbox.add_child(card)

func _is_hero_candidate(emp: Object) -> bool:
	for template in _hero_templates:
		if template["id"] == emp.id:
			return true
	return false

func _make_candidate_card(emp: Object, is_hero: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	if is_hero:
		card_style.bg_color         = Color(0.10, 0.09, 0.05, 1.0)
		card_style.border_width_left   = 2
		card_style.border_width_top    = 2
		card_style.border_width_right  = 2
		card_style.border_width_bottom = 2
		card_style.border_color     = Color(1.0, 0.78, 0.15, 1.0)
	else:
		card_style.bg_color         = Color(0.078, 0.078, 0.172, 1.0)
		card_style.border_width_left   = 1
		card_style.border_width_top    = 1
		card_style.border_width_right  = 1
		card_style.border_width_bottom = 1
		card_style.border_color     = Color(0.18, 0.42, 0.78, 0.55)
	card_style.corner_radius_top_left     = 6
	card_style.corner_radius_top_right    = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left  = 6
	panel.add_theme_stylebox_override("panel", card_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Top row: name + HERO tag (if hero) + role tag
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var name_lbl: Label = Label.new()
	name_lbl.text = emp.full_name()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 15)
	top_row.add_child(name_lbl)

	if is_hero:
		var hero_tag: Label = Label.new()
		hero_tag.text = "HERO"
		hero_tag.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
		hero_tag.add_theme_font_size_override("font_size", 11)
		hero_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		top_row.add_child(hero_tag)

	var role_lbl: Label = Label.new()
	role_lbl.text = _role_str(emp.role)
	role_lbl.modulate = _role_color(emp.role)
	role_lbl.add_theme_font_size_override("font_size", 11)
	role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(role_lbl)

	# Personality
	var pers_lbl: Label = Label.new()
	pers_lbl.text = _pers_str(emp.personality)
	pers_lbl.add_theme_color_override("font_color", Color(0.60, 0.62, 0.72, 1.0))
	pers_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(pers_lbl)

	# SKL bar
	var skl_row: HBoxContainer = HBoxContainer.new()
	skl_row.add_theme_constant_override("separation", 8)
	vbox.add_child(skl_row)

	var skl_key: Label = Label.new()
	skl_key.text = "SKL"
	skl_key.custom_minimum_size = Vector2(32, 0)
	skl_key.add_theme_color_override("font_color", Color(0.50, 0.51, 0.62, 1.0))
	skl_key.add_theme_font_size_override("font_size", 10)
	skl_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skl_row.add_child(skl_key)

	var skl_bar: ProgressBar = ProgressBar.new()
	skl_bar.custom_minimum_size = Vector2(0, 14)
	skl_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skl_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skl_bar.value = float(emp.skill)
	skl_bar.show_percentage = false
	var skl_bg: StyleBoxFlat = StyleBoxFlat.new()
	skl_bg.bg_color = Color(0.08, 0.08, 0.18, 1.0)
	skl_bg.corner_radius_top_left     = 3
	skl_bg.corner_radius_top_right    = 3
	skl_bg.corner_radius_bottom_right = 3
	skl_bg.corner_radius_bottom_left  = 3
	var skl_fill: StyleBoxFlat = StyleBoxFlat.new()
	skl_fill.bg_color = Color(0.22, 0.9, 0.42, 1.0)
	skl_fill.corner_radius_top_left     = 3
	skl_fill.corner_radius_top_right    = 3
	skl_fill.corner_radius_bottom_right = 3
	skl_fill.corner_radius_bottom_left  = 3
	skl_bar.add_theme_stylebox_override("background", skl_bg)
	skl_bar.add_theme_stylebox_override("fill", skl_fill)
	skl_row.add_child(skl_bar)

	# MOT bar
	var mot_row: HBoxContainer = HBoxContainer.new()
	mot_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mot_row)

	var mot_key: Label = Label.new()
	mot_key.text = "MOT"
	mot_key.custom_minimum_size = Vector2(32, 0)
	mot_key.add_theme_color_override("font_color", Color(0.50, 0.51, 0.62, 1.0))
	mot_key.add_theme_font_size_override("font_size", 10)
	mot_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mot_row.add_child(mot_key)

	var mot_bar: ProgressBar = ProgressBar.new()
	mot_bar.custom_minimum_size = Vector2(0, 14)
	mot_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mot_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mot_bar.value = float(emp.motivation)
	mot_bar.show_percentage = false
	var mot_bg: StyleBoxFlat = StyleBoxFlat.new()
	mot_bg.bg_color = Color(0.08, 0.08, 0.18, 1.0)
	mot_bg.corner_radius_top_left     = 3
	mot_bg.corner_radius_top_right    = 3
	mot_bg.corner_radius_bottom_right = 3
	mot_bg.corner_radius_bottom_left  = 3
	var mot_fill: StyleBoxFlat = StyleBoxFlat.new()
	mot_fill.bg_color = Color(1.0, 0.75, 0.1, 1.0)
	mot_fill.corner_radius_top_left     = 3
	mot_fill.corner_radius_top_right    = 3
	mot_fill.corner_radius_bottom_right = 3
	mot_fill.corner_radius_bottom_left  = 3
	mot_bar.add_theme_stylebox_override("background", mot_bg)
	mot_bar.add_theme_stylebox_override("fill", mot_fill)
	mot_row.add_child(mot_bar)

	# Bottom row: salary + HIRE button
	var bot_row: HBoxContainer = HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bot_row)

	var salary_lbl: Label = Label.new()
	salary_lbl.text = "$%s / mo" % _fmt(emp.monthly_salary)
	salary_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salary_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95, 1.0))
	salary_lbl.add_theme_font_size_override("font_size", 13)
	salary_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_row.add_child(salary_lbl)

	var hire_btn: Button = Button.new()
	hire_btn.text = "HIRE"
	hire_btn.custom_minimum_size = Vector2(80, 36)
	hire_btn.add_theme_font_size_override("font_size", 13)
	var hire_style: StyleBoxFlat = StyleBoxFlat.new()
	hire_style.bg_color         = Color(0.08, 0.36, 0.17, 1.0)
	hire_style.border_width_left   = 1
	hire_style.border_width_top    = 1
	hire_style.border_width_right  = 1
	hire_style.border_width_bottom = 1
	hire_style.border_color     = Color(0.22, 0.9, 0.42, 0.7)
	hire_style.corner_radius_top_left     = 4
	hire_style.corner_radius_top_right    = 4
	hire_style.corner_radius_bottom_right = 4
	hire_style.corner_radius_bottom_left  = 4
	hire_btn.add_theme_stylebox_override("normal", hire_style)
	if is_hero:
		hire_btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
	else:
		hire_btn.add_theme_color_override("font_color", Color(0.9, 0.98, 0.92, 1.0))
	bot_row.add_child(hire_btn)

	hire_btn.pressed.connect(func() -> void:
		if _gm == null:
			return
		_gm.employees.hire(emp)
		_gm.broadcast("%s joined the team!" % emp.full_name())
		hire_btn.text     = "HIRED"
		hire_btn.disabled = true
	)

	return panel

# ─────────────────────────────────────────
#  CANDIDATE GENERATION
# ─────────────────────────────────────────
func _generate_candidates(tier: int, count: int) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var result: Array = []
	for i: int in range(count):
		var emp: Object = _em.generate_random_candidate()
		emp.skill          = rng.randi_range(TIER_SKILL_MIN[tier], TIER_SKILL_MAX[tier])
		emp.motivation     = rng.randi_range(TIER_MOT_MIN[tier],   TIER_MOT_MAX[tier])
		emp.monthly_salary = (emp.skill + emp.motivation) / 2 * 30
		result.append(emp)
	return result

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(amount: int) -> void:
	_cash_label.text = "$" + _fmt(amount)

func _on_ad_selected(tier: int, cost: int, count: int) -> void:
	if _gm == null:
		return
	if not _gm.economy.spend(cost, "Recruitment Ad"):
		_gm.broadcast("Not enough cash for this advertisement.")
		return

	selected_tier     = tier
	_hero_templates.clear()
	current_candidates = _generate_candidates(tier, count)

	# S-tier: also pull in any available hero employees
	if tier == 5:
		var heroes: Array = _gm.employees.get_available_heroes()
		for template in heroes:
			_hero_templates.append(template)
			var hero_emp: Object = _gm.employees.create_hero_employee(template)
			current_candidates.append(hero_emp)

	if tier == 5:
		_show_champ_dialogue()
	else:
		_show_candidates()

func _on_champ_timer_timeout() -> void:
	_champ_dots.visible     = false
	_champ_continue.visible = true

func _on_champ_continue_pressed() -> void:
	_show_candidates()

func _on_back_pressed() -> void:
	match current_screen:
		0:
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		1:
			_show_ad_select()
		2:
			_show_ad_select()

# ─────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────
func _tier_color(tier: int) -> Color:
	match tier:
		0: return Color(0.60, 0.60, 0.60, 1.0)  # E - grey
		1: return Color(0.55, 0.80, 0.45, 1.0)  # D - green
		2: return Color(0.35, 0.70, 1.00, 1.0)  # C - blue
		3: return Color(0.70, 0.45, 1.00, 1.0)  # B - purple
		4: return Color(1.00, 0.55, 0.20, 1.0)  # A - orange
		5: return Color(1.00, 0.78, 0.15, 1.0)  # S - gold
	return Color.WHITE

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
		0: return Color(0.40, 0.80, 1.00, 1.0)  # blue   - Developer
		1: return Color(1.00, 0.60, 0.90, 1.0)  # pink   - Designer
		2: return Color(1.00, 0.85, 0.30, 1.0)  # gold   - Marketer
		3: return Color(0.50, 1.00, 0.60, 1.0)  # green  - HR
		4: return Color(0.80, 0.70, 1.00, 1.0)  # purple - Accountant
		5: return Color(1.00, 0.50, 0.30, 1.0)  # orange - Manager
		6: return Color(0.65, 0.65, 0.65, 1.0)  # gray   - Intern
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
