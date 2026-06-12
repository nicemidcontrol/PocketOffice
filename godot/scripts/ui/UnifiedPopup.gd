extends CanvasLayer

# UnifiedPopup (PR-6) — the single popup template per UI_SYSTEMS_BIBLE.
# Serves tutorials, item drops, achievements, evaluations, and bulletins.
# Interim BaseModal palette; art re-skin later under the new ART_BIBLE.
#
# Usage: instantiate, add to tree, setup(title, pages[, icon]), open().
# pages entries may be String or {"text": String}; 1 to 3 pages.

signal popup_closed

const MAX_PAGES: int = 3
const DOT_SIZE: int = 8
const DOT_FILLED: Color = Color(1.0, 0.82, 0.1, 1.0)
const DOT_EMPTY: Color = Color(0.4, 0.41, 0.52, 1.0)

@onready var _dimmer: ColorRect = $Dimmer
@onready var _banner_title: Label = $Dimmer/Card/VBox/Banner/BannerMargin/BannerRow/BannerTitle
@onready var _banner_icon: TextureRect = $Dimmer/Card/VBox/Banner/BannerMargin/BannerRow/BannerIcon
@onready var _body_area: MarginContainer = $Dimmer/Card/VBox/BodyArea
@onready var _body_label: Label = $Dimmer/Card/VBox/BodyArea/BodyLabel
@onready var _nav_row: HBoxContainer = $Dimmer/Card/VBox/NavRow
@onready var _prev_arrow: Button = $Dimmer/Card/VBox/NavRow/PrevArrow
@onready var _next_arrow: Button = $Dimmer/Card/VBox/NavRow/NextArrow
@onready var _dots_row: HBoxContainer = $Dimmer/Card/VBox/NavRow/DotsRow
@onready var _close_btn: Button = $Dimmer/Card/VBox/CloseRow/CloseBtn

var _title: String = ""
var _pages: Array = []
var _banner_texture: Texture2D = null
var current_page: int = 0
var acknowledged: bool = false
var _close_emitted: bool = false

func _ready() -> void:
	visible = false
	_dimmer.gui_input.connect(_on_dimmer_input)
	_body_area.gui_input.connect(_on_body_input)
	_prev_arrow.pressed.connect(prev_page)
	_next_arrow.pressed.connect(next_page)
	_close_btn.pressed.connect(_on_close_pressed)

# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────
func setup(title: String, pages: Array, banner_icon: Texture2D = null) -> void:
	_title = title
	_pages = pages.duplicate()
	if _pages.is_empty():
		_pages = [""]
	if _pages.size() > MAX_PAGES:
		print("[UnifiedPopup] WARNING: %d pages given, max is %d - extra pages dropped" % [_pages.size(), MAX_PAGES])
		_pages = _pages.slice(0, MAX_PAGES)
	_banner_texture = banner_icon
	current_page = 0
	acknowledged = false
	_close_emitted = false

func open() -> void:
	visible = true
	_banner_title.text = _title
	_banner_icon.texture = _banner_texture
	_banner_icon.visible = _banner_texture != null
	_build_dots()
	_go_to_page(0)

func page_count() -> int:
	return _pages.size()

func is_last_page() -> bool:
	return current_page == _pages.size() - 1

func next_page() -> void:
	if current_page < _pages.size() - 1:
		_go_to_page(current_page + 1)

func prev_page() -> void:
	if current_page > 0:
		_go_to_page(current_page - 1)

func skip_to_last() -> void:
	_go_to_page(_pages.size() - 1)

# ─────────────────────────────────────────
#  PAGE STATE
# ─────────────────────────────────────────
func _go_to_page(idx: int) -> void:
	current_page = clampi(idx, 0, _pages.size() - 1)
	if is_last_page():
		# Reaching the last page by any means = fully acknowledged.
		acknowledged = true
	_refresh()

func _page_text(idx: int) -> String:
	var entry: Variant = _pages[idx]
	if entry is Dictionary:
		return str((entry as Dictionary).get("text", ""))
	return str(entry)

func _refresh() -> void:
	_body_label.text = _page_text(current_page)
	var multi_page: bool = _pages.size() > 1
	_nav_row.visible = multi_page
	_prev_arrow.visible = multi_page and current_page > 0
	_next_arrow.visible = multi_page and not is_last_page()
	_close_btn.visible = is_last_page()
	for i: int in range(_dots_row.get_child_count()):
		var dot: ColorRect = _dots_row.get_child(i)
		dot.color = DOT_FILLED if i == current_page else DOT_EMPTY

func _build_dots() -> void:
	for child in _dots_row.get_children():
		_dots_row.remove_child(child)
		child.queue_free()
	if _pages.size() < 2:
		return
	for i: int in range(_pages.size()):
		var dot: ColorRect = ColorRect.new()
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = DOT_EMPTY
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots_row.add_child(dot)

# ─────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────
func _on_body_input(event: InputEvent) -> void:
	# Skip rule: tap anywhere on the body jumps to the last page.
	if _is_left_click(event):
		skip_to_last()

func _on_dimmer_input(event: InputEvent) -> void:
	# Outside tap closes only once the popup is fully acknowledged.
	if _is_left_click(event) and acknowledged:
		_close()

func _is_left_click(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return false

# ─────────────────────────────────────────
#  CLOSE
# ─────────────────────────────────────────
func _on_close_pressed() -> void:
	_close()

func _close() -> void:
	if _close_emitted:
		return
	_close_emitted = true
	popup_closed.emit()
	queue_free()
