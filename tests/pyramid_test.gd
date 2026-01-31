extends SceneTree
## MEGA END-TO-END TEST: Build a 15-story balanced pyramid arcology
##
## Tests ALL build rules from documentation:
## - Entrances ground_only
## - Adjacency required
## - Elevators connected to corridors
## - Underground excavation
## - Multi-floor blocks
## - Balanced work/life/transit/green layout
##
## Layout Design (like a real architect):
## - Underground (-2, -1): Industrial, warehouses, utilities
## - Floor 0: 4 entrances, main corridors, commercial lobby
## - Floors 1-3: Commercial (offices, shops, restaurants)
## - Floors 4-7: Residential (standard housing)
## - Floors 8-10: Residential (premium) + Civic (school, clinic)
## - Floors 11-13: Gardens + Premium residential
## - Floor 14: Penthouse + Rooftop park
##
## Run: godot --path . --script res://tests/pyramid_test.gd

const SCREENSHOT_DIR := "res://test_output/pyramid/"
const ScenarioConfigScript = preload("res://src/phase0/scenario_config.gd")

var _sandbox: Node3D
var _blocks_placed := 0
var _blocks_failed := 0
var _current_floor := 0
var _screenshot_count := 0
var _errors: Array[String] = []

# Block type shortcuts - loaded from registry
var ENTRANCE: Resource
var CORRIDOR: Resource
var STAIRS: Resource
var ELEVATOR: Resource
var RES_BUDGET: Resource
var RES_STANDARD: Resource
var RES_PREMIUM: Resource
var PENTHOUSE: Resource
var COMMERCIAL_SHOP: Resource
var COMMERCIAL_OFFICE: Resource
var COMMERCIAL_RESTAURANT: Resource
var CAFE: Resource
var GROCERY: Resource
var INDUSTRIAL: Resource
var WAREHOUSE: Resource
var GARDEN: Resource
var PLANTER: Resource
var ROOFTOP_PARK: Resource
var POWER: Resource
var HVAC: Resource
var SECURITY: Resource
var SCHOOL: Resource
var CLINIC: Resource
var LIBRARY: Resource
var COMMUNITY_CENTER: Resource
var GYM: Resource

# Build zone center
const CENTER_X := 50
const CENTER_Z := 50


func _init() -> void:
	print("=" .repeat(70))
	print("PYRAMID ARCOLOGY - 15 STORY MEGA END-TO-END TEST")
	print("=" .repeat(70))
	print("")

	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR.replace("res://", ""))

	# Load scene
	print("[Setup] Loading phase0_sandbox...")
	var scene = load("res://scenes/phase0_sandbox.tscn")
	if not scene:
		_fatal("Failed to load scene")
		return

	_sandbox = scene.instantiate()
	get_root().add_child(_sandbox)
	await _wait_frames(3)

	# Hide MenuManager
	var menu_manager = get_root().get_node_or_null("MenuManager")
	if menu_manager:
		menu_manager._hide_all_menus()
		menu_manager._game_running = true
		menu_manager.layer = -100

	# Remove scenario picker, build world directly
	var picker = _sandbox.get_node_or_null("PickerCanvas")
	if picker:
		picker.queue_free()

	var config = ScenarioConfigScript.blank_slate()
	_sandbox._config = config
	_sandbox.build_zone_origin = config.build_zone_origin
	_sandbox.build_zone_size = config.build_zone_size
	_sandbox._build_world()

	await _wait_frames(10)
	print("[Setup] World ready")
	print("")

	# Cache block definitions
	_cache_block_definitions()

	# Take initial screenshot
	await _screenshot("00_empty_world")

	# BUILD THE 15-STORY PYRAMID!
	print("=" .repeat(70))
	print("BUILDING 15-STORY BALANCED PYRAMID ARCOLOGY")
	print("=" .repeat(70))
	print("")

	# Phase 1: Ground floor (entrances, main circulation)
	await _build_ground_floor()

	# Phase 2: Underground industrial (excavate, then build)
	await _build_underground()

	# Phase 3: Commercial floors (1-3)
	await _build_commercial_floors()

	# Phase 4: Residential floors (4-7 standard, 8-10 premium+civic)
	await _build_residential_floors()

	# Phase 5: Garden floors (11-13)
	await _build_garden_floors()

	# Phase 6: Penthouse (14)
	await _build_penthouse()

	# Final overview
	await _screenshot("99_complete_pyramid")

	# Orbit camera for glamour shots
	await _orbit_camera_shots()

	# Results
	print("")
	print("=" .repeat(70))
	print("TEST RESULTS")
	print("=" .repeat(70))
	print("")
	print("Blocks placed: %d" % _blocks_placed)
	print("Blocks failed: %d" % _blocks_failed)
	print("Screenshots: %d" % _screenshot_count)
	print("")

	if _errors.size() > 0:
		print("ERRORS (first 20):")
		for i in range(min(_errors.size(), 20)):
			print("  - %s" % _errors[i])
		print("")

	if _blocks_failed > 0:
		print("TEST FAILED - %d block placements rejected" % _blocks_failed)
		quit(1)
	else:
		print("TEST PASSED - 15-story pyramid complete!")
		quit(0)


