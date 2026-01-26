class_name Block
extends RefCounted
## Lightweight data holder for a placed block
## Static properties (cost, size, traversability) come from BlockRegistry

signal property_changed(property_name: String)

var grid_position: Vector3i:
	set(value):
		if grid_position != value:
			grid_position = value
			property_changed.emit("grid_position")

var block_type: String:
	set(value):
		if block_type != value:
			block_type = value
			property_changed.emit("block_type")

var connected: bool = false:
	set(value):
		if connected != value:
			connected = value
			property_changed.emit("connected")

# Reference to sprite node (set by renderer, not owned by Block)
var sprite: Sprite2D


func _init(type: String = "", pos: Vector3i = Vector3i.ZERO) -> void:
	block_type = type
	grid_position = pos


## Get full block definition from BlockRegistry
## Returns empty dictionary if BlockRegistry unavailable or type unknown
func get_definition() -> Dictionary:
	# BlockRegistry is autoloaded - check if it exists in the tree
	var registry = Engine.get_main_loop()
	if registry and registry.has_node("/root/BlockRegistry"):
		var block_registry = registry.get_node("/root/BlockRegistry")
		if block_registry.has_method("get_block_data"):
			return block_registry.get_block_data(block_type)
	return {}


## Get traversability ("public" or "private")
## Public blocks can be walked through; private blocks are destinations only
func get_traversability() -> String:
	var def := get_definition()
	return def.get("traversability", "private")


## Check if this block allows through-traffic
func is_public() -> bool:
	return get_traversability() == "public"


## Get sprite resource path
func get_sprite_path() -> String:
	var def := get_definition()
	return def.get("sprite", "")


## Get block category (transit, residential, commercial, etc.)
func get_category() -> String:
	var def := get_definition()
	return def.get("category", "")


## Check if block connects horizontally to neighbors
func connects_horizontal() -> bool:
	var def := get_definition()
	return def.get("connects_horizontal", false)


## Check if block connects vertically (stairs, elevators)
func connects_vertical() -> bool:
	var def := get_definition()
	return def.get("connects_vertical", false)


## Get display name
func get_display_name() -> String:
	var def := get_definition()
	return def.get("name", block_type)


## String representation for debugging
func _to_string() -> String:
	return "Block(%s @ %s, connected=%s)" % [block_type, grid_position, connected]
