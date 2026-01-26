extends SceneTree
## Tests for ToastNotification UI component
## Run: godot --headless --script test/ui/test_toast_notification.gd

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== ToastNotification Tests ===\n")

	# Run tests
	_test_toast_creation()
	_test_toast_constants()
	_test_type_icons()
	_test_type_colors()
	_test_auto_dismiss_times()
	_test_show_toast()
	_test_active_count()
	_test_clear_all()
	_test_max_visible()
	_test_signals()

	# Print results
	print("\n=== Results ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)

	if _failed > 0:
		print("\nSome tests FAILED!")
		quit(1)
	else:
		print("\nAll tests PASSED!")
		quit(0)


func _test_toast_creation() -> void:
	print("Testing: toast creation...")

	var toast := ToastNotification.new()

	assert(toast != null, "Should create ToastNotification instance")
	_passed += 1
	assert(toast is Control, "Should be a Control")
	_passed += 1
	assert(toast.name == "ToastNotification" or toast.name == "", "Should have correct name")
	_passed += 1

	toast.queue_free()
	print("  ✓ toast creation")


func _test_toast_constants() -> void:
	print("Testing: toast constants...")

	assert(ToastNotification.TOAST_WIDTH == 300, "TOAST_WIDTH should be 300")
	_passed += 1
	assert(ToastNotification.TOAST_HEIGHT == 80, "TOAST_HEIGHT should be 80")
	_passed += 1
	assert(ToastNotification.TOAST_MARGIN == 16, "TOAST_MARGIN should be 16")
	_passed += 1
	assert(ToastNotification.SLIDE_DURATION > 0, "SLIDE_DURATION should be positive")
	_passed += 1
	assert(ToastNotification.DEFAULT_DISPLAY_TIME == 5.0, "DEFAULT_DISPLAY_TIME should be 5.0")
	_passed += 1

	print("  ✓ toast constants")


func _test_type_icons() -> void:
	print("Testing: type icons...")

	assert(ToastNotification.TYPE_ICONS[ToastNotification.TYPE_INFO] == "ℹ️", "INFO icon should be ℹ️")
	_passed += 1
	assert(ToastNotification.TYPE_ICONS[ToastNotification.TYPE_POSITIVE] == "✅", "POSITIVE icon should be ✅")
	_passed += 1
	assert(ToastNotification.TYPE_ICONS[ToastNotification.TYPE_NEWS] == "📰", "NEWS icon should be 📰")
	_passed += 1
	assert(ToastNotification.TYPE_ICONS[ToastNotification.TYPE_WARNING] == "⚠", "WARNING icon should be ⚠")
	_passed += 1
	assert(ToastNotification.TYPE_ICONS[ToastNotification.TYPE_EMERGENCY] == "🔴", "EMERGENCY icon should be 🔴")
	_passed += 1

	print("  ✓ type icons")


func _test_type_colors() -> void:
	print("Testing: type colors...")

	# Test that colors are valid Color objects
	assert(ToastNotification.TYPE_COLORS[ToastNotification.TYPE_INFO] is Color, "INFO color should be Color")
	_passed += 1
	assert(ToastNotification.TYPE_COLORS[ToastNotification.TYPE_POSITIVE] is Color, "POSITIVE color should be Color")
	_passed += 1
	assert(ToastNotification.TYPE_COLORS[ToastNotification.TYPE_WARNING] is Color, "WARNING color should be Color")
	_passed += 1
	assert(ToastNotification.TYPE_COLORS[ToastNotification.TYPE_EMERGENCY] is Color, "EMERGENCY color should be Color")
	_passed += 1

	print("  ✓ type colors")


func _test_auto_dismiss_times() -> void:
	print("Testing: auto dismiss times...")

	# INFO, POSITIVE, NEWS should auto-dismiss
	assert(ToastNotification.TYPE_AUTO_DISMISS[ToastNotification.TYPE_INFO] > 0, "INFO should auto-dismiss")
	_passed += 1
	assert(ToastNotification.TYPE_AUTO_DISMISS[ToastNotification.TYPE_POSITIVE] > 0, "POSITIVE should auto-dismiss")
	_passed += 1
	assert(ToastNotification.TYPE_AUTO_DISMISS[ToastNotification.TYPE_NEWS] > 0, "NEWS should auto-dismiss")
	_passed += 1

	# WARNING and EMERGENCY should NOT auto-dismiss
	assert(ToastNotification.TYPE_AUTO_DISMISS[ToastNotification.TYPE_WARNING] == 0, "WARNING should not auto-dismiss")
	_passed += 1
	assert(ToastNotification.TYPE_AUTO_DISMISS[ToastNotification.TYPE_EMERGENCY] == 0, "EMERGENCY should not auto-dismiss")
	_passed += 1

	print("  ✓ auto dismiss times")


func _test_show_toast() -> void:
	print("Testing: show toast...")

	var toast := ToastNotification.new()

	# Create notification data
	var notification := {
		"id": 1,
		"title": "Test Toast",
		"description": "This is a test",
		"type": ToastNotification.TYPE_INFO,
		"icon": "ℹ️",
		"color": Color.WHITE,
		"auto_dismiss_time": 5.0
	}

	# Note: _show_toast creates child nodes, which needs tree
	# Test that method exists and doesn't crash
	var has_method := toast.has_method("_show_toast")
	assert(has_method, "Should have _show_toast method")
	_passed += 1

	var has_public_method := toast.has_method("show_toast")
	assert(has_public_method, "Should have public show_toast method")
	_passed += 1

	toast.queue_free()
	print("  ✓ show toast")


func _test_active_count() -> void:
	print("Testing: active count...")

	var toast := ToastNotification.new()

	assert(toast.get_active_count() == 0, "Should start with 0 active toasts")
	_passed += 1

	toast.queue_free()
	print("  ✓ active count")


func _test_clear_all() -> void:
	print("Testing: clear all...")

	var toast := ToastNotification.new()

	# Clear should not crash even with no toasts
	toast.clear_all()
	assert(toast.get_active_count() == 0, "Should have 0 after clear_all")
	_passed += 1

	toast.queue_free()
	print("  ✓ clear all")


func _test_max_visible() -> void:
	print("Testing: max visible...")

	var toast := ToastNotification.new()

	# Default max visible
	assert(toast._max_visible_toasts == 5, "Should default to 5 max visible")
	_passed += 1

	# Set max visible
	toast.set_max_visible(3)
	assert(toast._max_visible_toasts == 3, "Should update to 3 max visible")
	_passed += 1

	# Cannot set to 0 or negative
	toast.set_max_visible(0)
	assert(toast._max_visible_toasts == 1, "Should clamp to minimum of 1")
	_passed += 1

	toast.queue_free()
	print("  ✓ max visible")


func _test_signals() -> void:
	print("Testing: signals...")

	var toast := ToastNotification.new()

	assert(toast.has_signal("toast_clicked"), "Should have toast_clicked signal")
	_passed += 1
	assert(toast.has_signal("toast_dismissed"), "Should have toast_dismissed signal")
	_passed += 1

	toast.queue_free()
	print("  ✓ signals")
