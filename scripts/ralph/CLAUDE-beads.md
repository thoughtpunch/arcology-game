# Arcology - Ralph Agent Instructions (Beads Edition)

You are an autonomous coding agent building the Arcology game in Godot 4.
Use `bd` (Beads) for task tracking instead of prd.json.

## Your Task (One Iteration)

1. Run `bd ready --json` to get unblocked tasks
2. Read `scripts/ralph/progress.txt` for codebase patterns (check **Codebase Patterns** section first)
3. Check you're on the correct branch. If not, check it out or create from `main`
4. Pick the **highest priority** ready task (lowest P number = highest priority)
5. Update task: `bd update <id> --status in_progress`
6. Implement that **single** task
7. Run quality checks (see below)
8. If checks pass, commit ALL changes with message: `feat: <bd-id> - <title>`
9. Close task: `bd close <id> --reason "Implemented"`
10. Sync: `bd sync`
11. Append learnings to `scripts/ralph/progress.txt`
12. Check for more work: `bd ready --json`

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
- `ARCHITECTURE.md` - Build milestones and patterns
- `scripts/ralph/progress.txt` - Learnings from previous iterations

**Tech Stack:**
- Godot 4.x
- GDScript (primary)
- 16-bit isometric pixel art

## Quality Checks

Before closing a task, ensure:

```bash
# If Godot project exists:
# 1. Project opens without errors
# 2. Main scene runs without crashes
# 3. No GDScript errors (check Output panel)

# For any code:
# - No syntax errors
# - Functions have type hints where reasonable
# - Classes have class_name declarations
```

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

```gdscript
const TILE_WIDTH = 64
const TILE_HEIGHT = 32
const FLOOR_HEIGHT = 24

func grid_to_screen(grid_pos: Vector3i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
    y -= grid_pos.z * FLOOR_HEIGHT
    return Vector2(x, y)
```

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

- **One task per iteration** - Don't try to do multiple
- **Use bd commands** - Not manual JSON editing
- **Small commits** - Each task = one commit with bd-id
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates
- **Sync before done** - Always `bd sync` after closing tasks

## If Stuck

1. Check dependencies: `bd show bd-xxx --json` - is something blocking?
2. Check patterns in progress.txt
3. Check ARCHITECTURE.md for implementation guidance
4. Simplify: implement the minimal version that passes
5. Create sub-task: `bd create "Smaller piece" --discovered-from bd-xxx`
6. Document the blocker for next iteration
