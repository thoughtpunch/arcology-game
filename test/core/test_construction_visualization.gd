extends SceneTree
## Test: Construction Visualization
## Tests that BlockRenderer shows construction progress visually
##
## Run with:
## godot --headless --path . --script test/core/test_construction_visualization.gd

var _tests_passed: int = 0
var _tests_failed: int = 0

var grid: Grid
var renderer: BlockRenderer
var construction_queue


func _init() -> void:
	print("=== Test: Construction Visualization ===")
	print("")

	# Wait for autoloads
	await process_frame

	_setup()

	# Core visualization tests
	print("## Construction Sprite Tests")
	_test_construction_creates_sprite()
	_test_construction_sprite_has_tint()
	_test_construction_sprite_removed_on_complete()
	_test_construction_sprite_removed_on_cancel()

	# Progress tests
	print("")
	print("## Progress Visualization Tests")
	_test_progress_updates_alpha()

	# Integration tests
	print("")
	print("## Integration Tests")
	_test_completed_construction_triggers_block_animation()
	_test_visibility_includes_construction_sprites()

	_cleanup()

	# Summary
	print("")
	print("=== Results ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)


func _setup() -> void:
	grid = Grid.new()
	get_root().add_child(grid)

	renderer = BlockRenderer.new()
	get_root().add_child(renderer)
	renderer.connect_to_grid(grid)

	# Load construction queue
	var CQScript = load("res://src/core/construction_queue.gd")
	construction_queue = CQScript.new()
	get_root().add_child(construction_queue)
	construction_queue.setup(grid)

	# Connect renderer to construction queue
	renderer.connect_to_construction_queue(construction_queue)


func _cleanup() -> void:
	construction_queue.queue_free()
	renderer.queue_free()
	grid.queue_free()


func _reset() -> void:
	grid.clear()
	construction_queue.clear_all()
	renderer._clear_construction_sprites()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, reason: String = "") -> void:
	if reason.is_empty():
		print("  FAIL: %s" % test_name)
	else:
		print("  FAIL: %s - %s" % [test_name, reason])
	_tests_failed += 1


# =============================================================================
# Construction Sprite Tests
# =============================================================================

## Test: Starting construction creates a sprite in renderer
func _test_construction_creates_sprite() -> void:
	_reset()
	var pos := Vector3i(5, 5, 0)

	construction_queue.start_construction(pos, "corridor")

	if renderer.has_construction(pos):
		_pass("Starting construction creates sprite in renderer")
	else:
		_fail("Starting construction creates sprite in renderer", "No construction sprite")


## Test: Construction sprite has blue tint
func _test_construction_sprite_has_tint() -> void:
	_reset()
	var pos := Vector3i(6, 6, 0)

	construction_queue.start_construction(pos, "corridor")

	if renderer._construction_sprites.has(pos):
		var data: Dictionary = renderer._construction_sprites[pos]
		var sprite: Sprite2D = data.sprite
		# Should have blue-ish tint (CONSTRUCTION_TINT)
		if sprite.modulate.r < 1.0 or sprite.modulate.b > sprite.modulate.r:
			_pass("Construction sprite has blue tint")
		else:
			_fail("Construction sprite has blue tint", "Modulate: %s" % sprite.modulate)
	else:
		_fail("Construction sprite has blue tint", "No construction sprite")


## Test: Construction sprite removed when complete
func _test_construction_sprite_removed_on_complete() -> void:
	_reset()
	var pos := Vector3i(7, 7, 0)

	construction_queue.start_construction(pos, "corridor")  # 1 hour

	# Verify sprite exists
	if not renderer.has_construction(pos):
		_fail("Construction sprite removed when complete", "No initial sprite")
		return

	# Complete construction
	construction_queue._on_time_changed(1, 1, 1, 9)

	if not renderer.has_construction(pos):
		_pass("Construction sprite removed when complete")
	else:
		_fail("Construction sprite removed when complete", "Sprite still exists")


## Test: Construction sprite removed when cancelled
func _test_construction_sprite_removed_on_cancel() -> void:
	_reset()
	var pos := Vector3i(8, 8, 0)

	construction_queue.start_construction(pos, "stairs")  # 2 hours
	construction_queue.cancel_construction(pos)

	if not renderer.has_construction(pos):
		_pass("Construction sprite removed when cancelled")
	else:
		_fail("Construction sprite removed when cancelled", "Sprite still exists")


# =============================================================================
# Progress Visualization Tests
# =============================================================================

## Test: Progress affects sprite alpha
func _test_progress_updates_alpha() -> void:
	_reset()
	var pos := Vector3i(9, 9, 0)

	construction_queue.start_construction(pos, "stairs")  # 2 hours

	if not renderer._construction_sprites.has(pos):
		_fail("Progress affects sprite alpha", "No construction sprite")
		return

	var data: Dictionary = renderer._construction_sprites[pos]
	var initial_alpha: float = data.sprite.modulate.a

	# Progress one hour
	construction_queue._on_time_changed(1, 1, 1, 9)

	# Alpha should increase as progress increases
	var new_alpha: float = data.sprite.modulate.a
	if new_alpha >= initial_alpha:
		_pass("Progress affects sprite alpha")
	else:
		_fail("Progress affects sprite alpha",
			"Alpha decreased: %f -> %f" % [initial_alpha, new_alpha])


# =============================================================================
# Integration Tests
# =============================================================================

## Test: Completed construction triggers block placement animation
func _test_completed_construction_triggers_block_animation() -> void:
	_reset()
	var pos := Vector3i(10, 10, 0)

	construction_queue.start_construction(pos, "corridor")  # 1 hour
	construction_queue._on_time_changed(1, 1, 1, 9)  # Complete it

	# Block should now exist in grid and have sprite in renderer
	if grid.has_block(pos) and renderer._sprites.has(pos):
		_pass("Completed construction triggers block placement animation")
	else:
		_fail("Completed construction triggers block placement animation",
			"Grid has block: %s, Renderer has sprite: %s" % [grid.has_block(pos), renderer._sprites.has(pos)])


## Test: Visibility update includes construction sprites
func _test_visibility_includes_construction_sprites() -> void:
	_reset()
	var pos := Vector3i(5, 5, 2)  # Higher floor

	construction_queue.start_construction(pos, "corridor")

	if not renderer._construction_sprites.has(pos):
		_fail("Visibility update includes construction sprites", "No construction sprite")
		return

	var data: Dictionary = renderer._construction_sprites[pos]
	var sprite: Sprite2D = data.sprite

	# With GameState at floor 0, floor 2 should be hidden
	renderer.update_visibility(0)

	# Sprite should be hidden (above current floor)
	if not sprite.visible:
		_pass("Visibility update includes construction sprites")
	else:
		_fail("Visibility update includes construction sprites", "Sprite still visible at floor 2 when on floor 0")
