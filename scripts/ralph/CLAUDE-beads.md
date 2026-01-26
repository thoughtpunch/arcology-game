# Arcology - Ralph Agent Instructions (Beads Edition)

You are an autonomous coding agent building the Arcology game in Godot 4.
Use `bd` (Beads) for task tracking instead of prd.json.

## Knowledge Base

**All project documentation is in `documentation/`:**
- `documentation/README.md` - Entry point
- `documentation/INDEX.md` - Searchable A-Z index
- `documentation/architecture/` - Build milestones
- `documentation/quick-reference/` - Formulas, conventions, isometric math
- `documentation/game-design/` - Blocks, environment, agents, economy

## Your Task (One Iteration)

1. Run `bd ready --json` to get unblocked tasks
2. Read `scripts/ralph/progress.txt` for codebase patterns (check **Codebase Patterns** section first)
3. **Consult `documentation/` for implementation details**
4. Check you're on the correct branch. If not, check it out or create from `main`
5. Pick the **highest priority** ready task (lowest P number = highest priority)
6. Update task: `bd update <id> --status in_progress`
7. Implement that **single** task
8. **Write tests** (positive AND negative assertions)
9. Run quality checks (see below)
10. **⚠️ MANDATORY: Commit with ticket ID:** `git commit -m "feat: arcology-x0d.1 - Title"`
11. Run post-task hook: `./scripts/hooks/post-task.sh <id>` (blocks if no commit!)
12. Close task: `bd close <id> --reason "Implemented"`
13. Sync: `bd sync`
14. Append learnings to `scripts/ralph/progress.txt`
15. Check for more work: `bd ready --json`

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

# Sync to git (export JSONL)
bd sync
```

## Stop Conditions

**All done?** If `bd ready --json` returns empty array `[]`, output exactly:
```
<promise>COMPLETE</promise>
```

**Stuck?** If a task fails 3+ times:
1. Add comment: `bd comment bd-xxx "Blocked: <reason>"`
2. Mark blocked: `bd update bd-xxx --status blocked`
3. Try next ready task
4. If ALL remaining tasks are blocked, output:
```
<ralph>STUCK</ralph>
```

## Project Context

**What is Arcology?**
A 3D isometric city-builder in Godot 4 where players build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Key Files:**
- `CLAUDE.md` - Quick project context
- `documentation/` - Full wiki-style knowledge base
- `documentation/architecture/` - Build milestones and patterns
- `documentation/quick-reference/` - Formulas, conventions, isometric math
- `documentation/INDEX.md` - Searchable A-Z index
- `scripts/ralph/progress.txt` - Learnings from previous iterations

**Tech Stack:**
- Godot 4.x
- GDScript (primary)
- 16-bit isometric pixel art

## ⚠️ MANDATORY: Commits Before Closing

**YOU MUST commit your work BEFORE closing any ticket.**

This is non-negotiable. The post-task hook will BLOCK ticket closure if no commits reference the ticket ID.

**Commit format:** `feat: <ticket-id> - <short description>`

Examples:
```bash
git add src/core/grid.gd test/test_grid.gd
git commit -m "feat: arcology-x0d.1 - Implement Grid class with isometric conversion"
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

### 2. Code Quality
```bash
# If Godot project exists:
# 1. Project opens without errors
# 2. Main scene runs without crashes
# 3. Tests pass: godot --headless -s test/test_<feature>.gd

# For any code:
# - No syntax errors
# - Functions have type hints where reasonable
# - Classes have class_name declarations
```

### 3. Post-Task Hook
**ALWAYS run before closing:**
```bash
./scripts/hooks/post-task.sh <ticket-id>
```
This will ERROR if no commits reference the ticket.

## Codebase Conventions

```gdscript
# Classes: PascalCase
class_name BlockRegistry

# Functions/variables: snake_case  
func get_block_at(pos: Vector3i) -> Block:

# Signals: past tense
signal block_placed(block)
signal resident_moved_in(resident)

# Constants: UPPER_SNAKE
const TILE_WIDTH = 64
```

## Directory Structure

```
arcology/
├── project.godot
├── .beads/              # Beads database
│   ├── beads.db         # SQLite (local)
│   └── issues.jsonl     # Git-synced
├── src/
│   ├── core/            # Grid, blocks, game clock
│   ├── blocks/          # Block type implementations
│   ├── environment/     # Light, air, noise, safety
│   ├── agents/          # Residents, needs, relationships
│   ├── transit/         # Pathfinding, elevators
│   ├── economy/         # Budget, rent
│   └── ui/              # HUD, overlays, menus
├── scenes/
├── assets/
│   └── sprites/blocks/  # Isometric block sprites
├── data/
│   ├── blocks.json      # Block definitions
│   └── balance.json     # Tuning numbers
└── scripts/ralph/
    ├── ralph-beads.sh   # The bash loop
    ├── CLAUDE.md        # This file
    └── progress.txt     # Learnings log
```

## Isometric Math Reference

Blocks are 3D cutaway cubes (top face + 2 walls) creating a hexagonal perimeter:

```gdscript
const TILE_WIDTH: int = 64    # Hexagon width / diamond width
const TILE_DEPTH: int = 32    # Diamond height (top face only)
const WALL_HEIGHT: int = 32   # Height of side faces
const FLOOR_HEIGHT: int = 32  # Visual offset per Z level (TILE_DEPTH + WALL_HEIGHT - overlap)

func grid_to_screen(grid_pos: Vector3i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_DEPTH / 2)
    y -= grid_pos.z * FLOOR_HEIGHT
    return Vector2(x, y)
```

**Sprite dimensions:** 64x64 pixels (hexagonal with top diamond + left/right walls)

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
- Use Vector3i for grid positions (x, y = horizontal, z = floor)
- Blocks emit signals, systems connect to them
- Load balance numbers from data/balance.json, not hardcoded
- Sprites go in assets/sprites/blocks/{category}/
```

## Important Reminders

- **COMMIT BEFORE CLOSING** - You CANNOT close a ticket without committing. Format: `feat: arcology-x0d.1 - Title`
- **TESTS REQUIRED** - Every feature needs positive AND negative assertion tests
- **One task per iteration** - Don't try to do multiple
- **Use bd commands** - Not manual JSON editing
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates
- **Sync before done** - Always `bd sync` after closing tasks

## If Stuck

1. Check dependencies: `bd show bd-xxx --json` - is something blocking?
2. Check patterns in progress.txt
3. Check `documentation/architecture/` for implementation guidance
4. Check `documentation/quick-reference/` for formulas and conventions
5. Simplify: implement the minimal version that passes
6. Create sub-task: `bd create "Smaller piece" --discovered-from bd-xxx`
7. Document the blocker for next iteration
