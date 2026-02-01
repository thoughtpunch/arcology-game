extends SceneTree
## Tests for VisibilityController.
## Run with: godot --headless --script test/game/test_visibility_controller.gd

const VisibilityControllerScript = preload("res://src/game/visibility_controller.gd")


func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== VisibilityController Tests ===")

	# Test 1: Default mode is NORMAL
	print("\nTest 1: Default mode is NORMAL")
	var vc := VisibilityControllerScript.new()
	if vc.current_mode == VisibilityControllerScript.Mode.NORMAL:
		print("  PASS: Default mode is NORMAL")
		tests_passed += 1
	else:
		print("  FAIL: Expected NORMAL, got %d" % vc.current_mode)
		tests_failed += 1

	# Test 2: set_mode changes mode
	print("\nTest 2: set_mode changes mode to XRAY")
	vc.set_mode(VisibilityControllerScript.Mode.XRAY)
	if vc.current_mode == VisibilityControllerScript.Mode.XRAY:
		print("  PASS: Mode changed to XRAY")
		tests_passed += 1
	else:
		print("  FAIL: Expected XRAY, got %d" % vc.current_mode)
		tests_failed += 1

	# Test 3: toggle_mode toggles to NORMAL if already in target mode
	print("\nTest 3: toggle_mode toggles back to NORMAL")
	vc.toggle_mode(VisibilityControllerScript.Mode.XRAY)
	if vc.current_mode == VisibilityControllerScript.Mode.NORMAL:
		print("  PASS: Mode toggled back to NORMAL")
		tests_passed += 1
	else:
		print("  FAIL: Expected NORMAL, got %d" % vc.current_mode)
		tests_failed += 1

	# Test 4: toggle_mode switches to target mode if not already there
	print("\nTest 4: toggle_mode switches to target mode")
	vc.toggle_mode(VisibilityControllerScript.Mode.CUTAWAY)
	if vc.current_mode == VisibilityControllerScript.Mode.CUTAWAY:
		print("  PASS: Mode changed to CUTAWAY")
		tests_passed += 1
	else:
		print("  FAIL: Expected CUTAWAY, got %d" % vc.current_mode)
		tests_failed += 1

	# Test 5: X-ray opacity default value
	print("\nTest 5: X-ray opacity default value")
	var vc2 := VisibilityControllerScript.new()
	var expected_default := 0.15
	if absf(vc2.xray_opacity - expected_default) < 0.001:
		print("  PASS: Default xray_opacity is %.2f" % vc2.xray_opacity)
		tests_passed += 1
	else:
		print("  FAIL: Expected %.2f, got %.2f" % [expected_default, vc2.xray_opacity])
		tests_failed += 1

	# Test 6: adjust_xray_opacity increases opacity
	print("\nTest 6: adjust_xray_opacity increases opacity")
	vc2.adjust_xray_opacity(0.1)
	var expected := 0.25
	if absf(vc2.xray_opacity - expected) < 0.001:
		print("  PASS: xray_opacity increased to %.2f" % vc2.xray_opacity)
		tests_passed += 1
	else:
		print("  FAIL: Expected %.2f, got %.2f" % [expected, vc2.xray_opacity])
		tests_failed += 1

	# Test 7: adjust_xray_opacity clamps to max (0.5)
	print("\nTest 7: adjust_xray_opacity clamps to max")
	vc2.adjust_xray_opacity(0.5)  # Should clamp at 0.5
	if absf(vc2.xray_opacity - 0.5) < 0.001:
		print("  PASS: xray_opacity clamped to max (%.2f)" % vc2.xray_opacity)
		tests_passed += 1
	else:
		print("  FAIL: Expected 0.5, got %.2f" % vc2.xray_opacity)
		tests_failed += 1

	# Test 8: adjust_xray_opacity clamps to min (0.0)
	print("\nTest 8: adjust_xray_opacity clamps to min")
	vc2.adjust_xray_opacity(-1.0)  # Should clamp at 0.0
	if absf(vc2.xray_opacity - 0.0) < 0.001:
		print("  PASS: xray_opacity clamped to min (%.2f)" % vc2.xray_opacity)
		tests_passed += 1
	else:
		print("  FAIL: Expected 0.0, got %.2f" % vc2.xray_opacity)
		tests_failed += 1

	# Test 9: set_xray_opacity sets value directly
	print("\nTest 9: set_xray_opacity sets value directly")
	vc2.set_xray_opacity(0.3)
	if absf(vc2.xray_opacity - 0.3) < 0.001:
		print("  PASS: xray_opacity set to %.2f" % vc2.xray_opacity)
		tests_passed += 1
	else:
		print("  FAIL: Expected 0.3, got %.2f" % vc2.xray_opacity)
		tests_failed += 1

	# Test 10: cut_floor adjustment
	print("\nTest 10: cut_floor adjustment")
	var vc3 := VisibilityControllerScript.new()
	vc3.adjust_cut_floor(3)
	if vc3.cut_floor == 8:  # Default 5 + 3
		print("  PASS: cut_floor adjusted to %d" % vc3.cut_floor)
		tests_passed += 1
	else:
		print("  FAIL: Expected 8, got %d" % vc3.cut_floor)
		tests_failed += 1

	# Test 11: cut_floor clamps to 0
	print("\nTest 11: cut_floor clamps to 0")
	vc3.adjust_cut_floor(-20)  # Should clamp at 0
	if vc3.cut_floor == 0:
		print("  PASS: cut_floor clamped to 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % vc3.cut_floor)
		tests_failed += 1

	# Test 12: get_mode_name returns correct string
	print("\nTest 12: get_mode_name returns correct string")
	var name := VisibilityControllerScript.get_mode_name(VisibilityControllerScript.Mode.XRAY)
	if name == "X-Ray":
		print("  PASS: Mode name is '%s'" % name)
		tests_passed += 1
	else:
		print("  FAIL: Expected 'X-Ray', got '%s'" % name)
		tests_failed += 1

	# Test 13: get_status_string returns empty for NORMAL mode
	print("\nTest 13: get_status_string empty for NORMAL")
	var vc4 := VisibilityControllerScript.new()
	var status := vc4.get_status_string()
	if status == "":
		print("  PASS: Status string is empty for NORMAL mode")
		tests_passed += 1
	else:
		print("  FAIL: Expected empty, got '%s'" % status)
		tests_failed += 1

	# Test 14: get_status_string returns info for XRAY mode
	print("\nTest 14: get_status_string shows info for XRAY")
	vc4.set_mode(VisibilityControllerScript.Mode.XRAY)
	status = vc4.get_status_string()
	if "X-RAY" in status and "Opacity" in status:
		print("  PASS: Status string shows X-RAY info")
		tests_passed += 1
	else:
		print("  FAIL: Expected X-RAY status, got '%s'" % status)
		tests_failed += 1

	# Test 15: section angle wraps around 360
	print("\nTest 15: section angle wraps around 360")
	var vc5 := VisibilityControllerScript.new()
	vc5.adjust_section_angle(400.0)  # 400 mod 360 = 40
	if absf(vc5.section_angle - 40.0) < 0.001:
		print("  PASS: section_angle wrapped to %.1f" % vc5.section_angle)
		tests_passed += 1
	else:
		print("  FAIL: Expected 40.0, got %.1f" % vc5.section_angle)
		tests_failed += 1

	# Test 16: NEGATIVE - set_mode with same mode does nothing
	print("\nTest 16: set_mode with same mode doesn't trigger signal")
	# Test that duplicate mode doesn't change anything
	var vc6 := VisibilityControllerScript.new()
	var original_mode := vc6.current_mode
	vc6.set_mode(VisibilityControllerScript.Mode.NORMAL)  # Already NORMAL
	if vc6.current_mode == original_mode:
		print("  PASS: Mode unchanged for same mode call")
		tests_passed += 1
	else:
		print("  FAIL: Mode changed unexpectedly")
		tests_failed += 1

	# Test 17: cycle_mode cycles through all modes
	print("\nTest 17: cycle_mode cycles through modes")
	vc6.set_mode(VisibilityControllerScript.Mode.NORMAL)
	vc6.cycle_mode()  # -> CUTAWAY
	var expected_after_cycle := VisibilityControllerScript.Mode.CUTAWAY
	if vc6.current_mode == expected_after_cycle:
		print("  PASS: cycle_mode advanced to CUTAWAY")
		tests_passed += 1
	else:
		print("  FAIL: Expected CUTAWAY, got %d" % vc6.current_mode)
		tests_failed += 1

	# Test 18: cycle_mode wraps around
	print("\nTest 18: cycle_mode wraps around")
	vc6.set_mode(VisibilityControllerScript.Mode.SECTION)  # Last mode (4)
	vc6.cycle_mode()  # Should wrap to NORMAL (0)
	if vc6.current_mode == VisibilityControllerScript.Mode.NORMAL:
		print("  PASS: cycle_mode wrapped to NORMAL")
		tests_passed += 1
	else:
		print("  FAIL: Expected NORMAL (0), got %d" % vc6.current_mode)
		tests_failed += 1

	# Test 19: isolate_floor default value
	print("\nTest 19: isolate_floor default value")
	var vc7 := VisibilityControllerScript.new()
	if vc7.isolate_floor == 0:
		print("  PASS: Default isolate_floor is 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % vc7.isolate_floor)
		tests_failed += 1

	# Test 20: set_isolate_floor sets value
	print("\nTest 20: set_isolate_floor sets value")
	vc7.set_isolate_floor(5)
	if vc7.isolate_floor == 5:
		print("  PASS: isolate_floor set to 5")
		tests_passed += 1
	else:
		print("  FAIL: Expected 5, got %d" % vc7.isolate_floor)
		tests_failed += 1

	# Test 21: adjust_isolate_floor increases floor
	print("\nTest 21: adjust_isolate_floor increases floor")
	vc7.adjust_isolate_floor(2)
	if vc7.isolate_floor == 7:  # 5 + 2
		print("  PASS: isolate_floor increased to %d" % vc7.isolate_floor)
		tests_passed += 1
	else:
		print("  FAIL: Expected 7, got %d" % vc7.isolate_floor)
		tests_failed += 1

	# Test 22: adjust_isolate_floor clamps to 0
	print("\nTest 22: adjust_isolate_floor clamps to 0")
	vc7.adjust_isolate_floor(-20)  # Should clamp at 0
	if vc7.isolate_floor == 0:
		print("  PASS: isolate_floor clamped to 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % vc7.isolate_floor)
		tests_failed += 1

	# Test 23: toggle_mode switches to ISOLATE
	print("\nTest 23: toggle_mode switches to ISOLATE")
	vc7.toggle_mode(VisibilityControllerScript.Mode.ISOLATE)
	if vc7.current_mode == VisibilityControllerScript.Mode.ISOLATE:
		print("  PASS: Mode toggled to ISOLATE")
		tests_passed += 1
	else:
		print("  FAIL: Expected ISOLATE, got %d" % vc7.current_mode)
		tests_failed += 1

	# Test 24: get_status_string shows ISOLATE info
	print("\nTest 24: get_status_string shows ISOLATE info")
	var isolate_status := vc7.get_status_string()
	if "ISOLATE" in isolate_status and "Floor" in isolate_status:
		print("  PASS: Status string shows ISOLATE info")
		tests_passed += 1
	else:
		print("  FAIL: Expected ISOLATE status, got '%s'" % isolate_status)
		tests_failed += 1

	# Test 25: isolate_ghost_alpha default value
	print("\nTest 25: isolate_ghost_alpha default value")
	var vc8 := VisibilityControllerScript.new()
	if absf(vc8.isolate_ghost_alpha - 0.08) < 0.001:
		print("  PASS: Default isolate_ghost_alpha is 0.08")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0.08, got %.2f" % vc8.isolate_ghost_alpha)
		tests_failed += 1

	# Test 26: NEGATIVE - adjust_isolate_floor doesn't go negative
	print("\nTest 26: adjust_isolate_floor doesn't allow negative floors")
	vc8.set_isolate_floor(2)
	vc8.adjust_isolate_floor(-5)  # Should clamp to 0, not go to -3
	if vc8.isolate_floor == 0:
		print("  PASS: isolate_floor clamped to 0 (not negative)")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % vc8.isolate_floor)
		tests_failed += 1

	# Test 27: Mode enum values
	print("\nTest 27: Mode enum values are correct")
	var isolate_value: int = VisibilityControllerScript.Mode.ISOLATE
	if isolate_value == 3:
		print("  PASS: ISOLATE mode value is 3")
		tests_passed += 1
	else:
		print("  FAIL: Expected 3, got %d" % isolate_value)
		tests_failed += 1

	# Test 28: get_mode_name returns Isolate for ISOLATE mode
	print("\nTest 28: get_mode_name returns 'Isolate' for ISOLATE")
	var isolate_name := VisibilityControllerScript.get_mode_name(VisibilityControllerScript.Mode.ISOLATE)
	if isolate_name == "Isolate":
		print("  PASS: Mode name is 'Isolate'")
		tests_passed += 1
	else:
		print("  FAIL: Expected 'Isolate', got '%s'" % isolate_name)
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
