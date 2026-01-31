#!/bin/bash
# CHECK-EPIC-ON-CLOSE: PostToolUse hook wrapper for Bash commands.
#
# Reads stdin JSON from Claude Code hook system.
# Fast-bails (~20ms) if the command isn't `bd close`.
# If it IS bd close, extracts the ticket ID and checks for epic completion.
#
# Output goes to stdout — Claude sees it as context in the conversation.

set -euo pipefail

# Read the hook input from stdin
INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || true

# Fast bail: if we couldn't parse, or it's not a bd close command
if [ -z "$COMMAND" ]; then
    exit 0
fi

if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|)bd\s+close\b'; then
    exit 0
fi

# Extract ticket ID from the bd close command
# Handles: bd close arcology-xyz, bd close arcology-xyz --reason "...", etc.
TICKET_ID=$(echo "$COMMAND" | grep -oE 'bd\s+close\s+(arcology-[a-z0-9.]+)' | awk '{print $NF}') || true

if [ -z "$TICKET_ID" ]; then
    exit 0
fi

# Resolve the project directory (same as $CLAUDE_PROJECT_DIR in hooks context)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Call the core detection script
exec "$PROJECT_DIR/scripts/hooks/check-epic-completion.sh" "$TICKET_ID"
