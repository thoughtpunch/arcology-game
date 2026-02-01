class_name PlacementValidator
extends RefCounted

## Validates block placement according to structural and gameplay rules.
##
## Structural model: Every cell must be within max_cantilever horizontal
## (Manhattan) distance of a vertically-supported column — an unbroken path
## of blocks down to ground (Y <= 0). max_cantilever = floor(BASE_CANTILEVER / gravity).
## At zero-g (gravity=0), no cantilever limit but blocks must connect to an anchor.
##
## Validation checks:
## 1. Space empty - can't place where a block exists
## 2. Structural support - gravity-aware cantilever BFS
## 3. Cantilever limit - max_cantilever cells from a supported column
## 4. Prerequisites - some blocks require adjacent infrastructure
## 5. Warnings - non-blocking issues (light blocking, dead ends, etc.)

const BASE_CANTILEVER: int = 2

# Shared horizontal offsets for BFS
const _HORIZONTAL_OFFSETS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)
]

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


func _check_structural_support(pos: Vector3i, _block_type: String) -> ValidationResult:
	## Check that the block has structural support using gravity-aware cantilever BFS.
	##
	## Every cell must be within max_cantilever horizontal (Manhattan) distance of a
	## vertically-supported column (unbroken path down to ground).
	## max_cantilever = floor(BASE_CANTILEVER / gravity).
	## At zero-g, unlimited cantilever but must connect to an anchor (any existing block).
	## If structural_integrity is disabled (via ScenarioConfig), always passes.

	if grid == null:
		return ValidationResult.success()  # Can't check without grid

	# If structural integrity is disabled, skip all support checks
	if scenario_config and scenario_config.has_method("is_within_cantilever_limit"):
		if not scenario_config.structural_integrity:
			return ValidationResult.success()

	# Ground level is always supported
	if pos.y <= 0:
		return ValidationResult.success()

	var max_cant: int = _get_max_cantilever()

	# -1 means unlimited cantilever (zero-g)
	if max_cant < 0:
		# Zero-g: just need any adjacent block (connectivity to anchor)
		for i in range(_HORIZONTAL_OFFSETS.size()):
			var neighbor_pos: Vector3i = pos + _HORIZONTAL_OFFSETS[i]
			if grid.has_block(neighbor_pos):
				return ValidationResult.success()
		# Also check above and below for zero-g connectivity
		if grid.has_block(pos + Vector3i(0, 1, 0)) or grid.has_block(pos + Vector3i(0, -1, 0)):
			return ValidationResult.success()
		return ValidationResult.invalid("No adjacent block (zero-g requires connectivity)")

	# Calculate the cantilever depth this position would have
	# (treating pos as if a block were already there for the purpose of checking)
	var depth: int = _calculate_cantilever_depth(pos)
	if depth <= max_cant:
		return ValidationResult.success()

	return ValidationResult.invalid("Exceeds cantilever limit (%d > %d)" % [depth, max_cant])


func _check_cantilever_limit(_pos: Vector3i, _block_type: String) -> ValidationResult:
	## Cantilever limit is now checked in _check_structural_support
	## This function exists for API compatibility
	return ValidationResult.success()


func _check_prerequisites(pos: Vector3i, block_type: String) -> ValidationResult:
	## Check block-specific placement prerequisites.
	## Blocking checks: requires_roof, requires_deep.
	## Non-blocking (warnings): private blocks without corridor access.

	var block_data := _get_block_data(block_type)
	if block_data.is_empty():
		return ValidationResult.success()

	# requires_roof: block needs sky exposure (no block directly above)
	if block_data.get("requires_roof", false):
		if grid and grid.has_block(pos + Vector3i(0, 1, 0)):
			return ValidationResult.invalid("Requires roof/sky exposure (block above)")

	# requires_deep: block must be underground (Y < 0)
	if block_data.get("requires_deep", false):
		if pos.y >= 0:
			return ValidationResult.invalid("Must be placed underground")

	return ValidationResult.success()


