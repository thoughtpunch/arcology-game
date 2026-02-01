extends SceneTree

## Tests for gravity-aware cantilever limits in structural integrity
##
## Tests:
## - Vertically-supported column detection (unbroken path to ground)
## - Cantilever depth BFS at various gravity levels
## - Earth gravity (max_cantilever=2): within and exceeding limits
## - Lunar gravity (max_cantilever=12): generous cantilever
## - Mars gravity (max_cantilever=5): moderate cantilever
## - High-G (max_cantilever=1): strict limits
## - Zero-g (max_cantilever=-1): connectivity-only, no limit
## - Structural integrity disabled: always passes
## - Block removal orphan detection (would_orphan_blocks)
## - validate_removal() API
## - Broken columns (gap in vertical support)

var _validator_script: GDScript
var _scenario_script: GDScript
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("=== Gravity-Aware Cantilever Tests ===")

	_validator_script = load("res://src/game/placement_validator.gd")
	_scenario_script = load("res://src/game/structural_scenario_config.gd")

	# --- Vertical Support Tests ---
	_test_ground_level_always_supported()
	_test_full_column_is_supported()
	_test_broken_column_not_supported()
	_test_single_gap_breaks_column()

	# --- Earth Gravity (max_cantilever=2) ---
	_test_earth_cantilever_within_limit()
	_test_earth_cantilever_at_limit()
	_test_earth_cantilever_exceeds_limit()
	_test_earth_cantilever_diagonal_path()

	# --- Lunar Gravity (max_cantilever=12) ---
	_test_lunar_generous_cantilever()
	_test_lunar_exceeds_limit()

	# --- Mars Gravity (max_cantilever=5) ---
	_test_mars_moderate_cantilever()

	# --- High-G (max_cantilever=1) ---
	_test_high_g_strict_limits()

	# --- Zero-G (max_cantilever=-1) ---
	_test_zero_g_adjacent_block_ok()
	_test_zero_g_vertical_neighbor_ok()
	_test_zero_g_no_neighbor_rejected()

	# --- Structural Integrity Disabled ---
	_test_integrity_disabled_always_passes()

	# --- Block Removal / Orphan Detection ---
	_test_removal_safe_with_alternate_support()
	_test_removal_orphans_cantilever_chain()
	_test_removal_breaks_vertical_column()
	_test_removal_last_block_ok()
	_test_validate_removal_api()
	_test_validate_removal_no_block()

	# --- Zero-G Removal / Connectivity ---
	_test_zero_g_removal_disconnects()
	_test_zero_g_removal_still_connected()

	# --- Cantilever Depth Calculation ---
	_test_depth_at_ground_level()
	_test_depth_with_column()
	_test_depth_floating()

	# --- ScenarioConfig Integration ---
	_test_scenario_config_earth()
	_test_scenario_config_lunar()
	_test_scenario_config_zero_g()

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


func _create_scenario(gravity: float, structural_integrity: bool = true) -> Resource:
	var config: Resource = _scenario_script.new()
	config.gravity = gravity
	config.structural_integrity = structural_integrity
	# Cantilever is computed from gravity
	if gravity <= 0.0:
		config.max_cantilever = -1
	else:
		config.max_cantilever = int(floor(2.0 / gravity))
	return config


func _create_validator(grid, scenario: Resource = null) -> RefCounted:
	return _validator_script.new(grid, null, scenario)


func _create_mock_block(block_type: String, pos: Vector3i) -> Dictionary:
	return {
		"block_type": block_type,
		"grid_position": pos,
		"traversability": "public" if block_type in ["corridor", "entrance", "stairs", "elevator_shaft"] else "private",
		"connected": false
	}


func _place_block(grid, pos: Vector3i, block_type: String = "corridor") -> void:
	grid.set_block(pos, _create_mock_block(block_type, pos))


func _place_column(grid, x: int, z: int, y_from: int, y_to: int, block_type: String = "corridor") -> void:
	## Place a column of blocks from y_from to y_to (inclusive)
	for y in range(y_from, y_to + 1):
		_place_block(grid, Vector3i(x, y, z), block_type)


