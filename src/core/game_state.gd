extends Node
## GameState singleton - centralized game state management
## Holds floor state, game clock, and other shared state

signal floor_changed(new_floor: int)
signal time_changed(year: int, month: int, day: int, hour: int)
signal speed_changed(speed: int)
signal paused_changed(paused: bool)

# Floor constraints
const MIN_FLOOR: int = 0
const MAX_FLOOR: int = 10

# Time constants
const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12
const HOURS_PER_DAY: int = 24

# Speed multipliers (real seconds per game hour)
const SPEED_NORMAL: float = 2.0  # 1 game day = 48 real seconds
const SPEED_FAST: float = 1.0    # 1 game day = 24 real seconds
const SPEED_FASTEST: float = 0.5 # 1 game day = 12 real seconds

# Current floor state
var current_floor: int = 0

# Game clock state
var year: int = 1
var month: int = 1
var day: int = 1
var hour: int = 8  # Start at 8 AM

# Time control state
var game_speed: int = 1  # 0=paused, 1=normal, 2=fast, 3=fastest
var paused: bool = false

# Internal time tracking
var _time_accumulator: float = 0.0


## Change the current floor, clamped to valid range
func set_floor(floor_num: int) -> void:
	var new_floor := clampi(floor_num, MIN_FLOOR, MAX_FLOOR)
	if new_floor != current_floor:
		current_floor = new_floor
		floor_changed.emit(current_floor)


## Go up one floor
func floor_up() -> void:
	set_floor(current_floor + 1)


## Go down one floor
func floor_down() -> void:
	set_floor(current_floor - 1)


## Check if can go up
func can_go_up() -> bool:
	return current_floor < MAX_FLOOR


## Check if can go down
func can_go_down() -> bool:
	return current_floor > MIN_FLOOR


## Process game time each frame
func _process(delta: float) -> void:
	if paused or game_speed == 0:
		return

	# Calculate time progression based on speed
	var seconds_per_hour: float = _get_seconds_per_hour()
	_time_accumulator += delta

	# Advance hours as needed
	while _time_accumulator >= seconds_per_hour:
		_time_accumulator -= seconds_per_hour
		_advance_hour()


## Get seconds per game hour based on current speed
func _get_seconds_per_hour() -> float:
	match game_speed:
		1: return SPEED_NORMAL
		2: return SPEED_FAST
		3: return SPEED_FASTEST
		_: return SPEED_NORMAL


## Advance time by one hour
func _advance_hour() -> void:
	hour += 1

	if hour >= HOURS_PER_DAY:
		hour = 0
		_advance_day()

	time_changed.emit(year, month, day, hour)


## Advance time by one day
func _advance_day() -> void:
	day += 1

	if day > DAYS_PER_MONTH:
		day = 1
		_advance_month()


## Advance time by one month
func _advance_month() -> void:
	month += 1

	if month > MONTHS_PER_YEAR:
		month = 1
		year += 1


## Set game speed (0=paused, 1=normal, 2=fast, 3=fastest)
func set_game_speed(speed: int) -> void:
	var new_speed := clampi(speed, 0, 3)
	if new_speed != game_speed:
		game_speed = new_speed

		# Handle pause state
		if game_speed == 0:
			paused = true
			paused_changed.emit(true)
		elif paused:
			paused = false
			paused_changed.emit(false)

		speed_changed.emit(game_speed)


## Toggle pause state
func toggle_pause() -> void:
	if paused:
		# Unpause - restore to speed 1 if was at 0
		paused = false
		if game_speed == 0:
			game_speed = 1
		paused_changed.emit(false)
		speed_changed.emit(game_speed)
	else:
		# Pause
		paused = true
		paused_changed.emit(true)


## Check if game is paused
func is_paused() -> bool:
	return paused


## Get current time as dictionary
func get_time() -> Dictionary:
	return {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour
	}


## Get time of day as string (morning/afternoon/evening/night)
func get_time_of_day() -> String:
	if hour >= 6 and hour < 12:
		return "morning"
	elif hour >= 12 and hour < 18:
		return "afternoon"
	elif hour >= 18 and hour < 22:
		return "evening"
	else:
		return "night"


## Get time of day icon
func get_time_of_day_icon() -> String:
	match get_time_of_day():
		"morning": return "🌅"
		"afternoon": return "☀️"
		"evening": return "🌆"
		"night": return "🌙"
		_: return "☀️"


## Get formatted date string
func get_date_string() -> String:
	return "Y%d M%d D%d" % [year, month, day]


## Set time directly (for loading saves)
func set_time(p_year: int, p_month: int, p_day: int, p_hour: int = 8) -> void:
	year = maxi(1, p_year)
	month = clampi(p_month, 1, MONTHS_PER_YEAR)
	day = clampi(p_day, 1, DAYS_PER_MONTH)
	hour = clampi(p_hour, 0, HOURS_PER_DAY - 1)
	_time_accumulator = 0.0
	time_changed.emit(year, month, day, hour)
