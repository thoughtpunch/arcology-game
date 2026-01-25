#!/bin/bash
# TIER 0: Parse Check (<1 second)
# Verifies GDScript syntax without running the game
# Run: ./scripts/qa/check.sh

set -e
cd "$(dirname "$0")/../.."

echo "🔍 Tier 0: Parse Check"

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "⚠️  Godot not found in PATH. Skipping parse check."
    echo "   Install Godot or add to PATH to enable."
    exit 0
fi

# Check if project exists
if [ ! -f "project.godot" ]; then
    echo "⚠️  No project.godot found. Skipping."
    exit 0
fi

# Run parse check
if godot --headless --check-only --path . 2>&1; then
    echo "✅ Parse check passed"
    exit 0
else
    echo "❌ Parse errors found"
    exit 1
fi
