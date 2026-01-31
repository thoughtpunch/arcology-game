extends RefCounted
class_name PlacementValidator

## Validates block placement according to structural and gameplay rules
##
## Validation checks:
## 1. Space empty - can't place where a block exists
## 2. Structural support - blocks need support from below or adjacent cantilevers
## 3. Cantilever limit - max 2 cubes horizontal without vertical support
## 4. Prerequisites - some blocks require adjacent infrastructure
## 5. Warnings - non-blocking issues (light blocking, dead ends, etc.)

# Grid reference for checking existing blocks
var grid: Node = null

# BlockRegistry reference for block type properties
var block_registry = null

# ScenarioConfig reference for structural rules
var scenario_config: Resource = null


## Validation result class
class ValidationResult:
	var valid: bool = true
	var reason: String = ""
	var warnings: Array[String] = []

	static func success() -> ValidationResult:
		return ValidationResult.new()

	static func invalid(err_reason: String) -> ValidationResult:
		var result := ValidationResult.new()
		result.valid = false
		result.reason = err_reason
		return result

	static func with_warnings(warning_list: Array[String]) -> ValidationResult:
		var result := ValidationResult.new()
		result.warnings = warning_list
		return result

	func add_warning(warning: String) -> void:
		warnings.append(warning)

	func has_warnings() -> bool:
		return warnings.size() > 0

	func _to_string() -> String:
		if not valid:
			return "Invalid: %s" % reason
		if has_warnings():
			return "Valid with warnings: %s" % ", ".join(warnings)
		return "Valid"


func _init(p_grid: Node = null, p_registry = null, p_scenario_config: Resource = null) -> void:
	grid = p_grid
	block_registry = p_registry
	scenario_config = p_scenario_config


## Validate placement at position for block type
## Returns ValidationResult with valid flag, reason, and warnings
func validate_placement(pos: Vector3i, block_type: String) -> ValidationResult:
	# Run all validation checks in order

	# 1. Space must be empty
	var space_result := _check_space_empty(pos)
	if not space_result.valid:
		return space_result

	# 2. Must have structural support
	var support_result := _check_structural_support(pos, block_type)
	if not support_result.valid:
		return support_result

	# 3. Check cantilever limit
	var cantilever_result := _check_cantilever_limit(pos, block_type)
	if not cantilever_result.valid:
		return cantilever_result

	# 4. Check prerequisites (block-specific requirements)
	var prereq_result := _check_prerequisites(pos, block_type)
	if not prereq_result.valid:
		return prereq_result

	# 5. Check floor constraints (ground_only, etc.)
	var floor_result := _check_floor_constraints(pos, block_type)
	if not floor_result.valid:
		return floor_result

	# 6. Check excavation for underground
	var excavation_result := _check_excavation(pos)
	if not excavation_result.valid:
		return excavation_result

	# Collect warnings (don't block placement)
	var warnings := _collect_warnings(pos, block_type)

	if warnings.size() > 0:
		return ValidationResult.with_warnings(warnings)

	return ValidationResult.success()


# --- Core Validation Checks ---

func _check_space_empty(pos: Vector3i) -> ValidationResult:
	## Check that the target position is not already occupied
	if grid == null:
		return ValidationResult.success()  # Can't check without grid

	if grid.has_block(pos):
		return ValidationResult.invalid("Space is occupied")

	return ValidationResult.success()


