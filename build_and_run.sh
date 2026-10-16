#!/bin/bash

# iBreak - Build and Run Script
# This script builds the app and launches it in the status bar as an agent (no Dock icon)

set -e  # Exit on any error

echo "🚀 Building iBreak..."

# Navigate to project directory (script location)
cd "$(dirname "$0")"

# Clean previous build (optional, uncomment if needed)
# echo "🧹 Cleaning previous build..."
# rm -rf .build/

# Build the app
swift build 2>&1 | tail -5 || true

echo ""
echo "✅ Build successful!"
echo "📱 Starting iBreak in status bar..."

# Kill any existing instance first
pkill -f ".build/.*iBreak" 2>/dev/null || true
sleep 0.5

# Run the app (background process — agent mode, no Dock icon)
.build/debug/iBreak &

echo ""
echo "✨ iBreak is now running!"
echo "📍 Look for 👁️ in your menu bar"
echo ""
echo "To stop: pkill -f '.build/.*iBreak'"