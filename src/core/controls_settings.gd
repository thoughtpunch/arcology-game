extends Node
## ControlsSettings autoload - applies controls settings and manages keybind remapping
## Listens to SettingsPersistence for changes and applies to:
## - CameraController: invert_scroll_zoom, mouse_sensitivity
## - InputMap: keybind remapping

# Default keybindings (action -> InputEvent data)
# These represent the project.godot defaults as a fallback
const DEFAULT_KEYBINDINGS := {
	"move_up": {"key": KEY_W, "alt_key": KEY_UP},
	"move_down": {"key": KEY_S, "alt_key": KEY_DOWN},
	"move_left": {"key": KEY_A, "alt_key": KEY_LEFT},
	"move_right": {"key": KEY_D, "alt_key": KEY_RIGHT},
	"zoom_in": {"mouse": MOUSE_BUTTON_WHEEL_UP, "key": KEY_EQUAL},
	"zoom_out": {"mouse": MOUSE_BUTTON_WHEEL_DOWN, "key": KEY_MINUS}
}

# Signals for systems that need to react
signal invert_scroll_zoom_changed(inverted: bool)
signal mouse_sensitivity_changed(sensitivity: float)
signal keybind_changed(action: String, events: Array[InputEvent])


func _ready() -> void:
	# Apply initial settings
	call_deferred("_apply_all_settings")

	# Connect to settings changes
	var sp := _get_settings_persistence()
	if sp:
		sp.setting_changed.connect(_on_setting_changed)
		sp.settings_loaded.connect(_apply_all_settings)


## Get SettingsPersistence autoload
func _get_settings_persistence() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/SettingsPersistence")
	return null


## Apply all controls settings from SettingsPersistence
func _apply_all_settings() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	# Apply control settings
	_apply_invert_scroll_zoom(sp.get_setting("invert_scroll_zoom", false))
	_apply_mouse_sensitivity(sp.get_setting("mouse_sensitivity", 50))

	# Apply keybindings
	var keybindings: Dictionary = sp.get_setting("keybindings", {})
	_apply_keybindings(keybindings)


## Handle individual setting changes
func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"invert_scroll_zoom":
			_apply_invert_scroll_zoom(value)
		"mouse_sensitivity":
			_apply_mouse_sensitivity(value)
		"keybindings":
			_apply_keybindings(value if value is Dictionary else {})


## Apply invert scroll zoom setting
func _apply_invert_scroll_zoom(inverted: Variant) -> void:
	var invert: bool = inverted if inverted is bool else bool(inverted)
	_invert_scroll_zoom = invert
	invert_scroll_zoom_changed.emit(invert)


## Apply mouse sensitivity setting
func _apply_mouse_sensitivity(sensitivity: Variant) -> void:
	var sens: int = sensitivity if sensitivity is int else int(sensitivity)
	_mouse_sensitivity = clampf(sens / 100.0, 0.1, 2.0)
	mouse_sensitivity_changed.emit(_mouse_sensitivity)


## Apply keybindings from settings
func _apply_keybindings(keybindings: Dictionary) -> void:
	for action in keybindings:
		if not InputMap.has_action(action):
			continue

		var binding: Dictionary = keybindings[action]
		if binding.is_empty():
			continue

		# Create events from stored data
		var events: Array[InputEvent] = _create_events_from_binding(binding)
		if events.is_empty():
			continue

		# Update InputMap
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)

		keybind_changed.emit(action, events)


## Create InputEvent array from binding data
func _create_events_from_binding(binding: Dictionary) -> Array[InputEvent]:
	var events: Array[InputEvent] = []

	# Handle keyboard key
	if "key" in binding:
		var key_event := InputEventKey.new()
		key_event.keycode = binding["key"]
		events.append(key_event)

	# Handle alternate key
	if "alt_key" in binding:
		var alt_event := InputEventKey.new()
		alt_event.keycode = binding["alt_key"]
		events.append(alt_event)

	# Handle mouse button
	if "mouse" in binding:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = binding["mouse"]
		events.append(mouse_event)

	return events


# State
var _invert_scroll_zoom: bool = false
var _mouse_sensitivity: float = 0.5


## Check if scroll zoom is inverted
func is_scroll_zoom_inverted() -> bool:
	return _invert_scroll_zoom


## Get mouse sensitivity multiplier (0.1 to 2.0)
func get_mouse_sensitivity() -> float:
	return _mouse_sensitivity


## Get the keybinding for an action as serializable Dictionary
func get_keybinding(action: String) -> Dictionary:
	if not InputMap.has_action(action):
		return {}

	var binding := {}
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if "key" in binding:
				binding["alt_key"] = event.keycode
			else:
				binding["key"] = event.keycode
		elif event is InputEventMouseButton:
			binding["mouse"] = event.button_index

	return binding


## Set a keybinding for an action
func set_keybinding(action: String, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		push_warning("ControlsSettings: Unknown action '%s'" % action)
		return

	# Update InputMap
	InputMap.action_erase_events(action)
	for event in events:
		InputMap.action_add_event(action, event)

	# Serialize and save to SettingsPersistence
	var binding := {}
	for event in events:
		if event is InputEventKey:
			if "key" in binding:
				binding["alt_key"] = event.keycode
			else:
				binding["key"] = event.keycode
		elif event is InputEventMouseButton:
			binding["mouse"] = event.button_index

	_save_keybinding(action, binding)
	keybind_changed.emit(action, events)


## Save keybinding to SettingsPersistence
func _save_keybinding(action: String, binding: Dictionary) -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	var keybindings: Dictionary = sp.get_setting("keybindings", {}).duplicate()
	keybindings[action] = binding
	sp.set_setting("keybindings", keybindings)


## Reset a keybinding to default
func reset_keybinding(action: String) -> void:
	if action not in DEFAULT_KEYBINDINGS:
		push_warning("ControlsSettings: No default for action '%s'" % action)
		return

	var binding: Dictionary = DEFAULT_KEYBINDINGS[action]
	var events: Array[InputEvent] = _create_events_from_binding(binding)
	set_keybinding(action, events)


## Reset all keybindings to defaults
func reset_all_keybindings() -> void:
	for action in DEFAULT_KEYBINDINGS:
		reset_keybinding(action)


## Get all actions that can be remapped
func get_remappable_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in DEFAULT_KEYBINDINGS:
		actions.append(action)
	return actions


## Check for keybind conflict (same key used by another action)
func check_conflict(action: String, event: InputEvent) -> String:
	for other_action in InputMap.get_actions():
		if other_action == action:
			continue
		if other_action.begins_with("ui_"):
			continue  # Skip built-in UI actions

		for other_event in InputMap.action_get_events(other_action):
			if _events_match(event, other_event):
				return other_action

	return ""  # No conflict


## Check if two events match (same key/button)
func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.keycode == b.keycode
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false


## Convert InputEvent to display string
static func event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP: return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Mouse Wheel Down"
			_: return "Mouse %d" % event.button_index
	return "Unknown"
