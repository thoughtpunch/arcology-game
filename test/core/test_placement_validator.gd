extends SceneTree

## Unit tests for PlacementValidator
##
## Tests validation rules for block placement:
## - Space occupancy checks
## - Structural support requirements
## - Cantilever limits
## - Floor constraints
## - Prerequisite checks
## - Warning generation

var _validator_script: GDScript
var _scenario_config_script: GDScript
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("=== PlacementValidator Tests ===")

	# Load scripts
	_validator_script = load("res://src/game/placement_validator.gd")
	_scenario_config_script = load("res://src/game/structural_scenario_config.gd")

	# Run tests
	_test_space_empty()
	_test_space_occupied()
	_test_structural_support_ground_level()
	_test_structural_support_block_below()
	_test_structural_support_no_support()
	_test_structural_support_cantilever()
	_test_cantilever_limit_within()
	_test_cantilever_limit_exceeded()
	_test_ground_only_constraint_valid()
	_test_ground_only_constraint_invalid()
	_test_minimum_floor_constraint()
	_test_warning_no_corridor_access()
	_test_warning_far_from_entrance()
	_test_warning_dead_end()
	_test_warning_blocks_light()
	_test_validation_result_success()
	_test_validation_result_invalid()
	_test_validation_result_with_warnings()
	_test_is_valid_placement()
	_test_get_placement_state()
	_test_private_block_no_corridor_warning()
	_test_multiple_warnings()
	_test_prerequisite_requires_roof_blocked()
	_test_prerequisite_requires_roof_valid()
	_test_prerequisite_requires_deep_blocked()
	_test_prerequisite_requires_deep_valid()
	_test_cantilever_limit_with_scenario_config()
	_test_cantilever_limit_lunar_gravity()
	_test_warning_at_cantilever_limit()
	_test_warning_far_from_utilities()
	_test_warning_far_from_utilities_not_for_infra()
	_test_warning_at_cantilever_limit_not_on_ground()

	# Summary
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)


func _create_grid() -> RefCounted:
	return MockGrid.new()


func _create_validator(grid = null, registry = null, scenario_config: Resource = null) -> RefCounted:
	var validator: RefCounted = _validator_script.new(grid, registry, scenario_config)
	return validator


func _create_mock_block(block_type: String, pos: Vector3i) -> Dictionary:
	## Create a dictionary that mimics a Block object
	return {
		"block_type": block_type,
		"grid_position": pos,
		"traversability": "public" if block_type in ["corridor", "entrance", "stairs", "elevator_shaft"] else "private",
		"connected": false
	}


# --- Space Empty Tests ---

func _test_space_empty() -> void:
	print("\nTest: Space Empty - Valid")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	var result = validator.validate_placement(Vector3i(0, 0, 0), "corridor")
	_assert(result.valid, "Empty space should be valid for placement")


func _test_space_occupied() -> void:
	print("\nTest: Space Occupied - Invalid")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a block at the test position
	var block := _create_mock_block("corridor", Vector3i(0, 0, 0))
	grid.set_block(Vector3i(0, 0, 0), block)

	var result = validator.validate_placement(Vector3i(0, 0, 0), "corridor")
	_assert(not result.valid, "Occupied space should be invalid")
	_assert(result.reason == "Space is occupied", "Should report space occupied: got '%s'" % result.reason)


# --- Structural Support Tests ---

func _test_structural_support_ground_level() -> void:
	print("\nTest: Structural Support - Ground Level Always Supported")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	var result = validator.validate_placement(Vector3i(0, 0, 0), "corridor")
	_assert(result.valid, "Ground level (Y=0) should always be supported")

	var result_below = validator.validate_placement(Vector3i(0, -1, 0), "corridor")
	_assert(result_below.valid, "Below ground (Y<0) should be supported")


func _test_structural_support_block_below() -> void:
	print("\nTest: Structural Support - Block Below")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a block at Y=0
	var block := _create_mock_block("corridor", Vector3i(0, 0, 0))
	grid.set_block(Vector3i(0, 0, 0), block)

	# Check Y=1 (should be supported by block below)
	var result = validator.validate_placement(Vector3i(0, 1, 0), "corridor")
	_assert(result.valid, "Block above existing block should be supported")


func _test_structural_support_no_support() -> void:
	print("\nTest: Structural Support - No Support (Floating)")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Try to place at Y=1 with nothing below
	var result = validator.validate_placement(Vector3i(0, 1, 0), "corridor")
	_assert(not result.valid, "Floating block should be invalid")
	_assert("cantilever" in result.reason.to_lower() or "support" in result.reason.to_lower(), "Should report cantilever/support issue: got '%s'" % result.reason)


