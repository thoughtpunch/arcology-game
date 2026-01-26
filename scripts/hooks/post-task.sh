#!/bin/bash
# POST-TASK HOOK: Must be run AFTER completing work on any ticket
# Usage: ./scripts/hooks/post-task.sh <ticket-id>
#
# Enforces: Definition of Done
# - Implementation matches game design
# - Documentation updated
# - Learnings captured
# - Followup tickets created

set -e

TICKET_ID="$1"

if [ -z "$TICKET_ID" ]; then
    echo "❌ ERROR: Must provide ticket ID"
    echo "Usage: ./scripts/hooks/post-task.sh <ticket-id>"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  ✅ POST-TASK: DEFINITION OF DONE CHECK                          ║"
echo "║  Ticket: $TICKET_ID"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Determine milestone
MILESTONE=$(echo "$TICKET_ID" | cut -d'.' -f1 | sed 's/arcology-//')
MILESTONE_DOC=""

case "$MILESTONE" in
    4ct|eip) MILESTONE_DOC="documentation/architecture/milestones/milestone-0-skeleton.md" ;;
    x0d|jin) MILESTONE_DOC="documentation/architecture/milestones/milestone-1-grid-blocks.md" ;;
    y6e|9gm) MILESTONE_DOC="documentation/architecture/milestones/milestone-2-floor-navigation.md" ;;
    itx|4lj) MILESTONE_DOC="documentation/architecture/milestones/milestone-3-connectivity.md" ;;
esac

echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ 📋 ACCEPTANCE CRITERIA                                           │"
echo "└─────────────────────────────────────────────────────────────────┘"

if [ -n "$MILESTONE_DOC" ] && [ -f "$MILESTONE_DOC" ]; then
    echo "From: $MILESTONE_DOC"
    echo ""
    sed -n '/## Acceptance Criteria/,/^##/p' "$MILESTONE_DOC" | head -20
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ✅ DEFINITION OF DONE - CHECKLIST                                │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "IMPLEMENTATION:"
echo "[ ] 1. Code matches the game design in the milestone doc"
echo "[ ] 2. Acceptance criteria are met (check above)"
echo "[ ] 3. Code follows conventions in documentation/quick-reference/code-conventions.md"
echo "[ ] 4. No hardcoded values - numbers are in data/*.json"
echo ""
echo "DOCUMENTATION:"
echo "[ ] 5. If you discovered new patterns, add them to scripts/ralph/progress.txt"
echo "[ ] 6. If docs were wrong/incomplete, UPDATE the relevant doc file"
echo "[ ] 7. If you found a bug in the design, add a comment to the ticket"
echo ""
echo "FOLLOWUP:"
echo "[ ] 8. If you found work that needs to be done, CREATE a new ticket:"
echo "       bd create \"<title>\" --type task --priority P2"
echo "[ ] 9. If this ticket revealed missing requirements, document them"
echo ""
echo "LEARNINGS:"
echo "[ ] 10. Add iteration notes to scripts/ralph/progress.txt:"
echo "        - What docs did you read?"
echo "        - What patterns did you discover?"
echo "        - What was unclear and how did you resolve it?"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ 📝 REQUIRED: Update progress.txt                                 │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "Add an entry like:"
echo ""
echo "## Iteration N - $(date +%Y-%m-%d)"
echo "Task: $TICKET_ID - <title>"
echo "Docs Consulted:"
echo "- documentation/architecture/milestones/milestone-X.md"
echo "- documentation/game-design/<relevant>.md"
echo "Status: PASSED"
echo "Changes:"
echo "- src/file.gd: Added X functionality"
echo "Learnings:"
echo "- Discovered that Y works by Z"
echo "Followup Tickets Created:"
echo "- bd-xxx: <new ticket if any>"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ❓ DID YOU UPDATE DOCS?                                          │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "If you found documentation that was:"
echo "- Wrong: Fix it in the doc file"
echo "- Missing: Add the missing section"
echo "- Unclear: Add clarifying notes"
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  MANDATORY: Commit before closing ticket                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ENFORCE: Check for uncommitted changes related to this work
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "⚠️  WARNING: You have uncommitted changes!"
    echo ""
    git status --short
    echo ""
    echo "You MUST commit your work before closing this ticket."
    echo "Run:"
    echo "  git add <files>"
    echo "  git commit -m \"feat: $TICKET_ID - <title>\""
    echo ""
fi

# ENFORCE: Check that a commit exists for this ticket
TICKET_COMMITS=$(git log --oneline --all | grep -c "$TICKET_ID" || echo "0")
if [ "$TICKET_COMMITS" -eq 0 ]; then
    echo "❌ ERROR: No commits found referencing $TICKET_ID"
    echo ""
    echo "You MUST create at least one commit with the ticket ID in the message."
    echo "Format: feat: $TICKET_ID - <description>"
    echo ""
    exit 1
fi

echo "✅ Found $TICKET_COMMITS commit(s) referencing $TICKET_ID"
echo ""

echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ✅ READY TO CLOSE                                               │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "Run:"
echo "  bd close $TICKET_ID --reason \"Implemented\""
echo "  bd sync"
