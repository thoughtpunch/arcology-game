## GdUnit4 test suite for OrbitalCamera bookmark system (Ctrl+1-9 save, Alt+1-9 recall).
## Tests save/recall state, empty slot handling, orthographic toggle, history push,
## slot independence, overwrite behavior, and signal emission.
class_name TestOrbitalCameraBookmarks
extends GdUnitTestSuite

const CameraScript = preload("res://src/phase0/orbital_camera.gd")


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


func _make_alt_key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	ev.alt_pressed = true
	ev.ctrl_pressed = false
	return ev


# --- Tests: Initial state ---

func test_no_bookmarks_by_default() -> void:
	var cam := _make_camera()
	for i in range(9):
		assert_bool(cam.has_bookmark(i)).is_false()
	cam.queue_free()


func test_get_bookmark_returns_empty_dict_for_unset_slot() -> void:
	var cam := _make_camera()
	assert_dict(cam.get_bookmark(0)).is_empty()
	assert_dict(cam.get_bookmark(8)).is_empty()
	cam.queue_free()


# --- Tests: Save bookmark ---

func test_save_bookmark_stores_state() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(50, 10, 80)
	cam._target_azimuth = 120.0
	cam._target_elevation = 45.0
	cam._target_distance = 300.0
	cam._target_fov = 55.0

	cam.save_bookmark(0)

	assert_bool(cam.has_bookmark(0)).is_true()
	var bm: Dictionary = cam.get_bookmark(0)
	assert_vector(bm.target).is_equal(Vector3(50, 10, 80))
	assert_float(bm.azimuth).is_equal(120.0)
	assert_float(bm.elevation).is_equal(45.0)
	assert_float(bm.distance).is_equal(300.0)
	assert_float(bm.fov).is_equal(55.0)
	assert_bool(bm.is_orthographic).is_false()
	cam.queue_free()


func test_save_bookmark_stores_orthographic_state() -> void:
	var cam := _make_camera()
	cam.is_orthographic = true

	cam.save_bookmark(3)

	var bm: Dictionary = cam.get_bookmark(3)
	assert_bool(bm.is_orthographic).is_true()
	cam.queue_free()


func test_save_multiple_slots_independently() -> void:
	var cam := _make_camera()

	cam._target_azimuth = 10.0
	cam.save_bookmark(0)

	cam._target_azimuth = 90.0
	cam.save_bookmark(4)

	assert_float(cam.get_bookmark(0).azimuth).is_equal(10.0)
	assert_float(cam.get_bookmark(4).azimuth).is_equal(90.0)
	cam.queue_free()


func test_save_bookmark_overwrites_existing() -> void:
	var cam := _make_camera()

	cam._target_azimuth = 30.0
	cam.save_bookmark(2)

	cam._target_azimuth = 200.0
	cam.save_bookmark(2)

	assert_float(cam.get_bookmark(2).azimuth).is_equal(200.0)
	cam.queue_free()


# --- Tests: Recall bookmark ---

func test_recall_bookmark_restores_state() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(50, 10, 80)
	cam._target_azimuth = 120.0
	cam._target_elevation = 45.0
	cam._target_distance = 300.0
	cam._target_fov = 55.0
	cam.save_bookmark(0)

	# Move camera away
	cam._target_target = Vector3(0, 0, 0)
	cam._target_azimuth = 0.0
	cam._target_elevation = 0.0
	cam._target_distance = 100.0
	cam._target_fov = 70.0

	cam.recall_bookmark(0)

	assert_vector(cam._target_target).is_equal(Vector3(50, 10, 80))
	assert_float(cam._target_azimuth).is_equal(120.0)
	assert_float(cam._target_elevation).is_equal(45.0)
	assert_float(cam._target_distance).is_equal(300.0)
	assert_float(cam._target_fov).is_equal(55.0)
	cam.queue_free()


func test_recall_empty_slot_does_nothing() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 45.0
	cam._target_elevation = 30.0
	var original_az: float = cam._target_azimuth
	var original_el: float = cam._target_elevation

	cam.recall_bookmark(5)  # Empty slot

	assert_float(cam._target_azimuth).is_equal(original_az)
	assert_float(cam._target_elevation).is_equal(original_el)
	cam.queue_free()


func test_recall_toggles_orthographic_if_different() -> void:
	var cam := _make_camera()
	cam.is_orthographic = false
	cam.save_bookmark(0)

	# Switch to orthographic
	cam.is_orthographic = true
	cam.camera.projection = Camera3D.PROJECTION_ORTHOGONAL

	# Recall should switch back to perspective
	cam.recall_bookmark(0)
	assert_bool(cam.is_orthographic).is_false()
	cam.queue_free()


func test_recall_sets_orthographic_if_bookmark_was_ortho() -> void:
	var cam := _make_camera()
	cam.is_orthographic = true
	cam.save_bookmark(0)

	# Switch to perspective
	cam.is_orthographic = false
	cam.camera.projection = Camera3D.PROJECTION_PERSPECTIVE

	cam.recall_bookmark(0)
	assert_bool(cam.is_orthographic).is_true()
	cam.queue_free()


