extends Node
## GameState singleton - centralized game state management
## Holds floor state, game clock, economy, and sandbox flags

signal floor_changed(new_floor: int)
signal time_changed(year: int, month: int, day: int, hour: int)
signal speed_changed(speed: int)
signal paused_changed(paused: bool)
signal money_changed(new_amount: int)
signal config_applied(config: Dictionary)

# Floor constraints
const MIN_FLOOR: int = -3  # Allow basement levels
const MAX_FLOOR: int = 10

# Time constants
const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12
const HOURS_PER_DAY: int = 24

# Speed multipliers (real seconds per game hour)
const SPEED_NORMAL: float = 2.0  # 1 game day = 48 real seconds
const SPEED_FAST: float = 1.0    # 1 game day = 24 real seconds
const SPEED_FASTEST: float = 0.5 # 1 game day = 12 real seconds

# Entropy rate mappings
const ENTROPY_RATES := {
	"Fast": 1.5,
	"Normal": 1.0,
	"Slow": 0.5
}

# Resident patience mappings
const PATIENCE_RATES := {
	"Impatient": 0.5,
	"Normal": 1.0,
	"Patient": 2.0
}

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

# Arcology identity
var arcology_name: String = "New Arcology"
var scenario: String = "fresh_start"

# Economy
var money: int = 50000
var population: int = 0
var aei_score: float = 0.0  # Arcology Excellence Index

# Gameplay multipliers
var entropy_multiplier: float = 1.0
var resident_patience_multiplier: float = 1.0

# Gameplay toggles
var disasters_enabled: bool = true

# Sandbox flags
var unlimited_money: bool = false
var instant_construction: bool = false
var all_blocks_unlocked: bool = false
var disable_failures: bool = false

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


# --- Economy ---

## Add or remove money. Returns false if insufficient funds (and not unlimited).
func add_money(amount: int) -> bool:
	if amount < 0 and not unlimited_money:
		if money + amount < 0:
			return false
	money += amount
	if money < 0 and not unlimited_money:
		money = 0
	money_changed.emit(money)
	return true


## Spend money. Returns false if insufficient funds (unless unlimited).
func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if unlimited_money:
		money_changed.emit(money)
		return true
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false


## Check if can afford amount
func can_afford(amount: int) -> bool:
	return unlimited_money or money >= amount


## Get current money
func get_money() -> int:
	return money


# --- New Game Config ---

## Apply configuration from NewGameMenu
## Called when starting a new game
func apply_new_game_config(config: Dictionary) -> void:
	# Reset time to start
	reset_time()

	# Arcology identity
	scenario = config.get("scenario", "fresh_start")
	arcology_name = config.get("name", "New Arcology")

	# Starting funds
	var funds_setting: Variant = config.get("starting_funds", 50000)
	if funds_setting is String:
		# Parse from dropdown format: "$50,000 (Normal)"
		money = _parse_funds_string(funds_setting)
	else:
		money = int(funds_setting)
	money_changed.emit(money)

	# Entropy rate
	var entropy_setting: Variant = config.get("entropy_rate", "Normal")
	if entropy_setting is String:
		entropy_multiplier = ENTROPY_RATES.get(entropy_setting, 1.0)
	else:
		entropy_multiplier = float(entropy_setting)

	# Resident patience
	var patience_setting: Variant = config.get("resident_patience", "Normal")
	if patience_setting is String:
		resident_patience_multiplier = PATIENCE_RATES.get(patience_setting, 1.0)
	else:
		resident_patience_multiplier = float(patience_setting)

	# Disasters
	disasters_enabled = config.get("disasters", true)

	# Sandbox flags
	unlimited_money = config.get("unlimited_money", false)
	instant_construction = config.get("instant_construction", false)
	all_blocks_unlocked = config.get("all_blocks_unlocked", false)
	disable_failures = config.get("disable_failures", false)

	# Reset other state
	population = 0
	aei_score = 0.0
	current_floor = 0

	print("GameState: Applied config - %s, $%d, entropy=%.1fx, patience=%.1fx" % [
		arcology_name, money, entropy_multiplier, resident_patience_multiplier
	])
	print("GameState: Sandbox - unlimited=$%s, instant=%s, unlocked=%s, no_fail=%s" % [
		unlimited_money, instant_construction, all_blocks_unlocked, disable_failures
	])

	config_applied.emit(config)


## Parse funds string like "$25,000 (Hard)" to integer
func _parse_funds_string(funds_str: String) -> int:
	# Extract just the number part
	var num_str := ""
	for c in funds_str:
		if c.is_valid_int() or c == ",":
			if c != ",":
				num_str += c
	if num_str.is_empty():
		return 50000
	return int(num_str)


## Reset time to game start
func reset_time() -> void:
	year = 1
	month = 1
	day = 1
	hour = 8
	_time_accumulator = 0.0
	time_changed.emit(year, month, day, hour)


## Reset all state to defaults (for new game)
func reset_all() -> void:
	reset_time()
	current_floor = 0
	money = 50000
	population = 0
	aei_score = 0.0
	arcology_name = "New Arcology"
	scenario = "fresh_start"
	entropy_multiplier = 1.0
	resident_patience_multiplier = 1.0
	disasters_enabled = true
	unlimited_money = false
	instant_construction = false
	all_blocks_unlocked = false
	disable_failures = false
	game_speed = 1
	paused = false
	floor_changed.emit(current_floor)
	money_changed.emit(money)


## Get full state as dictionary (for saving)
func get_state() -> Dictionary:
	return {
		"arcology_name": arcology_name,
		"scenario": scenario,
		"money": money,
		"population": population,
		"aei_score": aei_score,
		"current_floor": current_floor,
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"game_speed": game_speed,
		"entropy_multiplier": entropy_multiplier,
		"resident_patience_multiplier": resident_patience_multiplier,
		"disasters_enabled": disasters_enabled,
		"unlimited_money": unlimited_money,
		"instant_construction": instant_construction,
		"all_blocks_unlocked": all_blocks_unlocked,
		"disable_failures": disable_failures
	}


## Load state from dictionary (for loading saves)
func load_state(state: Dictionary) -> void:
	arcology_name = state.get("arcology_name", "New Arcology")
	scenario = state.get("scenario", "fresh_start")
	money = state.get("money", 50000)
	population = state.get("population", 0)
	aei_score = state.get("aei_score", 0.0)
	current_floor = state.get("current_floor", 0)
	year = state.get("year", 1)
	month = state.get("month", 1)
	day = state.get("day", 1)
	hour = state.get("hour", 8)
	game_speed = state.get("game_speed", 1)
	entropy_multiplier = state.get("entropy_multiplier", 1.0)
	resident_patience_multiplier = state.get("resident_patience_multiplier", 1.0)
	disasters_enabled = state.get("disasters_enabled", true)
	unlimited_money = state.get("unlimited_money", false)
	instant_construction = state.get("instant_construction", false)
	all_blocks_unlocked = state.get("all_blocks_unlocked", false)
	disable_failures = state.get("disable_failures", false)
	_time_accumulator = 0.0

	# Emit signals
	floor_changed.emit(current_floor)
	money_changed.emit(money)
	time_changed.emit(year, month, day, hour)
	speed_changed.emit(game_speed)