func _check_structural_support(pos: Vector3i, block_type: String) -> ValidationResult:
	## Check that the block has structural support
	## Ground level (z=0) is always supported
	## Above ground needs block below or adjacent cantilever support (within limit)
	## If structural_integrity is disabled (via ScenarioConfig), always passes.

	if grid == null:
		return ValidationResult.success()  # Can't check without grid

	# If structural integrity is disabled, skip all support checks
	if scenario_config and scenario_config.has_method("is_within_cantilever_limit"):
		if not scenario_config.structural_integrity:
			return ValidationResult.success()

	# Ground level is always supported
	if pos.z <= 0:
		return ValidationResult.success()

	# Check for block directly below (fully supported)
	var below_pos := pos + Vector3i(0, 0, -1)
	if grid.has_block(below_pos):
		return ValidationResult.success()

	# Get cantilever limit from scenario config or use default
	var max_cant: int = 2
	if scenario_config and "max_cantilever" in scenario_config:
		max_cant = scenario_config.max_cantilever
	# -1 means unlimited cantilever (zero-g)
	if max_cant < 0:
		# Unlimited cantilever - just need any adjacent block
		var horizontal_neighbors: Array[Vector3i] = [
			pos + Vector3i(1, 0, 0),
			pos + Vector3i(-1, 0, 0),
			pos + Vector3i(0, 1, 0),
			pos + Vector3i(0, -1, 0)
		]
		for i in range(horizontal_neighbors.size()):
			var neighbor_pos: Vector3i = horizontal_neighbors[i]
			if grid.has_block(neighbor_pos):
				return ValidationResult.success()
		return ValidationResult.invalid("No adjacent block (zero-g requires connectivity)")

	# Check for cantilever support from adjacent blocks
	# Adjacent blocks can provide support if they have vertical support
	# and we're within cantilever limit
	var horizontal_neighbors: Array[Vector3i] = [
		pos + Vector3i(1, 0, 0),
		pos + Vector3i(-1, 0, 0),
		pos + Vector3i(0, 1, 0),
		pos + Vector3i(0, -1, 0)
	]

	for i in range(horizontal_neighbors.size()):
		var neighbor_pos: Vector3i = horizontal_neighbors[i]
		if grid.has_block(neighbor_pos):
			# Check cantilever depth from this neighbor
			var neighbor_depth := _calculate_cantilever_depth_from(neighbor_pos)
			# If neighbor is within cantilever limit, we can extend from it
			if neighbor_depth < max_cant:
				return ValidationResult.success()

	return ValidationResult.invalid("No structural support")


func _check_cantilever_limit(_pos: Vector3i, _block_type: String) -> ValidationResult:
	## Cantilever limit is now checked in _check_structural_support
	## This function exists for API compatibility
	return ValidationResult.success()


func _check_prerequisites(pos: Vector3i, block_type: String) -> ValidationResult:
	## Check block-specific placement prerequisites
	## e.g., residential blocks need adjacent corridor access

	var block_data := _get_block_data(block_type)
	if block_data.is_empty():
		return ValidationResult.success()

	# Private blocks (residential, commercial) need adjacent public access
	var traversability: String = block_data.get("traversability", "public")
	if traversability == "private":
		if not _has_adjacent_public_block(pos):
			# This is a warning, not a hard block - allow placement but warn
			# Actually, per ticket spec, prerequisites can block - let's make this a warning
			pass  # Will be caught by warnings

	return ValidationResult.success()


func _check_floor_constraints(pos: Vector3i, block_type: String) -> ValidationResult:
	## Check floor-specific constraints (ground_only, max height, ground depth)

	# Check for known ground_only block types (hardcoded fallback)
	const GROUND_ONLY_TYPES: Array[String] = ["entrance"]
	if block_type in GROUND_ONLY_TYPES and pos.z != 0:
		return ValidationResult.invalid("Block can only be placed at ground level")

	var block_data := _get_block_data(block_type)

	# Check ground_only constraint
	if block_data.get("ground_only", false) and pos.z != 0:
		return ValidationResult.invalid("Block can only be placed at ground level")

	# Check minimum floor (ground depth) from scenario config
	var min_floor: int = -3  # Default fallback
	if scenario_config and "ground_depth" in scenario_config:
		min_floor = -scenario_config.ground_depth
	if pos.z < min_floor:
		return ValidationResult.invalid("Below minimum floor level")

	# Check maximum build height from scenario config
	if scenario_config and scenario_config.has_method("is_within_build_height"):
		if not scenario_config.is_within_build_height(pos.z):
			return ValidationResult.invalid("Above maximum build height")

	# Check build zone from scenario config
	if scenario_config and scenario_config.has_method("is_in_build_zone"):
		if not scenario_config.is_in_build_zone(pos):
			return ValidationResult.invalid("Outside build zone")

	return ValidationResult.success()