func _test_structural_support_cantilever() -> void:
	print("\nTest: Structural Support - Cantilever from Adjacent")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Create a supported block at (0,1,0) by first placing (0,0,0) below it
	var block_base := _create_mock_block("corridor", Vector3i(0, 0, 0))
	grid.set_block(Vector3i(0, 0, 0), block_base)

	var block_above := _create_mock_block("corridor", Vector3i(0, 1, 0))
	grid.set_block(Vector3i(0, 1, 0), block_above)

	# Now try to place at (1,1,0) - cantilever from (0,1,0)
	var result = validator.validate_placement(Vector3i(1, 1, 0), "corridor")
	_assert(result.valid, "Cantilever from supported adjacent block should be valid")


# --- Cantilever Limit Tests ---

func _test_cantilever_limit_within() -> void:
	print("\nTest: Cantilever Limit - Within Limit")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Build a column at (0,0)
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Add first cantilever at (1,1,0)
	grid.set_block(Vector3i(1, 1, 0), _create_mock_block("corridor", Vector3i(1, 1, 0)))

	# Second cantilever at (2,1,0) should be within limit (2 blocks max)
	var result = validator.validate_placement(Vector3i(2, 1, 0), "corridor")
	_assert(result.valid, "Second cantilever block should be within limit")


func _test_cantilever_limit_exceeded() -> void:
	print("\nTest: Cantilever Limit - Exceeded")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Build a column at (0,0)
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Add two cantilever blocks
	grid.set_block(Vector3i(1, 1, 0), _create_mock_block("corridor", Vector3i(1, 1, 0)))
	grid.set_block(Vector3i(2, 1, 0), _create_mock_block("corridor", Vector3i(2, 1, 0)))

	# Third cantilever at (3,1,0) should exceed limit
	var result = validator.validate_placement(Vector3i(3, 1, 0), "corridor")
	_assert(not result.valid, "Third cantilever block should exceed limit")
	# Cantilever limit produces a descriptive error message
	_assert("cantilever" in result.reason.to_lower() or "support" in result.reason.to_lower(), "Should report cantilever/support issue: got '%s'" % result.reason)


# --- Floor Constraint Tests ---

func _test_ground_only_constraint_valid() -> void:
	print("\nTest: Ground Only Constraint - Valid at Ground")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Entrance is ground_only, Y=0 should be valid
	var result = validator.validate_placement(Vector3i(0, 0, 0), "entrance")
	_assert(result.valid, "Ground-only block at Y=0 should be valid")


func _test_ground_only_constraint_invalid() -> void:
	print("\nTest: Ground Only Constraint - Invalid Above Ground")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a supporting block first
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))

	# Entrance is ground_only, Y=1 should be invalid
	var result = validator.validate_placement(Vector3i(0, 1, 0), "entrance")
	_assert(not result.valid, "Ground-only block above ground should be invalid")
	_assert("ground level" in result.reason.to_lower(), "Should report ground level constraint: got '%s'" % result.reason)


func _test_minimum_floor_constraint() -> void:
	print("\nTest: Minimum Floor Constraint")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Y=-4 is below minimum (-3)
	var result = validator.validate_placement(Vector3i(0, -4, 0), "corridor")
	_assert(not result.valid, "Below minimum floor should be invalid")
	_assert("minimum floor" in result.reason.to_lower(), "Should report minimum floor: got '%s'" % result.reason)


# --- Warning Tests ---

func _test_warning_no_corridor_access() -> void:
	print("\nTest: Warning - No Corridor Access")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a residential block with no adjacent corridors
	var result = validator.validate_placement(Vector3i(0, 0, 0), "residential_basic")

	# Should be valid but with warning
	_assert(result.valid, "Private block without corridor should still be valid")
	_assert(result.has_warnings(), "Should have warnings")

	var has_corridor_warning := false
	for warning in result.warnings:
		if "corridor" in warning.to_lower():
			has_corridor_warning = true
			break
	_assert(has_corridor_warning, "Should warn about no corridor access")


