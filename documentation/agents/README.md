# AI Agent Instructions

[← Back to Documentation](../README.md)

---

## Overview

Instructions for AI coding agents working on the Arcology project.

---

## Contents

| Agent | Description | Link |
|-------|-------------|------|
| **Ralph** | Autonomous iteration agent | [ralph/](./ralph/) |

### Ralph Quick Start

1. Get ready tasks: `bd ready --json`
2. Pick highest priority task
3. Implement it
4. Commit: `git commit -m "feat: <bd-id> - <title>"`
5. Close: `bd close <id> --reason "Done"`
6. Sync: `bd sync`
7. Repeat

---

## General Agent Guidance

### Read Order

1. **[../README.md](../README.md)** - Project overview
2. **[../architecture/](../architecture/)** - Current milestone
3. **Relevant game design docs** - What you're implementing

### Finding Information

1. Check **[../INDEX.md](../INDEX.md)** for specific topics
2. Use **[../quick-reference/](../quick-reference/)** for lookups
3. Check **milestone docs** for implementation steps

### Code Style

Follow **[../quick-reference/code-conventions.md](../quick-reference/code-conventions.md)**:
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Signals: past tense
- Constants: `UPPER_SNAKE`

### Data-Driven

Keep numbers in JSON, not code:
- `data/blocks.json` - Block definitions
- `data/balance.json` - Tuning numbers

### Quality Checks

Before committing:
1. Project opens without errors
2. Main scene runs without crashes
3. No GDScript errors
4. Type hints on functions

---

## Common Tasks

| Task | Reference |
|------|-----------|
| Add block type | [../game-design/blocks/](../game-design/blocks/) |
| Add environment system | [../game-design/environment/](../game-design/environment/) |
| Understand formulas | [../quick-reference/formulas.md](../quick-reference/formulas.md) |
| Check milestone scope | [../architecture/milestones/](../architecture/milestones/) |

---

## See Also

- [../README.md](../README.md) - Main documentation entry
- [../INDEX.md](../INDEX.md) - Searchable index
- [../architecture/](../architecture/) - Build milestones
