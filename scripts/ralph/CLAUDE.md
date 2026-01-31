# Arcology - Ralph Agent Instructions (Beads Edition)

You are an autonomous coding agent building the Arcology game in Godot 4.
Use `bd` (Beads) for task tracking instead of prd.json.

## Knowledge Base

**All project documentation is in `documentation/`:**
- `documentation/README.md` - Entry point
- `documentation/INDEX.md` - Searchable A-Z index
- `documentation/architecture/` - Build milestones
- `documentation/quick-reference/` - Formulas, conventions, 3D math
- `documentation/game-design/` - Blocks, environment, agents, economy

## Your Task (One Iteration)

**NOTE:** The bash loop (`ralph-beads.sh`) assigns you ONE task. Work on ONLY that task.

1. Read `scripts/ralph/progress.txt` for codebase patterns (check **Codebase Patterns** section first)
2. **Consult `documentation/` for implementation details**
3. Check you're on the correct branch. If not, check it out or create from `main`
4. Claim the assigned task: `bd update <id> --status in_progress`
5. Implement that **single** task
6. **Write tests** (positive AND negative assertions)
7. Run quality checks (see below)
8. **⚠️ MANDATORY: Commit with ticket ID:** `git commit -m "feat: arcology-x0d.1 - Title"`
9. **⚠️ MANDATORY: Back-link commit SHA to ticket:**
    ```bash
    SHA=$(git rev-parse HEAD)
    bd comments add <id> "Commit: $SHA"
    ```
10. Run post-task hook: `./scripts/hooks/post-task.sh <id>` (blocks if no commit or no comment!)
11. **⚠️ MANDATORY: Add completion comment** (see Completion Comment Format below)
12. Close task: `bd close <id> --reason "Implemented"`
13. Sync: `./scripts/hooks/bd-sync-rich.sh`
14. Append learnings to `scripts/ralph/progress.txt`
15. **STOP** — The bash loop will assign the next task. Do NOT check for more work yourself.

## Completion Comment Format

**Before closing a ticket**, add a detailed completion comment:

```bash
bd comment <ticket-id> "$(cat <<'EOF'
## Completion Summary

**Completed:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

### What Was Done
- <Specific change 1>
- <Specific change 2>
- Files modified: <list them>

### What Was Left Undone / Deferred
- <Any scope cut, edge cases not handled, or "None - full scope implemented">

### Gotchas / Notes for Future Work
- <Anything surprising, patterns to document, assumptions made>

### Test Coverage
- <Tests added, manual testing done>
EOF
)"
```

This is MANDATORY for every ticket closure.

## Beads Commands Reference

```bash
# Get ready (unblocked) tasks as JSON
bd ready --json

# Get task details
bd show bd-abc123 --json

# Update status
bd update bd-abc123 --status in_progress

# Close completed task
bd close bd-abc123 --reason "Implemented and tested"

# Create new discovered task
bd create "Fix bug found during implementation" --priority 1 --discovered-from bd-abc123

# Add dependency (A blocked by B)
bd dep add bd-A bd-B

# Sync to git (rich commit messages)
./scripts/hooks/bd-sync-rich.sh
```

## Stop Conditions

**IMPORTANT:** The bash loop (`ralph-beads.sh`) handles task selection and iteration.
You are given ONE task per iteration. Do NOT check for more work yourself.
Do NOT output `<promise>COMPLETE</promise>` — the bash script handles completion detection.

**Stuck on your assigned task?** If you cannot complete the task after 3 attempts:
1. Add comment: `bd comments add <id> "Blocked: <reason>"`
2. Mark blocked: `bd update <id> --status blocked`
3. Output: `<ralph>STUCK</ralph>`

The bash loop will then try the next task or report that all tasks are blocked.

## Project Context

**What is Arcology?**
A 3D city-builder in Godot 4 where players build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Key Files:**
- `CLAUDE.md` - Quick project context
- `documentation/` - Full wiki-style knowledge base
- `documentation/architecture/` - Build milestones and patterns
- `documentation/quick-reference/` - Formulas, conventions, 3D math
- `documentation/INDEX.md` - Searchable A-Z index
- `scripts/ralph/progress.txt` - Learnings from previous iterations

