## Holds all block definitions for Phase 0 sandbox.

const BlockDefScript = preload("res://src/phase0/block_definition.gd")

var _definitions: Dictionary = {}


func _init() -> void:
	_register_all()


func _register_all() -> void:
	_register("cube", "Cube", Vector3i(1, 1, 1), Color(0.7, 0.7, 0.7), true)
	_register("beam_3", "Beam (3)", Vector3i(3, 1, 1), Color(0.5, 0.6, 0.7), false)
	_register("plate_2x2", "Plate (2x2)", Vector3i(2, 1, 2), Color(0.6, 0.7, 0.5), true)
	_register("wall_3x2", "Wall (3x2)", Vector3i(3, 2, 1), Color(0.7, 0.55, 0.55), false)
	_register("column", "Column", Vector3i(1, 2, 1), Color(0.55, 0.55, 0.7), true)
	_register("platform_4x4", "Platform (4x4)", Vector3i(4, 1, 4), Color(0.5, 0.65, 0.6), true)


func _register(
	id: String, display_name: String, size: Vector3i,
	color: Color, is_symmetric: bool,
) -> void:
	var def: Resource = BlockDefScript.new()
	def.id = id
	def.display_name = display_name
	def.size = size
	def.color = color
	def.is_symmetric = is_symmetric
	_definitions[id] = def


func get_definition(id: String) -> Resource:
	return _definitions.get(id)


func get_all_definitions() -> Array:
	var result: Array = []
	for def in _definitions.values():
		result.append(def)
	return result
