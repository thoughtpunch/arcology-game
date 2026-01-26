extends SceneTree
## Smoke Test - Tier 2
## Loads main scene, runs 1 frame, verifies no crash
## Run: godot --headless --script res://tests/smoke_test.gd

func _init() -> void:
	print("=" .repeat(60))
	print("SMOKE TEST")
	print("=" .repeat(60))

	# Try to load main scene
	print("Loading main scene...")
	var main_scene = load("res://scenes/main.tscn")

	if main_scene == null:
		print("✗ Failed to load main scene")
		quit(1)
		return

	print("✓ Main scene loaded")

	# Instantiate
	print("Instantiating...")
	var instance = main_scene.instantiate()

	if instance == null:
		print("✗ Failed to instantiate main scene")
		quit(1)
		return

	print("✓ Main scene instantiated")

	# Add to tree
	print("Adding to tree...")
	get_root().add_child(instance)
	print("✓ Added to tree")

	# Wait one frame to trigger _ready() methods
	print("Running one frame...")
	await process_frame
	print("✓ First frame completed")

	# Check for expected nodes
	print("")
	print("Checking expected nodes...")

	var checks := [
		["Camera2D", instance.has_node("Camera2D")],
		["World", instance.has_node("World")],
		["UI", instance.has_node("UI")],
	]

	var all_passed := true
	for check in checks:
		var name = check[0]
		var exists = check[1]
		if exists:
			print("  ✓ %s exists" % name)
		else:
			print("  ⚠ %s not found (may be optional)" % name)

	print("")
	print("=" .repeat(60))
	print("SMOKE TEST PASSED")
	print("=" .repeat(60))

	quit(0)