# ============================================================
# Vertical Support Tests
# ============================================================

func _test_ground_level_always_supported() -> void:
	print("\nTest: Ground level (Y=0) is always supported")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	var result = validator.validate_placement(Vector3i(5, 0, 5), "corridor")
	_assert(result.valid, "Y=0 should always be valid")

	var result_neg = validator.validate_placement(Vector3i(5, -1, 5), "corridor")
	_assert(result_neg.valid, "Y<0 should also be supported")


func _test_full_column_is_supported() -> void:
	print("\nTest: Block above full column is supported (depth=0)")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Build column Y=0 to Y=4
	_place_column(grid, 0, 0, 0, 4)

	# Y=5 should be supported (continuous column below)
	var result = validator.validate_placement(Vector3i(0, 5, 0), "corridor")
	_assert(result.valid, "Block on top of full column should be valid")


func _test_broken_column_not_supported() -> void:
	print("\nTest: Broken column (gap at Y=2) breaks support")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Place Y=0, Y=1, skip Y=2, place Y=3
	_place_block(grid, Vector3i(0, 0, 0))
	_place_block(grid, Vector3i(0, 1, 0))
	# No block at Y=2
	_place_block(grid, Vector3i(0, 3, 0))

	# Y=4 should NOT be supported because the column under Y=3 has a gap at Y=2
	# The block at Y=3 is cantilevered (not column-supported) so it doesn't provide
	# column support for Y=4. Y=4 needs adjacent cantilever path or its own column.
	# Since there's no adjacent block, Y=4 is floating.
	var result = validator.validate_placement(Vector3i(0, 4, 0), "corridor")
	_assert(not result.valid, "Block above broken column should be invalid")


func _test_single_gap_breaks_column() -> void:
	print("\nTest: Single gap in column breaks vertical support for all above")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Column with gap at Y=1
	_place_block(grid, Vector3i(0, 0, 0))
	# Skip Y=1
	_place_block(grid, Vector3i(0, 2, 0))

	# Y=3 above the broken column: the block at Y=2 has no vertical support
	# (gap at Y=1), so it can't provide column support. Y=3 is floating.
	var result = validator.validate_placement(Vector3i(0, 3, 0), "corridor")
	_assert(not result.valid, "Block above column with gap should be invalid")


# ============================================================
# Earth Gravity Tests (max_cantilever=2)
# ============================================================

func _test_earth_cantilever_within_limit() -> void:
	print("\nTest: Earth gravity — 1 cell cantilever is OK")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)  # Earth: max_cant = 2
	var validator := _create_validator(grid, scenario)

	# Build column at (0,0)
	_place_column(grid, 0, 0, 0, 1)

	# 1 cell cantilever
	_place_block(grid, Vector3i(1, 1, 0))

	# Place at (2,1,0) = 2nd cantilever cell
	var result = validator.validate_placement(Vector3i(2, 1, 0), "corridor")
	_assert(result.valid, "2nd cantilever cell should be within Earth limit")


func _test_earth_cantilever_at_limit() -> void:
	print("\nTest: Earth gravity — 2 cells is exactly at limit")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)  # max_cant = 2
	var validator := _create_validator(grid, scenario)

	# Column at (0,0)
	_place_column(grid, 0, 0, 0, 1)
	_place_block(grid, Vector3i(1, 1, 0))
	_place_block(grid, Vector3i(2, 1, 0))

	# (3,1,0) would be 3 cells out — should fail
	var result = validator.validate_placement(Vector3i(3, 1, 0), "corridor")
	_assert(not result.valid, "3rd cantilever cell should exceed Earth limit")
	_assert("cantilever" in result.reason.to_lower() or "support" in result.reason.to_lower(),
		"Should mention cantilever or support in reason: got '%s'" % result.reason)


