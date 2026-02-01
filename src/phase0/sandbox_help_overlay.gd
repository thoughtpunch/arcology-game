extends Control

## Help overlay showing all keyboard/mouse controls.
## Toggle with F1 or ? (Shift+/).
## Does not pause the game.

const COLOR_BG := Color(0.0, 0.0, 0.0, 0.7)
const COLOR_PANEL := Color(0.1, 0.12, 0.18, 0.95)
const COLOR_HEADING := Color(0.0, 0.9, 0.9)
const COLOR_KEY := Color(0.9, 0.85, 0.6)
const COLOR_DESC := Color(0.8, 0.8, 0.82)
const COLOR_DIM := Color(0.5, 0.5, 0.55)

const CONTROLS := [
	["BUILDING", ""],
	["LMB", "Place block"],
	["RMB (tap)", "Remove block / dig ground"],
	["Double-click", "Focus camera on target"],
	[",  (comma)", "Rotate block counter-clockwise"],
	[".  (period)", "Rotate block clockwise"],
	["Tab / Shift+Tab", "Cycle block category"],
	["1-9", "Select block within category"],
	["", ""],
	["SELECTION", ""],
	["Ctrl + LMB", "Select / toggle block"],
	["Shift + LMB", "Add block to selection"],
	["Ctrl + Shift + LMB", "Remove block from selection"],
	["Ctrl + Alt + LMB", "Select-through (behind topmost)"],
	["", ""],
	["CAMERA — MOUSE", ""],
	["RMB + drag", "Orbit (rotate + tilt)"],
	["MMB + drag", "Pan (truck in camera plane)"],
	["Scroll wheel", "Zoom in / out"],
	["Shift + LMB drag", "Zoom (trackpad-friendly)"],
	["", ""],
	["CAMERA — KEYBOARD", ""],
	["WASD", "Pan camera (scales with zoom)"],
	["Q / Space", "Move camera up"],
	["E / C", "Move camera down"],
	["F", "Frame cursor (focus on hit point)"],
	["H", "Return to home position"],
	["Z", "Level horizon (reset tilt)"],
	["Backspace", "Previous camera position"],
	["Shift + Backspace", "Next camera position"],
	["", ""],
	["SPEED MODIFIERS", ""],
	["Shift (hold)", "0.25x precision mode"],
	["Ctrl (hold)", "3x boost"],
	["Shift + Ctrl", "10x sprint"],
	["", ""],
	["CAMERA — VIEWS", ""],
	["Numpad 1 / 3 / 7", "Front / Right / Top view"],
	["Numpad 5", "Toggle perspective / orthographic"],
	["[  /  ]", "Decrease / increase FOV"],
	["", ""],
	["CAMERA — BOOKMARKS", ""],
	["Ctrl + 1-9", "Save camera position to slot"],
	["Alt + 1-9", "Recall saved camera position"],
	["", ""],
	["INTERFACE", ""],
	["` (backtick)", "Toggle UI visibility"],
	["F1  or  ?", "Toggle this help overlay"],
	["F3", "Toggle debug panel"],
	["ESC", "Pause menu"],
]

var _overlay: ColorRect
var _panel: PanelContainer


func _ready() -> void:
	_setup_layout()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			visible = not visible
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SLASH and event.shift_pressed:
			visible = not visible
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			visible = false
			get_viewport().set_input_as_handled()


func _setup_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = COLOR_BG
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_HEADING)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Control rows
	for entry in CONTROLS:
		var key: String = entry[0]
		var desc: String = entry[1]

		if key == "" and desc == "":
			# Spacer
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 6)
			vbox.add_child(spacer)
			continue

		if desc == "":
			# Section heading
			var heading := Label.new()
			heading.text = key
			heading.add_theme_font_size_override("font_size", 13)
			heading.add_theme_color_override("font_color", COLOR_HEADING)
			vbox.add_child(heading)
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var key_label := Label.new()
		key_label.text = key
		key_label.custom_minimum_size = Vector2(180, 0)
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.add_theme_color_override("font_color", COLOR_KEY)
		row.add_child(key_label)

		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", COLOR_DESC)
		row.add_child(desc_label)

		vbox.add_child(row)

	# Footer
	var footer_sep := HSeparator.new()
	vbox.add_child(footer_sep)
	var footer := Label.new()
	footer.text = "Press F1 or ? to close"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", COLOR_DIM)
	vbox.add_child(footer)
