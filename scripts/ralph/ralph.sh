#!/bin/bash
# Ralph - Autonomous AI coding loop for Claude Code
# Based on Geoffrey Huntley's Ralph pattern and snarktank/ralph
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Ralph - Autonomous Coding Agent for Arcology${NC}"
echo -e "${BLUE}  Max iterations: $MAX_ITERATIONS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Check for required tools
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: Claude Code CLI not found${NC}"
    echo "Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq not found${NC}"
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Check for required files
if [ ! -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    echo -e "${RED}Error: CLAUDE.md not found in $SCRIPT_DIR${NC}"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/prd.json" ]; then
    echo -e "${RED}Error: prd.json not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Initialize progress.txt if it doesn't exist
if [ ! -f "$SCRIPT_DIR/progress.txt" ]; then
    echo "## Codebase Patterns" > "$SCRIPT_DIR/progress.txt"
    echo "" >> "$SCRIPT_DIR/progress.txt"
    echo "---" >> "$SCRIPT_DIR/progress.txt"
    echo "" >> "$SCRIPT_DIR/progress.txt"
fi

# Function to count remaining stories
count_remaining() {
    jq '[.userStories[] | select(.passes == false)] | length' "$SCRIPT_DIR/prd.json"
}

# Function to get next story info
next_story() {
    jq -r '.userStories | map(select(.passes == false)) | sort_by(.priority) | .[0] | "\(.id): \(.title)"' "$SCRIPT_DIR/prd.json"
}

# Main loop
cd "$PROJECT_ROOT"

for i in $(seq 1 $MAX_ITERATIONS); do
    REMAINING=$(count_remaining)
    
    if [ "$REMAINING" -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ All stories complete! Ralph is done.${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        exit 0
    fi
    
    NEXT=$(next_story)
    
    echo ""
    echo -e "${YELLOW}═══ Iteration $i of $MAX_ITERATIONS ═══${NC}"
    echo -e "Remaining stories: ${REMAINING}"
    echo -e "Next: ${BLUE}$NEXT${NC}"
    echo ""
    
    # Run Claude Code with the prompt
    # --dangerously-skip-permissions allows autonomous operation
    # --print outputs to stdout (we capture it)
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr) || true
    
    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ All stories complete! Ralph is done.${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        exit 0
    fi
    
    # Check for stuck signal
    if echo "$OUTPUT" | grep -q "<ralph>STUCK</ralph>"; then
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ✗ Ralph is stuck! Check prd.json for blocked stories.${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
        exit 2
    fi
    
    # Brief pause between iterations
    sleep 2
done

echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Max iterations ($MAX_ITERATIONS) reached${NC}"
echo -e "${YELLOW}  Remaining stories: $(count_remaining)${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
exit 1
