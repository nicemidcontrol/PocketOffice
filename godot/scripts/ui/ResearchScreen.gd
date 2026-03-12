extends CanvasLayer

signal screen_closed

@onready var _cp_label:    Label         = $Card/Header/HBox/CpLabel
@onready var _vbox:        VBoxContainer = $Card/Scroll/VBox
@onready var _notif_panel: Panel         = $NotifLayer/NotifPanel
@onready var _notif_label: Label         = $NotifLayer/NotifPanel/Margin/VBox/NotifLabel
@onready var _notif_timer: Timer         = $NotifLayer/NotifPanel/NotifTimer

var _gm: Node = null
var _dm: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Dimmer.gui_input.connect(_on_dimmer_input)
	_gm = get_node_or_null("/root/GameManager")
	_dm = get_node_or_null("/root/DonorManager")

	if _gm != null:
		_gm.corp_points_changed.connect(_on_cp_changed)
		_cp_label.text = "%d CP" % _gm.corp_points

	if _dm != null:
		_dm.donor_won.connect(_on_donor_won)

	_build_cards()

func _on_back_pressed() -> void:
	screen_closed.emit()
	queue_free()

func _on_notif_timer_timeout() -> void:
	_notif_panel.visible = false

func _on_cp_changed(new_val: int) -> void:
	_cp_label.text = "%d CP" % new_val

func _on_donor_won(donor_name: String, monthly: int) -> void:
	_notif_label.text = "%s secured!\n+$%d/mo funding" % [donor_name, monthly]
	_notif_panel.visible = true
	_notif_timer.start()
	_rebuild_cards()

# ─────────────────────────────────────────
#  CARD BUILDING
# ─────────────────────────────────────────
func _build_cards() -> void:
	if _dm == null or _gm == null:
		return
	for donor in _dm.donors:
		_vbox.add_child(_make_card(donor))

func _rebuild_cards() -> void:
	for child in _vbox.get_children():
		child.queue_free()
	await get_tree().process_frame
	_build_cards()

