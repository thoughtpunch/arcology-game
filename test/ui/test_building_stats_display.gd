extends SceneTree
## Unit tests for BuildingStatsDisplay and Grid.get_building_stats()

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== Building Stats Display Tests ===")

	# Grid.get_building_stats() tests
	test_grid_stats_empty()
	test_grid_stats_single_block()
	test_grid_stats_tower()
	test_grid_stats_flat_spread()
	test_grid_stats_complex_building()
	test_grid_stats_after_removal()
	test_grid_stats_negative_z()

	# BuildingStatsDisplay tests
	test_display_creation()
	test_display_starts_hidden()
	test_display_update_shows_when_blocks_exist()
	test_display_hides_when_zero_volume()
	test_display_label_values()
	test_display_connect_to_grid()
	test_display_reactive_update_on_add()
	test_display_reactive_update_on_remove()

	# HUD integration tests
	test_hud_has_building_stats()
	test_hud_update_building_stats()
	test_hud_get_building_stats_display()

	# Negative assertion tests
	test_display_update_with_null_grid()
	test_display_connect_to_grid_null()
	test_grid_stats_all_same_column()

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
		print("  PASS: %s" % message)
	else:
		tests_failed += 1
		print("  FAIL: %s" % message)


func assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  PASS: %s" % message)
	else:
		tests_failed += 1
		print("  FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)])


# --- Grid.get_building_stats() Tests ---

func test_grid_stats_empty() -> void:
	print("\n-- Grid stats: empty grid --")
	var grid := Grid.new()
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 0, "Empty grid height = 0")
	assert_equal(stats.volume, 0, "Empty grid volume = 0")
	assert_equal(stats.footprint, 0, "Empty grid footprint = 0")


func test_grid_stats_single_block() -> void:
	print("\n-- Grid stats: single block --")
	var grid := Grid.new()
	var block: Block = _make_block("entrance", Vector3i(0, 0, 0))
	grid.set_block(Vector3i(0, 0, 0), block)
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 1, "Single block at Z=0: height = 1")
	assert_equal(stats.volume, 1, "Single block: volume = 1")
	assert_equal(stats.footprint, 1, "Single block: footprint = 1")


func test_grid_stats_tower() -> void:
	print("\n-- Grid stats: vertical tower --")
	var grid := Grid.new()
	for z in range(5):
		var block: Block = _make_block("corridor", Vector3i(0, 0, z))
		grid.set_block(Vector3i(0, 0, z), block)
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 5, "5-block tower: height = 5")
	assert_equal(stats.volume, 5, "5-block tower: volume = 5")
	assert_equal(stats.footprint, 1, "Tower in one column: footprint = 1")


func test_grid_stats_flat_spread() -> void:
	print("\n-- Grid stats: flat spread --")
	var grid := Grid.new()
	for x in range(3):
		for y in range(4):
			var block: Block = _make_block("corridor", Vector3i(x, y, 0))
			grid.set_block(Vector3i(x, y, 0), block)
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 1, "Flat spread at Z=0: height = 1")
	assert_equal(stats.volume, 12, "3x4 flat spread: volume = 12")
	assert_equal(stats.footprint, 12, "3x4 flat spread: footprint = 12")


func test_grid_stats_complex_building() -> void:
	print("\n-- Grid stats: complex building --")
	var grid := Grid.new()
	# Ground floor: 3x3
	for x in range(3):
		for y in range(3):
			grid.set_block(Vector3i(x, y, 0), _make_block("corridor", Vector3i(x, y, 0)))
	# Second floor: 2x2
	for x in range(2):
		for y in range(2):
			grid.set_block(Vector3i(x, y, 1), _make_block("corridor", Vector3i(x, y, 1)))
	# Third floor: 1 block
	grid.set_block(Vector3i(0, 0, 2), _make_block("corridor", Vector3i(0, 0, 2)))
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 3, "Pyramid: height = 3")
	assert_equal(stats.volume, 14, "9 + 4 + 1 = 14: volume = 14")
	assert_equal(stats.footprint, 9, "3x3 base: footprint = 9")


func test_grid_stats_after_removal() -> void:
	print("\n-- Grid stats: after removal --")
	var grid := Grid.new()
	grid.set_block(Vector3i(0, 0, 0), _make_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(1, 0, 0), _make_block("corridor", Vector3i(1, 0, 0)))
	grid.set_block(Vector3i(0, 0, 1), _make_block("corridor", Vector3i(0, 0, 1)))
	grid.remove_block(Vector3i(0, 0, 1))
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 1, "After removing top block: height = 1")
	assert_equal(stats.volume, 2, "After removal: volume = 2")
	assert_equal(stats.footprint, 2, "Two columns: footprint = 2")


func test_grid_stats_negative_z() -> void:
	print("\n-- Grid stats: negative Z (basement) --")
	var grid := Grid.new()
	grid.set_block(Vector3i(0, 0, -1), _make_block("corridor", Vector3i(0, 0, -1)))
	grid.set_block(Vector3i(0, 0, 0), _make_block("corridor", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(0, 0, 1), _make_block("corridor", Vector3i(0, 0, 1)))
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 2, "Z -1 to 1: height = max(z)+1 = 2")
	assert_equal(stats.volume, 3, "3 blocks: volume = 3")
	assert_equal(stats.footprint, 1, "Same column: footprint = 1")


func test_grid_stats_all_same_column() -> void:
	print("\n-- Grid stats: all blocks in same column --")
	var grid := Grid.new()
	for z in range(10):
		grid.set_block(Vector3i(5, 5, z), _make_block("corridor", Vector3i(5, 5, z)))
	var stats: Dictionary = grid.get_building_stats()
	assert_equal(stats.height, 10, "10-tall tower: height = 10")
	assert_equal(stats.volume, 10, "10 blocks: volume = 10")
	assert_equal(stats.footprint, 1, "All same column: footprint = 1")


