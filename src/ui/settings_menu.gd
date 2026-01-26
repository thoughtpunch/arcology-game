class_name SettingsMenu
extends Control
## Settings menu with tabbed interface for Game, Graphics, Audio, Controls, Accessibility
## See: documentation/ui/menus.md

# Color scheme
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Tab identifiers
enum Tab {
	GAME,
	GRAPHICS,
	AUDIO,
	CONTROLS,
	ACCESSIBILITY
}

# Signals
signal settings_changed(setting_name: String, value)
signal back_pressed
signal apply_pressed
signal reset_defaults_pressed

# UI components
var _panel: PanelContainer
var _tab_container: HBoxContainer
var _content_container: Control
var _current_tab: Tab = Tab.GAME
var _tab_buttons: Array[Button] = []
var _tab_contents: Dictionary = {}  # Tab -> Control

# Settings values (defaults)
var _settings := {
	# Game tab
	"auto_save_interval": 10,  # minutes
	"edge_scrolling": true,
	"scroll_speed": 50,  # percentage
	"pause_on_lost_focus": true,
	"tutorial_hints": false,
	"show_news_popups": true,
	"auto_pause_emergencies": true,
	"notification_sound": true,
	# Graphics tab
	"resolution": "1920x1080",
	"display_mode": "Fullscreen",
	"vsync": true,
	"frame_rate_limit": 60,
	"sprite_quality": "High",
	"shadow_quality": "Medium",
	"animation_quality": "High",
	"particle_effects": true,
	"ui_scale": 100,
	"show_fps": false,
	# Audio tab
	"master_volume": 80,
	"music_volume": 60,
	"sfx_volume": 80,
	"ambient_volume": 40,
	"ui_volume": 100,
	"mute_when_minimized": true,
	"dynamic_music": true,
	# Controls tab
	"invert_scroll_zoom": false,
	"mouse_sensitivity": 50,
	# Accessibility tab
	"colorblind_mode": "Off",
	"high_contrast_ui": false,
	"reduce_motion": false,
	"screen_flash_effects": true,
	"font_size": "Medium",
	"dyslexia_font": false,
	"extended_tooltips": false,
	"slower_game_speed_max": false
}


func _ready() -> void:
	_setup_layout()
	_show_tab(Tab.GAME)