**Tech Stack:**
- Godot 4.x with Vulkan / Forward+ renderer
- GDScript (primary)
- 3D procedural geometry (meshes, not sprites)
- Free orbital + orthographic snap camera

## ⚠️ MANDATORY: Commits Before Closing

**YOU MUST commit your work BEFORE closing any ticket.**

This is non-negotiable. The post-task hook will BLOCK ticket closure if no commits reference the ticket ID.

**Commit format:** `feat: <ticket-id> - <short description>`

Examples:
```bash
git add src/core/grid.gd test/test_grid.gd
git commit -m "feat: arcology-x0d.1 - Implement Grid class with 3D coordinate conversion"
```

Every commit MUST include the ticket ID (e.g., `arcology-x0d.1`) so work is traceable, just like Jira or GitHub issues.

## Quality Checks

Before closing a task, ensure:

### 1. Tests Required
**Every implementation MUST have tests:**

```gdscript
# test/test_<feature>.gd
extends SceneTree

func _init():
    # POSITIVE assertions - verify correct behavior
    assert(grid.get_block_at(pos) == expected_block, "Should return placed block")
    assert(grid.is_empty(empty_pos), "Empty position should return true")

    # NEGATIVE assertions - verify error handling
    assert(grid.get_block_at(invalid_pos) == null, "Invalid position should return null")
    assert(not grid.place_block(occupied_pos, block), "Should reject duplicate placement")

    quit()
```

**Test coverage requirements:**
- Positive assertions (happy path works)
- Negative assertions (edge cases handled)
- Unit tests for individual functions
- Integration tests for system interactions

### 2. ⚠️ MANDATORY: Run ALL Tests Before Closing

**You MUST run tests and fix any failures before closing a ticket:**

```bash
# Run the test for your feature
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/<category>/test_<feature>.gd

# Run related tests that might be affected
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/core/test_grid.gd

# If tests fail:
# 1. Fix the code
# 2. Re-run tests until they pass
# 3. If a test cannot be fixed, add a comment to the ticket:
#    bd comments add <ticket-id> "Test failure: <error message> - needs investigation"
```

**If tests are broken and cannot be fixed:**
- Do NOT close the ticket
- Add a comment with the exact error
- Mark ticket as blocked: `bd update <ticket-id> --status blocked`

### 3. Code Quality
```bash
# If Godot project exists:
# 1. Project opens without errors
# 2. Main scene runs without crashes
# 3. Tests pass (see above)

# For any code:
# - No syntax errors
# - Functions have type hints where reasonable
# - Classes have class_name declarations
```

### 4. Post-Task Hook
**ALWAYS run before closing:**
```bash
./scripts/hooks/post-task.sh <ticket-id>
```
This will ERROR if no commits reference the ticket.

## Codebase Conventions

```gdscript
# Coordinate system: Y-up (Godot default)
# X = East-West, Y = Vertical (up), Z = North-South

# Grid positions: always Vector3i
var grid_pos: Vector3i = Vector3i(5, 2, 3)  # cell at x=5, y=2 (2 floors up), z=3

# World positions: always Vector3 (grid_pos * CELL_SIZE)
var world_pos: Vector3 = Vector3(30.0, 12.0, 18.0)

# Classes: PascalCase
class_name BlockRegistry

# Functions/variables: snake_case
func get_block_at(pos: Vector3i) -> Block:
func grid_to_world(grid_pos: Vector3i) -> Vector3:

# Signals: past tense
signal block_placed(block)
signal resident_moved_in(resident)

# Constants: UPPER_SNAKE
const CELL_SIZE: float = 6.0    # 6m per cell (true cube)
const CHUNK_SIZE: int = 8       # 8×8×8 cells per chunk

# Face enum
enum CubeFace { TOP, BOTTOM, NORTH, SOUTH, EAST, WEST }
```