func test_recall_does_not_toggle_ortho_if_same() -> void:
	var cam := _make_camera()
	cam.is_orthographic = false
	cam.save_bookmark(0)

	# Still perspective
	cam.recall_bookmark(0)
	assert_bool(cam.is_orthographic).is_false()
	cam.queue_free()


func test_recall_pushes_history() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(500, 0, 500)
	cam._target_azimuth = 180.0
	cam.save_bookmark(0)

	# Move far enough that history push will accept
	cam._target_target = Vector3(0, 0, 0)
	cam._target_azimuth = 0.0
	var history_size_before: int = cam._history.size()

	cam.recall_bookmark(0)

	assert_int(cam._history.size()).is_greater(history_size_before)
	cam.queue_free()


# --- Tests: Key event handling ---

func test_ctrl_1_saves_bookmark_slot_0() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 77.0

	cam._handle_key(_make_ctrl_key_event(KEY_1))

	assert_bool(cam.has_bookmark(0)).is_true()
	assert_float(cam.get_bookmark(0).azimuth).is_equal(77.0)
	cam.queue_free()


func test_ctrl_9_saves_bookmark_slot_8() -> void:
	var cam := _make_camera()
	cam._target_distance = 500.0

	cam._handle_key(_make_ctrl_key_event(KEY_9))

	assert_bool(cam.has_bookmark(8)).is_true()
	assert_float(cam.get_bookmark(8).distance).is_equal(500.0)
	cam.queue_free()


func test_alt_1_recalls_bookmark_slot_0() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 77.0
	cam.save_bookmark(0)

	cam._target_azimuth = 0.0
	cam._handle_key(_make_alt_key_event(KEY_1))

	assert_float(cam._target_azimuth).is_equal(77.0)
	cam.queue_free()


func test_alt_9_recalls_bookmark_slot_8() -> void:
	var cam := _make_camera()
	cam._target_distance = 500.0
	cam.save_bookmark(8)

	cam._target_distance = 100.0
	cam._handle_key(_make_alt_key_event(KEY_9))

	assert_float(cam._target_distance).is_equal(500.0)
	cam.queue_free()


func test_alt_key_on_empty_slot_does_not_change_state() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 45.0

	cam._handle_key(_make_alt_key_event(KEY_5))  # Slot 4, never saved

	assert_float(cam._target_azimuth).is_equal(45.0)
	cam.queue_free()


# --- Tests: Clear bookmarks ---

func test_clear_bookmark_removes_slot() -> void:
	var cam := _make_camera()
	cam.save_bookmark(0)
	assert_bool(cam.has_bookmark(0)).is_true()

	cam.clear_bookmark(0)
	assert_bool(cam.has_bookmark(0)).is_false()
	cam.queue_free()


func test_clear_all_bookmarks() -> void:
	var cam := _make_camera()
	cam.save_bookmark(0)
	cam.save_bookmark(3)
	cam.save_bookmark(8)

	cam.clear_all_bookmarks()

	for i in range(9):
		assert_bool(cam.has_bookmark(i)).is_false()
	cam.queue_free()


# --- Tests: Signal emission ---

func test_save_emits_bookmark_saved_signal() -> void:
	var cam := _make_camera()
	var signal_monitor := monitor_signals(cam)

	cam.save_bookmark(2)

	assert_signal(cam).is_emitted("bookmark_saved", [2])
	cam.queue_free()


func test_recall_emits_bookmark_recalled_signal() -> void:
	var cam := _make_camera()
	cam.save_bookmark(5)
	var signal_monitor := monitor_signals(cam)

	cam.recall_bookmark(5)

	assert_signal(cam).is_emitted("bookmark_recalled", [5])
	cam.queue_free()


func test_recall_empty_slot_does_not_emit_signal() -> void:
	var cam := _make_camera()
	var signal_monitor := monitor_signals(cam)

	cam.recall_bookmark(7)

	assert_signal(cam).is_not_emitted("bookmark_recalled")
	cam.queue_free()


# --- Tests: Bookmark independence from current state ---

func test_bookmark_is_snapshot_not_reference() -> void:
	## Modifying camera state after save should not affect bookmark
	var cam := _make_camera()
	cam._target_target = Vector3(50, 10, 80)
	cam.save_bookmark(0)

	cam._target_target = Vector3(999, 999, 999)

	assert_vector(cam.get_bookmark(0).target).is_equal(Vector3(50, 10, 80))
	cam.queue_free()


# --- Tests: Regular number keys (no modifier) should NOT create bookmarks ---

func test_bare_number_key_does_not_save_bookmark() -> void:
	var cam := _make_camera()
	var ev := InputEventKey.new()
	ev.keycode = KEY_1
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = false
	ev.alt_pressed = false

	cam._handle_key(ev)

	assert_bool(cam.has_bookmark(0)).is_false()
	cam.queue_free()


# --- Tests: All 9 slots work ---

func test_all_nine_slots_save_and_recall() -> void:
	var cam := _make_camera()
	for i in range(9):
		cam._target_azimuth = float(i * 40)
		cam.save_bookmark(i)

	for i in range(9):
		cam.recall_bookmark(i)
		assert_float(cam._target_azimuth).is_equal(float(i * 40))

	cam.queue_free()
