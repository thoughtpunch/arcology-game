extends SceneTree
## Unit tests for BlockPicker class
## Tests block type selection, button creation, and keyboard shortcuts

var block_picker: BlockPicker
var selected_types: Array = []


func _init():
	print("Running BlockPicker tests...")

	_test_block_order_constant()
	_test_select_type()
	_test_get_selected_type()
	_test_signal_emission()

	print("All BlockPicker tests passed!")
	quit()


func _on_type_selected(block_type: String):
	selected_types.append(block_type)


func _reset():
	selected_types.clear()


## Test: BLOCK_ORDER constant is properly defined
func _test_block_order_constant():
	print("  Test: BLOCK_ORDER constant...")

	# Verify BLOCK_ORDER has expected entries
	assert(BlockPicker.BLOCK_ORDER.size() == 6, "Should have 6 block types in order")
	assert(BlockPicker.BLOCK_ORDER[0] == "corridor", "First block should be corridor")
	assert(BlockPicker.BLOCK_ORDER[1] == "entrance", "Second block should be entrance")
	assert(BlockPicker.BLOCK_ORDER[2] == "stairs", "Third block should be stairs")
	assert(BlockPicker.BLOCK_ORDER[3] == "elevator_shaft", "Fourth block should be elevator_shaft")
	assert(BlockPicker.BLOCK_ORDER[4] == "residential_basic", "Fifth block should be residential_basic")
	assert(BlockPicker.BLOCK_ORDER[5] == "commercial_basic", "Sixth block should be commercial_basic")

	print("    PASSED")


## Test: select_type changes internal state
func _test_select_type():
	print("  Test: select_type...")

	block_picker = BlockPicker.new()

	# Manually add to _buttons dictionary for testing (simulating button creation)
	# In full integration test, buttons would be created from BlockRegistry
	var mock_button := Button.new()
	mock_button.toggle_mode = true
	block_picker._buttons["corridor"] = mock_button

	var mock_button2 := Button.new()
	mock_button2.toggle_mode = true
	block_picker._buttons["residential_basic"] = mock_button2

	# Select corridor
	block_picker.select_type("corridor")
	assert(block_picker._selected_type == "corridor", "Should select corridor")
	assert(mock_button.button_pressed == true, "Corridor button should be pressed")
	assert(mock_button2.button_pressed == false, "Residential button should not be pressed")

	# Select residential
	block_picker.select_type("residential_basic")
	assert(block_picker._selected_type == "residential_basic", "Should select residential")
	assert(mock_button.button_pressed == false, "Corridor button should not be pressed")
	assert(mock_button2.button_pressed == true, "Residential button should be pressed")

	# Clean up
	mock_button.queue_free()
	mock_button2.queue_free()

	print("    PASSED")


## Test: get_selected_type returns correct value
func _test_get_selected_type():
	print("  Test: get_selected_type...")

	block_picker = BlockPicker.new()

	# Add mock buttons
	var mock_button := Button.new()
	mock_button.toggle_mode = true
	block_picker._buttons["stairs"] = mock_button

	block_picker.select_type("stairs")
	assert(block_picker.get_selected_type() == "stairs", "get_selected_type should return stairs")

	# Clean up
	mock_button.queue_free()

	print("    PASSED")


## Test: Signal emission on selection
func _test_signal_emission():
	print("  Test: Signal emission...")
	_reset()

	block_picker = BlockPicker.new()
	block_picker.block_type_selected.connect(_on_type_selected)

	# Add mock button
	var mock_button := Button.new()
	mock_button.toggle_mode = true
	block_picker._buttons["entrance"] = mock_button

	# Select and verify signal
	block_picker.select_type("entrance")

	assert(selected_types.size() == 1, "Should emit one signal")
	assert(selected_types[0] == "entrance", "Signal should have entrance type")

	# Select again
	block_picker.select_type("entrance")
	assert(selected_types.size() == 2, "Should emit signal even for same type")

	# Clean up
	mock_button.queue_free()

	print("    PASSED")
