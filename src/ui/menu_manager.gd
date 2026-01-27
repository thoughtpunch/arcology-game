extends CanvasLayer
## Manages all game menus and transitions between them
## Handles menu navigation, game state, and auto-save integration
## See: documentation/ui/menus.md

# Menu states
enum MenuState {
	NONE,           # In gameplay
	MAIN_MENU,      # Main menu (startup)
	PAUSE,          # Pause menu overlay
	SETTINGS,       # Settings menu
	NEW_GAME,       # New game menu
	SAVE,           # Save menu
	LOAD,           # Load menu
	CREDITS         # Credits screen
}

# Signals
signal game_started(config: Dictionary)
signal game_loaded(save_path: String)
signal game_resumed
signal quit_requested

# Menu instances
var main_menu: MainMenu
var pause_menu: PauseMenu
var settings_menu: SettingsMenu
var new_game_menu: NewGameMenu
var save_load_menu: SaveLoadMenu
var confirmation_dialog: GameConfirmationDialog
var auto_save: AutoSave

# State
var _current_state := MenuState.MAIN_MENU
var _previous_state := MenuState.NONE
var _game_running := false
var _has_unsaved_changes := false

# Pending confirmation state
enum PendingConfirmation { NONE, DELETE_SAVE, UNSAVED_CHANGES }
var _pending_confirmation := PendingConfirmation.NONE


func _ready() -> void:
	# Set high layer so menus appear above game
	layer = 100

	_create_menus()
	_connect_signals()

	# Start at main menu
	show_main_menu()


func _create_menus() -> void:
	# Main menu
	main_menu = MainMenu.new()
	main_menu.name = "MainMenu"
	main_menu.visible = false
	add_child(main_menu)

	# Pause menu
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	add_child(pause_menu)

	# Settings menu
	settings_menu = SettingsMenu.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.visible = false
	add_child(settings_menu)

	# New game menu
	new_game_menu = NewGameMenu.new()
	new_game_menu.name = "NewGameMenu"
	new_game_menu.visible = false
	add_child(new_game_menu)

	# Save/Load menu
	save_load_menu = SaveLoadMenu.new()
	save_load_menu.name = "SaveLoadMenu"
	save_load_menu.visible = false
	add_child(save_load_menu)

	# Confirmation dialog (always on top)
	confirmation_dialog = GameConfirmationDialog.new()
	confirmation_dialog.name = "ConfirmationDialog"
	confirmation_dialog.visible = false
	add_child(confirmation_dialog)

	# Auto-save system
	auto_save = AutoSave.new()
	auto_save.name = "AutoSave"
	add_child(auto_save)


func _connect_signals() -> void:
	# Main menu
	main_menu.new_game_pressed.connect(_on_new_game_pressed)
	main_menu.continue_pressed.connect(_on_continue_pressed)
	main_menu.load_game_pressed.connect(_on_load_game_pressed)
	main_menu.settings_pressed.connect(_on_settings_pressed)
	main_menu.credits_pressed.connect(_on_credits_pressed)
	main_menu.quit_pressed.connect(_on_quit_pressed)

	# Pause menu
	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.save_game_pressed.connect(_on_save_game_pressed)
	pause_menu.load_game_pressed.connect(_on_pause_load_pressed)
	pause_menu.settings_pressed.connect(_on_pause_settings_pressed)
	pause_menu.main_menu_pressed.connect(_on_return_to_main_menu)
	pause_menu.quit_pressed.connect(_on_pause_quit_pressed)

	# Settings menu
	settings_menu.back_pressed.connect(_on_settings_back)
	settings_menu.apply_pressed.connect(_on_settings_apply)

	# New game menu
	new_game_menu.back_pressed.connect(_on_new_game_back)
	new_game_menu.start_game_pressed.connect(_on_start_game)

	# Save/Load menu
	save_load_menu.back_pressed.connect(_on_save_load_back)
	save_load_menu.save_selected.connect(_on_save_selected)
	save_load_menu.load_selected.connect(_on_load_selected)
	save_load_menu.delete_confirmation_requested.connect(_on_delete_confirmation_requested)

	# Confirmation dialog
	confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
	confirmation_dialog.cancelled.connect(_on_confirmation_cancelled)
	confirmation_dialog.save_and_quit.connect(_on_save_and_quit)

	# Auto-save
	auto_save.auto_save_completed.connect(_on_auto_save_completed)


