# Beads Integration for Ralph

[← Back to Ralph](./README.md) | [← Back to Agents](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Ralph uses Beads (`bd`) for task tracking instead of manual JSON files.

---

## Commands Reference

```bash
# Get ready (unblocked) tasks as JSON
bd ready --json

# Get task details
bd show bd-abc123 --json

# Update status
bd update bd-abc123 --status in_progress

# Close completed task
bd close bd-abc123 --reason "Implemented and tested"

# Create new discovered task
bd create "Fix bug found during implementation" --priority 1 --discovered-from bd-abc123

# Add dependency (A blocked by B)
bd dep add bd-A bd-B

# Sync to git (export JSONL)
bd sync
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `bd ready` | What can I work on? |
| `bd ready --json` | Same, for scripting |
| `bd show <id>` | Task details |
| `bd list` | All tasks |
| `bd list --status open` | Open tasks only |
| `bd update <id> --status in_progress` | Start working |
| `bd close <id> --reason "Done"` | Mark complete |
| `bd create "New task" -t task -p 1 --discovered-from <id>` | New task |
| `bd dep add <blocked> <blocker>` | Add dependency |
| `bd sync` | Export to git |
| `bd doctor --fix` | Fix issues |

---

## Directory Structure

```
arcology/
├── .beads/              # Beads database
│   ├── beads.db         # SQLite (local)
│   └── issues.jsonl     # Git-synced
└── scripts/ralph/
    ├── progress.txt     # Learnings log
    └── ...
```

---

## Task Workflow

```
bd ready → pick task → bd update --status in_progress → implement →
commit → bd close → bd sync → bd ready (repeat)
```

---

## See Also

- [instructions.md](./instructions.md) - Full iteration workflow
- [kickstart.md](./kickstart.md) - Bootstrap prompts
