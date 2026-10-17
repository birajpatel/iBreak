//  App.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa
import Foundation

/// Main application delegate that manages the status bar item and break timer.
/// Conforms to BreakDelegate protocol for loose coupling with UI components.
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, BreakDelegate, TimeProvider {
    
    // MARK: - Properties
    
    private var statusItemController: StatusItemController?
    private var breakTimer: Timer?
    
    // Configuration — 20 minutes between breaks (standard eye care recommendation)
    private let defaultBreakInterval: TimeInterval = 20 * 60     // Production value
    private let breakDuration: TimeInterval = 20                // Auto-dismiss after 20 seconds
    
    // State tracking with observable properties
    private(set) var timeToNextBreak: TimeInterval = 60 * 20 { // Initialize to full interval (seconds)
        didSet {
            NotificationCenter.default.post(name: .timeToNextBreakChanged, object: nil)
            updateStatusItemTitle()
        }
    }
    
    private(set) var isBreakActive = false {
        didSet { NotificationCenter.default.post(name: .breakStateChanged, object: nil) }
    }
    
    // Break window management
    private var breakWindowController: BreakWindowController?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("📱 iBreak: Application did finish launching")
        
        // Agent app — no Dock icon, no ⌘-Tab entry (macOS 27 / Tahoe compatible)
        NSApp.setActivationPolicy(.accessory)
        
        seedStatusItemPosition()
        statusItemController = StatusItemController(delegate: self, timeSource: self)
        startBreakTimer()
        
        // Handle display sleep/wake to preserve countdown state
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayDidWake),
            name: .screenParametersChanged,
            object: nil
        )
        
        print("✅ iBreak: Status bar item created and timer started")
    }
    
    func applicationWillTerminate(_ notification: Notification) { stopTimers() }
    
    // MARK: - Status Bar Position
    
    /// Seed the status item preferred position so our icon is visible (away from notch).
    private func seedStatusItemPosition() {
        let key = "NSStatusItem Preferred Position iBreak"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(0, forKey: key) // Claim slot at right end
        }
    }
    
    // MARK: - Timer Management
    
    /// Start or restart the break timer with proper interval.
    func startBreakTimer() {
        stopTimers()
        isBreakActive = false
        timeToNextBreak = defaultBreakInterval  // Reset to full interval (20 min)
        
        breakTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateCountdown),
            userInfo: nil,
            repeats: true
        )
    }
    
    /// Update the countdown and trigger break when needed.
    @objc private func updateCountdown() {
        guard !isBreakActive else { return }
        timeToNextBreak -= 1
        if timeToNextBreak <= 0 { triggerBreak() }
    }
    
    // MARK: - Break Logic
    
    /// Trigger a break notification window.
    private func triggerBreak() {
        guard !isBreakActive else { return }
        isBreakActive = true
        statusItemController?.updateTitle()  // Show pause indicator in status bar
        stopTimers()

        if breakWindowController == nil {
            breakWindowController = BreakWindowController(delegate: self)
        }
        breakWindowController?.showWindow(self)

        // Auto-dismiss after configured duration
        DispatchQueue.main.asyncAfter(deadline: .now() + breakDuration) { [weak self] in
            guard let self = self, self.isBreakActive else { return }
            self.dismissBreak()
        }
    }
    
    /// Take an immediate break (from status bar menu or status item click).
    @objc func takeImmediateBreak() {
        guard !isBreakActive else { return }
        stopTimers()
        triggerBreak()
    }
    
    /// Skip the current break and reset timer with short delay to prevent spam.
    @objc func skipBreak() {
        if isBreakActive {
            timeToNextBreak = 30 // Give user 30 seconds before next break
            dismissCurrentBreakWindow(action: .skip)
        } else {
            // No active break - just reset the timer to give a fresh start
            stopTimers()
            startBreakTimer() // Restart with full interval
            statusItemController?.updateTitle()
        }
    }
    
    /// Snooze the break for 5 minutes — closes window, sets 5-min countdown.
    func snoozeBreak() {
        timeToNextBreak = 5 * 60 // 5 minutes from now
        updateStatusBarDisplay()
        dismissCurrentBreakWindow(action: .snooze)
    }
    
    /// Dismiss the current break window (auto-dismiss path — full reset to 20 min).
    private func dismissBreak() {
        guard isBreakActive else { return }
        timeToNextBreak = defaultBreakInterval // Full interval reset before restarting timer
        dismissCurrentBreakWindow(action: nil)
    }
    
    // MARK: - BreakDelegate Protocol Methods
    
    /// Called by BreakWindowController when user clicks Skip/Snooze, or internally for auto-dismiss.
    func breakWindowDismissed(action: BreakAction? = nil) {
        guard isBreakActive else { return }
        dismissCurrentBreakWindow(action: action)
    }
    
    private func dismissCurrentBreakWindow(action: BreakAction?) {
        isBreakActive = false
        statusItemController?.updateTitle()  // Restore time display in status bar
        breakWindowController?.closeWindow() // Closes window + stops countdown + plays exit sound

        switch action {
        case .snooze:
            timeToNextBreak = 5 * 60 // Set snooze duration before starting timer
            stopTimers()
            isBreakActive = false
            breakTimer = Timer.scheduledTimer(
                timeInterval: 1.0,
                target: self,
                selector: #selector(updateCountdown),
                userInfo: nil,
                repeats: true
            )
        default: // .skip, nil (auto-dismiss)
            startBreakTimer() // Resume from full interval (20 min) — NOT immediate!
        }
    }
    
    /// Update the status bar display.
    private func updateStatusBarDisplay() {
        NotificationCenter.default.post(
            name: .statusBarUpdate,
            object: nil,
            userInfo: [
                StatusBarUserInfoKey.timeToNextBreak: timeToNextBreak,
                StatusBarUserInfoKey.isBreakActive: isBreakActive
            ]
        )
    }

    /// Update the status bar item title with remaining time (MM:SS format).
    private func updateStatusItemTitle() {
        statusItemController?.updateTitle()
    }
    
    /// Resume countdown from a specific time (used after display wake)
    private func resumeCountdown(from remainingSeconds: TimeInterval) {
        var timeLeft = Int(remainingSeconds)
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if timeLeft > 0 {
                timeLeft -= 1
                self.timeToNextBreak = TimeInterval(timeLeft)
            } else {
                timer.invalidate()
                self.breakTimer = nil
                self.triggerBreak()
            }
        }
    }

    /// Handle display wake - restore countdown state that may have been lost during sleep
    @objc private func displayDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // If we were counting down but timer got suspended, resume from saved time
            if !self.isBreakActive && self.breakTimer == nil && self.timeToNextBreak > 0 {
                print("🔄 Resuming break countdown after display wake")
                self.resumeCountdown(from: self.timeToNextBreak)
            }
        }
    }

    /// Stop all active timers.
    func stopTimers() { breakTimer?.invalidate(); breakTimer = nil }
}

// MARK: - App Entry Point
let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate
print("🚀 iBreak starting up...")
app.activate(ignoringOtherApps: false); app.run()
