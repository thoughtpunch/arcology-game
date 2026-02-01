## GdUnit4 test suite for OrbitalCamera path recording and playback.
## Tests Ctrl+R recording toggle, Ctrl+P playback, keyframe capture,
## smooth interpolation, signal emission, and edge cases.
class_name TestOrbitalCameraPath
extends GdUnitTestSuite

const CameraScript = preload("res://src/game/orbital_camera.gd")


# --- Helpers ---

func _make_camera() -> Node3D:
	## Create a camera in the scene tree so viewport calls work
	var cam: Node3D = CameraScript.new()
	cam.target = Vector3(100, 0, 100)
	cam._target_target = Vector3(100, 0, 100)
	add_child(cam)
	return cam


func _make_ctrl_key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = true
	ev.alt_pressed = false
	return ev


# --- Tests: Initial state ---

func test_not_recording_by_default() -> void:
	var cam := _make_camera()
	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()


func test_not_playing_by_default() -> void:
	var cam := _make_camera()
	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


func test_no_keyframes_by_default() -> void:
	var cam := _make_camera()
	assert_int(cam.get_path_keyframe_count()).is_equal(0)
	cam.queue_free()


# --- Tests: Start recording ---

func test_start_recording_sets_flag() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	assert_bool(cam.is_recording_path()).is_true()
	cam.queue_free()


func test_start_recording_clears_existing_keyframes() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam.add_path_keyframe()
	cam.add_path_keyframe()
	assert_int(cam.get_path_keyframe_count()).is_equal(3)  # Initial + 2

	cam.start_path_recording()  # Should clear and add initial
	assert_int(cam.get_path_keyframe_count()).is_equal(1)
	cam.queue_free()


func test_start_recording_captures_initial_keyframe() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(50, 10, 80)
	cam._target_azimuth = 120.0

	cam.start_path_recording()

	assert_int(cam.get_path_keyframe_count()).is_equal(1)
	var keyframes: Array = cam.get_path_keyframes()
	assert_vector(keyframes[0].target).is_equal(Vector3(50, 10, 80))
	assert_float(keyframes[0].azimuth).is_equal(120.0)
	cam.queue_free()


func test_start_recording_emits_signal() -> void:
	var cam := _make_camera()
	var _monitor := monitor_signals(cam)

	cam.start_path_recording()

	assert_signal(cam).is_emitted("path_recording_started")
	cam.queue_free()


# --- Tests: Stop recording ---

func test_stop_recording_clears_flag() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam.stop_path_recording()
	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()


func test_stop_recording_preserves_keyframes() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam.add_path_keyframe()
	cam.add_path_keyframe()
	var count_before: int = cam.get_path_keyframe_count()

	cam.stop_path_recording()

	assert_int(cam.get_path_keyframe_count()).is_equal(count_before)
	cam.queue_free()


func test_stop_recording_emits_signal_with_count() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam.add_path_keyframe()
	var _monitor := monitor_signals(cam)

	cam.stop_path_recording()

	assert_signal(cam).is_emitted("path_recording_stopped", [2])
	cam.queue_free()


# --- Tests: Toggle recording ---

func test_toggle_starts_recording_when_not_recording() -> void:
	var cam := _make_camera()
	cam.toggle_path_recording()
	assert_bool(cam.is_recording_path()).is_true()
	cam.queue_free()


func test_toggle_stops_recording_when_recording() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam.toggle_path_recording()
	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()


func test_toggle_recording_stops_playback() -> void:
	var cam := _make_camera()
	# Setup playback
	cam.start_path_recording()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.stop_path_recording()
	cam.start_path_playback()
	assert_bool(cam.is_playing_path()).is_true()

	cam.toggle_path_recording()

	assert_bool(cam.is_playing_path()).is_false()
	assert_bool(cam.is_recording_path()).is_true()
	cam.queue_free()


# --- Tests: Add keyframe ---

func test_add_keyframe_captures_current_state() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(200, 50, 300)
	cam._target_azimuth = 45.0
	cam._target_elevation = 60.0
	cam._target_distance = 150.0
	cam._target_fov = 80.0
	cam.is_orthographic = true

	cam.add_path_keyframe()

	var keyframes: Array = cam.get_path_keyframes()
	assert_int(keyframes.size()).is_equal(1)
	assert_vector(keyframes[0].target).is_equal(Vector3(200, 50, 300))
	assert_float(keyframes[0].azimuth).is_equal(45.0)
	assert_float(keyframes[0].elevation).is_equal(60.0)
	assert_float(keyframes[0].distance).is_equal(150.0)
	assert_float(keyframes[0].fov).is_equal(80.0)
	assert_bool(keyframes[0].is_orthographic).is_true()
	cam.queue_free()


