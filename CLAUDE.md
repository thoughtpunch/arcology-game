# CLAUDE.md - Arcology Project Guide

> **For AI assistants (Claude Code, etc.) working on this project**

## Quick Start

**Read these in order:**
1. **This file** - High-level context (you're here)
2. **[documentation/](./documentation/README.md)** - Full wiki-style knowledge base
3. **[documentation/architecture/](./documentation/architecture/)** - Build milestones

**Quick lookups:**
- [documentation/INDEX.md](./documentation/INDEX.md) - Searchable A-Z index
- [documentation/quick-reference/](./documentation/quick-reference/) - Formulas, conventions, math

## What Is Arcology?

A **3D isometric city-builder** where you build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Core loop:** Build blocks → People move in → Meet their needs → Watch them flourish (or suffer)

**Win condition:** Not profit. Not population. **Eudaimonia** (human flourishing).

## The 30-Second Pitch

You fight two enemies:
- **Entropy**: Everything decays—buildings, relationships, knowledge
- **Human Nature**: NIMBYism, tribalism, short-term thinking

Your tools: Architecture, infrastructure, community spaces.

## Tech Stack

| What | Choice |
|------|--------|
| Engine | Godot 4.x |
| Language | GDScript (C# for performance-critical) |
| Art | 16-bit isometric pixel art |
| Data | JSON configs, Godot Resources |

## Key Concepts (Memorize These)

### 1. Everything Is Blocks
The world is a 3D voxel grid. Every structure = blocks snapped to grid.

### 2. Public vs Private Blocks
- **Private** (apartment, restaurant): Pathfinding goes TO it
- **Public** (food hall, atrium, corridor): Pathfinding goes THROUGH it

### 3. Crime Doesn't Climb
Upper floors are naturally safer. This creates organic social geography.

### 4. Light Is Infrastructure
Sunlight is harvested and piped like electricity. Deep interiors need light pipes.

### 5. Five Human Needs
```
PURPOSE     → meaning, growth
ESTEEM      → respect, status  
BELONGING   → relationships
SAFETY      → security
SURVIVAL    → food, shelter, health
```
Lower needs must be met before higher ones matter.

## File Map

```
arcology/
├── CLAUDE.md              ← You are here (context)
├── documentation/         ← Wiki-style knowledge base
│   ├── README.md          ← Documentation entry point
│   ├── INDEX.md           ← Searchable A-Z index
│   ├── quick-reference/   ← Formulas, conventions, math
│   ├── architecture/      ← Build milestones (0-10+)
│   ├── game-design/       ← Blocks, environment, agents, economy
│   ├── technical/         ← Data model, simulation tick
│   ├── ui/                ← Views, overlays, narrative
│   └── agents/            ← AI agent instructions (Ralph)
├── src/                   ← Game code
├── scenes/                ← Godot scenes
├── assets/                ← Sprites, audio
└── data/                  ← JSON configs (blocks, balance)
```

## Current Development Phase

**Check [documentation/architecture/](./documentation/architecture/) for current milestone.**

Milestones 1-10 = Core game loop
Milestones 11-22 = Depth features

## Code Conventions

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

## Common Tasks

### Adding a Block Type
1. Add to `data/blocks.json`
2. Create sprite in `assets/sprites/blocks/`
3. If special behavior needed, create script in `src/blocks/`

### Adding an Environment System
1. Create `src/environment/{system}_system.gd`
2. Connect to `block_placed`/`block_removed` signals
3. Store calculated values on `block.environment.{property}`

### Adding UI
1. Create scene in `scenes/ui/`
2. Script in `src/ui/`
3. Connect to game signals, don't poll

## Data-Driven Philosophy

**Keep numbers out of code:**

```json
// data/balance.json
{
  "light_falloff_per_floor": 20,
  "residential_rent_base": 100
}
```

```gdscript
# Load at runtime
var balance = load_json("res://data/balance.json")
var falloff = balance.light_falloff_per_floor
```

## When You're Stuck

1. Check [documentation/architecture/](./documentation/architecture/) for the current milestone scope
2. Simplify—cut the feature in half
3. Hardcode first, data-drive later
4. Check [documentation/quick-reference/formulas.md](./documentation/quick-reference/formulas.md) for formulas
5. Ask: "Does this need to exist in Milestone N?"

## Key Formulas (Quick Reference)

```
rent = base_rent × desirability × demand

desirability = (light×0.2 + air×0.15 + quiet×0.15 + safety×0.15 + access×0.2 + vibes×0.15)

flourishing = f(survival, safety, belonging, esteem, purpose)
  // Lower needs gate higher ones

AEI = individual(40%) + community(25%) + sustainability(20%) + resilience(15%)
```

## Don't Forget

- [ ] Blocks are load-bearing (CNC-U material, no structural engineering needed)
- [ ] Cantilevers max 1-2 units in gravity scenarios
- [ ] All environment values propagate (not magic radius)
- [ ] Notable residents (500) get full sim; rest are statistical
- [ ] Overlays: light, air, noise, safety, traffic

---

**Now explore [documentation/](./documentation/README.md) for the full knowledge base.**
