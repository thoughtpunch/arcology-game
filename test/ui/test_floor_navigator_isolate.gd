extends SceneTree
## Tests for FloorNavigator isolate mode integration.
## Run with: godot --headless --script test/ui/test_floor_navigator_isolate.gd

const FloorNavigatorScript = preload("res://src/ui/floor_navigator.gd")


func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== FloorNavigator Isolate Mode Tests ===")

	# Test 1: Default state is not isolate mode
	print("\nTest 1: Default state is not isolate mode")
	var nav := FloorNavigatorScript.new()
	if not nav.is_isolate_mode():
		print("  PASS: Default is_isolate_mode() is false")
		tests_passed += 1
	else:
		print("  FAIL: Expected false, got true")
		tests_failed += 1

	# Test 2: set_isolate_mode enables isolate mode
	print("\nTest 2: set_isolate_mode enables isolate mode")
	nav.set_isolate_mode(true, 3)
	if nav.is_isolate_mode():
		print("  PASS: is_isolate_mode() returns true after enable")
		tests_passed += 1
	else:
		print("  FAIL: Expected true after set_isolate_mode(true)")
		tests_failed += 1

	# Test 3: set_isolate_mode sets the floor
	print("\nTest 3: set_isolate_mode sets the floor")
	if nav.get_isolate_floor() == 3:
		print("  PASS: get_isolate_floor() returns 3")
		tests_passed += 1
	else:
		print("  FAIL: Expected 3, got %d" % nav.get_isolate_floor())
		tests_failed += 1

	# Test 4: set_isolate_floor updates the floor
	print("\nTest 4: set_isolate_floor updates the floor")
	nav.set_isolate_floor(7)
	if nav.get_isolate_floor() == 7:
		print("  PASS: get_isolate_floor() returns 7 after update")
		tests_passed += 1
	else:
		print("  FAIL: Expected 7, got %d" % nav.get_isolate_floor())
		tests_failed += 1

	# Test 5: set_isolate_mode(false) disables isolate mode
	print("\nTest 5: set_isolate_mode(false) disables isolate mode")
	nav.set_isolate_mode(false)
	if not nav.is_isolate_mode():
		print("  PASS: is_isolate_mode() returns false after disable")
		tests_passed += 1
	else:
		print("  FAIL: Expected false after set_isolate_mode(false)")
		tests_failed += 1

	# Test 6: Default isolate floor is 0
	print("\nTest 6: Default isolate floor is 0")
	var nav2 := FloorNavigatorScript.new()
	if nav2.get_isolate_floor() == 0:
		print("  PASS: Default isolate floor is 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % nav2.get_isolate_floor())
		tests_failed += 1

	# Test 7: NEGATIVE - get_isolate_floor works even when not in isolate mode
	print("\nTest 7: get_isolate_floor works even when not in isolate mode")
	nav2.set_isolate_floor(5)  # Set floor without enabling isolate mode
	if nav2.get_isolate_floor() == 5:
		print("  PASS: Floor can be pre-set before enabling isolate mode")
		tests_passed += 1
	else:
		print("  FAIL: Expected 5, got %d" % nav2.get_isolate_floor())
		tests_failed += 1

	# Test 8: Floor navigator added to group
	print("\nTest 8: Floor navigator has get_floor_text method")
	if nav.has_method("get_floor_text"):
		print("  PASS: get_floor_text method exists")
		tests_passed += 1
	else:
		print("  FAIL: get_floor_text method not found")
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
