class_name GameConfirmationDialog
extends Control
## Modal confirmation dialog for destructive actions, errors, and warnings
## See: documentation/ui/menus.md

# Color scheme
const COLOR_OVERLAY := Color(0, 0, 0, 0.6)
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_DANGER := Color("#8b0000")
const COLOR_BUTTON_SUCCESS := Color("#2e7d32")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")
const COLOR_WARNING := Color("#ff9800")
const COLOR_ERROR := Color("#f44336")
const COLOR_INFO := Color("#4a90d9")

# Dialog types
enum DialogType {
	CONFIRM,       # Standard yes/no
	CONFIRM_SAVE,  # Save & quit / Quit / Cancel
	ERROR,         # OK only
	WARNING,       # OK only with warning icon
	INFO           # OK only with info icon
}

# Animation
const FADE_DURATION := 0.15

# Signals
signal confirmed
signal cancelled
signal save_and_quit  # For CONFIRM_SAVE type

# UI components
var _overlay: ColorRect
var _panel: PanelContainer
var _icon_label: Label
var _title_label: Label
var _message_label: Label
var _detail_container: VBoxContainer
var _button_container: HBoxContainer
var _dialog_type := DialogType.CONFIRM


func _ready() -> void:
	_setup_layout()
	visible = false


func _setup_layout() -> void:
	# Full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dimming overlay
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = COLOR_OVERLAY
	_overlay.name = "Overlay"
	add_child(_overlay)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.name = "CenterContainer"
	add_child(center)

	# Dialog panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(400, 0)
	_panel.name = "DialogPanel"
	center.add_child(_panel)

	# Style panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", panel_style)

	# Content container
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.name = "ContentVBox"
	_panel.add_child(vbox)

	# Header with icon and title
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.name = "Header"
	vbox.add_child(header)

	_icon_label = Label.new()
	_icon_label.add_theme_font_size_override("font_size", 24)
	_icon_label.name = "IconLabel"
	header.add_child(_icon_label)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", COLOR_TEXT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.name = "TitleLabel"
	header.add_child(_title_label)

	# Message
	_message_label = Label.new()
	_message_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size = Vector2(350, 0)
	_message_label.name = "MessageLabel"
	vbox.add_child(_message_label)

	# Optional detail container (for lists, etc.)
	_detail_container = VBoxContainer.new()
	_detail_container.add_theme_constant_override("separation", 4)
	_detail_container.name = "DetailContainer"
	vbox.add_child(_detail_container)

	# Button container
	_button_container = HBoxContainer.new()
	_button_container.add_theme_constant_override("separation", 12)
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_container.name = "ButtonContainer"
	vbox.add_child(_button_container)


func _create_button(text: String, style_type: String = "normal") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 40)
	btn.focus_mode = Control.FOCUS_ALL

	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8

	match style_type:
		"danger":
			normal_style.bg_color = COLOR_BUTTON_DANGER
		"success":
			normal_style.bg_color = COLOR_BUTTON_SUCCESS
		"accent":
			normal_style.bg_color = COLOR_ACCENT
		_:
			normal_style.bg_color = COLOR_BUTTON

	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = normal_style.bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var focus_style := normal_style.duplicate()
	focus_style.border_color = COLOR_TEXT
	focus_style.border_width_left = 2
	focus_style.border_width_right = 2
	focus_style.border_width_top = 2
	focus_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("focus", focus_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)

	return btn


func _clear_buttons() -> void:
	for child in _button_container.get_children():
		child.queue_free()


func _clear_details() -> void:
	for child in _detail_container.get_children():
		child.queue_free()


func _setup_confirm_buttons() -> void:
	_clear_buttons()

	var cancel_btn := _create_button("Cancel")
	cancel_btn.name = "CancelButton"
	cancel_btn.pressed.connect(_on_cancel)
	_button_container.add_child(cancel_btn)

	var confirm_btn := _create_button("Confirm", "accent")
	confirm_btn.name = "ConfirmButton"
	confirm_btn.pressed.connect(_on_confirm)
	_button_container.add_child(confirm_btn)


