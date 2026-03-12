extends CanvasLayer

signal screen_closed

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _tab_facilities:  Button = $Card/VBox/TabRow/FacilitiesTab
@onready var _tab_combos:      Button = $Card/VBox/TabRow/CombosTab
@onready var _prev_btn:        Button = $Card/VBox/ArrowRow/PrevBtn
@onready var _next_btn:        Button = $Card/VBox/ArrowRow/NextBtn
@onready var _item_name_label: Label  = $Card/VBox/ArrowRow/ItemNameLabel
@onready var _detail_name:     Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DetailTopRow/DetailNameLabel
@onready var _detail_badge:    Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DetailTopRow/DetailBadgeLabel
@onready var _detail_desc:     Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DetailDescLabel
@onready var _detail_stat:     Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DetailStatLabel
@onready var _detail_cost:     Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DetailCostLabel
@onready var _action_btn:      Button = $Card/VBox/ActionBtn
@onready var _close_btn:       Button = $Card/VBox/CloseRow/CloseBtn

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:              Node   = null
var _fm:              Node   = null
var _facility_index:  int    = 0
var _combo_index:     int    = 0
var _active_tab:      String = "facilities"

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Dimmer.gui_input.connect(_on_dimmer_input)
	_gm = get_node_or_null("/root/GameManager")
	_fm = get_node_or_null("/root/FacilityManager")
	if _fm != null:
		_fm.facilities_updated.connect(_refresh)
	_tab_facilities.pressed.connect(_on_facilities_tab_pressed)
	_tab_combos.pressed.connect(_on_combos_tab_pressed)
	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)
	_action_btn.pressed.connect(_on_action_btn_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_show_facilities_tab()
	_refresh()

# ─────────────────────────────────────────
#  TABS
# ─────────────────────────────────────────
func _show_facilities_tab() -> void:
	_active_tab = "facilities"
	_tab_facilities.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_tab_combos.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1.0))
	_action_btn.visible = true
	_refresh_display()

func _show_combos_tab() -> void:
	_active_tab = "combos"
	_tab_combos.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_tab_facilities.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58, 1.0))
	_action_btn.visible = false
	_refresh_display()

# ─────────────────────────────────────────
#  ARROW NAVIGATION
# ─────────────────────────────────────────
func _on_prev() -> void:
	if _fm == null:
		return
	if _active_tab == "facilities":
		if _fm.facilities.is_empty():
			return
		_facility_index = (_facility_index - 1 + _fm.facilities.size()) % _fm.facilities.size()
	else:
		var combos: Array = _fm.get_combos()
		if combos.is_empty():
			return
		_combo_index = (_combo_index - 1 + combos.size()) % combos.size()
	_refresh_display()

func _on_next() -> void:
	if _fm == null:
		return
	if _active_tab == "facilities":
		if _fm.facilities.is_empty():
			return
		_facility_index = (_facility_index + 1) % _fm.facilities.size()
	else:
		var combos: Array = _fm.get_combos()
		if combos.is_empty():
			return
		_combo_index = (_combo_index + 1) % combos.size()
	_refresh_display()

# ─────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────
func _refresh_display() -> void:
	if _fm == null:
		return
	if _active_tab == "facilities":
		if _fm.facilities.is_empty():
			return
		var f: Dictionary = _fm.facilities[_facility_index]
		_item_name_label.text = f.get("name", "")
		_detail_name.text = f.get("name", "")
		var tw: int = int(f.get("tile_w", 1))
		var th: int = int(f.get("tile_h", 1))
		_detail_badge.text = "%dx%d" % [tw, th]
		_detail_badge.add_theme_color_override("font_color", Color(0.52, 0.52, 0.62))
		_detail_desc.text = f.get("description", "")
		_detail_stat.text = _format_buff(f.get("stat_buff", {}))
		_detail_cost.text = "$%d" % int(f.get("cost", 0))
		_refresh_action_btn(f)
	else:
		var combos: Array = _fm.get_combos()
		if combos.is_empty():
			return
		var combo: Dictionary = combos[_combo_index]
		_item_name_label.text = combo.get("name", "")
		_detail_name.text = combo.get("name", "")
		var is_active: bool = _fm.active_combos.has(combo.get("id", ""))
		_detail_badge.text = "ACTIVE" if is_active else "LOCKED"
		_detail_badge.add_theme_color_override("font_color",
			Color(0.22, 0.9, 0.42) if is_active else Color(0.48, 0.48, 0.58))
		var req_names: Array[String] = []
		for req_id in combo.get("requires", []):
			req_names.append(_get_facility_name(req_id))
		_detail_desc.text = "Requires: " + ", ".join(req_names)
		_detail_stat.text = combo.get("bonus_desc", "")
		_detail_cost.text = ""

func _refresh_action_btn(f: Dictionary) -> void:
	var placed: bool = bool(f.get("placed", false))
	var cash: int = _gm.economy.current_cash if _gm != null else 0
	var can_afford: bool = cash >= int(f.get("cost", 0))
	_action_btn.disabled = false
	if placed:
		_action_btn.text = "PLACED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.48, 0.48, 0.58))
	elif can_afford:
		_action_btn.text = "BUY"
		_action_btn.add_theme_color_override("font_color", Color(0.22, 0.9, 0.42))
	else:
		_action_btn.text = "TOO POOR"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

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
func _on_facilities_tab_pressed() -> void:
	_show_facilities_tab()

func _on_combos_tab_pressed() -> void:
	_show_combos_tab()

func _on_action_btn_pressed() -> void:
	if _active_tab != "facilities":
		return
	if _fm == null or _gm == null:
		return
	if _fm.facilities.is_empty():
		return
	var f: Dictionary = _fm.facilities[_facility_index]
	if not bool(f.get("placed", false)):
		_fm.place_facility(f.get("id", ""), _gm)

func _refresh() -> void:
	_refresh_display()

func _on_close_pressed() -> void:
	queue_free()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()