func _check_excavation(pos: Vector3i) -> ValidationResult:
	## Check if underground position is excavated
	## Grid auto-excavates on placement, so this is mostly a future concern

	# Underground positions that aren't excavated can't have blocks
	# But Grid.set_block auto-excavates, so we'll just check validity
	if grid == null:
		return ValidationResult.success()

	# Grid.can_place_at handles excavation check internally
	# For now, we assume auto-excavation is enabled

	return ValidationResult.success()


# --- Warnings (non-blocking) ---

func _collect_warnings(pos: Vector3i, block_type: String) -> Array[String]:
	## Collect non-blocking warnings about the placement
	var warnings: Array[String] = []

	# Check if block will block natural light to floors below
	if _blocks_light_below(pos):
		warnings.append("Will block natural light to floors below")

	# Check if corridor creates a dead-end
	if _creates_dead_end(pos, block_type):
		warnings.append("Corridor dead-ends here")

	# Check if private block lacks corridor access
	var block_data := _get_block_data(block_type)
	var traversability: String = block_data.get("traversability", "")

	# Fallback: known private block types
	const PRIVATE_TYPES: Array[String] = ["residential_basic", "commercial_basic"]
	if traversability.is_empty() and block_type in PRIVATE_TYPES:
		traversability = "private"

	if traversability == "private" and not _has_adjacent_public_block(pos):
		warnings.append("No adjacent corridor access")

	# Check if far from entrance
	if _is_far_from_entrance(pos):
		warnings.append("Far from entrance")

	return warnings


# --- Helper Methods ---

func _has_vertical_support(pos: Vector3i) -> bool:
	## Check if position has vertical support (block below, or is ground level)
	if pos.z <= 0:
		return true

	var below := pos + Vector3i(0, 0, -1)
	if grid.has_block(below):
		return true

	return false


func _calculate_cantilever_depth_from(pos: Vector3i) -> int:
	## Calculate cantilever depth for an existing block
	## Returns 0 if vertically supported, 1+ if cantilevered
	if grid == null:
		return 0

	if _has_vertical_support(pos):
		return 0

	# Trace back to a supported block
	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{ "pos": pos, "depth": 0 }]
	visited[pos] = true

	var horizontal_offsets: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0)
	]

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector3i = current.pos
		var current_depth: int = current.depth

		if grid.has_block(current_pos) and _has_vertical_support(current_pos):
			return current_depth

		for j in range(horizontal_offsets.size()):
			var offset: Vector3i = horizontal_offsets[j]
			var neighbor: Vector3i = current_pos + offset
			if not visited.has(neighbor):
				visited[neighbor] = true
				if grid.has_block(neighbor):
					queue.append({ "pos": neighbor, "depth": current_depth + 1 })

	return 999  # No support found


func _calculate_cantilever_depth(pos: Vector3i) -> int:
	## Calculate how many blocks this position is cantilevered from support
	## Uses BFS to find shortest path to a vertically-supported block

	if grid == null:
		return 0

	# If this position has vertical support, no cantilever
	if _has_vertical_support(pos):
		return 0

	# BFS to find nearest vertically-supported block at same Z level
	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{ "pos": pos, "depth": 0 }]
	visited[pos] = true

	var horizontal_offsets := [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0)
	]

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector3i = current.pos
		var current_depth: int = current.depth

		# Check if this position has vertical support
		if grid.has_block(current_pos) and _has_vertical_support(current_pos):
			return current_depth

		# Explore horizontal neighbors
		for j in range(horizontal_offsets.size()):
			var offset: Vector3i = horizontal_offsets[j]
			var neighbor: Vector3i = current_pos + offset
			if not visited.has(neighbor):
				visited[neighbor] = true
				if grid.has_block(neighbor):
					queue.append({ "pos": neighbor, "depth": current_depth + 1 })

	# No path to supported block found - this would be a floating block
	return 999  # Very high number indicates no support found