func _setup_save_confirm_buttons() -> void:
	_clear_buttons()

	var save_quit_btn := _create_button("Save & Quit", "success")
	save_quit_btn.name = "SaveQuitButton"
	save_quit_btn.pressed.connect(_on_save_and_quit)
	_button_container.add_child(save_quit_btn)

	var quit_btn := _create_button("Quit", "danger")
	quit_btn.name = "QuitButton"
	quit_btn.pressed.connect(_on_confirm)
	_button_container.add_child(quit_btn)

	var cancel_btn := _create_button("Cancel")
	cancel_btn.name = "CancelButton"
	cancel_btn.pressed.connect(_on_cancel)
	_button_container.add_child(cancel_btn)


func _setup_ok_button() -> void:
	_clear_buttons()

	var ok_btn := _create_button("OK", "accent")
	ok_btn.name = "OKButton"
	ok_btn.pressed.connect(_on_confirm)
	_button_container.add_child(ok_btn)


func _update_icon(dialog_type: DialogType) -> void:
	match dialog_type:
		DialogType.ERROR:
			_icon_label.text = "✕"
			_icon_label.add_theme_color_override("font_color", COLOR_ERROR)
		DialogType.WARNING:
			_icon_label.text = "⚠"
			_icon_label.add_theme_color_override("font_color", COLOR_WARNING)
		DialogType.INFO:
			_icon_label.text = "ℹ"
			_icon_label.add_theme_color_override("font_color", COLOR_INFO)
		_:
			_icon_label.text = ""


## Show a confirmation dialog
func show_confirm(title: String, message: String, details: Array = []) -> void:
	_dialog_type = DialogType.CONFIRM
	_title_label.text = title
	_message_label.text = message
	_update_icon(DialogType.CONFIRM)
	_setup_confirm_buttons()

	_clear_details()
	for detail in details:
		var label := Label.new()
		label.text = "• %s" % detail
		label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_detail_container.add_child(label)

	_show_dialog()


## Show an unsaved changes dialog
func show_unsaved_changes(title: String = "UNSAVED CHANGES", message: String = "You have unsaved progress.\nAre you sure you want to quit?") -> void:
	_dialog_type = DialogType.CONFIRM_SAVE
	_title_label.text = title
	_message_label.text = message
	_update_icon(DialogType.WARNING)
	_setup_save_confirm_buttons()
	_clear_details()
	_show_dialog()


## Show an error dialog
func show_error(title: String, message: String, details: Array = []) -> void:
	_dialog_type = DialogType.ERROR
	_title_label.text = "⚠ %s" % title
	_message_label.text = message
	_update_icon(DialogType.ERROR)
	_setup_ok_button()

	_clear_details()
	for detail in details:
		var label := Label.new()
		label.text = detail
		label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		_detail_container.add_child(label)

	_show_dialog()


## Show a warning dialog
func show_warning(title: String, message: String) -> void:
	_dialog_type = DialogType.WARNING
	_title_label.text = title
	_message_label.text = message
	_update_icon(DialogType.WARNING)
	_setup_ok_button()
	_clear_details()
	_show_dialog()


## Show an info dialog
func show_info(title: String, message: String) -> void:
	_dialog_type = DialogType.INFO
	_title_label.text = title
	_message_label.text = message
	_update_icon(DialogType.INFO)
	_setup_ok_button()
	_clear_details()
	_show_dialog()


func _show_dialog() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

	# Focus first button
	await get_tree().process_frame
	var first_btn := _button_container.get_child(0)
	if first_btn is Button:
		first_btn.grab_focus()


func _hide_dialog() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): visible = false)


func _on_confirm() -> void:
	_hide_dialog()
	confirmed.emit()


func _on_cancel() -> void:
	_hide_dialog()
	cancelled.emit()


func _on_save_and_quit() -> void:
	_hide_dialog()
	save_and_quit.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()


## Get current dialog type
func get_dialog_type() -> DialogType:
	return _dialog_type


## Check if dialog is visible
func is_showing() -> bool:
	return visible
