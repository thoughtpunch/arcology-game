# Ralph Agent Instructions

[← Back to Ralph](./README.md) | [← Back to Agents](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Instructions for each iteration of autonomous development.

---

## Your Task (One Iteration)

1. Run `bd ready --json` to get unblocked tasks
2. Read `scripts/ralph/progress.txt` for codebase patterns (check **Codebase Patterns** section first)
3. Check you're on the correct branch. If not, check it out or create from `main`
4. Pick the **highest priority** ready task (lowest P number = highest priority)
5. Update task: `bd update <id> --status in_progress`
6. Implement that **single** task
7. Run quality checks (see below)
8. If checks pass, commit ALL changes with message: `feat: <bd-id> - <title>`
9. Close task: `bd close <id> --reason "Implemented"`
10. Sync: `bd sync`
11. Append learnings to `scripts/ralph/progress.txt`
12. Check for more work: `bd ready --json`

---

## Quality Checks

Before closing a task, ensure:

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

If `bd ready --json` returns empty array `[]`, output exactly:

```
<promise>COMPLETE</promise>
```

### Stuck

If a task fails 3+ times:

1. Add comment: `bd comment bd-xxx "Blocked: <reason>"`
2. Mark blocked: `bd update bd-xxx --status blocked`
3. Try next ready task
4. If ALL remaining tasks are blocked, output:

```
<ralph>STUCK</ralph>
```

---

## Progress Log Format

After completing a task, append to `scripts/ralph/progress.txt`:

```
## Iteration [N] - [Date]
Task: bd-xxx - [Title]
Status: PASSED / FAILED
Changes:
- [file1]: [what changed]
- [file2]: [what changed]
Learnings:
- [anything future iterations should know]
Blockers:
- [if failed, why]
```

---

## Codebase Patterns Section

If you discover a reusable pattern, add it to **## Codebase Patterns** at TOP of `progress.txt`:

```
## Codebase Patterns
- Use Vector3i for grid positions (x, y = horizontal, z = floor)
- Blocks emit signals, systems connect to them
- Load balance numbers from data/balance.json, not hardcoded
- Sprites go in assets/sprites/blocks/{category}/
```

---

## Important Reminders

- **One task per iteration** - Don't try to do multiple
- **Use bd commands** - Not manual JSON editing
- **Small commits** - Each task = one commit with bd-id
- **Data-driven** - Put numbers in JSON, not code
- **Signals > polling** - Use Godot signals for updates
- **Sync before done** - Always `bd sync` after closing tasks

---

## If Stuck

1. Check dependencies: `bd show bd-xxx --json` - is something blocking?
2. Check patterns in progress.txt
3. Check [../../architecture/](../../architecture/) for implementation guidance
4. Simplify: implement the minimal version that passes
5. Create sub-task: `bd create "Smaller piece" --discovered-from bd-xxx`
6. Document the blocker for next iteration

---

## See Also

- [beads.md](./beads.md) - Beads command reference
- [kickstart.md](./kickstart.md) - Bootstrap prompts
- [../../quick-reference/code-conventions.md](../../quick-reference/code-conventions.md) - Code style