func test_add_keyframe_emits_signal_with_index() -> void:
	var cam := _make_camera()
	var _monitor := monitor_signals(cam)

	cam.add_path_keyframe()  # Index 0

	assert_signal(cam).is_emitted("path_keyframe_added", [0])
	cam.queue_free()


func test_keyframes_accumulate() -> void:
	var cam := _make_camera()

	cam._target_azimuth = 0.0
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam._target_azimuth = 180.0
	cam.add_path_keyframe()

	assert_int(cam.get_path_keyframe_count()).is_equal(3)
	var keyframes: Array = cam.get_path_keyframes()
	assert_float(keyframes[0].azimuth).is_equal(0.0)
	assert_float(keyframes[1].azimuth).is_equal(90.0)
	assert_float(keyframes[2].azimuth).is_equal(180.0)
	cam.queue_free()


# --- Tests: Clear path ---

func test_clear_path_removes_all_keyframes() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam.add_path_keyframe()
	cam.add_path_keyframe()

	cam.clear_path()

	assert_int(cam.get_path_keyframe_count()).is_equal(0)
	cam.queue_free()


# --- Tests: Playback requirements ---

func test_playback_requires_at_least_2_keyframes() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()  # Only 1 keyframe

	cam.start_path_playback()

	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


func test_playback_starts_with_2_keyframes() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()

	cam.start_path_playback()

	assert_bool(cam.is_playing_path()).is_true()
	cam.queue_free()


func test_playback_emits_signal_with_count() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	var _monitor := monitor_signals(cam)

	cam.start_path_playback()

	assert_signal(cam).is_emitted("path_playback_started", [2])
	cam.queue_free()


# --- Tests: Playback state ---

func test_playback_sets_camera_to_first_keyframe() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(0, 0, 0)
	cam._target_azimuth = 0.0
	cam.add_path_keyframe()

	cam._target_target = Vector3(100, 50, 100)
	cam._target_azimuth = 180.0
	cam.add_path_keyframe()

	# Move camera elsewhere
	cam._target_target = Vector3(999, 999, 999)
	cam._target_azimuth = 45.0

	cam.start_path_playback()

	# Should jump to first keyframe
	assert_vector(cam._target_target).is_equal(Vector3(0, 0, 0))
	assert_float(cam._target_azimuth).is_equal(0.0)
	cam.queue_free()


func test_stop_playback_clears_flag() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	cam.stop_path_playback()

	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


func test_stop_playback_emits_signal() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()
	var _monitor := monitor_signals(cam)

	cam.stop_path_playback()

	assert_signal(cam).is_emitted("path_playback_stopped")
	cam.queue_free()


# --- Tests: Toggle playback ---

func test_toggle_starts_playback_when_not_playing() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()

	cam.toggle_path_playback()

	assert_bool(cam.is_playing_path()).is_true()
	cam.queue_free()


func test_toggle_stops_playback_when_playing() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	cam.toggle_path_playback()

	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


func test_toggle_playback_stops_recording() -> void:
	var cam := _make_camera()
	cam.start_path_recording()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()

	cam.toggle_path_playback()

	assert_bool(cam.is_recording_path()).is_false()
	assert_bool(cam.is_playing_path()).is_true()
	cam.queue_free()


# --- Tests: Playback interpolation ---

func test_playback_interpolates_over_time() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 0.0
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	# Simulate half-way through first segment
	cam._playback_time = cam.PATH_PLAYBACK_DURATION * 0.5
	cam._update_playback(0.0)

	# Should be roughly halfway between 0 and 90 degrees
	# Using smoothstep so at t=0.5: 3*0.25 - 2*0.125 = 0.5
	assert_float(cam._target_azimuth).is_equal_approx(45.0, 1.0)
	cam.queue_free()


func test_playback_loops_at_end() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 0.0
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	# Go past the end
	var total_duration: float = cam.PATH_PLAYBACK_DURATION
	cam._playback_time = total_duration + 0.1
	cam._update_playback(0.0)

	# Should loop back
	assert_float(cam._playback_time).is_less(total_duration)
	cam.queue_free()


# --- Tests: Playback speed ---

func test_set_playback_speed() -> void:
	var cam := _make_camera()
	cam.set_playback_speed(2.0)
	assert_float(cam.get_playback_speed()).is_equal(2.0)
	cam.queue_free()


