extends SceneTree
## Test: Construction Queue System
## Tests that block placement creates construction jobs that complete over time
##
## Run with:
## godot --headless --path . --script test/core/test_construction_queue.gd

var _tests_passed: int = 0
var _tests_failed: int = 0

var grid: Grid
var construction_queue  # Instance of ConstructionQueue

# Signal tracking
var _started_signals: Array = []
var _progress_signals: Array = []
var _completed_signals: Array = []
var _cancelled_signals: Array = []


func _init() -> void:
	print("=== Test: Construction Queue System ===")
	print("")

	# Wait for autoloads
	await process_frame

	_setup()

	# Core functionality tests
	print("## Core Functionality")
	_test_start_construction_creates_job()
	_test_job_has_correct_hours()
	_test_construction_progress_on_time_tick()
	_test_construction_completes_after_hours()
	_test_completed_block_added_to_grid()

	# Edge cases
	print("")
	print("## Edge Cases")
	_test_cannot_construct_on_occupied_position()
	_test_cannot_construct_on_active_construction()
	_test_cancel_construction()
	_test_instant_construction_mode()

	# Signal tests
	print("")
	print("## Signal Tests")
	_test_started_signal_emitted()
	_test_progress_signal_emitted()
	_test_completed_signal_emitted()

	# Data-driven tests
	print("")
	print("## Data-Driven Tests")
	_test_construction_time_from_block_data()
	_test_construction_time_multiplier()

	_cleanup()

	# Summary
	print("")
	print("=== Results ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)


func _setup() -> void:
	grid = Grid.new()
	get_root().add_child(grid)

	var CQScript = load("res://src/core/construction_queue.gd")
	construction_queue = CQScript.new()
	get_root().add_child(construction_queue)
	construction_queue.setup(grid)

	# Connect to signals for tracking
	construction_queue.construction_started.connect(_on_started)
	construction_queue.construction_progress.connect(_on_progress)
	construction_queue.construction_completed.connect(_on_completed)
	construction_queue.construction_cancelled.connect(_on_cancelled)


func _cleanup() -> void:
	construction_queue.queue_free()
	grid.queue_free()


func _reset() -> void:
	grid.clear()
	construction_queue.clear_all()
	_started_signals.clear()
	_progress_signals.clear()
	_completed_signals.clear()
	_cancelled_signals.clear()
	construction_queue.instant_construction = false
	construction_queue.construction_time_multiplier = 1.0


func _on_started(pos: Vector3i, block_type: String, total_hours: int) -> void:
	_started_signals.append({"pos": pos, "type": block_type, "hours": total_hours})


func _on_progress(pos: Vector3i, hours_remaining: int, total_hours: int) -> void:
	_progress_signals.append({"pos": pos, "remaining": hours_remaining, "total": total_hours})


func _on_completed(pos: Vector3i, block_type: String) -> void:
	_completed_signals.append({"pos": pos, "type": block_type})


func _on_cancelled(pos: Vector3i, block_type: String) -> void:
	_cancelled_signals.append({"pos": pos, "type": block_type})


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, reason: String = "") -> void:
	if reason.is_empty():
		print("  FAIL: %s" % test_name)
	else:
		print("  FAIL: %s - %s" % [test_name, reason])
	_tests_failed += 1


# =============================================================================
# Core Functionality Tests
# =============================================================================

## Test: Starting construction creates a job
func _test_start_construction_creates_job() -> void:
	_reset()
	var pos := Vector3i(5, 5, 0)

	var success: bool = construction_queue.start_construction(pos, "corridor")

	if success and construction_queue.has_construction(pos):
		_pass("Starting construction creates a job")
	else:
		_fail("Starting construction creates a job", "Job not created")


## Test: Job has correct hours from block data
func _test_job_has_correct_hours() -> void:
	_reset()
	var pos := Vector3i(3, 3, 0)

	construction_queue.start_construction(pos, "corridor")
	var job = construction_queue.get_job(pos)

	# Corridor has construction_time_hours: 1
	if job and job.total_hours == 1:
		_pass("Job has correct hours from block data")
	else:
		var hours = job.total_hours if job else -1
		_fail("Job has correct hours from block data", "Expected 1, got %d" % hours)


## Test: Construction progresses on time tick
func _test_construction_progress_on_time_tick() -> void:
	_reset()
	var pos := Vector3i(4, 4, 0)

	# Start construction with 2 hours (use stairs)
	construction_queue.start_construction(pos, "stairs")
	var job = construction_queue.get_job(pos)
	var initial_hours: int = job.hours_remaining

	# Simulate time tick
	construction_queue._on_time_changed(1, 1, 1, 9)

	if job.hours_remaining == initial_hours - 1:
		_pass("Construction progresses on time tick")
	else:
		_fail("Construction progresses on time tick",
			"Expected %d, got %d" % [initial_hours - 1, job.hours_remaining])


## Test: Construction completes after required hours
func _test_construction_completes_after_hours() -> void:
	_reset()
	var pos := Vector3i(2, 2, 0)

	# Start construction with 1 hour (corridor)
	construction_queue.start_construction(pos, "corridor")

	# Simulate 1 hour passing
	construction_queue._on_time_changed(1, 1, 1, 9)

	# Job should be gone (completed)
	if not construction_queue.has_construction(pos):
		_pass("Construction completes after required hours")
	else:
		_fail("Construction completes after required hours", "Job still active")


