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
var overlay_sidebar: OverlaySidebar
var info_panel_manager: InfoPanelManager
var toast_notification: ToastNotification


func _ready() -> void:
	print("Arcology initialized")
	_setup_terrain()
	_setup_grid()
	_setup_input_handler()
	_setup_simple_ui()  # Minimal UI like reference video
	_place_test_blocks()


func _setup_simple_ui() -> void:
	# Create a minimal block picker at bottom of screen (like reference video)
	var block_bar := HBoxContainer.new()
	block_bar.name = "BlockBar"
	block_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	block_bar.offset_top = -80
	block_bar.offset_bottom = -16
	block_bar.add_theme_constant_override("separation", 12)
	ui_layer.add_child(block_bar)

	# Get block types from registry
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if not registry:
		push_warning("BlockRegistry not found")
		return

	# Create icon buttons for each block type
	var block_types := ["corridor", "entrance", "stairs", "residential_basic", "commercial_basic"]
	for i in range(block_types.size()):
		var block_type: String = block_types[i]
		var block_data: Dictionary = registry.get_block_data(block_type)

		var btn := Button.new()
		btn.name = block_type
		btn.custom_minimum_size = Vector2(64, 64)
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)  # Select first by default

		# Try to load sprite as button icon
		var sprite_path: String = block_data.get("sprite", "")
		if sprite_path != "" and ResourceLoader.exists(sprite_path):
			var texture := load(sprite_path) as Texture2D
			if texture:
				btn.icon = texture
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
		else:
			# Fallback to text
			btn.text = str(i + 1)

		# Style the button
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style)

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

		btn.pressed.connect(_on_simple_block_selected.bind(block_type, block_bar))
		block_bar.add_child(btn)

	# Select first block by default
	if block_types.size() > 0:
		input_handler.set_selected_block_type(block_types[0])

	print("Simple UI ready. Click blocks at bottom, then click to place.")


func _on_simple_block_selected(block_type: String, bar: HBoxContainer) -> void:
	# Deselect all buttons
	for child in bar.get_children():
		if child is Button:
			child.button_pressed = (child.name == block_type)

	# Set the selected block type
	input_handler.set_selected_block_type(block_type)
	print("Selected: %s" % block_type)


func _setup_terrain() -> void:
	# Create terrain as first child of world (renders beneath everything)
	terrain = Terrain.new()
	world.add_child(terrain)
	terrain.move_to_front()  # Actually we want it at back
	world.move_child(terrain, 0)  # Move to index 0 (first child, renders first)

	# Set default theme from terrain.json (earth)
	terrain.theme = "earth"

	# For now, just use a simple green background without decorations or river
	# This keeps the game clean and focused on core gameplay
	# Decorations and river can be enabled later once the core is solid
	print("Terrain ready (simple green background)")


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
	input_handler.block_selected.connect(_on_block_selected)

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


func _on_info_panel_block_action(action: String, block_pos: Vector3i) -> void:
	match action:
		"demolish":
			if grid.has_block(block_pos):
				grid.remove_block(block_pos)
				print("Demolished block at %s" % block_pos)
				info_panel_manager.close_current_panel()
		"upgrade":
			print("Upgrade requested for block at %s" % block_pos)
		"details":
			print("Details requested for block at %s" % block_pos)


func _on_block_selected(pos: Vector3i, block_type: String) -> void:
	print("Block selected: %s at %s" % [block_type, pos])

	# Get block data from grid
	var block = grid.get_block_at(pos)
	var block_data := {}

	if block:
		# Build block_data dictionary with available information
		block_data["status"] = "Vacant"  # Default, would come from simulation
		block_data["environment"] = {
			"light": 75.0,
			"air": 80.0,
			"noise": 30.0,
			"safety": 70.0,
			"vibes": 60.0
		}
		block_data["economics"] = {
			"rent": 100,
			"desirability": 0.72,
			"maintenance": 15
		}

	# Show the info panel
	info_panel_manager.show_block_info(pos, block_type, block_data)


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
	# Time display is now handled by TimeControls connected to GameState

	# Connect tool sidebar signals
	_connect_tool_sidebar()

	# Setup info panel manager
	_setup_info_panel_manager()

	# Setup toast notifications
	_setup_toast_notifications()

	print("HUD ready.")


