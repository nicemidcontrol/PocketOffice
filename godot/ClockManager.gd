extends Node

# ClockManager - Autoload singleton
# Tracks in-game time with 1 in-game day = 8 real seconds at game_speed 1.0.
# Work hours: 08:00 to 16:00 (480 in-game minutes per day, 22 days per month).

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal work_day_started
signal work_day_ended
signal month_changed(month: int, year: int)
signal time_updated(hour: int, minute: int)

# ------------------------------------------
#  STATE
# ------------------------------------------
var current_hour: int   = 8
var current_minute: int = 0
var current_day: int    = 1
var current_month: int  = 1
var current_year: int   = 2024
var game_speed: float   = 1.0
var is_work_time: bool  = false
var is_paused: bool     = false

# 1 in-game day = 8 real seconds = 480 in-game minutes
# => 1 in-game minute = 8.0 / 480.0 real seconds
var _second_acc: float = 0.0
const _SECONDS_PER_MINUTE: float = 8.0 / 480.0

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	is_work_time = true
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
		_end_work_day()

func _end_work_day() -> void:
	work_day_ended.emit()
	is_work_time = false
	_advance_day()

func _advance_day() -> void:
	current_day += 1
	if current_day > 22:
		current_day = 1
		_advance_month()
	current_hour = 8
	current_minute = 0
	is_work_time = true
	work_day_started.emit()
	time_updated.emit(current_hour, current_minute)

func _advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	month_changed.emit(current_month, current_year)
