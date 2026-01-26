class_name Resident
extends Node2D
## A simulated resident with needs, personality, and AI-driven behavior
## Uses LimboAI behavior trees for decision making
## See: documentation/game-design/human-simulation/

signal needs_changed(need_name: String, old_value: float, new_value: float)
signal mood_changed(new_mood: String)
signal arrived_at_destination(destination: Vector3i)
signal action_completed(action_name: String)

# Constants for need thresholds
const NEED_MIN: float = 0.0
const NEED_MAX: float = 100.0
const CRITICAL_THRESHOLD: float = 20.0
const SATISFIED_THRESHOLD: float = 70.0

# Mood states
enum Mood { MISERABLE, UNHAPPY, STRESSED, CONTENT, HAPPY }

# Activity states
enum Activity { IDLE, TRAVELING, WORKING, EATING, SLEEPING, SOCIALIZING, RECREATING }


# === Identity ===
@export var resident_name: String = ""
@export var age: int = 30
@export var archetype: String = "young_professional"  # young_professional, family, retiree, artist, entrepreneur


# === Location ===
var home_block: Vector3i = Vector3i.ZERO
var workplace_block: Vector3i = Vector3i(-1, -1, -1)  # -1,-1,-1 = unemployed
var current_position: Vector3i = Vector3i.ZERO
var target_position: Vector3i = Vector3i.ZERO


# === Personality (Big Five, 0-100) ===
@export_range(0, 100) var openness: int = 50
@export_range(0, 100) var conscientiousness: int = 50
@export_range(0, 100) var extraversion: int = 50
@export_range(0, 100) var agreeableness: int = 50
@export_range(0, 100) var neuroticism: int = 50


# === Needs (0-100) ===
var _needs: Dictionary = {
	"survival": 80.0,
	"safety": 70.0,
	"belonging": 60.0,
	"esteem": 50.0,
	"purpose": 50.0
}


# === State ===
var _mood: Mood = Mood.CONTENT
var _activity: Activity = Activity.IDLE
var _residence_months: int = 0
var _flight_risk: float = 0.0


# === Behavior Tree Integration ===
# These will be accessed by behavior tree tasks via the Blackboard
var bt_player: Node  # BTPlayer reference (set externally)


func _ready() -> void:
	_calculate_flight_risk()


# === Need Management ===

func get_need(need_name: String) -> float:
	return _needs.get(need_name, 0.0)


func set_need(need_name: String, value: float) -> void:
	if not need_name in _needs:
		return

	var old_value: float = _needs[need_name]
	var new_value: float = clampf(value, NEED_MIN, NEED_MAX)

	if old_value != new_value:
		_needs[need_name] = new_value
		needs_changed.emit(need_name, old_value, new_value)
		_update_mood()


func modify_need(need_name: String, delta: float) -> void:
	set_need(need_name, get_need(need_name) + delta)


func get_lowest_need() -> String:
	var lowest_name: String = "survival"
	var lowest_value: float = 100.0

	for need_name in _needs:
		if _needs[need_name] < lowest_value:
			lowest_value = _needs[need_name]
			lowest_name = need_name

	return lowest_name


func get_critical_needs() -> Array[String]:
	var critical: Array[String] = []
	for need_name in _needs:
		if _needs[need_name] < CRITICAL_THRESHOLD:
			critical.append(need_name)
	return critical


func is_need_critical(need_name: String) -> bool:
	return get_need(need_name) < CRITICAL_THRESHOLD


func is_need_satisfied(need_name: String) -> bool:
	return get_need(need_name) >= SATISFIED_THRESHOLD


# === Mood ===

func get_mood() -> Mood:
	return _mood


func get_mood_string() -> String:
	match _mood:
		Mood.MISERABLE: return "miserable"
		Mood.UNHAPPY: return "unhappy"
		Mood.STRESSED: return "stressed"
		Mood.CONTENT: return "content"
		Mood.HAPPY: return "happy"
		_: return "content"


func _update_mood() -> void:
	var old_mood := _mood
	var flourishing := calculate_flourishing()

	if flourishing < 20:
		_mood = Mood.MISERABLE
	elif flourishing < 40:
		_mood = Mood.UNHAPPY
	elif flourishing < 55:
		_mood = Mood.STRESSED
	elif flourishing < 75:
		_mood = Mood.CONTENT
	else:
		_mood = Mood.HAPPY

	if old_mood != _mood:
		mood_changed.emit(get_mood_string())


# === Flourishing Calculation ===

