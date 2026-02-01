## Excavation cost and permit system.
##
## Handles the economics of digging underground:
##   - Base cost per cell (increases with depth)
##   - Optional permit requirement for deep excavation
##   - Cost preview for UI display
##
## Cost formula from documentation/game-design/economy/permits.md:
##   excavation_cost = BASE_EXCAVATION × DEPTH_MULTIPLIER[floor]
##
## DEPTH_MULTIPLIER:
##   Y = -1 to -3:   1.0x (easy dig)
##   Y = -4 to -6:   1.5x (moderate dig)
##   Y = -7 to -10:  2.5x (hard dig)
##   Y = -11 to -20: 4.0x (very hard)
##   Y < -20:        6.0x (extreme)

## Base cost per excavated cell (in currency units)
const BASE_EXCAVATION_COST: int = 100

## Depth multipliers by Y level range
const DEPTH_MULTIPLIERS := {
	-3: 1.0,   # Y = -1 to -3
	-6: 1.5,   # Y = -4 to -6
	-10: 2.5,  # Y = -7 to -10
	-20: 4.0,  # Y = -11 to -20
}
const EXTREME_DEPTH_MULTIPLIER: float = 6.0  # Y < -20


static func get_depth_multiplier(y_level: int) -> float:
	## Returns the cost multiplier for a given Y level.
	## Y should be negative (underground).
	if y_level >= 0:
		return 0.0  # Above ground, no excavation cost

	var abs_depth: int = -y_level  # Convert to positive depth

	if abs_depth <= 3:
		return 1.0
	elif abs_depth <= 6:
		return 1.5
	elif abs_depth <= 10:
		return 2.5
	elif abs_depth <= 20:
		return 4.0
	else:
		return EXTREME_DEPTH_MULTIPLIER


static func calculate_excavation_cost(y_level: int) -> int:
	## Returns the cost to excavate one cell at the given Y level.
	var multiplier: float = get_depth_multiplier(y_level)
	return int(float(BASE_EXCAVATION_COST) * multiplier)


static func calculate_total_cost(cells: Array[Vector3i]) -> int:
	## Returns the total cost to excavate multiple cells.
	var total: int = 0
	for cell in cells:
		total += calculate_excavation_cost(cell.y)
	return total


static func get_depth_category(y_level: int) -> String:
	## Returns a human-readable category for the depth.
	if y_level >= 0:
		return "Surface"
	var abs_depth: int = -y_level
	if abs_depth <= 3:
		return "Topsoil"
	elif abs_depth <= 6:
		return "Subsoil"
	elif abs_depth <= 10:
		return "Bedrock"
	elif abs_depth <= 20:
		return "Deep Rock"
	else:
		return "Extreme Depth"


static func format_cost(cost: int) -> String:
	## Formats a cost value for display (with commas).
	var s := str(cost)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return "$" + result


static func get_cost_preview_text(y_level: int) -> String:
	## Returns a formatted string for cost preview display.
	var cost: int = calculate_excavation_cost(y_level)
	var category: String = get_depth_category(y_level)
	var multiplier: float = get_depth_multiplier(y_level)
	return "%s (%s, %.1fx): %s" % [category, "Y=%d" % y_level, multiplier, format_cost(cost)]


# NOTE: Functions that interact with GameState (can_afford, spend, refund)
# are intentionally NOT included here. Use GameState directly in the caller,
# passing calculate_excavation_cost(y_level) as the amount. This avoids
# static function -> autoload reference issues in headless tests.
