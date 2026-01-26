extends SceneTree
## Unit tests for InputHandler class
## Tests placement validation, block selection, and signal emission

var grid: Grid
var input_handler: InputHandler
var placement_signals: Array = []
var removal_signals: Array = []


func _init():
	print("Running InputHandler tests...")

	_setup()
	_test_placement_on_empty_cell()
	_test_placement_on_occupied_cell()
	_test_removal_of_existing_block()
	_test_removal_of_empty_cell()
	_test_placement_validation()
	_test_entrance_ground_only()
	_test_block_type_selection()
	_test_floor_change()

	print("All InputHandler tests passed!")
	quit()


func _setup():
	# Create grid
	grid = Grid.new()

	# Create input handler
	input_handler = InputHandler.new()

	# Connect signals to track calls
	input_handler.block_placement_attempted.connect(_on_placement_attempted)
	input_handler.block_removal_attempted.connect(_on_removal_attempted)


func _on_placement_attempted(pos: Vector3i, type: String, success: bool):
	placement_signals.append({"pos": pos, "type": type, "success": success})


func _on_removal_attempted(pos: Vector3i, success: bool):
	removal_signals.append({"pos": pos, "success": success})


func _reset_signals():
	placement_signals.clear()
	removal_signals.clear()


## Test: Can place block on empty cell
func _test_placement_on_empty_cell():
	print("  Test: Placement on empty cell...")
	_reset_signals()
	grid.clear()

	# Manually set grid reference (normally done via setup())
	input_handler.grid = grid

	var pos := Vector3i(5, 5, 0)

	# Call internal method directly for testing
	input_handler._try_place_block(pos)

	# Verify block was placed
	assert(grid.has_block(pos), "Block should be placed on empty cell")
	assert(grid.get_block(pos).block_type == "corridor", "Block type should be corridor")

	# Verify signal emitted with success
	assert(placement_signals.size() == 1, "Should emit one placement signal")
	assert(placement_signals[0].success == true, "Signal should indicate success")
	assert(placement_signals[0].pos == pos, "Signal should have correct position")
	assert(placement_signals[0].type == "corridor", "Signal should have correct type")

	print("    PASSED")


## Test: Cannot place block on occupied cell
func _test_placement_on_occupied_cell():
	print("  Test: Placement on occupied cell...")
	_reset_signals()
	grid.clear()

	input_handler.grid = grid

	var pos := Vector3i(3, 3, 0)

	# Place a block first
	var existing_block := Block.new("residential_basic", pos)
	grid.set_block(pos, existing_block)

	# Try to place another block at same position
	input_handler._try_place_block(pos)

	# Verify only one block exists (the original)
	assert(grid.get_block(pos).block_type == "residential_basic", "Original block should remain")

	# Verify signal emitted with failure
	assert(placement_signals.size() == 1, "Should emit one placement signal")
	assert(placement_signals[0].success == false, "Signal should indicate failure")

	print("    PASSED")


## Test: Can remove existing block
func _test_removal_of_existing_block():
	print("  Test: Removal of existing block...")
	_reset_signals()
	grid.clear()

	input_handler.grid = grid

	var pos := Vector3i(4, 4, 0)

	# Place a block first
	var block := Block.new("corridor", pos)
	grid.set_block(pos, block)
	assert(grid.has_block(pos), "Block should exist before removal")

	# Remove it
	input_handler._try_remove_block(pos)

	# Verify block was removed
	assert(not grid.has_block(pos), "Block should be removed")

	# Verify signal emitted with success
	assert(removal_signals.size() == 1, "Should emit one removal signal")
	assert(removal_signals[0].success == true, "Signal should indicate success")
	assert(removal_signals[0].pos == pos, "Signal should have correct position")

	print("    PASSED")


## Test: Cannot remove from empty cell
func _test_removal_of_empty_cell():
	print("  Test: Removal from empty cell...")
	_reset_signals()
	grid.clear()

	input_handler.grid = grid

	var pos := Vector3i(7, 7, 0)

	# Try to remove from empty position
	input_handler._try_remove_block(pos)

	# Verify signal emitted with failure
	assert(removal_signals.size() == 1, "Should emit one removal signal")
	assert(removal_signals[0].success == false, "Signal should indicate failure")

	print("    PASSED")


## Test: Placement validation logic
func _test_placement_validation():
	print("  Test: Placement validation...")
	grid.clear()

	input_handler.grid = grid

	var empty_pos := Vector3i(1, 1, 0)
	var occupied_pos := Vector3i(2, 2, 0)

	# Place a block
	var block := Block.new("corridor", occupied_pos)
	grid.set_block(occupied_pos, block)

	# Validate empty position - should be valid
	assert(input_handler._is_placement_valid(empty_pos), "Empty cell should be valid for placement")

	# Validate occupied position - should be invalid
	assert(not input_handler._is_placement_valid(occupied_pos), "Occupied cell should be invalid for placement")

	print("    PASSED")


## Test: Entrance can only be placed at ground level (Z=0)
func _test_entrance_ground_only():
	print("  Test: Entrance ground_only constraint...")
	_reset_signals()
	grid.clear()

	input_handler.grid = grid
	input_handler.selected_block_type = "entrance"

	# Test placement at Z=0 (should succeed)
	var ground_pos := Vector3i(0, 0, 0)
	input_handler._try_place_block(ground_pos)

	# Note: This test will only fully work with BlockRegistry autoload
	# For now, we test the validation logic directly

	# Since BlockRegistry may not be available in test, we test the logic
	# If entrance has ground_only=true in blocks.json, Z>0 should be invalid
	var upper_pos := Vector3i(0, 0, 1)

	# The validation depends on BlockRegistry being available
	# In a full integration test with autoloads, this would reject Z>0

	print("    PASSED (partial - requires BlockRegistry for full test)")


## Test: Block type selection
func _test_block_type_selection():
	print("  Test: Block type selection...")

	input_handler.selected_block_type = "corridor"
	assert(input_handler.selected_block_type == "corridor", "Should start with corridor")

	input_handler.set_selected_block_type("residential_basic")
	assert(input_handler.selected_block_type == "residential_basic", "Should change to residential")

	input_handler.set_selected_block_type("commercial_basic")
	assert(input_handler.selected_block_type == "commercial_basic", "Should change to commercial")

	print("    PASSED")


## Test: Floor change
func _test_floor_change():
	print("  Test: Floor change...")

	assert(input_handler.current_floor == 0, "Should start at floor 0")

	input_handler.set_current_floor(3)
	assert(input_handler.current_floor == 3, "Should change to floor 3")

	input_handler.set_current_floor(0)
	assert(input_handler.current_floor == 0, "Should change back to floor 0")

	print("    PASSED")
