extends Node
## Singleton that loads and provides block definitions from JSON
## Register as AutoLoad: Project Settings > AutoLoad > BlockRegistry

const BLOCKS_PATH := "res://data/blocks.json"

# Default unlocked blocks (always available)
const DEFAULT_UNLOCKED := ["entrance", "corridor", "residential_basic", "stairs"]

var _blocks: Dictionary = {}
var _loaded: bool = false
var _unlocked_blocks: Array[String] = []
var _all_unlocked: bool = false


func _ready() -> void:
	_load_blocks()
	_reset_unlocked()


## Load block definitions from JSON file
func _load_blocks() -> void:
	if not FileAccess.file_exists(BLOCKS_PATH):
		push_error("BlockRegistry: blocks.json not found at %s" % BLOCKS_PATH)
		return

	var file := FileAccess.open(BLOCKS_PATH, FileAccess.READ)
	if file == null:
		push_error("BlockRegistry: Failed to open %s" % BLOCKS_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("BlockRegistry: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data = json.get_data()
	if not data is Dictionary:
		push_error("BlockRegistry: blocks.json must be a dictionary")
		return

	_blocks = data
	_loaded = true
	print("BlockRegistry: Loaded %d block types" % _blocks.size())


## Get block definition by type ID
## Returns empty dictionary if type not found
func get_block_data(type_id: String) -> Dictionary:
	if not _loaded:
		return {}
	return _blocks.get(type_id, {})


## Get all available block type IDs
func get_all_types() -> Array[String]:
	if not _loaded:
		return []
	var types: Array[String] = []
	for key in _blocks.keys():
		types.append(key)
	return types


## Check if a block type exists
func has_type(type_id: String) -> bool:
	return _blocks.has(type_id)


## Get block types filtered by category
func get_types_by_category(category: String) -> Array[String]:
	var types: Array[String] = []
	for type_id in _blocks:
		var block_data: Dictionary = _blocks[type_id]
		if block_data.get("category", "") == category:
			types.append(type_id)
	return types


## Get block cost
func get_cost(type_id: String) -> int:
	var data := get_block_data(type_id)
	return data.get("cost", 0)


## Get block traversability ("public" or "private")
func get_traversability(type_id: String) -> String:
	var data := get_block_data(type_id)
	return data.get("traversability", "private")


## Check if block type is public (allows through-traffic)
func is_public(type_id: String) -> bool:
	return get_traversability(type_id) == "public"


## Check if block type connects horizontally
func connects_horizontal(type_id: String) -> bool:
	var data := get_block_data(type_id)
	return data.get("connects_horizontal", false)


## Check if block type connects vertically (stairs, elevators)
func connects_vertical(type_id: String) -> bool:
	var data := get_block_data(type_id)
	return data.get("connects_vertical", false)


## Check if block type can only be placed at ground level
func is_ground_only(type_id: String) -> bool:
	var data := get_block_data(type_id)
	return data.get("ground_only", false)


## Reload blocks from JSON (for hot-reloading during development)
func reload() -> void:
	_blocks.clear()
	_loaded = false
	_load_blocks()


# --- Block Unlocking System ---

## Reset unlocked blocks to default
func _reset_unlocked() -> void:
	_unlocked_blocks.clear()
	for block_type in DEFAULT_UNLOCKED:
		_unlocked_blocks.append(block_type)
	_all_unlocked = false


## Check if a block type is unlocked (available for building)
func is_unlocked(type_id: String) -> bool:
	if _all_unlocked:
		return true
	return type_id in _unlocked_blocks


## Unlock a specific block type
func unlock_block(type_id: String) -> void:
	if has_type(type_id) and type_id not in _unlocked_blocks:
		_unlocked_blocks.append(type_id)


## Lock a specific block type (remove from unlocked list)
func lock_block(type_id: String) -> void:
	var index := _unlocked_blocks.find(type_id)
	if index >= 0:
		_unlocked_blocks.remove_at(index)


## Unlock all block types (sandbox mode)
func unlock_all() -> void:
	_all_unlocked = true


## Lock all blocks except defaults (reset to normal gameplay)
func lock_all_to_defaults() -> void:
	_all_unlocked = false
	_reset_unlocked()


## Get all unlocked block type IDs
func get_unlocked_types() -> Array[String]:
	if _all_unlocked:
		return get_all_types()
	return _unlocked_blocks.duplicate()


## Get unlocked types filtered by category
func get_unlocked_types_by_category(category: String) -> Array[String]:
	var types: Array[String] = []
	for type_id in _blocks:
		if not is_unlocked(type_id):
			continue
		var block_data: Dictionary = _blocks[type_id]
		if block_data.get("category", "") == category:
			types.append(type_id)
	return types


## Check if all blocks are unlocked (sandbox mode)
func is_all_unlocked() -> bool:
	return _all_unlocked
