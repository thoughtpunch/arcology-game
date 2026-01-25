#!/bin/bash
# TIER 2: Smoke Test (~5 seconds)
# Loads main scene, runs 1 frame, verifies no crash
# Run: ./scripts/qa/smoke.sh

set -e
cd "$(dirname "$0")/../.."

echo "💨 Tier 2: Smoke Test"

# First run Tier 0+1
./scripts/qa/check.sh || exit 1
# Skip Tier 1 if no tests exist (check.sh is enough)

# Check if smoke test exists
if [ ! -f "tests/smoke_test.gd" ]; then
    echo "⚠️  No smoke test found at tests/smoke_test.gd"
    echo "   Create smoke test to enable this tier."
    exit 0
fi

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "⚠️  Godot not found. Skipping smoke test."
    exit 0
fi

# Smoke test needs a display (or Xvfb)
# Try headless first, fall back to Xvfb if available
echo "Running smoke test..."

# Try headless mode first (works for scene loading, not rendering)
if godot --headless --path . --script res://tests/smoke_test.gd 2>&1; then
    echo "✅ Smoke test passed"
    exit 0
else
    echo "❌ Smoke test failed"
    exit 1
fi
