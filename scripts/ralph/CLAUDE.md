# Arcology - Ralph Agent Instructions

You are an autonomous coding agent building the Arcology game in Godot 4.

## ⚠️ MANDATORY: Documentation First

**BEFORE starting ANY task, you MUST:**
1. Run `./scripts/hooks/pre-task.sh <ticket-id>` to get required reading
2. READ all documentation files listed in the ticket comments
3. CHECK the milestone doc for acceptance criteria

**AFTER completing ANY task, you MUST:**
1. Run `./scripts/hooks/post-task.sh <ticket-id>` to verify implementation
2. VERIFY your implementation matches the acceptance criteria
3. ADD any new patterns to progress.txt

## Knowledge Base

**All project documentation is in `documentation/`:**
- `documentation/README.md` - Entry point
- `documentation/INDEX.md` - Searchable A-Z index
- `documentation/architecture/milestones/` - Build milestones with acceptance criteria
- `documentation/quick-reference/` - Formulas, conventions, isometric math
- `documentation/game-design/` - Blocks, environment, agents, economy

## Your Task (One Iteration)

1. Get next task: `bd ready --json | head -1`
2. **Run pre-task hook:** `./scripts/hooks/pre-task.sh <ticket-id>`
3. **READ the documentation** listed in the hook output
4. Read progress log: `scripts/ralph/progress.txt` (check **Codebase Patterns** first)
5. Mark in progress: `bd update <ticket-id> --status in_progress`
6. Implement that **single** task following the docs
7. Run quality checks (see below)
8. **Run post-task hook:** `./scripts/hooks/post-task.sh <ticket-id>`
9. If checks pass, commit: `git commit -m "feat: <ticket-id> - <title>"`
10. **⚠️ MANDATORY: Add completion comment** (see Completion Comment Format below)
11. Close task: `bd close <ticket-id> --reason "Implemented per docs"`
12. Sync: `bd sync`
13. Append learnings to `scripts/ralph/progress.txt`

## Completion Comment Format

**Before closing a ticket**, add a detailed completion comment with cycle time:

```bash
bd comments add <ticket-id> "$(cat <<'EOF'
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

This is **MANDATORY** for every ticket closure.

## Documentation Reference Pattern

Every ticket has a **📚 Required Reading** comment listing:
- Primary milestone doc (e.g., `milestone-1-grid-blocks.md`)
- Supporting docs (e.g., `core-concepts.md`, `isometric-math.md`)
- Specific sections to check (e.g., `#acceptance-criteria`)

**You MUST read these before implementing.**

## Stop Conditions

**All done?** If `bd ready --json` returns empty:
```
<promise>COMPLETE</promise>
```

**Stuck?** If you've failed the same task 3+ times:
1. Add comment: `bd comments add <id> "Blocked: <reason>"`
2. Try next task
3. If ALL remaining tasks are blocked:
```
<ralph>STUCK</ralph>
```

## Project Context

**What is Arcology?**
A 3D isometric city-builder in Godot 4 where players build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Key Documentation:**
- `documentation/architecture/milestones/` - WHAT to build, acceptance criteria
- `documentation/game-design/core-concepts.md` - HOW things work
- `documentation/quick-reference/isometric-math.md` - Coordinate math
- `documentation/game-design/blocks/` - Block catalog

**Tech Stack:**
- Godot 4.x
- GDScript (primary)
- 16-bit isometric pixel art

## Quality Checks

Before closing a task:

```bash
# 1. Run post-task hook to verify against docs
./scripts/hooks/post-task.sh <ticket-id>

# 2. If Godot project exists:
#    - Project opens without errors
#    - Main scene runs without crashes
#    - No GDScript errors

# 3. Code quality:
#    - No syntax errors
#    - Functions have type hints
#    - Classes have class_name declarations
```

## Codebase Conventions

See `documentation/quick-reference/code-conventions.md`

```gdscript
# Classes: PascalCase
class_name BlockRegistry

# Functions/variables: snake_case
func get_block_at(pos: Vector3i) -> Block:

# Signals: past tense
signal block_placed(block)

# Constants: UPPER_SNAKE
const TILE_WIDTH = 64
```

## Directory Structure

```
arcology/
├── documentation/         # 📚 READ THIS FIRST
│   ├── architecture/      # Milestones, patterns
│   ├── game-design/       # Blocks, systems
│   └── quick-reference/   # Formulas, conventions
├── project.godot
├── src/
│   ├── core/              # Grid, blocks, game clock
│   ├── blocks/            # Block type implementations
│   ├── environment/       # Light, air, noise, safety
│   └── ui/                # HUD, overlays, menus
├── scenes/
├── assets/sprites/blocks/ # Isometric block sprites
├── data/
│   ├── blocks.json        # Block definitions
│   └── balance.json       # Tuning numbers
└── scripts/
    ├── hooks/             # pre-task.sh, post-task.sh
    └── ralph/             # Agent files
```

## Progress Log Format

After completing a task, append to `scripts/ralph/progress.txt`:

```
## Iteration [N] - [Date]
Task: <ticket-id> - [Title]
Docs Read: [list of docs consulted]
Status: PASSED / FAILED
Changes:
- [file1]: [what changed]
Learnings:
- [anything future iterations should know]
```

## Important Reminders

- **DOCS FIRST** - Read documentation before writing code
- **COMPLETION COMMENT MANDATORY** - Add `bd comments add` before closing ANY ticket
- **One task per iteration** - Don't try to do multiple
- **Small commits** - Each task = one commit
- **Verify against docs** - Run post-task hook before closing
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates

## If Stuck

1. **Re-read the docs** - Answer is probably there
2. Check `documentation/INDEX.md` for the concept
3. Check `documentation/quick-reference/formulas.md` for calculations
4. Check existing code patterns in `progress.txt`
5. Simplify: implement the minimal version
6. Document the blocker clearly for the next iteration
