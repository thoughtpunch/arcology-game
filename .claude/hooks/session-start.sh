#!/bin/bash
# SESSION-START HOOK: Fires on every Claude Code session start
# Shows active work, ready ticket count, and workflow reminder.
# Must be fast (<2 seconds).

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

# Show in-progress tickets (active work)
IN_PROGRESS=$(bd list --status in_progress --limit 10 --quiet 2>/dev/null) || true
if [ -n "$IN_PROGRESS" ]; then
    echo ""
    echo "IN-PROGRESS:"
    echo "$IN_PROGRESS" | sed 's/^/  /'
else
    echo ""
    echo "IN-PROGRESS: (none)"
fi

# Count ready tickets
READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null) || READY_COUNT="?"
echo ""
echo "READY TO WORK: $READY_COUNT ticket(s)"

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
