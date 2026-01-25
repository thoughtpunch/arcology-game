#!/bin/bash
# PRE-TASK HOOK: Must be run BEFORE starting work on any ticket
# Usage: ./scripts/hooks/pre-task.sh <ticket-id>
#
# Enforces: Reading docs, understanding requirements, identifying questions

set -e

TICKET_ID="$1"

if [ -z "$TICKET_ID" ]; then
    echo "❌ ERROR: Must provide ticket ID"
    echo "Usage: ./scripts/hooks/pre-task.sh <ticket-id>"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  📚 PRE-TASK: DOCUMENTATION & REQUIREMENTS CHECK                 ║"
echo "║  Ticket: $TICKET_ID"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Get ticket details
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ TICKET DETAILS                                                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
bd show "$TICKET_ID" 2>/dev/null || { echo "❌ Could not find ticket"; exit 1; }

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ 📖 REQUIRED READING                                              │"
echo "└─────────────────────────────────────────────────────────────────┘"

# Determine milestone and show relevant docs
MILESTONE=$(echo "$TICKET_ID" | cut -d'.' -f1 | sed 's/arcology-//')
case "$MILESTONE" in
    4ct|eip)
        echo "🎯 Milestone 0: documentation/architecture/milestones/milestone-0-skeleton.md"
        echo "   Supporting: documentation/quick-reference/tech-stack.md"
        ;;
    x0d|jin)
        echo "🎯 Milestone 1: documentation/architecture/milestones/milestone-1-grid-blocks.md"
        echo "   Supporting: documentation/game-design/core-concepts.md"
        echo "   Supporting: documentation/quick-reference/isometric-math.md"
        echo "   Supporting: documentation/game-design/blocks/README.md"
        ;;
    y6e|9gm)
        echo "🎯 Milestone 2: documentation/architecture/milestones/milestone-2-floor-navigation.md"
        echo "   Supporting: documentation/ui/views.md"
        ;;
    itx|4lj)
        echo "🎯 Milestone 3: documentation/architecture/milestones/milestone-3-connectivity.md"
        echo "   Supporting: documentation/game-design/transit/pathfinding.md"
        echo "   Supporting: documentation/game-design/transit/corridors.md"
        echo "   Supporting: documentation/game-design/blocks/transit.md"
        ;;
    *)
        echo "   Check documentation/INDEX.md for relevant topics"
        ;;
esac

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ✅ BEFORE YOU START - CHECKLIST                                  │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "[ ] 1. READ the milestone doc listed above"
echo "[ ] 2. READ the supporting docs for context"
echo "[ ] 3. CHECK the ticket comments for specific requirements"
echo "[ ] 4. CHECK documentation/INDEX.md for any unfamiliar terms"
echo "[ ] 5. IDENTIFY any unclear requirements or missing info"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ ❓ IF ANYTHING IS UNCLEAR                                        │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "1. Add a comment to the ticket with your question:"
echo "   bd comments add $TICKET_ID \"Question: <your question>\""
echo ""
echo "2. Check if the PRD has the answer:"
echo "   grep -r \"<keyword>\" documentation/"
echo ""
echo "3. If truly blocked, mark the ticket:"
echo "   bd update $TICKET_ID --status blocked"
echo "   bd comments add $TICKET_ID \"Blocked: Need clarification on...\""
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Once you have read the docs and understand the requirements:    ║"
echo "║                                                                  ║"
echo "║  bd update $TICKET_ID --status in_progress                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
