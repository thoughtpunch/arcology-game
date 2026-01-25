# AGENTS.md - Arcology Codebase Guide

> This file is read automatically by AI coding tools (Claude Code, Amp, Cursor, etc.)
> Update it with patterns, conventions, and gotchas discovered during development.

## Project Overview

**Arcology** is a 3D isometric city-builder in Godot 4 where players build vertical megastructures and cultivate human flourishing.

**Key files to read first:**
- `CLAUDE.md` - Quick context for AI assistants
- `ARCHITECTURE.md` - Build plan with milestones
- `.beads/` - Beads task database (if using Beads)
- `scripts/ralph/prd.json` - User stories (if using prd.json)
- `scripts/ralph/progress.txt` - Learnings from previous iterations

## Tech Stack

- **Engine:** Godot 4.x
- **Language:** GDScript (primary), C# only if performance-critical
- **Art:** 16-bit isometric pixel art (64x32 tiles)

## Code Conventions

```gdscript
# Classes: PascalCase with class_name declaration
class_name BlockRegistry
extends Node

# Functions/variables: snake_case with type hints
func get_block_at(pos: Vector3i) -> Block:
    return blocks.get(pos)

# Signals: past tense
signal block_placed(block: Block)
signal resident_moved_in(resident: Resident)

# Constants: UPPER_SNAKE_CASE
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32
const FLOOR_HEIGHT: int = 24
```

## Directory Structure

```
arcology/
├── project.godot
├── CLAUDE.md              # AI context
├── ARCHITECTURE.md        # Build plan
├── AGENTS.md              # This file
├── src/
│   ├── core/              # Grid, Block, GameClock
│   ├── blocks/            # Block type implementations
│   ├── environment/       # Light, Air, Noise, Safety systems
│   ├── agents/            # Residents, Needs, Relationships
│   ├── transit/           # Pathfinding, Elevators
│   ├── economy/           # Budget, Rent
│   └── ui/                # HUD, Overlays, Menus
├── scenes/                # Godot .tscn files
├── assets/
│   └── sprites/blocks/    # Isometric block sprites
├── data/
│   ├── blocks.json        # Block definitions
│   └── balance.json       # Tuning numbers
└── scripts/ralph/         # Ralph autonomous loop files
    ├── ralph-beads.sh     # Beads-powered loop (recommended)
    ├── ralph.sh           # prd.json-powered loop (simpler)
    ├── setup-beads.sh     # Initialize Beads with tasks
    ├── CLAUDE-beads.md    # Prompt for Beads mode
    ├── CLAUDE.md          # Prompt for prd.json mode
    ├── prd.json           # User stories (Option B)
    └── progress.txt       # Learnings log
```

## Isometric Math

Standard 2:1 isometric projection:

```gdscript
const TILE_WIDTH = 64
const TILE_HEIGHT = 32
const FLOOR_HEIGHT = 24

func grid_to_screen(grid_pos: Vector3i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
    y -= grid_pos.z * FLOOR_HEIGHT  # Higher Z = higher on screen
    return Vector2(x, y)

func screen_to_grid(screen_pos: Vector2, z_level: int) -> Vector3i:
    var adjusted_y = screen_pos.y + z_level * FLOOR_HEIGHT
    var grid_x = (screen_pos.x / (TILE_WIDTH / 2) + adjusted_y / (TILE_HEIGHT / 2)) / 2
    var grid_y = (adjusted_y / (TILE_HEIGHT / 2) - screen_pos.x / (TILE_WIDTH / 2)) / 2
    return Vector3i(int(grid_x), int(grid_y), z_level)
```

## Data-Driven Design

**Never hardcode balance numbers.** Load from JSON:

```gdscript
# Load at runtime
var balance = load_json("res://data/balance.json")
var light_falloff = balance.light_falloff_per_floor  # e.g., 20
```

## Patterns Discovered

(Add patterns here as you discover them)

- Grid uses Dictionary with Vector3i keys for O(1) lookup
- Blocks emit signals when placed/removed; systems connect to grid signals
- Y-sorting handles depth; use `y_sort_enabled` on parent node

## Common Gotchas

(Add gotchas here as you encounter them)

- Remember to call `queue_free()` on removed block sprites
- Godot 4 uses `Vector3i` not `Vector3` for integer positions
- Check `project.godot` exists before assuming project is initialized

## Quality Checks

Before committing, ensure:
1. Godot project opens without errors
2. Main scene runs without crashes
3. No GDScript errors in Output panel
4. All modified files have type hints where reasonable

## How to Run Ralph

**Option A: Beads (Recommended for complex projects)**
```bash
cd arcology
./scripts/ralph/setup-beads.sh     # One-time: populate tasks
./scripts/ralph/ralph-beads.sh 25  # Run autonomous loop
```

Beads advantages:
- Dependency-aware (`bd ready` shows only unblocked tasks)
- Hash-based IDs (no merge conflicts with multiple agents)
- Git-synced (`.beads/issues.jsonl`)
- Agent can discover new work with `bd create --discovered-from`

**Option B: prd.json (Simpler, good for starting out)**
```bash
cd arcology
./scripts/ralph/ralph.sh 25  # Run up to 25 iterations
```

prd.json: Flat list of stories, agent marks `passes: true` when done.

Both approaches: Ralph autonomously works through tasks, committing as it goes.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
