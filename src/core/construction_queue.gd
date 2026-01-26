class_name ConstructionQueue
extends Node
## Manages block construction jobs
## Blocks take time to build - placement creates a job, not instant block
## Listens to GameState.time_changed to progress construction

signal construction_started(pos: Vector3i, block_type: String, total_hours: int)
signal construction_progress(pos: Vector3i, hours_remaining: int, total_hours: int)
signal construction_completed(pos: Vector3i, block_type: String)
signal construction_cancelled(pos: Vector3i, block_type: String)

# Reference to grid (set during setup)
var grid: Grid

# Active construction jobs: Vector3i -> ConstructionJob
var _jobs: Dictionary = {}

# Default construction time if not specified in block data
const DEFAULT_CONSTRUCTION_HOURS: int = 2

# Global multiplier for construction time (can be set in balance.json)
var construction_time_multiplier: float = 1.0

# Instant construction mode (for debugging or game settings)
var instant_construction: bool = false


class ConstructionJob:
	var position: Vector3i
	var block_type: String
	var hours_remaining: int
	var total_hours: int
	var started_at: Dictionary  # {year, month, day, hour}

	func _init(p_pos: Vector3i, p_type: String, p_hours: int, p_start_time: Dictionary) -> void:
		position = p_pos
		block_type = p_type
		hours_remaining = p_hours
		total_hours = p_hours
		started_at = p_start_time

	func get_progress() -> float:
		if total_hours <= 0:
			return 1.0
		return 1.0 - (float(hours_remaining) / float(total_hours))


func _ready() -> void:
	# Connect to GameState time signal
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.time_changed.connect(_on_time_changed)


## Setup with grid reference
func setup(p_grid: Grid) -> void:
	grid = p_grid


## Start construction of a block at position
## Returns true if construction started, false if position occupied or invalid
func start_construction(pos: Vector3i, block_type: String) -> bool:
	# Check if position already has a block or active construction
	if grid and grid.has_block(pos):
		return false
	if _jobs.has(pos):
		return false

	# Get construction time from BlockRegistry
	var hours := _get_construction_hours(block_type)

	# Apply global multiplier
	hours = int(ceil(hours * construction_time_multiplier))
	hours = maxi(1, hours)  # At least 1 hour

	# Get current time for tracking
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	var start_time := {}
	if game_state:
		start_time = game_state.get_time()

	# Handle instant construction mode
	if instant_construction or hours == 0:
		_complete_construction(pos, block_type)
		return true

	# Create construction job
	var job := ConstructionJob.new(pos, block_type, hours, start_time)
	_jobs[pos] = job

	construction_started.emit(pos, block_type, hours)
	return true


## Cancel construction at position
## Returns true if cancelled, false if no construction at position
func cancel_construction(pos: Vector3i) -> bool:
	if not _jobs.has(pos):
		return false

	var job: ConstructionJob = _jobs[pos]
	_jobs.erase(pos)

	construction_cancelled.emit(pos, job.block_type)
	return true


## Check if position has active construction
func has_construction(pos: Vector3i) -> bool:
	return _jobs.has(pos)


## Get construction job at position (or null)
func get_job(pos: Vector3i) -> ConstructionJob:
	return _jobs.get(pos)


## Get all active construction positions
func get_all_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	for pos in _jobs.keys():
		positions.append(pos)
	return positions


## Get job count
func get_job_count() -> int:
	return _jobs.size()


## Get construction hours for a block type
func _get_construction_hours(block_type: String) -> int:
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry:
		var block_data: Dictionary = registry.get_block_data(block_type)
		return block_data.get("construction_time_hours", DEFAULT_CONSTRUCTION_HOURS)
	return DEFAULT_CONSTRUCTION_HOURS


## Called every game hour - progress all construction jobs
func _on_time_changed(_year: int, _month: int, _day: int, _hour: int) -> void:
	var completed_positions: Array[Vector3i] = []

	# Progress all jobs
	for pos in _jobs.keys():
		var job: ConstructionJob = _jobs[pos]
		job.hours_remaining -= 1

		if job.hours_remaining <= 0:
			completed_positions.append(pos)
		else:
			construction_progress.emit(pos, job.hours_remaining, job.total_hours)

	# Complete finished jobs (separate loop to avoid modifying dict during iteration)
	for pos in completed_positions:
		var job: ConstructionJob = _jobs[pos]
		_jobs.erase(pos)
		_complete_construction(pos, job.block_type)


## Finalize construction - create the actual block
func _complete_construction(pos: Vector3i, block_type: String) -> void:
	if grid:
		var block := Block.new(block_type, pos)
		grid.set_block(pos, block)

	construction_completed.emit(pos, block_type)


## Set instant construction mode
func set_instant_construction(enabled: bool) -> void:
	instant_construction = enabled


## Clear all construction jobs (for game reset)
func clear_all() -> void:
	for pos in _jobs.keys():
		var job: ConstructionJob = _jobs[pos]
		construction_cancelled.emit(pos, job.block_type)
	_jobs.clear()
