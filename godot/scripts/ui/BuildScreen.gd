extends CanvasLayer

signal screen_closed

@onready var _cash_label:        Label           = $Card/Header/HBox/CashLabel
@onready var _tab_facilities:    Button          = $Card/TabBar/FacilitiesTab
@onready var _tab_combos:        Button          = $Card/TabBar/CombosTab
@onready var _facilities_scroll: ScrollContainer = $Card/FacilitiesScroll
@onready var _combos_scroll:     ScrollContainer = $Card/CombosScroll
@onready var _facilities_list:   VBoxContainer   = $Card/FacilitiesScroll/FacilitiesList
@onready var _combos_list:       VBoxContainer   = $Card/CombosScroll/CombosList

var _gm: Node = null
var _fm: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gm = get_node_or_null("/root/GameManager")
	_fm = get_node_or_null("/root/FacilityManager")
	if _fm != null:
		_fm.facilities_updated.connect(_refresh)
	_show_facilities_tab()
	_refresh()

# ─────────────────────────────────────────
#  TABS
# ─────────────────────────────────────────
func _show_facilities_tab() -> void:
	_facilities_scroll.visible = true
	_combos_scroll.visible = false
	_tab_facilities.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_tab_combos.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1.0))

func _show_combos_tab() -> void:
	_facilities_scroll.visible = false
	_combos_scroll.visible = true
	_tab_facilities.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1.0))
	_tab_combos.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

# ─────────────────────────────────────────
#  REFRESH
# ─────────────────────────────────────────
func _refresh() -> void:
	_update_cash()
	_build_facilities_list()
	_build_combos_list()

func _update_cash() -> void:
	if _gm == null:
		return
	_cash_label.text = "$%d" % _gm.economy.current_cash

# ─────────────────────────────────────────
#  FACILITY CARDS
# ─────────────────────────────────────────
func _build_facilities_list() -> void:
	for child in _facilities_list.get_children():
		child.queue_free()
	if _fm == null:
		return
	for f in _fm.facilities:
		_facilities_list.add_child(_make_facility_card(f))

func _make_facility_card(f: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.078, 0.078, 0.172, 1.0)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.18, 0.42, 0.78, 0.6)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", card_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	vbox.add_child(name_row)

	var name_label: Label = Label.new()
	name_label.text = f["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_label.add_theme_font_size_override("font_size", 14)
	name_row.add_child(name_label)

	var tile_label: Label = Label.new()
	tile_label.text = "%dx%d" % [int(f["tile_w"]), int(f["tile_h"])]
	tile_label.add_theme_color_override("font_color", Color(0.52, 0.52, 0.62, 1.0))
	tile_label.add_theme_font_size_override("font_size", 11)
	tile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(tile_label)

	var desc_label: Label = Label.new()
	desc_label.text = f["description"]
	desc_label.add_theme_color_override("font_color", Color(0.66, 0.66, 0.76, 1.0))
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	var stat_label: Label = Label.new()
	stat_label.text = _format_buff(f["stat_buff"])
	stat_label.add_theme_color_override("font_color", Color(0.22, 0.88, 0.48, 1.0))
	stat_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(stat_label)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bottom_row)

	var cost_label: Label = Label.new()
	cost_label.text = "$%d" % int(f["cost"])
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_row.add_child(cost_label)

	var placed: bool = bool(f["placed"])
	var cash: int = _gm.economy.current_cash if _gm != null else 0
	var can_afford: bool = cash >= int(f["cost"])

	var status_btn: Button = Button.new()
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.05, 0.05, 0.14, 1.0)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.22, 0.22, 0.35, 1.0)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left = 4
	status_btn.add_theme_stylebox_override("normal", btn_style)
	status_btn.add_theme_stylebox_override("hover", btn_style)
	status_btn.add_theme_stylebox_override("pressed", btn_style)
	status_btn.add_theme_stylebox_override("disabled", btn_style)
	status_btn.add_theme_font_size_override("font_size", 12)
	status_btn.custom_minimum_size = Vector2(96, 34)

	if placed:
		status_btn.text = "PLACED"
		status_btn.disabled = true
		status_btn.add_theme_color_override("font_disabled_color", Color(0.48, 0.48, 0.58, 1.0))
	elif can_afford:
		status_btn.text = "BUY"
		status_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
		var fid: String = f["id"]
		status_btn.pressed.connect(func() -> void:
			if _fm != null and _gm != null:
				_fm.place_facility(fid, _gm)
		)
	else:
		status_btn.text = "TOO POOR"
		status_btn.disabled = true
		status_btn.add_theme_color_override("font_disabled_color", Color(0.9, 0.3, 0.3, 1.0))

	bottom_row.add_child(status_btn)
	return panel

