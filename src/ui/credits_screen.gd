class_name CreditsScreen
extends Control
## Credits screen with scrolling credits text
## Displays game info, team, and acknowledgements

# Color scheme (same as other menus)
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Signals
signal back_pressed

# Scroll settings
const SCROLL_SPEED := 40.0  # pixels per second
const SCROLL_PAUSE_AT_TOP := 2.0  # seconds to wait before scrolling

# Credits content
const CREDITS_TEXT := """
A R C O L O G Y
━━━━━━━━━━━━━━━━━━━━━━━

Build. Nurture. Flourish.

Version 0.1.0




GAME DESIGN
━━━━━━━━━━━━━━━━━━━━━━━

Daniel Barrett




PROGRAMMING
━━━━━━━━━━━━━━━━━━━━━━━

Daniel Barrett
Claude (Anthropic)




CONCEPT & INSPIRATION
━━━━━━━━━━━━━━━━━━━━━━━

SimCity (Maxis)
SimTower (Maxis)
Dwarf Fortress (Bay 12 Games)
Project Highrise (SomaSim)




BUILT WITH
━━━━━━━━━━━━━━━━━━━━━━━

Godot Engine 4.5
GDScript
Beehave (Behavior Trees)
LimboAI




SPECIAL THANKS
━━━━━━━━━━━━━━━━━━━━━━━

The Godot Community
Anthropic
All playtesters and contributors




━━━━━━━━━━━━━━━━━━━━━━━

© 2024 Arcology Team
All Rights Reserved

━━━━━━━━━━━━━━━━━━━━━━━

Thank you for playing!
"""

# UI components
var _scroll_container: ScrollContainer
var _credits_label: Label
var _back_button: Button

# State
var _auto_scroll := true
var _scroll_timer := 0.0
var _initial_pause := SCROLL_PAUSE_AT_TOP


func _ready() -> void:
	_setup_layout()


func _process(delta: float) -> void:
	if not visible or not _auto_scroll:
		return

	# Initial pause before scrolling
	if _initial_pause > 0:
		_initial_pause -= delta
		return

	# Auto-scroll
	if _scroll_container:
		var current := _scroll_container.scroll_vertical
		var max_scroll: int = _credits_label.size.y - _scroll_container.size.y
		if current < max_scroll:
			_scroll_container.scroll_vertical = current + int(SCROLL_SPEED * delta)
		else:
			# Reset to top after reaching bottom
			_scroll_timer += delta
			if _scroll_timer > 3.0:  # Wait 3 seconds then restart
				_scroll_container.scroll_vertical = 0
				_scroll_timer = 0.0
				_initial_pause = SCROLL_PAUSE_AT_TOP


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

	# Top bar with back button
	var top_bar := _create_top_bar()
	main_vbox.add_child(top_bar)

	# Credits scroll area
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.name = "ScrollContainer"
	main_vbox.add_child(_scroll_container)

	# Credits content with padding
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 100)
	content_margin.add_theme_constant_override("margin_right", 100)
	content_margin.add_theme_constant_override("margin_top", 50)
	content_margin.add_theme_constant_override("margin_bottom", 200)
	content_margin.name = "ContentMargin"
	_scroll_container.add_child(content_margin)

	# Credits label
	_credits_label = Label.new()
	_credits_label.text = CREDITS_TEXT
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.add_theme_font_size_override("font_size", 20)
	_credits_label.add_theme_color_override("font_color", COLOR_TEXT)
	_credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_label.name = "CreditsLabel"
	content_margin.add_child(_credits_label)

	# Pause scrolling when user interacts
	_scroll_container.gui_input.connect(_on_scroll_input)


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
	title.text = "CREDITS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	hbox.add_child(title)

	# Right spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size = Vector2(120, 0)  # Match back button width
	hbox.add_child(spacer2)

	return top_bar


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


func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# User interacted, pause auto-scroll temporarily
		_auto_scroll = false
		# Resume after a delay
		get_tree().create_timer(5.0).timeout.connect(func(): _auto_scroll = true)


func _on_back_pressed() -> void:
	back_pressed.emit()


## Reset scroll position (call when showing)
func reset_scroll() -> void:
	if _scroll_container:
		_scroll_container.scroll_vertical = 0
	_initial_pause = SCROLL_PAUSE_AT_TOP
	_scroll_timer = 0.0
	_auto_scroll = true


## Get the credits text (for testing)
func get_credits_text() -> String:
	return CREDITS_TEXT