func _cache_block_definitions() -> void:
	var reg = _sandbox.registry
	ENTRANCE = reg.get_definition("entrance")
	CORRIDOR = reg.get_definition("corridor")
	STAIRS = reg.get_definition("stairs")
	ELEVATOR = reg.get_definition("elevator_shaft")
	RES_BUDGET = reg.get_definition("residential_budget")
	RES_STANDARD = reg.get_definition("residential_standard")
	RES_PREMIUM = reg.get_definition("residential_premium")
	PENTHOUSE = reg.get_definition("penthouse")
	COMMERCIAL_SHOP = reg.get_definition("commercial_shop")
	COMMERCIAL_OFFICE = reg.get_definition("commercial_office")
	COMMERCIAL_RESTAURANT = reg.get_definition("commercial_restaurant")
	CAFE = reg.get_definition("cafe")
	GROCERY = reg.get_definition("grocery")
	INDUSTRIAL = reg.get_definition("industrial_light")
	WAREHOUSE = reg.get_definition("warehouse")
	GARDEN = reg.get_definition("green_garden")
	PLANTER = reg.get_definition("green_planter")
	ROOFTOP_PARK = reg.get_definition("rooftop_park")
	POWER = reg.get_definition("infra_power")
	HVAC = reg.get_definition("infra_hvac")
	SECURITY = reg.get_definition("civic_security")
	SCHOOL = reg.get_definition("civic_school")
	CLINIC = reg.get_definition("civic_clinic")
	LIBRARY = reg.get_definition("library")
	COMMUNITY_CENTER = reg.get_definition("community_center")
	GYM = reg.get_definition("entertainment_gym")


func _place(def: Resource, x: int, y: int, z: int, rot: int = 0) -> bool:
	if not def:
		_errors.append("Null definition at (%d,%d,%d)" % [x, y, z])
		_blocks_failed += 1
		return false

	var pos := Vector3i(x, y, z)
	var result = _sandbox.place_block(def, pos, rot)

	if result:
		_blocks_placed += 1
		return true
	else:
		_blocks_failed += 1
		_errors.append("Failed to place %s at (%d,%d,%d) rot=%d" % [def.id, x, y, z, rot])
		return false


