# Milestone 0: Skeleton

**Goal:** Empty Godot project that runs

---

## Checklist

```
✓ Project created with folder structure
✓ Main scene loads
✓ Can see a placeholder sprite
✓ Basic input handling (camera pan/zoom)
```

## Deliverable

You can run the game and move a camera around an empty space.

---

## Tasks

### 1. Create Project Structure

```
arcology/
├── project.godot
├── src/
│   ├── core/
│   ├── blocks/
│   ├── environment/
│   ├── agents/
│   ├── transit/
│   ├── economy/
│   └── ui/
├── scenes/
│   └── main.tscn
├── assets/
│   └── sprites/
│       └── blocks/
├── data/
└── documentation/
```

### 2. Main Scene

Create `scenes/main.tscn`:
- Node2D root
- Camera2D child with zoom/pan
- Placeholder sprite to verify rendering

### 3. Camera Controls

Basic isometric camera:
- WASD or arrow keys to pan
- Scroll wheel to zoom
- Optional: middle-click drag to pan

```gdscript
# src/ui/camera.gd
extends Camera2D

var zoom_speed: float = 0.1
var pan_speed: float = 400

func _process(delta):
    # Pan
    var input = Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        input.x += 1
    if Input.is_action_pressed("ui_left"):
        input.x -= 1
    if Input.is_action_pressed("ui_down"):
        input.y += 1
    if Input.is_action_pressed("ui_up"):
        input.y -= 1

    position += input * pan_speed * delta / zoom.x

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom *= 1 + zoom_speed
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom *= 1 - zoom_speed
        zoom = zoom.clamp(Vector2(0.5, 0.5), Vector2(3, 3))
```

### 4. Placeholder Sprite

Create a simple 64x32 isometric tile in `assets/sprites/blocks/`:
- Can be a colored rectangle for now
- Verifies rendering pipeline works

---

## Acceptance Criteria

- [ ] `project.godot` opens in Godot 4 without errors
- [ ] Main scene runs without crashes
- [ ] Can see placeholder sprite
- [ ] Camera pans with arrow keys/WASD
- [ ] Camera zooms with scroll wheel
- [ ] All folders created per structure
