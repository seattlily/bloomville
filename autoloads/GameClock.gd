extends Node

## Real-time seconds per in-game day.
## Debug mode uses a shorter cycle for rapid testing.
const REAL_SECONDS_PER_DAY: float = 600.0
const DEBUG_SECONDS_PER_DAY: float = 30.0
const DAYS_PER_SEASON: int = 30

enum Season { SPRING = 0, SUMMER = 1, FALL = 2, WINTER = 3 }

var debug_mode: bool = true

var current_day: int = 1
var current_season: Season = Season.SPRING
var current_year: int = 1
## Normalized 0.0–1.0 progress through the current day. Used by HUD progress bar.
var time_of_day: float = 0.0

signal day_started(day: int, season: Season, year: int)
signal day_ended(day: int, season: Season, year: int)
signal season_changed(new_season: Season, year: int)
## Fires once per virtual hour (0–23) within each in-game day.
signal hour_passed(hour: int)

var _elapsed: float = 0.0
var _last_hour: int = -1


func _ready() -> void:
	_elapsed = 0.25 * _seconds_per_day()  # start at 6 AM, not midnight
	time_of_day = 0.25
	day_started.emit(current_day, current_season, current_year)


func _process(delta: float) -> void:
	_elapsed += delta
	time_of_day = _elapsed / _seconds_per_day()

	var current_hour := int(time_of_day * 24.0)
	if current_hour != _last_hour and current_hour < 24:
		_last_hour = current_hour
		hour_passed.emit(current_hour)

	if _elapsed >= _seconds_per_day():
		_elapsed -= _seconds_per_day()
		_last_hour = -1
		_advance_day()


func _seconds_per_day() -> float:
	return DEBUG_SECONDS_PER_DAY if debug_mode else REAL_SECONDS_PER_DAY


func _advance_day() -> void:
	day_ended.emit(current_day, current_season, current_year)
	current_day += 1
	if current_day > DAYS_PER_SEASON:
		current_day = 1
		_advance_season()
	day_started.emit(current_day, current_season, current_year)


func _advance_season() -> void:
	current_season = ((current_season + 1) % 4) as Season
	if current_season == Season.SPRING:
		current_year += 1
	season_changed.emit(current_season, current_year)


func get_season_name() -> String:
	return ["Spring", "Summer", "Fall", "Winter"][current_season]


func get_time_string() -> String:
	var total_minutes := int(time_of_day * 24.0 * 60.0)
	var hour := total_minutes / 60
	var minute := total_minutes % 60
	var suffix := "AM" if hour < 12 else "PM"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minute, suffix]


func set_starting_season(season: Season) -> void:
	current_season = season
