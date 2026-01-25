# Arcology - Ralph Agent Instructions

You are an autonomous coding agent building the Arcology game in Godot 4.

## Your Task (One Iteration)

1. Read the PRD at `scripts/ralph/prd.json`
2. Read the progress log at `scripts/ralph/progress.txt` (check **Codebase Patterns** section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from `main`
4. Pick the **highest priority** user story where `passes: false`
5. Implement that **single** user story
6. Run quality checks (see below)
7. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
8. Update `scripts/ralph/prd.json` to set `passes: true` for the completed story
9. Append learnings to `scripts/ralph/progress.txt`
10. If ALL stories now have `passes: true`, output: `<promise>COMPLETE</promise>`

## Stop Conditions

**All done?** If ALL user stories have `passes: true`, output exactly:
```
<promise>COMPLETE</promise>
```

**Stuck?** If you've failed the same story 3+ times and cannot proceed:
1. Add `"blocked": true` and `"blockedReason": "..."` to the story in prd.json
2. Try the next story
3. If ALL remaining stories are blocked, output:
```
<ralph>STUCK</ralph>
```

## Project Context

**What is Arcology?**
A 3D isometric city-builder in Godot 4 where players build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Key Files:**
- `CLAUDE.md` - Quick project context
- `ARCHITECTURE.md` - Build milestones and patterns
- `docs/arcology-prd.md` - Full design spec (reference)

**Tech Stack:**
- Godot 4.x
- GDScript (primary)
- 16-bit isometric pixel art

## Quality Checks

Before committing, ensure:

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
├── src/
│   ├── core/           # Grid, blocks, game clock
│   ├── blocks/         # Block type implementations
│   ├── environment/    # Light, air, noise, safety
│   ├── agents/         # Residents, needs, relationships
│   ├── transit/        # Pathfinding, elevators
│   ├── economy/        # Budget, rent
│   └── ui/             # HUD, overlays, menus
├── scenes/
├── assets/
│   └── sprites/blocks/ # Isometric block sprites
├── data/
│   ├── blocks.json     # Block definitions
│   └── balance.json    # Tuning numbers
└── scripts/ralph/
    ├── prd.json        # Current user stories
    └── progress.txt    # Learnings log
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

After completing a story, append to `scripts/ralph/progress.txt`:

```
## Iteration [N] - [Date]
Story: [Story ID] - [Title]
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

If you discover a reusable pattern, add it to the **## Codebase Patterns** section at the TOP of `progress.txt`:

```
## Codebase Patterns
- Use Vector3i for grid positions (x, y = horizontal, z = floor)
- Blocks emit signals, systems connect to them
- Load balance numbers from data/balance.json, not hardcoded
- Sprites go in assets/sprites/blocks/{category}/
```

## Important Reminders

- **One story per iteration** - Don't try to do multiple
- **Small commits** - Each story = one commit
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates
- **Check ARCHITECTURE.md** for the current milestone scope
- If a story is too big, note it in progress.txt and mark as blocked

## If Stuck

1. Check if the story depends on unfinished work → mark blocked
2. Check ARCHITECTURE.md for implementation guidance
3. Check existing code patterns in progress.txt
4. Simplify: implement the minimal version that passes
5. Document the blocker clearly for the next iteration
