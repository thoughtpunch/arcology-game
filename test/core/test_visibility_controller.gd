extends SceneTree

## Unit tests for VisibilityController
##
## Tests cutaway visibility mode functionality:
## - Mode switching (NORMAL, CUTAWAY)
## - Cut height adjustment
## - Floor visibility calculations
## - Cut plane indicator
## - Signal emissions

const VisibilityControllerClass := preload("res://src/core/visibility_controller.gd")

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== VisibilityController Tests ===\n")

	# Mode Tests
	_test_initial_mode()
	_test_set_mode_normal()
	_test_set_mode_cutaway()
	_test_toggle_cutaway()
	_test_mode_name()

	# Cut Height Tests
	_test_initial_cut_height()
	_test_set_cut_height()
	_test_cut_height_clamp_min()
	_test_cut_height_clamp_max()
	_test_adjust_cut_height_up()
	_test_adjust_cut_height_down()
	_test_get_cut_floor()
	_test_set_cut_floor()

	# Visibility Tests
	_test_is_position_visible_normal()
	_test_is_position_visible_cutaway_below()
	_test_is_position_visible_cutaway_above()
	_test_is_floor_visible_normal()
	_test_is_floor_visible_cutaway()

	# Cut Plane Indicator Tests
	_test_cut_plane_indicator_creation()
	_test_cut_plane_indicator_position()
	_test_cut_plane_indicator_visibility()

	# Signal Tests
	_test_mode_changed_signal()
	_test_cut_height_changed_signal()

	print("\n=== Results: %d/%d passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("PASS: %s" % test_name)
	else:
		print("FAIL: %s" % test_name)


# --- Mode Tests ---

func _test_initial_mode() -> void:
	var controller: Node = VisibilityControllerClass.new()
	_assert(controller.mode == VisibilityControllerClass.Mode.NORMAL, "Initial mode is NORMAL")
	controller.free()


func _test_set_mode_normal() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	controller.set_mode(VisibilityControllerClass.Mode.NORMAL)
	_assert(controller.mode == VisibilityControllerClass.Mode.NORMAL, "Set mode to NORMAL")
	controller.free()


func _test_set_mode_cutaway() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	_assert(controller.mode == VisibilityControllerClass.Mode.CUTAWAY, "Set mode to CUTAWAY")
	controller.free()


func _test_toggle_cutaway() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.toggle_cutaway()
	_assert(controller.mode == VisibilityControllerClass.Mode.CUTAWAY, "Toggle to CUTAWAY")
	controller.toggle_cutaway()
	_assert(controller.mode == VisibilityControllerClass.Mode.NORMAL, "Toggle back to NORMAL")
	controller.free()


func _test_mode_name() -> void:
	_assert(VisibilityControllerClass.get_mode_name(VisibilityControllerClass.Mode.NORMAL) == "Normal", "Mode name: Normal")
	_assert(VisibilityControllerClass.get_mode_name(VisibilityControllerClass.Mode.CUTAWAY) == "Cutaway", "Mode name: Cutaway")
	_assert(VisibilityControllerClass.get_mode_name(VisibilityControllerClass.Mode.XRAY) == "X-Ray", "Mode name: X-Ray")


# --- Cut Height Tests ---

func _test_initial_cut_height() -> void:
	var controller: Node = VisibilityControllerClass.new()
	_assert(controller.cut_height == VisibilityControllerClass.DEFAULT_CUT_HEIGHT, "Initial cut height is default")
	controller.free()


func _test_set_cut_height() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_height(10.5)
	_assert(is_equal_approx(controller.cut_height, 10.5), "Set cut height to 10.5")
	controller.free()


func _test_cut_height_clamp_min() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_height(-5.0)
	_assert(controller.cut_height >= VisibilityControllerClass.MIN_CUT_HEIGHT, "Cut height clamped to minimum")
	controller.free()


func _test_cut_height_clamp_max() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_height(500.0)
	_assert(controller.cut_height <= VisibilityControllerClass.MAX_CUT_HEIGHT, "Cut height clamped to maximum")
	controller.free()


func _test_adjust_cut_height_up() -> void:
	var controller: Node = VisibilityControllerClass.new()
	var initial: float = controller.cut_height
	controller.adjust_cut_height(VisibilityControllerClass.CUT_HEIGHT_STEP)
	_assert(controller.cut_height > initial, "Adjust cut height up increases height")
	controller.free()


func _test_adjust_cut_height_down() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_height(20.0)  # Start higher
	var initial: float = controller.cut_height
	controller.adjust_cut_height(-VisibilityControllerClass.CUT_HEIGHT_STEP)
	_assert(controller.cut_height < initial, "Adjust cut height down decreases height")
	controller.free()


func _test_get_cut_floor() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_height(7.0)  # 7.0 / 3.5 = floor 2
	_assert(controller.get_cut_floor() == 2, "Get cut floor from height")
	controller.free()


func _test_set_cut_floor() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_cut_floor(3)
	var expected_height: float = (3 + 1) * VisibilityControllerClass.CUBE_HEIGHT
	_assert(is_equal_approx(controller.cut_height, expected_height), "Set cut floor sets correct height")
	controller.free()


# --- Visibility Tests ---

func _test_is_position_visible_normal() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.NORMAL)
	_assert(controller.is_position_visible(100.0), "Normal mode: all positions visible")
	controller.free()