func _check_floor_constraints(pos: Vector3i, block_type: String) -> ValidationResult:
	## Check floor-specific constraints (ground_only, max height, ground depth)

	# Check for known ground_only block types (hardcoded fallback)
	const GROUND_ONLY_TYPES: Array[String] = ["entrance"]
	if block_type in GROUND_ONLY_TYPES and pos.y != 0:
		return ValidationResult.invalid("Block can only be placed at ground level")

	var block_data := _get_block_data(block_type)

	# Check ground_only constraint
	if block_data.get("ground_only", false) and pos.y != 0:
		return ValidationResult.invalid("Block can only be placed at ground level")

	# Check minimum floor (ground depth) from scenario config
	var min_floor: int = -3  # Default fallback
	if scenario_config and "ground_depth" in scenario_config:
		min_floor = -scenario_config.ground_depth
	if pos.y < min_floor:
		return ValidationResult.invalid("Below minimum floor level")

	# Check maximum build height from scenario config
	if scenario_config and scenario_config.has_method("is_within_build_height"):
		if not scenario_config.is_within_build_height(pos.y):
			return ValidationResult.invalid("Above maximum build height")

	# Check build zone from scenario config
	if scenario_config and scenario_config.has_method("is_in_build_zone"):
		if not scenario_config.is_in_build_zone(pos):
			return ValidationResult.invalid("Outside build zone")

	return ValidationResult.success()


func _check_excavation(_pos: Vector3i) -> ValidationResult:
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

	# Check if at cantilever limit (valid but structurally risky)
	if _is_at_cantilever_limit(pos):
		warnings.append("At cantilever limit — no further extension possible")

	# Check if far from utilities (power, water, HVAC)
	# Only for block categories that consume utilities
	var category: String = block_data.get("category", "")
	const NEEDS_UTILITIES: Array[String] = ["residential", "commercial", "civic", "entertainment"]
	if category in NEEDS_UTILITIES and _is_far_from_utilities(pos):
		warnings.append("Far from utilities")

	return warnings


# --- Helper Methods ---


func _has_vertical_support(pos: Vector3i) -> bool:
	## Check if position has a vertically-supported column: an unbroken chain
	## of occupied cells from pos down to ground (Y <= 0).
	## Ground level and below are always considered supported.
	if pos.y <= 0:
		return true

	# Trace downward — every cell from Y-1 down to Y=0 must be occupied
	for check_y in range(pos.y - 1, -1, -1):
		if not grid.has_block(Vector3i(pos.x, check_y, pos.z)):
			return false

	return true


func _get_max_cantilever() -> int:
	## Get max cantilever distance from scenario config or compute from gravity.
	## Returns -1 for zero-g (unlimited).
	if scenario_config:
		if "max_cantilever" in scenario_config:
			return scenario_config.max_cantilever
		if "gravity" in scenario_config:
			var grav: float = scenario_config.gravity
			if grav <= 0.0:
				return -1
			return int(floor(float(BASE_CANTILEVER) / grav))
	return BASE_CANTILEVER  # Default: Earth gravity


func _calculate_cantilever_depth(pos: Vector3i) -> int:
	## Calculate the shortest horizontal (Manhattan) distance from pos to the
	## nearest vertically-supported column at the same Y level.
	## Uses BFS outward through occupied horizontal neighbors.
	## Returns 0 if pos itself is vertically supported, 999 if no support found.
	##
	## "Vertically supported" means an unbroken column of blocks from that
	## position down to ground (Y <= 0).

	if grid == null:
		return 0

	# Ground level and below are always supported (no cantilever)
	if pos.y <= 0:
		return 0

	# If this position has its own vertical support, depth is 0
	if _has_vertical_support(pos):
		return 0

	# BFS outward through horizontal neighbors to find nearest supported column
	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{"pos": pos, "depth": 0}]
	visited[pos] = true

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector3i = current.pos
		var current_depth: int = current.depth

		# If this occupied position has vertical support, return the distance
		if current_depth > 0 and grid.has_block(current_pos) and _has_vertical_support(current_pos):
			return current_depth

		# Explore horizontal neighbors (same Y level only)
		for j in range(_HORIZONTAL_OFFSETS.size()):
			var offset: Vector3i = _HORIZONTAL_OFFSETS[j]
			var neighbor: Vector3i = current_pos + offset
			if not visited.has(neighbor):
				visited[neighbor] = true
				if grid.has_block(neighbor):
					queue.append({"pos": neighbor, "depth": current_depth + 1})

	return 999  # No support path found


