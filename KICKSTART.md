# Arcology Kickstart Prompt for Claude Code

Copy this entire prompt and paste it into Claude Code to bootstrap the project.

---

## Your Mission

You're starting development on **Arcology**, a 3D isometric city-builder in Godot 4. 

### Step 1: Setup

1. Install Beads if not present:
   ```bash
   command -v bd || curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
   ```

2. Initialize the project:
   ```bash
   mkdir -p arcology && cd arcology
   git init
   bd init --quiet
   ```

3. Read the project docs:
   - `arcology-prd.md` - Full PRD (skim sections 1-6 for architecture, Appendix A for block types)
   - `ARCHITECTURE.md` - Build plan with 10 milestones
   - `CLAUDE.md` - Quick reference

### Step 2: Create Beads from ARCHITECTURE.md

Read ARCHITECTURE.md and create beads for **Milestones 0-3 only** (the foundation). Create:

1. **4 Epics** (one per milestone):
   ```bash
   bd create "M0: Project Skeleton" -t epic -p 0
   bd create "M1: Grid & Blocks" -t epic -p 0  
   bd create "M2: Floor Navigation" -t epic -p 1
   bd create "M3: Connectivity" -t epic -p 1
   ```

2. **Tasks under each epic** with clear acceptance criteria. For example:
   ```bash
   bd create "Create Godot 4 project structure" -t task -p 0 \
     --description "Create project.godot, folder structure (src/, scenes/, assets/, data/), and main.tscn entry scene. Acceptance: Opens in Godot 4 without errors."
   ```

3. **Dependencies** between tasks:
   ```bash
   # Camera depends on project structure
   bd dep add <camera-id> <project-structure-id>
   ```

**Task sizing rule:** Each task should be completable in ~10-30 minutes. If bigger, split it.

### Step 3: Start Building

Once beads are created:

1. Check what's ready: `bd ready`
2. Pick the top task: `bd update <id> --status in_progress`
3. Implement it
4. Test it works
5. Commit: `git add -A && git commit -m "feat: <bd-id> - <title>"`
6. Close: `bd close <id> --reason "Implemented"`
7. Sync: `bd sync`
8. Repeat: `bd ready`

### Key Patterns from PRD

**Isometric math (memorize this):**
```gdscript
const TILE_WIDTH = 64
const TILE_HEIGHT = 32  
const FLOOR_HEIGHT = 24

func grid_to_screen(pos: Vector3i) -> Vector2:
    var x = (pos.x - pos.y) * (TILE_WIDTH / 2)
    var y = (pos.x + pos.y) * (TILE_HEIGHT / 2) - pos.z * FLOOR_HEIGHT
    return Vector2(x, y)
```

**Code conventions:**
- Classes: `class_name BlockRegistry` (PascalCase)
- Functions: `func get_block_at()` (snake_case)
- Signals: `signal block_placed` (past tense)
- Data in JSON, not hardcoded

**Directory structure:**
```
arcology/
├── project.godot
├── src/core/          # Grid, Block, GameState
├── src/ui/            # HUD, menus
├── scenes/            # .tscn files
├── assets/sprites/    # Isometric art
└── data/              # blocks.json, balance.json
```

### What Success Looks Like

After M0-M3 complete (~17 tasks), you'll have:
- Godot project with isometric camera
- Grid system with block placement/removal
- Floor navigation (up/down)
- Connectivity system (entrance + flood-fill)
- Stairs for vertical connections

Then move to M4 (Environmental Systems) and beyond.

---

## Quick Reference Commands

```bash
bd ready              # What can I work on?
bd ready --json       # Same, for scripting
bd show <id>          # Task details
bd list               # All tasks
bd list --status open # Open tasks only

bd update <id> --status in_progress
bd close <id> --reason "Done"
bd create "New task" -t task -p 1 --discovered-from <id>
bd dep add <blocked> <blocker>

bd sync               # Export to git
bd doctor --fix       # Fix issues
```

---

**GO!** Start with Step 1, then create the beads, then build.
