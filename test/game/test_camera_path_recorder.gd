## GdUnit4 test suite for CameraPathRecorder - camera path recording and playback
class_name TestCameraPathRecorder
extends GdUnitTestSuite

const RecorderScript = preload("res://src/game/camera_path_recorder.gd")


func _make_state(target := Vector3.ZERO, azimuth := 45.0) -> Dictionary:
	return {
		"target": target,
		"azimuth": azimuth,
		"elevation": 30.0,
		"distance": 100.0,
		"fov": 70.0,
		"is_orthographic": false,
	}


func test_start_recording_clears_keyframes() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())

	recorder.start_recording()

	assert_int(recorder.get_keyframe_count()).is_equal(0)
	assert_bool(recorder.is_recording()).is_true()


func test_stop_recording() -> void:
	var recorder := RecorderScript.new()
	recorder.start_recording()

	recorder.stop_recording()

	assert_bool(recorder.is_recording()).is_false()


func test_add_keyframe() -> void:
	var recorder := RecorderScript.new()
	recorder.start_recording()

	recorder.add_keyframe(_make_state(Vector3(1, 0, 0)))
	recorder.add_keyframe(_make_state(Vector3(2, 0, 0)))

	assert_int(recorder.get_keyframe_count()).is_equal(2)


func test_clear() -> void:
	var recorder := RecorderScript.new()
	recorder.start_recording()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())

	recorder.clear()

	assert_int(recorder.get_keyframe_count()).is_equal(0)
	assert_bool(recorder.is_recording()).is_false()


func test_playback_requires_two_keyframes() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())

	var started := recorder.start_playback()

	assert_bool(started).is_false()
	assert_bool(recorder.is_playing()).is_false()


func test_playback_starts_with_two_keyframes() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())

	var started := recorder.start_playback()

	assert_bool(started).is_true()
	assert_bool(recorder.is_playing()).is_true()


func test_stop_playback() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())
	recorder.start_playback()

	recorder.stop_playback()

	assert_bool(recorder.is_playing()).is_false()


func test_update_returns_interpolated_state() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state(Vector3(0, 0, 0), 0.0))
	recorder.add_keyframe(_make_state(Vector3(100, 0, 0), 90.0))
	recorder.set_segment_duration(1.0)
	recorder.start_playback()

	# At t=0.5, should be partway between keyframes
	var state := recorder.update(0.5)

	assert_float(state.target.x).is_greater(10.0)
	assert_float(state.target.x).is_less(90.0)


func test_update_returns_empty_when_not_playing() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())

	var state := recorder.update(0.1)

	assert_bool(state.is_empty()).is_true()


func test_playback_loops() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state(Vector3(0, 0, 0)))
	recorder.add_keyframe(_make_state(Vector3(100, 0, 0)))
	recorder.set_segment_duration(1.0)
	recorder.start_playback()

	# Advance past the end (1 segment = 1 second)
	recorder.update(1.5)

	# Should still be playing (looped)
	assert_bool(recorder.is_playing()).is_true()


func test_playback_speed() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())
	recorder.set_segment_duration(1.0)

	recorder.set_playback_speed(2.0)

	assert_float(recorder.get_playback_speed()).is_equal(2.0)


func test_playback_speed_minimum() -> void:
	var recorder := RecorderScript.new()

	recorder.set_playback_speed(0.01)

	assert_float(recorder.get_playback_speed()).is_equal(0.1)


func test_get_first_keyframe() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state(Vector3(42, 0, 0)))
	recorder.add_keyframe(_make_state(Vector3(100, 0, 0)))

	var first := recorder.get_first_keyframe()

	assert_vector(first.target).is_equal(Vector3(42, 0, 0))


func test_export_and_import_keyframes() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state(Vector3(1, 0, 0)))
	recorder.add_keyframe(_make_state(Vector3(2, 0, 0)))

	var exported := recorder.export_keyframes()

	var recorder2 := RecorderScript.new()
	recorder2.import_keyframes(exported)

	assert_int(recorder2.get_keyframe_count()).is_equal(2)


func test_recording_started_signal() -> void:
	var recorder := RecorderScript.new()
	var result := [false]  # Use array to capture in lambda
	recorder.recording_started.connect(func(): result[0] = true)

	recorder.start_recording()

	assert_bool(result[0]).is_true()


func test_recording_stopped_signal() -> void:
	var recorder := RecorderScript.new()
	recorder.start_recording()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())
	var result := [-1]  # Use array to capture in lambda
	recorder.recording_stopped.connect(func(c): result[0] = c)

	recorder.stop_recording()

	assert_int(result[0]).is_equal(2)


func test_toggle_recording() -> void:
	var recorder := RecorderScript.new()

	recorder.toggle_recording()
	assert_bool(recorder.is_recording()).is_true()

	recorder.toggle_recording()
	assert_bool(recorder.is_recording()).is_false()


func test_toggle_playback() -> void:
	var recorder := RecorderScript.new()
	recorder.add_keyframe(_make_state())
	recorder.add_keyframe(_make_state())

	recorder.toggle_playback()
	assert_bool(recorder.is_playing()).is_true()

	recorder.toggle_playback()
	assert_bool(recorder.is_playing()).is_false()