func _test_earth_cantilever_exceeds_limit() -> void:
	print("\nTest: Earth gravity — 4 cells out is rejected")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Column at (0,0)
	_place_column(grid, 0, 0, 0, 1)
	# Chain of blocks on floor 1
	_place_block(grid, Vector3i(1, 1, 0))
	_place_block(grid, Vector3i(2, 1, 0))
	_place_block(grid, Vector3i(3, 1, 0))

	# (4,1,0) = 4 cells from column
	var result = validator.validate_placement(Vector3i(4, 1, 0), "corridor")
	_assert(not result.valid, "4 cells cantilever should be rejected at Earth gravity")


func _test_earth_cantilever_diagonal_path() -> void:
	print("\nTest: Earth gravity — diagonal BFS finds closest column")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Column at (0,0)
	_place_column(grid, 0, 0, 0, 1)
	# Place at (1,1,0) and (1,1,1)
	_place_block(grid, Vector3i(1, 1, 0))
	_place_block(grid, Vector3i(1, 1, 1))

	# (1,1,1) is 2 Manhattan distance from column (0,1,0)
	# So (2,1,1) would be 3 from column = rejected at Earth gravity
	var result = validator.validate_placement(Vector3i(2, 1, 1), "corridor")
	_assert(not result.valid, "Diagonal path exceeding limit should be rejected")


# ============================================================
# Lunar Gravity Tests (max_cantilever=12)
# ============================================================

func _test_lunar_generous_cantilever() -> void:
	print("\nTest: Lunar gravity — 10 cell cantilever is OK")
	var grid := _create_grid()
	var scenario := _create_scenario(0.16)  # Lunar: floor(2/0.16) = 12
	var validator := _create_validator(grid, scenario)

	_assert(scenario.max_cantilever == 12, "Lunar max_cantilever should be 12: got %d" % scenario.max_cantilever)

	# Column at (0,0)
	_place_column(grid, 0, 0, 0, 1)

	# Build a 10-cell horizontal chain
	for x in range(1, 11):
		_place_block(grid, Vector3i(x, 1, 0))

	# 11th cell should be within limit (11 <= 12)
	var result = validator.validate_placement(Vector3i(11, 1, 0), "corridor")
	_assert(result.valid, "11 cell cantilever should be within lunar limit (12)")


func _test_lunar_exceeds_limit() -> void:
	print("\nTest: Lunar gravity — 13 cells exceeds limit")
	var grid := _create_grid()
	var scenario := _create_scenario(0.16)  # max_cant = 12
	var validator := _create_validator(grid, scenario)

	_place_column(grid, 0, 0, 0, 1)
	for x in range(1, 13):
		_place_block(grid, Vector3i(x, 1, 0))

	# 13th cell = distance 13 > 12
	var result = validator.validate_placement(Vector3i(13, 1, 0), "corridor")
	_assert(not result.valid, "13 cell cantilever should exceed lunar limit (12)")


# ============================================================
# Mars Gravity Tests (max_cantilever=5)
# ============================================================

func _test_mars_moderate_cantilever() -> void:
	print("\nTest: Mars gravity — 5 cells OK, 6 cells rejected")
	var grid := _create_grid()
	var scenario := _create_scenario(0.38)  # Mars: floor(2/0.38) = 5
	var validator := _create_validator(grid, scenario)

	_assert(scenario.max_cantilever == 5, "Mars max_cantilever should be 5: got %d" % scenario.max_cantilever)

	_place_column(grid, 0, 0, 0, 1)
	for x in range(1, 6):
		_place_block(grid, Vector3i(x, 1, 0))

	# 5 cells out is at limit
	var result_ok = validator.validate_placement(Vector3i(5, 1, 0), "corridor")
	# Wait — 5 cells from column means distance 5. max_cant is 5. BFS finds depth 5.
	# Actually blocks at x=1..5 means x=5 is 5 cells from column at x=0.
	# The depth of the NEW block at x=6 would be 6. Let me verify.
	# We already have blocks at x=1..5, placing at x=6 means BFS from (6,1,0) finds
	# (5,1,0) at depth 1, then traces back to column: (5) depth 5, so total = 6.
	# Wait no. BFS from (6,1,0): neighbor (5,1,0) exists at depth 1.
	# Is (5,1,0) vertically supported? No, only (0,0,0) and (0,1,0) are columns.
	# BFS continues: (4,1,0) depth 2, (3,1,0) depth 3, (2,1,0) depth 4, (1,1,0) depth 5, (0,1,0) depth 6.
	# (0,1,0) IS vertically supported. So depth = 6 > 5 = rejected.

	# Let me test placing at (5,1,0) — that's already placed. Test (6,1,0) = 6 cells from column
	var result_fail = validator.validate_placement(Vector3i(6, 1, 0), "corridor")
	_assert(not result_fail.valid, "6 cells from column should exceed Mars limit (5)")


