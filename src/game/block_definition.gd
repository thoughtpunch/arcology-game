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
@export var panel_material: int = -1  # -1 = use category default (PanelMaterial.Type)

## Optional path to external 3D model scene (e.g., "res://assets/models/blocks/corridor.glb").
## If empty, the block uses procedural BoxMesh geometry (current default).
## When set, the model scene should have origin at bottom-center, scaled to cell units.
@export var model_scene: String = ""