func _has_adjacent_public_block(pos: Vector3i) -> bool:
	## Check if any adjacent block is public (traversable)
	if grid == null:
		return false

	var neighbors := [
		pos + Vector3i(1, 0, 0),
		pos + Vector3i(-1, 0, 0),
		pos + Vector3i(0, 1, 0),
		pos + Vector3i(0, -1, 0)
	]

	for i in range(neighbors.size()):
		var neighbor_pos: Vector3i = neighbors[i]
		var block = grid.get_block_at(neighbor_pos)
		if block:
			if _is_block_public(block):
				return true

	return false


func _is_block_public(block) -> bool:
	## Check if block is public (traversable)
	if block is Object and block.has_method("is_public"):
		return block.is_public()
	if block is Dictionary:
		return block.get("traversability", "private") == "public"

	# Fallback to registry
	var block_type: String = ""
	if block is Object and "block_type" in block:
		block_type = block.block_type
	elif block is Dictionary:
		block_type = block.get("block_type", "")

	if block_type.is_empty():
		return false

	var block_data := _get_block_data(block_type)
	return block_data.get("traversability", "private") == "public"


func _blocks_light_below(pos: Vector3i) -> bool:
	## Check if placing a block here would block light to floors below
	## For now, any block above Z=0 can potentially block light

	# Only above-ground blocks can block light
	if pos.z <= 0:
		return false

	# Check if there are blocks below that might need light
	if grid == null:
		return false

	# Check a few floors below
	for z in range(pos.z - 1, -1, -1):
		var check_pos := Vector3i(pos.x, pos.y, z)
		if grid.has_block(check_pos):
			return true  # There's a block below that might be affected

	return false


func _creates_dead_end(pos: Vector3i, block_type: String) -> bool:
	## Check if placing a corridor here creates a dead-end
	var block_data := _get_block_data(block_type)

	# Only corridors and public blocks can create dead-ends
	var traversability: String = block_data.get("traversability", "private")
	if traversability != "public":
		return false

	# Count adjacent public/traversable blocks
	if grid == null:
		return false

	var public_neighbors := 0
	var neighbors := [
		pos + Vector3i(1, 0, 0),
		pos + Vector3i(-1, 0, 0),
		pos + Vector3i(0, 1, 0),
		pos + Vector3i(0, -1, 0)
	]

	for neighbor_pos in neighbors:
		var block = grid.get_block_at(neighbor_pos)
		if block and _is_block_public(block):
			public_neighbors += 1

	# Dead-end if only 0 or 1 public connections
	return public_neighbors <= 1


func _is_far_from_entrance(pos: Vector3i) -> bool:
	## Check if position is far from any entrance
	if grid == null:
		return false

	var entrances: Array[Vector3i] = grid.get_entrance_positions()
	if entrances.is_empty():
		return true  # No entrances at all

	# Find minimum distance to any entrance
	var min_distance := 999999
	for i in range(entrances.size()):
		var entrance_pos: Vector3i = entrances[i]
		var dist: int = Grid.manhattan_distance(pos, entrance_pos)
		if dist < min_distance:
			min_distance = dist

	# "Far" is more than 15 blocks away
	const FAR_THRESHOLD: int = 15
	return min_distance > FAR_THRESHOLD


func _get_block_data(block_type: String) -> Dictionary:
	## Get block definition from BlockRegistry
	if block_registry:
		if block_registry.has_method("get_block_data"):
			return block_registry.get_block_data(block_type)

	# Try scene tree lookup
	var tree := Engine.get_main_loop()
	if tree and tree.has_method("get_root"):
		var root = tree.get_root()
		if root:
			var registry = root.get_node_or_null("/root/BlockRegistry")
			if registry and registry.has_method("get_block_data"):
				return registry.get_block_data(block_type)

	return {}


# --- Public API ---

func is_valid_placement(pos: Vector3i, block_type: String) -> bool:
	## Quick check if placement is valid (no details)
	var result := validate_placement(pos, block_type)
	return result.valid


func get_placement_state(pos: Vector3i, block_type: String) -> int:
	## Get ghost state for placement (0=valid, 1=warning, 2=invalid)
	## Matches GhostPreview3D.GhostState values
	var result := validate_placement(pos, block_type)

	if not result.valid:
		return 3  # INVALID
	if result.has_warnings():
		return 2  # WARNING
	return 1  # VALID
