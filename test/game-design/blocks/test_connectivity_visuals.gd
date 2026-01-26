extends SceneTree
## Unit tests for connectivity visual feedback (arcology-itx.4)

var _tests_passed := 0
var _tests_failed := 0


func _init():
	print("=== Connectivity Visuals Tests ===")

	_test_disconnected_tint_constant()
	_test_connected_tint_constant()
	_test_update_connectivity_visual_connected()
	_test_update_connectivity_visual_disconnected()
	_test_visibility_preserves_connectivity_tint()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


func _assert(condition: bool, message: String):
	if condition:
		_tests_passed += 1
		print("  ✓ " + message)
	else:
		_tests_failed += 1
		print("  ✗ " + message)


func _assert_color_approx(actual: Color, expected: Color, message: String):
	var tolerance := 0.01
	var matches: bool = (
		abs(actual.r - expected.r) < tolerance and
		abs(actual.g - expected.g) < tolerance and
		abs(actual.b - expected.b) < tolerance
	)
	if matches:
		_tests_passed += 1
		print("  ✓ " + message)
	else:
		_tests_failed += 1
		print("  ✗ " + message + " (got %s, expected %s)" % [actual, expected])


# --- Test Cases ---

func _test_disconnected_tint_constant():
	print("\nTest: DISCONNECTED_TINT is reddish")
	var renderer = BlockRenderer.new()
	_assert(renderer.DISCONNECTED_TINT.r > 0.9, "Red channel should be high")
	_assert(renderer.DISCONNECTED_TINT.g < 0.6, "Green channel should be reduced")
	_assert(renderer.DISCONNECTED_TINT.b < 0.6, "Blue channel should be reduced")


func _test_connected_tint_constant():
	print("\nTest: CONNECTED_TINT is white")
	var renderer = BlockRenderer.new()
	_assert_color_approx(renderer.CONNECTED_TINT, Color.WHITE, "Connected tint should be white")


func _test_update_connectivity_visual_connected():
	print("\nTest: Connected block gets white tint")
	var renderer = BlockRenderer.new()

	# Create mock block with sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color.RED  # Start with something else to verify change
	var block = {"connected": true, "sprite": sprite}

	renderer._update_connectivity_visual(block)

	_assert_color_approx(sprite.modulate, Color.WHITE, "Connected block should be white")


func _test_update_connectivity_visual_disconnected():
	print("\nTest: Disconnected block gets red tint")
	var renderer = BlockRenderer.new()

	# Create mock block with sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color.WHITE
	var block = {"connected": false, "sprite": sprite}

	renderer._update_connectivity_visual(block)

	_assert(sprite.modulate.r > 0.9, "Disconnected block should have high red")
	_assert(sprite.modulate.g < 0.6, "Disconnected block should have reduced green")


func _test_visibility_preserves_connectivity_tint():
	print("\nTest: Floor visibility preserves connectivity tint")
	# This test verifies that when floor visibility is updated,
	# the connectivity tint (red for disconnected) is preserved
	var renderer = BlockRenderer.new()
	var grid = Grid.new()
	renderer.grid = grid

	var sprite = Sprite2D.new()
	var block = {"connected": false, "sprite": sprite, "grid_position": Vector3i(0, 0, 0), "block_type": "corridor"}
	grid.set_block(Vector3i(0, 0, 0), block)
	renderer._sprites[Vector3i(0, 0, 0)] = sprite

	# Update visibility for current floor
	renderer._update_sprite_visibility(Vector3i(0, 0, 0), 0)

	_assert(sprite.modulate.r > 0.9, "Should preserve red tint after visibility update")
	_assert(sprite.modulate.g < 0.6, "Should preserve reduced green after visibility update")
	_assert(sprite.modulate.a > 0.99, "Alpha should be full for current floor")