## Directory Structure

```
arcology/
├── project.godot
├── .beads/              # Beads database
│   ├── beads.db         # SQLite (local)
│   └── issues.jsonl     # Git-synced
├── src/
│   ├── phase0/          # Block stacking sandbox (current active code)
│   ├── core/            # Grid, blocks, placement, game state
│   ├── rendering/       # 3D block rendering, chunk manager
│   ├── blocks/          # Block type implementations
│   ├── environment/     # Light, air, noise, safety
│   ├── agents/          # Residents, needs, behavior trees
│   ├── transit/         # Pathfinding, elevators
│   ├── economy/         # Budget, rent
│   └── ui/              # HUD, overlays, menus, panels
├── scenes/              # phase0_sandbox.tscn, main.tscn
├── shaders/             # Ghost preview, face highlight, grid overlay
├── test/                # Unit and integration tests (mirrors src/ structure)
├── assets/              # Audio, fonts, sprites
├── data/
│   ├── blocks.json      # Block definitions
│   ├── terrain.json     # Terrain configuration
│   └── scenarios/       # Scenario presets
└── scripts/ralph/
    ├── ralph-beads.sh   # The bash loop
    ├── CLAUDE.md        # This file
    └── progress.txt     # Learnings log
```

## 3D Grid Math Reference

Blocks are 6m×6m×6m cubes on an orthogonal Y-up grid. See `src/phase0/grid_utils.gd` for canonical implementation.

```gdscript
const CELL_SIZE: float = 6.0  # 6m per cell in all axes

# Grid (integer cells) → World (meters)
static func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE

static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE + Vector3.ONE * (CELL_SIZE / 2.0)

# World (meters) → Grid (integer cells)
static func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CELL_SIZE)),
        int(floor(world_pos.y / CELL_SIZE)),
        int(floor(world_pos.z / CELL_SIZE))
    )
```

**Cell faces:** TOP (Y+), BOTTOM (Y-), NORTH (Z+), SOUTH (Z-), EAST (X+), WEST (X-)
**Chunks:** 8×8×8 cells grouped for rendering optimization
**3D Architecture Spec:** `documentation/architecture/3d-refactor/specification.md`

## Progress Log Format

After completing a task, append to `scripts/ralph/progress.txt`:

```
## Iteration [N] - [Date]
Task: bd-xxx - [Title]
Status: PASSED / FAILED
Changes:
- [file1]: [what changed]
- [file2]: [what changed]
Learnings:
- [anything future iterations should know]
Blockers:
- [if failed, why]
```

## Codebase Patterns Section

If you discover a reusable pattern, add it to **## Codebase Patterns** at TOP of `progress.txt`:

```
## Codebase Patterns
- Use Vector3i for grid positions (Y-up: x = east, y = up, z = north)
- CELL_SIZE = 6.0 (6m cubes), CHUNK_SIZE = 8 (8×8×8 cells)
- Blocks emit signals, systems connect to them
- Load balance numbers from data/balance.json, not hardcoded
- 3D meshes via procedural geometry (BoxMesh, etc.)
```

## Important Reminders

- **COMMIT BEFORE CLOSING** - You CANNOT close a ticket without committing. Format: `feat: arcology-x0d.1 - Title`
- **TESTS REQUIRED** - Every feature needs positive AND negative assertion tests
- **One task per iteration** - Don't try to do multiple
- **Use bd commands** - Not manual JSON editing
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates
- **Sync before done** - Always `./scripts/hooks/bd-sync-rich.sh` after closing tasks

## If Stuck

1. Check dependencies: `bd show bd-xxx --json` - is something blocking?
2. Check patterns in progress.txt
3. Check `documentation/architecture/` for implementation guidance
4. Check `documentation/quick-reference/` for formulas and conventions
5. Simplify: implement the minimal version that passes
6. Create sub-task: `bd create "Smaller piece" --discovered-from bd-xxx`
7. Document the blocker for next iteration
