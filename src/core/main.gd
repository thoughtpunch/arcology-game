extends Node2D
## Main game scene controller
## Simple, clean interface inspired by reference city builder video
## Handles camera controls and game initialization

const CameraControllerClass := preload("res://src/core/camera_controller.gd")
const CameraControlsPaneClass := preload("res://src/ui/camera_controls_pane.gd")

@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI

var grid: Grid
var block_renderer: BlockRenderer
var input_handler: InputHandler
var terrain: Terrain
var camera_controller: Node  # CameraController instance
var construction_queue  # ConstructionQueue instance

# UI Components
var hud: HUD
var build_toolbar: BuildToolbar
var block_picker: BlockPicker
var floor_selector: FloorSelector
var camera_controls_pane: Control  # CameraControlsPaneClass instance

# Game state
var _game_initialized := false
var _game_config: Dictionary = {}


func _ready() -> void:
	print("Arcology initialized - connecting to MenuManager")

	# Connect to MenuManager signals
	var menu_manager = get_tree().get_root().get_node_or_null("/root/MenuManager")
	if menu_manager:
		menu_manager.game_started.connect(_on_game_started)
		menu_manager.game_loaded.connect(_on_game_loaded)
		menu_manager.game_resumed.connect(_on_game_resumed)
		print("MenuManager connected - waiting for game start")
	else:
		# No MenuManager - start game directly (for testing/debugging)
		push_warning("MenuManager not found - starting game directly")
		_initialize_game()


func _on_game_started(config: Dictionary) -> void:
	print("Starting new game with config: %s" % config)
	_game_config = config
	_apply_game_config(config)
	_initialize_game()
	_place_starting_block()


func _on_game_loaded(save_path: String) -> void:
	print("Loading game from: %s" % save_path)
	_initialize_game()
	_load_game(save_path)


func _on_game_resumed() -> void:
	# Game resumed from pause - no action needed
	pass


func _apply_game_config(config: Dictionary) -> void:
	# Apply config to GameState
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.apply_new_game_config(config)

	# Apply block unlocking
	var block_registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if block_registry:
		if config.get("all_blocks_unlocked", false):
			block_registry.unlock_all()
		else:
			block_registry.lock_all_to_defaults()


func _initialize_game() -> void:
	if _game_initialized:
		return

	_game_initialized = true
	_setup_camera()
	_setup_terrain()
	_setup_grid()
	_setup_input_handler()
	_setup_hud()
	_setup_build_toolbar()
	_setup_block_picker()
	_setup_floor_selector()
	_setup_camera_controls()
	print("Game initialized")


func _setup_camera() -> void:
	camera_controller = CameraControllerClass.new()
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
	block_renderer.view_mode_changed.connect(_on_view_mode_changed)

	# Connect grid to terrain for decoration visibility
	if terrain:
		grid.block_added.connect(_on_grid_block_added)
		grid.block_removed.connect(_on_grid_block_removed)

	# Connect floor changes to visibility updates
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_changed.connect(_on_floor_visibility_changed)

	# Setup construction queue
	_setup_construction_queue()


func _setup_construction_queue() -> void:
	var CQScript = load("res://src/core/construction_queue.gd")
	construction_queue = CQScript.new()
	add_child(construction_queue)
	construction_queue.setup(grid)

	# Connect to block renderer for visualization
	if block_renderer:
		block_renderer.connect_to_construction_queue(construction_queue)

	# Check GameState for instant construction flag
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state and game_state.instant_construction:
		construction_queue.set_instant_construction(true)


func _setup_input_handler() -> void:
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.setup(grid, camera, world)

	# Feedback signals
	input_handler.block_placement_attempted.connect(_on_block_placed)
	input_handler.block_removal_attempted.connect(_on_block_removed)
	input_handler.block_selected.connect(_on_block_selected)

	# Give InputHandler access to block_renderer for show_all_floors check
	# (set after block_renderer is created in _setup_grid)
	call_deferred("_connect_input_handler_to_renderer")

	print("Click to place blocks, right-click to remove")


func _connect_input_handler_to_renderer() -> void:
	if input_handler and block_renderer:
		input_handler.set_block_renderer(block_renderer)
	if input_handler and construction_queue:
		input_handler.set_construction_queue(construction_queue)


func _on_block_placed(pos: Vector3i, type: String, success: bool) -> void:
	if success:
		print("Placed %s at %s" % [type, pos])


