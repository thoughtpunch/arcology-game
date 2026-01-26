extends SceneTree
## Visual Test - Tier 3
## Loads game, waits for render, takes screenshot
## Run: godot --script res://tests/visual_test.gd
## (Requires display - use Xvfb on headless systems)

func _init() -> void:
	print("=" .repeat(60))
	print("VISUAL TEST")
	print("=" .repeat(60))

	# Load main scene
	print("Loading main scene...")
	var main_scene = load("res://scenes/main.tscn")

	if main_scene == null:
		print("✗ Failed to load main scene")
		quit(1)
		return

	var instance = main_scene.instantiate()
	get_root().add_child(instance)
	print("✓ Scene loaded and added to tree")

	# Wait for rendering to complete
	print("Waiting for render...")

	# Wait several frames to ensure everything is rendered
	for i in range(10):
		await process_frame

	# Additional wait for any async loading
	await create_timer(0.5).timeout

	print("✓ Render complete")

	# Take screenshot
	print("Capturing screenshot...")

	var viewport = get_root().get_viewport()
	if viewport == null:
		print("✗ Could not get viewport")
		quit(1)
		return

	# Wait for next frame to ensure texture is ready
	await RenderingServer.frame_post_draw

	var image = viewport.get_texture().get_image()

	if image == null:
		print("✗ Could not capture image")
		quit(1)
		return

	# Save screenshot
	var output_path = "res://test_output/screenshot.png"
	var error = image.save_png(output_path)

	if error != OK:
		print("✗ Failed to save screenshot: %s" % error)
		quit(1)
		return

	print("✓ Screenshot saved to: test_output/screenshot.png")

	# Print image info
	print("")
	print("Image details:")
	print("  Size: %dx%d" % [image.get_width(), image.get_height()])
	print("  Format: %s" % image.get_format())

	print("")
	print("=" .repeat(60))
	print("VISUAL TEST PASSED")
	print("=" .repeat(60))
	print("")
	print("Next: Have Claude analyze test_output/screenshot.png")

	quit(0)
