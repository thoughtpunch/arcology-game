# Ralph Agent Instructions

[← Back to Ralph](./README.md) | [← Back to Agents](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Instructions for each iteration of autonomous development.

**Key principle:** Documentation first. Every task has required reading. Every completion requires updating docs.

---

## ⚠️ MANDATORY HOOKS

Before and after every task, you MUST run the enforcement hooks:

```bash
# BEFORE starting work
./scripts/hooks/pre-task.sh <ticket-id>

# AFTER completing work
./scripts/hooks/post-task.sh <ticket-id>
```

These hooks enforce the Definition of Done.

---

## Your Task (One Iteration)

### Phase 1: Setup
1. Get next task: `bd ready --json | head -1`
2. **Run pre-task hook:** `./scripts/hooks/pre-task.sh <ticket-id>`
3. **READ all documentation** listed in the hook output
4. Check `scripts/ralph/progress.txt` for codebase patterns
5. If anything is unclear, add questions to the ticket

### Phase 2: Implement
6. Mark in progress: `bd update <ticket-id> --status in_progress`
7. **Record start time:** `export TASK_STARTED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")`
8. Implement the task following the documentation
9. Run quality checks

### Phase 3: Verify & Document
10. **Run post-task hook:** `./scripts/hooks/post-task.sh <ticket-id>`
11. Verify implementation matches acceptance criteria
12. **Update documentation** if you found gaps or errors
13. **Create followup tickets** if you discovered new work
14. **Add learnings** to `scripts/ralph/progress.txt`

### Phase 4: Complete
15. Commit: `git commit -m "feat: <ticket-id> - <title>"`
16. **Add completion comment** (see Completion Comment Format below)
17. Close: `bd close <ticket-id> --reason "<one-line summary>"`
18. Sync: `bd sync`

---

## Completion Comment Format

Before closing a ticket, add a detailed completion comment for cycle time tracking and knowledge capture:

```bash
bd comment <ticket-id> "$(cat <<'EOF'
## Completion Summary

**Completed:** <ISO8601 timestamp, e.g., 2026-01-25T19:45:00Z>
**Duration:** <Xh Ym Zs> (from in_progress to completion)

### Implementation Approach
<Why this approach was chosen. What alternatives were considered.
Why this solution fits the codebase architecture.>

### What Was Done
- <Specific change 1>
- <Specific change 2>
- <Files modified: list them>

### What Was Left Undone / Deferred
- <Any scope that was cut>
- <Edge cases not handled>
- <Future improvements identified>
- <Or "None - full scope implemented">

### Gotchas / Notes for Future Work
- <Anything surprising discovered>
- <Patterns that should be documented>
- <Dependencies or assumptions made>

### Test Coverage
- <How the implementation was verified>
- <Manual testing done>
- <Automated tests added (if any)>
EOF
)"
```

### Calculating Duration

```bash
# At task start (Phase 2):
export TASK_STARTED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# At task completion (Phase 4):
TASK_COMPLETED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Calculate duration (macOS):
START_SEC=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$TASK_STARTED" +%s)
END_SEC=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$TASK_COMPLETED" +%s)
DURATION=$((END_SEC - START_SEC))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))
echo "Duration: ${HOURS}h ${MINUTES}m ${SECONDS}s"
```

---

## Definition of Done

A task is DONE when:

### Implementation
- [ ] Code matches the game design in the milestone doc
- [ ] All acceptance criteria are met
- [ ] Code follows conventions in `documentation/quick-reference/code-conventions.md`
- [ ] No hardcoded magic numbers (use `data/*.json`)

### Documentation
- [ ] Patterns discovered are added to `progress.txt`
- [ ] Any doc errors/gaps are fixed in the doc files
- [ ] Learnings are recorded with context

### Ticket Closure
- [ ] **Completion comment added** with full summary (see format above)
- [ ] Duration tracked (started_at → completed_at)
- [ ] Implementation rationale documented
- [ ] Deferred work explicitly noted

### Followup
- [ ] New work discovered → create tickets
- [ ] Questions asked → add comments to tickets
- [ ] Design gaps → document and create tickets

---

## Quality Checks

```bash
# If Godot project exists:
# 1. Project opens without errors
# 2. Main scene runs without crashes
# 3. No GDScript errors (check Output panel)

# For any code:
# - No syntax errors
# - Functions have type hints where reasonable
# - Classes have class_name declarations
```

---

## Stop Conditions

### All Done

If `bd ready --json` returns empty:

```
<promise>COMPLETE</promise>
```

### Stuck

If a task fails 3+ times:

1. Add comment: `bd comments add <id> "Blocked: <reason>"`
2. Mark blocked: `bd update <id> --status blocked`
3. Try next ready task
4. If ALL remaining tasks are blocked:

```
<ralph>STUCK</ralph>
```

---

## Progress Log Format

After completing a task, append to `scripts/ralph/progress.txt`:

```markdown
## Iteration [N] - [Date]
Task: <ticket-id> - [Title]

Docs Consulted:
- documentation/architecture/milestones/milestone-X.md
- documentation/game-design/<relevant>.md

Status: PASSED / FAILED

Changes:
- [file1]: [what changed]
- [file2]: [what changed]

Learnings:
- [anything future iterations should know]
- [patterns discovered]
- [how unclear things were resolved]

Followup Tickets Created:
- <new-ticket-id>: [title if any]

Doc Updates Made:
- [doc file]: [what was added/fixed]
```

---

## Codebase Patterns Section

If you discover a reusable pattern, add it to **## Codebase Patterns** at TOP of `progress.txt`:

```markdown
## Codebase Patterns
- Use Vector3i for grid positions (x, y = horizontal, z = floor)
- Blocks emit signals, systems connect to them
- Load balance numbers from data/balance.json, not hardcoded
- Sprites go in assets/sprites/blocks/{category}/
- [NEW PATTERN YOU DISCOVERED]
```

---

## If Stuck

1. **Re-read the docs** - Answer is probably there
2. Search: `grep -r "<keyword>" documentation/`
3. Check `documentation/INDEX.md` for the concept
4. Check `documentation/quick-reference/formulas.md` for calculations
5. Check existing patterns in `progress.txt`
6. Simplify: implement the minimal version
7. Create sub-task: `bd create "Smaller piece" --type task`
8. Document the blocker clearly

---

## See Also

- [beads.md](./beads.md) - Beads command reference
- [kickstart.md](./kickstart.md) - Bootstrap prompts
- [../../quick-reference/code-conventions.md](../../quick-reference/code-conventions.md) - Code style
- [../../architecture/patterns.md](../../architecture/patterns.md) - Architecture patterns
