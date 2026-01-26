class_name BlockPicker
extends Control
## UI for selecting which block type to place
## Shows buttons for each block type with keyboard shortcuts

signal block_type_selected(block_type: String)

# References
var _buttons: Dictionary = {}  # block_type -> Button
var _button_container: HBoxContainer
var _selected_type: String = ""

# Block type order (matches keyboard shortcuts 1-6)
const BLOCK_ORDER: Array[String] = [
	"corridor",
	"entrance",
	"stairs",
	"elevator_shaft",
	"residential_basic",
	"commercial_basic"
]


func _ready() -> void:
	_setup_ui()
	# Short delay to allow BlockRegistry to load
	call_deferred("_populate_buttons")


func _setup_ui() -> void:
	# Set up as bottom panel
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -60
	offset_bottom = 0

	# Create background panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	# Create horizontal container for buttons
	_button_container = HBoxContainer.new()
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_container.add_theme_constant_override("separation", 10)
	panel.add_child(_button_container)


func _populate_buttons() -> void:
	# Get BlockRegistry
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		push_warning("BlockPicker: BlockRegistry not found")
		return

	# Create button for each block type in order
	for i in range(BLOCK_ORDER.size()):
		var block_type: String = BLOCK_ORDER[i]
		if not registry.has_type(block_type):
			continue

		var block_data: Dictionary = registry.get_block_data(block_type)
		_create_button(block_type, block_data, i + 1)

	# Select first type by default
	if BLOCK_ORDER.size() > 0:
		select_type(BLOCK_ORDER[0])


func _create_button(block_type: String, block_data: Dictionary, shortcut_num: int) -> void:
	var button := Button.new()

	# Set button text with shortcut hint
	var display_name: String = block_data.get("name", block_type)
	button.text = "%d: %s" % [shortcut_num, display_name]
	button.tooltip_text = display_name

	# Style settings
	button.custom_minimum_size = Vector2(100, 40)
	button.toggle_mode = true  # Enable toggle for visual selection

	# Connect button press
	button.pressed.connect(_on_button_pressed.bind(block_type))

	_button_container.add_child(button)
	_buttons[block_type] = button


func _on_button_pressed(block_type: String) -> void:
	select_type(block_type)


## Select a block type programmatically
func select_type(block_type: String) -> void:
	if not _buttons.has(block_type):
		return

	# Update visual state - deselect all, select current
	for type in _buttons:
		_buttons[type].button_pressed = (type == block_type)

	_selected_type = block_type
	block_type_selected.emit(block_type)


## Get currently selected block type
func get_selected_type() -> String:
	return _selected_type


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	# Handle number keys 1-6 for quick selection
	var key := event as InputEventKey
	var index := -1

	match key.keycode:
		KEY_1: index = 0
		KEY_2: index = 1
		KEY_3: index = 2
		KEY_4: index = 3
		KEY_5: index = 4
		KEY_6: index = 5

	if index >= 0 and index < BLOCK_ORDER.size():
		select_type(BLOCK_ORDER[index])
		get_viewport().set_input_as_handled()