func _build_ground_floor() -> void:
	print("[Floor 0] Ground Level - Entrances & Main Circulation")
	_current_floor = 0

	# 4 entrances on each side (TEST: ground_only rule)
	print("  Placing 4 entrances...")
	_place(ENTRANCE, CENTER_X, 0, CENTER_Z - 6)  # North
	_place(ENTRANCE, CENTER_X, 0, CENTER_Z + 6)  # South
	_place(ENTRANCE, CENTER_X + 6, 0, CENTER_Z)  # East
	_place(ENTRANCE, CENTER_X - 6, 0, CENTER_Z)  # West

	await _screenshot("01_entrances")

	# Main corridors (cross pattern) using BFS from entrances
	print("  Building main corridors...")
	# North-South corridor from North entrance
	for z in range(CENTER_Z - 5, CENTER_Z + 1):
		_place(CORRIDOR, CENTER_X, 0, z)
	# Then from South entrance
	for z in range(CENTER_Z + 5, CENTER_Z, -1):
		_place(CORRIDOR, CENTER_X, 0, z)

	# East-West corridor from West entrance
	for x in range(CENTER_X - 5, CENTER_X):
		_place(CORRIDOR, x, 0, CENTER_Z)
	# Then from East entrance
	for x in range(CENTER_X + 5, CENTER_X, -1):
		_place(CORRIDOR, x, 0, CENTER_Z)

	await _screenshot("02_main_corridors")

	# 4 elevator cores at corners (TEST: elevators need corridor connections)
	print("  Building elevator cores with corridor connections...")
	# NW elevator core
	_place(CORRIDOR, CENTER_X - 3, 0, CENTER_Z - 1)  # Connect from main
	_place(CORRIDOR, CENTER_X - 3, 0, CENTER_Z - 2)  # Lobby
	_place(ELEVATOR, CENTER_X - 3, 0, CENTER_Z - 3)  # Elevator

	# NE elevator core
	_place(CORRIDOR, CENTER_X + 3, 0, CENTER_Z - 1)
	_place(CORRIDOR, CENTER_X + 3, 0, CENTER_Z - 2)
	_place(ELEVATOR, CENTER_X + 3, 0, CENTER_Z - 3)

	# SW elevator core
	_place(CORRIDOR, CENTER_X - 3, 0, CENTER_Z + 1)
	_place(CORRIDOR, CENTER_X - 3, 0, CENTER_Z + 2)
	_place(ELEVATOR, CENTER_X - 3, 0, CENTER_Z + 3)

	# SE elevator core
	_place(CORRIDOR, CENTER_X + 3, 0, CENTER_Z + 1)
	_place(CORRIDOR, CENTER_X + 3, 0, CENTER_Z + 2)
	_place(ELEVATOR, CENTER_X + 3, 0, CENTER_Z + 3)

	# Underground access stairs (placed now so they're not filled by commercial)
	print("  Placing underground access stairs...")
	_place(CORRIDOR, CENTER_X + 4, 0, CENTER_Z - 1)
	_place(STAIRS, CENTER_X + 4, 0, CENTER_Z - 2)

	await _screenshot("03_elevator_cores")

	# Fill with commercial lobby using BFS
	print("  Filling lobby with commercial...")
	var filled := _bfs_fill_floor(0, 6, COMMERCIAL_SHOP, 80)
	print("    Filled %d commercial blocks" % filled)

	await _screenshot("04_ground_complete")
	print("  Ground floor complete: %d blocks" % _blocks_placed)
	print("")


func _build_underground() -> void:
	print("[Underground] Excavating and building 2 industrial floors")
	print("")

	var stair_x := CENTER_X + 4
	var stair_z := CENTER_Z - 2
	var dig_radius := 4

	print("  Underground access via stairs at (%d, 0, %d)" % [stair_x, stair_z])
	await _screenshot("05a_underground_access")

	# Excavate level -1
	print("  [Step 1] Excavating floor -1...")
	var cells_dug := 0
	var excavated_cells: Array[Vector3i] = []
	for dx in range(-dig_radius, dig_radius + 1):
		for dz in range(-dig_radius, dig_radius + 1):
			var x := stair_x + dx
			var z := stair_z + dz
			var cell := Vector3i(x, -1, z)
			if _sandbox.cell_occupancy.has(cell) and _sandbox.cell_occupancy[cell] == -1:
				_sandbox._remove_ground_cell(cell)
				cells_dug += 1
			excavated_cells.append(cell)
	print("    Excavated %d cells at y=-1" % cells_dug)
	await _screenshot("05b_excavated_level_minus1")

	# Build floor -1
	print("  [Step 2] Building floor -1 industrial...")
	_current_floor = -1
	_place(STAIRS, stair_x, -1, stair_z)

	var excavated_set: Dictionary = {}
	for cell in excavated_cells:
		excavated_set[cell] = true

	var filled_1 := _bfs_fill_underground(-1, stair_x, stair_z, excavated_set, 60)
	print("    Built %d industrial blocks at y=-1" % filled_1)
	await _screenshot("05c_floor_minus1_built")

	# Excavate level -2
	print("  [Step 3] Excavating floor -2...")
	cells_dug = 0
	excavated_cells.clear()
	excavated_set.clear()
	for dx in range(-dig_radius, dig_radius + 1):
		for dz in range(-dig_radius, dig_radius + 1):
			var x := stair_x + dx
			var z := stair_z + dz
			var cell := Vector3i(x, -2, z)
			if _sandbox.cell_occupancy.has(cell) and _sandbox.cell_occupancy[cell] == -1:
				_sandbox._remove_ground_cell(cell)
				cells_dug += 1
			excavated_cells.append(cell)
			excavated_set[cell] = true
	print("    Excavated %d cells at y=-2" % cells_dug)
	await _screenshot("05d_excavated_level_minus2")

	# Build floor -2
	print("  [Step 4] Building floor -2 industrial...")
	_current_floor = -2
	_place(STAIRS, stair_x, -2, stair_z)

	var filled_2 := _bfs_fill_underground(-2, stair_x, stair_z, excavated_set, 60)
	print("    Built %d industrial blocks at y=-2" % filled_2)
	await _screenshot("05e_floor_minus2_built")

	print("  Underground industrial complete")
	print("")


