@tool
class_name BTTravelTo
extends BTAction
## LimboAI action task: Travel to a destination
## Starts pathfinding to target and returns RUNNING until arrival

## Blackboard variable containing the target position (Vector3i)
@export var target_var: StringName = &"target_block"

## Optional: specific position to travel to (overrides target_var if set)
@export var fixed_destination: Vector3i = Vector3i(-1, -1, -1)

## Travel speed (grid units per second)
@export var speed: float = 2.0


func _generate_name() -> String:
	if fixed_destination.x >= 0:
		return (
			"TravelTo: (%d,%d,%d)" % [fixed_destination.x, fixed_destination.y, fixed_destination.z]
		)
	return "TravelTo: $%s" % target_var


func _enter() -> void:
	var resident: Resident = _get_resident()
	if not resident:
		return

	var destination := _get_destination()
	if destination.x >= 0:
		resident.move_to(destination)


func _tick(delta: float) -> Status:
	var resident: Resident = _get_resident()
	if not resident:
		return FAILURE

	var destination := _get_destination()
	if destination.x < 0:
		return FAILURE

	# Check if already at destination
	if resident.current_position == destination:
		resident.arrive_at(destination)
		return SUCCESS

	# Simulate movement (in a real implementation, this would use pathfinding)
	var from_pos := resident.current_position
	var dir := Vector3i(
		signi(destination.x - from_pos.x),
		signi(destination.y - from_pos.y),
		signi(destination.z - from_pos.z)
	)

	# Move one step at a time (simplified - real implementation would track fractional progress)
	# For now, move at fixed intervals based on speed
	var steps := roundi(speed * delta)
	if steps < 1:
		steps = 1

	for i in range(steps):
		if resident.current_position == destination:
			break

		# Move towards destination
		var new_pos := resident.current_position
		if new_pos.x != destination.x:
			new_pos.x += signi(destination.x - new_pos.x)
		elif new_pos.y != destination.y:
			new_pos.y += signi(destination.y - new_pos.y)
		elif new_pos.z != destination.z:
			new_pos.z += signi(destination.z - new_pos.z)

		resident.current_position = new_pos

	# Check if arrived
	if resident.current_position == destination:
		resident.arrive_at(destination)
		return SUCCESS

	return RUNNING


func _get_destination() -> Vector3i:
	if fixed_destination.x >= 0:
		return fixed_destination

	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var(target_var):
		return bb.get_var(target_var)

	return Vector3i(-1, -1, -1)


func _get_resident() -> Resident:
	var agent = get_agent()
	if agent is Resident:
		return agent

	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var("resident"):
		return bb.get_var("resident")

	return null
