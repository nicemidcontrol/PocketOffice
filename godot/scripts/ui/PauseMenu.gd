extends CanvasLayer

signal hire_requested
signal project_board_requested
signal employee_list_requested
signal build_requested
signal research_requested
signal shop_requested

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _root:          Control         = $Root
@onready var _hr_sub:        MarginContainer = $Root/ButtonsContainer/HRSub
@onready var _corporate_sub: MarginContainer = $Root/ButtonsContainer/CorporateSub
@onready var _lists_sub:     MarginContainer = $Root/ButtonsContainer/ListsSub
@onready var _system_sub:    MarginContainer = $Root/ButtonsContainer/SystemSub
@onready var _toast:         Label           = $Root/Toast

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node     = null
var _tween: Tween = null

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_root.visible = false
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[PauseMenu] GameManager autoload not found.")

# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────
func open() -> void:
	_close_all_subs()
	_root.visible = true
	get_tree().paused = true

# ─────────────────────────────────────────
#  SUBMENU HELPERS
# ─────────────────────────────────────────
func _close() -> void:
	_root.visible = false
	get_tree().paused = false

func _close_all_subs() -> void:
	_hr_sub.visible        = false
	_corporate_sub.visible = false
	_lists_sub.visible     = false
	_system_sub.visible    = false

func _toggle_sub(sub: MarginContainer) -> void:
	var was_open: bool = sub.visible
	_close_all_subs()
	sub.visible = !was_open

# ─────────────────────────────────────────
#  TOAST
# ─────────────────────────────────────────
func _show_toast(msg: String) -> void:
	_toast.text = msg
	if _tween:
		_tween.kill()
	_toast.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(1.5)
	_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)

# ─────────────────────────────────────────
#  INPUT HANDLERS (wired in .tscn)
# ─────────────────────────────────────────
func _on_overlay_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_close()

# ─────────────────────────────────────────
#  MENU ITEM HANDLERS (wired in .tscn)
# ─────────────────────────────────────────
func _on_build_pressed() -> void:
	_close()
	build_requested.emit()

func _on_hr_pressed() -> void:
	_toggle_sub(_hr_sub)

func _on_recruit_pressed() -> void:
	_close()
	hire_requested.emit()

func _on_items_pressed() -> void:
	_close()
	shop_requested.emit()

func _on_employee_list_pressed() -> void:
	_close()
	employee_list_requested.emit()

func _on_coming_soon() -> void:
	_show_toast("Coming Soon")

func _on_assign_pressed() -> void:
	_close()
	project_board_requested.emit()

func _on_research_pressed() -> void:
	_close()
	research_requested.emit()

func _on_corporate_pressed() -> void:
	_toggle_sub(_corporate_sub)

func _on_lists_pressed() -> void:
	_toggle_sub(_lists_sub)

func _on_system_pressed() -> void:
	_toggle_sub(_system_sub)

func _on_score_pressed() -> void:
	_close()
	score_requested.emit()

func _on_menu_save_pressed() -> void:
	if _gm != null:
		_gm.save_game()
	_show_toast("Saved!")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
