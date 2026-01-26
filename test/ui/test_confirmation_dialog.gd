extends SceneTree
## Unit tests for GameConfirmationDialog class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== GameConfirmationDialog Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_starts_hidden()
	_test_has_overlay()
	_test_has_panel()

	# Dialog type tests
	_test_confirm_dialog()
	_test_error_dialog()
	_test_warning_dialog()
	_test_info_dialog()
	_test_unsaved_changes_dialog()

	# Button configuration tests
	_test_confirm_has_two_buttons()
	_test_error_has_ok_button()
	_test_unsaved_has_three_buttons()

	# Signal tests
	_test_confirm_emits_confirmed()
	_test_cancel_emits_cancelled()
	_test_save_quit_emits_signal()

	# Show/hide tests
	_test_show_confirm_makes_visible()
	_test_is_showing_returns_visibility()

	# Content tests
	_test_title_updates()
	_test_message_updates()
	_test_details_added()

	# Negative tests
	_test_hidden_by_default()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var dialog := GameConfirmationDialog.new()
	_assert(dialog != null, "GameConfirmationDialog should create without error")
	dialog.queue_free()


func _test_starts_hidden() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = false
	_assert(dialog.visible == false, "Should start hidden")
	dialog.queue_free()


func _test_has_overlay() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	var overlay: ColorRect = dialog.get_node_or_null("Overlay")
	_assert(overlay != null, "Should have overlay")
	_assert(overlay.color.a > 0 and overlay.color.a < 1, "Overlay should be semi-transparent")
	dialog.queue_free()


func _test_has_panel() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	var panel: PanelContainer = dialog.get_node_or_null("CenterContainer/DialogPanel")
	_assert(panel != null, "Should have dialog panel")
	dialog.queue_free()


func _test_confirm_dialog() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_confirm("Test Title", "Test message")
	_assert(dialog.get_dialog_type() == GameConfirmationDialog.DialogType.CONFIRM, "Should be CONFIRM type")
	_assert(dialog._title_label.text == "Test Title", "Title should be set")
	_assert(dialog._message_label.text == "Test message", "Message should be set")
	dialog.queue_free()


func _test_error_dialog() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_error("Error", "Something went wrong")
	_assert(dialog.get_dialog_type() == GameConfirmationDialog.DialogType.ERROR, "Should be ERROR type")
	dialog.queue_free()


func _test_warning_dialog() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_warning("Warning", "Be careful")
	_assert(dialog.get_dialog_type() == GameConfirmationDialog.DialogType.WARNING, "Should be WARNING type")
	dialog.queue_free()


func _test_info_dialog() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_info("Info", "Just so you know")
	_assert(dialog.get_dialog_type() == GameConfirmationDialog.DialogType.INFO, "Should be INFO type")
	dialog.queue_free()


func _test_unsaved_changes_dialog() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_unsaved_changes()
	_assert(dialog.get_dialog_type() == GameConfirmationDialog.DialogType.CONFIRM_SAVE, "Should be CONFIRM_SAVE type")
	_assert(dialog._title_label.text == "UNSAVED CHANGES", "Title should be 'UNSAVED CHANGES'")
	dialog.queue_free()


func _test_confirm_has_two_buttons() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_confirm("Test", "Test message")
	_assert(dialog._button_container.get_child_count() == 2, "Confirm dialog should have 2 buttons")
	dialog.queue_free()


func _test_error_has_ok_button() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_error("Error", "Test")
	_assert(dialog._button_container.get_child_count() == 1, "Error dialog should have 1 button")
	var ok_btn: Button = dialog._button_container.get_node_or_null("OKButton")
	_assert(ok_btn != null, "Error dialog should have OK button")
	dialog.queue_free()


func _test_unsaved_has_three_buttons() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_unsaved_changes()
	_assert(dialog._button_container.get_child_count() == 3, "Unsaved changes dialog should have 3 buttons")
	dialog.queue_free()


func _test_confirm_emits_confirmed() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = true
	var signal_received := false
	dialog.confirmed.connect(func(): signal_received = true)
	dialog._on_confirm()
	_assert(signal_received, "Confirm should emit confirmed signal")
	dialog.queue_free()


func _test_cancel_emits_cancelled() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = true
	var signal_received := false
	dialog.cancelled.connect(func(): signal_received = true)
	dialog._on_cancel()
	_assert(signal_received, "Cancel should emit cancelled signal")
	dialog.queue_free()


func _test_save_quit_emits_signal() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = true
	var signal_received := false
	dialog.save_and_quit.connect(func(): signal_received = true)
	dialog._on_save_and_quit()
	_assert(signal_received, "Save & Quit should emit save_and_quit signal")
	dialog.queue_free()


func _test_show_confirm_makes_visible() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = false
	dialog.show_confirm("Test", "Test")
	_assert(dialog.visible == true, "show_confirm should make dialog visible")
	dialog.queue_free()


func _test_is_showing_returns_visibility() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = true
	_assert(dialog.is_showing() == true, "is_showing should return true when visible")
	dialog.visible = false
	_assert(dialog.is_showing() == false, "is_showing should return false when hidden")
	dialog.queue_free()


func _test_title_updates() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_confirm("Custom Title", "Message")
	_assert(dialog._title_label.text == "Custom Title", "Title should update")
	dialog.show_confirm("Different Title", "Message")
	_assert(dialog._title_label.text == "Different Title", "Title should change")
	dialog.queue_free()


func _test_message_updates() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_confirm("Title", "First message")
	_assert(dialog._message_label.text == "First message", "Message should update")
	dialog.show_confirm("Title", "Second message")
	_assert(dialog._message_label.text == "Second message", "Message should change")
	dialog.queue_free()


func _test_details_added() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.show_confirm("Title", "Message", ["Detail 1", "Detail 2"])
	_assert(dialog._detail_container.get_child_count() == 2, "Should have 2 detail items")
	dialog.queue_free()


func _test_hidden_by_default() -> void:
	var dialog := GameConfirmationDialog.new()
	dialog._setup_layout()
	dialog.visible = false  # As set in _ready
	_assert(dialog.is_showing() == false, "Dialog should be hidden by default")
	dialog.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
