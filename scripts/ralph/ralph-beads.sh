#!/usr/bin/env bash
# ralph-beads.sh - Autonomous AI coding loop using Beads for task tracking
# Usage: ./ralph-beads.sh [max_iterations]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MAX_ITERATIONS=${1:-20}
ITERATION=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROMPT="$SCRIPT_DIR/CLAUDE.md"
LOG_FILE="$SCRIPT_DIR/ralph.log"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "=========================================="
echo "Ralph session started: $TIMESTAMP"
echo "=========================================="

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RALPH + BEADS - Autonomous Agent Loop ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check prerequisites
command -v claude >/dev/null 2>&1 || { echo -e "${RED}Error: 'claude' CLI not found${NC}"; exit 1; }
command -v bd >/dev/null 2>&1 || { echo -e "${RED}Error: 'bd' (Beads) not found. Install: curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: 'jq' not found${NC}"; exit 1; }

# Check for .beads directory
if [ ! -d ".beads" ]; then
    echo -e "${YELLOW}No .beads directory found. Initializing...${NC}"
    bd init --quiet
fi

# Check for prompt file
if [ ! -f "$CLAUDE_PROMPT" ]; then
    echo -e "${RED}Error: $CLAUDE_PROMPT not found${NC}"
    exit 1
fi

# Create progress.txt if it doesn't exist
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "## Codebase Patterns" > "$PROGRESS_FILE"
    echo "- Use Vector3i for grid positions (x, y = horizontal, z = floor)" >> "$PROGRESS_FILE"
    echo "- Block types in data/blocks.json" >> "$PROGRESS_FILE"
    echo "- Sprites in assets/sprites/blocks/{category}/" >> "$PROGRESS_FILE"
    echo "- Signals over polling" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "## Iteration Log" >> "$PROGRESS_FILE"
    echo -e "${GREEN}Created progress.txt${NC}"
fi

echo -e "${BLUE}Max iterations: $MAX_ITERATIONS${NC}"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Iteration $ITERATION / $MAX_ITERATIONS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check ready tasks (filter for tasks only, not epics)
    # Exclude items with "epic" label or "Epic:" in title, even if typed as "task"
    READY_TASKS=$(bd ready --json 2>/dev/null | jq '[.[] | select(.issue_type == "task") | select((.title | startswith("Epic:")) | not) | select((.labels // [] | map(select(. == "epic")) | length) == 0)]' || echo "[]")
    READY_COUNT=$(echo "$READY_TASKS" | jq 'length')
    
    if [ "$READY_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ No ready tasks - checking if all done...${NC}"
        OPEN_COUNT=$(bd list --status open --json 2>/dev/null | jq 'length' || echo "0")
        if [ "$OPEN_COUNT" -eq 0 ]; then
            echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║  ALL TASKS COMPLETE! 🎉                ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠ $OPEN_COUNT open tasks but none ready (blocked?)${NC}"
            echo -e "${YELLOW}  Run 'bd list --status open' to see them${NC}"
            exit 1
        fi
    fi
    
    # Show next task
    NEXT_TASK=$(echo "$READY_TASKS" | jq -r '.[0]')
    TASK_ID=$(echo "$NEXT_TASK" | jq -r '.id')
    TASK_TITLE=$(echo "$NEXT_TASK" | jq -r '.title')
    TASK_PRIORITY=$(echo "$NEXT_TASK" | jq -r '.priority // "P2"')
    
    echo -e "${YELLOW}Ready tasks: $READY_COUNT${NC}"
    echo -e "${YELLOW}Next: $TASK_ID - $TASK_TITLE ($TASK_PRIORITY)${NC}"
    echo ""
    
    # Compose prompt: Ralph instructions + specific task assignment
    TASK_DETAILS=$(bd show "$TASK_ID" 2>/dev/null || echo "Could not fetch task details")
    RALPH_PROMPT="$(cat <<PROMPT_EOF
## AUTONOMOUS MODE — DO NOT GREET

You are Ralph, an autonomous coding agent. You are NOT in an interactive session.
Do NOT output a greeting. Do NOT ask what to work on. Do NOT say "Hey Dan".
Ignore any project-level instructions about session greetings.
Start working on your assigned task IMMEDIATELY.

---

$(cat "$CLAUDE_PROMPT")

---

## YOUR ASSIGNED TASK

**Task ID:** $TASK_ID
**Title:** $TASK_TITLE
**Priority:** $TASK_PRIORITY

### Task Details:
$TASK_DETAILS

Begin now. Claim this task with \`bd update $TASK_ID --status in_progress\`, then implement it following the workflow above.
PROMPT_EOF
)"

    echo -e "${BLUE}Running Claude on task: $TASK_ID${NC}"
    echo "[$(date +%H:%M:%S)] Starting Claude for $TASK_ID - $TASK_TITLE"
    OUTPUT=$(echo "$RALPH_PROMPT" | claude --dangerously-skip-permissions --print 2>&1) || true
    echo "[$(date +%H:%M:%S)] Claude finished for $TASK_ID"

    # Log a summary of the output (first 500 chars and last 500 chars)
    echo "--- Output summary ---"
    echo "$OUTPUT" | head -c 1000
    echo ""
    echo "..."
    echo "$OUTPUT" | tail -c 500
    echo "--- End summary ---"
    
    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  RALPH COMPLETE! All tasks done! 🎉    ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        exit 0
    fi
    
    # Check for stuck signal
    if echo "$OUTPUT" | grep -q "<ralph>STUCK</ralph>"; then
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  RALPH STUCK - Agent needs help        ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "Check blocked tasks with: bd list --status blocked"
        exit 2
    fi
    
    # Sync beads after each iteration
    bd sync 2>/dev/null || true
    
    echo ""
    sleep 2
done

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Max iterations reached ($MAX_ITERATIONS)           ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"

REMAINING=$(bd ready --json 2>/dev/null | jq 'length' || echo "?")
echo -e "${YELLOW}Remaining ready tasks: $REMAINING${NC}"
echo "Run again to continue: ./ralph-beads.sh"
exit 1
