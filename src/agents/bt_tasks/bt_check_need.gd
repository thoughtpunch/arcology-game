@tool
class_name BTCheckNeed
extends BTCondition
## LimboAI condition task: Check if a need is below threshold
## Used in behavior trees to drive need-based decision making

## The need to check (survival, safety, belonging, esteem, purpose)
@export var need_name: String = "survival"

## Threshold below which the need is considered "unmet"
@export_range(0, 100) var threshold: float = 50.0

## If true, check if need is ABOVE threshold instead of below
@export var check_above: bool = false


func _generate_name() -> String:
	if check_above:
		return "CheckNeed: %s > %.0f" % [need_name, threshold]
	return "CheckNeed: %s < %.0f" % [need_name, threshold]


func _tick(_delta: float) -> Status:
	var resident: Resident = _get_resident()
	if not resident:
		return FAILURE

	var need_value: float = resident.get_need(need_name)

	if check_above:
		if need_value > threshold:
			return SUCCESS
		return FAILURE
	if need_value < threshold:
		return SUCCESS
	return FAILURE


func _get_resident() -> Resident:
	## Get the resident from the agent or blackboard
	var agent = get_agent()
	if agent is Resident:
		return agent

	# Try to get from blackboard
	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var("resident"):
		return bb.get_var("resident")

	return null
