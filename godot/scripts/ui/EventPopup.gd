extends CanvasLayer

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _title_label:   Label         = $Panel/Margin/VBox/TitleLabel
@onready var _desc_label:    Label         = $Panel/Margin/VBox/DescLabel
@onready var _choices_vbox:  VBoxContainer = $Panel/Margin/VBox/ChoicesVBox

# ------------------------------------------
#  STATE
# ------------------------------------------
var _current_event: Dictionary = {}

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

# ------------------------------------------
#  PUBLIC API
# ------------------------------------------
func show_event(event: Dictionary) -> void:
	_current_event = event
	_title_label.text = event.get("title", "")
	_desc_label.text = event.get("description", "")
	_build_choices(event.get("choices", []))
	visible = true
	get_tree().paused = true

# ------------------------------------------
#  CHOICE BUILDING
# ------------------------------------------
func _build_choices(choices: Array) -> void:
	for child in _choices_vbox.get_children():
		child.queue_free()
	var idx: int = 0
	for choice in choices:
		var btn: PanelContainer = _make_choice_btn(choice, idx)
		_choices_vbox.add_child(btn)
		idx += 1

func _make_choice_btn(choice: Dictionary, choice_idx: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.18, 1.0)
	style.border_width_top    = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.18, 0.42, 0.78, 1.0)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left  = 4
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var text_lbl: Label = Label.new()
	text_lbl.text = choice.get("text", "")
	text_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	text_lbl.add_theme_font_size_override("font_size", 12)
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(text_lbl)

	var preview: String = choice.get("preview", "")
	if not preview.is_empty():
		var prev_lbl: Label = Label.new()
		prev_lbl.text = preview
		prev_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1, 1.0))
		prev_lbl.add_theme_font_size_override("font_size", 10)
		prev_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(prev_lbl)

	panel.gui_input.connect(func(input_event: InputEvent) -> void:
		if input_event is InputEventMouseButton and input_event.pressed \
				and input_event.button_index == MOUSE_BUTTON_LEFT:
			_on_choice_selected(choice_idx)
	)

	return panel

# ------------------------------------------
#  HANDLERS
# ------------------------------------------
func _on_choice_selected(choice_idx: int) -> void:
	var choices: Array = _current_event.get("choices", [])
	if choice_idx >= choices.size():
		return
	var em: Node = get_node_or_null("/root/EventManager")
	if em != null:
		em.resolve(choices[choice_idx])
	_hide_popup()

func _hide_popup() -> void:
	visible = false
	get_tree().paused = false
	_current_event = {}
	for child in _choices_vbox.get_children():
		child.queue_free()