func _test_is_position_visible_cutaway_below() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	controller.set_cut_height(20.0)
	_assert(controller.is_position_visible(15.0), "Cutaway: position below cut is visible")
	controller.free()


func _test_is_position_visible_cutaway_above() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	controller.set_cut_height(20.0)
	_assert(not controller.is_position_visible(25.0), "Cutaway: position above cut is NOT visible")
	controller.free()


func _test_is_floor_visible_normal() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.NORMAL)
	_assert(controller.is_floor_visible(10), "Normal mode: all floors visible")
	controller.free()


func _test_is_floor_visible_cutaway() -> void:
	var controller: Node = VisibilityControllerClass.new()
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	controller.set_cut_height(14.0)  # Floor 4 top = 17.5, floor 3 top = 14.0
	_assert(controller.is_floor_visible(2), "Cutaway: floor 2 visible (top at 10.5)")
	_assert(not controller.is_floor_visible(4), "Cutaway: floor 4 NOT visible (top at 17.5)")
	controller.free()


# --- Cut Plane Indicator Tests ---

func _test_cut_plane_indicator_creation() -> void:
	var controller: Node = VisibilityControllerClass.new()
	var parent := Node3D.new()
	controller.show_cut_plane_indicator(parent, Vector2(100, 100))
	_assert(parent.get_child_count() > 0, "Cut plane indicator created")
	controller.hide_cut_plane_indicator()
	parent.free()
	controller.free()


func _test_cut_plane_indicator_position() -> void:
	var controller: Node = VisibilityControllerClass.new()
	var parent := Node3D.new()
	controller.show_cut_plane_indicator(parent)
	controller.set_cut_height(21.0)
	# _update_cut_plane_position is called internally
	var indicator: MeshInstance3D = parent.get_child(0)
	_assert(is_equal_approx(indicator.position.y, 21.0), "Cut plane indicator at cut height")
	controller.hide_cut_plane_indicator()
	parent.free()
	controller.free()


func _test_cut_plane_indicator_visibility() -> void:
	var controller: Node = VisibilityControllerClass.new()
	var parent := Node3D.new()
	controller.show_cut_plane_indicator(parent)
	var indicator: MeshInstance3D = parent.get_child(0)

	# Should be hidden in NORMAL mode
	controller.set_mode(VisibilityControllerClass.Mode.NORMAL)
	_assert(not indicator.visible, "Cut plane hidden in NORMAL mode")

	# Should be visible in CUTAWAY mode
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)
	_assert(indicator.visible, "Cut plane visible in CUTAWAY mode")

	controller.hide_cut_plane_indicator()
	parent.free()
	controller.free()


# --- Signal Tests ---

# Signal test state (workaround for lambda variable capture issues)
var _signal_test_mode_received := false
var _signal_test_mode_value: int = -1
var _signal_test_height_received := false
var _signal_test_height_value: float = -1.0


func _on_test_mode_changed(mode: int) -> void:
	_signal_test_mode_received = true
	_signal_test_mode_value = mode


func _on_test_height_changed(height: float) -> void:
	_signal_test_height_received = true
	_signal_test_height_value = height


func _test_mode_changed_signal() -> void:
	var controller: Node = VisibilityControllerClass.new()
	_signal_test_mode_received = false
	_signal_test_mode_value = -1

	controller.mode_changed.connect(_on_test_mode_changed)
	controller.set_mode(VisibilityControllerClass.Mode.CUTAWAY)

	_assert(_signal_test_mode_received, "mode_changed signal emitted")
	_assert(_signal_test_mode_value == VisibilityControllerClass.Mode.CUTAWAY, "mode_changed has correct mode")
	controller.free()


func _test_cut_height_changed_signal() -> void:
	var controller: Node = VisibilityControllerClass.new()
	_signal_test_height_received = false
	_signal_test_height_value = -1.0

	controller.cut_height_changed.connect(_on_test_height_changed)
	controller.set_cut_height(25.0)

	_assert(_signal_test_height_received, "cut_height_changed signal emitted")
	_assert(is_equal_approx(_signal_test_height_value, 25.0), "cut_height_changed has correct height")
	controller.free()
