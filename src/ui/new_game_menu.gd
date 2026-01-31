class_name NewGameMenu
extends Control
## New game menu with scenario selection and game settings
## See: documentation/ui/menus.md

signal back_pressed
signal start_game_pressed(config: Dictionary)

# Screens
enum Screen { SCENARIO_SELECT, GAME_SETTINGS }

# Color scheme
const COLOR_BACKGROUND := Color("#1a1a2e")
const COLOR_PANEL := Color("#16213e")
const COLOR_CARD := Color("#1a1a2e")
const COLOR_CARD_SELECTED := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Scenarios
const SCENARIOS := [
	{
		"id": "fresh_start",
		"name": "Fresh Start",
		"difficulty": "Easy",
		"description": "A blank plot of land. Build your dream arcology from scratch."
	},
	{
		"id": "troubled_tower",
		"name": "Troubled Tower",
		"difficulty": "Medium",
		"description": "Inherit a struggling arcology. Fix the problems before residents leave."
	},
	{
		"id": "crisis_mode",
		"name": "Crisis Mode",
		"difficulty": "Hard",
		"description": "Everything is on fire. Literally. Can you turn it around?"
	}
]

# UI components
var _panel: PanelContainer
var _scenario_container: VBoxContainer
var _settings_container: VBoxContainer
var _scenario_cards: Array[Control] = []
var _current_screen := Screen.SCENARIO_SELECT
var _selected_scenario_index := -1

# Game config
var _game_config := {
	"scenario": "fresh_start",
	"name": "New Arcology",
	"starting_funds": 50000,
	"entropy_rate": "Normal",
	"resident_patience": "Normal",
	"disasters": true,
	"unlimited_money": false,
	"instant_construction": false,
	"all_blocks_unlocked": false,
	"disable_failures": false
}


func _ready() -> void:
	_setup_layout()
	_show_screen(Screen.SCENARIO_SELECT)


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
	_panel.offset_left = 60
	_panel.offset_right = -60
	_panel.offset_top = 40
	_panel.offset_bottom = -40
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
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	main_vbox.name = "MainVBox"
	_panel.add_child(main_vbox)

	# Create both screens (one visible at a time)
	_scenario_container = _create_scenario_screen()
	main_vbox.add_child(_scenario_container)

	_settings_container = _create_settings_screen()
	main_vbox.add_child(_settings_container)


func _create_scenario_screen() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.name = "ScenarioScreen"

	# Header
	var header := HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)

	var title := Label.new()
	title.text = "NEW GAME"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.name = "TitleLabel"
	header.add_child(title)

	var back_btn := _create_button("Back")
	back_btn.name = "BackButton"
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "SELECT SCENARIO"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	subtitle.name = "SubtitleLabel"
	vbox.add_child(subtitle)

	# Scenario cards
	var cards_container := VBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 12)
	cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_container.name = "CardsContainer"
	vbox.add_child(cards_container)

	for i in range(SCENARIOS.size()):
		var card := _create_scenario_card(SCENARIOS[i], i)
		cards_container.add_child(card)
		_scenario_cards.append(card)

	return vbox


func _create_scenario_card(scenario: Dictionary, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	card.name = "%sCard" % scenario.id.to_pascal_case()

	# Card style
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COLOR_CARD
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_color = Color.TRANSPARENT
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 3
	card_style.border_width_bottom = 3
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	# Placeholder image
	var image_placeholder := ColorRect.new()
	image_placeholder.custom_minimum_size = Vector2(80, 80)
	image_placeholder.color = COLOR_BUTTON
	image_placeholder.name = "ImagePlaceholder"
	hbox.add_child(image_placeholder)

	# Text content
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 4)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_box)

	var name_label := Label.new()
	name_label.text = scenario.name.to_upper()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.name = "NameLabel"
	text_box.add_child(name_label)

	var diff_label := Label.new()
	diff_label.text = "Difficulty: %s" % scenario.difficulty
	diff_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	diff_label.name = "DifficultyLabel"
	text_box.add_child(diff_label)

	var sep := HSeparator.new()
	text_box.add_child(sep)

	var desc_label := Label.new()
	desc_label.text = scenario.description
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.name = "DescriptionLabel"
	text_box.add_child(desc_label)

	# Select button
	var select_btn := _create_button("SELECT")
	select_btn.name = "SelectButton"
	select_btn.pressed.connect(_on_scenario_selected.bind(index))
	hbox.add_child(select_btn)

	return card