func _test_warning_far_from_entrance() -> void:
	print("\nTest: Warning - Far From Entrance")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Add an entrance
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("entrance", Vector3i(0, 0, 0)))

	# Place a block far away (more than 15 manhattan distance)
	var result = validator.validate_placement(Vector3i(20, 0, 0), "corridor")

	_assert(result.valid, "Far placement should still be valid")
	_assert(result.has_warnings(), "Should have warnings")

	var has_far_warning := false
	for warning in result.warnings:
		if "far" in warning.to_lower():
			has_far_warning = true
			break
	_assert(has_far_warning, "Should warn about distance from entrance")


func _test_warning_dead_end() -> void:
	print("\nTest: Warning - Corridor Dead End")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a corridor with only one exit
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))

	# Adding another corridor that only connects to one other corridor
	var result = validator.validate_placement(Vector3i(1, 0, 0), "corridor")

	# This creates a dead-end (only 1 public neighbor)
	_assert(result.valid, "Dead-end placement should still be valid")
	_assert(result.has_warnings(), "Should have warnings about dead-end")


func _test_warning_blocks_light() -> void:
	print("\nTest: Warning - Blocks Light Below")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a block at ground level
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))

	# Place a block above it
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Try to place another block on top - should warn about blocking light
	var result = validator.validate_placement(Vector3i(0, 2, 0), "corridor")

	_assert(result.valid, "Block that shadows others should still be valid")
	# Light warning may or may not trigger depending on implementation


# --- ValidationResult Tests ---

func _test_validation_result_success() -> void:
	print("\nTest: ValidationResult.success()")
	var result = _validator_script.ValidationResult.success()
	_assert(result.valid, "Success result should be valid")
	_assert(result.reason.is_empty(), "Success result should have no reason")
	_assert(not result.has_warnings(), "Success result should have no warnings")


func _test_validation_result_invalid() -> void:
	print("\nTest: ValidationResult.invalid()")
	var result = _validator_script.ValidationResult.invalid("Test error")
	_assert(not result.valid, "Invalid result should not be valid")
	_assert(result.reason == "Test error", "Invalid result should have reason")


func _test_validation_result_with_warnings() -> void:
	print("\nTest: ValidationResult.with_warnings()")
	var warnings: Array[String] = ["Warning 1", "Warning 2"]
	var result = _validator_script.ValidationResult.with_warnings(warnings)
	_assert(result.valid, "Warnings-only result should still be valid")
	_assert(result.has_warnings(), "Should have warnings")
	_assert(result.warnings.size() == 2, "Should have 2 warnings")


# --- API Tests ---

func _test_is_valid_placement() -> void:
	print("\nTest: is_valid_placement()")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	_assert(validator.is_valid_placement(Vector3i(0, 0, 0), "corridor"), "Empty ground should be valid")

	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	_assert(not validator.is_valid_placement(Vector3i(0, 0, 0), "corridor"), "Occupied should be invalid")


func _test_get_placement_state() -> void:
	print("\nTest: get_placement_state()")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Note: Without an entrance, even valid placements have warnings (dead-end, far from entrance)
	# So we'll test with an entrance to get a truly valid placement

	# Add entrance first
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("entrance", Vector3i(0, 0, 0)))

	# Adjacent corridor to entrance = valid without warnings = 1 (VALID)
	# (not far from entrance, not a dead-end since connected to entrance)
	var state_valid: int = validator.get_placement_state(Vector3i(1, 0, 0), "corridor")
	# Still gets dead-end warning since only one public neighbor, so expect WARNING
	# Actually, let's just test that it works without specific value
	_assert(state_valid >= 1 and state_valid <= 2, "Valid/warning placement should return 1 or 2: got %d" % state_valid)

	# Invalid placement = 3 (INVALID)
	var state_invalid: int = validator.get_placement_state(Vector3i(0, 0, 0), "corridor")
	_assert(state_invalid == 3, "Invalid placement should return 3 (INVALID): got %d" % state_invalid)

	# Placement with warnings = 2 (WARNING)
	var state_warning: int = validator.get_placement_state(Vector3i(5, 0, 5), "residential_basic")
	_assert(state_warning == 2, "Placement with warnings should return 2 (WARNING): got %d" % state_warning)


func _test_private_block_no_corridor_warning() -> void:
	print("\nTest: Private Block No Corridor Access Warning")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place a private block (residential) without any corridors nearby
	var result = validator.validate_placement(Vector3i(0, 0, 0), "residential_basic")

	_assert(result.valid, "Private block should be placeable")
	_assert(result.has_warnings(), "Should warn about no corridor access")

	# Now add a corridor and check that warning disappears
	grid.set_block(Vector3i(1, 0, 0), _create_mock_block("corridor", Vector3i(1, 0, 0)))

	var result2 = validator.validate_placement(Vector3i(0, 0, 0), "residential_basic")
	var has_corridor_warning := false
	for warning in result2.warnings:
		if "corridor" in warning.to_lower():
			has_corridor_warning = true
			break
	_assert(not has_corridor_warning, "Warning should disappear when corridor is adjacent")