func _setup_layout() -> void:
	# Full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BACKGROUND
	bg.name = "Background"
	add_child(bg)

	# Main panel with margins
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 80
	_panel.offset_right = -80
	_panel.offset_top = 60
	_panel.offset_bottom = -60
	_panel.name = "SettingsPanel"
	add_child(_panel)

	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", panel_style)

	# Main content layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.name = "MainVBox"
	_panel.add_child(vbox)

	# Header with title and back button
	var header := HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.name = "TitleLabel"
	header.add_child(title)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(80, 32)
	back_btn.name = "BackButton"
	back_btn.pressed.connect(_on_back_pressed)
	_style_button(back_btn)
	header.add_child(back_btn)

	# Tab bar
	_tab_container = HBoxContainer.new()
	_tab_container.add_theme_constant_override("separation", 4)
	_tab_container.name = "TabContainer"
	vbox.add_child(_tab_container)

	var tab_names := ["Game", "Graphics", "Audio", "Controls", "Accessibility"]
	for i in range(tab_names.size()):
		var tab_btn := Button.new()
		tab_btn.text = tab_names[i]
		tab_btn.toggle_mode = true
		tab_btn.custom_minimum_size = Vector2(100, 36)
		tab_btn.name = "%sTab" % tab_names[i]
		tab_btn.pressed.connect(_on_tab_pressed.bind(i))
		_style_tab_button(tab_btn)
		_tab_container.add_child(tab_btn)
		_tab_buttons.append(tab_btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Tab content area
	_content_container = Control.new()
	_content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_container.name = "ContentContainer"
	vbox.add_child(_content_container)

	# Create all tab contents
	_create_game_tab()
	_create_graphics_tab()
	_create_audio_tab()
	_create_controls_tab()
	_create_accessibility_tab()

	# Footer with action buttons
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.name = "Footer"
	vbox.add_child(footer)

	var reset_btn := Button.new()
	reset_btn.text = "Reset Defaults"
	reset_btn.custom_minimum_size = Vector2(120, 36)
	reset_btn.name = "ResetButton"
	reset_btn.pressed.connect(_on_reset_pressed)
	_style_button(reset_btn)
	footer.add_child(reset_btn)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.custom_minimum_size = Vector2(100, 36)
	apply_btn.name = "ApplyButton"
	apply_btn.pressed.connect(_on_apply_pressed)
	_style_button(apply_btn)
	footer.add_child(apply_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.name = "CancelButton"
	cancel_btn.pressed.connect(_on_back_pressed)
	_style_button(cancel_btn)
	footer.add_child(cancel_btn)


func _create_game_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.name = "GameTabScroll"
	_content_container.add_child(scroll)
	_tab_contents[Tab.GAME] = scroll

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Gameplay section
	vbox.add_child(_create_section_header("GAMEPLAY"))
	vbox.add_child(_create_dropdown_setting("Auto-Save Interval", "auto_save_interval",
		["5 minutes", "10 minutes", "15 minutes", "30 minutes", "Disabled"]))
	vbox.add_child(_create_toggle_setting("Edge Scrolling", "edge_scrolling"))
	vbox.add_child(_create_slider_setting("Scroll Speed", "scroll_speed", 0, 100))
	vbox.add_child(_create_toggle_setting("Pause on Lost Focus", "pause_on_lost_focus"))
	vbox.add_child(_create_toggle_setting("Tutorial Hints", "tutorial_hints"))

	# Notifications section
	vbox.add_child(_create_section_header("NOTIFICATIONS"))
	vbox.add_child(_create_toggle_setting("Show News Popups", "show_news_popups"))
	vbox.add_child(_create_toggle_setting("Auto-Pause Emergencies", "auto_pause_emergencies"))
	vbox.add_child(_create_toggle_setting("Notification Sound", "notification_sound"))


func _create_graphics_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.name = "GraphicsTabScroll"
	_content_container.add_child(scroll)
	_tab_contents[Tab.GRAPHICS] = scroll

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Display section
	vbox.add_child(_create_section_header("DISPLAY"))
	vbox.add_child(_create_dropdown_setting("Resolution", "resolution",
		["1280x720", "1920x1080", "2560x1440", "3840x2160"]))
	vbox.add_child(_create_dropdown_setting("Display Mode", "display_mode",
		["Windowed", "Fullscreen", "Borderless"]))
	vbox.add_child(_create_toggle_setting("VSync", "vsync"))
	vbox.add_child(_create_dropdown_setting("Frame Rate Limit", "frame_rate_limit",
		["30 FPS", "60 FPS", "120 FPS", "Unlimited"]))

	# Quality section
	vbox.add_child(_create_section_header("QUALITY"))
	vbox.add_child(_create_dropdown_setting("Sprite Quality", "sprite_quality",
		["Low", "Medium", "High"]))
	vbox.add_child(_create_dropdown_setting("Shadow Quality", "shadow_quality",
		["Off", "Low", "Medium", "High"]))
	vbox.add_child(_create_dropdown_setting("Animation Quality", "animation_quality",
		["Low", "Medium", "High"]))
	vbox.add_child(_create_toggle_setting("Particle Effects", "particle_effects"))

	# UI section
	vbox.add_child(_create_section_header("UI"))
	vbox.add_child(_create_slider_setting("UI Scale", "ui_scale", 75, 150))
	vbox.add_child(_create_toggle_setting("Show FPS Counter", "show_fps"))


func _create_audio_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.name = "AudioTabScroll"
	_content_container.add_child(scroll)
	_tab_contents[Tab.AUDIO] = scroll

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Volume section
	vbox.add_child(_create_section_header("VOLUME"))
	vbox.add_child(_create_slider_setting("Master Volume", "master_volume", 0, 100))
	vbox.add_child(_create_slider_setting("Music Volume", "music_volume", 0, 100))
	vbox.add_child(_create_slider_setting("Sound Effects", "sfx_volume", 0, 100))
	vbox.add_child(_create_slider_setting("Ambient Sounds", "ambient_volume", 0, 100))
	vbox.add_child(_create_slider_setting("UI Sounds", "ui_volume", 0, 100))

	# Options section
	vbox.add_child(_create_section_header("OPTIONS"))
	vbox.add_child(_create_toggle_setting("Mute When Minimized", "mute_when_minimized"))
	vbox.add_child(_create_toggle_setting("Dynamic Music", "dynamic_music"))


func _create_controls_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.name = "ControlsTabScroll"
	_content_container.add_child(scroll)
	_tab_contents[Tab.CONTROLS] = scroll

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Keyboard section
	vbox.add_child(_create_section_header("KEYBOARD - CAMERA"))
	vbox.add_child(_create_keybind_setting("Pan Up", "W"))
	vbox.add_child(_create_keybind_setting("Pan Down", "S"))
	vbox.add_child(_create_keybind_setting("Pan Left", "A"))
	vbox.add_child(_create_keybind_setting("Pan Right", "D"))
	vbox.add_child(_create_keybind_setting("Rotate Left", "Q"))
	vbox.add_child(_create_keybind_setting("Rotate Right", "E"))
	vbox.add_child(_create_keybind_setting("Zoom In", "+"))
	vbox.add_child(_create_keybind_setting("Zoom Out", "-"))
	vbox.add_child(_create_keybind_setting("Reset Zoom", "Home"))
	vbox.add_child(_create_keybind_setting("Toggle Camera Panel", "H"))

	# Building section
	vbox.add_child(_create_section_header("KEYBOARD - BUILDING"))
	vbox.add_child(_create_keybind_setting("Floor Up", "Page Up"))
	vbox.add_child(_create_keybind_setting("Floor Down", "Page Down"))
	vbox.add_child(_create_keybind_setting("Toggle All Floors", "V"))

	# Game section
	vbox.add_child(_create_section_header("KEYBOARD - GAME"))
	vbox.add_child(_create_keybind_setting("Pause Menu", "Escape"))
	vbox.add_child(_create_keybind_setting("Pause/Play", "Space"))

	# Mouse section
	vbox.add_child(_create_section_header("MOUSE"))
	vbox.add_child(_create_toggle_setting("Invert Scroll Zoom", "invert_scroll_zoom"))
	vbox.add_child(_create_slider_setting("Mouse Sensitivity", "mouse_sensitivity", 0, 100))


func _create_accessibility_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.name = "AccessibilityTabScroll"
	_content_container.add_child(scroll)
	_tab_contents[Tab.ACCESSIBILITY] = scroll

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Visual section
	vbox.add_child(_create_section_header("VISUAL"))
	vbox.add_child(_create_dropdown_setting("Color Blind Mode", "colorblind_mode",
		["Off", "Deuteranopia", "Protanopia", "Tritanopia"]))
	vbox.add_child(_create_toggle_setting("High Contrast UI", "high_contrast_ui"))
	vbox.add_child(_create_toggle_setting("Reduce Motion", "reduce_motion"))
	vbox.add_child(_create_toggle_setting("Screen Flash Effects", "screen_flash_effects"))

	# Text section
	vbox.add_child(_create_section_header("TEXT"))
	vbox.add_child(_create_dropdown_setting("Font Size", "font_size",
		["Small", "Medium", "Large", "Extra Large"]))
	vbox.add_child(_create_toggle_setting("Dyslexia-Friendly Font", "dyslexia_font"))

	# Gameplay section
	vbox.add_child(_create_section_header("GAMEPLAY"))
	vbox.add_child(_create_toggle_setting("Extended Tooltips", "extended_tooltips"))
	vbox.add_child(_create_toggle_setting("Slower Game Speed Max", "slower_game_speed_max"))


func _create_section_header(title: String) -> Label:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	label.name = "%sHeader" % title.to_pascal_case()
	return label


func _create_toggle_setting(label_text: String, setting_key: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.name = "%sSetting" % setting_key.to_pascal_case()

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var toggle := CheckButton.new()
	toggle.button_pressed = _settings.get(setting_key, false)
	toggle.name = "%sToggle" % setting_key.to_pascal_case()
	toggle.toggled.connect(_on_setting_changed.bind(setting_key))
	hbox.add_child(toggle)

	return hbox


func _create_slider_setting(label_text: String, setting_key: String, min_val: float, max_val: float) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.name = "%sSetting" % setting_key.to_pascal_case()

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = _settings.get(setting_key, 50)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 0)
	slider.name = "%sSlider" % setting_key.to_pascal_case()
	slider.value_changed.connect(_on_slider_changed.bind(setting_key))
	hbox.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(slider.value)
	value_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.name = "%sValue" % setting_key.to_pascal_case()
	hbox.add_child(value_label)

	# Update value label when slider changes
	slider.value_changed.connect(func(val: float): value_label.text = "%d%%" % int(val))

	return hbox


func _create_dropdown_setting(label_text: String, setting_key: String, options: Array) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.name = "%sSetting" % setting_key.to_pascal_case()

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(180, 0)
	dropdown.name = "%sDropdown" % setting_key.to_pascal_case()
	for option in options:
		dropdown.add_item(option)
	# Select current value
	var current_value = _settings.get(setting_key, "")
	for i in range(options.size()):
		if str(options[i]).begins_with(str(current_value)):
			dropdown.selected = i
			break
	dropdown.item_selected.connect(_on_dropdown_changed.bind(setting_key, options))
	hbox.add_child(dropdown)

	return hbox


func _create_keybind_setting(action_name: String, current_key: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.name = "%sSetting" % action_name.to_pascal_case().replace(" ", "")

	var label := Label.new()
	label.text = action_name
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var key_btn := Button.new()
	key_btn.text = "[%s]" % current_key
	key_btn.custom_minimum_size = Vector2(100, 0)
	key_btn.name = "%sKeyButton" % action_name.to_pascal_case().replace(" ", "")
	hbox.add_child(key_btn)

	var rebind_btn := Button.new()
	rebind_btn.text = "Rebind"
	rebind_btn.custom_minimum_size = Vector2(70, 0)
	_style_button(rebind_btn)
	hbox.add_child(rebind_btn)

	return hbox


func _style_button(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)


func _style_tab_button(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = COLOR_BUTTON_ACTIVE
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)


func _show_tab(tab: Tab) -> void:
	_current_tab = tab

	# Update tab button states
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].button_pressed = (i == tab)

	# Show only the selected tab content
	for t in _tab_contents:
		_tab_contents[t].visible = (t == tab)


func _on_tab_pressed(tab_index: int) -> void:
	_show_tab(tab_index as Tab)


func _on_setting_changed(value: bool, setting_key: String) -> void:
	_settings[setting_key] = value
	settings_changed.emit(setting_key, value)


func _on_slider_changed(value: float, setting_key: String) -> void:
	_settings[setting_key] = int(value)
	settings_changed.emit(setting_key, int(value))


func _on_dropdown_changed(index: int, setting_key: String, options: Array) -> void:
	_settings[setting_key] = options[index]
	settings_changed.emit(setting_key, options[index])


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_apply_pressed() -> void:
	apply_pressed.emit()


func _on_reset_pressed() -> void:
	reset_defaults_pressed.emit()


## Get current settings
func get_settings() -> Dictionary:
	return _settings.duplicate()


## Set settings (used when loading)
func set_settings(settings: Dictionary) -> void:
	for key in settings:
		if key in _settings:
			_settings[key] = settings[key]


## Get current tab
func get_current_tab() -> Tab:
	return _current_tab


## Set current tab
func set_current_tab(tab: Tab) -> void:
	_show_tab(tab)