func _unhandled_input(event: InputEvent) -> void:
	# Handle Esc key for pause menu
	if event.is_action_pressed("ui_cancel"):
		if _game_running:
			if _current_state == MenuState.NONE:
				show_pause_menu()
				get_viewport().set_input_as_handled()
			elif _current_state == MenuState.PAUSE:
				hide_pause_menu()
				get_viewport().set_input_as_handled()


func _hide_all_menus() -> void:
	main_menu.visible = false
	pause_menu.visible = false
	settings_menu.visible = false
	new_game_menu.visible = false
	save_load_menu.visible = false


## Show main menu
func show_main_menu() -> void:
	_previous_state = _current_state
	_current_state = MenuState.MAIN_MENU
	_hide_all_menus()
	main_menu.visible = true
	# Refresh Continue button state in case saves changed
	main_menu.refresh_saves()


## Show pause menu
func show_pause_menu() -> void:
	if not _game_running:
		return
	_previous_state = _current_state
	_current_state = MenuState.PAUSE
	pause_menu.show_menu()
	_pause_game()


## Hide pause menu and resume
func hide_pause_menu() -> void:
	pause_menu.hide_menu()
	_current_state = MenuState.NONE
	_resume_game()
	game_resumed.emit()


## Show settings menu
func show_settings_menu() -> void:
	_previous_state = _current_state
	_current_state = MenuState.SETTINGS
	_hide_all_menus()
	settings_menu.visible = true


## Show new game menu
func show_new_game_menu() -> void:
	_previous_state = _current_state
	_current_state = MenuState.NEW_GAME
	_hide_all_menus()
	new_game_menu.visible = true


## Show save menu
func show_save_menu() -> void:
	_previous_state = _current_state
	_current_state = MenuState.SAVE
	_hide_all_menus()
	save_load_menu.set_mode(SaveLoadMenu.Mode.SAVE)
	save_load_menu.visible = true


## Show load menu
func show_load_menu() -> void:
	_previous_state = _current_state
	_current_state = MenuState.LOAD
	_hide_all_menus()
	save_load_menu.set_mode(SaveLoadMenu.Mode.LOAD)
	save_load_menu.visible = true


## Hide all menus (return to gameplay)
func hide_menus() -> void:
	_hide_all_menus()
	_current_state = MenuState.NONE


## Show confirmation dialog
func show_confirmation(title: String, message: String, details: Array = []) -> void:
	confirmation_dialog.show_confirm(title, message, details)


## Show unsaved changes dialog
func show_unsaved_changes_dialog() -> void:
	confirmation_dialog.show_unsaved_changes()


## Show error dialog
func show_error(title: String, message: String) -> void:
	confirmation_dialog.show_error(title, message)


func _pause_game() -> void:
	get_tree().paused = true


func _resume_game() -> void:
	get_tree().paused = false


# Signal handlers

func _on_new_game_pressed() -> void:
	show_new_game_menu()


func _on_continue_pressed() -> void:
	# Load most recent save
	var saves := _get_sorted_saves()
	if not saves.is_empty():
		_on_load_selected(saves[0].path)


func _on_load_game_pressed() -> void:
	show_load_menu()


func _on_settings_pressed() -> void:
	show_settings_menu()


func _on_credits_pressed() -> void:
	# TODO: Implement credits screen
	print("Credits pressed - not implemented yet")


func _on_quit_pressed() -> void:
	quit_requested.emit()
	get_tree().quit()


func _on_resume_pressed() -> void:
	hide_pause_menu()


func _on_save_game_pressed() -> void:
	show_save_menu()


func _on_pause_load_pressed() -> void:
	if _has_unsaved_changes:
		show_unsaved_changes_dialog()
	else:
		show_load_menu()


func _on_pause_settings_pressed() -> void:
	show_settings_menu()


