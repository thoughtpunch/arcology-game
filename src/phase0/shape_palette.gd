extends HBoxContainer

signal shape_selected(definition: Resource)

var registry: RefCounted
var _buttons: Dictionary = {}  # String (id) -> Button
var _current_id: String = "cube"


func _ready() -> void:
	if not registry:
		return
	_build_buttons()


func _build_buttons() -> void:
	var defs: Array = registry.get_all_definitions()
	var index := 0
	for def in defs:
		index += 1
		var button := Button.new()
		button.text = "%d: %s" % [index, def.display_name]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(90, 40)
		button.pressed.connect(_on_button_pressed.bind(def))
		add_child(button)
		_buttons[def.id] = button

	# Highlight default
	if _buttons.has(_current_id):
		_buttons[_current_id].button_pressed = true


func _on_button_pressed(definition: Resource) -> void:
	highlight_definition(definition)
	shape_selected.emit(definition)


func highlight_definition(definition: Resource) -> void:
	_current_id = definition.id
	for id in _buttons:
		_buttons[id].button_pressed = (id == _current_id)