## Test: Completed construction adds block to grid
func _test_completed_block_added_to_grid() -> void:
	_reset()
	var pos := Vector3i(1, 1, 0)

	# Start and complete construction
	construction_queue.start_construction(pos, "corridor")
	construction_queue._on_time_changed(1, 1, 1, 9)  # Complete it

	if grid.has_block(pos):
		var block = grid.get_block(pos)
		if block.block_type == "corridor":
			_pass("Completed construction adds block to grid")
		else:
			_fail("Completed construction adds block to grid", "Wrong block type")
	else:
		_fail("Completed construction adds block to grid", "No block in grid")


# =============================================================================
# Edge Cases
# =============================================================================

## Test: Cannot start construction on occupied position
func _test_cannot_construct_on_occupied_position() -> void:
	_reset()
	var pos := Vector3i(6, 6, 0)

	# Place existing block
	var block := Block.new("corridor", pos)
	grid.set_block(pos, block)

	# Try to start construction
	var success: bool = construction_queue.start_construction(pos, "residential_basic")

	if not success:
		_pass("Cannot start construction on occupied position")
	else:
		_fail("Cannot start construction on occupied position", "Construction started")


## Test: Cannot start construction where already constructing
func _test_cannot_construct_on_active_construction() -> void:
	_reset()
	var pos := Vector3i(7, 7, 0)

	# Start first construction
	construction_queue.start_construction(pos, "stairs")

	# Try to start second construction at same position
	var success: bool = construction_queue.start_construction(pos, "corridor")

	if not success:
		_pass("Cannot start construction where already constructing")
	else:
		_fail("Cannot start construction where already constructing", "Second construction started")


## Test: Cancel construction removes job
func _test_cancel_construction() -> void:
	_reset()
	var pos := Vector3i(8, 8, 0)

	construction_queue.start_construction(pos, "residential_basic")
	var cancelled: bool = construction_queue.cancel_construction(pos)

	if cancelled and not construction_queue.has_construction(pos):
		_pass("Cancel construction removes job")
	else:
		_fail("Cancel construction removes job", "Job still exists or cancel failed")


## Test: Instant construction mode completes immediately
func _test_instant_construction_mode() -> void:
	_reset()
	var pos := Vector3i(9, 9, 0)

	construction_queue.set_instant_construction(true)
	construction_queue.start_construction(pos, "residential_basic")

	# Block should be immediately in grid, no job
	if grid.has_block(pos) and not construction_queue.has_construction(pos):
		_pass("Instant construction mode completes immediately")
	else:
		_fail("Instant construction mode completes immediately",
			"Block: %s, Job: %s" % [grid.has_block(pos), construction_queue.has_construction(pos)])


# =============================================================================
# Signal Tests
# =============================================================================

## Test: construction_started signal emitted
func _test_started_signal_emitted() -> void:
	_reset()
	var pos := Vector3i(10, 10, 0)

	construction_queue.start_construction(pos, "corridor")

	if _started_signals.size() > 0 and _started_signals[0].pos == pos:
		_pass("construction_started signal emitted")
	else:
		_fail("construction_started signal emitted", "No signal received")


## Test: construction_progress signal emitted on tick
func _test_progress_signal_emitted() -> void:
	_reset()
	var pos := Vector3i(11, 11, 0)

	# Use stairs (2 hours) so progress signal fires before completion
	construction_queue.start_construction(pos, "stairs")
	construction_queue._on_time_changed(1, 1, 1, 9)

	if _progress_signals.size() > 0 and _progress_signals[0].pos == pos:
		_pass("construction_progress signal emitted on tick")
	else:
		_fail("construction_progress signal emitted on tick", "No signal received")


## Test: construction_completed signal emitted
func _test_completed_signal_emitted() -> void:
	_reset()
	var pos := Vector3i(12, 12, 0)

	construction_queue.start_construction(pos, "corridor")
	construction_queue._on_time_changed(1, 1, 1, 9)  # Complete it

	if _completed_signals.size() > 0 and _completed_signals[0].pos == pos:
		_pass("construction_completed signal emitted")
	else:
		_fail("construction_completed signal emitted", "No signal received")


# =============================================================================
# Data-Driven Tests
# =============================================================================

## Test: Construction time comes from block data
func _test_construction_time_from_block_data() -> void:
	_reset()

	# Test different block types have different construction times
	var pos1 := Vector3i(13, 13, 0)
	var pos2 := Vector3i(14, 14, 0)

	construction_queue.start_construction(pos1, "corridor")  # 1 hour
	construction_queue.start_construction(pos2, "residential_basic")  # 8 hours

	var job1 = construction_queue.get_job(pos1)
	var job2 = construction_queue.get_job(pos2)

	if job1.total_hours == 1 and job2.total_hours == 8:
		_pass("Construction time comes from block data")
	else:
		_fail("Construction time comes from block data",
			"corridor=%d (expected 1), residential=%d (expected 8)" % [job1.total_hours, job2.total_hours])


## Test: Construction time multiplier affects duration
func _test_construction_time_multiplier() -> void:
	_reset()
	var pos := Vector3i(15, 15, 0)

	construction_queue.construction_time_multiplier = 2.0
	construction_queue.start_construction(pos, "corridor")  # 1 hour * 2 = 2 hours

	var job = construction_queue.get_job(pos)

	if job.total_hours == 2:
		_pass("Construction time multiplier affects duration")
	else:
		_fail("Construction time multiplier affects duration",
			"Expected 2, got %d" % job.total_hours)
