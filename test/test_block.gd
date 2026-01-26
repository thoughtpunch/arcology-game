extends SceneTree
## Test script for Block class
## Run with: godot --headless --script test/test_block.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Block Tests ===")

	# Test 1: Instantiation with position and type
	print("\nTest 1: Instantiation")
	var block := Block.new("corridor", Vector3i(5, 3, 1))

	if block.block_type == "corridor":
		print("  PASS: block_type is 'corridor'")
		tests_passed += 1
	else:
		print("  FAIL: block_type is '%s'" % block.block_type)
		tests_failed += 1

	if block.grid_position == Vector3i(5, 3, 1):
		print("  PASS: grid_position is (5, 3, 1)")
		tests_passed += 1
	else:
		print("  FAIL: grid_position is %s" % block.grid_position)
		tests_failed += 1

	# Test 2: Default values
	print("\nTest 2: Default values")
	var block2 := Block.new()

	if block2.block_type == "":
		print("  PASS: default block_type is empty")
		tests_passed += 1
	else:
		print("  FAIL: default block_type is '%s'" % block2.block_type)
		tests_failed += 1

	if block2.grid_position == Vector3i.ZERO:
		print("  PASS: default grid_position is ZERO")
		tests_passed += 1
	else:
		print("  FAIL: default grid_position is %s" % block2.grid_position)
		tests_failed += 1

	if block2.connected == false:
		print("  PASS: default connected is false")
		tests_passed += 1
	else:
		print("  FAIL: default connected is %s" % block2.connected)
		tests_failed += 1

	# Test 3: Connected property is writable
	print("\nTest 3: Connected property")
	block.connected = true
	if block.connected == true:
		print("  PASS: connected can be set to true")
		tests_passed += 1
	else:
		print("  FAIL: connected is %s" % block.connected)
		tests_failed += 1

	block.connected = false
	if block.connected == false:
		print("  PASS: connected can be set to false")
		tests_passed += 1
	else:
		print("  FAIL: connected is %s" % block.connected)
		tests_failed += 1

	# Test 4: Signals exist
	print("\nTest 4: Signals")
	var signal_list = block.get_signal_list()
	var has_property_changed = false
	for sig in signal_list:
		if sig.name == "property_changed":
			has_property_changed = true

	if has_property_changed:
		print("  PASS: property_changed signal exists")
		tests_passed += 1
	else:
		print("  FAIL: property_changed signal missing")
		tests_failed += 1

	# Test 5: get_definition returns empty dict when no registry
	print("\nTest 5: get_definition without BlockRegistry")
	var def := block.get_definition()
	if def is Dictionary:
		print("  PASS: get_definition returns Dictionary")
		tests_passed += 1
	else:
		print("  FAIL: get_definition returns %s" % typeof(def))
		tests_failed += 1

	# Test 6: Helper methods work with empty definition
	print("\nTest 6: Helper methods without BlockRegistry")
	if block.get_traversability() == "private":
		print("  PASS: get_traversability defaults to 'private'")
		tests_passed += 1
	else:
		print("  FAIL: get_traversability is '%s'" % block.get_traversability())
		tests_failed += 1

	if block.get_sprite_path() == "":
		print("  PASS: get_sprite_path defaults to empty")
		tests_passed += 1
	else:
		print("  FAIL: get_sprite_path is '%s'" % block.get_sprite_path())
		tests_failed += 1

	# Test 7: String representation
	print("\nTest 7: String representation")
	var str_repr := str(block)
	if "corridor" in str_repr and "5" in str_repr:
		print("  PASS: _to_string includes type and position")
		tests_passed += 1
	else:
		print("  FAIL: _to_string is '%s'" % str_repr)
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
