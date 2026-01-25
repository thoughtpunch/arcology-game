#!/usr/bin/env bash
# setup-beads.sh - Initialize Beads with Arcology milestone tasks
# Run this once to populate the task database

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Arcology - Beads Setup                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check for bd
command -v bd >/dev/null 2>&1 || { 
    echo "Installing Beads..."
    curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
}

# Initialize if needed
if [ ! -d ".beads" ]; then
    echo -e "${YELLOW}Initializing Beads...${NC}"
    bd init --quiet
fi

echo -e "${BLUE}Creating epics...${NC}"

# Create Epics
bd create "Milestone 0 - Project Skeleton" -t epic -p 0 --description "Basic Godot project setup with camera controls" 2>/dev/null || true
bd create "Milestone 1 - Grid & Blocks" -t epic -p 0 --description "Core grid system and block placement" 2>/dev/null || true
bd create "Milestone 2 - Floor Navigation" -t epic -p 1 --description "Vertical floor switching and visibility" 2>/dev/null || true
bd create "Milestone 3 - Connectivity" -t epic -p 1 --description "Block adjacency and path connectivity" 2>/dev/null || true

echo -e "${BLUE}Creating M0 tasks...${NC}"

# M0 Tasks
bd create "Create Godot project structure" -t task -p 0 --description "
Create project.godot with proper settings.
Create folder structure: src/, scenes/, assets/, data/.
Create main.tscn as entry scene.
Acceptance: Project opens in Godot 4 without errors." 2>/dev/null || true

bd create "Basic camera with pan/zoom" -t task -p 0 --description "
Implement Camera2D with:
- WASD/arrow keys for panning
- Mouse wheel for zoom (0.5x to 3x)
- Smooth movement with lerp
- Camera bounds to prevent infinite scroll
Acceptance: Camera pans and zooms smoothly with limits." 2>/dev/null || true

echo -e "${BLUE}Creating M1 tasks...${NC}"

# M1 Tasks
bd create "Grid data structure" -t task -p 1 --description "
Create Grid class (src/core/grid.gd) with:
- Sparse Dictionary[Vector3i, Block]
- get_block(pos), set_block(pos, block), remove_block(pos)
- grid_to_screen(Vector3i) -> Vector2 conversion
- TILE_WIDTH=64, TILE_HEIGHT=32, FLOOR_HEIGHT=24
Acceptance: Can store/retrieve blocks by 3D position." 2>/dev/null || true

bd create "Block base class" -t task -p 1 --description "
Create Block class (src/core/block.gd) with:
- grid_position: Vector3i
- block_type: String
- Signals: block_placed, block_removed
Acceptance: Block instances can be created with position and type." 2>/dev/null || true

bd create "Block registry with JSON loading" -t task -p 1 --description "
Create BlockRegistry singleton (src/core/block_registry.gd):
- Loads data/blocks.json at startup
- get_block_data(type_id) -> Dictionary
- Create data/blocks.json with 4 types: corridor, residential, commercial, industrial
Acceptance: Can query block properties by type ID." 2>/dev/null || true

bd create "Placeholder block sprites" -t task -p 2 --description "
Create 64x64 isometric placeholder sprites:
- corridor: gray
- residential: blue
- commercial: green  
- industrial: orange
Save to assets/sprites/blocks/{type}.png
Acceptance: 4 colored placeholder sprites exist." 2>/dev/null || true

bd create "Render blocks isometrically" -t task -p 1 --description "
Create BlockRenderer (src/core/block_renderer.gd):
- Iterates Grid, creates Sprite2D for each block
- Uses grid_to_screen() for positioning
- Y-sorting for proper depth
- Z-level offset for floors
Acceptance: Blocks render at correct isometric positions." 2>/dev/null || true

bd create "Click to place blocks" -t task -p 1 --description "
Implement block placement:
- screen_to_grid() conversion (inverse of grid_to_screen)
- Left-click places current block type at mouse position
- Uses current floor level for Z
- Ghost preview before placement
Acceptance: Can click to place blocks on the grid." 2>/dev/null || true

