extends SceneTree
## Unit tests for FloorSelector

var floor_selector: Control


func _init() -> void:
	print("Testing FloorSelector...")
	_test_class_exists()
	_test_creation()
	_test_ui_components()
	print("FloorSelector tests PASSED")
	quit()


func _test_class_exists() -> void:
	# Verify the class loads
	var script = load("res://src/ui/floor_selector.gd")
	assert(script != null, "FloorSelector script should load")
	print("  class_exists: OK")


func _test_creation() -> void:
	# Create instance
	floor_selector = FloorSelector.new()
	assert(floor_selector != null, "FloorSelector instance should be created")
	assert(floor_selector is Control, "FloorSelector should extend Control")
	print("  creation: OK")


func _test_ui_components() -> void:
	# We can't fully test UI without scene tree, but we can check signals exist
	assert(floor_selector.has_signal("floor_change_requested"), "Should have floor_change_requested signal")
	print("  ui_components: OK")
