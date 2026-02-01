extends Resource

@export var id: String
@export var display_name: String
@export var size: Vector3i
@export var color: Color
@export var category: String = ""
@export var traversability: String = ""
@export var ground_only: bool = false
@export var connects_horizontal: bool = false
@export var connects_vertical: bool = false
@export var capacity: int = 0
@export var jobs: int = 0
@export var cost: int = 0
