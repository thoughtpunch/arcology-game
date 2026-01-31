#!/bin/bash
# SESSION-START HOOK: Fires on every Claude Code session start
# Shows active work, ready ticket count, recent commits, and workflow reminder.
# Runs bd commands fresh (no caching) to get current data.

set -euo pipefail

# Check bd is available
if ! command -v bd &>/dev/null; then
    echo "[beads] bd not found — skipping ticket status"
    exit 0
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  BEADS TICKET STATUS                                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

# Show in-progress tickets (active work) - run fresh
IN_PROGRESS=$(bd list --status in_progress --limit 10 2>/dev/null | grep -v "^Showing" | grep -v "^$") || true
if [ -n "$IN_PROGRESS" ]; then
    echo ""
    echo "IN-PROGRESS:"
    echo "$IN_PROGRESS" | sed 's/^/  /'
else
    echo ""
    echo "IN-PROGRESS: (none)"
fi

# Get ready count from bd ready output (parses "N issues" from header line)
# Note: bd ready outputs to stderr, so we redirect stderr to stdout
READY_COUNT=$(bd ready --limit 0 2>&1 | grep -oE '[0-9]+ issues' | head -1 | grep -oE '[0-9]+') || READY_COUNT="?"
echo ""
echo "READY TO WORK: $READY_COUNT ticket(s)"

# Get total open tickets count
TOTAL_OPEN=$(bd list --limit 0 2>/dev/null | grep -c '^arcology-') || TOTAL_OPEN="?"
echo "TOTAL OPEN: $TOTAL_OPEN ticket(s)"

# Show last 5 commits
echo ""
echo "RECENT COMMITS:"
git log --oneline -5 2>/dev/null | sed 's/^/  /' || echo "  (no commits)"

# Workflow reminder
echo ""
echo "WORKFLOW: SCAN -> CLAIM/CREATE -> DO -> UPDATE -> CLOSE -> COMMIT"
echo "  bd search \"<keyword>\"        # 1. Scan for related tickets"
echo "  bd update <id> --status in_progress  # 2. Claim"
echo "  # ... do the work ...        # 3. Implement"
echo "  bd comments add <id> \"...\"   # 4. Update with chain-of-thought"
echo "  bd close <id> --reason \"...\" # 5. Close"
echo "  git commit -m \"feat: <id> - ...\"  # 6. Commit (ID required!)"
echo ""
