extends Node2D
## Main game scene controller
## Handles camera controls and game initialization

const PAN_SPEED := 500.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 3.0

@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World

var grid: Grid
var block_renderer: BlockRenderer


func _ready() -> void:
	print("Arcology initialized")
	_setup_grid()
	_place_test_blocks()


func _setup_grid() -> void:
	# Create grid
	grid = Grid.new()
	add_child(grid)

	# Create renderer and connect to grid
	block_renderer = BlockRenderer.new()
	world.add_child(block_renderer)
	block_renderer.connect_to_grid(grid)


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
