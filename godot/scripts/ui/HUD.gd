extends CanvasLayer

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var cash_label:    Label = $TopBar/Margin/HBox/CashSection/CashLabel
@onready var cp_label:      Label = $TopBar/Margin/HBox/CpSection/CpLabel
@onready var date_label:    Label = $TopBar/Margin/HBox/DateSection/DateLabel
@onready var season_label:  Label = $TopBar/Margin/HBox/SeasonSection/SeasonLabel
@onready var message_panel: Panel = $MessagePanel
@onready var message_label: Label = $MessagePanel/Margin/MessageLabel
@onready var message_timer: Timer = $MessageTimer

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm: Node     = null
var _cm: Node     = null
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
	_gm.corp_points_changed.connect(_on_cp_changed)
	_gm.month_passed.connect(_on_month_passed)

	_cm = get_node_or_null("/root/ClockManager")
	if _cm != null:
		_cm.time_updated.connect(_on_time_updated)
		# Poll corp_points on each work day: idle CP uses gm.corp_points += directly
		# and bypasses corp_points_changed, so work_day_started is the safety net.
		_cm.work_day_started.connect(_on_work_day_started)

	_refresh_all()

# ─────────────────────────────────────────
#  REFRESH HELPERS
# ─────────────────────────────────────────
func _refresh_all() -> void:
	_update_cash(_gm.economy.current_cash)
	_update_cp(_gm.corp_points)
	_update_date()

func _update_cash(amount: int) -> void:
	cash_label.text = _gm.format_cash(amount)

func _update_cp(amount: int) -> void:
	cp_label.text = str(amount) + " CP"

func _update_reputation() -> void:
	pass

func _update_date() -> void:
	var month: int     = _gm.company_data.get("current_month", 1)
	var game_year: int = _gm.game_year
	var tick: int      = _gm.company_data.get("current_tick", 0)
	var week: int      = clampi((tick / 2) + 1, 1, 4)
	date_label.text = "W%d  M%d  Y%d" % [week, month, game_year]
	_update_season(month)

func _update_season(month: int) -> void:
	var season: String = "WINTER"
	if month >= 3 and month <= 5:
		season = "SPRING"
	elif month >= 6 and month <= 8:
		season = "SUMMER"
	elif month >= 9 and month <= 11:
		season = "AUTUMN"
	season_label.text = season

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(new_cash: int) -> void:
	_update_cash(new_cash)

func _on_cp_changed(new_cp: int) -> void:
	_update_cp(new_cp)

func _on_work_day_started() -> void:
	# Catches idle CP awarded via direct corp_points += (no signal emitted).
	_update_cp(_gm.corp_points)

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

func _on_time_updated(_hour: int, _minute: int) -> void:
	pass
