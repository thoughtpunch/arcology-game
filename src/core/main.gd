extends Node3D
## Main game scene controller
## Simple, clean interface inspired by reference city builder video
## Handles camera controls and game initialization
##
## NOTE: As of 3D refactor Phase 1, this scene uses Node3D root.
## 2D systems (Terrain, BlockRenderer) are temporarily disabled.
## 3D equivalents will be implemented in subsequent phases.

# 2D camera controller - temporarily disabled for 3D refactor
# const CameraControllerClass := preload("res://src/core/camera_controller.gd")
const CameraControlsPaneClass := preload("res://src/ui/camera_controls_pane.gd")

# 3D camera controller
const ArcologyCameraClass := preload("res://src/core/camera_3d_controller.gd")

# 3D block renderer
const BlockRenderer3DClass := preload("res://src/rendering/block_renderer_3d.gd")

# 3D input handler
const InputHandler3DClass := preload("res://src/core/input_handler_3d.gd")

# Visibility controller for cutaway mode
const VisibilityControllerClass := preload("res://src/core/visibility_controller.gd")

# Scenario config resource
const ScenarioConfigClass := preload("res://src/data/scenario_config.gd")

@onready var world: Node3D = $World
@onready var ui_layer: CanvasLayer = $UI

var grid: Grid
var block_renderer: BlockRenderer  # 2D renderer - temporarily disabled for 3D refactor
var block_renderer_3d: Node3D  # 3D renderer (BlockRenderer3D)
var input_handler: InputHandler  # 2D input - temporarily disabled for 3D refactor
var input_handler_3d: Node3D  # 3D input handler (InputHandler3D)
var terrain: Terrain  # 2D terrain - temporarily disabled for 3D refactor
var camera_controller  # ArcologyCamera instance for 3D
var construction_queue  # ConstructionQueue instance
var visibility_controller  # VisibilityController for cutaway mode (3D only)
var scenario_config: Resource  # ScenarioConfig for current session

# Flag for 3D mode - will be removed once 3D refactor is complete
var _is_3d_mode := true

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
	_setup_scenario_config()
	_setup_camera()
	_setup_terrain()
	_setup_grid()
	_setup_visibility_controller()
	_setup_input_handler()
	_setup_hud()
	_setup_build_toolbar()
	_setup_block_picker()
	_setup_floor_selector()
	_setup_camera_controls()
	print("Game initialized")


func _setup_scenario_config() -> void:
	# Try to load scenario config from game config, or fall back to default
	var scenario_name: String = _game_config.get("scenario_config", "")
	if not scenario_name.is_empty():
		scenario_config = ScenarioConfigClass.load_scenario(scenario_name)

	if not scenario_config:
		# Load earth_standard as default, fall back to programmatic default
		scenario_config = ScenarioConfigClass.load_scenario("earth_standard")

	if not scenario_config:
		scenario_config = ScenarioConfigClass.create_default()

	# Apply scenario config values to GameState
	_apply_scenario_to_game_state()

	print("Scenario config loaded: %s" % scenario_config.get_summary())


func _setup_camera() -> void:
	if _is_3d_mode:
		# Use 3D ArcologyCamera with orbital controls and ortho snap views
		camera_controller = ArcologyCameraClass.new()
		camera_controller.name = "ArcologyCamera"
		add_child(camera_controller)
		# ArcologyCamera creates its own Camera3D as a child
		print("3D Camera controls: Q/E rotate, R/F tilt, WASD pan, scroll zoom")
		print("  Tab=toggle mode, Shift+1-7=ortho views, Home=reset")
	else:
		# Legacy 2D camera (disabled during 3D refactor)
		pass
		#camera_controller = CameraControllerClass.new()
		#add_child(camera_controller)
		#camera_controller.setup(camera)
		#print("Camera controls: WASD/arrows pan, scroll zoom, Q/E rotate, middle/right drag pan, double-click center")


func _setup_terrain() -> void:
	if _is_3d_mode:
		# 2D terrain disabled during 3D refactor
		# Ground plane is in the scene file (World/GroundPlane)
		print("3D mode: Using scene ground plane (2D terrain disabled)")
		return

	# Legacy 2D terrain (disabled during 3D refactor)
	terrain = Terrain.new()
	world.add_child(terrain)
	world.move_child(terrain, 0)  # First child = renders first (behind everything)
	terrain.theme = "earth"
	print("Terrain ready")


func _setup_grid() -> void:
	grid = Grid.new()
	add_child(grid)

	if _is_3d_mode:
		# 3D block renderer
		block_renderer_3d = BlockRenderer3DClass.new()
		block_renderer_3d.name = "BlockRenderer3D"
		world.add_child(block_renderer_3d)
		block_renderer_3d.connect_to_grid(grid)
		print("3D mode: Grid ready with BlockRenderer3D")
	else:
		# Legacy 2D renderer (disabled during 3D refactor)
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
		if not _is_3d_mode:
			game_state.floor_changed.connect(_on_floor_visibility_changed)
		# Connect for unsaved changes tracking
		game_state.money_changed.connect(_on_game_state_changed)
		game_state.config_applied.connect(_on_config_applied)

	# Setup construction queue
	_setup_construction_queue()


