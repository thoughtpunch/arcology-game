#!/bin/bash
# ENFORCE-TICKET-IN-COMMIT: PreToolUse hook for Bash
# Blocks `git commit` commands that don't include a ticket ID.
#
# Reads stdin JSON from Claude Code hook system.
# Exit 0 = allow, Exit 2 = block (with stderr message).

set -euo pipefail

# Read the hook input from stdin
INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || true

# If we couldn't parse a command, pass through
if [ -z "$COMMAND" ]; then
    exit 0
fi

# Only care about git commit commands
if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit\b'; then
    exit 0
fi

# Allow --amend (modifying existing commits)
if echo "$COMMAND" | grep -qE '\s--amend\b'; then
    exit 0
fi

# Allow merge commits (git commit with no -m, or merge messages)
if echo "$COMMAND" | grep -qiE '(merge|Merge)'; then
    exit 0
fi

# Allow bd sync commits (these are automated)
if echo "$COMMAND" | grep -qE 'bd sync'; then
    exit 0
fi

# Allow commits that don't have -m (interactive editor — likely merge commits)
if ! echo "$COMMAND" | grep -qE '\s-m\s'; then
    exit 0
fi

# Check for ticket ID pattern: arcology-[a-z0-9]
if echo "$COMMAND" | grep -qE 'arcology-[a-z0-9]'; then
    exit 0
fi

# No ticket ID found — block the commit
echo "BLOCKED: Commit message must include a ticket ID (e.g., arcology-abc)." >&2
echo "" >&2
echo "Either:" >&2
echo "  1. Include a ticket ID: git commit -m \"feat: arcology-xyz - Description\"" >&2
echo "  2. Create a ticket first: bd create \"Description\" -t task -p 2" >&2
echo "  3. Find an existing ticket: bd search \"keyword\"" >&2
echo "" >&2
exit 2