func _connect_tool_sidebar() -> void:
	# Get the ToolSidebar from HUD
	if not hud or not hud.left_sidebar:
		push_warning("ToolSidebar not found in HUD")
		return

	var tool_sidebar: ToolSidebar = hud.left_sidebar as ToolSidebar
	if tool_sidebar:
		tool_sidebar.tool_selected.connect(_on_tool_selected)
		tool_sidebar.quick_build_selected.connect(_on_quick_build_selected)
		tool_sidebar.favorite_selected.connect(_on_favorite_selected)
		print("Tool sidebar connected.")


func _on_tool_selected(tool: int) -> void:
	# Map ToolSidebar.Tool enum to InputHandler.Mode
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
		ToolSidebar.Tool.INFO:
			input_handler.set_mode(InputHandler.Mode.SELECT)
			print("Mode: INFO (using SELECT mode)")
		ToolSidebar.Tool.UPGRADE:
			input_handler.set_mode(InputHandler.Mode.SELECT)
			print("Mode: UPGRADE (using SELECT mode)")


func _on_quick_build_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	input_handler.set_mode(InputHandler.Mode.BUILD)
	print("Quick build: %s" % block_type)


func _on_favorite_selected(block_type: String) -> void:
	input_handler.set_selected_block_type(block_type)
	input_handler.set_mode(InputHandler.Mode.BUILD)
	print("Favorite: %s" % block_type)


func _setup_info_panel_manager() -> void:
	info_panel_manager = InfoPanelManager.new()
	add_child(info_panel_manager)
	info_panel_manager.setup(hud)

	# Connect to block actions
	info_panel_manager.block_action.connect(_on_info_panel_block_action)

	print("Info panel manager ready.")


func _setup_toast_notifications() -> void:
	# Create toast notification container
	toast_notification = ToastNotification.new()
	toast_notification.name = "ToastNotification"

	# Position in top-right corner
	toast_notification.anchor_left = 1.0
	toast_notification.anchor_right = 1.0
	toast_notification.anchor_top = 0.0
	toast_notification.anchor_bottom = 0.0

	# Offset from edge (below top bar)
	toast_notification.offset_left = -320  # Toast width
	toast_notification.offset_right = -16  # Right margin
	toast_notification.offset_top = 56  # Below top bar
	toast_notification.offset_bottom = 500  # Room for toasts

	ui_layer.add_child(toast_notification)

	print("Toast notifications ready.")


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


func _setup_overlay_sidebar() -> void:
	# Create overlay sidebar on right side of screen
	overlay_sidebar = OverlaySidebar.new()
	overlay_sidebar.name = "OverlaySidebar"

	# Anchor to right side, below top bar and above bottom bar
	overlay_sidebar.anchor_left = 1.0
	overlay_sidebar.anchor_right = 1.0
	overlay_sidebar.anchor_top = 0.0
	overlay_sidebar.anchor_bottom = 1.0

	# Position to right edge with margins for top/bottom bars
	overlay_sidebar.offset_left = -64  # Start at collapsed width
	overlay_sidebar.offset_right = 0
	overlay_sidebar.offset_top = 56  # Below top bar (48px + 8px margin)
	overlay_sidebar.offset_bottom = -88  # Above bottom bar (80px + 8px margin)

	# Grow left when expanding
	overlay_sidebar.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	ui_layer.add_child(overlay_sidebar)

	# Connect overlay change signal
	overlay_sidebar.overlay_changed.connect(_on_overlay_changed)

	print("Overlay sidebar ready. F2-F9 for overlays, ` for None.")


func _on_overlay_changed(overlay_type: int) -> void:
	var overlay_name := OverlaySidebar.get_overlay_name(overlay_type)
	print("Overlay changed to: %s" % overlay_name)
	# Future: trigger actual overlay rendering system


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
	# Start with an empty canvas - player places blocks
	# Just place one entrance to start
	var entrance := Block.new("entrance", Vector3i(0, 0, 0))
	grid.set_block(entrance.grid_position, entrance)
	print("Starting block placed. Click to build!")


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