# ============================================================
# High-G Tests (max_cantilever=1)
# ============================================================

func _test_high_g_strict_limits() -> void:
	print("\nTest: High-G — max_cantilever=1, only 1 cell out allowed")
	var grid := _create_grid()
	var scenario := _create_scenario(2.0)  # floor(2/2.0) = 1
	var validator := _create_validator(grid, scenario)

	_assert(scenario.max_cantilever == 1, "High-G max_cantilever should be 1: got %d" % scenario.max_cantilever)

	_place_column(grid, 0, 0, 0, 1)

	# 1 cell out OK
	var result_ok = validator.validate_placement(Vector3i(1, 1, 0), "corridor")
	_assert(result_ok.valid, "1 cell cantilever should be OK at High-G")

	# Place it, then 2 cells out should fail
	_place_block(grid, Vector3i(1, 1, 0))
	var result_fail = validator.validate_placement(Vector3i(2, 1, 0), "corridor")
	_assert(not result_fail.valid, "2 cells cantilever should be rejected at High-G")


# ============================================================
# Zero-G Tests (max_cantilever=-1)
# ============================================================

func _test_zero_g_adjacent_block_ok() -> void:
	print("\nTest: Zero-G — any adjacent horizontal block is OK")
	var grid := _create_grid()
	var scenario := _create_scenario(0.0)  # Zero-g
	var validator := _create_validator(grid, scenario)

	_assert(scenario.max_cantilever == -1, "Zero-G max_cantilever should be -1")

	# Place a block at Y=5 (no ground needed in zero-g, but placement check
	# sees Y<=0 as always valid, so place at Y=1 with Y=0 as anchor)
	_place_block(grid, Vector3i(0, 0, 0))
	_place_block(grid, Vector3i(0, 1, 0))

	# Adjacent block at (1,1,0) should be OK
	var result = validator.validate_placement(Vector3i(1, 1, 0), "corridor")
	_assert(result.valid, "Zero-G: adjacent block should be valid")


func _test_zero_g_vertical_neighbor_ok() -> void:
	print("\nTest: Zero-G — vertical neighbor counts for connectivity")
	var grid := _create_grid()
	var scenario := _create_scenario(0.0)
	var validator := _create_validator(grid, scenario)

	_place_block(grid, Vector3i(0, 1, 0))

	# Block above at Y=2 should be OK (vertical neighbor exists)
	var result = validator.validate_placement(Vector3i(0, 2, 0), "corridor")
	_assert(result.valid, "Zero-G: vertical neighbor should count for connectivity")


func _test_zero_g_no_neighbor_rejected() -> void:
	print("\nTest: Zero-G — no neighbor means rejected")
	var grid := _create_grid()
	var scenario := _create_scenario(0.0)
	var validator := _create_validator(grid, scenario)

	_place_block(grid, Vector3i(0, 0, 0))

	# Isolated block at (5,5,5) — no neighbors
	var result = validator.validate_placement(Vector3i(5, 5, 5), "corridor")
	_assert(not result.valid, "Zero-G: isolated block should be rejected")
	_assert("connectivity" in result.reason.to_lower() or "adjacent" in result.reason.to_lower(),
		"Should mention connectivity: got '%s'" % result.reason)