func _on_block_removed(pos: Vector3i, success: bool) -> void:
	if success:
		print("Removed block at %s" % pos)


func _on_block_selected(pos: Vector3i, block_type: String) -> void:
	print("Selected block at %s (%s)" % [pos, block_type])


func _setup_hud() -> void:
	# Create main HUD layout (top bar, sidebars, bottom bar)
	hud = HUD.new()
	ui_layer.add_child(hud)

	# Connect to GameState
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		# Floor changes
		game_state.floor_changed.connect(_on_hud_floor_changed)
		hud.update_floor_display(game_state.current_floor)

		# Money changes
		game_state.money_changed.connect(_on_money_changed)

		# Time changes
		game_state.time_changed.connect(_on_time_changed)

		# Set initial values from GameState
		hud.update_resources(game_state.money, game_state.population, int(game_state.aei_score))
		hud.update_datetime(game_state.year, game_state.month, game_state.day)
	else:
		# Fallback defaults
		hud.update_resources(50000, 0, 0)
		hud.update_datetime(1, 1, 1)

	# Connect tool sidebar to input handler
	if hud.left_sidebar and hud.left_sidebar is ToolSidebar:
		var tool_sidebar: ToolSidebar = hud.left_sidebar
		tool_sidebar.tool_selected.connect(_on_tool_selected)
		# Start with BUILD mode
		tool_sidebar.set_current_tool(ToolSidebar.Tool.BUILD)

	# Connect viewport clicks to input handler
	hud.viewport_clicked.connect(_on_viewport_clicked)

	print("HUD ready")


func _on_viewport_clicked(event: InputEventMouseButton) -> void:
	# Forward viewport clicks to input handler
	input_handler.handle_viewport_click(event)


func _on_hud_floor_changed(new_floor: int) -> void:
	hud.update_floor_display(new_floor)


func _on_money_changed(new_amount: int) -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		hud.update_resources(new_amount, game_state.population, int(game_state.aei_score))


func _on_time_changed(year: int, month: int, day: int, _hour: int) -> void:
	hud.update_datetime(year, month, day)


func _on_tool_selected(tool: int) -> void:
	# Map ToolSidebar.Tool to InputHandler.Mode
	match tool:
		ToolSidebar.Tool.SELECT:
			input_handler.set_mode(InputHandler.Mode.SELECT)
			print("Mode: SELECT")
		ToolSidebar.Tool.BUILD:
			input_handler.set_mode(InputHandler.Mode.BUILD)
			print("Mode: BUILD")
		ToolSidebar.Tool.DEMOLISH:
			input_handler.set_mode(InputHandler.Mode.DEMOLISH)
			print("Mode: DEMOLISH")
		_:
			# INFO and UPGRADE don't have matching InputHandler modes yet
			input_handler.set_mode(InputHandler.Mode.SELECT)
			print("Mode: SELECT (fallback)")


func _setup_build_toolbar() -> void:
	# Create build toolbar for block category selection
	build_toolbar = BuildToolbar.new()
	build_toolbar.name = "BuildToolbar"

	# Position above bottom bar
	build_toolbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	build_toolbar.offset_top = -180
	build_toolbar.offset_bottom = -90
	# Let mouse events pass through when not on buttons
	build_toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ui_layer.add_child(build_toolbar)

	# Connect block selection to input handler
	build_toolbar.block_selected.connect(_on_build_toolbar_block_selected)

	print("Build toolbar ready. Keys 1-7 for categories.")


func _on_build_toolbar_block_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	print("Selected: %s" % block_type)


func _setup_block_picker() -> void:
	# Legacy block picker - provides keyboard shortcuts (1-6)
	block_picker = BlockPicker.new()
	ui_layer.add_child(block_picker)
	block_picker.block_type_selected.connect(_on_block_type_selected)
	print("Block picker ready. Keys 1-6 to select block type.")


func _on_block_type_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	print("Selected block type: %s" % block_type)


func _setup_floor_selector() -> void:
	# Legacy floor selector - provides keyboard shortcuts (PageUp/PageDown)
	floor_selector = FloorSelector.new()
	ui_layer.add_child(floor_selector)
	floor_selector.floor_change_requested.connect(_on_floor_changed)
	print("Floor selector ready. PageUp/PageDown to change floors.")


func _on_floor_changed(new_floor: int) -> void:
	print("Current floor: %d" % new_floor)


