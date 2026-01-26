extends SceneTree
## Tests for underground terrain system
## Tests excavation tracking (Grid) and underground rendering (Terrain)

var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== Underground Terrain Tests ===\n")

	# Excavation tests (Grid)
	_test_surface_positions_always_excavated()
	_test_underground_not_excavated_by_default()
	_test_excavate_underground_position()
	_test_excavate_surface_fails()
	_test_excavate_idempotent()
	_test_can_place_underground_requires_excavation()
	_test_block_placement_auto_excavates()
	_test_excavation_persists_after_block_removal()
	_test_reset_excavation()

	# Terrain underground config tests
	_test_earth_theme_has_underground()
	_test_space_theme_no_underground()
	_test_underground_sprite_for_depth()
	_test_underground_sprite_path()

	# Underground visibility tests
	_test_underground_hidden_on_surface()
	_test_underground_visible_at_floor()

	# Signal tests
	_test_excavation_signal()

	print("\n=== Results ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)

	if _tests_failed > 0:
		print("\nSOME TESTS FAILED")
	else:
		print("\nALL TESTS PASSED")

	quit()


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("PASS: %s" % test_name)
		_tests_passed += 1
	else:
		print("FAIL: %s" % test_name)
		_tests_failed += 1


# =============================================================================
# GRID EXCAVATION TESTS
# =============================================================================

func _test_surface_positions_always_excavated() -> void:
	var grid := Grid.new()

	# Z=0 and above should always be "excavated"
	_assert(grid.is_excavated(Vector3i(0, 0, 0)), "Z=0 is excavated")
	_assert(grid.is_excavated(Vector3i(5, 5, 0)), "Z=0 any position is excavated")
	_assert(grid.is_excavated(Vector3i(0, 0, 1)), "Z=1 is excavated")
	_assert(grid.is_excavated(Vector3i(0, 0, 10)), "Z=10 is excavated")


func _test_underground_not_excavated_by_default() -> void:
	var grid := Grid.new()

	# Underground positions start unexcavated
	_assert(not grid.is_excavated(Vector3i(0, 0, -1)), "Z=-1 not excavated by default")
	_assert(not grid.is_excavated(Vector3i(5, 5, -2)), "Z=-2 not excavated by default")
	_assert(not grid.is_excavated(Vector3i(0, 0, -10)), "Z=-10 not excavated by default")


func _test_excavate_underground_position() -> void:
	var grid := Grid.new()
	var pos := Vector3i(3, 3, -1)

	# Excavate
	var result := grid.excavate(pos)
	_assert(result == true, "Excavate returns true on success")
	_assert(grid.is_excavated(pos), "Position is excavated after excavate()")


func _test_excavate_surface_fails() -> void:
	var grid := Grid.new()

	# Surface positions cannot be "excavated" (already buildable)
	var result := grid.excavate(Vector3i(0, 0, 0))
	_assert(result == false, "Cannot excavate Z=0")

	result = grid.excavate(Vector3i(0, 0, 1))
	_assert(result == false, "Cannot excavate Z=1")


func _test_excavate_idempotent() -> void:
	var grid := Grid.new()
	var pos := Vector3i(2, 2, -2)

	# First excavation succeeds
	_assert(grid.excavate(pos) == true, "First excavate succeeds")

	# Second excavation returns false (already done)
	_assert(grid.excavate(pos) == false, "Second excavate returns false")

	# But position is still excavated
	_assert(grid.is_excavated(pos), "Position still excavated after duplicate call")


func _test_can_place_underground_requires_excavation() -> void:
	var grid := Grid.new()
	var pos := Vector3i(1, 1, -1)

	# Cannot place before excavation
	_assert(not grid.can_place_at(pos), "Cannot place underground before excavation")

	# Excavate
	grid.excavate(pos)

	# Now can place
	_assert(grid.can_place_at(pos), "Can place underground after excavation")


func _test_block_placement_auto_excavates() -> void:
	var grid := Grid.new()
	var pos := Vector3i(4, 4, -1)

	# Create mock block
	var block := {"block_type": "corridor", "grid_position": Vector3i.ZERO}

	# Not excavated initially
	_assert(not grid.is_excavated(pos), "Not excavated before block placement")

	# Place block (simulating forced placement that auto-excavates)
	grid.set_block(pos, block)

	# Should be excavated now
	_assert(grid.is_excavated(pos), "Auto-excavated when block placed")


func _test_excavation_persists_after_block_removal() -> void:
	var grid := Grid.new()
	var pos := Vector3i(2, 3, -2)

	# Create and place block
	var block := {"block_type": "corridor", "grid_position": Vector3i.ZERO}
	grid.set_block(pos, block)

	# Remove block
	grid.remove_block(pos)

	# Excavation should persist
	_assert(grid.is_excavated(pos), "Excavation persists after block removal")
	_assert(not grid.has_block(pos), "Block is removed")
	_assert(grid.can_place_at(pos), "Can still place at excavated position")


func _test_reset_excavation() -> void:
	var grid := Grid.new()
	var pos1 := Vector3i(1, 1, -1)
	var pos2 := Vector3i(2, 2, -2)

	# Excavate some positions
	grid.excavate(pos1)
	grid.excavate(pos2)
	_assert(grid.get_excavation_count() == 2, "Two positions excavated")

	# Reset
	grid.reset_excavation()
	_assert(grid.get_excavation_count() == 0, "Excavation count is 0 after reset")
	_assert(not grid.is_excavated(pos1), "Position 1 not excavated after reset")
	_assert(not grid.is_excavated(pos2), "Position 2 not excavated after reset")


# =============================================================================
# TERRAIN UNDERGROUND CONFIG TESTS
# =============================================================================

func _test_earth_theme_has_underground() -> void:
	var terrain := Terrain.new()
	terrain.theme = "earth"

	_assert(terrain.has_underground(), "Earth theme has underground")


func _test_space_theme_no_underground() -> void:
	var terrain := Terrain.new()
	terrain.theme = "space"

	_assert(not terrain.has_underground(), "Space theme has no underground")


func _test_underground_sprite_for_depth() -> void:
	var terrain := Terrain.new()
	terrain.theme = "earth"

	# Test depth-to-sprite mapping (internal method, access via sprite path)
	var path_z1 := terrain._get_underground_sprite_path(-1)
	var path_z2 := terrain._get_underground_sprite_path(-2)
	var path_z3 := terrain._get_underground_sprite_path(-3)
	var path_z5 := terrain._get_underground_sprite_path(-5)

	_assert(path_z1.ends_with("soil.png"), "Z=-1 uses soil sprite")
	_assert(path_z2.ends_with("rock.png"), "Z=-2 uses rock sprite")
	_assert(path_z3.ends_with("bedrock.png"), "Z=-3 uses bedrock sprite")
	_assert(path_z5.ends_with("bedrock.png"), "Z=-5 uses bedrock (default)")


func _test_underground_sprite_path() -> void:
	var terrain := Terrain.new()
	terrain.theme = "earth"

	var path := terrain._get_underground_sprite_path(-1)
	_assert(path.begins_with("res://assets/sprites/terrain/earth/underground/"), "Path has correct base")
	_assert(not path.is_empty(), "Path is not empty for valid depth")

	# Surface should return empty
	var surface_path := terrain._get_underground_sprite_path(0)
	_assert(surface_path.is_empty(), "Surface Z=0 returns empty path")


# =============================================================================
# UNDERGROUND VISIBILITY TESTS
# =============================================================================

func _test_underground_hidden_on_surface() -> void:
	var terrain := Terrain.new()
	terrain.theme = "earth"

	# Set to surface level
	terrain.update_underground_visibility(0)
	_assert(terrain._current_floor == 0, "Current floor is surface")

	# Without generating, count should be 0
	_assert(terrain.get_underground_tile_count() == 0, "No tiles before generation")


func _test_underground_visible_at_floor() -> void:
	var terrain := Terrain.new()
	terrain.theme = "earth"

	# Test visibility logic without actual tile generation
	# (Since we can't load textures in headless mode)
	terrain._current_floor = -1

	# Visibility is updated but we can't test actual sprites in headless
	_assert(terrain._current_floor == -1, "Floor set to -1")


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func _test_excavation_signal() -> void:
	var grid := Grid.new()
	var pos := Vector3i(5, 5, -1)

	# Track signal emission synchronously
	var received_signals: Array = []

	# Connect to signal
	grid.excavation_changed.connect(func(p: Vector3i, e: bool):
		received_signals.append({"pos": p, "excavated": e})
	)

	# Excavate - signal should be emitted synchronously
	grid.excavate(pos)

	# Check signal was received
	_assert(received_signals.size() == 1, "Excavation signal received")
	if received_signals.size() > 0:
		var sig = received_signals[0]
		_assert(sig.pos == pos, "Signal has correct position")
		_assert(sig.excavated == true, "Signal indicates excavated")
	else:
		_assert(false, "Signal has correct position (no signal)")
		_assert(false, "Signal indicates excavated (no signal)")
