extends Control

@onready var _count_label: Label         = $Header/HBox/CountLabel
@onready var _card_list:   VBoxContainer = $Body/CardList

var _gm: Node = null

func _ready() -> void:
	_gm = get_node_or_null("/root/GameManager")
	_build_list()

# ─────────────────────────────────────────
#  LIST BUILDER
# ─────────────────────────────────────────
func _build_list() -> void:
	for child in _card_list.get_children():
		child.queue_free()
	if _gm == null:
		_count_label.text = "0 / 20"
		return
	var hired: Array = _gm.employees.get_hired_employees()
	_count_label.text = "%d / 20" % hired.size()
	if hired.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No employees yet. Recruit from HR > Recruit."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 1.0))
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_card_list.add_child(empty_label)
		return
	for emp in hired:
		_card_list.add_child(_make_card(emp))

# ─────────────────────────────────────────
#  CARD BUILDER
# ─────────────────────────────────────────
func _make_card(emp: Employee) -> PanelContainer:
	var is_hero: bool = _gm.employees.is_hero_employee(emp.id)
	var is_derek: bool = emp.id == "derek_anan"

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.078, 0.078, 0.172, 1.0)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	if is_hero:
		card_style.border_color = Color(1.0, 0.78, 0.15, 1.0)
	else:
		card_style.border_color = Color(0.18, 0.42, 0.78, 0.55)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", card_style)

	if is_derek:
		var tween: Tween = panel.create_tween()
		tween.set_loops()
		tween.tween_property(card_style, "border_color", Color(1.0, 0.30, 0.10, 1.0), 0.7)
		tween.tween_property(card_style, "border_color", Color(0.30, 0.80, 1.00, 1.0), 0.7)
		tween.tween_property(card_style, "border_color", Color(0.65, 0.20, 1.00, 1.0), 0.7)
		tween.tween_property(card_style, "border_color", Color(1.00, 0.78, 0.15, 1.0), 0.7)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# ── Name row ──
	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	vbox.add_child(name_row)

	var name_label: Label = Label.new()
	name_label.text = emp.full_name()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(name_label)

	if is_hero:
		var hero_badge: Label = Label.new()
		hero_badge.text = "HERO"
		hero_badge.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15, 1.0))
		hero_badge.add_theme_font_size_override("font_size", 10)
		hero_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_row.add_child(hero_badge)

	var role_badge: Label = Label.new()
	role_badge.text = _role_str(emp.role)
	role_badge.add_theme_color_override("font_color", _role_color(emp.role))
	role_badge.add_theme_font_size_override("font_size", 12)
	role_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(role_badge)

	# ── Personality ──
	var pers_label: Label = Label.new()
	pers_label.text = _get_personality_str(emp)
	pers_label.add_theme_color_override("font_color", Color(0.58, 0.58, 0.68, 1.0))
	pers_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(pers_label)

	# ── Stats row ──
	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_row)

	var skl_label: Label = Label.new()
	skl_label.text = "SKL"
	skl_label.add_theme_color_override("font_color", Color(0.52, 0.52, 0.62, 1.0))
	skl_label.add_theme_font_size_override("font_size", 10)
	skl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_row.add_child(skl_label)

	stats_row.add_child(_make_stat_bar(float(emp.skill), Color(0.22, 0.9, 0.42, 1.0)))

	var mot_label: Label = Label.new()
	mot_label.text = "MOT"
	mot_label.add_theme_color_override("font_color", Color(0.52, 0.52, 0.62, 1.0))
	mot_label.add_theme_font_size_override("font_size", 10)
	mot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_row.add_child(mot_label)

	stats_row.add_child(_make_stat_bar(float(emp.motivation), Color(1.0, 0.75, 0.1, 1.0)))

	# ── Salary ──
	var salary_label: Label = Label.new()
	salary_label.text = "$%d / mo" % emp.monthly_salary
	salary_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
	salary_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(salary_label)

	return panel

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _make_stat_bar(value: float, fill_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.value = value
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.18, 1.0)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("background", bg_style)

	return bar

func _get_personality_str(emp: Employee) -> String:
	if _gm != null:
		var template: Dictionary = _gm.employees.get_hero_template(emp.id)
		if not template.is_empty() and template.has("personality_label"):
			return template["personality_label"]
	return _pers_str(emp.personality)

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
		0: return Color(0.40, 0.80, 1.00, 1.0)
		1: return Color(1.00, 0.60, 0.90, 1.0)
		2: return Color(1.00, 0.85, 0.30, 1.0)
		3: return Color(0.50, 1.00, 0.60, 1.0)
		4: return Color(0.80, 0.70, 1.00, 1.0)
		5: return Color(1.00, 0.50, 0.30, 1.0)
		6: return Color(0.65, 0.65, 0.65, 1.0)
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

# ─────────────────────────────────────────
#  INPUT HANDLER
# ─────────────────────────────────────────
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