func _setup_visibility_controller() -> void:
	if not _is_3d_mode:
		return

	visibility_controller = VisibilityControllerClass.new()
	visibility_controller.name = "VisibilityController"
	add_child(visibility_controller)

	# Connect to renderer for direct material updates (optional)
	if block_renderer_3d:
		visibility_controller.connect_to_renderer(block_renderer_3d)

	# Create cut plane indicator in the world
	if world:
		visibility_controller.show_cut_plane_indicator(world, Vector2(300, 300))

	# Connect signals for HUD updates
	visibility_controller.mode_changed.connect(_on_visibility_mode_changed)
	visibility_controller.cut_height_changed.connect(_on_cut_height_changed)

	print("Visibility controller ready. C=toggle cutaway, [/]=adjust height")


func _on_visibility_mode_changed(new_mode: int) -> void:
	var mode_name := VisibilityControllerClass.get_mode_name(new_mode)
	print("Visibility mode changed: %s" % mode_name)
	# Future: Update HUD indicator


func _on_cut_height_changed(new_height: float) -> void:
	var floor_num := int(new_height / VisibilityControllerClass.CUBE_HEIGHT)
	print("Cut height: %.1fm (floor %d)" % [new_height, floor_num])
	# Future: Update HUD floor indicator


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
	if _is_3d_mode:
		# Use 3D raycast input handler
		input_handler_3d = InputHandler3DClass.new()
		input_handler_3d.name = "InputHandler3D"
		add_child(input_handler_3d)

		# Setup with dependencies
		var cam: Camera3D = camera_controller.get_camera() if camera_controller else null
		input_handler_3d.setup(grid, cam, block_renderer_3d)

		# Connect signals
		input_handler_3d.block_placement_attempted.connect(_on_block_placed)
		input_handler_3d.block_removal_attempted.connect(_on_block_removed)
		input_handler_3d.block_selected.connect(_on_block_selected)

		# Pass scenario config to placement validator
		if scenario_config:
			input_handler_3d.set_scenario_config(scenario_config)

		# Connect to construction queue
		call_deferred("_connect_input_handler_3d_to_queue")

		print("3D mode: Click to place blocks, right-click to remove")
		return

	# Legacy 2D input handler (disabled during 3D refactor)
	input_handler = InputHandler.new()
	add_child(input_handler)
	# Note: camera variable doesn't exist in 3D mode
	#input_handler.setup(grid, camera, world)

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


func _connect_input_handler_3d_to_queue() -> void:
	if input_handler_3d and construction_queue:
		input_handler_3d.set_construction_queue(construction_queue)


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

	# Connect building stats display to grid
	if grid:
		var stats_display: BuildingStatsDisplay = hud.get_building_stats_display()
		if stats_display:
			stats_display.connect_to_grid(grid)

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
	if _is_3d_mode and input_handler_3d:
		input_handler_3d.handle_viewport_click(event)
	elif input_handler:
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
	if _is_3d_mode and input_handler_3d:
		match tool:
			ToolSidebar.Tool.SELECT:
				input_handler_3d.set_mode(InputHandler3DClass.Mode.SELECT)
				print("Mode: SELECT")
			ToolSidebar.Tool.BUILD:
				input_handler_3d.set_mode(InputHandler3DClass.Mode.BUILD)
				print("Mode: BUILD")
			ToolSidebar.Tool.DEMOLISH:
				input_handler_3d.set_mode(InputHandler3DClass.Mode.DEMOLISH)
				print("Mode: DEMOLISH")
			_:
				input_handler_3d.set_mode(InputHandler3DClass.Mode.SELECT)
				print("Mode: SELECT (fallback)")
	elif input_handler:
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
	if _is_3d_mode and input_handler_3d:
		input_handler_3d.set_selected_block_type(block_type)
	elif input_handler:
		input_handler.set_selected_block_type(block_type)
	print("Selected: %s" % block_type)


func _setup_block_picker() -> void:
	# Legacy block picker - provides keyboard shortcuts (1-6)
	block_picker = BlockPicker.new()
	ui_layer.add_child(block_picker)
	block_picker.block_type_selected.connect(_on_block_type_selected)
	print("Block picker ready. Keys 1-6 to select block type.")


