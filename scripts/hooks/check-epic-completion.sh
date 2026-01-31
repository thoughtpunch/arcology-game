#!/bin/bash
# CHECK-EPIC-COMPLETION: Detects when all children of an epic are closed.
#
# Usage: check-epic-completion.sh <ticket-id>
#
# Logic:
#   1. Given a ticket ID (e.g., "arcology-xyz.3"), derive the parent epic ID
#   2. Query bd epic status for that parent
#   3. If not all children closed: output progress summary
#   4. If all children closed: output rich review context for Claude
#
# Designed to be called from hook wrappers or standalone.
# Output goes to stdout — the caller decides what to do with it.

set -euo pipefail

TICKET_ID="${1:-}"

if [ -z "$TICKET_ID" ]; then
    exit 0
fi

# Check bd is available
if ! command -v bd &>/dev/null; then
    exit 0
fi

# --- Step 1: Find parent epic ---
# Hierarchical children have IDs like "arcology-xyz.3" — parent is "arcology-xyz"
PARENT_ID=""

if echo "$TICKET_ID" | grep -qE '^arcology-[a-z0-9]+\.[0-9]+$'; then
    # Hierarchical child: strip the ".N" suffix
    PARENT_ID=$(echo "$TICKET_ID" | sed 's/\.[0-9]*$//')
fi

