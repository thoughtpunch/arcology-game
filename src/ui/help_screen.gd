class_name HelpScreen
extends Control
## Help screen with controls reference and gameplay tips
## Accessible from pause menu

signal back_pressed

# Color scheme (same as other menus)
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Help content sections
const CONTROLS_TEXT := """CONTROLS
━━━━━━━━━━━━━━━━━━━━━━━

Camera Movement
  WASD / Arrow Keys  -  Pan camera
  Middle Mouse Drag  -  Pan camera
  Right Mouse Drag   -  Pan camera

Camera Zoom
  Mouse Scroll       -  Zoom in/out
  + / -              -  Zoom in/out

Camera Rotation
  Q                  -  Rotate left
  E                  -  Rotate right

View Modes
  V                  -  Toggle all floors view
  I / T              -  Toggle isometric/top-down
  PageUp / PageDown  -  Change current floor

Building
  Left Click         -  Place block
  Right Click        -  Remove block
  1-7                -  Select block category

Game Speed
  Space              -  Pause/resume
  1, 2, 3            -  Set game speed

Menus
  Escape             -  Pause menu
  H                  -  Toggle camera controls
"""

const TIPS_TEXT := """GAMEPLAY TIPS
━━━━━━━━━━━━━━━━━━━━━━━

Getting Started
• Start with an entrance block at ground level
• Connect corridors to create pathways
• Add residential blocks for population
• Stairs connect different floors

Building Efficiently
• Blocks must be connected to the entrance
• Unconnected blocks won't function
• Plan vertical access early (stairs/elevators)
• Leave room for expansion

Resource Management
• Each block has construction and maintenance costs
• Balance income from residents with expenses
• Auto-save protects your progress

Environment Factors
• Light reaches blocks near the exterior
• Air quality improves near open spaces
• Noise travels from commercial areas
• Safety decreases in dark, isolated areas

Resident Happiness
• Meet basic needs: shelter, safety
• Provide amenities: shops, parks
• Create community spaces
• Balance residential and commercial
"""

# UI components
var _tab_container: TabContainer
var _back_button: Button


func _ready() -> void:
	_setup_layout()


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

	# Main layout
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	main_vbox.name = "MainLayout"
	add_child(main_vbox)

	# Top bar
	var top_bar := _create_top_bar()
	main_vbox.add_child(top_bar)

	# Tab container for help sections
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.name = "TabContainer"
	main_vbox.add_child(_tab_container)

	# Style tab container
	var tab_style := StyleBoxFlat.new()
	tab_style.bg_color = COLOR_PANEL
	_tab_container.add_theme_stylebox_override("panel", tab_style)

	# Controls tab
	var controls_scroll := _create_help_tab("Controls", CONTROLS_TEXT)
	_tab_container.add_child(controls_scroll)

	# Tips tab
	var tips_scroll := _create_help_tab("Tips", TIPS_TEXT)
	_tab_container.add_child(tips_scroll)


func _create_top_bar() -> Control:
	var top_bar := PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 60)
	top_bar.name = "TopBar"

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	top_bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_child(hbox)

	# Back button
	_back_button = Button.new()
	_back_button.text = "< BACK"
	_back_button.custom_minimum_size = Vector2(120, 40)
	_back_button.pressed.connect(_on_back_pressed)
	_style_button(_back_button)
	hbox.add_child(_back_button)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Title
	var title := Label.new()
	title.text = "HELP"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	hbox.add_child(title)

	# Right spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(spacer2)

	return top_bar


func _create_help_tab(tab_name: String, content: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)

	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)

	return scroll


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := hover.duplicate()
	pressed.bg_color = COLOR_BUTTON_HOVER.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)


func _on_back_pressed() -> void:
	back_pressed.emit()


## Get controls text (for testing)
func get_controls_text() -> String:
	return CONTROLS_TEXT


## Get tips text (for testing)
func get_tips_text() -> String:
	return TIPS_TEXT