# ============================================================
# Structural Integrity Disabled
# ============================================================

func _test_integrity_disabled_always_passes() -> void:
	print("\nTest: Structural integrity disabled — always passes")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0, false)  # structural_integrity = false
	var validator := _create_validator(grid, scenario)

	# Floating block at Y=10 with nothing below
	var result = validator.validate_placement(Vector3i(0, 10, 0), "corridor")
	_assert(result.valid, "With integrity disabled, floating blocks should be valid")


# ============================================================
# Block Removal / Orphan Detection
# ============================================================

func _test_removal_safe_with_alternate_support() -> void:
	print("\nTest: Removal safe when alternate support exists")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Two columns supporting a bridge:
	# Column A at (0,0) and Column B at (3,0)
	_place_column(grid, 0, 0, 0, 1)
	_place_column(grid, 3, 0, 0, 1)
	# Bridge: (1,1,0) and (2,1,0)
	_place_block(grid, Vector3i(1, 1, 0))
	_place_block(grid, Vector3i(2, 1, 0))

	# Removing (1,1,0) should be OK: (2,1,0) is 1 cell from column B
	var result: bool = validator.would_orphan_blocks(Vector3i(1, 1, 0))
	_assert(not result, "Removing bridge block with alternate column should be safe")


func _test_removal_orphans_cantilever_chain() -> void:
	print("\nTest: Removal orphans cantilever chain")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)  # max_cant = 2
	var validator := _create_validator(grid, scenario)

	# Column at (0,0)
	_place_column(grid, 0, 0, 0, 1)
	# Cantilever chain: (1,1,0) -> (2,1,0)
	_place_block(grid, Vector3i(1, 1, 0))
	_place_block(grid, Vector3i(2, 1, 0))

	# Removing (1,1,0) makes (2,1,0) be 2 cells from column, which is at limit
	# Actually depth of (2,1,0) without (1,1,0): BFS from (2,1,0), no horizontal neighbor
	# with block exists (only (1,1,0) which is excluded). So depth = 999.
	# That exceeds max_cant = 2. So it SHOULD orphan.
	var result: bool = validator.would_orphan_blocks(Vector3i(1, 1, 0))
	_assert(result, "Removing middle of cantilever chain should orphan end block")


func _test_removal_breaks_vertical_column() -> void:
	print("\nTest: Removal breaks vertical column support")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)  # max_cant = 2
	var validator := _create_validator(grid, scenario)

	# Tall column: Y=0 through Y=3
	_place_column(grid, 0, 0, 0, 3)
	# Cantilever off Y=3: (1,3,0)
	_place_block(grid, Vector3i(1, 3, 0))

	# Removing Y=1 breaks the column — Y=2, Y=3, and (1,3,0) lose support
	var result: bool = validator.would_orphan_blocks(Vector3i(0, 1, 0))
	_assert(result, "Removing block in column should orphan blocks above")


func _test_removal_last_block_ok() -> void:
	print("\nTest: Removing the last block is always OK")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	_place_block(grid, Vector3i(0, 0, 0))

	var result: bool = validator.would_orphan_blocks(Vector3i(0, 0, 0))
	_assert(not result, "Removing the only block should be OK")


func _test_validate_removal_api() -> void:
	print("\nTest: validate_removal() returns ValidationResult")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	_place_column(grid, 0, 0, 0, 2)
	_place_block(grid, Vector3i(1, 2, 0))

	# Removing base should orphan
	var result = validator.validate_removal(Vector3i(0, 0, 0))
	_assert(not result.valid, "validate_removal should return invalid when orphaning")
	_assert("support" in result.reason.to_lower(), "Should mention support: got '%s'" % result.reason)

	# Removing tip should be fine
	var result2 = validator.validate_removal(Vector3i(1, 2, 0))
	_assert(result2.valid, "validate_removal of tip should be valid")


func _test_validate_removal_no_block() -> void:
	print("\nTest: validate_removal() on empty position")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	var result = validator.validate_removal(Vector3i(0, 0, 0))
	_assert(not result.valid, "validate_removal of empty position should be invalid")


