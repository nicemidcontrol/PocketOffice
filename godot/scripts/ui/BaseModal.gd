extends CanvasLayer

signal screen_closed

@onready var _dimmer: ColorRect = $Dimmer
@onready var _prev_btn: Button = $Dimmer/Card/VBox/ArrowRow/PrevBtn
@onready var _next_btn: Button = $Dimmer/Card/VBox/ArrowRow/NextBtn
@onready var _item_name_label: Label = $Dimmer/Card/VBox/ArrowRow/ItemNameLabel
@onready var _page_label: Label = $Dimmer/Card/VBox/PageLabel
@onready var _title_label: Label = $Dimmer/Card/VBox/TitleLabel
@onready var _action_btn: Button = $Dimmer/Card/VBox/ActionBtn
@onready var _close_btn: Button = $Dimmer/Card/VBox/CloseBtn

var _current_index: int = 0
var _total_items: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dimmer.gui_input.connect(_on_dimmer_input)
	_close_btn.pressed.connect(_on_close)
	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_close()

func _on_close() -> void:
	# Ensure PauseMenu is dismissed so player returns directly to the office.
	# PauseMenu._close() hides its root and unpauses the tree.
	var pause_menu: Node = get_node_or_null("/root/Main/PauseMenu")
	if pause_menu != null:
		pause_menu.call("_close")
	emit_signal("screen_closed")
	queue_free()

func _on_prev() -> void:
	if _total_items == 0:
		return
	_current_index = (_current_index - 1 + _total_items) % _total_items
	_refresh_display()

func _on_next() -> void:
	if _total_items == 0:
		return
	_current_index = (_current_index + 1) % _total_items
	_refresh_display()

func _refresh_display() -> void:
	_page_label.text = str(_current_index + 1) + " / " + str(_total_items)

func set_title(t: String) -> void:
	_title_label.text = t

func set_items_count(n: int) -> void:
	_total_items = n
	_refresh_display()
