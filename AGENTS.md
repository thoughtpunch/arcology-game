# AGENTS.md - Living Codebase Guide

> This file is read automatically by AI coding tools (Claude Code, Amp, Cursor, etc.)
> **Update this with patterns and gotchas discovered during development.**

## Start Here

| Resource | Link |
|----------|------|
| **Full Knowledge Base** | [documentation/](./documentation/README.md) |
| **Searchable Index** | [documentation/INDEX.md](./documentation/INDEX.md) |
| **Quick Reference** | [documentation/quick-reference/](./documentation/quick-reference/) |
| **Architecture** | [documentation/architecture/](./documentation/architecture/) |
| **Ralph Agent** | [documentation/agents/ralph/](./documentation/agents/ralph/) |

---

## Patterns Discovered

> Add patterns here as you discover them during development.

- Grid uses Dictionary with Vector3i keys for O(1) lookup
- Blocks emit signals when placed/removed; systems connect to grid signals
- Y-sorting handles depth; use `y_sort_enabled` on parent node

---

## Common Gotchas

> Add gotchas here as you encounter them during development.

- Remember to call `queue_free()` on removed block sprites
- Godot 4 uses `Vector3i` not `Vector3` for integer positions
- Check `project.godot` exists before assuming project is initialized

---

## Quality Checks

Before committing:
1. Godot project opens without errors
2. Main scene runs without crashes
3. No GDScript errors in Output panel
4. Type hints on modified functions

---

**See [documentation/](./documentation/README.md) for full project knowledge.**