func _create_settings_screen() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.name = "SettingsScreen"

	# Header
	var header := HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)

	var title := Label.new()
	title.text = "GAME SETTINGS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.name = "TitleLabel"
	header.add_child(title)

	var back_btn := _create_button("Back")
	back_btn.name = "BackButton"
	back_btn.pressed.connect(_on_settings_back)
	header.add_child(back_btn)

	# Settings scroll area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "SettingsScroll"
	vbox.add_child(scroll)

	var settings_vbox := VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 16)
	settings_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(settings_vbox)

	# Arcology name
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	settings_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.text = "Arcology Name:"
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_row.add_child(name_label)

	var name_input := LineEdit.new()
	name_input.text = _game_config.name
	name_input.custom_minimum_size = Vector2(300, 0)
	name_input.name = "NameInput"
	name_input.text_changed.connect(_on_name_changed)
	name_row.add_child(name_input)

	# Separator
	settings_vbox.add_child(HSeparator.new())

	# Difficulty options header
	var diff_header := Label.new()
	diff_header.text = "DIFFICULTY OPTIONS"
	diff_header.add_theme_font_size_override("font_size", 16)
	diff_header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	settings_vbox.add_child(diff_header)

	# Starting funds
	settings_vbox.add_child(
		_create_dropdown_row(
			"Starting Funds", ["$25,000 (Hard)", "$50,000 (Normal)", "$100,000 (Easy)"], 1
		)
	)

	# Entropy rate
	settings_vbox.add_child(_create_dropdown_row("Entropy Rate", ["Fast", "Normal", "Slow"], 1))

	# Resident patience
	settings_vbox.add_child(
		_create_dropdown_row("Resident Patience", ["Impatient", "Normal", "Patient"], 1)
	)

	# Disasters
	settings_vbox.add_child(_create_toggle_row("Disasters", true))

	# Separator
	settings_vbox.add_child(HSeparator.new())

	# Sandbox options header
	var sandbox_header := Label.new()
	sandbox_header.text = "SANDBOX OPTIONS"
	sandbox_header.add_theme_font_size_override("font_size", 16)
	sandbox_header.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	settings_vbox.add_child(sandbox_header)

	# Sandbox toggles
	settings_vbox.add_child(_create_checkbox_row("Unlimited Money", false, "unlimited_money"))
	settings_vbox.add_child(
		_create_checkbox_row("Instant Construction", false, "instant_construction")
	)
	settings_vbox.add_child(
		_create_checkbox_row("All Blocks Unlocked", false, "all_blocks_unlocked")
	)
	settings_vbox.add_child(_create_checkbox_row("Disable Failures", false, "disable_failures"))

	# Footer with action buttons
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.name = "Footer"
	vbox.add_child(footer)

	var cancel_btn := _create_button("Cancel")
	cancel_btn.name = "CancelButton"
	cancel_btn.pressed.connect(_on_settings_back)
	footer.add_child(cancel_btn)

	var start_btn := _create_button("Start Game")
	start_btn.name = "StartGameButton"
	start_btn.custom_minimum_size = Vector2(120, 40)
	start_btn.pressed.connect(_on_start_game)
	footer.add_child(start_btn)

	return vbox


func _create_dropdown_row(label_text: String, options: Array, default_index: int) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(200, 0)
	for option in options:
		dropdown.add_item(option)
	dropdown.selected = default_index
	dropdown.name = "%sDropdown" % label_text.to_pascal_case().replace(" ", "")
	hbox.add_child(dropdown)

	return hbox


func _create_toggle_row(label_text: String, default_value: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(200, 0)
	dropdown.add_item("Enabled")
	dropdown.add_item("Disabled")
	dropdown.selected = 0 if default_value else 1
	dropdown.name = "%sDropdown" % label_text.to_pascal_case().replace(" ", "")
	hbox.add_child(dropdown)

	return hbox


func _create_checkbox_row(
	label_text: String, default_value: bool, config_key: String
) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.name = "%sRow" % config_key.to_pascal_case()

	var checkbox := CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = default_value
	checkbox.add_theme_color_override("font_color", COLOR_TEXT)
	checkbox.name = "%sCheckbox" % config_key.to_pascal_case()
	checkbox.toggled.connect(_on_checkbox_toggled.bind(config_key))
	hbox.add_child(checkbox)

	return hbox


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


func _show_screen(screen: Screen) -> void:
	_current_screen = screen
	_scenario_container.visible = (screen == Screen.SCENARIO_SELECT)
	_settings_container.visible = (screen == Screen.GAME_SETTINGS)


func _update_scenario_card_selection(index: int) -> void:
	for i in range(_scenario_cards.size()):
		var card: PanelContainer = _scenario_cards[i]
		var style: StyleBoxFlat = card.get_theme_stylebox("panel")
		if i == index:
			style.border_color = COLOR_ACCENT
		else:
			style.border_color = Color.TRANSPARENT


func _on_scenario_selected(index: int) -> void:
	_selected_scenario_index = index
	_game_config.scenario = SCENARIOS[index].id
	_update_scenario_card_selection(index)
	_show_screen(Screen.GAME_SETTINGS)


func _on_settings_back() -> void:
	_show_screen(Screen.SCENARIO_SELECT)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_name_changed(new_name: String) -> void:
	_game_config.name = new_name


func _on_checkbox_toggled(enabled: bool, config_key: String) -> void:
	_game_config[config_key] = enabled


func _on_start_game() -> void:
	start_game_pressed.emit(_game_config)


## Get current screen
func get_current_screen() -> Screen:
	return _current_screen


## Get selected scenario index
func get_selected_scenario() -> int:
	return _selected_scenario_index


## Get game config
func get_game_config() -> Dictionary:
	return _game_config.duplicate()