# ─────────────────────────────────────────
#  COMBO CARDS
# ─────────────────────────────────────────
func _build_combos_list() -> void:
	for child in _combos_list.get_children():
		child.queue_free()
	if _fm == null:
		return
	for combo in _fm.get_combos():
		_combos_list.add_child(_make_combo_card(combo))

func _make_combo_card(combo: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.078, 0.078, 0.172, 1.0)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.45, 0.28, 0.68, 0.7)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", card_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	vbox.add_child(name_row)

	var name_label: Label = Label.new()
	name_label.text = combo["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_label.add_theme_font_size_override("font_size", 14)
	name_row.add_child(name_label)

	var is_active: bool = _fm != null and _fm.active_combos.has(combo["id"])
	var badge: Label = Label.new()
	badge.text = "ACTIVE" if is_active else "LOCKED"
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	if is_active:
		badge.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42, 1.0))
	else:
		badge.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1.0))
	name_row.add_child(badge)

	var req_names: Array[String] = []
	for req_id in combo["requires"]:
		req_names.append(_get_facility_name(req_id))
	var req_label: Label = Label.new()
	req_label.text = "Requires: " + ", ".join(req_names)
	req_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28, 1.0))
	req_label.add_theme_font_size_override("font_size", 11)
	req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(req_label)

	var bonus_label: Label = Label.new()
	bonus_label.text = combo["bonus_desc"]
	bonus_label.add_theme_color_override("font_color", Color(0.22, 0.88, 0.48, 1.0))
	bonus_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(bonus_label)

	return panel

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _format_buff(buff: Dictionary) -> String:
	var parts: Array[String] = []
	for key in buff:
		var val: int = int(buff[key])
		var sign: String = "+" if val >= 0 else ""
		match key:
			"motivation":
				parts.append("MOT %s%d" % [sign, val])
			"focus":
				parts.append("Focus %s%d" % [sign, val])
			"teamwork":
				parts.append("Teamwork %s%d" % [sign, val])
			"project_speed":
				parts.append("Project Speed %s%d%%" % [sign, val])
			"tech_speed":
				parts.append("Tech Speed %s%d%%" % [sign, val])
			"skill_growth":
				parts.append("Skill Growth %s%d%%" % [sign, val])
			"drama":
				parts.append("Drama %s%d%%" % [sign, val])
			"reputation":
				parts.append("Reputation %s%d" % [sign, val])
			"charm":
				parts.append("Charm %s%d" % [sign, val])
			"burnout_rate":
				parts.append("Burnout Rate %s%d%%" % [sign, val])
			_:
				parts.append("%s %s%d" % [key, sign, val])
	return ", ".join(parts)

func _get_facility_name(id: String) -> String:
	if _fm == null:
		return id
	for f in _fm.facilities:
		if f["id"] == id:
			return f["name"]
	return id

# ─────────────────────────────────────────
#  INPUT HANDLERS
# ─────────────────────────────────────────
func _on_back_pressed() -> void:
	screen_closed.emit()
	queue_free()

func _on_facilities_tab_pressed() -> void:
	_show_facilities_tab()

func _on_combos_tab_pressed() -> void:
	_show_combos_tab()
