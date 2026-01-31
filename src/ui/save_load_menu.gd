class_name SaveLoadMenu
extends Control
## Save/Load menu for game state persistence
## Handles save game creation, loading, and auto-save management
## See: documentation/ui/menus.md

signal back_pressed
signal save_selected(save_name: String)
signal load_selected(save_path: String)
signal save_deleted(save_path: String)
signal delete_confirmation_requested(save_name: String, save_path: String)

# Mode
enum Mode { SAVE, LOAD }

# Color scheme
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_CARD := Color("#1a1a2e")
const COLOR_CARD_SELECTED := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_DANGER := Color("#8b0000")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_TEXT_MUTED := Color("#888888")
const COLOR_ACCENT := Color("#e94560")
const COLOR_AUTO_TAG := Color("#4a90d9")

# Save directory
const SAVE_DIR := "user://saves/"
const AUTO_SAVE_PREFIX := "autosave_"
const MAX_AUTO_SAVES := 3

# UI components
var _panel: PanelContainer
var _save_name_input: LineEdit
var _save_list: VBoxContainer
var _selected_save_path := ""
var _mode := Mode.LOAD
var _pending_delete_path := ""  # Path of save awaiting deletion confirmation


func _ready() -> void:
	_ensure_save_directory()
	_setup_layout()
	call_deferred("_refresh_save_list")


func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


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

	# Main panel
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 100
	_panel.offset_right = -100
	_panel.offset_top = 60
	_panel.offset_bottom = -60
	_panel.name = "MainPanel"
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

	# Main vbox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.name = "MainVBox"
	_panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)

	var title := Label.new()
	title.text = "LOAD GAME"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.name = "TitleLabel"
	header.add_child(title)

	var back_btn := _create_button("Back")
	back_btn.name = "BackButton"
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	# Save name input (only visible in save mode)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	name_row.name = "SaveNameRow"
	vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = "Save Name:"
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_row.add_child(name_label)

	_save_name_input = LineEdit.new()
	_save_name_input.text = "New Save"
	_save_name_input.custom_minimum_size = Vector2(300, 0)
	_save_name_input.name = "SaveNameInput"
	name_row.add_child(_save_name_input)

	# Separator
	vbox.add_child(HSeparator.new())

	# Filter/sort bar (for load mode)
	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 12)
	filter_bar.name = "FilterBar"
	vbox.add_child(filter_bar)

	var filter_label := Label.new()
	filter_label.text = "Filter:"
	filter_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	filter_bar.add_child(filter_label)

	var filter_dropdown := OptionButton.new()
	filter_dropdown.add_item("All Saves")
	filter_dropdown.add_item("Manual Only")
	filter_dropdown.add_item("Auto-saves Only")
	filter_dropdown.custom_minimum_size = Vector2(150, 0)
	filter_dropdown.name = "FilterDropdown"
	filter_bar.add_child(filter_dropdown)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_bar.add_child(spacer)

	var sort_label := Label.new()
	sort_label.text = "Sort:"
	sort_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	filter_bar.add_child(sort_label)

	var sort_dropdown := OptionButton.new()
	sort_dropdown.add_item("Most Recent")
	sort_dropdown.add_item("Oldest First")
	sort_dropdown.add_item("Name A-Z")
	sort_dropdown.custom_minimum_size = Vector2(150, 0)
	sort_dropdown.name = "SortDropdown"
	filter_bar.add_child(sort_dropdown)

	# Section header
	var existing_header := Label.new()
	existing_header.text = "EXISTING SAVES"
	existing_header.add_theme_font_size_override("font_size", 14)
	existing_header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	existing_header.name = "ExistingSavesHeader"
	vbox.add_child(existing_header)

	# Save list (scrollable)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "SaveListScroll"
	vbox.add_child(scroll)

	_save_list = VBoxContainer.new()
	_save_list.add_theme_constant_override("separation", 8)
	_save_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_list.name = "SaveList"
	scroll.add_child(_save_list)

	# Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.name = "Footer"
	vbox.add_child(footer)

	var cancel_btn := _create_button("Cancel")
	cancel_btn.name = "CancelButton"
	cancel_btn.pressed.connect(_on_back_pressed)
	footer.add_child(cancel_btn)

	var action_btn := _create_button("Save New")
	action_btn.name = "ActionButton"
	action_btn.custom_minimum_size = Vector2(120, 40)
	action_btn.pressed.connect(_on_action_pressed)
	footer.add_child(action_btn)