func _setup_camera_controls() -> void:
	# Create camera controls pane (Cities Skylines style)
	camera_controls_pane = CameraControlsPaneClass.new()
	camera_controls_pane.name = "CameraControlsPane"
	ui_layer.add_child(camera_controls_pane)

	# Connect to camera controller
	if camera_controller:
		camera_controls_pane.connect_to_camera(camera_controller)

	print("Camera controls: H toggle pane, Q/E rotate, +/- zoom, I/T view mode")


func _on_floor_visibility_changed(new_floor: int) -> void:
	block_renderer.update_visibility(new_floor)


func _on_view_mode_changed(show_all: bool) -> void:
	# Update floor navigator display
	var floor_navigator: FloorNavigator = hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator")
	if floor_navigator:
		floor_navigator.set_view_mode(show_all)
	var mode := "ALL FLOORS" if show_all else "CUTAWAY"
	print("View mode: %s" % mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_V:
				# Toggle show all floors
				block_renderer.toggle_show_all_floors()
			KEY_DELETE:
				# Clear all blocks (with Shift held for confirmation)
				if event.shift_pressed:
					_clear_all_blocks()
				else:
					print("Hold Shift+Delete to clear all blocks")
			KEY_BACKSPACE:
				# Alternative: Shift+Backspace to clear all
				if event.shift_pressed:
					_clear_all_blocks()


func _clear_all_blocks() -> void:
	var count := grid.get_block_count()
	if count == 0:
		print("No blocks to clear")
		return

	grid.clear()
	print("Cleared %d blocks" % count)

	# Place a new starting entrance
	_place_starting_block()


func _on_grid_block_added(pos: Vector3i, _block) -> void:
	# Hide decoration at Z=0 when block placed
	if pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.hide_decoration_at(pos_2d)
		terrain.hide_river_at(pos_2d)


func _on_grid_block_removed(pos: Vector3i) -> void:
	# Show decoration at Z=0 when block removed
	if pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.show_decoration_at(pos_2d)
		terrain.show_river_at(pos_2d)


func _place_starting_block() -> void:
	# Start with one entrance block at origin
	var entrance := Block.new("entrance", Vector3i(0, 0, 0))
	grid.set_block(entrance.grid_position, entrance)
	print("Starting block placed - start building!")


# --- Save/Load System ---

func _load_game(save_path: String) -> void:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file: %s" % save_path)
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("Failed to parse save file: %s" % json.get_error_message())
		return

	var save_data: Dictionary = json.get_data()
	_apply_save_data(save_data)
	print("Game loaded from: %s" % save_path)


func _apply_save_data(data: Dictionary) -> void:
	# Clear existing blocks
	if grid:
		grid.clear()

	# Load blocks
	var blocks_data: Array = data.get("blocks", [])
	for block_data in blocks_data:
		var pos := Vector3i(
			block_data.get("x", 0),
			block_data.get("y", 0),
			block_data.get("z", 0)
		)
		var block_type: String = block_data.get("type", "residential")
		var block := Block.new(block_type, pos)
		grid.set_block(pos, block)

	# Load game state
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.current_floor = data.get("current_floor", 0)

	# Load config
	_game_config = data.get("config", {})

	print("Loaded %d blocks" % blocks_data.size())


func save_game(save_name: String) -> String:
	# Ensure saves directory exists
	var save_dir := "user://saves/"
	DirAccess.make_dir_recursive_absolute(save_dir)

	# Generate save file path
	var timestamp := Time.get_unix_time_from_system()
	var save_path := "%s%s.save" % [save_dir, save_name.to_lower().replace(" ", "_")]

	var save_data := _create_save_data(save_name, timestamp)

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to create save file: %s" % save_path)
		return ""

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	# Mark as saved
	var menu_manager = get_tree().get_root().get_node_or_null("/root/MenuManager")
	if menu_manager:
		menu_manager._has_unsaved_changes = false

	print("Game saved to: %s" % save_path)
	return save_path


func _create_save_data(save_name: String, timestamp: float) -> Dictionary:
	var blocks_data := []

	# Save all blocks
	if grid:
		for block in grid.get_all_blocks():
			blocks_data.append({
				"x": block.grid_position.x,
				"y": block.grid_position.y,
				"z": block.grid_position.z,
				"type": block.block_type
			})

	# Get current game state
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	var current_floor := 0
	if game_state:
		current_floor = game_state.current_floor

	return {
		"name": save_name,
		"timestamp": timestamp,
		"version": "0.1.0",
		"current_floor": current_floor,
		"config": _game_config,
		"blocks": blocks_data
	}
