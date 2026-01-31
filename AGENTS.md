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

## MANDATORY: Beads Ticket Workflow

This project uses [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) for issue tracking. Issues are stored in `.beads/` and tracked in git.

**Every piece of work MUST follow the 6-step workflow. No exceptions.**

### Essential Commands

```bash
# View issues (launches TUI - avoid in automated sessions)
bv

# CLI commands for agents (use these instead)
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd search "keyword"   # Search for related tickets
bd create "Title" -t task -p 2
bd update <id> --status in_progress
bd comments add <id> "text"
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
./scripts/hooks/bd-sync-rich.sh  # Sync with rich commit messages
```

### The 6-Step Workflow (MANDATORY)

```
SCAN -> CLAIM/CREATE -> DO -> UPDATE -> CLOSE -> COMMIT
```

1. **SCAN**: Search for related tickets before starting work
   ```bash
   ./scripts/hooks/scan-tickets.sh "keyword1" "keyword2"
   bd search "relevant term"
   ```
2. **CLAIM/CREATE**: Every piece of work MUST have a ticket
   ```bash
   bd update <id> --status in_progress          # Claim existing
   bd create "Description" -t task -p 2          # Or create new
   # If related to closed ticket, link it:
   bd create "Follow-up to arcology-xyz - Desc" -t task -p 2 --deps "discovered-from:arcology-xyz"
   ```
3. **DO**: Implement the work
4. **UPDATE**: MUST add a chain-of-thought comment before closing
   ```bash
   bd comments add <id> "What was done: ... | Left undone: ... | Gotchas: ..."
   ```
5. **CLOSE**: Close the ticket
   ```bash
   bd close <id> --reason "Completed"
   ```
6. **COMMIT**: Commit with ticket ID, then back-link
   ```bash
   git commit -m "feat: arcology-xyz - Short description"
   SHA=$(git rev-parse HEAD)
   bd comments add <id> "Commit: $SHA"
   ```

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>` to add dependencies
- **Worklog Chain**: If work relates to a closed ticket, create a NEW ticket linked via `--deps "discovered-from:<id>"`. Never orphan work.

### Session Protocol

**At session start:**
```bash
bd list --status in_progress  # See active work
bd ready                      # See available work
./scripts/hooks/scan-tickets.sh "keyword"  # Scan for related tickets
```

**Before ending any session:**
```bash
git status                        # Check what changed
git add <files>                   # Stage code changes
./scripts/hooks/bd-sync-rich.sh   # Sync beads changes (rich commit msg)
git commit -m "feat: <id> - ..."  # Commit code (ticket ID required!)
SHA=$(git rev-parse HEAD)
bd comments add <id> "Commit: $SHA"  # Back-link commit to ticket
./scripts/hooks/bd-sync-rich.sh   # Sync any new beads changes
git push                          # Push to remote
```

### Rules

- You MUST check `bd ready` or `bd search` at session start
- You MUST update ticket status as you work (in_progress -> closed)
- You MUST add a completion comment before closing any ticket
- You MUST include the ticket ID in every commit message
- You MUST back-link the commit SHA to the ticket after committing
- You MUST create new issues with `bd create` when you discover tasks
- You MUST use `./scripts/hooks/bd-sync-rich.sh` instead of bare `bd sync`
- You MUST never orphan work — every change traces to a ticket

<!-- end-bv-agent-instructions -->