func _make_card(donor: Dictionary) -> Control:
	var id: String    = donor["id"]
	var check: Dictionary = _dm.check_requirements(id, _gm)
	var is_won: bool  = _dm.won_donors.has(id)
	var is_ok: bool   = bool(check["ok"])

	var card: PanelContainer = PanelContainer.new()
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.07, 0.16, 0.95)
	card_style.border_width_left = 3
	if is_won:
		card_style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	elif is_ok:
		card_style.border_color = Color(0.2, 0.85, 0.3, 1.0)
	else:
		card_style.border_color = Color(0.65, 0.1, 0.1, 1.0)
	card_style.corner_radius_top_left     = 6
	card_style.corner_radius_top_right    = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left  = 6
	card_style.content_margin_left   = 12.0
	card_style.content_margin_right  = 12.0
	card_style.content_margin_top    = 10.0
	card_style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", card_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	card.add_child(margin)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	margin.add_child(col)

	var name_lbl: Label = Label.new()
	name_lbl.text = donor["name"]
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 16)
	col.add_child(name_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = donor["description"]
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc_lbl)

	col.add_child(_make_sep())
	col.add_child(_make_req_row(donor, _gm, _dm.won_donors.has(id)))

	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 12)
	col.add_child(reward_row)

	var cp_cost_lbl: Label = Label.new()
	cp_cost_lbl.text = "Cost: %d CP" % int(donor["cp_cost"])
	cp_cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	cp_cost_lbl.add_theme_font_size_override("font_size", 13)
	reward_row.add_child(cp_cost_lbl)

	var monthly_lbl: Label = Label.new()
	monthly_lbl.text = "+$%d/mo" % int(donor["monthly_funding"])
	monthly_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	monthly_lbl.add_theme_font_size_override("font_size", 13)
	reward_row.add_child(monthly_lbl)

	var one_cp_lbl: Label = Label.new()
	one_cp_lbl.text = "+%d CP" % int(donor["one_time_cp"])
	one_cp_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	one_cp_lbl.add_theme_font_size_override("font_size", 13)
	reward_row.add_child(one_cp_lbl)

	var hero_names: Array  = donor["unlocks_hero_names"]
	var proj_names: Array  = donor["unlocks_projects"]
	if hero_names.size() > 0 or proj_names.size() > 0:
		var unlock_lbl: Label = Label.new()
		var unlock_parts: Array = []
		for h in hero_names:
			unlock_parts.append(str(h))
		for p in proj_names:
			unlock_parts.append(str(p))
		unlock_lbl.text = "Unlocks: " + ", ".join(unlock_parts)
		unlock_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 1.0))
		unlock_lbl.add_theme_font_size_override("font_size", 11)
		unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(unlock_lbl)

	var reasons: Array = check["reasons"]
	if not is_won and reasons.size() > 0:
		for reason in reasons:
			var req_lbl: Label = Label.new()
			req_lbl.text = "  " + str(reason)
			req_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			req_lbl.add_theme_font_size_override("font_size", 11)
			col.add_child(req_lbl)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.corner_radius_top_left     = 4
	btn_style.corner_radius_top_right    = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.corner_radius_bottom_left  = 4
	btn_style.content_margin_left   = 8.0
	btn_style.content_margin_right  = 8.0
	btn_style.content_margin_top    = 4.0
	btn_style.content_margin_bottom = 4.0

	if is_won:
		btn.text = "WON"
		btn.disabled = true
		btn_style.bg_color = Color(0.25, 0.25, 0.25, 1.0)
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	elif is_ok:
		btn.text = "PURSUE"
		btn_style.bg_color = Color(0.08, 0.38, 0.12, 1.0)
		btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
		btn.pressed.connect(_on_pursue_pressed.bind(id))
	else:
		btn.text = "LOCKED"
		btn.disabled = true
		btn_style.bg_color = Color(0.28, 0.06, 0.06, 1.0)
		btn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))

	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_stylebox_override("normal",   btn_style)
	btn.add_theme_stylebox_override("hover",    btn_style)
	btn.add_theme_stylebox_override("pressed",  btn_style)
	btn.add_theme_stylebox_override("disabled", btn_style)
	col.add_child(btn)

	return card

func _make_req_row(donor: Dictionary, gm: Node, is_won: bool) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var rep: int  = int(gm.company_data.get("reputation", 0))
	var req_rep: int = int(donor["req_reputation"])
	var rep_ok: bool = rep >= req_rep or is_won

	var cur_year: int  = int(gm.company_data.get("current_year", 2024))
	var game_year: int = cur_year - 2023
	var req_year: int  = int(donor["req_year"])
	var year_ok: bool  = game_year >= req_year or is_won

	var req_role: String = donor["req_role"]
	var role_ok: bool    = true
	if req_role != "":
		role_ok = _dm._team_has_role(req_role, gm) or is_won

	var rep_lbl: Label = Label.new()
	rep_lbl.text = "REP %d" % req_rep
	rep_lbl.add_theme_font_size_override("font_size", 12)
	rep_lbl.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4, 1.0) if rep_ok else Color(1.0, 0.3, 0.3, 1.0))
	row.add_child(rep_lbl)

	var year_lbl: Label = Label.new()
	year_lbl.text = "Yr %d" % req_year
	year_lbl.add_theme_font_size_override("font_size", 12)
	year_lbl.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4, 1.0) if year_ok else Color(1.0, 0.3, 0.3, 1.0))
	row.add_child(year_lbl)

	if req_role != "":
		var role_lbl: Label = Label.new()
		role_lbl.text = req_role
		role_lbl.add_theme_font_size_override("font_size", 12)
		role_lbl.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.4, 1.0) if role_ok else Color(1.0, 0.3, 0.3, 1.0))
		row.add_child(role_lbl)

	return row

func _make_sep() -> HSeparator:
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.2, 0.2, 0.35, 0.8))
	return sep

func _on_pursue_pressed(id: String) -> void:
	if _dm == null or _gm == null:
		return
	var _result: bool = _dm.try_win_donor(id, _gm)

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()