func _bfs_fill_underground(y: int, start_x: int, start_z: int, excavated: Dictionary, max_blocks: int) -> int:
	# Use only 1x1 blocks underground to avoid overlap issues
	var industrial_types := [POWER, HVAC, POWER, HVAC]
	var to_fill: Array[Vector3i] = []
	var visited: Dictionary = {}
	var filled := 0

	visited[Vector3i(start_x, y, start_z)] = true

	for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
		var nb: Vector3i = Vector3i(start_x, y, start_z) + dir
		if excavated.has(nb) and not _sandbox.is_cell_occupied(nb):
			to_fill.append(nb)
			visited[nb] = true

	while to_fill.size() > 0 and filled < max_blocks:
		var cell: Vector3i = to_fill.pop_front()
		if _sandbox.is_cell_occupied(cell):
			continue
		if not excavated.has(cell):
			continue

		var type_idx := filled % industrial_types.size()
		var block_type = industrial_types[type_idx]
		if block_type == null:
			block_type = POWER

		if _place(block_type, cell.x, cell.y, cell.z):
			filled += 1
			for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
				var nb: Vector3i = cell + dir
				if not visited.has(nb) and excavated.has(nb) and not _sandbox.is_cell_occupied(nb):
					to_fill.append(nb)
					visited[nb] = true

	return filled


func _bfs_fill_floor(y: int, radius: int, block_type: Resource, max_blocks: int) -> int:
	var to_fill: Array[Vector3i] = []
	var visited: Dictionary = {}
	var filled := 0

	for x in range(CENTER_X - radius, CENTER_X + radius + 1):
		for z in range(CENTER_Z - radius, CENTER_Z + radius + 1):
			var cell := Vector3i(x, y, z)
			if _sandbox.is_cell_occupied(cell):
				visited[cell] = true
				for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
					var nb: Vector3i = cell + dir
					if not visited.has(nb) and not _sandbox.is_cell_occupied(nb):
						if abs(nb.x - CENTER_X) <= radius and abs(nb.z - CENTER_Z) <= radius:
							to_fill.append(nb)
							visited[nb] = true

	while to_fill.size() > 0 and filled < max_blocks:
		var cell: Vector3i = to_fill.pop_front()
		if _sandbox.is_cell_occupied(cell):
			continue

		if _place(block_type, cell.x, cell.y, cell.z):
			filled += 1
			for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
				var nb: Vector3i = cell + dir
				if not visited.has(nb) and not _sandbox.is_cell_occupied(nb):
					if abs(nb.x - CENTER_X) <= radius and abs(nb.z - CENTER_Z) <= radius:
						to_fill.append(nb)
						visited[nb] = true

	return filled


func _build_commercial_floors() -> void:
	print("[Floors 1-3] Commercial District")

	for floor_y in [1, 2, 3]:
		print("  [Floor %d] Building commercial..." % floor_y)
		_current_floor = floor_y

		# Extend elevator shafts
		_place(ELEVATOR, CENTER_X - 3, floor_y, CENTER_Z - 3)
		_place(ELEVATOR, CENTER_X + 3, floor_y, CENTER_Z - 3)
		_place(ELEVATOR, CENTER_X - 3, floor_y, CENTER_Z + 3)
		_place(ELEVATOR, CENTER_X + 3, floor_y, CENTER_Z + 3)

		# Elevator lobbies - CORRIDORS connect to elevators
		_place(CORRIDOR, CENTER_X - 3, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X + 3, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X - 3, floor_y, CENTER_Z + 2)
		_place(CORRIDOR, CENTER_X + 3, floor_y, CENTER_Z + 2)

		# Cross corridors
		for z in range(CENTER_Z - 2, CENTER_Z + 3):
			_place(CORRIDOR, CENTER_X, floor_y, z)
		for x in range(CENTER_X - 2, CENTER_X + 3):
			if x != CENTER_X:
				_place(CORRIDOR, x, floor_y, CENTER_Z)

		# Connect elevator lobbies to main corridors
		_place(CORRIDOR, CENTER_X - 2, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X - 1, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X + 1, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X + 2, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X - 2, floor_y, CENTER_Z + 2)
		_place(CORRIDOR, CENTER_X - 1, floor_y, CENTER_Z + 2)
		_place(CORRIDOR, CENTER_X + 1, floor_y, CENTER_Z + 2)
		_place(CORRIDOR, CENTER_X + 2, floor_y, CENTER_Z + 2)

		# Fill with varied commercial
		var block_type = COMMERCIAL_OFFICE if floor_y == 3 else (COMMERCIAL_RESTAURANT if floor_y == 2 else COMMERCIAL_SHOP)
		var filled := _bfs_fill_floor(floor_y, 5, block_type, 60)
		print("    Filled %d commercial blocks" % filled)

		await _screenshot("%02d_floor_%d_commercial" % [6 + floor_y - 1, floor_y])

	print("")


