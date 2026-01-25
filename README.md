# Arcology

A 3D isometric city-builder where you build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

## Quick Start

| Audience | Start Here |
|----------|------------|
| **AI Agents (Claude, etc.)** | [CLAUDE.md](./CLAUDE.md) |
| **Documentation** | [documentation/](./documentation/README.md) |
| **Ralph Agent** | [documentation/agents/ralph/](./documentation/agents/ralph/) |

## Documentation

All project knowledge is in the **[documentation/](./documentation/)** folder:

- **[INDEX.md](./documentation/INDEX.md)** - Searchable A-Z index
- **[quick-reference/](./documentation/quick-reference/)** - Formulas, conventions, isometric math
- **[architecture/](./documentation/architecture/)** - Build milestones
- **[game-design/](./documentation/game-design/)** - Blocks, environment, agents, economy
- **[technical/](./documentation/technical/)** - Data model, simulation tick
- **[agents/](./documentation/agents/)** - AI agent instructions

## Tech Stack

| What | Choice |
|------|--------|
| Engine | Godot 4.x |
| Language | GDScript |
| Art | 16-bit isometric pixel art |
| Data | JSON configs |

## Core Concept

**Win condition:** Not profit. Not population. **Eudaimonia** (human flourishing).

You fight two enemies:
- **Entropy**: Everything decays
- **Human Nature**: NIMBYism, tribalism, short-term thinking

## Project Structure

```
arcology/
├── CLAUDE.md              # AI agent quick reference
├── documentation/         # Wiki-style knowledge base
├── src/                   # Game code
├── scenes/                # Godot scenes
├── assets/                # Sprites, audio
├── data/                  # JSON configs
└── scripts/ralph/         # Ralph agent runtime files
```
