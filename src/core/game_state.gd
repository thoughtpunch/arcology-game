extends Node
## GameState singleton - centralized game state management
## Holds floor state, game clock, and other shared state

signal floor_changed(new_floor: int)

# Floor constraints
const MIN_FLOOR: int = 0
const MAX_FLOOR: int = 10

# Current floor state
var current_floor: int = 0


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
