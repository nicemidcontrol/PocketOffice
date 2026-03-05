extends Node

# ClockManager - Autoload singleton
# 1 month = 8 ticks, each tick = 60 real seconds
# 1 year = 96 real minutes (12 months x 8 ticks x 60s)
# 5-year campaign = ~8 hours total playtime

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal work_day_started
signal month_changed(month: int, year: int)
signal time_updated(hour: int, minute: int)

# ------------------------------------------
#  STATE
# ------------------------------------------
var current_hour: int   = 8
var current_minute: int = 0
var current_month: int  = 1
var current_year: int   = 2024
var game_speed: float   = 1.0
var is_paused: bool     = false

# 1 tick = 60 real seconds, simulated as 08:00-16:00 (480 in-game minutes)
# => 1 in-game minute = 60.0 / 480.0 real seconds
const _SECONDS_PER_MINUTE: float = 60.0 / 480.0
const _TICKS_PER_MONTH: int      = 8

var _second_acc: float = 0.0
var _tick_count: int   = 0

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	work_day_started.emit()
	time_updated.emit(current_hour, current_minute)

func _process(delta: float) -> void:
	if is_paused:
		return
	_second_acc += delta * game_speed
	while _second_acc >= _SECONDS_PER_MINUTE:
		_second_acc -= _SECONDS_PER_MINUTE
		_tick_minute()

# ------------------------------------------
#  TIME PROGRESSION
# ------------------------------------------
func _tick_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
	time_updated.emit(current_hour, current_minute)
	if current_hour >= 16 and current_minute == 0:
		_end_tick()

func _end_tick() -> void:
	_tick_count += 1
	if _tick_count >= _TICKS_PER_MONTH:
		_tick_count = 0
		_advance_month()
	current_hour = 8
	current_minute = 0
	work_day_started.emit()
	time_updated.emit(current_hour, current_minute)

func _advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	month_changed.emit(current_month, current_year)
