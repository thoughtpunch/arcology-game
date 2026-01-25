# Tech Stack

## Core Technologies

| Layer | Choice | Why |
|-------|--------|-----|
| Engine | Godot 4.x | Open source, great 2D/isometric, GDScript is easy |
| Primary Language | GDScript | Fast iteration, Godot-native |
| Performance-Critical | C# or GDExtension | Only if/when needed |
| Data Format | JSON (saves), Resources (runtime) | Human-readable, Godot-native |
| Art Pipeline | Aseprite → PNG → Godot Import | Industry standard for pixel art |

## Art Specifications

- **Style:** 16-bit isometric pixel art
- **Tile dimensions:** 64×32 pixels (2:1 ratio)
- **Floor height:** 24 pixels visual height per Z level
- **Inspiration:** Classic Fallout, SimCity 2000

## Target Platforms

- **Primary:** PC (Steam), Mac, Linux
- **Potential:** Tablet (mobile port)

## Project Structure

```
arcology/
├── project.godot
├── CLAUDE.md                    # Context for AI assistants
│
├── src/
│   ├── core/
│   │   ├── grid.gd              # 3D voxel grid management
│   │   ├── block.gd             # Base block class
│   │   ├── block_registry.gd    # Block type definitions
│   │   └── game_clock.gd        # Time simulation
│   │
│   ├── blocks/                  # Block type implementations
│   ├── environment/             # Light, air, noise, safety
│   ├── agents/                  # Residents, needs, relationships
│   ├── transit/                 # Pathfinding, elevators
│   ├── economy/                 # Budget, rent
│   └── ui/                      # HUD, overlays, menus
│
├── scenes/
│   ├── main.tscn
│   ├── arcology.tscn            # The main game world
│   ├── blocks/                  # Block scenes
│   └── ui/                      # UI scenes
│
├── assets/
│   ├── sprites/
│   │   ├── blocks/              # Isometric block sprites
│   │   ├── ui/
│   │   └── portraits/
│   ├── audio/
│   └── fonts/
│
├── data/
│   ├── blocks.json              # Block definitions
│   ├── scenarios.json
│   └── balance.json             # Tuning numbers
│
└── documentation/               # This documentation
```

## Dependencies

- **Godot 4.x** - Engine (no external plugins required for core)
- **GUT** - Godot Unit Testing (optional, for tests)

## Performance Targets

| Scale | Blocks | Population | Target FPS |
|-------|--------|------------|------------|
| Small | ~1,000 | ~5,000 | 60 |
| Medium | ~5,000 | ~25,000 | 60 |
| Large | ~20,000 | ~100,000 | 30+ |
