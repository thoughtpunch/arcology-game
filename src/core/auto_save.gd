class_name AutoSave
extends Node
## Auto-save system for periodic game state persistence
## Saves every configurable interval, keeps last N auto-saves
## See: documentation/ui/menus.md

# Constants
const SAVE_DIR := "user://saves/"
const AUTO_SAVE_PREFIX := "autosave_"
const DEFAULT_INTERVAL_MINUTES := 10
const MAX_AUTO_SAVES := 3

# Signals
signal auto_save_started
signal auto_save_completed(save_path: String)
signal auto_save_failed(error: String)

# State
var _enabled := true
var _interval_minutes := DEFAULT_INTERVAL_MINUTES
var _timer: Timer
var _last_save_time := 0.0
var _save_in_progress := false
var _save_number := 0


func _ready() -> void:
	_setup_timer()
	_ensure_save_directory()
	_load_save_number()


func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = _interval_minutes * 60.0
	_timer.one_shot = false
	_timer.autostart = _enabled
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func _load_save_number() -> void:
	# Find highest existing auto-save number
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with(AUTO_SAVE_PREFIX) and file_name.ends_with(".save"):
			var num_str := file_name.replace(AUTO_SAVE_PREFIX, "").replace(".save", "")
			if num_str.is_valid_int():
				var num := int(num_str)
				if num >= _save_number:
					_save_number = num + 1
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_timer_timeout() -> void:
	if _enabled and not _save_in_progress:
		trigger_auto_save()


## Trigger an auto-save now
func trigger_auto_save() -> void:
	if _save_in_progress:
		return

	_save_in_progress = true
	auto_save_started.emit()

	# Generate save path
	var save_path := _get_next_save_path()

	# Get game state from GameState autoload
	var game_state = _get_game_state()
	if not game_state:
		_save_in_progress = false
		auto_save_failed.emit("GameState not available")
		return

	# Build save data
	var save_data := _build_save_data(game_state)

	# Write to file
	var success := _write_save_file(save_path, save_data)

	if success:
		_last_save_time = Time.get_unix_time_from_system()
		_save_number += 1
		_cleanup_old_auto_saves()
		auto_save_completed.emit(save_path)
	else:
		auto_save_failed.emit("Failed to write save file")

	_save_in_progress = false


func _get_next_save_path() -> String:
	return SAVE_DIR + AUTO_SAVE_PREFIX + str(_save_number) + ".save"


func _get_game_state() -> Object:
	var tree := get_tree()
	if not tree:
		return null
	return tree.get_root().get_node_or_null("/root/GameState")


func _build_save_data(game_state: Object) -> Dictionary:
	var now := Time.get_datetime_dict_from_system()
	var date_str := "%04d-%02d-%02d %02d:%02d" % [
		now.year, now.month, now.day, now.hour, now.minute
	]

	var data := {
		"name": "Auto-save",
		"date": date_str,
		"timestamp": Time.get_unix_time_from_system(),
		"is_auto": true,
		"population": 0,
		"money": 100000,
		"aei": 0,
		"scenario": "fresh_start",
		"playtime": "0h 0m"
	}

	# Get data from game state if available
	if game_state.has_method("get_current_floor"):
		data["current_floor"] = game_state.get_current_floor()

	# Get grid data if available
	var grid := _get_grid()
	if grid:
		data["blocks"] = _serialize_blocks(grid)

	return data


func _get_grid() -> Object:
	var tree := get_tree()
	if not tree:
		return null
	var main := tree.get_root().get_node_or_null("/root/Main")
	if main and main.has_method("get") and "grid" in main:
		return main.grid
	return null


func _serialize_blocks(grid: Object) -> Array:
	var blocks := []
	if not grid.has_method("get_all_blocks"):
		return blocks

	for pos in grid.get_all_blocks():
		var block = grid.get_block_at(pos)
		if block:
			blocks.append({
				"type": block.block_type if "block_type" in block else "unknown",
				"position": [pos.x, pos.y, pos.z]
			})
	return blocks


func _write_save_file(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _cleanup_old_auto_saves() -> void:
	var auto_saves := _get_auto_saves()

	# Sort by timestamp (newest first)
	auto_saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	# Delete old ones beyond MAX_AUTO_SAVES
	for i in range(MAX_AUTO_SAVES, auto_saves.size()):
		var path: String = auto_saves[i].path
		DirAccess.remove_absolute(path)


func _get_auto_saves() -> Array:
	var saves := []
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with(AUTO_SAVE_PREFIX) and file_name.ends_with(".save"):
			var path := SAVE_DIR + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json := JSON.new()
				var error := json.parse(file.get_as_text())
				file.close()
				if error == OK:
					var data: Dictionary = json.get_data()
					data["path"] = path
					saves.append(data)
		file_name = dir.get_next()
	dir.list_dir_end()

	return saves


## Set auto-save enabled state
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _timer:
		if enabled:
			_timer.start()
		else:
			_timer.stop()


## Check if auto-save is enabled
func is_enabled() -> bool:
	return _enabled


## Set auto-save interval in minutes
func set_interval(minutes: int) -> void:
	_interval_minutes = maxi(1, minutes)
	if _timer:
		_timer.wait_time = _interval_minutes * 60.0


## Get auto-save interval in minutes
func get_interval() -> int:
	return _interval_minutes


## Get time until next auto-save in seconds
func get_time_until_next() -> float:
	if not _timer or not _enabled:
		return -1.0
	return _timer.time_left


## Get last save time as Unix timestamp
func get_last_save_time() -> float:
	return _last_save_time


## Check if save is in progress
func is_saving() -> bool:
	return _save_in_progress


## Force an immediate save (bypasses timer check)
func force_save() -> void:
	if not _save_in_progress:
		trigger_auto_save()