# --- BuildingStatsDisplay Tests ---

func test_display_creation() -> void:
	print("\n-- Display: creation --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	assert_true(display is HBoxContainer, "Display is HBoxContainer")
	assert_true(display._height_value != null, "Height value label exists")
	assert_true(display._volume_value != null, "Volume value label exists")
	assert_true(display._footprint_value != null, "Footprint value label exists")


func test_display_starts_hidden() -> void:
	print("\n-- Display: starts hidden --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	assert_true(not display.visible, "Display starts hidden (no blocks)")


func test_display_update_shows_when_blocks_exist() -> void:
	print("\n-- Display: shows when blocks exist --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	display.update_stats(3, 15, 8)
	assert_true(display.visible, "Display visible when volume > 0")


func test_display_hides_when_zero_volume() -> void:
	print("\n-- Display: hides when zero volume --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	display.update_stats(3, 15, 8)
	assert_true(display.visible, "Visible with data")
	display.update_stats(0, 0, 0)
	assert_true(not display.visible, "Hidden when volume = 0")


func test_display_label_values() -> void:
	print("\n-- Display: label values --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	display.update_stats(5, 42, 12)
	assert_equal(display._height_value.text, "5", "Height label shows '5'")
	assert_equal(display._volume_value.text, "42", "Volume label shows '42'")
	assert_equal(display._footprint_value.text, "12", "Footprint label shows '12'")


func test_display_connect_to_grid() -> void:
	print("\n-- Display: connect to grid --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	var grid := Grid.new()
	grid.set_block(Vector3i(0, 0, 0), _make_block("entrance", Vector3i(0, 0, 0)))
	display.connect_to_grid(grid)
	assert_true(display.visible, "Display visible after connecting to grid with blocks")
	assert_equal(display._height_value.text, "1", "Height updated from grid")
	assert_equal(display._volume_value.text, "1", "Volume updated from grid")
	assert_equal(display._footprint_value.text, "1", "Footprint updated from grid")


func test_display_reactive_update_on_add() -> void:
	print("\n-- Display: reactive update on block add --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	var grid := Grid.new()
	display.connect_to_grid(grid)
	assert_true(not display.visible, "Hidden before blocks")
	grid.set_block(Vector3i(0, 0, 0), _make_block("entrance", Vector3i(0, 0, 0)))
	assert_true(display.visible, "Visible after block added")
	assert_equal(display._volume_value.text, "1", "Volume updated to 1")
	grid.set_block(Vector3i(1, 0, 0), _make_block("corridor", Vector3i(1, 0, 0)))
	assert_equal(display._volume_value.text, "2", "Volume updated to 2 after second block")
	assert_equal(display._footprint_value.text, "2", "Footprint updated to 2")


func test_display_reactive_update_on_remove() -> void:
	print("\n-- Display: reactive update on block remove --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	var grid := Grid.new()
	display.connect_to_grid(grid)
	grid.set_block(Vector3i(0, 0, 0), _make_block("entrance", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(1, 0, 0), _make_block("corridor", Vector3i(1, 0, 0)))
	assert_equal(display._volume_value.text, "2", "Volume = 2 before removal")
	grid.remove_block(Vector3i(1, 0, 0))
	assert_equal(display._volume_value.text, "1", "Volume = 1 after removal")
	assert_equal(display._footprint_value.text, "1", "Footprint = 1 after removal")


# --- HUD Integration Tests ---

func test_hud_has_building_stats() -> void:
	print("\n-- HUD: has building stats display --")
	var hud := HUD.new()
	hud._setup_layout()
	var stats: BuildingStatsDisplay = hud.top_bar.get_node_or_null("HBoxContainer/BuildingStats")
	assert_true(stats != null, "BuildingStats node exists in top bar")
	assert_true(stats is BuildingStatsDisplay, "BuildingStats is correct type")


func test_hud_update_building_stats() -> void:
	print("\n-- HUD: update_building_stats method --")
	var hud := HUD.new()
	hud._setup_layout()
	hud.update_building_stats(7, 50, 20)
	var stats: BuildingStatsDisplay = hud.top_bar.get_node_or_null("HBoxContainer/BuildingStats")
	assert_true(stats != null, "BuildingStats accessible")
	if stats:
		assert_equal(stats._height_value.text, "7", "HUD update sets height")
		assert_equal(stats._volume_value.text, "50", "HUD update sets volume")
		assert_equal(stats._footprint_value.text, "20", "HUD update sets footprint")


func test_hud_get_building_stats_display() -> void:
	print("\n-- HUD: get_building_stats_display accessor --")
	var hud := HUD.new()
	hud._setup_layout()
	var display: BuildingStatsDisplay = hud.get_building_stats_display()
	assert_true(display != null, "get_building_stats_display() returns non-null")
	assert_true(display is BuildingStatsDisplay, "Returns correct type")


# --- Negative Assertion Tests ---

func test_display_update_with_null_grid() -> void:
	print("\n-- Negative: update with null grid --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	display.update_stats_from_grid()
	assert_true(not display.visible, "Hidden when grid is null")
	assert_equal(display._height_value.text, "0", "Height = 0 with null grid")


func test_display_connect_to_grid_null() -> void:
	print("\n-- Negative: connect_to_grid with null --")
	var display := BuildingStatsDisplay.new()
	display._setup_ui()
	display.connect_to_grid(null)
	assert_true(not display.visible, "Hidden with null grid")


# --- Helpers ---

func _make_block(type: String, pos: Vector3i):
	var block: Block = Block.new(type, pos)
	return block
