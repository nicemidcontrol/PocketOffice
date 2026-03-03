extends CanvasLayer

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _saved_lbl: Label  = $Bar/SavedLabel

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node     = null
var _tween: Tween = null

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal menu_requested

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[BottomBar] GameManager autoload not found.")

# ─────────────────────────────────────────
#  HANDLERS (wired in .tscn)
# ─────────────────────────────────────────
func _on_save_pressed() -> void:
	if _gm != null:
		_gm.save_game()
	_flash_saved()

func _on_menu_pressed() -> void:
	menu_requested.emit()

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _flash_saved() -> void:
	if _tween:
		_tween.kill()
	_saved_lbl.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(1.2)
	_tween.tween_property(_saved_lbl, "modulate:a", 0.0, 0.4)
