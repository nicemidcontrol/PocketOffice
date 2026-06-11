extends CanvasLayer

# Character Customization (PR-5) — cosmetic-only founder setup shown before
# the first office load. Plain interim styling on the BaseModal palette; a
# visual re-skin happens later under the new ART_BIBLE.

signal customization_complete

const MAX_NAME_LENGTH: int = 20
const MAX_NGO_NAME_LENGTH: int = 30
const PORTRAIT_COUNT: int = 6
# Placeholder swatches until portrait art exists (ART_BIBLE re-skin).
const PORTRAIT_COLORS: Array[Color] = [
	Color(0.75, 0.35, 0.30, 1.0),
	Color(0.85, 0.65, 0.25, 1.0),
	Color(0.30, 0.65, 0.40, 1.0),
	Color(0.25, 0.55, 0.80, 1.0),
	Color(0.55, 0.40, 0.75, 1.0),
	Color(0.80, 0.45, 0.65, 1.0),
]
const PORTRAIT_INITIALS: Array[String] = ["A", "B", "C", "D", "E", "F"]

@onready var _portrait_grid: GridContainer = $Dimmer/Card/Margin/VBox/PortraitGrid
@onready var _name_edit: LineEdit = $Dimmer/Card/Margin/VBox/NameEdit
@onready var _ngo_edit: LineEdit = $Dimmer/Card/Margin/VBox/NgoEdit
@onready var _start_btn: Button = $Dimmer/Card/Margin/VBox/StartBtn

var _selected_portrait_id: int = 0
var _slot_buttons: Array[Button] = []

# ─────────────────────────────────────────
#  VALIDATION (static so tests hit it directly)
# ─────────────────────────────────────────
static func sanitize_name(raw: String, max_len: int) -> String:
	return raw.strip_edges().left(max_len)

static func is_valid_input(pm_name: String, ngo_name: String) -> bool:
	if sanitize_name(pm_name, MAX_NAME_LENGTH).is_empty():
		return false
	return not sanitize_name(ngo_name, MAX_NGO_NAME_LENGTH).is_empty()

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_portrait_slots()
	_name_edit.text_changed.connect(_on_any_text_changed)
	_ngo_edit.text_changed.connect(_on_any_text_changed)
	_start_btn.pressed.connect(_on_start_pressed)
	_update_start_state()

# ─────────────────────────────────────────
#  PORTRAIT SLOTS
# ─────────────────────────────────────────
func _build_portrait_slots() -> void:
	for i: int in range(PORTRAIT_COUNT):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.focus_mode = Control.FOCUS_NONE
		var swatch: ColorRect = ColorRect.new()
		swatch.color = PORTRAIT_COLORS[i]
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		btn.add_child(swatch)
		var initial: Label = Label.new()
		initial.text = PORTRAIT_INITIALS[i]
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial.add_theme_font_size_override("font_size", 22)
		initial.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
		btn.add_child(initial)
		var portrait_id: int = i
		btn.pressed.connect(func() -> void: _on_portrait_pressed(portrait_id))
		_portrait_grid.add_child(btn)
		_slot_buttons.append(btn)
	_update_portrait_selection()

func _on_portrait_pressed(portrait_id: int) -> void:
	_selected_portrait_id = portrait_id
	_update_portrait_selection()

func _update_portrait_selection() -> void:
	for i: int in range(_slot_buttons.size()):
		var selected: bool = i == _selected_portrait_id
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.18, 1.0)
		var border_width: int = 3 if selected else 1
		style.border_width_left   = border_width
		style.border_width_top    = border_width
		style.border_width_right  = border_width
		style.border_width_bottom = border_width
		if selected:
			style.border_color = Color(0.3, 1.0, 0.4, 1.0)
		else:
			style.border_color = Color(0.18, 0.42, 0.78, 0.4)
		var btn: Button = _slot_buttons[i]
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

# ─────────────────────────────────────────
#  INPUT VALIDATION + START
# ─────────────────────────────────────────
func _on_any_text_changed(_new_text: String) -> void:
	_update_start_state()

func _update_start_state() -> void:
	_start_btn.disabled = not is_valid_input(_name_edit.text, _ngo_edit.text)

func _on_start_pressed() -> void:
	var pm_name: String = sanitize_name(_name_edit.text, MAX_NAME_LENGTH)
	var ngo_name: String = sanitize_name(_ngo_edit.text, MAX_NGO_NAME_LENGTH)
	if pm_name.is_empty() or ngo_name.is_empty():
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.create_protagonist(_selected_portrait_id, pm_name, ngo_name)
		gm.save_game()
	customization_complete.emit()
	queue_free()
