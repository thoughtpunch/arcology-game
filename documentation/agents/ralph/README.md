# Ralph - Autonomous Iteration Agent

[← Back to Agents](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Ralph is an autonomous coding agent that builds Arcology incrementally, one task at a time. It runs in a loop, picking up tasks, implementing them, and moving on.

---

## Contents

| Document | Description | Link |
|----------|-------------|------|
| **Instructions** | Task workflow for each iteration | [instructions.md](./instructions.md) |
| **Beads Integration** | Using Beads for task tracking | [beads.md](./beads.md) |
| **Kickstart** | Bootstrap prompts for Claude Code | [kickstart.md](./kickstart.md) |

---

## Quick Start

1. Get ready tasks: `bd ready --json`
2. Pick highest priority task
3. Implement it
4. Commit: `git commit -m "feat: <bd-id> - <title>"`
5. Close: `bd close <id> --reason "Done"`
6. Sync: `bd sync`
7. Repeat

---

## Stop Conditions

| Signal | Meaning | Action |
|--------|---------|--------|
| `<promise>COMPLETE</promise>` | All tasks done | Exit cleanly |
| `<ralph>STUCK</ralph>` | All remaining tasks blocked | Human intervention needed |

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/ralph/progress.txt` | Cross-iteration learnings |
| `.beads/issues.jsonl` | Task database (git-synced) |

---

## See Also

- [../../quick-reference/code-conventions.md](../../quick-reference/code-conventions.md) - Code style
- [../../architecture/](../../architecture/) - Build milestones
- [../../quick-reference/3d-grid-math.md](../../quick-reference/3d-grid-math.md) - 3D grid math reference