func _calculate_cantilever_depth_excluding(pos: Vector3i, excluded_pos: Vector3i) -> int:
	## Same as _calculate_cantilever_depth but pretends excluded_pos doesn't exist.
	## Used for checking what would happen if a block at excluded_pos were removed.

	if grid == null:
		return 0

	if pos.y <= 0:
		return 0

	# Check vertical support, but skip excluded_pos in the column
	if _has_vertical_support_excluding(pos, excluded_pos):
		return 0

	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{"pos": pos, "depth": 0}]
	visited[pos] = true
	visited[excluded_pos] = true  # Pretend excluded doesn't exist

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector3i = current.pos
		var current_depth: int = current.depth

		if (
			current_depth > 0
			and grid.has_block(current_pos)
			and _has_vertical_support_excluding(current_pos, excluded_pos)
		):
			return current_depth

		for j in range(_HORIZONTAL_OFFSETS.size()):
			var offset: Vector3i = _HORIZONTAL_OFFSETS[j]
			var neighbor: Vector3i = current_pos + offset
			if not visited.has(neighbor):
				visited[neighbor] = true
				if grid.has_block(neighbor):
					queue.append({"pos": neighbor, "depth": current_depth + 1})

	return 999


func _has_vertical_support_excluding(pos: Vector3i, excluded_pos: Vector3i) -> bool:
	## Check vertical support but pretend excluded_pos doesn't exist.
	if pos.y <= 0:
		return true

	for check_y in range(pos.y - 1, -1, -1):
		var check_pos := Vector3i(pos.x, check_y, pos.z)
		if check_pos == excluded_pos:
			return false
		if not grid.has_block(check_pos):
			return false

	return true


