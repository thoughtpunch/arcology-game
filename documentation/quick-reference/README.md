# Quick Reference

[← Back to Documentation](../README.md)

---

## Overview

Fast lookup tables for common development tasks.

---

## Contents

| Topic | Description | Link |
|-------|-------------|------|
| **Tech Stack** | Engine, language, tools | [tech-stack.md](./tech-stack.md) |
| **Code Conventions** | Naming, style, patterns | [code-conventions.md](./code-conventions.md) |
| **Isometric Math** | *(superseded)* Old 2D system | [isometric-math.md](./isometric-math.md) |
| **Formulas** | Game balance calculations | [formulas.md](./formulas.md) |
| **Glossary** | Term definitions | [glossary.md](./glossary.md) |

---

## Most Used

### Grid Constants

```gdscript
const CELL_SIZE: float = 6.0   # World units per grid cell
const GROUND_SIZE: int = 100   # Grid cells per ground dimension
const GROUND_DEPTH: int = 5    # Diggable ground layers
```

### Naming Conventions

| Type | Style | Example |
|------|-------|---------|
| Classes | PascalCase | `BlockRegistry` |
| Functions | snake_case | `get_block_at()` |
| Variables | snake_case | `current_floor` |
| Signals | past_tense | `block_placed` |
| Constants | UPPER_SNAKE | `CELL_SIZE` |

### Key Formulas

```
rent = base_rent * desirability * demand
desirability = light*0.2 + air*0.15 + quiet*0.15 + safety*0.15 + access*0.2 + vibes*0.15
```

---

## See Also

- [../architecture/](../architecture/) - Build milestones
- [../technical/](../technical/) - Implementation details
- [../game-design/](../game-design/) - Game systems