func _create_save_card(save_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)
	card.name = "SaveCard_%s" % save_data.get("filename", "unknown")

	# Card style
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COLOR_CARD
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card_style.border_color = Color.TRANSPARENT
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# Thumbnail placeholder
	var thumb := ColorRect.new()
	thumb.custom_minimum_size = Vector2(64, 64)
	thumb.color = COLOR_BUTTON
	thumb.name = "Thumbnail"
	hbox.add_child(thumb)

	# Info section
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 2)
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_box)

	# Name row with auto tag
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_box.add_child(name_row)

	var name_label := Label.new()
	name_label.text = save_data.get("name", "Unknown Save")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.name = "NameLabel"
	name_row.add_child(name_label)

	if save_data.get("is_auto", false):
		var auto_tag := Label.new()
		auto_tag.text = "[AUTO]"
		auto_tag.add_theme_font_size_override("font_size", 12)
		auto_tag.add_theme_color_override("font_color", COLOR_AUTO_TAG)
		name_row.add_child(auto_tag)

	var date_label := Label.new()
	date_label.text = "Saved: %s" % save_data.get("date", "Unknown")
	date_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	date_label.name = "DateLabel"
	info_box.add_child(date_label)

	var stats_label := Label.new()
	stats_label.text = (
		"Pop: %s | AEI: %d | $%s"
		% [
			_format_number(save_data.get("population", 0)),
			save_data.get("aei", 0),
			_format_number(save_data.get("money", 0))
		]
	)
	stats_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	stats_label.name = "StatsLabel"
	info_box.add_child(stats_label)

	if save_data.has("scenario") and save_data.has("playtime"):
		var extra_label := Label.new()
		extra_label.text = "Scenario: %s | Playtime: %s" % [save_data.scenario, save_data.playtime]
		extra_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		extra_label.name = "ExtraLabel"
		info_box.add_child(extra_label)

	# Action buttons
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 4)
	hbox.add_child(btn_box)

	var save_path: String = save_data.get("path", "")

	if _mode == Mode.SAVE:
		var overwrite_btn := _create_small_button("Overwrite")
		overwrite_btn.name = "OverwriteButton"
		overwrite_btn.pressed.connect(_on_overwrite_pressed.bind(save_path))
		btn_box.add_child(overwrite_btn)
	else:
		var load_btn := _create_small_button("Load")
		load_btn.name = "LoadButton"
		load_btn.pressed.connect(_on_load_pressed.bind(save_path))
		btn_box.add_child(load_btn)

	var delete_btn := _create_small_button("Delete")
	delete_btn.name = "DeleteButton"
	delete_btn.pressed.connect(_on_delete_pressed.bind(save_path))
	# Style delete button red
	var delete_style := delete_btn.get_theme_stylebox("normal").duplicate()
	delete_style.bg_color = COLOR_BUTTON_DANGER
	delete_btn.add_theme_stylebox_override("normal", delete_style)
	btn_box.add_child(delete_btn)

	return card


func _create_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 36)

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

	btn.add_theme_color_override("font_color", COLOR_TEXT)

	return btn


func _create_small_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(70, 28)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 3
	normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_left = 3
	normal_style.corner_radius_bottom_right = 3
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)

	return btn


