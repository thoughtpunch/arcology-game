extends Node2D
## Main game scene controller
## Handles camera controls and game initialization

const PAN_SPEED := 500.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 3.0

@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI

var grid: Grid
var block_renderer: BlockRenderer
var input_handler: InputHandler
var block_picker: BlockPicker
var floor_selector: FloorSelector
var terrain: Terrain
var hud: HUD
var build_toolbar: BuildToolbar


func _ready() -> void:
	print("Arcology initialized")
	_setup_terrain()
	_setup_grid()
	_setup_input_handler()
	_setup_hud()
	_setup_build_toolbar()
	_setup_block_picker()
	_setup_floor_selector()
	_place_test_blocks()


func _setup_terrain() -> void:
	# Create terrain as first child of world (renders beneath everything)
	terrain = Terrain.new()
	world.add_child(terrain)
	terrain.move_to_front()  # Actually we want it at back
	world.move_child(terrain, 0)  # Move to index 0 (first child, renders first)

	# Set default theme from terrain.json (earth)
	terrain.theme = "earth"

	# Grid area roughly -20 to +20 in each direction
	var scatter_area := Rect2i(-20, -20, 40, 40)

	# Generate river first (so decorations don't spawn on river)
	terrain.generate_river(scatter_area)

	# Scatter decorations across visible area
	terrain.scatter_decorations(scatter_area)

	print("Terrain ready with %d decorations, %d river tiles" % [terrain.get_decoration_count(), terrain.get_river_tile_count()])


func _setup_grid() -> void:
	# Create grid
	grid = Grid.new()
	add_child(grid)

	# Create renderer and connect to grid
	block_renderer = BlockRenderer.new()
	world.add_child(block_renderer)
	block_renderer.connect_to_grid(grid)

	# Connect grid to terrain for decoration visibility
	if terrain:
		grid.block_added.connect(_on_grid_block_added)
		grid.block_removed.connect(_on_grid_block_removed)

	# Connect floor changes to visibility updates
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_changed.connect(_on_floor_visibility_changed)


func _setup_input_handler() -> void:
	# Create input handler
	input_handler = InputHandler.new()
	add_child(input_handler)

	# Setup with references - ghost sprites render in world space
	input_handler.setup(grid, camera, world)

	# Connect signals for feedback
	input_handler.block_placement_attempted.connect(_on_block_placement_attempted)
	input_handler.block_removal_attempted.connect(_on_block_removal_attempted)

	print("Input handler ready. Left-click to place, right-click to remove.")


func _on_block_placement_attempted(pos: Vector3i, type: String, success: bool) -> void:
	if success:
		print("Placed %s at %s" % [type, pos])
	else:
		print("Cannot place %s at %s (invalid)" % [type, pos])


func _on_block_removal_attempted(pos: Vector3i, success: bool) -> void:
	if success:
		print("Removed block at %s" % pos)
	else:
		print("No block to remove at %s" % pos)


func _setup_hud() -> void:
	# Create main HUD layout
	hud = HUD.new()
	ui_layer.add_child(hud)

	# Connect floor changes to HUD
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_changed.connect(_on_hud_floor_changed)
		# Initialize with current floor
		hud.update_floor_display(game_state.current_floor)

	# Set initial resources (placeholder values)
	hud.update_resources(100000, 0, 0)
	hud.update_datetime(1, 1, 1)

	print("HUD ready.")


func _on_hud_floor_changed(new_floor: int) -> void:
	hud.update_floor_display(new_floor)


func _setup_build_toolbar() -> void:
	# Create build toolbar for block category selection
	build_toolbar = BuildToolbar.new()
	build_toolbar.name = "BuildToolbar"

	# Position above bottom bar (anchored to bottom of screen)
	build_toolbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	build_toolbar.offset_top = -180  # Space for toolbar + flyout
	build_toolbar.offset_bottom = -90  # Above bottom bar

	ui_layer.add_child(build_toolbar)

	# Connect block selection to input handler
	build_toolbar.block_selected.connect(_on_build_toolbar_block_selected)

	print("Build toolbar ready. Keys 1-7 for categories.")


func _on_build_toolbar_block_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	print("Build toolbar selected: %s" % block_type)


func _setup_block_picker() -> void:
	# Create block picker UI (legacy - now part of HUD bottom bar)
	# Keep for now as functional block selector with keyboard shortcuts
	block_picker = BlockPicker.new()
	ui_layer.add_child(block_picker)

	# Connect to input handler
	block_picker.block_type_selected.connect(_on_block_type_selected)

	print("Block picker ready. Keys 1-6 to select block type.")


func _on_block_type_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	print("Selected block type: %s" % block_type)


func _setup_floor_selector() -> void:
	# Create floor selector UI
	floor_selector = FloorSelector.new()
	ui_layer.add_child(floor_selector)

	# Connect to floor change events
	floor_selector.floor_change_requested.connect(_on_floor_changed)

	print("Floor selector ready. PageUp/PageDown to change floors.")


func _on_floor_changed(new_floor: int) -> void:
	print("Current floor: %d" % new_floor)


func _on_floor_visibility_changed(new_floor: int) -> void:
	# Update block visibility when floor changes
	block_renderer.update_visibility(new_floor)


func _on_grid_block_added(pos: Vector3i, _block) -> void:
	# Hide decoration and river at Z=0 when block placed
	if pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.hide_decoration_at(pos_2d)
		terrain.hide_river_at(pos_2d)


func _on_grid_block_removed(pos: Vector3i) -> void:
	# Show decoration and river at Z=0 when block removed
	if pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.show_decoration_at(pos_2d)
		terrain.show_river_at(pos_2d)


func _place_test_blocks() -> void:
	# Place some test blocks to verify rendering
	# Row of corridors at ground level
	for x in range(-2, 3):
		var block := Block.new("corridor", Vector3i(x, 0, 0))
		grid.set_block(block.grid_position, block)

	# Some vertical corridors
	for y in range(1, 3):
		var block := Block.new("corridor", Vector3i(0, y, 0))
		grid.set_block(block.grid_position, block)

	# Entrance at origin
	var entrance := Block.new("entrance", Vector3i(0, -1, 0))
	grid.set_block(entrance.grid_position, entrance)

	# Stack some blocks on Z=1 to test floor stacking
	var upper1 := Block.new("residential_basic", Vector3i(1, 0, 1))
	grid.set_block(upper1.grid_position, upper1)

	var upper2 := Block.new("commercial_basic", Vector3i(2, 0, 1))
	grid.set_block(upper2.grid_position, upper2)

	# Stairs to connect floors
	var stairs := Block.new("stairs", Vector3i(0, 0, 1))
	grid.set_block(stairs.grid_position, stairs)

	print("Placed %d test blocks" % grid.get_block_count())

	# Apply initial visibility based on starting floor
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		block_renderer.update_visibility(game_state.current_floor)


func _process(delta: float) -> void:
	_handle_camera_pan(delta)


func _unhandled_input(event: InputEvent) -> void:
	_handle_camera_zoom(event)


func _handle_camera_pan(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * PAN_SPEED * delta


func _handle_camera_zoom(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_zoom_camera(ZOOM_SPEED)
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(-ZOOM_SPEED)


func _zoom_camera(amount: float) -> void:
	var new_zoom := camera.zoom.x + amount
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(new_zoom, new_zoom)
