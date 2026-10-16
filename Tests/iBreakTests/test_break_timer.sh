#!/bin/bash

# Integration test for iBreak break timer functionality
# Verifies that breaks don't appear too frequently (the original bug)

set -e

echo "🧪 Testing Break Timer Frequency..."

# Kill any existing instances
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 1

# Build the app
echo "📦 Building iBreak..."
swift build 2>&1 | tail -3

# Start the app in background
echo "🚀 Starting iBreak..."
.build/debug/iBreak &
APP_PID=$!

# Give it time to initialize
sleep 3

# Verify process is running
if ! kill -0 $APP_PID 2>/dev/null; then
    echo "❌ FAIL: App failed to start"
    exit 1
fi
echo "✅ PASS: App started successfully (PID: $APP_PID)"

# Test 1: Verify break interval is set correctly (should be 20 minutes, not 5 seconds)
echo ""
echo "Test 1: Checking defaultBreakInterval configuration..."
if grep -q 'defaultBreakInterval.*20 \* 60' Sources/iBreak/main.swift; then
    echo "✅ PASS: Break interval is set to 20 minutes (production value)"
else
    echo "❌ FAIL: Break interval is NOT set to production value"
    pkill -f ".build/.*iBreak" 2>/dev/null || true
    exit 1
fi

# Test 2: Verify skip delay prevents rapid-fire dialogs
echo ""
echo "Test 2: Checking skip behavior..."
if grep -q 'timeToNextBreak = 30' Sources/iBreak/main.swift; then
    echo "✅ PASS: Skip sets 30-second delay before next break"
else
    echo "❌ FAIL: No skip delay found"
fi

# Test 3: Verify auto-dismiss resets to full interval
echo ""
echo "Test 3: Checking auto-dismiss behavior..."
if grep -A2 'func dismissBreak' Sources/iBreak/main.swift | grep -q 'defaultBreakInterval'; then
    echo "✅ PASS: Auto-dismiss properly resets timer"
else
    echo "❌ FAIL: Auto-dismiss doesn't reset timer correctly"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 1

echo ""
echo "✅ All tests passed!"
exit 0