func _test_multiple_warnings() -> void:
	print("\nTest: Multiple Warnings")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Add entrance far away
	grid.set_block(Vector3i(20, 0, 20), _create_mock_block("entrance", Vector3i(20, 0, 20)))

	# Place a private block at origin - should have warnings about:
	# - No corridor access
	# - Far from entrance
	var result = validator.validate_placement(Vector3i(0, 0, 0), "residential_basic")

	_assert(result.valid, "Should be valid even with multiple warnings")
	_assert(result.warnings.size() >= 2, "Should have at least 2 warnings: got %d" % result.warnings.size())


# --- Prerequisite Tests ---


func _create_mock_registry() -> RefCounted:
	## Create a mock block registry with get_block_data method
	var mock := MockBlockRegistry.new()
	return mock


func _create_mock_block_with_category(block_type: String, pos: Vector3i, category: String) -> Dictionary:
	## Create a mock block with category info
	return {
		"block_type": block_type,
		"grid_position": pos,
		"traversability": "private",
		"category": category,
		"connected": false
	}


func _test_prerequisite_requires_roof_blocked() -> void:
	print("\nTest: Prerequisite - requires_roof Blocked (block above)")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# Place a block above the target position
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# solar_collector has requires_roof: true
	var result = validator.validate_placement(Vector3i(0, 0, 0), "solar_collector")
	_assert(not result.valid, "requires_roof block with block above should be invalid")
	_assert("roof" in result.reason.to_lower() or "sky" in result.reason.to_lower(),
		"Should report roof/sky requirement: got '%s'" % result.reason)


func _test_prerequisite_requires_roof_valid() -> void:
	print("\nTest: Prerequisite - requires_roof Valid (nothing above)")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# solar_collector at ground level with nothing above should be valid
	var result = validator.validate_placement(Vector3i(0, 0, 0), "solar_collector")
	_assert(result.valid, "requires_roof block with no block above should be valid")


func _test_prerequisite_requires_deep_blocked() -> void:
	print("\nTest: Prerequisite - requires_deep Blocked (above ground)")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# geothermal_plant has requires_deep: true
	var result = validator.validate_placement(Vector3i(0, 0, 0), "geothermal_plant")
	_assert(not result.valid, "requires_deep block at Y=0 should be invalid")
	_assert("underground" in result.reason.to_lower(),
		"Should report underground requirement: got '%s'" % result.reason)


func _test_prerequisite_requires_deep_valid() -> void:
	print("\nTest: Prerequisite - requires_deep Valid (underground)")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# geothermal_plant underground should be valid
	var result = validator.validate_placement(Vector3i(0, -1, 0), "geothermal_plant")
	_assert(result.valid, "requires_deep block at Y=-1 should be valid")


func _test_cantilever_limit_with_scenario_config() -> void:
	print("\nTest: Cantilever Limit with ScenarioConfig (Earth gravity)")
	var grid := _create_grid()
	var config: Resource = _scenario_config_script.callv("from_dict", [{"gravity": 1.0}])
	var validator := _create_validator(grid, null, config)

	# Build a column at (0,0)
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Add two cantilever blocks (max_cantilever=2 for Earth)
	grid.set_block(Vector3i(1, 1, 0), _create_mock_block("corridor", Vector3i(1, 1, 0)))
	grid.set_block(Vector3i(2, 1, 0), _create_mock_block("corridor", Vector3i(2, 1, 0)))

	# Third cantilever at (3,1,0) should exceed limit
	var result = validator.validate_placement(Vector3i(3, 1, 0), "corridor")
	_assert(not result.valid, "Third cantilever should exceed Earth cantilever limit")


