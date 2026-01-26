@tool
class_name BTUseBlock
extends BTAction
## LimboAI action task: Use/interact with the current block
## Applies need effects based on block type and duration

## Duration of the interaction in seconds (simulated time)
@export var duration: float = 1.0

## The need to satisfy (empty = auto-detect from block type)
@export var target_need: String = ""

## Amount of need satisfaction per use
@export var need_amount: float = 10.0

## Activity state while using the block
@export var activity_state: String = "idle"

var _elapsed: float = 0.0


func _generate_name() -> String:
	if target_need != "":
		return "UseBlock: %s +%.0f" % [target_need, need_amount]
	else:
		return "UseBlock: %.1fs" % duration


func _enter() -> void:
	_elapsed = 0.0
	var resident: Resident = _get_resident()
	if resident:
		_set_activity(resident)


func _tick(delta: float) -> Status:
	var resident: Resident = _get_resident()
	if not resident:
		return FAILURE

	_elapsed += delta

	if _elapsed >= duration:
		# Apply need satisfaction
		_apply_effects(resident)
		resident.set_activity(Resident.Activity.IDLE)
		resident.action_completed.emit("use_block")
		return SUCCESS

	return RUNNING


func _apply_effects(resident: Resident) -> void:
	var need_to_modify := target_need

	# If no specific need set, try to determine from context
	if need_to_modify == "":
		need_to_modify = _infer_need_from_activity()

	if need_to_modify != "":
		resident.modify_need(need_to_modify, need_amount)


func _infer_need_from_activity() -> String:
	## Map activity states to needs
	match activity_state:
		"eating": return "survival"
		"sleeping": return "survival"
		"working": return "purpose"
		"socializing": return "belonging"
		"recreating": return "esteem"
		_: return ""


func _set_activity(resident: Resident) -> void:
	match activity_state:
		"eating": resident.set_activity(Resident.Activity.EATING)
		"sleeping": resident.set_activity(Resident.Activity.SLEEPING)
		"working": resident.set_activity(Resident.Activity.WORKING)
		"socializing": resident.set_activity(Resident.Activity.SOCIALIZING)
		"recreating": resident.set_activity(Resident.Activity.RECREATING)
		_: resident.set_activity(Resident.Activity.IDLE)


func _get_resident() -> Resident:
	var agent = get_agent()
	if agent is Resident:
		return agent

	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var("resident"):
		return bb.get_var("resident")

	return null
