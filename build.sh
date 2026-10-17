#!/bin/bash

# iBreak - Unified Build System
# Handles both rapid development cycles and production installations seamlessly.

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="iBreak.app"
RELEASE_BUILD=".build/release/iBreak"
DEBUG_BUILD=".build/debug/iBreak"
INSTALL_PATH="/Users/biraj/Applications/${APP_NAME}"

# --- Usage Information ---
show_usage() {
    cat << 'EOF'
🚀 iBreak - Unified Build System

Usage: ./build.sh [OPTIONS]

Modes (mutually exclusive):
  --dev,   -d   Development mode (default)  🔧
      Builds in debug mode and runs directly from .build/debug/
      Perfect for rapid iteration while coding.

  --install,-i  Production installation      📦
      Builds optimized release binary into proper macOS .app bundle
      Installs to ~/Applications/iBreak.app and launches it.

Other Options:
  --help,   -h  Show this help message

Examples:
  ./build.sh              # Development mode (default)
  ./build.sh --dev        # Explicit development mode  
  ./build.sh --install    # Production install with .app bundle
EOF
}

# --- Kill existing instances safely ---
kill_existing() {
    echo "🧹 Stopping any running iBreak instances..." >&2
    pkill -9 -f "\.build/.*/iBreak" 2>/dev/null || true
    if [ -d "${INSTALL_PATH}" ]; then
        rm -rf "${INSTALL_PATH}" && echo "   🗑️ Removed old app bundle." >&2
    fi
    sleep 1
}

# --- Build function with mode selection ---
build() {
    local mode="$1"
    local build_path=""
    
    if [ "$mode" = "release" ]; then
        echo "" >&2
        echo "🔧 Building optimized release binary..." >&2
        swift build -c release 2>&1 | tail -3 || { echo "❌ Release build failed!"; exit 1; }
        build_path="$RELEASE_BUILD"
    else
        echo "" >&2  
        echo "🔨 Building debug binary for development..." >&2
        swift build 2>&1 | tail -3 || { echo "❌ Debug build failed!"; exit 1; }
        build_path="$DEBUG_BUILD"
    fi

    if [ ! -f "$build_path" ]; then
        echo "❌ Build artifact not found at $build_path" >&2
        exit 1
    fi
    
    echo "✅ Binary built successfully." >&2
}

# --- Development workflow ---
run_dev() {
    build debug
    kill_existing
    
    echo "" >&2
    echo "🚀 Starting iBreak in development mode..." >&2
    "$DEBUG_BUILD" &
    sleep 2

    if pgrep -f "\.build/debug/iBreak" > /dev/null; then
        cat << EOF

✨ iBreak is running! 👁️ (Development Mode)
📍 Menu bar: Eye icon with live countdown timer  
🔧 To stop: pkill -f '.build/.*iBreak'
EOF
    else
        echo "❌ Failed to start. Check console for details." >&2
        exit 1
    fi
}

# --- Production installation workflow ---
run_install() {
    build release
    kill_existing
    
    # Create proper .app bundle structure
    echo "" >&2
    echo "📦 Creating macOS app bundle..." >&2
    mkdir -p "${INSTALL_PATH}/Contents/MacOS"
    cp "$RELEASE_BUILD" "${INSTALL_PATH}/Contents/MacOS/iBreak"

    cat > "${INSTALL_PATH}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>iBreak</string>
    <key>CFBundleIdentifier</key><string>com.birajpatel.iBreak</string>  
    <key>CFBundleName</key><string>iBreak</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/> <!-- Agent app: no Dock icon -->
    <key>NSHumanReadableCopyright</key><string>Copyright © 2024 Biraj Patel.</string>
</dict>
</plist>
PLIST

    echo "✅ App bundle installed at: ${INSTALL_PATH}" >&2
    
    # Launch the app  
    echo "" >&2
    echo "🚀 Launching iBreak..." >&2
    "${INSTALL_PATH}/Contents/MacOS/iBreak" &
    sleep 2

    if pgrep -f "/Applications/${APP_NAME}/Contents/MacOS/iBreak" > /dev/null; then
        cat << EOF

✨ iBreak is installed and running! 👁️ (Production Mode)  
📍 Location: ${INSTALL_PATH}
🔧 To uninstall later: rm -rf '${INSTALL_PATH}'  
EOF
    else
        echo "❌ Failed to launch. Check console.app for details." >&2
        exit 1
    fi
}

# --- Parse Arguments ---
MODE="dev"  # Default mode

while [[ $# -gt 0 ]]; do
    case $1 in
        --install|-i) MODE="release"; shift ;;
        --dev|-d)     MODE="debug"; shift ;;
        --help|-h)    show_usage; exit 0 ;;
        *) echo "❌ Unknown option: $1\nRun './build.sh --help' for usage."; exit 1 ;;
    esac
done

# --- Execute Based on Mode ---
case "$MODE" in
    dev|debug) run_dev ;;
    release)   run_install ;;
esac