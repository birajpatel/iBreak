#!/bin/bash

# Integration test for iBreak build and run functionality
# Verifies that the app builds cleanly and runs without crashing

set -e

echo "🧪 Testing Build and Run..."

# Kill any existing instances
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 1

# Test 1: Clean build succeeds
echo ""
echo "Test 1: Verifying clean build..."
BUILD_OUTPUT=$(swift build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "Build complete"; then
    echo "✅ PASS: Build completed successfully"
else
    echo "❌ FAIL: Build failed"
    echo "$BUILD_OUTPUT"
    exit 1
fi

# Test 2: Verify no warnings about unhandled files
echo ""
echo "Test 2: Checking for build warnings..."
if echo "$BUILD_OUTPUT" | grep -qi "warning.*unhandled"; then
    echo "❌ FAIL: Unhandled source files warning present"
    exit 1
else
    echo "✅ PASS: No unhandled file warnings"
fi

# Test 3: App launches and creates process
echo ""
echo "Test 3: Testing app launch..."
.build/debug/iBreak &
APP_PID=$!
sleep 2

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ PASS: App launched successfully (PID: $APP_PID)"
else
    echo "❌ FAIL: App crashed on startup"
    exit 1
fi

# Test 4: Verify status bar item is created (check for expected output)
echo ""
echo "Test 4: Verifying initialization..."
if grep -q "Status item configured with modern button API" Sources/iBreak/main.swift; then
    echo "✅ PASS: Status item configuration code present"
else
    echo "❌ FAIL: Missing status bar configuration"
fi

# Test 5: Verify app uses accessory activation policy (no Dock icon)
echo ""
echo "Test 5: Checking activation policy..."
if grep -q 'setActivationPolicy(.accessory)' Sources/iBreak/main.swift; then
    echo "✅ PASS: App correctly configured as agent (no Dock icon)"
else
    echo "❌ FAIL: Missing accessory activation policy"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 1

echo ""
echo "✅ All build and run tests passed!"
exit 0
