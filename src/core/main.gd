extends Node2D
## Main game scene controller
## Handles camera controls and game initialization

const PAN_SPEED := 500.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 3.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	print("Arcology initialized")


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