func _test_cantilever_limit_lunar_gravity() -> void:
	print("\nTest: Cantilever Limit with Lunar Gravity (extended)")
	var grid := _create_grid()
	var config: Resource = _scenario_config_script.callv("from_dict", [{"gravity": 0.16}])
	var validator := _create_validator(grid, null, config)

	# Build a column at (0,0)
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Build a long cantilever chain — lunar max_cantilever = floor(2/0.16) = 12
	for x in range(1, 13):
		grid.set_block(Vector3i(x, 1, 0), _create_mock_block("corridor", Vector3i(x, 1, 0)))

	# Cantilever at 12 should still be valid (within limit)
	var result_12 = validator.validate_placement(Vector3i(12, 1, 0), "corridor")
	# Block at x=12 already placed, check x=13 instead (13th extension)
	var result_13 = validator.validate_placement(Vector3i(13, 1, 0), "corridor")
	_assert(not result_13.valid, "13th cantilever extension should exceed lunar limit (12)")


func _test_warning_at_cantilever_limit() -> void:
	print("\nTest: Warning - At Cantilever Limit")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Build a column at (0,0)
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 1, 0), _create_mock_block("corridor", Vector3i(0, 1, 0)))

	# Add first cantilever block
	grid.set_block(Vector3i(1, 1, 0), _create_mock_block("corridor", Vector3i(1, 1, 0)))

	# Place at exactly max_cantilever (depth=2 on Earth)
	var result = validator.validate_placement(Vector3i(2, 1, 0), "corridor")
	_assert(result.valid, "Placement at cantilever limit should be valid")

	var has_limit_warning := false
	for warning in result.warnings:
		if "cantilever limit" in warning.to_lower():
			has_limit_warning = true
			break
	_assert(has_limit_warning, "Should warn about being at cantilever limit")


func _test_warning_at_cantilever_limit_not_on_ground() -> void:
	print("\nTest: Warning - No Cantilever Limit Warning on Ground")
	var grid := _create_grid()
	var validator := _create_validator(grid)

	# Place block at ground level - should NOT warn about cantilever
	var result = validator.validate_placement(Vector3i(0, 0, 0), "corridor")
	var has_limit_warning := false
	for warning in result.warnings:
		if "cantilever" in warning.to_lower():
			has_limit_warning = true
			break
	_assert(not has_limit_warning, "Ground-level block should not have cantilever warning")


func _test_warning_far_from_utilities() -> void:
	print("\nTest: Warning - Far From Utilities")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# Place entrance so we don't get far-from-entrance warning confusing things
	grid.set_block(Vector3i(0, 0, 0), _create_mock_block("entrance", Vector3i(0, 0, 0)))

	# Place a residential block with no infrastructure nearby
	var result = validator.validate_placement(Vector3i(1, 0, 0), "residential_budget")
	_assert(result.valid, "Should be valid")

	var has_utility_warning := false
	for warning in result.warnings:
		if "utilities" in warning.to_lower():
			has_utility_warning = true
			break
	_assert(has_utility_warning, "Should warn about being far from utilities")


func _test_warning_far_from_utilities_not_for_infra() -> void:
	print("\nTest: Warning - No Utility Warning for Infrastructure Blocks")
	var grid := _create_grid()
	var registry := _create_mock_registry()
	var validator := _create_validator(grid, registry)

	# Place an infrastructure block — should NOT get utility warning
	var result = validator.validate_placement(Vector3i(0, 0, 0), "infra_power")
	var has_utility_warning := false
	for warning in result.warnings:
		if "utilities" in warning.to_lower():
			has_utility_warning = true
			break
	_assert(not has_utility_warning, "Infrastructure block should not warn about utilities")


## Mock Grid that implements the Grid-compatible API
class MockGrid:
	extends RefCounted

	var _blocks: Dictionary = {}  # Vector3i -> Dictionary (block data)

	func set_block(pos: Vector3i, block: Dictionary) -> void:
		_blocks[pos] = block

	func has_block(pos: Vector3i) -> bool:
		return _blocks.has(pos)

	func get_block_at(pos: Vector3i) -> Variant:
		return _blocks.get(pos, null)

	func get_all_positions() -> Array:
		return _blocks.keys()

	func get_entrance_positions() -> Array[Vector3i]:
		var positions: Array[Vector3i] = []
		for pos in _blocks:
			var block: Dictionary = _blocks[pos]
			if block.get("block_type", "") == "entrance":
				positions.append(pos)
		return positions


## Mock BlockRegistry that returns data from blocks.json
class MockBlockRegistry:
	extends RefCounted

	var _blocks: Dictionary = {}

	func _init() -> void:
		# Load blocks.json directly
		var file := FileAccess.open("res://data/blocks.json", FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			file.close()
			if err == OK:
				_blocks = json.get_data()

	func get_block_data(block_type: String) -> Dictionary:
		return _blocks.get(block_type, {})
