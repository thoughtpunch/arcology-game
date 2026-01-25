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
7. Implement the task following the documentation
8. Run quality checks

### Phase 3: Verify & Document
9. **Run post-task hook:** `./scripts/hooks/post-task.sh <ticket-id>`
10. Verify implementation matches acceptance criteria
11. **Update documentation** if you found gaps or errors
12. **Create followup tickets** if you discovered new work
13. **Add learnings** to `scripts/ralph/progress.txt`

### Phase 4: Complete
14. Commit: `git commit -m "feat: <ticket-id> - <title>"`
15. Close: `bd close <ticket-id> --reason "Implemented per docs"`
16. Sync: `bd sync`

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
