#!/bin/bash
# TIER 1: Unit Tests (~2 seconds)
# Runs pure logic tests without rendering
# Run: ./scripts/qa/test.sh

set -e
cd "$(dirname "$0")/../.."

echo "🧪 Tier 1: Unit Tests"

# First run Tier 0
./scripts/qa/check.sh || exit 1

# Check if test runner exists
if [ ! -f "tests/unit_tests.gd" ]; then
    echo "⚠️  No unit tests found at tests/unit_tests.gd"
    echo "   Create tests to enable this tier."
    exit 0
fi

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "⚠️  Godot not found. Skipping unit tests."
    exit 0
fi

# Run unit tests headless (no display needed)
echo "Running unit tests..."
if godot --headless --path . --script res://tests/unit_tests.gd 2>&1; then
    echo "✅ Unit tests passed"
    exit 0
else
    echo "❌ Unit tests failed"
    exit 1
fi