func calculate_flourishing() -> float:
	## Hierarchical flourishing calculation per documentation
	## Lower needs gate higher ones

	var survival: float = _needs["survival"]
	var safety: float = _needs["safety"]
	var belonging: float = _needs["belonging"]
	var esteem: float = _needs["esteem"]
	var purpose: float = _needs["purpose"]

	# Survival gates everything
	if survival < 50:
		return survival * 0.3  # 0-15 range

	# Safety gates higher needs
	if safety < 40:
		return 30.0 + (safety - 40.0) * 0.5  # 15-30 range

	# Belonging gates higher needs
	if belonging < 30:
		return 50.0 + (belonging - 30.0) * 0.5  # 30-50 range

	# Esteem gates purpose
	if esteem < 30:
		return 60.0 + (esteem - 30.0) * 0.4  # 50-60 range

	# All base needs met - purpose drives flourishing
	var base: float = 70.0
	var purpose_bonus: float = (purpose - 50.0) * 0.6  # up to +30
	return minf(100.0, base + purpose_bonus)


# === Activity State ===

func get_activity() -> Activity:
	return _activity


func get_activity_string() -> String:
	match _activity:
		Activity.IDLE: return "idle"
		Activity.TRAVELING: return "traveling"
		Activity.WORKING: return "working"
		Activity.EATING: return "eating"
		Activity.SLEEPING: return "sleeping"
		Activity.SOCIALIZING: return "socializing"
		Activity.RECREATING: return "recreating"
		_: return "idle"


func set_activity(activity: Activity) -> void:
	_activity = activity


# === Movement ===

func is_at_home() -> bool:
	return current_position == home_block


func is_at_work() -> bool:
	return workplace_block.x >= 0 and current_position == workplace_block


func has_job() -> bool:
	return workplace_block.x >= 0


func move_to(destination: Vector3i) -> void:
	target_position = destination
	_activity = Activity.TRAVELING


func arrive_at(destination: Vector3i) -> void:
	current_position = destination
	if _activity == Activity.TRAVELING:
		_activity = Activity.IDLE
	arrived_at_destination.emit(destination)


# === Flight Risk ===

func get_flight_risk() -> float:
	return _flight_risk


func _calculate_flight_risk() -> void:
	## Calculate likelihood of resident moving out
	var risk := 0.0

	# Low flourishing increases risk
	var flourishing := calculate_flourishing()
	if flourishing < 40:
		risk += (40.0 - flourishing) * 1.5

	# Critical needs dramatically increase risk
	for need_name in _needs:
		if _needs[need_name] < CRITICAL_THRESHOLD:
			risk += 15.0

	# Long residence decreases risk (attachment)
	if _residence_months > 12:
		risk -= minf(20.0, _residence_months * 0.5)

	# High neuroticism increases sensitivity to problems
	risk *= 1.0 + (neuroticism - 50.0) / 100.0

	_flight_risk = clampf(risk, 0.0, 100.0)


# === Serialization ===

func to_dict() -> Dictionary:
	return {
		"name": resident_name,
		"age": age,
		"archetype": archetype,
		"home_block": {"x": home_block.x, "y": home_block.y, "z": home_block.z},
		"workplace_block": {"x": workplace_block.x, "y": workplace_block.y, "z": workplace_block.z},
		"current_position": {"x": current_position.x, "y": current_position.y, "z": current_position.z},
		"personality": {
			"openness": openness,
			"conscientiousness": conscientiousness,
			"extraversion": extraversion,
			"agreeableness": agreeableness,
			"neuroticism": neuroticism
		},
		"needs": _needs.duplicate(),
		"residence_months": _residence_months
	}


static func from_dict(data: Dictionary) -> Node2D:
	var script: GDScript = load("res://src/agents/resident.gd")
	var resident: Node2D = script.new()
	resident.resident_name = data.get("name", "")
	resident.age = data.get("age", 30)
	resident.archetype = data.get("archetype", "young_professional")

	var home: Dictionary = data.get("home_block", {})
	resident.home_block = Vector3i(home.get("x", 0), home.get("y", 0), home.get("z", 0))

	var work: Dictionary = data.get("workplace_block", {})
	resident.workplace_block = Vector3i(work.get("x", -1), work.get("y", -1), work.get("z", -1))

	var pos: Dictionary = data.get("current_position", {})
	resident.current_position = Vector3i(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))

	var personality: Dictionary = data.get("personality", {})
	resident.openness = personality.get("openness", 50)
	resident.conscientiousness = personality.get("conscientiousness", 50)
	resident.extraversion = personality.get("extraversion", 50)
	resident.agreeableness = personality.get("agreeableness", 50)
	resident.neuroticism = personality.get("neuroticism", 50)

	var needs: Dictionary = data.get("needs", {})
	for need_name in needs:
		resident._needs[need_name] = needs[need_name]

	resident._residence_months = data.get("residence_months", 0)
	resident._update_mood()
	resident._calculate_flight_risk()

	return resident
