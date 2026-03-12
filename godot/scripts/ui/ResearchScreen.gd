extends CanvasLayer

signal screen_closed

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _cp_label:     Label  = $Card/VBox/CpLabel
@onready var _item_name:    Label  = $Card/VBox/ArrowRow/ItemNameLabel
@onready var _page_label:   Label  = $Card/VBox/PageLabel
@onready var _desc_label:   Label  = $Card/VBox/DetailCard/Margin/DetailVBox/DescLabel
@onready var _req_label:    Label  = $Card/VBox/DetailCard/Margin/DetailVBox/ReqLabel
@onready var _cost_label:   Label  = $Card/VBox/DetailCard/Margin/DetailVBox/CostLabel
@onready var _reward_label: Label  = $Card/VBox/DetailCard/Margin/DetailVBox/RewardLabel
@onready var _unlock_label: Label  = $Card/VBox/DetailCard/Margin/DetailVBox/UnlockLabel
@onready var _reason_label: Label  = $Card/VBox/DetailCard/Margin/DetailVBox/ReasonLabel
@onready var _research_btn: Button = $Card/VBox/ResearchBtn
@onready var _close_btn:    Button = $Card/VBox/CloseRow/CloseBtn
@onready var _notif_panel:  Panel  = $NotifLayer/NotifPanel
@onready var _notif_label:  Label  = $NotifLayer/NotifPanel/Margin/VBox/NotifLabel
@onready var _notif_timer:  Timer  = $NotifLayer/NotifPanel/NotifTimer

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:           Node  = null
var _dm:           Node  = null
var _items:        Array = []
var current_index: int   = 0

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
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
		_items = _dm.donors

	_refresh_display()

# ─────────────────────────────────────────
#  NAVIGATION
# ─────────────────────────────────────────
func _on_prev_pressed() -> void:
	if _items.is_empty():
		return
	current_index = (current_index - 1 + _items.size()) % _items.size()
	_refresh_display()

func _on_next_pressed() -> void:
	if _items.is_empty():
		return
	current_index = (current_index + 1) % _items.size()
	_refresh_display()

# ─────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────
func _refresh_display() -> void:
	if _items.is_empty() or _dm == null or _gm == null:
		_item_name.text = "No items"
		_page_label.text = "0 / 0"
		_desc_label.text = ""
		_req_label.text = ""
		_cost_label.text = ""
		_reward_label.text = ""
		_unlock_label.visible = false
		_reason_label.visible = false
		_research_btn.text = "LOCKED"
		_research_btn.disabled = true
		return

	var item: Dictionary = _items[current_index]
	var id: String = item.get("id", "")
	var check: Dictionary = _dm.check_requirements(id, _gm)
	var is_done: bool = _dm.won_donors.has(id)
	var is_ok: bool   = bool(check.get("ok", false))

	_item_name.text  = item.get("name", "")
	_page_label.text = "%d / %d" % [current_index + 1, _items.size()]
	_desc_label.text = item.get("description", "")

	# Requirements
	var rep: int       = int(_gm.company_data.get("reputation", 0))
	var req_rep: int   = int(item.get("req_reputation", 0))
	var rep_ok: bool   = rep >= req_rep or is_done
	var cur_year: int  = int(_gm.company_data.get("current_year", 2024))
	var game_year: int = cur_year - 2023
	var req_year: int  = int(item.get("req_year", 1))
	var year_ok: bool  = game_year >= req_year or is_done
	var req_role: String = item.get("req_role", "")
	var role_ok: bool    = true
	if req_role != "":
		role_ok = _dm._team_has_role(req_role, _gm) or is_done
	var req_parts: Array[String] = []
	req_parts.append("REP %d  %s" % [req_rep, "[OK]" if rep_ok else "[X]"])
	req_parts.append("Yr %d  %s" % [req_year, "[OK]" if year_ok else "[X]"])
	if req_role != "":
		req_parts.append("%s  %s" % [req_role, "[OK]" if role_ok else "[X]"])
	_req_label.text = "   ".join(req_parts)

	# Cost
	var cp_cost: int = int(item.get("cp_cost", 0))
	_cost_label.text = "Cost: %d CP" % cp_cost

	# Rewards
	var monthly: int = int(item.get("monthly_funding", 0))
	var one_cp: int  = int(item.get("one_time_cp", 0))
	_reward_label.text = "+$%d/mo   +%d CP bonus" % [monthly, one_cp]

	# Unlocks
	var hero_names: Array = item.get("unlocks_hero_names", [])
	var proj_names: Array = item.get("unlocks_projects", [])
	if hero_names.size() > 0 or proj_names.size() > 0:
		var parts: Array[String] = []
		for h in hero_names:
			parts.append(str(h))
		for p in proj_names:
			parts.append(str(p))
		_unlock_label.text = "Unlocks: " + ", ".join(parts)
		_unlock_label.visible = true
	else:
		_unlock_label.visible = false

	# Failure reasons
	var reasons: Array = check.get("reasons", [])
	if not is_done and reasons.size() > 0:
		_reason_label.text = "\n".join(reasons)
		_reason_label.visible = true
	else:
		_reason_label.visible = false

	# Action button
	if is_done:
		_research_btn.text = "DONE"
		_research_btn.disabled = true
		_research_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	elif is_ok:
		_research_btn.text = "RESEARCH"
		_research_btn.disabled = false
		_research_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	else:
		_research_btn.text = "LOCKED"
		_research_btn.disabled = true
		_research_btn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))

# ─────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────
func _on_research_pressed() -> void:
	if _items.is_empty() or _dm == null or _gm == null:
		return
	var item: Dictionary = _items[current_index]
	var id: String = item.get("id", "")
	var _result: bool = _dm.try_win_donor(id, _gm)

func _on_close_pressed() -> void:
	screen_closed.emit()
	queue_free()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cp_changed(new_val: int) -> void:
	_cp_label.text = "%d CP" % new_val
	_refresh_display()

func _on_donor_won(donor_name_str: String, monthly: int) -> void:
	_notif_label.text = "%s secured!\n+$%d/mo funding" % [donor_name_str, monthly]
	_notif_panel.visible = true
	_notif_timer.start()
	_refresh_display()

func _on_notif_timer_timeout() -> void:
	_notif_panel.visible = false