func _has_adjacent_public_block(pos: Vector3i) -> bool:
	## Check if any adjacent block is public (traversable)
	if grid == null:
		return false

	var neighbors := [
		pos + Vector3i(1, 0, 0),
		pos + Vector3i(-1, 0, 0),
		pos + Vector3i(0, 0, 1),
		pos + Vector3i(0, 0, -1)
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
	## For now, any block above Y=0 can potentially block light

	# Only above-ground blocks can block light
	if pos.y <= 0:
		return false

	# Check if there are blocks below that might need light
	if grid == null:
		return false

	# Check a few floors below
	for y in range(pos.y - 1, -1, -1):
		var check_pos := Vector3i(pos.x, y, pos.z)
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
		pos + Vector3i(0, 0, 1),
		pos + Vector3i(0, 0, -1)
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


func _is_at_cantilever_limit(pos: Vector3i) -> bool:
	## Check if placement is at the exact cantilever limit (valid but risky —
	## no further horizontal extension will be possible from this position).
	if grid == null:
		return false

	# Only relevant above ground
	if pos.y <= 0:
		return false

	var max_cant: int = _get_max_cantilever()
	if max_cant < 0:
		return false  # Zero-g: no cantilever limit

	var depth: int = _calculate_cantilever_depth(pos)
	return depth == max_cant


func _is_far_from_utilities(pos: Vector3i) -> bool:
	## Check if position is far from infrastructure blocks (power, water, HVAC).
	## Infrastructure blocks have category "infrastructure" in blocks.json.
	if grid == null:
		return false

	# Only warn for blocks that actually need utilities (residential, commercial, civic)
	# Transit and infrastructure blocks themselves don't need this check
	const NEEDS_UTILITIES: Array[String] = ["residential", "commercial", "civic", "entertainment"]
	# We'll check the block being placed later, for now scan the grid

	# Search for nearby infrastructure blocks within a threshold
	const UTILITY_THRESHOLD: int = 10
	var all_positions: Array = grid.get_all_positions()

	for i in range(all_positions.size()):
		var check_pos: Vector3i = all_positions[i]
		var dist: int = Grid.manhattan_distance(pos, check_pos)
		if dist > UTILITY_THRESHOLD:
			continue

		var block = grid.get_block_at(check_pos)
		if block == null:
			continue

		var category: String = ""
		if block is Dictionary:
			category = block.get("category", "")
		elif block is Object and "category" in block:
			category = block.category
		else:
			# Try to look up via block_type
			var bt: String = ""
			if block is Dictionary:
				bt = block.get("block_type", "")
			elif block is Object and "block_type" in block:
				bt = block.block_type
			if not bt.is_empty():
				var bd := _get_block_data(bt)
				category = bd.get("category", "")

		if category == "infrastructure":
			return false  # Found a nearby utility

	# No infrastructure blocks found nearby
	return true


func _get_block_data(block_type: String) -> Dictionary:
	## Get block definition from BlockRegistry.
	## Supports both core registry (get_block_data -> Dictionary) and
	## Phase 0 registry (get_definition -> Resource).
	if block_registry:
		if block_registry.has_method("get_block_data"):
			return block_registry.get_block_data(block_type)
		if block_registry.has_method("get_definition"):
			var def = block_registry.get_definition(block_type)
			if def:
				return _resource_to_block_data(def)

	# Try scene tree lookup
	var tree := Engine.get_main_loop()
	if tree and tree.has_method("get_root"):
		var root = tree.get_root()
		if root:
			var registry = root.get_node_or_null("/root/BlockRegistry")
			if registry and registry.has_method("get_block_data"):
				return registry.get_block_data(block_type)

	return {}


func _resource_to_block_data(def: Resource) -> Dictionary:
	## Convert a Phase 0 BlockDefinition Resource to a dictionary
	## compatible with the core validator's expected format.
	var data: Dictionary = {}
	if "traversability" in def:
		data["traversability"] = def.traversability
	if "ground_only" in def:
		data["ground_only"] = def.ground_only
	if "category" in def:
		data["category"] = def.category
	if "id" in def:
		data["block_type"] = def.id
	return data


# --- Public API ---


func validate_multi_cell_placement(cells: Array[Vector3i], block_type: String) -> ValidationResult:
	## Validate placement of a multi-cell block.
	## All cells are checked for space/floor constraints.
	## Cantilever BFS treats ALL cells as hypothetically occupied.
	if cells.is_empty():
		return ValidationResult.invalid("No cells to place")

	var block_data := _get_block_data(block_type)

	# Check each cell for basic constraints
	for cell in cells:
		# Space must be empty
		var space_result := _check_space_empty(cell)
		if not space_result.valid:
			return space_result

		# Floor constraints (ground_only, min/max height, build zone)
		var floor_result := _check_floor_constraints(cell, block_type)
		if not floor_result.valid:
			return floor_result

	# Structural support: at least one cell must pass cantilever check
	# treating all cells of this block as hypothetically occupied
	if grid != null:
		# If structural integrity is disabled, skip
		if scenario_config and scenario_config.has_method("is_within_cantilever_limit"):
			if not scenario_config.structural_integrity:
				return ValidationResult.success()

		# All cells at or below ground are always supported
		var all_at_ground := true
		for cell in cells:
			if cell.y > 0:
				all_at_ground = false
				break
		if all_at_ground:
			return ValidationResult.success()

		var max_cant: int = _get_max_cantilever()

		# Zero-g: need adjacency to existing block
		if max_cant < 0:
			for cell in cells:
				for i in range(_HORIZONTAL_OFFSETS.size()):
					var neighbor: Vector3i = cell + _HORIZONTAL_OFFSETS[i]
					if neighbor not in cells and grid.has_block(neighbor):
						return ValidationResult.success()
				if grid.has_block(cell + Vector3i(0, 1, 0)) or grid.has_block(cell + Vector3i(0, -1, 0)):
					var above: Vector3i = cell + Vector3i(0, 1, 0)
					var below: Vector3i = cell + Vector3i(0, -1, 0)
					if (above not in cells and grid.has_block(above)) or (below not in cells and grid.has_block(below)):
						return ValidationResult.success()
			return ValidationResult.invalid("No adjacent block (zero-g requires connectivity)")

		# Normal gravity: every cell must be within cantilever limit,
		# treating all cells of this block as hypothetically occupied
		for cell in cells:
			if cell.y <= 0:
				continue
			var depth: int = _calculate_cantilever_depth_with_hypothetical(cell, cells)
			if depth > max_cant:
				return ValidationResult.invalid(
					"Exceeds cantilever limit (%d > %d) at %s" % [depth, max_cant, cell]
				)

	# Collect warnings from first cell (representative)
	var warnings := _collect_warnings(cells[0], block_type)
	if warnings.size() > 0:
		return ValidationResult.with_warnings(warnings)

	return ValidationResult.success()


func _calculate_cantilever_depth_with_hypothetical(pos: Vector3i, hypothetical: Array[Vector3i]) -> int:
	## Like _calculate_cantilever_depth but treats hypothetical positions as occupied.
	if grid == null:
		return 0
	if pos.y <= 0:
		return 0
	if _has_vertical_support_with_hypothetical(pos, hypothetical):
		return 0

	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{"pos": pos, "depth": 0}]
	visited[pos] = true

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_pos: Vector3i = current.pos
		var current_depth: int = current.depth

		if current_depth > 0:
			var occupied: bool = grid.has_block(current_pos) or current_pos in hypothetical
			if occupied and _has_vertical_support_with_hypothetical(current_pos, hypothetical):
				return current_depth

		for j in range(_HORIZONTAL_OFFSETS.size()):
			var offset: Vector3i = _HORIZONTAL_OFFSETS[j]
			var neighbor: Vector3i = current_pos + offset
			if not visited.has(neighbor):
				visited[neighbor] = true
				if grid.has_block(neighbor) or neighbor in hypothetical:
					queue.append({"pos": neighbor, "depth": current_depth + 1})

	return 999


