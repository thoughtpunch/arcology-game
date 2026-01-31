#!/bin/bash
# BD-SYNC-RICH: Wrapper for `bd sync` with rich commit messages
# Shows a changelog of ticket activity since last sync.
#
# Usage: ./scripts/hooks/bd-sync-rich.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

# Find the timestamp of the last bd sync commit
LAST_SYNC_TIME=$(git log --format=%aI -1 -- .beads/issues.jsonl 2>/dev/null) || true

# Build the activity log
ACTIVITY=""
if [ -n "$LAST_SYNC_TIME" ]; then
    # Get activity since last sync
    # bd activity --since accepts relative times (5m, 1h) and absolute timestamps
    # Convert ISO timestamp to a rough relative time isn't reliable, so use
    # the ISO timestamp directly if bd supports it, otherwise fall back
    ACTIVITY=$(bd activity --since "$LAST_SYNC_TIME" --json 2>/dev/null) || true
fi

# If no activity from timestamp, try last 30 minutes as fallback
if [ -z "$ACTIVITY" ] || [ "$ACTIVITY" = "[]" ] || [ "$ACTIVITY" = "null" ]; then
    ACTIVITY=$(bd activity --since 30m --json 2>/dev/null) || true
fi

# Build the rich commit message
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
MSG="bd sync: $TIMESTAMP"

# Parse activity into changelog lines
if [ -n "$ACTIVITY" ] && [ "$ACTIVITY" != "[]" ] && [ "$ACTIVITY" != "null" ]; then
    CHANGELOG=$(echo "$ACTIVITY" | jq -r '
        .[] |
        if .type == "create" then "+ \(.id) created — \(.title // "untitled")"
        elif .type == "update" and .changes.status == "in_progress" then "→ \(.id) in_progress — \(.title // "untitled")"
        elif .type == "update" and .changes.status == "closed" then "✓ \(.id) closed — \(.title // "untitled")"
        elif .type == "delete" then "⊘ \(.id) deleted — \(.title // "untitled")"
        elif .type == "update" then "~ \(.id) updated — \(.title // "untitled")"
        else "  \(.id) \(.type) — \(.title // "untitled")"
        end
    ' 2>/dev/null) || true

    if [ -n "$CHANGELOG" ]; then
        MSG="$MSG

Changes:
$CHANGELOG"
    fi
fi

# Run bd sync with the rich message
bd sync -m "$MSG"
