# Arcology Documentation

> **For AI assistants (Claude Code, etc.) and human developers**

## What Is Arcology?

A **3D city-builder** where you build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Core loop:** Build blocks → People move in → Meet their needs → Watch them flourish (or suffer)

**Win condition:** Not profit. Not population. **Eudaimonia** (human flourishing).

---

## Quick Navigation

| If you need... | Go to... |
|----------------|----------|
| Start building immediately | [Quick Reference](./quick-reference/) |
| Current development milestone | [Architecture](./architecture/) |
| How a game system works | [Game Design](./game-design/) |
| Technical implementation | [Technical](./technical/) |
| UI/UX specifications | [UI](./ui/) |
| Full searchable index | [INDEX.md](./INDEX.md) |

---

## Document Structure

```
documentation/
├── README.md                 ← You are here
├── INDEX.md                  ← Full searchable index
│
├── quick-reference/          ← Fast lookup for common tasks
│   ├── tech-stack.md
│   ├── code-conventions.md
│   ├── 3d-grid-math.md
│   ├── formulas.md
│   └── glossary.md
│
├── architecture/             ← How to build (iterative)
│   ├── README.md             ← Milestone overview
│   ├── milestones/           ← Individual milestone specs
│   ├── patterns.md
│   └── performance.md
│
├── game-design/              ← What to build (design spec)
│   ├── README.md
│   ├── core-concepts.md
│   ├── blocks/               ← Block catalog by category
│   ├── environment/          ← Light, air, noise, safety
│   ├── human-simulation/     ← Agents, needs, relationships
│   ├── economy/              ← Budget, rent, permits
│   ├── dynamics/             ← Entropy, human nature
│   ├── transit/              ← Corridors, elevators, pathfinding
│   └── scenarios.md
│
├── technical/                ← Implementation details
│   ├── README.md
│   ├── data-model.md
│   └── simulation-tick.md
│
├── ui/                       ← Interface specifications
│   ├── README.md
│   ├── views.md
│   ├── overlays.md
│   └── narrative.md
│
└── agents/                   ← AI agent instructions
    ├── README.md
    └── ralph/                ← Ralph autonomous agent
```

---

## Key Concepts (Memorize These)

### 1. Everything Is Cells
The world is a 3D orthogonal grid of **cells** (6m×6m×6m cubes). Every structure = blocks snapped to cell grid. Cells have 6 faces (TOP, BOTTOM, NORTH, SOUTH, EAST, WEST). Coordinate system is Y-up (X = east, Y = up, Z = north).

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

---

## Tech Stack

| What | Choice |
|------|--------|
| Engine | Godot 4.x |
| Renderer | Vulkan / Forward+ |
| Language | GDScript (C# for performance-critical) |
| Art | 3D blocks (procedural geometry, stylized realism) |
| Camera | Free orbital + orthographic snap modes |
| Data | JSON configs, Godot Resources |

---

## Current Development Phase

**Check [Architecture](./architecture/) for current milestone.**

**3D Architecture Reference:** [architecture/3d-refactor/specification.md](./architecture/3d-refactor/specification.md)

- Milestones 0-10 = Core game loop
- Milestones 11-22 = Depth features

---

## For AI Agents

1. **Start here** for context
2. **Check [INDEX.md](./INDEX.md)** to find specific topics
3. **Check [Architecture](./architecture/)** for build instructions
4. **Check [Quick Reference](./quick-reference/)** for code patterns

### Common Agent Tasks

| Task | Reference |
|------|-----------|
| Adding a block type | [blocks/README.md](./game-design/blocks/) |
| Adding environment system | [environment/README.md](./game-design/environment/) |
| Grid math (3D) | [3d-grid-math.md](./quick-reference/3d-grid-math.md), `src/phase0/grid_utils.gd` |
| Game formulas | [formulas.md](./quick-reference/formulas.md) |
| Code style | [code-conventions.md](./quick-reference/code-conventions.md) |

---

## Quick Links

- [Glossary](./quick-reference/glossary.md) - All game terms defined
- [Formulas](./quick-reference/formulas.md) - All calculations
- [3D Grid Math](./quick-reference/3d-grid-math.md) - Coordinate system, conversions
- [3D Refactor Spec](./architecture/3d-refactor/specification.md) - Full 3D architecture
- [Block Catalog](./game-design/blocks/) - All block types
- [Milestones](./architecture/milestones/) - Build order