func _has_vertical_support_with_hypothetical(pos: Vector3i, hypothetical: Array[Vector3i]) -> bool:
	## Check vertical support treating hypothetical positions as occupied.
	if pos.y <= 0:
		return true
	for check_y in range(pos.y - 1, -1, -1):
		var check_pos := Vector3i(pos.x, check_y, pos.z)
		if not grid.has_block(check_pos) and check_pos not in hypothetical:
			return false
	return true


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


func would_orphan_blocks(pos: Vector3i) -> bool:
	## Check if removing the block at pos would cause any remaining block to
	## exceed its cantilever limit. Returns true if removal should be rejected.
	##
	## For zero-g: checks that all remaining blocks stay connected to an anchor.
	## For normal gravity: checks cantilever distance from supported columns.

	if grid == null:
		return false

	if not grid.has_block(pos):
		return false

	# If structural integrity is disabled, removal never orphans
	if scenario_config and scenario_config.has_method("is_within_cantilever_limit"):
		if not scenario_config.structural_integrity:
			return false

	var max_cant: int = _get_max_cantilever()

	# Zero-g: check connectivity (all blocks must remain connected to anchor)
	if max_cant < 0:
		return _would_disconnect_from_anchor(pos)

	# Normal gravity: check that no remaining block exceeds cantilever limit
	# Only need to check blocks on the same Y level and blocks directly above
	# that might have relied on pos for their column support.
	var affected_positions: Array[Vector3i] = _get_structurally_dependent_positions(pos)

	for i in range(affected_positions.size()):
		var check_pos: Vector3i = affected_positions[i]
		if check_pos == pos:
			continue
		var new_depth: int = _calculate_cantilever_depth_excluding(check_pos, pos)
		if new_depth > max_cant:
			return true

	return false


