extends "res://scripts/ui/BaseModal.gd"

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _cp_label:     Label = $Dimmer/Card/VBox/CpLabel
@onready var _desc_label:   Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/DescLabel
@onready var _req_label:    Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/ReqLabel
@onready var _cost_label:   Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/CostLabel
@onready var _reward_label: Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/RewardLabel
@onready var _unlock_label: Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/UnlockLabel
@onready var _reason_label: Label = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/ReasonLabel
@onready var _notif_panel:  Panel = $NotifLayer/NotifPanel
@onready var _notif_label:  Label = $NotifLayer/NotifPanel/Margin/VBox/NotifLabel
@onready var _notif_timer:  Timer = $NotifLayer/NotifPanel/NotifTimer

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:       Node           = null
var _dm:       Node           = null
var _items:    Array          = []
var _req_rich: RichTextLabel  = null

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	super._ready()
	set_title("RESEARCH")
	_gm = get_node_or_null("/root/GameManager")
	_dm = get_node_or_null("/root/DonorManager")

	if _gm != null:
		_gm.corp_points_changed.connect(_on_cp_changed)
		_cp_label.text = "%d CP" % _gm.corp_points

	if _dm != null:
		_dm.donor_won.connect(_on_donor_won)
		_items = _dm.donors

	# ── label styling ─────────────────────────────────────────────────
	# NOTE: must run before set_items_count() which triggers _refresh_display()
	_desc_label.autowrap_mode     = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.max_lines_visible = 2
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	_unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unlock_label.add_theme_font_size_override("font_size", 10)
	_unlock_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	# ── section spacing ───────────────────────────────────────────────
	var detail_vbox: VBoxContainer = _desc_label.get_parent() as VBoxContainer
	detail_vbox.add_theme_constant_override("separation", 8)

	# ── replace ReqLabel with RichTextLabel for per-requirement colours
	_req_rich = RichTextLabel.new()
	_req_rich.bbcode_enabled           = true
	_req_rich.fit_content              = true
	_req_rich.scroll_active            = false
	_req_rich.size_flags_horizontal    = Control.SIZE_FILL
	_req_rich.add_theme_font_size_override("normal_font_size", 11)
	detail_vbox.add_child(_req_rich)
	detail_vbox.move_child(_req_rich, _req_label.get_index())
	_req_label.hide()

	set_items_count(_items.size())

# ─────────────────────────────────────────
#  DISPLAY (BaseModal override)
# ─────────────────────────────────────────
func _refresh_display() -> void:
	if _req_rich == null:
		return
	if _items.is_empty() or _dm == null or _gm == null:
		_item_name_label.text   = "No items"
		_page_label.text        = "0 / 0"
		_desc_label.text        = ""
		_req_rich.text          = ""
		_cost_label.text        = ""
		_reward_label.text      = ""
		_unlock_label.visible   = false
		_reason_label.visible   = false
		_action_btn.text        = "LOCKED"
		_action_btn.disabled    = true
		return

	super._refresh_display()

	var item: Dictionary = _items[_current_index]
	var id: String       = item.get("id", "")
	var check: Dictionary = _dm.check_requirements(id, _gm)
	var is_done: bool = _dm.won_donors.has(id)
	var is_ok: bool   = bool(check.get("ok", false))

	_item_name_label.text = item.get("name", "")
	_desc_label.text      = item.get("description", "")

	# Requirements — one per line, colour-coded per item
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
	var c_green: String      = "#4de64d"
	var c_red: String        = "#e64d4d"
	var req_lines: Array[String] = []
	req_lines.append("[color=%s]REP %d  %s[/color]" % [
		c_green if rep_ok else c_red, req_rep, "[OK]" if rep_ok else "[X]"
	])
	req_lines.append("[color=%s]Year %d  %s[/color]" % [
		c_green if year_ok else c_red, req_year, "[OK]" if year_ok else "[X]"
	])
	if req_role != "":
		req_lines.append("[color=%s]%s  %s[/color]" % [
			c_green if role_ok else c_red, req_role, "[OK]" if role_ok else "[X]"
		])
	_req_rich.text = "\n".join(req_lines)

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
		_unlock_label.text    = "Unlocks: " + ", ".join(parts)
		_unlock_label.visible = true
	else:
		_unlock_label.visible = false

	# Failure reasons
	var reasons: Array = check.get("reasons", [])
	if not is_done and reasons.size() > 0:
		_reason_label.text    = "\n".join(reasons)
		_reason_label.visible = true
	else:
		_reason_label.visible = false

	# Action button
	if is_done:
		_action_btn.text     = "DONE"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	elif is_ok:
		_action_btn.text     = "RESEARCH"
		_action_btn.disabled = false
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	else:
		_action_btn.text     = "LOCKED"
		_action_btn.disabled = true
		_action_btn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))

# ─────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────
func _on_research_pressed() -> void:
	if _items.is_empty() or _dm == null or _gm == null:
		return
	var item: Dictionary = _items[_current_index]
	var id: String = item.get("id", "")
	var _result: bool = _dm.try_win_donor(id, _gm)

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cp_changed(new_val: int) -> void:
	_cp_label.text = "%d CP" % new_val
	_refresh_display()

func _on_donor_won(donor_name_str: String, monthly: int) -> void:
	_notif_label.text    = "%s secured!\n+$%d/mo funding" % [donor_name_str, monthly]
	_notif_panel.visible = true
	_notif_timer.start()
	_refresh_display()

func _on_notif_timer_timeout() -> void:
	_notif_panel.visible = false