bd create "Right-click to remove blocks" -t task -p 2 --description "
Implement block removal:
- Right-click removes block at cursor position
- Emits block_removed signal
- Updates renderer
Acceptance: Can right-click to remove placed blocks." 2>/dev/null || true

bd create "Simple block picker UI" -t task -p 2 --description "
Create UI for block selection:
- HBoxContainer with 4 buttons (one per block type)
- Visual feedback for selected type
- Keyboard shortcuts 1-4
Acceptance: Can select block type via UI or keyboard." 2>/dev/null || true

echo -e "${BLUE}Creating M2 tasks...${NC}"

# M2 Tasks
bd create "Floor level tracking" -t task -p 2 --description "
Add current_floor state:
- Global or GameState singleton with current_floor: int
- UI label showing current floor
- Min floor 0, max floor 10 initially
Acceptance: Game tracks and displays current floor." 2>/dev/null || true

bd create "Floor navigation controls" -t task -p 2 --description "
Add floor switching:
- Up/Down buttons in UI
- Page Up/Page Down keyboard shortcuts
- Clamp to valid range
Acceptance: Can switch floors with UI and keyboard." 2>/dev/null || true

bd create "Floor visibility system" -t task -p 2 --description "
Implement floor rendering rules:
- Current floor: 100% opacity
- Floor below (Z-1): 50% opacity
- Two below (Z-2): 25% opacity
- Floors above current: hidden
- Update when floor changes
Acceptance: Floors fade by depth, above floors hidden." 2>/dev/null || true

echo -e "${BLUE}Creating M3 tasks...${NC}"

# M3 Tasks
bd create "Adjacency detection" -t task -p 2 --description "
Add Grid.get_neighbors(pos: Vector3i) -> Array[Vector3i]:
- Returns 6 directions: +X, -X, +Y, -Y, +Z, -Z
- Only returns positions that have blocks
Acceptance: Can query adjacent blocks in 6 directions." 2>/dev/null || true

bd create "Entrance block and connectivity" -t task -p 2 --description "
Add entrance block type and connectivity:
- New block type 'entrance' at Z=0 only
- Add 'connected' boolean to Block class
- Flood-fill from entrance marks reachable blocks
- Recalculate on block add/remove
Acceptance: Blocks reachable from entrance marked connected." 2>/dev/null || true

bd create "Visual indicator for unconnected blocks" -t task -p 3 --description "
Show disconnected blocks visually:
- Red tint or warning icon on unconnected blocks
- Toggle overlay on/off with key (C for connectivity)
Acceptance: Can see which blocks are not connected." 2>/dev/null || true

bd create "Stairs block for vertical connectivity" -t task -p 3 --description "
Add stairs block type:
- Connects Z to Z+1 (spans two floors)
- Flood-fill traverses stairs vertically
- Visual shows connection between floors
Acceptance: Stairs allow vertical connectivity in flood-fill." 2>/dev/null || true

echo -e "${BLUE}Setting up dependencies...${NC}"

# Get task IDs (they'll be hash-based like bd-a1b2)
# We'll use title matching to find them

# Function to get task ID by title substring
get_task_id() {
    bd list --json 2>/dev/null | jq -r ".[] | select(.title | contains(\"$1\")) | .id" | head -1
}

# Set up dependency chain for M0
PROJ_STRUCT=$(get_task_id "Godot project structure")
CAMERA=$(get_task_id "camera with pan/zoom")
if [ -n "$PROJ_STRUCT" ] && [ -n "$CAMERA" ]; then
    bd dep add "$CAMERA" "$PROJ_STRUCT" 2>/dev/null || true
fi

# M1 depends on M0
GRID=$(get_task_id "Grid data structure")
if [ -n "$GRID" ] && [ -n "$CAMERA" ]; then
    bd dep add "$GRID" "$CAMERA" 2>/dev/null || true