func validate_removal(pos: Vector3i) -> ValidationResult:
	## Validate whether removing the block at pos is safe.
	## Returns invalid if removal would orphan other blocks.

	if grid == null:
		return ValidationResult.success()

	if not grid.has_block(pos):
		return ValidationResult.invalid("No block to remove")

	if would_orphan_blocks(pos):
		return ValidationResult.invalid("Removal would leave blocks without structural support")

	return ValidationResult.success()


func _would_disconnect_from_anchor(removal_pos: Vector3i) -> bool:
	## Zero-g check: would removing removal_pos disconnect any block from
	## the anchor network? Uses BFS from all entrances, skipping removal_pos.
	## Returns true if any block would be disconnected.

	if grid == null:
		return false

	var all_positions: Array = grid.get_all_positions()
	if all_positions.size() <= 1:
		return false  # Removing the last block is always OK

	# Get entrance/anchor positions
	var entrances: Array[Vector3i] = grid.get_entrance_positions()
	if entrances.is_empty():
		return false  # No anchors — can't check connectivity

	# BFS from all entrances, excluding removal_pos
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []

	for entrance_pos in entrances:
		if entrance_pos != removal_pos and grid.has_block(entrance_pos):
			queue.append(entrance_pos)
			visited[entrance_pos] = true

	var all_offsets: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0)
	]

	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		for j in range(all_offsets.size()):
			var neighbor: Vector3i = current + all_offsets[j]
			if not visited.has(neighbor) and neighbor != removal_pos and grid.has_block(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	# Check if all blocks (except the one being removed) are reachable
	for i in range(all_positions.size()):
		var block_pos: Vector3i = all_positions[i]
		if block_pos != removal_pos and not visited.has(block_pos):
			return true  # Found a block that would be disconnected

	return false


func _get_structurally_dependent_positions(removal_pos: Vector3i) -> Array[Vector3i]:
	## Get all positions that might be structurally affected by removing
	## the block at removal_pos. Includes:
	## - Horizontal neighbors on the same floor (cantilever chain)
	## - All blocks above this column (vertical support chain)
	## - Horizontal neighbors of blocks above (their cantilever chains)

	var affected: Array[Vector3i] = []
	var checked: Dictionary = {}

	# 1. Horizontal neighbors on same floor
	for j in range(_HORIZONTAL_OFFSETS.size()):
		var neighbor: Vector3i = removal_pos + _HORIZONTAL_OFFSETS[j]
		if grid.has_block(neighbor) and not checked.has(neighbor):
			affected.append(neighbor)
			checked[neighbor] = true

	# 2. All blocks directly above in the column, and their horizontal neighbors
	var y: int = removal_pos.y + 1
	var max_y: int = removal_pos.y + 100  # Safety limit
	while y <= max_y:
		var above_pos := Vector3i(removal_pos.x, y, removal_pos.z)
		if not grid.has_block(above_pos):
			break  # Column ends here
		if not checked.has(above_pos):
			affected.append(above_pos)
			checked[above_pos] = true
		# Horizontal neighbors of each block above
		for j in range(_HORIZONTAL_OFFSETS.size()):
			var h_neighbor: Vector3i = above_pos + _HORIZONTAL_OFFSETS[j]
			if grid.has_block(h_neighbor) and not checked.has(h_neighbor):
				affected.append(h_neighbor)
				checked[h_neighbor] = true
		y += 1

	# 3. BFS outward from already-affected positions to find cantilever chains
	# that might depend on the removed block's column
	var bfs_queue: Array[Vector3i] = affected.duplicate()
	while not bfs_queue.is_empty():
		var current: Vector3i = bfs_queue.pop_front()
		for j in range(_HORIZONTAL_OFFSETS.size()):
			var neighbor: Vector3i = current + _HORIZONTAL_OFFSETS[j]
			if not checked.has(neighbor) and grid.has_block(neighbor):
				# Only expand into positions that don't have their own vertical support
				# (excluding the removal position)
				if not _has_vertical_support_excluding(neighbor, removal_pos):
					affected.append(neighbor)
					checked[neighbor] = true
					bfs_queue.append(neighbor)

	return affected
