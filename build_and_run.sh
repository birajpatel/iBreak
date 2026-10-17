#!/bin/bash

# iBreak - Build, Run & Install Script
# Builds the app and launches it in the status bar as an agent (no Dock icon)

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Building iBreak..."
echo ""

# Check Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift compiler not found. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Build the app with verbose error reporting
echo "🔧 Compiling sources..."
BUILD_OUTPUT=$(swift build 2>&1) || {
    echo "$BUILD_OUTPUT" | tail -20
    echo ""
    echo "❌ Build failed! See errors above."
    exit 1
}

# Check for successful compilation
if ! swift build 2>&1 | grep -q "Build complete"; then
    echo "⚠️ Warning: Unexpected output during build"
fi

echo "✅ Build successful!"
echo ""

# Kill any existing instance first  
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 1

echo "📱 Starting iBreak in status bar..."

# Run the app (background process — agent mode, no Dock icon)
.build/debug/iBreak &

sleep 2

if pgrep -f ".build/.*iBreak" > /dev/null; then
    echo ""
    echo "✨ iBreak is now running! 👁️"
    echo ""
    echo "📍 Features:"  
    echo "   • Live MM:SS countdown in menu bar (light theme)"
    echo "   • Break reminders every 20 minutes by default"
    echo "   • Skips/Snoozes work anytime from menu"
    echo "   • Preserves timer state during display sleep/wake"
    echo ""
    echo "🛠️ To stop: pkill -f '.build/.*iBreak'"
else
    echo ""
    echo "❌ Failed to start iBreak. Check console for details."
    exit 1
fi