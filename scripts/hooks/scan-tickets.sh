#!/bin/bash
# SCAN-TICKETS: Reusable ticket search utility
# Usage: ./scripts/hooks/scan-tickets.sh [keyword1] [keyword2] ...
#
# Searches for open/in-progress tickets matching each keyword.
# Always exits 0 (informational only, never blocks).

set -euo pipefail

KEYWORDS=("$@")

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ TICKET SCAN                                                     │"
echo "└─────────────────────────────────────────────────────────────────┘"

# Show in-progress work first
echo ""
echo "IN-PROGRESS TICKETS:"
IN_PROGRESS=$(bd list --status in_progress --limit 20 2>/dev/null) || true
if [ -z "$IN_PROGRESS" ]; then
    echo "  (none)"
else
    echo "$IN_PROGRESS" | sed 's/^/  /'
fi

# Search for each keyword
if [ ${#KEYWORDS[@]} -gt 0 ]; then
    echo ""
    echo "KEYWORD SEARCH:"
    for kw in "${KEYWORDS[@]}"; do
        echo ""
        echo "  \"$kw\":"
        RESULTS=$(bd search "$kw" --status open --limit 10 2>/dev/null) || true
        if [ -z "$RESULTS" ]; then
            echo "    (no open matches)"
        else
            echo "$RESULTS" | sed 's/^/    /'
        fi
    done
fi

# Show ready count
echo ""
READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null) || READY_COUNT="?"
echo "READY TO WORK: $READY_COUNT ticket(s)"
echo ""

exit 0
