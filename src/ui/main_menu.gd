class_name MainMenu
extends Control
## Main menu displayed on game launch
## Provides navigation to New Game, Load Game, Settings, Credits, Quit
## See: documentation/ui/menus.md

# Color scheme (same as HUD)
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Signals
signal new_game_pressed
signal continue_pressed
signal load_game_pressed
signal settings_pressed
signal credits_pressed
signal quit_pressed

# UI components
var _title_label: Label
var _tagline_label: Label
var _button_container: VBoxContainer
var _version_label: Label
var _copyright_label: Label
var _continue_button: Button

# State
var _has_saves := false


func _ready() -> void:
	_setup_layout()
	_apply_theme()
	# Check for saved games to show/hide Continue button
	call_deferred("_check_for_saves")


func _setup_layout() -> void:
	# Full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Background panel
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BACKGROUND
	bg.name = "Background"
	add_child(bg)

	# Center container for menu content
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.name = "CenterContainer"
	add_child(center)

	# Main content box
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	content.name = "ContentBox"
	center.add_child(content)

	# Title section
	var title_section := VBoxContainer.new()
	title_section.add_theme_constant_override("separation", 8)
	title_section.name = "TitleSection"
	content.add_child(title_section)

	# Game title
	_title_label = Label.new()
	_title_label.text = "A R C O L O G Y"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", COLOR_TEXT)
	_title_label.name = "TitleLabel"
	title_section.add_child(_title_label)

	# Separator line
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(300, 2)
	sep.name = "TitleSeparator"
	title_section.add_child(sep)

	# Tagline
	_tagline_label = Label.new()
	_tagline_label.text = "Build. Nurture. Flourish."
	_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_label.add_theme_font_size_override("font_size", 18)
	_tagline_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_tagline_label.name = "TaglineLabel"
	title_section.add_child(_tagline_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	content.add_child(spacer)

	# Button container
	_button_container = VBoxContainer.new()
	_button_container.add_theme_constant_override("separation", 12)
	_button_container.name = "ButtonContainer"
	content.add_child(_button_container)

	# Menu buttons
	var new_game_btn := _create_menu_button("NEW GAME")
	new_game_btn.name = "NewGameButton"
	new_game_btn.pressed.connect(_on_new_game_pressed)
	_button_container.add_child(new_game_btn)

	_continue_button = _create_menu_button("CONTINUE")
	_continue_button.name = "ContinueButton"
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.visible = false  # Hidden until we check for saves
	_button_container.add_child(_continue_button)

	var load_btn := _create_menu_button("LOAD GAME")
	load_btn.name = "LoadGameButton"
	load_btn.pressed.connect(_on_load_pressed)
	_button_container.add_child(load_btn)

	var settings_btn := _create_menu_button("SETTINGS")
	settings_btn.name = "SettingsButton"
	settings_btn.pressed.connect(_on_settings_pressed)
	_button_container.add_child(settings_btn)

	var credits_btn := _create_menu_button("CREDITS")
	credits_btn.name = "CreditsButton"
	credits_btn.pressed.connect(_on_credits_pressed)
	_button_container.add_child(credits_btn)

	var quit_btn := _create_menu_button("QUIT")
	quit_btn.name = "QuitButton"
	quit_btn.pressed.connect(_on_quit_pressed)
	_button_container.add_child(quit_btn)

	# Footer with version and copyright
	var footer := HBoxContainer.new()
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -40
	footer.offset_bottom = -8
	footer.offset_left = 16
	footer.offset_right = -16
	footer.name = "Footer"
	add_child(footer)

	_version_label = Label.new()
	_version_label.text = "v0.1.0"
	_version_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_version_label.name = "VersionLabel"
	footer.add_child(_version_label)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)

	_copyright_label = Label.new()
	_copyright_label.text = "© 2024 Arcology Team"
	_copyright_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_copyright_label.name = "CopyrightLabel"
	footer.add_child(_copyright_label)


func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 48)
	btn.focus_mode = Control.FOCUS_ALL

	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
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


func _apply_theme() -> void:
	# Additional theme setup if needed
	pass


func _check_for_saves() -> void:
	# Check if any save files exist
	var save_dir := "user://saves/"
	var dir := DirAccess.open(save_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".save"):
				_has_saves = true
				break
			file_name = dir.get_next()
		dir.list_dir_end()

	_continue_button.visible = _has_saves


func _on_new_game_pressed() -> void:
	new_game_pressed.emit()


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _on_load_pressed() -> void:
	load_game_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_credits_pressed() -> void:
	credits_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()


## Set whether Continue button is visible (for testing)
func set_has_saves(has_saves: bool) -> void:
	_has_saves = has_saves
	if _continue_button:
		_continue_button.visible = has_saves


## Get button by name for testing
func get_button(button_name: String) -> Button:
	return _button_container.get_node_or_null(button_name) as Button


## Check if Continue button is visible
func is_continue_visible() -> bool:
	return _continue_button.visible if _continue_button else false
