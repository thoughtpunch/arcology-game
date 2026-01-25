# Ralph Kickstart Prompts

[← Back to Ralph](./README.md) | [← Back to Agents](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Bootstrap prompts for starting Claude Code sessions with Ralph.

---

## Option A: Interactive Mode (You Drive)

Paste this into Claude Code:

```
You're building Arcology, a 3D isometric city-builder in Godot 4. Use `bd` (Beads) for task tracking.

## Setup

```bash
command -v bd || curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
mkdir -p arcology && cd arcology
git init
bd init --quiet
```

## Read These Files

- `documentation/README.md` - Documentation entry point
- `documentation/architecture/` - Build milestones
- `CLAUDE.md` - Quick reference

## Create Beads for M0-M3

Read documentation/architecture/milestones/ and create beads for Milestones 0-3:
1. Create 4 epics (M0-M3)
2. Create tasks with acceptance criteria
3. Add dependencies between tasks
4. Each task = 10-30 min work

## Then Build

bd ready → pick task → implement → commit → bd close → bd sync → repeat

**Start now.**
```

---

## Option B: Ralph Autonomous Loop (Hands-Off)

Let Ralph run Claude Code in a loop until all tasks are done.

### 1. First Session - Setup & Create Beads

```
You're building Arcology. Set up the project and create beads from the architecture docs.

```bash
# Install tools
command -v bd || curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Create project
mkdir -p arcology && cd arcology
git init
bd init --quiet

# Copy ralph files
mkdir -p scripts/ralph
```

Read documentation/architecture/milestones/ and create beads for M0-M3:
- 4 epics, ~17 tasks total
- Add dependencies (camera needs project structure, etc.)
- Each task completable in one Claude session

When done: `bd sync && git add -A && git commit -m "chore: initial beads setup"`
```

### 2. Copy Ralph Files Into Project

After the first session, copy these into `arcology/scripts/ralph/`:
- `ralph-beads.sh` (the loop)
- `progress.txt` (learnings log)

### 3. Run The Loop

```bash
cd arcology
chmod +x scripts/ralph/ralph-beads.sh
./scripts/ralph/ralph-beads.sh 25  # Run up to 25 iterations
```

---

## The Ralph Loop Explained

```
┌─────────────────────────────────────────────────────────┐
│  ralph-beads.sh                                         │
│                                                         │
│  while true:                                            │
│    ┌─────────────────────────────────────────────────┐  │
│    │  claude < instructions                          │  │
│    │                                                 │  │
│    │  1. bd ready --json     # what's unblocked?     │  │
│    │  2. Pick highest priority task                  │  │
│    │  3. bd update <id> --status in_progress         │  │
│    │  4. Implement the task                          │  │
│    │  5. git commit -m "feat: <bd-id> - title"       │  │
│    │  6. bd close <id> --reason "Done"               │  │
│    │  7. bd sync                                     │  │
│    │  8. Append learnings to progress.txt            │  │
│    └─────────────────────────────────────────────────┘  │
│                                                         │
│    if output contains "<promise>COMPLETE</promise>":    │
│      exit 0  # All done!                                │
│    if output contains "<ralph>STUCK</ralph>":           │
│      exit 2  # Needs help                               │
│                                                         │
│    sleep 2                                              │
│    continue                                             │
└─────────────────────────────────────────────────────────┘
```

---

## Stop Conditions

- **All done:** Claude outputs `<promise>COMPLETE</promise>` - Ralph exits cleanly
- **Stuck:** Claude outputs `<ralph>STUCK</ralph>` - Ralph exits, you intervene
- **Max iterations:** Ralph stops after N iterations (default 20)

---

## Monitor Progress

In another terminal:

```bash
cd arcology
watch -n 5 'bd ready && echo "---" && bd list --status closed | tail -5'
```

---

## See Also

- [instructions.md](./instructions.md) - Full iteration workflow
- [beads.md](./beads.md) - Beads commands
- [../../architecture/milestones/](../../architecture/milestones/) - Milestone details
