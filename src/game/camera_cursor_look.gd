class_name CameraCursorLook
extends RefCounted
## Manages cursor-look mode where camera orbits based on mouse position.
##
## Usage:
##   var cursor_look := CameraCursorLook.new()
##   cursor_look.toggle()
##   # Each frame:
##   var delta_angles := cursor_look.update(delta, mouse_pos, viewport_size, speed_multiplier)
##   target_azimuth += delta_angles.x
##   target_elevation += delta_angles.y

signal toggled(enabled: bool)

const DEFAULT_SENSITIVITY: float = 0.15  # Degrees per frame at screen edge
const DEFAULT_DEADZONE: float = 0.1  # Fraction of screen center with no movement

var sensitivity: float = DEFAULT_SENSITIVITY
var deadzone: float = DEFAULT_DEADZONE

var _enabled: bool = false


## Toggle cursor-look mode on/off.
func toggle() -> void:
	set_enabled(not _enabled)


## Enable or disable cursor-look mode.
func set_enabled(value: bool) -> void:
	if _enabled != value:
		_enabled = value
		toggled.emit(_enabled)


## Check if cursor-look is enabled.
func is_enabled() -> bool:
	return _enabled


## Update cursor-look and return angle deltas.
## Returns Vector2(azimuth_delta, elevation_delta) in degrees.
##
## Parameters:
##   delta: Frame delta time
##   mouse_pos: Current mouse position in viewport
##   viewport_size: Size of the viewport
##   speed_multiplier: Optional movement speed multiplier (default 1.0)
func update(delta: float, mouse_pos: Vector2, viewport_size: Vector2, speed_multiplier: float = 1.0) -> Vector2:
	if not _enabled:
		return Vector2.ZERO
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return Vector2.ZERO

	# Normalize to -1..1 (0,0 = center)
	var normalized := Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)

	# Apply deadzone
	normalized.x = _apply_deadzone(normalized.x)
	normalized.y = _apply_deadzone(normalized.y)

	if normalized == Vector2.ZERO:
		return Vector2.ZERO

	# Calculate orbit deltas (Y inverted for elevation)
	var orbit_speed := sensitivity * speed_multiplier * delta * 60.0  # Normalize to 60fps
	return Vector2(
		normalized.x * orbit_speed,
		-normalized.y * orbit_speed  # Invert Y so moving mouse up tilts up
	)


func _apply_deadzone(value: float) -> float:
	if abs(value) < deadzone:
		return 0.0
	# Remap from deadzone edge to 1
	return sign(value) * (abs(value) - deadzone) / (1.0 - deadzone)
