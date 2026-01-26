class_name PauseMenu
extends Control
## Pause menu overlay displayed during gameplay
## Accessed via Esc key, dims background and shows menu options
## See: documentation/ui/menus.md

# Color scheme
const COLOR_OVERLAY := Color(0, 0, 0, 0.5)  # 50% opacity overlay
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_ACCENT := Color("#e94560")

# Animation
const FADE_DURATION := 0.2

# Signals
signal resume_pressed
signal save_game_pressed
signal load_game_pressed
signal settings_pressed
signal help_pressed
signal main_menu_pressed
signal quit_pressed

# UI components
var _overlay: ColorRect
var _panel: PanelContainer
var _button_container: VBoxContainer


func _ready() -> void:
	_setup_layout()
	# Start hidden
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

	# Main panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 400)
	_panel.name = "MenuPanel"
	center.add_child(_panel)

	# Style the panel
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
	title.text = "GAME PAUSED"
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

	# Menu buttons
	var resume_btn := _create_menu_button("RESUME")
	resume_btn.name = "ResumeButton"
	resume_btn.pressed.connect(_on_resume_pressed)
	_button_container.add_child(resume_btn)

	var save_btn := _create_menu_button("SAVE GAME")
	save_btn.name = "SaveGameButton"
	save_btn.pressed.connect(_on_save_game_pressed)
	_button_container.add_child(save_btn)

	var load_btn := _create_menu_button("LOAD GAME")
	load_btn.name = "LoadGameButton"
	load_btn.pressed.connect(_on_load_game_pressed)
	_button_container.add_child(load_btn)

	var settings_btn := _create_menu_button("SETTINGS")
	settings_btn.name = "SettingsButton"
	settings_btn.pressed.connect(_on_settings_pressed)
	_button_container.add_child(settings_btn)

	var help_btn := _create_menu_button("HELP")
	help_btn.name = "HelpButton"
	help_btn.pressed.connect(_on_help_pressed)
	_button_container.add_child(help_btn)

	var main_menu_btn := _create_menu_button("MAIN MENU")
	main_menu_btn.name = "MainMenuButton"
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	_button_container.add_child(main_menu_btn)

	var quit_btn := _create_menu_button("QUIT GAME")
	quit_btn.name = "QuitButton"
	quit_btn.pressed.connect(_on_quit_pressed)
	_button_container.add_child(quit_btn)


func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 40)
	btn.focus_mode = Control.FOCUS_ALL

	# Style the button
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

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)

	return btn


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Esc key
		if visible:
			hide_menu()
		get_viewport().set_input_as_handled()


## Show the pause menu with fade animation
func show_menu() -> void:
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

	# Focus first button
	var resume_btn: Button = _button_container.get_node_or_null("ResumeButton")
	if resume_btn:
		resume_btn.grab_focus()


## Hide the pause menu with fade animation
func hide_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): visible = false)
	resume_pressed.emit()


func _on_resume_pressed() -> void:
	hide_menu()


func _on_save_game_pressed() -> void:
	save_game_pressed.emit()


func _on_load_game_pressed() -> void:
	load_game_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_help_pressed() -> void:
	help_pressed.emit()


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()


## Get button by name for testing
func get_button(button_name: String) -> Button:
	return _button_container.get_node_or_null(button_name) as Button


## Check if menu is currently shown
func is_shown() -> bool:
	return visible