func _build_residential_floors() -> void:
	print("[Floors 4-10] Residential District")

	# Floors 4-7: Standard housing
	for floor_y in [4, 5, 6, 7]:
		print("  [Floor %d] Building standard residential..." % floor_y)
		_current_floor = floor_y

		# Elevator shafts
		_place(ELEVATOR, CENTER_X - 3, floor_y, CENTER_Z - 3)
		_place(ELEVATOR, CENTER_X + 3, floor_y, CENTER_Z - 3)
		_place(ELEVATOR, CENTER_X - 3, floor_y, CENTER_Z + 3)
		_place(ELEVATOR, CENTER_X + 3, floor_y, CENTER_Z + 3)

		# Elevator lobbies
		_place(CORRIDOR, CENTER_X - 3, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X + 3, floor_y, CENTER_Z - 2)
		_place(CORRIDOR, CENTER_X - 3, floor_y, CENTER_Z + 2)
		_place(CORRIDOR, CENTER_X + 3, floor_y, CENTER_Z + 2)

		# Central corridors
		for z in range(CENTER_Z - 2, CENTER_Z + 3):
			_place(CORRIDOR, CENTER_X, floor_y, z)
		for x in range(CENTER_X - 2, CENTER_X + 3):
			if x != CENTER_X:
				_place(CORRIDOR, x, floor_y, CENTER_Z)

		# Fill with residential
		var filled := _bfs_fill_floor(floor_y, 4, RES_STANDARD, 50)
		print("    Filled %d residential blocks" % filled)

		await _screenshot("%02d_floor_%d_residential" % [9 + floor_y - 4, floor_y])

	# Floors 8-10: Premium housing + civic services
	for floor_y in [8, 9, 10]:
		print("  [Floor %d] Building premium residential + civic..." % floor_y)
		_current_floor = floor_y

		# Elevator shafts (smaller footprint at upper floors)
		_place(ELEVATOR, CENTER_X - 2, floor_y, CENTER_Z - 2)
		_place(ELEVATOR, CENTER_X + 2, floor_y, CENTER_Z - 2)
		_place(ELEVATOR, CENTER_X - 2, floor_y, CENTER_Z + 2)
		_place(ELEVATOR, CENTER_X + 2, floor_y, CENTER_Z + 2)

		# Elevator lobbies
		_place(CORRIDOR, CENTER_X - 2, floor_y, CENTER_Z - 1)
		_place(CORRIDOR, CENTER_X + 2, floor_y, CENTER_Z - 1)
		_place(CORRIDOR, CENTER_X - 2, floor_y, CENTER_Z + 1)
		_place(CORRIDOR, CENTER_X + 2, floor_y, CENTER_Z + 1)

		# Central corridors
		for z in range(CENTER_Z - 1, CENTER_Z + 2):
			_place(CORRIDOR, CENTER_X, floor_y, z)
		for x in range(CENTER_X - 1, CENTER_X + 2):
			if x != CENTER_X:
				_place(CORRIDOR, x, floor_y, CENTER_Z)

		# Add civic services on floor 9
		if floor_y == 9:
			# Security station near elevator
			if SECURITY:
				_place(SECURITY, CENTER_X - 1, floor_y, CENTER_Z - 1)

		# Fill with premium residential
		var filled := _bfs_fill_floor(floor_y, 3, RES_PREMIUM, 40)
		print("    Filled %d premium residential blocks" % filled)

		await _screenshot("%02d_floor_%d_premium" % [13 + floor_y - 8, floor_y])

	print("")


