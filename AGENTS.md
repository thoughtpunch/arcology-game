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

<!-- bv-agent-instructions-v1 -->

---

## Beads Workflow Integration

This project uses [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) for issue tracking. Issues are stored in `.beads/` and tracked in git.

### Essential Commands

```bash
# View issues (launches TUI - avoid in automated sessions)
bv

# CLI commands for agents (use these instead)
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
bd sync               # Commit and push changes
```

### Workflow Pattern

1. **Start**: Run `bd ready` to find actionable work
2. **Claim**: Use `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `bd close <id>`
5. **Sync**: Always run `bd sync` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>` to add dependencies

### Session Protocol

**Before ending any session, run this checklist:**

```bash
git status              # Check what changed
git add <files>         # Stage code changes
bd sync                 # Commit beads changes
git commit -m "..."     # Commit code
bd sync                 # Commit any new beads changes
git push                # Push to remote
```

### Best Practices

- Check `bd ready` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `bd create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always `bd sync` before ending session

<!-- end-bv-agent-instructions -->
