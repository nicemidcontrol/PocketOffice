extends CanvasLayer

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _panel:       Panel         = $Panel
@onready var _alert_list:  VBoxContainer = $Panel/Margin/VBox/AlertScroll/AlertList
@onready var _close_btn:   Button        = $Panel/Margin/VBox/CloseBtn

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	_panel.visible = false
	_close_btn.pressed.connect(_on_close)
	var ipm: Node = get_node_or_null("/root/InternalProblemManager")
	if ipm != null:
		ipm.warning_issued.connect(_on_warning_issued)
		ipm.problem_escalated.connect(_on_problem_escalated)

# ------------------------------------------
#  SIGNAL HANDLERS
# ------------------------------------------
func _on_warning_issued(warning: Dictionary) -> void:
	_refresh_list()

func _on_problem_escalated(warning: Dictionary) -> void:
	_refresh_list()
	# Auto-show panel on escalations
	_panel.visible = true

# ------------------------------------------
#  LIST BUILDING
# ------------------------------------------
func _refresh_list() -> void:
	for child in _alert_list.get_children():
		child.queue_free()
	var ipm: Node = get_node_or_null("/root/InternalProblemManager")
	if ipm == null:
		return
	var warnings: Array = ipm.get_active_warnings()
	if warnings.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "No active alerts."
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 1))
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_alert_list.add_child(empty_lbl)
		return
	for w in warnings:
		_alert_list.add_child(_make_alert_row(w))

func _make_alert_row(w: Dictionary) -> PanelContainer:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var escalated: bool = w.get("escalated", false)
	style.bg_color = Color(0.12, 0.04, 0.04, 0.95) if escalated else Color(0.08, 0.06, 0.04, 0.95)
	style.border_width_top    = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.2, 0.2, 1) if escalated else Color(0.8, 0.55, 0.1, 1)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left  = 4

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	var lbl: Label = Label.new()
	lbl.text = w.get("message", "")
	lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.6, 1) if escalated else Color(0.95, 0.82, 0.5, 1))
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(lbl)

	var key: String = w.get("key", "")
	if not key.is_empty():
		var dismiss_btn: Button = Button.new()
		dismiss_btn.text = "X"
		dismiss_btn.add_theme_font_size_override("font_size", 10)
		dismiss_btn.custom_minimum_size = Vector2(24, 0)
		dismiss_btn.pressed.connect(func() -> void: _on_dismiss(key))
		hbox.add_child(dismiss_btn)

	return panel

# ------------------------------------------
#  HANDLERS
# ------------------------------------------
func _on_close() -> void:
	_panel.visible = false

func _on_dismiss(key: String) -> void:
	var ipm: Node = get_node_or_null("/root/InternalProblemManager")
	if ipm != null:
		ipm.dismiss_warning(key)
	_refresh_list()

# ------------------------------------------
#  PUBLIC API
# ------------------------------------------
func show_panel() -> void:
	_refresh_list()
	_panel.visible = true
