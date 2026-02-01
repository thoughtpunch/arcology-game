extends Control

## Pause menu for the Phase 0 sandbox.
## Resume, Reset Scenario, Options (placeholder), Exit to Main Menu, Quit.
## Reset and Exit to Main Menu show a confirmation dialog before acting.

signal resumed

const COLOR_OVERLAY := Color(0, 0, 0, 0.5)
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_ACCENT := Color("#e94560")
const FADE_DURATION := 0.2

var _overlay: ColorRect
var _panel: PanelContainer
var _button_container: VBoxContainer


func _ready() -> void:
	_setup_layout()
	visible = false


func _setup_layout() -> void:
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

	# Main panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)
	_panel.name = "MenuPanel"
	center.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", panel_style)

	# Content container
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.name = "ContentBox"
	_panel.add_child(content)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.name = "TitleLabel"
	content.add_child(title)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer)

	# Button container
	_button_container = VBoxContainer.new()
	_button_container.add_theme_constant_override("separation", 8)
	_button_container.name = "ButtonContainer"
	content.add_child(_button_container)

	# Resume button
	var resume_btn := _create_menu_button("RESUME")
	resume_btn.name = "ResumeButton"
	resume_btn.pressed.connect(_on_resume_pressed)
	_button_container.add_child(resume_btn)

	# Reset scenario button
	var reset_btn := _create_menu_button("RESET SCENARIO")
	reset_btn.name = "ResetButton"
	reset_btn.pressed.connect(_on_reset_pressed)
	_button_container.add_child(reset_btn)

	# Options button (placeholder — no settings system yet)
	var options_btn := _create_menu_button("OPTIONS")
	options_btn.name = "OptionsButton"
	options_btn.disabled = true
	options_btn.tooltip_text = "Settings coming soon"
	_button_container.add_child(options_btn)

	# Separator before exit buttons
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.2)
	_button_container.add_child(sep)

	# Exit to main menu button
	var main_menu_btn := _create_menu_button("EXIT TO MAIN MENU")
	main_menu_btn.name = "MainMenuButton"
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	_button_container.add_child(main_menu_btn)

	# Quit to desktop button
	var quit_btn := _create_menu_button("QUIT TO DESKTOP")
	quit_btn.name = "QuitButton"
	quit_btn.pressed.connect(_on_quit_pressed)
	_button_container.add_child(quit_btn)


func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 40)
	btn.focus_mode = Control.FOCUS_ALL

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := hover_style.duplicate()
	pressed_style.bg_color = COLOR_BUTTON_HOVER.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var focus_style := normal_style.duplicate()
	focus_style.border_color = COLOR_ACCENT
	focus_style.border_width_left = 2
	focus_style.border_width_right = 2
	focus_style.border_width_top = 2
	focus_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("focus", focus_style)

	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = COLOR_BUTTON.darkened(0.3)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.45))

	return btn


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if visible:
				hide_menu()
			else:
				show_menu()
			get_viewport().set_input_as_handled()


func show_menu() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

	var resume_btn: Button = _button_container.get_node_or_null("ResumeButton")
	if resume_btn:
		resume_btn.grab_focus()


func hide_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): visible = false)
	resumed.emit()


func _on_resume_pressed() -> void:
	hide_menu()


func _on_reset_pressed() -> void:
	_show_confirm(
		"Reset this scenario?\nAll placed blocks will be lost.",
		func(): get_tree().reload_current_scene()
	)


func _on_main_menu_pressed() -> void:
	_show_confirm(
		"Exit to main menu?\nUnsaved progress will be lost.",
		func(): get_tree().change_scene_to_file("res://scenes/main.tscn")
	)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_confirm(message: String, on_confirm: Callable) -> void:
	## Show a confirmation dialog over the pause menu.
	## Replaces the button panel with a message + Yes/No buttons.
	## On cancel, returns to the main pause menu.
	var confirm_overlay := ColorRect.new()
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.color = Color(0, 0, 0, 0.6)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn := _create_menu_button("CANCEL")
	cancel_btn.custom_minimum_size = Vector2(120, 36)
	cancel_btn.pressed.connect(func(): confirm_overlay.queue_free())
	btn_row.add_child(cancel_btn)

	var confirm_btn := _create_menu_button("CONFIRM")
	confirm_btn.custom_minimum_size = Vector2(120, 36)
	confirm_btn.pressed.connect(
		func():
			confirm_overlay.queue_free()
			on_confirm.call()
	)
	btn_row.add_child(confirm_btn)

	# Style the confirm button with the accent color
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = COLOR_ACCENT
	confirm_style.corner_radius_top_left = 4
	confirm_style.corner_radius_top_right = 4
	confirm_style.corner_radius_bottom_left = 4
	confirm_style.corner_radius_bottom_right = 4
	confirm_style.content_margin_left = 12
	confirm_style.content_margin_right = 12
	confirm_style.content_margin_top = 6
	confirm_style.content_margin_bottom = 6
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	var confirm_hover := confirm_style.duplicate()
	confirm_hover.bg_color = COLOR_ACCENT.lightened(0.15)
	confirm_btn.add_theme_stylebox_override("hover", confirm_hover)

	cancel_btn.grab_focus()
