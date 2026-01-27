extends Node3D

## Main script for 3D spike scene
## Wires together camera, spawner, and placer

@onready var camera: Camera3D = $Camera3D
@onready var spawner: Node3D = $BlockSpawner
@onready var placer: Node3D = $BlockPlacer

# Block type selection (1-6 keys)
const BLOCK_TYPES: Array[String] = [
	"corridor",
	"residential_basic",
	"commercial_basic",
	"entrance",
	"stairs",
	"elevator_shaft"
]


func _ready() -> void:
	# Wire up placer with camera and spawner
	if placer:
		placer.camera = camera
		placer.spawner = spawner

		# Connect signals for debugging
		placer.block_placed.connect(_on_block_placed)
		placer.block_removed.connect(_on_block_removed)


func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1-6 to select block type
	if event is InputEventKey and event.pressed:
		var idx := -1
		match event.keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
			KEY_5: idx = 4
			KEY_6: idx = 5

		if idx >= 0 and idx < BLOCK_TYPES.size():
			var block_type: String = BLOCK_TYPES[idx]
			placer.set_selected_block_type(block_type)
			print("Selected: ", block_type)


func _on_block_placed(position: Vector3i, block_type: String) -> void:
	print("Placed ", block_type, " at ", position)


func _on_block_removed(position: Vector3i) -> void:
	print("Removed block at ", position)