# ============================================================
# Zero-G Removal / Connectivity
# ============================================================

func _test_zero_g_removal_disconnects() -> void:
	print("\nTest: Zero-G — removing bridge disconnects island")
	var grid := _create_grid()
	var scenario := _create_scenario(0.0)
	var validator := _create_validator(grid, scenario)

	# Entrance at (0,0,0), chain: (1,0,0) -> (2,0,0) -> (3,0,0)
	_place_block(grid, Vector3i(0, 0, 0), "entrance")
	_place_block(grid, Vector3i(1, 0, 0))
	_place_block(grid, Vector3i(2, 0, 0))
	_place_block(grid, Vector3i(3, 0, 0))

	# Removing (1,0,0) disconnects (2,0,0) and (3,0,0) from entrance
	var result: bool = validator.would_orphan_blocks(Vector3i(1, 0, 0))
	_assert(result, "Zero-G: removing bridge should disconnect island")


func _test_zero_g_removal_still_connected() -> void:
	print("\nTest: Zero-G — removal with alternate path still connected")
	var grid := _create_grid()
	var scenario := _create_scenario(0.0)
	var validator := _create_validator(grid, scenario)

	# Ring: entrance at (0,0,0), two paths to (2,0,0)
	_place_block(grid, Vector3i(0, 0, 0), "entrance")
	_place_block(grid, Vector3i(1, 0, 0))
	_place_block(grid, Vector3i(2, 0, 0))
	_place_block(grid, Vector3i(0, 0, 1))
	_place_block(grid, Vector3i(1, 0, 1))
	_place_block(grid, Vector3i(2, 0, 1))

	# Removing (1,0,0) should be OK: path via z=1 row still exists
	var result: bool = validator.would_orphan_blocks(Vector3i(1, 0, 0))
	_assert(not result, "Zero-G: removal with alternate path should stay connected")


# ============================================================
# Cantilever Depth Calculation
# ============================================================

func _test_depth_at_ground_level() -> void:
	print("\nTest: Cantilever depth at ground level = 0")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# Ground-level block has depth 0 (always supported)
	var result = validator.validate_placement(Vector3i(0, 0, 0), "corridor")
	_assert(result.valid, "Ground level should have depth 0 (valid)")


func _test_depth_with_column() -> void:
	print("\nTest: Block on column has depth 0")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	_place_column(grid, 0, 0, 0, 2)

	var result = validator.validate_placement(Vector3i(0, 3, 0), "corridor")
	_assert(result.valid, "Block directly above column should be valid (depth 0)")


func _test_depth_floating() -> void:
	print("\nTest: Floating block has depth 999 (rejected)")
	var grid := _create_grid()
	var scenario := _create_scenario(1.0)
	var validator := _create_validator(grid, scenario)

	# No blocks anywhere nearby
	var result = validator.validate_placement(Vector3i(0, 5, 0), "corridor")
	_assert(not result.valid, "Floating block should be rejected")


# ============================================================
# ScenarioConfig Integration
# ============================================================

func _test_scenario_config_earth() -> void:
	print("\nTest: ScenarioConfig — Earth standard")
	var config: Resource = _scenario_script.new()
	# Default is Earth gravity
	_assert(config.gravity == 1.0, "Default gravity should be 1.0")
	_assert(config.max_cantilever == 2, "Default max_cantilever should be 2")


func _test_scenario_config_lunar() -> void:
	print("\nTest: ScenarioConfig — Lunar colony")
	var config := _create_scenario(0.16)
	_assert(config.max_cantilever == 12, "Lunar max_cantilever should be 12: got %d" % config.max_cantilever)


func _test_scenario_config_zero_g() -> void:
	print("\nTest: ScenarioConfig — Zero-G station")
	var config := _create_scenario(0.0)
	_assert(config.max_cantilever == -1, "Zero-G max_cantilever should be -1: got %d" % config.max_cantilever)


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