func test_playback_speed_minimum() -> void:
	var cam := _make_camera()
	cam.set_playback_speed(0.01)  # Below minimum
	assert_float(cam.get_playback_speed()).is_equal(0.1)  # Clamped to minimum
	cam.queue_free()


# --- Tests: Key event handling ---

func test_ctrl_r_starts_recording() -> void:
	var cam := _make_camera()

	cam._handle_key(_make_ctrl_key_event(KEY_R))

	assert_bool(cam.is_recording_path()).is_true()
	cam.queue_free()


func test_ctrl_r_stops_recording_when_active() -> void:
	var cam := _make_camera()
	cam.start_path_recording()

	cam._handle_key(_make_ctrl_key_event(KEY_R))

	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()


func test_ctrl_p_starts_playback() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()

	cam._handle_key(_make_ctrl_key_event(KEY_P))

	assert_bool(cam.is_playing_path()).is_true()
	cam.queue_free()


func test_ctrl_p_stops_playback_when_active() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	cam._handle_key(_make_ctrl_key_event(KEY_P))

	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


# --- Tests: Path data import/export ---

func test_get_keyframes_returns_copy() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 45.0
	cam.add_path_keyframe()

	var keyframes: Array = cam.get_path_keyframes()
	keyframes.clear()

	# Original should be unchanged
	assert_int(cam.get_path_keyframe_count()).is_equal(1)
	cam.queue_free()


func test_set_keyframes_loads_path() -> void:
	var cam := _make_camera()
	var keyframes: Array[Dictionary] = [
		{"target": Vector3(0, 0, 0), "azimuth": 0.0, "elevation": 30.0, "distance": 100.0, "fov": 70.0, "is_orthographic": false, "time": 0.0},
		{"target": Vector3(100, 0, 100), "azimuth": 90.0, "elevation": 45.0, "distance": 150.0, "fov": 70.0, "is_orthographic": false, "time": 1.0},
	]

	cam.set_path_keyframes(keyframes)

	assert_int(cam.get_path_keyframe_count()).is_equal(2)
	var loaded: Array = cam.get_path_keyframes()
	assert_float(loaded[0].azimuth).is_equal(0.0)
	assert_float(loaded[1].azimuth).is_equal(90.0)
	cam.queue_free()


# --- Tests: Multi-segment playback ---

func test_playback_traverses_multiple_keyframes() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 0.0
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()
	cam._target_azimuth = 180.0
	cam.add_path_keyframe()
	cam.start_path_playback()

	# Go to start of second segment (t=1.0 in normalized time)
	cam._playback_time = cam.PATH_PLAYBACK_DURATION
	cam._update_playback(0.0)

	# Should be at/near the second keyframe (azimuth 90)
	assert_float(cam._target_azimuth).is_equal_approx(90.0, 1.0)
	cam.queue_free()


# --- Tests: Orthographic handling in playback ---

func test_playback_handles_orthographic_transition() -> void:
	var cam := _make_camera()
	cam.is_orthographic = false
	cam.add_path_keyframe()

	cam.is_orthographic = true
	cam.add_path_keyframe()
	cam.start_path_playback()

	# First keyframe is perspective
	assert_bool(cam.is_orthographic).is_false()

	# Move past midpoint of segment
	cam._playback_time = cam.PATH_PLAYBACK_DURATION * 0.6
	cam._update_playback(0.0)

	# Should have transitioned to orthographic
	assert_bool(cam.is_orthographic).is_true()
	cam.queue_free()


# --- Tests: Negative cases ---

func test_bare_r_key_does_not_start_recording() -> void:
	var cam := _make_camera()
	var ev := InputEventKey.new()
	ev.keycode = KEY_R
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = false
	ev.alt_pressed = false

	cam._handle_key(ev)

	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()


func test_bare_p_key_does_not_start_playback() -> void:
	var cam := _make_camera()
	cam.add_path_keyframe()
	cam._target_azimuth = 90.0
	cam.add_path_keyframe()

	var ev := InputEventKey.new()
	ev.keycode = KEY_P
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = false
	ev.alt_pressed = false

	cam._handle_key(ev)

	assert_bool(cam.is_playing_path()).is_false()
	cam.queue_free()


func test_alt_r_does_not_start_recording() -> void:
	var cam := _make_camera()
	var ev := InputEventKey.new()
	ev.keycode = KEY_R
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = false
	ev.alt_pressed = true

	cam._handle_key(ev)

	assert_bool(cam.is_recording_path()).is_false()
	cam.queue_free()
