# iBreak - Eye Care Reminder for macOS

![Swift](https://img.shields.io/badge/Swift-6.4-orange?style=for-the-badge&logo=swift)
![macOS](https://img.shields.io/badge/macOS-13+-blue?style=for-the-badge&logo=apple)

A lightweight menu bar app that reminds you to take regular breaks for your eye health, following the **20-20-20 rule**: every 20 minutes, look at something 20 feet away for 20 seconds.

## Features ✨

- 🍎 **Menu Bar Integration** - Status item showing live countdown timer (MM:SS format)
- ⏰ **Automatic Reminders** - Break dialogs appear every 20 minutes by default  
- 🎯 **On-Top Alerts** - Break windows display above all other apps on primary screen
- 🔊 **Sound Cues** - Attention-grabbing sound when break starts, gentle chime when dismissed
- ⌚ **Display Sleep Handling** - Preserves timer state across monitor sleep/wake cycles
- 🌓 **Light Theme** - Clean macOS-native interface with proper contrast ratios

## Installation 📦

### Prerequisites  
- macOS 13.0+ (Ventura or later)
- Xcode Command Line Tools: `xcode-select --install`

### Quick Start
```bash
# Clone the repository
git clone https://github.com/birajpatel/iBreak.git
cd iBreak

# Build and run  
./build_and_run.sh
```

Or manually build with Swift Package Manager:
```bash
swift build        # Compiles to .build/debug/iBreak
.build/debug/iBreak &  # Runs in menu bar (agent mode - no Dock icon)
```

## Usage 🚀

Once running, you'll see a 👁️ eye icon in your menu bar showing time remaining until the next break.

### Menu Options  
- **Take a Break Now** → Trigger an immediate break dialog
- **Skip This Break** → Reset timer (works anytime, even outside breaks)
- **Quit iBreak** → Exit completely (`⌘Q`)

### During Breaks  
Clicking "Snooze" delays the next break by 5 minutes. Clicking "Skip" resets to full interval. Dialog auto-dismisses after 20 seconds.

## Project Structure 📁

```
Sources/iBreak/
├── main.swift                  # App entry point + AppDelegate (MVVM pattern)  
├── Models/
│   ├── BreakAction.swift       # User action enum (.skip, .snooze)
│   └── Notifications.swift     # Custom Notification.Name extensions  
├── Protocols/                  # Loose coupling interfaces
│   ├── BreakDelegate.swift     
│   ├── TimeProvider.swift
│   └── SoundPlayer.swift
├── Views/
│   ├── StatusItemController.swift  # Menu bar management (modern button API)
│   ├── BreakWindowController.swift  # NSPanel lifecycle + positioning  
│   └── BreakDialogView.swift        # Custom NSView dialog UI
└── ViewModels/
    └── BreakViewModel.swift          # ObservableObject for countdown state

Tests/iBreakTests/                  # Integration tests (shell-based)
├── run_all_tests.sh                # Master test runner  
├── test_build_and_run.sh           # Verifies clean build + launch  
└── test_break_timer.sh             # Checks timer logic correctness
```

## Architecture Decisions 🏗️

- **Pure AppKit** - No SwiftUI dependencies for maximum compatibility with macOS 13+
- **Protocol-Oriented Design** - Uses `BreakDelegate`, `TimeProvider`, and `SoundPlayer` protocols enabling dependency injection and unit testing  
- **Single Executable Target** - All code compiled into one binary via Swift Package Manager
- **Agent Mode** - Runs as `.accessory` activation policy (no Dock icon, no ⌘Tab entry)

## Testing 🧪

Run the full test suite:
```bash
bash Tests/iBreakTests/run_all_tests.sh
# Or individually:
bash Tests/iBreakTests/test_build_and_run.sh   # Build verification
bash Tests/iBreakTests/test_break_timer.sh      # Timer logic checks
```

## Configuration ⚙️

Default timing values (hardcoded in `main.swift`):
- Break interval: 20 minutes (`defaultBreakInterval = 60 * 20`)  
- Auto-dismiss duration: 20 seconds (`breakDuration = 20`)
- Snooze length: 5 minutes (`timeToNextBreak = 5 * 60`)

## Contributing 🤝

Pull requests welcome! Please ensure all tests pass before submitting changes.

## License 📄

This project is provided as-is for educational purposes.