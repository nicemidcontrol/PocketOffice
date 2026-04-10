extends RefCounted

# Displays a "MEMO FROM SECRETARY" popup when tasks or projects become unlocked.
# Call show_unlock(parent, unlocked_items, on_closed).
# Does nothing if unlocked_items is empty.
# Each item dict: { "type": "task"/"project", "name": String }

const _MESSAGES: Array[String] = [
	"Congratulations. More work just arrived. You're welcome.",
	"Good news: you finished something. Bad news: here's more.",
	"The board is thrilled. They've rewarded you with... more tasks.",
	"Alert: new items detected in your workload. No, you can't refuse.",
	"Task complete! Your reward? The gift of additional responsibility.",
]

var _layer:     CanvasLayer = null
var _on_closed: Callable    = Callable()

func show_unlock(parent: Node, unlocked_items: Array, on_closed: Callable) -> void:
	if unlocked_items.is_empty():
		return
	_on_closed = on_closed

	_layer       = CanvasLayer.new()
	_layer.layer = 9

	# Dimmer — full viewport
	var dimmer: ColorRect     = ColorRect.new()
	dimmer.anchor_left        = 0.0
	dimmer.anchor_top         = 0.0
	dimmer.anchor_right       = 1.0
	dimmer.anchor_bottom      = 1.0
	dimmer.grow_horizontal    = Control.GROW_DIRECTION_BOTH
	dimmer.grow_vertical      = Control.GROW_DIRECTION_BOTH
	dimmer.color              = Color(0.0, 0.0, 0.0, 0.55)
	_layer.add_child(dimmer)

	# Card — centered, navy bg, blue border
	var card: Panel        = Panel.new()
	card.anchor_left       = 0.5
	card.anchor_top        = 0.5
	card.anchor_right      = 0.5
	card.anchor_bottom     = 0.5
	card.offset_left       = -175.0
	card.offset_right      =  175.0
	card.offset_top        = -160.0
	card.offset_bottom     =  160.0
	card.grow_horizontal   = Control.GROW_DIRECTION_BOTH
	card.grow_vertical     = Control.GROW_DIRECTION_BOTH

	var style: StyleBoxFlat              = StyleBoxFlat.new()
	style.bg_color                       = Color(0.047, 0.047, 0.11, 0.97)
	style.border_width_left              = 2
	style.border_width_top               = 2
	style.border_width_right             = 2
	style.border_width_bottom            = 2
	style.border_color                   = Color(0.18, 0.42, 0.78, 1.0)
	style.corner_radius_top_left         = 10
	style.corner_radius_top_right        = 10
	style.corner_radius_bottom_right     = 10
	style.corner_radius_bottom_left      = 10
	card.add_theme_stylebox_override("panel", style)
	dimmer.add_child(card)

	# Margin
	var margin: MarginContainer    = MarginContainer.new()
	margin.anchor_left             = 0.0
	margin.anchor_top              = 0.0
	margin.anchor_right            = 1.0
	margin.anchor_bottom           = 1.0
	margin.grow_horizontal         = Control.GROW_DIRECTION_BOTH
	margin.grow_vertical           = Control.GROW_DIRECTION_BOTH
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	# Content VBox
	var vbox: VBoxContainer        = VBoxContainer.new()
	vbox.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical       = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Title
	_add_label(vbox, "MEMO FROM SECRETARY", 14, Color(0.95, 0.95, 0.98, 1.0), true)
	vbox.add_child(HSeparator.new())

	# Secretary message — randomly selected
	var msg_idx: int   = randi() % _MESSAGES.size()
	var msg_lbl: Label = _add_label(vbox, _MESSAGES[msg_idx], 11, Color(0.6, 0.6, 0.7, 1.0), true)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox.add_child(HSeparator.new())

	# Unlocked items list
	for item in unlocked_items:
		var item_type: String = item.get("type", "task")
		var item_name: String = item.get("name", "")
		var prefix: String    = "New task unlocked:" if item_type == "task" else "New project unlocked:"
		var item_lbl: Label   = _add_label(vbox, prefix + " " + item_name, 12, Color(0.22, 0.9, 0.42, 1.0), false)
		item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox.add_child(HSeparator.new())

	# OK button
	var ok_btn: Button           = Button.new()
	ok_btn.text                  = "OK"
	ok_btn.custom_minimum_size   = Vector2(0, 36)
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.add_theme_font_size_override("font_size", 13)
	ok_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	ok_btn.pressed.connect(_on_ok_pressed)
	vbox.add_child(ok_btn)

	parent.add_child(_layer)

func _add_label(parent: VBoxContainer, text: String, size: int, color: Color, centered: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func _on_ok_pressed() -> void:
	if _layer != null:
		_layer.queue_free()
		_layer = null
	_on_closed.call()