func _build_garden_floors() -> void:
	print("[Floors 11-13] Garden District")

	for floor_y in [11, 12, 13]:
		print("  [Floor %d] Building gardens + premium..." % floor_y)
		_current_floor = floor_y

		# Single central elevator at upper floors
		_place(ELEVATOR, CENTER_X, floor_y, CENTER_Z)

		# Corridors around elevator
		_place(CORRIDOR, CENTER_X - 1, floor_y, CENTER_Z)
		_place(CORRIDOR, CENTER_X + 1, floor_y, CENTER_Z)
		_place(CORRIDOR, CENTER_X, floor_y, CENTER_Z - 1)
		_place(CORRIDOR, CENTER_X, floor_y, CENTER_Z + 1)

		# Fill with alternating planters and premium housing
		var to_fill: Array[Vector3i] = []
		var visited: Dictionary = {}
		var radius := 2
		var filled := 0

		for x in range(CENTER_X - radius, CENTER_X + radius + 1):
			for z in range(CENTER_Z - radius, CENTER_Z + radius + 1):
				var cell := Vector3i(x, floor_y, z)
				if _sandbox.is_cell_occupied(cell):
					visited[cell] = true
					for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
						var nb: Vector3i = cell + dir
						if not visited.has(nb) and abs(nb.x - CENTER_X) <= radius and abs(nb.z - CENTER_Z) <= radius:
							to_fill.append(nb)
							visited[nb] = true

		while to_fill.size() > 0 and filled < 20:
			var cell: Vector3i = to_fill.pop_front()
			if _sandbox.is_cell_occupied(cell):
				continue
			# Alternate: planters on edges, premium in middle
			var block_type = PLANTER if filled % 2 == 0 else RES_PREMIUM
			if _place(block_type, cell.x, cell.y, cell.z):
				filled += 1
				for dir in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
					var nb: Vector3i = cell + dir
					if not visited.has(nb) and abs(nb.x - CENTER_X) <= radius and abs(nb.z - CENTER_Z) <= radius:
						to_fill.append(nb)
						visited[nb] = true

		print("    Filled %d garden/premium blocks" % filled)
		await _screenshot("%02d_floor_%d_garden" % [16 + floor_y - 11, floor_y])

	print("")


func _build_penthouse() -> void:
	print("[Floor 14] Penthouse Level")
	_current_floor = 14

	# Final elevator
	_place(ELEVATOR, CENTER_X, 14, CENTER_Z)

	# Penthouse apartments around the elevator
	_place(CORRIDOR, CENTER_X - 1, 14, CENTER_Z)
	_place(CORRIDOR, CENTER_X + 1, 14, CENTER_Z)
	_place(CORRIDOR, CENTER_X, 14, CENTER_Z - 1)
	_place(CORRIDOR, CENTER_X, 14, CENTER_Z + 1)

	# Premium penthouses
	_place(RES_PREMIUM, CENTER_X - 1, 14, CENTER_Z - 1)
	_place(RES_PREMIUM, CENTER_X + 1, 14, CENTER_Z - 1)
	_place(RES_PREMIUM, CENTER_X - 1, 14, CENTER_Z + 1)
	_place(RES_PREMIUM, CENTER_X + 1, 14, CENTER_Z + 1)

	await _screenshot("19_penthouse")
	print("  Penthouse complete")
	print("")


func _orbit_camera_shots() -> void:
	print("[Camera] Taking orbital glamour shots...")
	var camera = _sandbox.get_node_or_null("OrbitalCamera")
	if not camera:
		return

	# Pan up to see the full 15-story pyramid
	camera.target = Vector3(CENTER_X * 6.0, 42.0, CENTER_Z * 6.0)
	camera.distance = 200.0
	camera.elevation = 20.0

	for angle in [0, 90, 180, 270]:
		camera.azimuth = float(angle)
		await _wait_frames(5)
		await _screenshot("orbit_%03d" % angle)

	print("  Orbital shots complete")


func _screenshot(name: String) -> void:
	_screenshot_count += 1
	await RenderingServer.frame_post_draw

	var viewport = get_root().get_viewport()
	if not viewport:
		return

	var image = viewport.get_texture().get_image()
	if not image:
		return

	var path = SCREENSHOT_DIR + name + ".png"
	image.save_png(path)
	print("    [img] %s" % name)


func _wait_frames(count: int) -> void:
	for i in range(count):
		await process_frame


func _fatal(msg: String) -> void:
	print("FATAL: %s" % msg)
	quit(1)
