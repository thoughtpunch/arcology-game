class_name CameraInertia
extends RefCounted
## Manages camera orbit inertia (momentum after releasing mouse drag).
##
## Usage:
##   var inertia := CameraInertia.new()
##   # During orbit drag, record velocity samples:
##   inertia.record_velocity(azimuth_delta, elevation_delta)
##   # On drag end:
##   inertia.start()
##   # Each frame:
##   var delta_angles := inertia.update(delta)
##   target_azimuth += delta_angles.x
##   target_elevation += delta_angles.y

signal toggled(enabled: bool)

const DEFAULT_DECAY_RATE: float = 4.0  # Higher = faster decay
const DEFAULT_MIN_VELOCITY: float = 0.5  # degrees/sec threshold to stop
const DEFAULT_VELOCITY_SCALE: float = 60.0  # Convert input delta to degrees/sec
const SAMPLE_COUNT: int = 3  # Number of velocity samples to average

var enabled: bool = true
var decay_rate: float = DEFAULT_DECAY_RATE
var min_velocity: float = DEFAULT_MIN_VELOCITY
var velocity_scale: float = DEFAULT_VELOCITY_SCALE

var _velocity: Vector2 = Vector2.ZERO  # degrees/sec (x=azimuth, y=elevation)
var _samples: Array[Vector2] = []


## Enable or disable inertia.
func set_enabled(value: bool) -> void:
	if enabled != value:
		enabled = value
		if not enabled:
			stop()
		toggled.emit(enabled)


## Check if inertia is enabled.
func is_enabled() -> bool:
	return enabled


## Record a velocity sample during orbit drag.
## Call this each frame while dragging.
func record_velocity(azimuth_delta: float, elevation_delta: float) -> void:
	if not enabled:
		return
	var sample := Vector2(azimuth_delta, elevation_delta) * velocity_scale
	_samples.append(sample)
	if _samples.size() > SAMPLE_COUNT:
		_samples.pop_front()


## Clear recorded velocity samples.
func clear_samples() -> void:
	_samples.clear()


## Start inertia from recorded samples.
## Call this when orbit drag ends.
func start() -> void:
	if not enabled or _samples.is_empty():
		_velocity = Vector2.ZERO
		return

	# Average the samples
	var avg := Vector2.ZERO
	for sample in _samples:
		avg += sample
	avg /= _samples.size()

	_velocity = avg
	_samples.clear()


## Immediately stop any active inertia.
func stop() -> void:
	_velocity = Vector2.ZERO
	_samples.clear()


## Update inertia and return angle deltas to apply.
## Returns Vector2(azimuth_delta, elevation_delta) in degrees.
func update(delta: float) -> Vector2:
	if not enabled:
		return Vector2.ZERO
	if _velocity.length() < min_velocity:
		_velocity = Vector2.ZERO
		return Vector2.ZERO

	var result := _velocity * delta

	# Exponential decay
	_velocity *= exp(-decay_rate * delta)

	return result


## Get current velocity (for debugging/UI).
func get_velocity() -> Vector2:
	return _velocity


## Check if inertia is currently active (has momentum).
func is_active() -> bool:
	return _velocity.length() >= min_velocity
