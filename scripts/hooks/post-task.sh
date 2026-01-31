#!/bin/bash
# POST-TASK HOOK: Must be run AFTER completing work on any ticket
# Usage: ./scripts/hooks/post-task.sh <ticket-id>
#
# Enforces: Definition of Done
# - Completion comment exists
# - Implementation matches game design
# - Documentation updated
# - Learnings captured
# - Followup tickets created
# - At least one commit references the ticket

set -e

TICKET_ID="$1"

if [ -z "$TICKET_ID" ]; then
    echo "ERROR: Must provide ticket ID"
    echo "Usage: ./scripts/hooks/post-task.sh <ticket-id>"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  POST-TASK: DEFINITION OF DONE CHECK                            ║"
echo "║  Ticket: $TICKET_ID"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Get ticket details for dynamic doc suggestions
TICKET_JSON=$(bd show "$TICKET_ID" --json 2>/dev/null) || true
TICKET_TITLE=$(echo "$TICKET_JSON" | jq -r '.title // empty' 2>/dev/null) || true
LABELS=$(echo "$TICKET_JSON" | jq -r '.labels[]? // empty' 2>/dev/null) || true
TITLE_LOWER=$(echo "$TICKET_TITLE" | tr '[:upper:]' '[:lower:]')

echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ACCEPTANCE CRITERIA                                              │"
echo "└─────────────────────────────────────────────────────────────────┘"

# Dynamic milestone doc lookup based on labels
MILESTONE_DOC=""
for label in $LABELS; do
    case "$label" in
        *milestone-0*) MILESTONE_DOC="documentation/architecture/milestones/milestone-0-skeleton.md" ;;
        *milestone-1*) MILESTONE_DOC="documentation/architecture/milestones/milestone-1-grid-blocks.md" ;;
        *milestone-2*) MILESTONE_DOC="documentation/architecture/milestones/milestone-2-floor-navigation.md" ;;
        *milestone-3*) MILESTONE_DOC="documentation/architecture/milestones/milestone-3-connectivity.md" ;;
        *milestone-4*) MILESTONE_DOC="documentation/architecture/milestones/milestone-4-environment.md" ;;
        *milestone-5*) MILESTONE_DOC="documentation/architecture/milestones/milestone-5-residents.md" ;;
    esac
done

# Fallback: try to infer from title keywords
if [ -z "$MILESTONE_DOC" ]; then
    if echo "$TITLE_LOWER" | grep -qE 'grid|block|place|build'; then
        MILESTONE_DOC="documentation/architecture/milestones/milestone-1-grid-blocks.md"
    elif echo "$TITLE_LOWER" | grep -qE 'camera|view|floor|navigation'; then
        MILESTONE_DOC="documentation/architecture/milestones/milestone-2-floor-navigation.md"
    elif echo "$TITLE_LOWER" | grep -qE 'path|corridor|connect|elevator'; then
        MILESTONE_DOC="documentation/architecture/milestones/milestone-3-connectivity.md"
    elif echo "$TITLE_LOWER" | grep -qE 'light|air|noise|environment'; then
        MILESTONE_DOC="documentation/architecture/milestones/milestone-4-environment.md"
    fi
fi

if [ -n "$MILESTONE_DOC" ] && [ -f "$MILESTONE_DOC" ]; then
    echo "From: $MILESTONE_DOC"
    echo ""
    sed -n '/## Acceptance Criteria/,/^##/p' "$MILESTONE_DOC" | head -20
else
    echo "  No milestone doc auto-detected. Check documentation/architecture/ manually."
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ DEFINITION OF DONE - CHECKLIST                                   │"
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
echo "       bd create \"<title>\" -t task -p 2 --deps \"discovered-from:$TICKET_ID\""
echo "[ ] 9. If this ticket revealed missing requirements, document them"
echo ""
echo "LEARNINGS:"
echo "[ ] 10. Add iteration notes to scripts/ralph/progress.txt"
echo ""

# ENFORCE: Check for completion comment
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ COMMENT CHECK                                                    │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

COMMENT_COUNT=$(bd comments "$TICKET_ID" --json 2>/dev/null | jq 'length' 2>/dev/null) || COMMENT_COUNT="0"

if [ "$COMMENT_COUNT" -eq 0 ] 2>/dev/null; then
    echo "ERROR: No comments found on $TICKET_ID"
    echo ""
    echo "You MUST add a completion comment before closing this ticket."
    echo "Run:"
    echo "  bd comments add $TICKET_ID \"## What was done"
    echo "  - <change 1>"
    echo "  - <change 2>"
    echo ""
    echo "  ## Left undone / deferred"
    echo "  - <or 'None'>"
    echo ""
    echo "  ## Gotchas"
    echo "  - <anything surprising>\""
    echo ""
    exit 1
else
    echo "Found $COMMENT_COUNT comment(s) on $TICKET_ID"
fi

echo ""

# ENFORCE: Check for uncommitted changes
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  MANDATORY: Commit before closing ticket                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "WARNING: You have uncommitted changes!"
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
    echo "ERROR: No commits found referencing $TICKET_ID"
    echo ""
    echo "You MUST create at least one commit with the ticket ID in the message."
    echo "Format: feat: $TICKET_ID - <description>"
    echo ""
    echo "Then back-link the commit SHA:"
    echo "  SHA=\$(git rev-parse HEAD)"
    echo "  bd comments add $TICKET_ID \"Commit: \$SHA\""
    echo ""
    exit 1
fi

echo "Found $TICKET_COMMITS commit(s) referencing $TICKET_ID"
echo ""

echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ READY TO CLOSE                                                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "Run:"
echo "  bd close $TICKET_ID --reason \"Implemented\""
echo "  ./scripts/hooks/bd-sync-rich.sh"
