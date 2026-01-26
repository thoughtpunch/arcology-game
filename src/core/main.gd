extends Node2D
## Main game scene controller
## Simple, clean interface inspired by reference city builder video
## Handles camera controls and game initialization

@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI

var grid: Grid
var block_renderer: BlockRenderer
var input_handler: InputHandler
var terrain: Terrain
var camera_controller: CameraController


func _ready() -> void:
	print("Arcology initialized")
	_setup_camera()
	_setup_terrain()
	_setup_grid()
	_setup_input_handler()
	_setup_simple_ui()
	_place_starting_block()


func _setup_camera() -> void:
	camera_controller = CameraController.new()
	add_child(camera_controller)
	camera_controller.setup(camera)
	print("Camera controls: WASD/arrows pan, scroll zoom, Q/E rotate, middle/right drag pan, double-click center")


func _setup_terrain() -> void:
	# Create terrain as first child of world (renders beneath everything)
	terrain = Terrain.new()
	world.add_child(terrain)
	world.move_child(terrain, 0)  # First child = renders first (behind everything)
	terrain.theme = "earth"
	print("Terrain ready")


func _setup_grid() -> void:
	grid = Grid.new()
	add_child(grid)

	# Create renderer and connect to grid
	block_renderer = BlockRenderer.new()
	world.add_child(block_renderer)
	block_renderer.connect_to_grid(grid)


func _setup_input_handler() -> void:
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.setup(grid, camera, world)

	# Feedback signals
	input_handler.block_placement_attempted.connect(_on_block_placed)
	input_handler.block_removal_attempted.connect(_on_block_removed)

	print("Click to place blocks, right-click to remove")


func _on_block_placed(pos: Vector3i, type: String, success: bool) -> void:
	if success:
		print("Placed %s at %s" % [type, pos])


func _on_block_removed(pos: Vector3i, success: bool) -> void:
	if success:
		print("Removed block at %s" % pos)


func _setup_simple_ui() -> void:
	# Create a minimal block picker at bottom of screen (like reference video)
	var block_bar := HBoxContainer.new()
	block_bar.name = "BlockBar"
	block_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	block_bar.offset_top = -80
	block_bar.offset_bottom = -16
	block_bar.add_theme_constant_override("separation", 12)
	ui_layer.add_child(block_bar)

	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if not registry:
		push_warning("BlockRegistry not found")
		return

	# Block types to show in toolbar
	var block_types := ["corridor", "entrance", "stairs", "residential_basic", "commercial_basic"]

	for i in range(block_types.size()):
		var block_type: String = block_types[i]
		var block_data: Dictionary = registry.get_block_data(block_type)

		var btn := Button.new()
		btn.name = block_type
		btn.custom_minimum_size = Vector2(64, 64)
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)

		# Try to load sprite as button icon
		var sprite_path: String = block_data.get("sprite", "")
		if sprite_path != "" and ResourceLoader.exists(sprite_path):
			var texture := load(sprite_path) as Texture2D
			if texture:
				btn.icon = texture
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
		else:
			btn.text = str(i + 1)

		# Style: dark semi-transparent background
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style)

		# Style: selected state with white border
		var style_pressed := StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.2, 0.4, 0.6, 0.8)
		style_pressed.border_color = Color.WHITE
		style_pressed.border_width_left = 2
		style_pressed.border_width_right = 2
		style_pressed.border_width_top = 2
		style_pressed.border_width_bottom = 2
		style_pressed.corner_radius_top_left = 8
		style_pressed.corner_radius_top_right = 8
		style_pressed.corner_radius_bottom_left = 8
		style_pressed.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("pressed", style_pressed)

		btn.pressed.connect(_on_block_button_pressed.bind(block_type, block_bar))
		block_bar.add_child(btn)

	# Select first block by default
	if block_types.size() > 0:
		input_handler.set_selected_block_type(block_types[0])

	print("UI ready - select blocks at bottom, click to place")


func _on_block_button_pressed(block_type: String, bar: HBoxContainer) -> void:
	# Update button states
	for child in bar.get_children():
		if child is Button:
			child.button_pressed = (child.name == block_type)

	input_handler.set_selected_block_type(block_type)
	print("Selected: %s" % block_type)


func _place_starting_block() -> void:
	# Start with one entrance block at origin
	var entrance := Block.new("entrance", Vector3i(0, 0, 0))
	grid.set_block(entrance.grid_position, entrance)
	print("Starting block placed - start building!")