fi

BLOCK_BASE=$(get_task_id "Block base class")
if [ -n "$BLOCK_BASE" ] && [ -n "$GRID" ]; then
    bd dep add "$BLOCK_BASE" "$GRID" 2>/dev/null || true
fi

REGISTRY=$(get_task_id "Block registry")
if [ -n "$REGISTRY" ] && [ -n "$BLOCK_BASE" ]; then
    bd dep add "$REGISTRY" "$BLOCK_BASE" 2>/dev/null || true
fi

SPRITES=$(get_task_id "Placeholder block sprites")
if [ -n "$SPRITES" ] && [ -n "$REGISTRY" ]; then
    bd dep add "$SPRITES" "$REGISTRY" 2>/dev/null || true
fi

RENDER=$(get_task_id "Render blocks isometrically")
if [ -n "$RENDER" ] && [ -n "$SPRITES" ]; then
    bd dep add "$RENDER" "$SPRITES" 2>/dev/null || true
fi

PLACE=$(get_task_id "Click to place")
if [ -n "$PLACE" ] && [ -n "$RENDER" ]; then
    bd dep add "$PLACE" "$RENDER" 2>/dev/null || true
fi

REMOVE=$(get_task_id "Right-click to remove")
if [ -n "$REMOVE" ] && [ -n "$PLACE" ]; then
    bd dep add "$REMOVE" "$PLACE" 2>/dev/null || true
fi

PICKER=$(get_task_id "block picker UI")
if [ -n "$PICKER" ] && [ -n "$PLACE" ]; then
    bd dep add "$PICKER" "$PLACE" 2>/dev/null || true
fi

# M2 depends on M1
FLOOR_TRACK=$(get_task_id "Floor level tracking")
if [ -n "$FLOOR_TRACK" ] && [ -n "$RENDER" ]; then
    bd dep add "$FLOOR_TRACK" "$RENDER" 2>/dev/null || true
fi

FLOOR_NAV=$(get_task_id "Floor navigation controls")
if [ -n "$FLOOR_NAV" ] && [ -n "$FLOOR_TRACK" ]; then
    bd dep add "$FLOOR_NAV" "$FLOOR_TRACK" 2>/dev/null || true
fi

FLOOR_VIS=$(get_task_id "Floor visibility")
if [ -n "$FLOOR_VIS" ] && [ -n "$FLOOR_NAV" ]; then
    bd dep add "$FLOOR_VIS" "$FLOOR_NAV" 2>/dev/null || true
fi

# M3 depends on M2
ADJACENCY=$(get_task_id "Adjacency detection")
if [ -n "$ADJACENCY" ] && [ -n "$FLOOR_VIS" ]; then
    bd dep add "$ADJACENCY" "$FLOOR_VIS" 2>/dev/null || true
fi

ENTRANCE=$(get_task_id "Entrance block")
if [ -n "$ENTRANCE" ] && [ -n "$ADJACENCY" ]; then
    bd dep add "$ENTRANCE" "$ADJACENCY" 2>/dev/null || true
fi

UNCONNECTED=$(get_task_id "unconnected blocks")
if [ -n "$UNCONNECTED" ] && [ -n "$ENTRANCE" ]; then
    bd dep add "$UNCONNECTED" "$ENTRANCE" 2>/dev/null || true
fi

STAIRS=$(get_task_id "Stairs block")
if [ -n "$STAIRS" ] && [ -n "$ENTRANCE" ]; then
    bd dep add "$STAIRS" "$ENTRANCE" 2>/dev/null || true
fi

# Sync to git
bd sync 2>/dev/null || true

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Beads setup complete!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Tasks created:"
bd list --json 2>/dev/null | jq 'length'
echo ""
echo "Ready to work on:"
bd ready
echo ""
echo "Run Ralph with: ./scripts/ralph/ralph-beads.sh"