func _refresh_save_list() -> void:
	# Clear existing
	for child in _save_list.get_children():
		child.queue_free()

	# Get all saves
	var saves := _get_all_saves()

	# Sort by date (most recent first)
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	# Create cards
	for save_data in saves:
		var card := _create_save_card(save_data)
		_save_list.add_child(card)

	# Show "no saves" message if empty
	if saves.is_empty():
		var no_saves := Label.new()
		no_saves.text = "No saved games found."
		no_saves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_saves.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		no_saves.name = "NoSavesLabel"
		_save_list.add_child(no_saves)


func _get_all_saves() -> Array:
	var saves := []
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var save_data := _load_save_metadata(SAVE_DIR + file_name)
			if not save_data.is_empty():
				saves.append(save_data)
		file_name = dir.get_next()
	dir.list_dir_end()

	return saves


func _load_save_metadata(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		return {}

	var data: Dictionary = json.get_data()
	data["path"] = path
	data["filename"] = path.get_file()
	data["is_auto"] = path.get_file().begins_with(AUTO_SAVE_PREFIX)

	return data


func _format_number(num: int) -> String:
	var s := str(abs(num))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" if num < 0 else "") + result


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_action_pressed() -> void:
	if _mode == Mode.SAVE:
		var save_name: String = _save_name_input.text.strip_edges()
		if save_name.is_empty():
			save_name = "New Save"
		save_selected.emit(save_name)
	# In load mode, action button is disabled until selection


func _on_load_pressed(save_path: String) -> void:
	_selected_save_path = save_path
	load_selected.emit(save_path)


func _on_overwrite_pressed(save_path: String) -> void:
	_selected_save_path = save_path
	# Would typically show confirmation dialog
	save_selected.emit(save_path.get_file().get_basename())


func _on_delete_pressed(save_path: String) -> void:
	# Store the path and request confirmation
	_pending_delete_path = save_path
	var save_name := save_path.get_file().get_basename()
	delete_confirmation_requested.emit(save_name, save_path)


## Called by MenuManager when deletion is confirmed
func confirm_delete() -> void:
	if _pending_delete_path.is_empty():
		return

	# Actually delete the file
	var error := DirAccess.remove_absolute(_pending_delete_path)
	if error == OK:
		print("Deleted save file: %s" % _pending_delete_path)
		save_deleted.emit(_pending_delete_path)
	else:
		push_error("Failed to delete save file: %s (error %d)" % [_pending_delete_path, error])

	_pending_delete_path = ""

	# Only refresh list if UI is initialized
	if _save_list:
		_refresh_save_list()


## Called by MenuManager when deletion is cancelled
func cancel_delete() -> void:
	_pending_delete_path = ""


## Get pending delete path (for testing)
func get_pending_delete_path() -> String:
	return _pending_delete_path


## Set the menu mode (Save or Load)
func set_mode(mode: Mode) -> void:
	_mode = mode

	# Update UI based on mode
	var title: Label = _panel.get_node_or_null("MainVBox/Header/TitleLabel")
	var name_row: Control = _panel.get_node_or_null("MainVBox/SaveNameRow")
	var action_btn: Button = _panel.get_node_or_null("MainVBox/Footer/ActionButton")

	if title:
		title.text = "SAVE GAME" if mode == Mode.SAVE else "LOAD GAME"
	if name_row:
		name_row.visible = (mode == Mode.SAVE)
	if action_btn:
		action_btn.text = "Save New" if mode == Mode.SAVE else "Load"
		action_btn.disabled = (mode == Mode.LOAD and _selected_save_path.is_empty())

	_refresh_save_list()


## Get current mode
func get_mode() -> Mode:
	return _mode


## Get save count
func get_save_count() -> int:
	return _get_all_saves().size()


## Delete old auto-saves beyond MAX_AUTO_SAVES
func cleanup_auto_saves() -> void:
	var saves := _get_all_saves()
	var auto_saves := saves.filter(func(s): return s.get("is_auto", false))
	auto_saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	# Delete oldest auto-saves beyond limit
	for i in range(MAX_AUTO_SAVES, auto_saves.size()):
		var path: String = auto_saves[i].path
		DirAccess.remove_absolute(path)
