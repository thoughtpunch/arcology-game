## BlockAnimation - Tween-based animations for block placement and removal.
## Extracted from sandbox_main.gd to reduce file size.
class_name BlockAnimation
extends RefCounted

const CELL_SIZE: float = 6.0


## Animate a block being placed (drop-in with scale bounce and emission flash).
## Must be called from a Node context to create tweens.
static func animate_placement(block_node: Node3D, parent: Node, audio_player: AudioStreamPlayer = null) -> void:
	# Drop-in: start scaled to 0 and offset up, tween to final position
	var final_pos := block_node.position
	block_node.position = final_pos + Vector3(0, CELL_SIZE * 2.0, 0)
	block_node.scale = Vector3(0.01, 0.01, 0.01)

	var tween := parent.create_tween().set_parallel(true)
	(
		tween
		. tween_property(
			block_node,
			"scale",
			Vector3.ONE,
			0.15,
		)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	(
		tween
		. tween_property(
			block_node,
			"position",
			final_pos,
			0.15,
		)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_QUAD)
	)

	# Emission flash on the mesh material
	var mesh_inst: MeshInstance3D = block_node.get_child(0) if block_node.get_child_count() > 0 else null
	if mesh_inst and mesh_inst is MeshInstance3D and mesh_inst.material_override:
		var mat: StandardMaterial3D = mesh_inst.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.5
			var flash_tween := parent.create_tween()
			(
				flash_tween
				. tween_property(
					mat,
					"emission_energy_multiplier",
					0.0,
					0.2,
				)
			)

	# Flash panel materials too
	var panels: Node3D = block_node.get_node_or_null("Panels")
	if panels:
		for child in panels.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var pmat: StandardMaterial3D = child.material_override
				pmat.emission_energy_multiplier = 0.5
				var ptween := parent.create_tween()
				ptween.tween_property(pmat, "emission_energy_multiplier", 0.0, 0.2)

	# Play audio
	if audio_player and audio_player.stream:
		audio_player.play()


## Animate a block being removed (shrink and drop, then queue_free).
## Must be called from a Node context to create tweens.
static func animate_removal(block_node: Node3D, parent: Node) -> void:
	# Disable collision immediately so raycasts don't hit it
	for child in block_node.get_children():
		if child is StaticBody3D:
			child.collision_layer = 0

	# Shrink and drop slightly before freeing
	var tween := parent.create_tween().set_parallel(true)
	(
		tween
		. tween_property(
			block_node,
			"scale",
			Vector3.ZERO,
			0.15,
		)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_BACK)
	)
	(
		tween
		. tween_property(
			block_node,
			"position",
			block_node.position + Vector3(0, -CELL_SIZE, 0),
			0.15,
		)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_QUAD)
	)
	tween.chain().tween_callback(block_node.queue_free)
