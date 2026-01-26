extends SceneTree
## Integration tests for BuildToolbar with InputHandler and BlockRegistry

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== Build Toolbar Integration Tests ===")

	# Run all tests
	test_toolbar_loads_blocks_from_registry()
	test_block_selection_updates_input_handler()
	test_category_has_blocks()
	test_transit_category_blocks()
	test_residential_category_blocks()

	# Print summary
	print("")
	print("=== Test Summary ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed == 0:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(a, b, message: String) -> void:
	if a == b:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s (got %s, expected %s)" % [message, str(a), str(b)])


func assert_gt(a, b, message: String) -> void:
	if a > b:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s (got %s, expected > %s)" % [message, str(a), str(b)])


func test_toolbar_loads_blocks_from_registry() -> void:
	print("\ntest_toolbar_loads_blocks_from_registry:")

	# BlockRegistry is autoloaded, so we access it via the tree
	# But in unit tests, we can load the JSON directly
	var registry_path := "res://data/blocks.json"
	assert_true(FileAccess.file_exists(registry_path), "blocks.json should exist")

	var file := FileAccess.open(registry_path, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	assert_eq(error, OK, "blocks.json should parse successfully")

	var blocks: Dictionary = json.get_data()
	assert_gt(blocks.size(), 0, "Should have at least one block type")


func test_block_selection_updates_input_handler() -> void:
	print("\ntest_block_selection_updates_input_handler:")

	# Create components
	var toolbar := BuildToolbar.new()
	var input_handler := InputHandler.new()
	var grid := Grid.new()

	toolbar._setup_ui()

	# Connect signal (simulating what main.gd does)
	toolbar.block_selected.connect(func(block_type: String):
		input_handler.set_selected_block_type(block_type)
	)

	# Select a block via toolbar
	toolbar.select_block("corridor")

	# Verify input handler received it
	assert_eq(input_handler.selected_block_type, "corridor", "Input handler should have selected block type")

	toolbar.free()
	input_handler.free()
	grid.free()


func test_category_has_blocks() -> void:
	print("\ntest_category_has_blocks:")

	# Load blocks.json and verify each category in the file has blocks
	var file := FileAccess.open("res://data/blocks.json", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	var blocks: Dictionary = json.get_data()

	# Count blocks per category
	var category_counts: Dictionary = {}
	for block_type in blocks:
		var category: String = blocks[block_type].get("category", "")
		if category != "":
			category_counts[category] = category_counts.get(category, 0) + 1

	# Verify categories that should have blocks
	assert_true(category_counts.has("transit"), "Should have transit blocks")
	assert_gt(category_counts.get("transit", 0), 0, "Transit should have at least 1 block")


func test_transit_category_blocks() -> void:
	print("\ntest_transit_category_blocks:")

	# Load blocks.json
	var file := FileAccess.open("res://data/blocks.json", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	var blocks: Dictionary = json.get_data()

	# Get transit blocks
	var transit_blocks: Array[String] = []
	for block_type in blocks:
		if blocks[block_type].get("category", "") == "transit":
			transit_blocks.append(block_type)

	# Verify expected transit blocks exist
	assert_true("corridor" in transit_blocks, "corridor should be a transit block")
	assert_true("entrance" in transit_blocks, "entrance should be a transit block")
	assert_true("stairs" in transit_blocks, "stairs should be a transit block")
	assert_true("elevator_shaft" in transit_blocks, "elevator_shaft should be a transit block")


func test_residential_category_blocks() -> void:
	print("\ntest_residential_category_blocks:")

	# Load blocks.json
	var file := FileAccess.open("res://data/blocks.json", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	var blocks: Dictionary = json.get_data()

	# Get residential blocks
	var residential_blocks: Array[String] = []
	for block_type in blocks:
		if blocks[block_type].get("category", "") == "residential":
			residential_blocks.append(block_type)

	# Verify expected residential blocks exist
	assert_true("residential_basic" in residential_blocks, "residential_basic should be a residential block")
	assert_eq(residential_blocks.size(), 1, "Should have 1 residential block currently")
