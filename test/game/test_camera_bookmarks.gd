## GdUnit4 test suite for CameraBookmarks - camera position bookmark management
class_name TestCameraBookmarks
extends GdUnitTestSuite

const CameraBookmarksScript = preload("res://src/game/camera_bookmarks.gd")


func _make_state(target := Vector3.ZERO, azimuth := 45.0, elevation := 30.0) -> Dictionary:
	return {
		"target": target,
		"azimuth": azimuth,
		"elevation": elevation,
		"distance": 100.0,
		"fov": 70.0,
		"is_orthographic": false,
	}


func test_save_and_recall_bookmark() -> void:
	var bookmarks := CameraBookmarksScript.new()
	var state := _make_state(Vector3(10, 0, 10), 90.0, 45.0)

	bookmarks.save(0, state)
	var recalled := bookmarks.recall(0)

	assert_vector(recalled.target).is_equal(Vector3(10, 0, 10))
	assert_float(recalled.azimuth).is_equal(90.0)
	assert_float(recalled.elevation).is_equal(45.0)


func test_recall_empty_slot_returns_empty_dict() -> void:
	var bookmarks := CameraBookmarksScript.new()

	var recalled := bookmarks.recall(5)

	assert_bool(recalled.is_empty()).is_true()


func test_has_bookmark() -> void:
	var bookmarks := CameraBookmarksScript.new()
	var state := _make_state()

	assert_bool(bookmarks.has(0)).is_false()
	bookmarks.save(0, state)
	assert_bool(bookmarks.has(0)).is_true()
	assert_bool(bookmarks.has(1)).is_false()


func test_clear_bookmark() -> void:
	var bookmarks := CameraBookmarksScript.new()
	bookmarks.save(0, _make_state())
	bookmarks.save(1, _make_state())

	bookmarks.clear(0)

	assert_bool(bookmarks.has(0)).is_false()
	assert_bool(bookmarks.has(1)).is_true()


func test_clear_all_bookmarks() -> void:
	var bookmarks := CameraBookmarksScript.new()
	bookmarks.save(0, _make_state())
	bookmarks.save(1, _make_state())
	bookmarks.save(2, _make_state())

	bookmarks.clear_all()

	assert_int(bookmarks.get_count()).is_equal(0)


func test_get_count() -> void:
	var bookmarks := CameraBookmarksScript.new()

	assert_int(bookmarks.get_count()).is_equal(0)
	bookmarks.save(0, _make_state())
	assert_int(bookmarks.get_count()).is_equal(1)
	bookmarks.save(5, _make_state())
	assert_int(bookmarks.get_count()).is_equal(2)


func test_get_occupied_slots() -> void:
	var bookmarks := CameraBookmarksScript.new()
	bookmarks.save(2, _make_state())
	bookmarks.save(0, _make_state())
	bookmarks.save(7, _make_state())

	var slots := bookmarks.get_occupied_slots()

	assert_array(slots).contains_exactly([0, 2, 7])


func test_export_and_import() -> void:
	var bookmarks := CameraBookmarksScript.new()
	bookmarks.save(0, _make_state(Vector3(1, 2, 3)))
	bookmarks.save(3, _make_state(Vector3(4, 5, 6)))

	var exported := bookmarks.export_all()

	var bookmarks2 := CameraBookmarksScript.new()
	bookmarks2.import_all(exported)

	assert_int(bookmarks2.get_count()).is_equal(2)
	assert_vector(bookmarks2.recall(0).target).is_equal(Vector3(1, 2, 3))
	assert_vector(bookmarks2.recall(3).target).is_equal(Vector3(4, 5, 6))


func test_save_emits_signal() -> void:
	var bookmarks := CameraBookmarksScript.new()
	var result := [-1]  # Use array to capture in lambda
	bookmarks.bookmark_saved.connect(func(s): result[0] = s)

	bookmarks.save(3, _make_state())

	assert_int(result[0]).is_equal(3)


func test_recall_emits_signal() -> void:
	var bookmarks := CameraBookmarksScript.new()
	bookmarks.save(2, _make_state())
	var result := [-1]  # Use array to capture in lambda
	bookmarks.bookmark_recalled.connect(func(s): result[0] = s)

	bookmarks.recall(2)

	assert_int(result[0]).is_equal(2)


func test_invalid_slot_is_rejected() -> void:
	var bookmarks := CameraBookmarksScript.new()

	bookmarks.save(-1, _make_state())
	bookmarks.save(9, _make_state())
	bookmarks.save(100, _make_state())

	assert_int(bookmarks.get_count()).is_equal(0)


func test_state_is_copied_not_referenced() -> void:
	var bookmarks := CameraBookmarksScript.new()
	var state := _make_state(Vector3(1, 2, 3))

	bookmarks.save(0, state)
	state.target = Vector3(99, 99, 99)  # Modify original

	var recalled := bookmarks.recall(0)
	assert_vector(recalled.target).is_equal(Vector3(1, 2, 3))  # Should be unchanged
