#!/bin/bash
# TIER 3: Visual Test (~15 seconds)
# Renders game, takes screenshot for Claude to analyze
# Run: ./scripts/qa/visual.sh
#
# Requires: Xvfb (virtual display) OR a real display
# On Mac: Works with normal display
# On Linux headless: Needs Xvfb

set -e
cd "$(dirname "$0")/../.."

echo "📸 Tier 3: Visual Test"

# First run Tier 0
./scripts/qa/check.sh || exit 1

# Check if visual test exists
if [ ! -f "tests/visual_test.gd" ]; then
    echo "⚠️  No visual test found at tests/visual_test.gd"
    echo "   Create visual test to enable this tier."
    exit 0
fi

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "⚠️  Godot not found. Skipping visual test."
    exit 0
fi

# Create output directory
mkdir -p test_output

# Detect display situation
setup_display() {
    # Mac: always has display
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🖥️  Mac detected, using native display"
        return 0
    fi

    # Linux: check for display
    if [ -n "$DISPLAY" ]; then
        echo "🖥️  Display found: $DISPLAY"
        return 0
    fi

    # Try to start Xvfb
    if command -v Xvfb &> /dev/null; then
        echo "🖥️  Starting virtual display (Xvfb)..."
        Xvfb :99 -screen 0 1280x720x24 &
        XVFB_PID=$!
        export DISPLAY=:99
        sleep 1
        echo "   Virtual display started on :99"
        return 0
    fi

    echo "❌ No display available and Xvfb not found"
    echo "   Install Xvfb: apt-get install xvfb"
    return 1
}

cleanup() {
    if [ -n "$XVFB_PID" ]; then
        kill $XVFB_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Setup display
setup_display || exit 1

# Run visual test
echo "Running visual test..."
if godot --path . --script res://tests/visual_test.gd 2>&1; then
    echo ""
    echo "✅ Visual test completed"
    echo ""
    echo "📸 Screenshot saved to: test_output/screenshot.png"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│ CLAUDE: Read the screenshot at test_output/screenshot.png      │"
    echo "│ Verify: Does the game render correctly?                        │"
    echo "│ - Isometric grid visible?                                      │"
    echo "│ - Blocks rendering at correct positions?                       │"
    echo "│ - Y-sorting correct (depth ordering)?                          │"
    echo "│ - UI elements visible?                                         │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    exit 0
else
    echo "❌ Visual test failed"
    exit 1
fi
