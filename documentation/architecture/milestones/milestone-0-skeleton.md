# Milestone 0: Skeleton

**Goal:** Empty Godot project that runs with a 3D viewport

---

## Checklist

```
Done  Project created with folder structure
Done  Main scene loads
Done  Can see a placeholder 3D mesh (BoxMesh cube)
Done  Basic input handling (3D orbital camera)
```

## Deliverable

You can run the game and orbit a 3D camera around an empty scene with a placeholder block.

---

## Tasks

### 1. Create Project Structure

```
arcology/
 project.godot
 src/
   core/
   phase0/
   blocks/
   environment/
   agents/
   transit/
   economy/
   rendering/
   ui/
 scenes/
   main.tscn
   main.tscn
 shaders/
 assets/
 data/
 documentation/
```

### 2. Main Scene

Create `scenes/main.tscn`:
- Node3D root
- Orbital camera (spherical coordinates: azimuth, elevation, distance)
- DirectionalLight3D for sun
- WorldEnvironment with sky
- Placeholder BoxMesh to verify 3D rendering

### 3. Camera Controls

3D orbital camera (`src/game/orbital_camera.gd`):
- Right-click drag to orbit (azimuth/elevation)
- WASD to pan relative to camera orientation
- Q/E for vertical movement
- Scroll wheel to zoom (proportional to distance)
- Shift+LMB drag to zoom (MacBook-friendly)
- Alt+LMB to orbit around point under cursor (3DS Max/Blender style)
- Middle-click drag to pan in camera plane
- Smooth interpolation via exponential lerp

```gdscript
# src/game/orbital_camera.gd
extends Node3D

var target: Vector3 = Vector3.ZERO
var azimuth: float = 45.0      # degrees, rotation around Y
var elevation: float = 30.0    # degrees, angle from horizontal
var distance: float = 200.0    # units from target

func _update_camera_position() -> void:
    var az_rad := deg_to_rad(azimuth)
    var el_rad := deg_to_rad(elevation)
    var offset := Vector3(
        sin(az_rad) * cos(el_rad),
        sin(el_rad),
        cos(az_rad) * cos(el_rad)
    ) * distance
    camera.global_position = target + offset
    camera.look_at(target, Vector3.UP)
```

### 4. Placeholder Block

Create a simple 6m BoxMesh in the scene:
- Verifies 3D rendering pipeline works
- Uses `CELL_SIZE = 6.0` from `grid_utils.gd`

---

## Acceptance Criteria

- [x] `project.godot` opens in Godot 4 without errors
- [x] Main scene runs without crashes
- [x] Can see placeholder 3D block in the viewport
- [x] Camera orbits with right-click drag
- [x] Camera pans with WASD
- [x] Camera zooms with scroll wheel
- [x] All folders created per structure
