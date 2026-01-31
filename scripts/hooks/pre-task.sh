#!/bin/bash
# PRE-TASK HOOK: Must be run BEFORE starting work on any ticket
# Usage: ./scripts/hooks/pre-task.sh <ticket-id>
#
# Enforces: Reading docs, understanding requirements, identifying questions
# Dynamically suggests docs based on ticket labels and title keywords.

set -e

TICKET_ID="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$TICKET_ID" ]; then
    echo "ERROR: Must provide ticket ID"
    echo "Usage: ./scripts/hooks/pre-task.sh <ticket-id>"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  PRE-TASK: DOCUMENTATION & REQUIREMENTS CHECK                   ║"
echo "║  Ticket: $TICKET_ID"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Get ticket details
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ TICKET DETAILS                                                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
bd show "$TICKET_ID" 2>/dev/null || { echo "ERROR: Could not find ticket"; exit 1; }

echo ""

# Scan for related tickets
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ RELATED TICKETS                                                  │"
echo "└─────────────────────────────────────────────────────────────────┘"

# Extract title keywords from the ticket for scanning
TICKET_JSON=$(bd show "$TICKET_ID" --json 2>/dev/null) || true
TICKET_TITLE=$(echo "$TICKET_JSON" | jq -r '.title // empty' 2>/dev/null) || true

if [ -n "$TICKET_TITLE" ]; then
    # Extract meaningful keywords (>3 chars, skip common words)
    KEYWORDS=$(echo "$TICKET_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | \
        grep -vE '^(the|and|for|with|from|that|this|have|will|been|into|over|such|than|them|then|were|what|when|your|about|after|could|every|first|other|their|which|would|should|implement|create|update|add|fix|remove|delete|make|set|get)$' | \
        awk 'length > 3' | head -3)

    if [ -n "$KEYWORDS" ]; then
        # Pass keywords to scan-tickets.sh
        KEYWORD_ARGS=()
        while IFS= read -r kw; do
            [ -n "$kw" ] && KEYWORD_ARGS+=("$kw")
        done <<< "$KEYWORDS"

        if [ ${#KEYWORD_ARGS[@]} -gt 0 ]; then
            "$SCRIPT_DIR/scan-tickets.sh" "${KEYWORD_ARGS[@]}" 2>/dev/null || true
        fi
    fi
else
    echo "  (could not extract title for keyword search)"
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ REQUIRED READING                                                 │"
echo "└─────────────────────────────────────────────────────────────────┘"

# Dynamic doc suggestions based on ticket labels and title
LABELS=$(echo "$TICKET_JSON" | jq -r '.labels[]? // empty' 2>/dev/null) || true
TITLE_LOWER=$(echo "$TICKET_TITLE" | tr '[:upper:]' '[:lower:]')
SUGGESTED_DOCS=()

# Check labels for doc suggestions
for label in $LABELS; do
    case "$label" in
        *grid*|*block*)
            SUGGESTED_DOCS+=("documentation/game-design/blocks/README.md")
            SUGGESTED_DOCS+=("documentation/game-design/core-concepts.md")
            ;;
        *ui*|*hud*|*overlay*)
            SUGGESTED_DOCS+=("documentation/ui/views.md")
            ;;
        *transit*|*path*|*corridor*)
            SUGGESTED_DOCS+=("documentation/game-design/transit/pathfinding.md")
            SUGGESTED_DOCS+=("documentation/game-design/transit/corridors.md")
            ;;
        *environment*|*light*|*air*|*noise*)
            SUGGESTED_DOCS+=("documentation/game-design/core-concepts.md")
            ;;
        *agent*|*resident*|*need*)
            SUGGESTED_DOCS+=("documentation/agents/ralph/")
            ;;
        *milestone-0*) SUGGESTED_DOCS+=("documentation/architecture/milestones/milestone-0-skeleton.md") ;;
        *milestone-1*) SUGGESTED_DOCS+=("documentation/architecture/milestones/milestone-1-grid-blocks.md") ;;
        *milestone-2*) SUGGESTED_DOCS+=("documentation/architecture/milestones/milestone-2-floor-navigation.md") ;;
        *milestone-3*) SUGGESTED_DOCS+=("documentation/architecture/milestones/milestone-3-connectivity.md") ;;
    esac
done

# Also check title keywords for doc suggestions
if echo "$TITLE_LOWER" | grep -qE 'grid|block|place|build'; then
    SUGGESTED_DOCS+=("documentation/game-design/blocks/README.md")
fi
if echo "$TITLE_LOWER" | grep -qE 'camera|view|hud|ui|overlay|render'; then
    SUGGESTED_DOCS+=("documentation/ui/views.md")
fi
if echo "$TITLE_LOWER" | grep -qE 'path|corridor|elevator|transit|connect'; then
    SUGGESTED_DOCS+=("documentation/game-design/transit/pathfinding.md")
fi
if echo "$TITLE_LOWER" | grep -qE 'light|air|noise|environment|safety'; then
    SUGGESTED_DOCS+=("documentation/game-design/core-concepts.md")
fi
if echo "$TITLE_LOWER" | grep -qE 'isometric|sprite|pixel|art'; then
    SUGGESTED_DOCS+=("documentation/quick-reference/isometric-math.md")
fi

# Deduplicate and print suggestions
if [ ${#SUGGESTED_DOCS[@]} -gt 0 ]; then
    printf '%s\n' "${SUGGESTED_DOCS[@]}" | sort -u | while read -r doc; do
        if [ -e "$doc" ]; then
            echo "  -> $doc"
        else
            echo "  -> $doc (not found — may need to create)"
        fi
    done
else
    echo "  Check documentation/INDEX.md for relevant topics"
fi

# Always suggest the index
echo ""
echo "  General reference: documentation/INDEX.md"
echo "  Formulas: documentation/quick-reference/formulas.md"

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ BEFORE YOU START - CHECKLIST                                     │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "[ ] 1. READ the suggested docs listed above"
echo "[ ] 2. CHECK the ticket comments for specific requirements"
echo "[ ] 3. CHECK documentation/INDEX.md for any unfamiliar terms"
echo "[ ] 4. IDENTIFY any unclear requirements or missing info"
echo "[ ] 5. SCAN related tickets (done above) — avoid duplicate work"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ IF ANYTHING IS UNCLEAR                                           │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "1. Add a comment to the ticket with your question:"
echo "   bd comments add $TICKET_ID \"Question: <your question>\""
echo ""
echo "2. Check if the docs have the answer:"
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
