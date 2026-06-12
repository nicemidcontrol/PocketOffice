extends HBoxContainer

# StaminaWidget (PR-7) — row of SP pips per UI_SYSTEMS_BIBLE.
# Pips are ColorRects (no unicode); filled = green, empty = grey,
# warning mode tints filled pips red for the ineligible card state.

const PIP_SIZE: int = 12
const PIP_GAP: int = 4
const BASE_PIP_COUNT: int = 5
const PIP_FILLED: Color = Color(0.22, 0.9, 0.42, 1.0)
const PIP_EMPTY: Color = Color(0.35, 0.36, 0.45, 1.0)
const PIP_WARNING: Color = Color(0.9, 0.25, 0.25, 1.0)

var _current: int = 0
var _maximum: int = BASE_PIP_COUNT
var _warning: bool = false

func _ready() -> void:
	add_theme_constant_override("separation", PIP_GAP)
	_rebuild()

func set_sp(current: int, maximum: int) -> void:
	_current = maxi(current, 0)
	_maximum = maxi(maximum, 1)
	_rebuild()

func set_warning(on: bool) -> void:
	_warning = on
	_refresh_colors()

func pip_count() -> int:
	# Always at least 5 pips; SP-cap items can push the row wider.
	return maxi(_maximum, BASE_PIP_COUNT)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i: int in range(pip_count()):
		var pip: ColorRect = ColorRect.new()
		pip.custom_minimum_size = Vector2(PIP_SIZE, PIP_SIZE)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pip)
	_refresh_colors()

func _refresh_colors() -> void:
	var fill_color: Color = PIP_WARNING if _warning else PIP_FILLED
	for i: int in range(get_child_count()):
		var pip: ColorRect = get_child(i)
		pip.color = fill_color if i < _current else PIP_EMPTY