func _on_block_type_selected(block_type: String) -> void:
	if _is_3d_mode and input_handler_3d:
		input_handler_3d.set_selected_block_type(block_type)
	elif input_handler:
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
	if _is_3d_mode:
		# In 3D mode, camera controls pane is disabled for now
		# The CameraOrbit script handles all controls directly
		print("3D mode: Camera controls handled by CameraOrbit (UI pane disabled)")
		return

	# Legacy 2D camera controls pane (disabled during 3D refactor)
	camera_controls_pane = CameraControlsPaneClass.new()
	camera_controls_pane.name = "CameraControlsPane"
	ui_layer.add_child(camera_controls_pane)

	# Connect to camera controller
	if camera_controller:
		camera_controls_pane.connect_to_camera(camera_controller)

	print("Camera controls: H toggle pane, Q/E rotate, +/- zoom, I/T view mode")


func _on_floor_visibility_changed(new_floor: int) -> void:
	if _is_3d_mode or not block_renderer:
		return
	block_renderer.update_visibility(new_floor)


func _on_view_mode_changed(show_all: bool) -> void:
	if _is_3d_mode:
		return
	# Update floor navigator display
	if hud and hud.bottom_bar:
		var floor_navigator: FloorNavigator = hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator")
		if floor_navigator:
			floor_navigator.set_view_mode(show_all)
	var mode := "ALL FLOORS" if show_all else "CUTAWAY"
	print("View mode: %s" % mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_V:
				# Toggle show all floors (2D mode only)
				if not _is_3d_mode and block_renderer:
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
	# Hide decoration at Z=0 when block placed (2D mode only)
	if not _is_3d_mode and pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.hide_decoration_at(pos_2d)
		terrain.hide_river_at(pos_2d)

	# Mark unsaved changes
	_mark_unsaved()


func _on_grid_block_removed(pos: Vector3i) -> void:
	# Show decoration at Z=0 when block removed (2D mode only)
	if not _is_3d_mode and pos.z == 0 and terrain:
		var pos_2d := Vector2i(pos.x, pos.y)
		terrain.show_decoration_at(pos_2d)
		terrain.show_river_at(pos_2d)

	# Mark unsaved changes
	_mark_unsaved()


func _place_starting_block() -> void:
	if _is_3d_mode:
		# In 3D mode, we still track grid data but don't render (yet)
		var entrance := Block.new("entrance", Vector3i(0, 0, 0))
		grid.set_block(entrance.grid_position, entrance)
		print("3D mode: Starting block added to grid (3D rendering in Phase 2)")
		return

	# Legacy 2D: Start with one entrance block at origin
	var entrance := Block.new("entrance", Vector3i(0, 0, 0))
	grid.set_block(entrance.grid_position, entrance)
	print("Starting block placed - start building!")


## Mark game as having unsaved changes
func _mark_unsaved() -> void:
	var menu_manager = get_tree().get_root().get_node_or_null("/root/MenuManager")
	if menu_manager:
		menu_manager.mark_unsaved_changes()


func _on_game_state_changed(_value) -> void:
	# Called when money or other game state changes
	_mark_unsaved()


func _on_config_applied(_config: Dictionary) -> void:
	# New game config applied - this is a fresh start, not unsaved
	# Don't mark unsaved here since it's the initial state
	pass


## Apply scenario config values to GameState constants
func _apply_scenario_to_game_state() -> void:
	if not scenario_config:
		return

	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		# Apply ground_depth as MIN_FLOOR (negative)
		# GameState.MIN_FLOOR is const, so we can't change it directly.
		# Instead, downstream systems should read from scenario_config.
		pass

	# Apply lighting from scenario config to scene environment
	if _is_3d_mode:
		_apply_scenario_lighting()


## Apply scenario lighting values to the 3D scene
func _apply_scenario_lighting() -> void:
	if not scenario_config:
		return

	# Find DirectionalLight3D in scene
	var light: DirectionalLight3D = null
	for child in get_children():
		if child is DirectionalLight3D:
			light = child
			break
	if not light and world:
		for child in world.get_children():
			if child is DirectionalLight3D:
				light = child
				break
	if light:
		light.light_energy = scenario_config.sun_energy

	# Find WorldEnvironment and apply ambient energy
	var world_env: WorldEnvironment = null
	for child in get_children():
		if child is WorldEnvironment:
			world_env = child
			break
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = scenario_config.ambient_energy


## Get current scenario config. Returns default if none loaded.
func get_scenario_config() -> Resource:
	if scenario_config:
		return scenario_config
	return ScenarioConfigClass.create_default()


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
	# Load terrain seed first (before any terrain generation) - 2D mode only
	if not _is_3d_mode and terrain:
		terrain.world_seed = data.get("terrain_seed", 0)

	# Clear existing blocks
	if grid:
		grid.clear()

	# Load blocks with connected status
	var blocks_data: Array = data.get("blocks", [])
	for block_data in blocks_data:
		var pos := Vector3i(
			block_data.get("x", 0),
			block_data.get("y", 0),
			block_data.get("z", 0)
		)
		var block_type: String = block_data.get("type", "residential_basic")
		var block := Block.new(block_type, pos)
		block.connected = block_data.get("connected", true)
		grid.set_block(pos, block)

	# Load full game state
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		# Check for new format (game_state object) vs old format (current_floor only)
		if data.has("game_state"):
			game_state.load_state(data.game_state)
		else:
			# Legacy format - just load current_floor
			game_state.current_floor = data.get("current_floor", 0)

	# Load config
	_game_config = data.get("config", {})

	# Load scenario config from save data
	var scenario_data: Dictionary = data.get("scenario_config", {})
	if not scenario_data.is_empty():
		scenario_config = ScenarioConfigClass.from_dict(scenario_data)
		_apply_scenario_to_game_state()

	# Load camera state
	var camera_data: Dictionary = data.get("camera", {})
	if camera_controller and not camera_data.is_empty():
		if _is_3d_mode:
			# 3D camera uses: target, azimuth, elevation, distance, ortho_size
			var target_pos := Vector3(
				camera_data.get("target_x", 0.0),
				camera_data.get("target_y", 0.0),
				camera_data.get("target_z", 0.0)
			)
			camera_controller.set_target(target_pos, true)
			camera_controller.set_azimuth(camera_data.get("azimuth", 45.0), true)
			camera_controller.set_elevation(camera_data.get("elevation", 45.0), true)
			camera_controller.set_distance(camera_data.get("distance", 100.0), true)
			camera_controller.set_ortho_size(camera_data.get("ortho_size", 50.0), true)
		else:
			# Legacy 2D camera state
			var pos := Vector2(
				camera_data.get("position_x", 0.0),
				camera_data.get("position_y", 0.0)
			)
			camera_controller.set_position(pos)
			camera_controller.set_zoom(camera_data.get("zoom", 1.0))
			camera_controller.set_rotation_index(camera_data.get("rotation_index", 0))
			camera_controller.apply_immediately()

	# Update HUD with loaded state
	if hud and game_state:
		hud.update_resources(game_state.money, game_state.population, int(game_state.aei_score))
		hud.update_datetime(game_state.year, game_state.month, game_state.day)
		hud.update_floor_display(game_state.current_floor)

	# Load block registry unlock state from config
	var block_registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if block_registry:
		if _game_config.get("all_blocks_unlocked", false):
			block_registry.unlock_all()
		else:
			block_registry.lock_all_to_defaults()

	print("Loaded %d blocks (save version: %s)" % [blocks_data.size(), data.get("version", "unknown")])


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

	# Save all blocks with connected status
	if grid:
		for block in grid.get_all_blocks():
			var block_data := {
				"x": block.grid_position.x,
				"y": block.grid_position.y,
				"z": block.grid_position.z,
				"type": block.block_type,
				"connected": block.connected if "connected" in block else true
			}
			blocks_data.append(block_data)

	# Get full game state
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	var state_data := {}
	if game_state:
		state_data = game_state.get_state()

	# Get camera state
	var camera_data := {}
	if camera_controller:
		if _is_3d_mode:
			# 3D camera uses: target, azimuth, elevation, distance, ortho_size
			camera_data = {
				"target_x": camera_controller.target.x,
				"target_y": camera_controller.target.y,
				"target_z": camera_controller.target.z,
				"azimuth": camera_controller.azimuth,
				"elevation": camera_controller.elevation,
				"distance": camera_controller.distance,
				"ortho_size": camera_controller.ortho_size
			}
		else:
			# Legacy 2D camera state
			camera_data = {
				"position_x": camera_controller.get_position().x,
				"position_y": camera_controller.get_position().y,
				"zoom": camera_controller.get_zoom(),
				"rotation_index": camera_controller.get_rotation_index()
			}

	# Get terrain seed (2D mode only)
	var terrain_seed := 0
	if not _is_3d_mode and terrain:
		terrain_seed = terrain.world_seed

	# Get statistics
	var stats := {
		"blocks_placed": grid.get_block_count() if grid else 0,
		"playtime_seconds": _get_playtime_seconds()
	}

	# Get scenario config
	var scenario_data := {}
	if scenario_config and scenario_config.has_method("to_dict"):
		scenario_data = scenario_config.to_dict()

	return {
		"name": save_name,
		"timestamp": timestamp,
		"version": "0.3.0",  # Upgraded: added scenario_config
		"game_state": state_data,
		"config": _game_config,
		"scenario_config": scenario_data,
		"blocks": blocks_data,
		"camera": camera_data,
		"terrain_seed": terrain_seed,
		"statistics": stats
	}


## Get current playtime in seconds (placeholder - needs proper tracking)
func _get_playtime_seconds() -> int:
	# TODO: Track actual playtime with Timer
	return 0
