class_name CameraPathRecorder
extends RefCounted
## Records and plays back camera movement paths.
##
## Usage:
##   var recorder := CameraPathRecorder.new()
##   recorder.start_recording()
##   recorder.add_keyframe(camera_state)
##   recorder.stop_recording()
##   recorder.start_playback()
##   # In _process: var state = recorder.update(delta)

signal recording_started()
signal recording_stopped(keyframe_count: int)
signal playback_started(keyframe_count: int)
signal playback_stopped()
signal keyframe_added(index: int)

const DEFAULT_SEGMENT_DURATION: float = 2.0  # Seconds between keyframes during playback
const MIN_PLAYBACK_SPEED: float = 0.1

var _keyframes: Array[Dictionary] = []
var _is_recording: bool = false
var _is_playing: bool = false
var _playback_time: float = 0.0
var _playback_speed: float = 1.0
var _segment_duration: float = DEFAULT_SEGMENT_DURATION


## Start recording. Clears any existing keyframes.
func start_recording() -> void:
	if _is_playing:
		stop_playback()
	_is_recording = true
	_keyframes.clear()
	recording_started.emit()


## Stop recording.
func stop_recording() -> void:
	_is_recording = false
	recording_stopped.emit(_keyframes.size())


## Toggle recording on/off.
func toggle_recording() -> void:
	if _is_recording:
		stop_recording()
	else:
		start_recording()


## Add a keyframe with the given camera state.
func add_keyframe(state: Dictionary) -> void:
	var keyframe := state.duplicate()
	keyframe["time"] = Time.get_ticks_msec() / 1000.0
	_keyframes.append(keyframe)
	keyframe_added.emit(_keyframes.size() - 1)


## Check if currently recording.
func is_recording() -> bool:
	return _is_recording


## Get number of recorded keyframes.
func get_keyframe_count() -> int:
	return _keyframes.size()


## Clear all keyframes.
func clear() -> void:
	_keyframes.clear()
	_is_recording = false
	_is_playing = false


## Start playback. Requires at least 2 keyframes.
## Returns false if not enough keyframes.
func start_playback() -> bool:
	if _keyframes.size() < 2:
		return false
	if _is_recording:
		stop_recording()
	_is_playing = true
	_playback_time = 0.0
	playback_started.emit(_keyframes.size())
	return true


## Stop playback.
func stop_playback() -> void:
	_is_playing = false
	playback_stopped.emit()


## Toggle playback on/off.
func toggle_playback() -> void:
	if _is_playing:
		stop_playback()
	else:
		start_playback()


## Check if currently playing.
func is_playing() -> bool:
	return _is_playing


## Set playback speed multiplier (minimum 0.1).
func set_playback_speed(speed: float) -> void:
	_playback_speed = maxf(MIN_PLAYBACK_SPEED, speed)


## Get current playback speed.
func get_playback_speed() -> float:
	return _playback_speed


## Set duration between keyframes during playback.
func set_segment_duration(duration: float) -> void:
	_segment_duration = maxf(0.1, duration)


## Update playback and return interpolated state.
## Returns empty dict if not playing or no keyframes.
## Call this each frame during playback.
func update(delta: float) -> Dictionary:
	if not _is_playing or _keyframes.size() < 2:
		return {}

	_playback_time += delta * _playback_speed

	var segment_count := _keyframes.size() - 1
	var total_duration := segment_count * _segment_duration

	# Loop at end
	if _playback_time >= total_duration:
		_playback_time = fmod(_playback_time, total_duration)

	# Find segment
	var segment_index := int(_playback_time / _segment_duration)
	segment_index = clampi(segment_index, 0, segment_count - 1)
	var segment_t := fmod(_playback_time, _segment_duration) / _segment_duration

	var kf_a: Dictionary = _keyframes[segment_index]
	var kf_b: Dictionary = _keyframes[segment_index + 1]

	# Smoothstep interpolation
	var t := _smoothstep(segment_t)

	return _interpolate_states(kf_a, kf_b, t)


## Get the first keyframe state (for initializing camera at playback start).
func get_first_keyframe() -> Dictionary:
	if _keyframes.is_empty():
		return {}
	return _keyframes[0].duplicate()


## Export keyframes for saving.
func export_keyframes() -> Array[Dictionary]:
	return _keyframes.duplicate()


## Import keyframes from saved data.
func import_keyframes(keyframes: Array[Dictionary]) -> void:
	_keyframes = keyframes.duplicate()
	_is_recording = false
	_is_playing = false


## Get current playback progress (0.0 to 1.0).
func get_playback_progress() -> float:
	if not _is_playing or _keyframes.size() < 2:
		return 0.0
	var segment_count := _keyframes.size() - 1
	var total_duration := segment_count * _segment_duration
	return _playback_time / total_duration


func _smoothstep(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _interpolate_states(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {
		"target": a.target.lerp(b.target, t) if a.has("target") and b.has("target") else a.get("target", Vector3.ZERO),
		"azimuth": lerpf(a.get("azimuth", 0.0), b.get("azimuth", 0.0), t),
		"elevation": lerpf(a.get("elevation", 0.0), b.get("elevation", 0.0), t),
		"distance": lerpf(a.get("distance", 100.0), b.get("distance", 100.0), t),
		"fov": lerpf(a.get("fov", 70.0), b.get("fov", 70.0), t),
		"is_orthographic": b.get("is_orthographic", false) if t > 0.5 else a.get("is_orthographic", false),
	}