# If no hierarchical parent found, check if the ticket itself has a parent-child dependency
if [ -z "$PARENT_ID" ]; then
    # Try to get parent from the ticket's dependency info
    TICKET_JSON=$(bd show "$TICKET_ID" --json 2>/dev/null) || exit 0
    # Look for a parent-child relationship in dependents
    PARENT_ID=$(echo "$TICKET_JSON" | jq -r '
        .[0].dependents[]? |
        select(.dependency_type == "parent-child") |
        .id // empty
    ' 2>/dev/null) || true
fi

# If still no parent, nothing to check
if [ -z "$PARENT_ID" ]; then
    exit 0
fi

# --- Step 2: Check if parent is an epic and get its status ---
EPIC_JSON=$(bd show "$PARENT_ID" --json 2>/dev/null) || exit 0
EPIC_TYPE=$(echo "$EPIC_JSON" | jq -r '.[0].issue_type // empty' 2>/dev/null) || true
EPIC_STATUS=$(echo "$EPIC_JSON" | jq -r '.[0].status // empty' 2>/dev/null) || true

# Only care about open epics
if [ "$EPIC_STATUS" != "open" ]; then
    exit 0
fi

# Must be an epic (or at least have children — some epics are mis-typed as tasks)
# We check for children regardless of type, since the plan includes fixing mis-typed epics

# --- Step 3: Get epic completion status ---
EPIC_STATUS_JSON=$(bd epic status --json 2>/dev/null) || exit 0

# Find this specific epic in the status list
MATCH=$(echo "$EPIC_STATUS_JSON" | jq --arg id "$PARENT_ID" '
    [.[] | select(.epic.id == $id)] | first // empty
' 2>/dev/null) || true

if [ -z "$MATCH" ] || [ "$MATCH" = "null" ]; then
    # Parent has no children tracked as epic — could be mis-typed or no children yet
    exit 0
fi

TOTAL=$(echo "$MATCH" | jq -r '.total_children // 0' 2>/dev/null)
CLOSED=$(echo "$MATCH" | jq -r '.closed_children // 0' 2>/dev/null)
ELIGIBLE=$(echo "$MATCH" | jq -r '.eligible_for_close // false' 2>/dev/null)

# Zero children means nothing to report
if [ "$TOTAL" -eq 0 ]; then
    exit 0
fi

EPIC_TITLE=$(echo "$MATCH" | jq -r '.epic.title // "Unknown"' 2>/dev/null)

# --- Step 4: Output based on completion status ---

if [ "$ELIGIBLE" != "true" ]; then
    # Not all children closed — show progress
    REMAINING=$((TOTAL - CLOSED))
    PERCENT=$((CLOSED * 100 / TOTAL))
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  EPIC PROGRESS UPDATE                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Epic: $PARENT_ID — $EPIC_TITLE"
    echo "Progress: $CLOSED/$TOTAL children closed ($PERCENT%)"
    echo "Remaining: $REMAINING task(s) still open"
    echo ""
    exit 0
fi

# --- ALL CHILDREN CLOSED — Full review context ---

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  🎯 EPIC COMPLETION DETECTED — REVIEW REQUIRED                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Epic: $PARENT_ID — $EPIC_TITLE"
echo "All $TOTAL children are now closed."
echo ""

# Epic description (includes acceptance criteria)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "EPIC DESCRIPTION & ACCEPTANCE CRITERIA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EPIC_DESC=$(echo "$EPIC_JSON" | jq -r '.[0].description // "No description"' 2>/dev/null)
echo "$EPIC_DESC"
echo ""

# Child completion comments
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CHILD TICKET SUMMARIES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get all children from the epic's show output
CHILDREN=$(bd show "$PARENT_ID" 2>/dev/null | grep -E '^\s+↳' | sed 's/.*↳ //' | awk -F: '{print $1}' | tr -d ' ') || true

if [ -n "$CHILDREN" ]; then
    while IFS= read -r CHILD_ID; do
        [ -z "$CHILD_ID" ] && continue
        CHILD_INFO=$(bd show "$CHILD_ID" 2>/dev/null) || continue
        CHILD_TITLE=$(echo "$CHILD_INFO" | head -1 | sed "s/^${CHILD_ID}: //")
        echo ""
        echo "--- $CHILD_ID: $CHILD_TITLE ---"

        # Get comments for this child (completion notes)
        CHILD_COMMENTS=$(bd comments list "$CHILD_ID" 2>/dev/null) || true
        if [ -n "$CHILD_COMMENTS" ]; then
            echo "$CHILD_COMMENTS"
        else
            echo "(no comments)"
        fi
    done <<< "$CHILDREN"
fi
echo ""

# Git commits referencing children
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RELATED GIT COMMITS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Search for commits referencing the epic or its children
GIT_COMMITS=$(git log --oneline --all --grep="$PARENT_ID" 2>/dev/null) || true
if [ -n "$GIT_COMMITS" ]; then
    echo "$GIT_COMMITS"
else
    echo "(no commits found referencing $PARENT_ID)"
fi
echo ""

# Existing epic-level comments
EPIC_COMMENTS=$(bd comments list "$PARENT_ID" 2>/dev/null) || true
if [ -n "$EPIC_COMMENTS" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "EXISTING EPIC COMMENTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$EPIC_COMMENTS"
    echo ""
fi

# Review instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "REVIEW INSTRUCTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "All children of epic $PARENT_ID are closed. Before closing this"
echo "epic, perform a HOLISTIC REVIEW across these 5 dimensions:"
echo ""
echo "1. SUCCESS CRITERIA — Does the codebase satisfy EVERY criterion"
echo "   listed in the epic description above? Check each checkbox."
echo ""
echo "2. IMPLEMENTATION GAPS — Are there features described in the epic"
echo "   that were NOT implemented by any child ticket?"
echo ""
echo "3. DEFERRED WORK — Aggregate all 'left undone' or 'deferred' items"
echo "   from child completion comments. Create follow-up tickets for any"
echo "   that still matter."
echo ""
echo "4. INTEGRATION — Do the pieces fit together? Were the children"
echo "   implemented in isolation or do they form a coherent whole?"
echo ""
echo "5. BEST PRACTICES — Were tests written? Documentation updated?"
echo "   Code conventions followed?"
echo ""
echo "THEN either:"
echo "  a) CLOSE the epic with a summary comment:"
echo "     bd comments add $PARENT_ID \"## Epic Review Summary ....\""
echo "     bd close $PARENT_ID --reason \"All criteria met\""
echo ""
echo "  b) CREATE FOLLOW-UP tickets for gaps:"
echo "     bd create \"Follow-up: <description>\" -t task -p 2 --deps \"discovered-from:$PARENT_ID\""
echo "     bd comments add $PARENT_ID \"Not closing yet — follow-ups created: ...\""
echo ""