func _on_return_to_main_menu() -> void:
	if _has_unsaved_changes:
		show_unsaved_changes_dialog()
	else:
		_game_running = false
		_resume_game()
		show_main_menu()


func _on_pause_quit_pressed() -> void:
	if _has_unsaved_changes:
		show_unsaved_changes_dialog()
	else:
		get_tree().quit()


func _on_settings_back() -> void:
	match _previous_state:
		MenuState.MAIN_MENU:
			show_main_menu()
		MenuState.PAUSE:
			_current_state = MenuState.PAUSE
			_hide_all_menus()
			pause_menu.visible = true
		_:
			show_main_menu()


func _on_settings_apply() -> void:
	# Apply settings
	var new_settings := settings_menu.get_settings()
	_apply_settings(new_settings)
	_on_settings_back()


func _apply_settings(settings: Dictionary) -> void:
	# Apply auto-save interval
	if settings.has("auto_save_interval"):
		var interval: int = settings.auto_save_interval
		auto_save.set_interval(interval)

	# TODO: Apply other settings (volume, graphics, etc.)


func _on_new_game_back() -> void:
	show_main_menu()


func _on_start_game(config: Dictionary) -> void:
	_game_running = true
	_has_unsaved_changes = false
	hide_menus()
	_resume_game()
	game_started.emit(config)


func _on_save_load_back() -> void:
	match _previous_state:
		MenuState.MAIN_MENU:
			show_main_menu()
		MenuState.PAUSE:
			_current_state = MenuState.PAUSE
			_hide_all_menus()
			pause_menu.visible = true
		_:
			show_main_menu()


func _on_save_selected(save_name: String) -> void:
	# Get main scene and call save_game
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("save_game"):
		var save_path: String = main_scene.save_game(save_name)
		if not save_path.is_empty():
			print("Saved game as: %s" % save_name)
			_has_unsaved_changes = false
		else:
			show_error("Save Failed", "Could not save the game. Please try again.")
	else:
		push_warning("MenuManager: Main scene doesn't have save_game method")
		_has_unsaved_changes = false
	_on_save_load_back()


func _on_load_selected(save_path: String) -> void:
	_game_running = true
	_has_unsaved_changes = false
	hide_menus()
	_resume_game()
	game_loaded.emit(save_path)


func _on_confirmation_confirmed() -> void:
	# Handle based on pending confirmation type
	match _pending_confirmation:
		PendingConfirmation.DELETE_SAVE:
			save_load_menu.confirm_delete()
		PendingConfirmation.UNSAVED_CHANGES:
			# Proceed without saving
			pass
	_pending_confirmation = PendingConfirmation.NONE


func _on_confirmation_cancelled() -> void:
	# Cancel any pending operation
	match _pending_confirmation:
		PendingConfirmation.DELETE_SAVE:
			save_load_menu.cancel_delete()
	_pending_confirmation = PendingConfirmation.NONE


func _on_delete_confirmation_requested(save_name: String, _save_path: String) -> void:
	_pending_confirmation = PendingConfirmation.DELETE_SAVE
	confirmation_dialog.show_confirm(
		"DELETE SAVE",
		"Are you sure you want to delete \"%s\"?\n\nThis cannot be undone." % save_name
	)


func _on_save_and_quit() -> void:
	# Save then quit
	auto_save.force_save()
	get_tree().quit()


func _on_auto_save_completed(save_path: String) -> void:
	_has_unsaved_changes = false
	print("Auto-saved to: %s" % save_path)


func _get_sorted_saves() -> Array:
	# Get saves sorted by date (most recent first)
	var saves := []
	var dir := DirAccess.open("user://saves/")
	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var path := "user://saves/" + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data: Dictionary = json.get_data()
					data["path"] = path
					saves.append(data)
				file.close()
		file_name = dir.get_next()
	dir.list_dir_end()

	saves.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
	return saves


## Get current menu state
func get_current_state() -> MenuState:
	return _current_state


## Check if game is running
func is_game_running() -> bool:
	return _game_running


## Mark game as having unsaved changes
func mark_unsaved_changes() -> void:
	_has_unsaved_changes = true


## Check if there are unsaved changes
func has_unsaved_changes() -> bool:
	return _has_unsaved_changes
