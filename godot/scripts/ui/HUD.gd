extends CanvasLayer

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var cash_label:    Label = $TopBar/Margin/HBox/CashSection/CashLabel
@onready var rep_label:     Label = $TopBar/Margin/HBox/RepSection/RepLabel
@onready var date_label:    Label = $TopBar/Margin/HBox/DateSection/DateLabel
@onready var message_panel: Panel = $MessagePanel
@onready var message_label: Label = $MessagePanel/Margin/MessageLabel
@onready var message_timer: Timer = $MessageTimer

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node     = null
var _tween: Tween = null

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	message_timer.timeout.connect(_on_message_timer_timeout)

	# GameManager is an Autoload — wait one frame to guarantee it is ready.
	await get_tree().process_frame
	_gm = get_node_or_null("/root/GameManager")
	if _gm == null:
		push_error("[HUD] GameManager autoload not found at /root/GameManager.")
		return

	_gm.game_message.connect(_on_game_message)
	_gm.economy.cash_changed.connect(_on_cash_changed)
	_gm.day_passed.connect(_on_day_passed)
	_gm.month_passed.connect(_on_month_passed)

	_refresh_all()

# ─────────────────────────────────────────
#  REFRESH HELPERS
# ─────────────────────────────────────────
func _refresh_all() -> void:
	_update_cash(_gm.economy.current_cash)
	_update_reputation()
	_update_date()

func _update_cash(amount: int) -> void:
	cash_label.text = "$" + _format_number(amount)

func _update_reputation() -> void:
	rep_label.text = str(_gm.company_data.get("reputation", 0))

func _update_date() -> void:
	var month: int = _gm.company_data.get("current_month", 1)
	var year: int  = _gm.company_data.get("current_year", 2024)
	date_label.text = "M%d  Y%d" % [month, year]

func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(new_cash: int) -> void:
	_update_cash(new_cash)

func _on_day_passed(_day: int) -> void:
	_update_reputation()
	_update_date()

func _on_month_passed(_month: int) -> void:
	_update_date()

func _on_game_message(message: String) -> void:
	message_label.text = message
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(message_panel, "modulate:a", 1.0, 0.15)
	message_timer.start()

func _on_message_timer_timeout() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(message_panel, "modulate:a", 0.0, 0.4)
