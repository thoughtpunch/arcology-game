extends Node
## Singleton that loads and provides block definitions from JSON
## Register as AutoLoad: Project Settings > AutoLoad > BlockRegistry

const BLOCKS_PATH := "res://data/blocks.json"

var _blocks: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	_load_blocks()


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
