//
//  main.swift
//  iBreak - Eye Care Reminder App for macOS
//

import Cocoa
import SwiftUI
import Foundation

/// Main application delegate that manages the status bar item and break timer
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    private var statusItemController: StatusItemController?
    private var breakTimer: Timer?
    
    // Configuration — 20 minutes between breaks (standard eye care recommendation)
    private let defaultBreakInterval: TimeInterval = 20 * 60     // 20 min production
    private let breakDuration: TimeInterval = 20                // 20 sec auto-dismiss

    // State tracking
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
        NSApp.setActivationPolicy(.accessory)
        seedStatusItemPosition()
        statusItemController = StatusItemController(delegate: self)
        startBreakTimer()
        print("✅ iBreak: Status bar item created and timer started")
    }

    func applicationWillTerminate(_ notification: Notification) { stopTimers() }

    // MARK: - Status Bar Position
    private func seedStatusItemPosition() {
        let key = "NSStatusItem Preferred Position iBreak"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(0, forKey: key)
        }
    }

    // MARK: - Timer Management
    /// Start or restart the break timer with proper interval
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

    /// Update the countdown and trigger break when needed
    @objc private func updateCountdown() {
        guard !isBreakActive else { return }
        timeToNextBreak -= 1
        if timeToNextBreak <= 0 { triggerBreak() }
    }

    // MARK: - Break Logic
    /// Trigger a break notification window
    private func triggerBreak() {
        guard !isBreakActive else { return }
        isBreakActive = true
        statusItemController?.updateTitle()  // Show pause indicator in status bar
        stopTimers()

        if breakWindowController == nil {
            breakWindowController = BreakWindowController(delegate: self)
        }
        breakWindowController?.showWindow(self)

        // Auto-dismiss after 20 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + breakDuration) { [weak self] in
            guard let self = self, self.isBreakActive else { return }
            self.dismissBreak()
        }
    }

    /// Take an immediate break (from status bar menu or status item click)
    @objc func takeImmediateBreak() {
        guard !isBreakActive else { return }
        stopTimers()
        triggerBreak()
    }

    /// Skip the current break and reset timer with short delay to prevent spam
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

    /// Snooze the break for a short period (5 minutes) — closes window, sets 5-min countdown
    func snoozeBreak() {
        timeToNextBreak = 5 * 60 // 5 minutes from now
        updateStatusBarDisplay()
        dismissCurrentBreakWindow(action: .snooze)
    }

    /// Dismiss the current break window (auto-dismiss path — full reset to 20 min)
    private func dismissBreak() {
        guard isBreakActive else { return }
        timeToNextBreak = defaultBreakInterval // Full interval reset before restarting timer
        dismissCurrentBreakWindow(action: nil)
    }

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

    /// Update the status bar display
    private func updateStatusBarDisplay() {
        NotificationCenter.default.post(
            name: .statusBarUpdate,
            object: nil,
            userInfo: ["timeToNextBreak": timeToNextBreak, "isBreakActive": isBreakActive]
        )
    }

    /// Update the status bar item title with remaining time (MM:SS format)
    private func updateStatusItemTitle() {
        statusItemController?.updateTitle()
    }

    /// Stop all active timers
    func stopTimers() { breakTimer?.invalidate(); breakTimer = nil }
}


// MARK: - Notifications
extension Notification.Name {
    static let statusBarUpdate = Notification.Name("StatusBarUpdate")
    static let timeToNextBreakChanged = Notification.Name("TimeToNextBreakChanged")
    static let breakStateChanged = Notification.Name("BreakStateChanged")
}

// MARK: - Break Action Enum
enum BreakAction { case snooze; case skip }

// MARK: - Status Item Controller (Modern macOS 27 / Tahoe Pattern)
@MainActor final class StatusItemController: NSObject {
    private weak var appDelegate: AppDelegate?
    private let statusItem: NSStatusItem

    init(delegate: AppDelegate) {
        self.appDelegate = delegate
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }

    /// Format time interval as MM:SS string
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Update the status bar title with remaining time (MM:SS format)
    func updateTitle() {
        guard let button = statusItem.button else { return }
        if appDelegate?.isBreakActive == true {
            button.title = "⏸️"
        } else {
            button.title = formatTime(appDelegate?.timeToNextBreak ?? 0)
        }
    }

    private func configureStatusItem() {
        statusItem.autosaveName = "iBreak"
        guard let button = statusItem.button else { return }
        
        if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "iBreak") {
            image.isTemplate = true
            button.image = image
        }
        
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        button.sendAction(on: [.leftMouseUp])  // Critical fix for macOS 27
        statusItem.menu = buildMenu()
        statusItem.isVisible = true  // Force visibility override
        updateTitle()  // Show initial time in status bar
        print("✅ Status item configured with modern button API")
    }

    @objc private func statusBarButtonClicked() {
        guard let delegate = appDelegate else { return }
        if NSApp.currentEvent?.type == .rightMouseUp || NSEvent.modifierFlags.contains(.control) { return }
        delegate.takeImmediateBreak()  // Left-click: trigger immediate break
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "iBreak")
        
        let takeBreakItem = NSMenuItem(title: "Take a Break Now", action: #selector(takeBreakNow), keyEquivalent: "")
        takeBreakItem.target = self; menu.addItem(takeBreakItem)
        menu.addItem(.separator())
        
        let skipItem = NSMenuItem(title: "Skip This Break", action: #selector(skipBreak), keyEquivalent: "")
        skipItem.target = self; menu.addItem(skipItem)
        menu.addItem(.separator())
        
        let quitItem = NSMenuItem(title: "Quit iBreak", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self; menu.addItem(quitItem)
        return menu
    }

    @objc private func takeBreakNow() { appDelegate?.takeImmediateBreak() }
    @objc private func skipBreak() { appDelegate?.skipBreak() }
    @objc private func quitApp() { NSApp.terminate(nil) }
}

// MARK: - Break Window Controller (On-Top, Auto-Dismiss)
final class BreakWindowController: NSWindowController {
    private weak var delegate: AppDelegate?
    private let viewModel = BreakViewModel()

    init(delegate: AppDelegate) {
        self.delegate = delegate; super.init(window: nil); setupWindow()
        BreakSoundManager.shared.playBreakStart()  // Entry sound
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupWindow() {
        let panel = NSPanel(contentRect: NSMakeRect(0, 0, 420, 350), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.isOpaque = true; panel.backgroundColor = NSColor.white
        panel.titleVisibility = .visible; panel.isFloatingPanel = true

        if let screen = NSScreen.main {
            let sf = screen.frame; let ws = CGSize(width: 420, height: 350)
            panel.setFrame(NSRect(x: sf.midX - ws.width/2, y: sf.midY - ws.height/2, width: ws.width, height: ws.height), display: true)
        }

        let breakDialogView = BreakDialogView(viewModel: viewModel) { [weak self] action in self?.handleAction(action) }
        panel.contentView = breakDialogView; panel.title = "Eye Care Reminder"; panel.isReleasedWhenClosed = false
        panel.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1); panel.makeKeyAndOrderFront(nil)
        self.window = panel
    }

    override func showWindow(_ sender: Any?) {
        viewModel.isShowing = true; viewModel.startCountdown()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(sender)
        window?.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1)
    }

    func closeWindow() {
        viewModel.stopCountdown(); viewModel.isShowing = false; BreakSoundManager.shared.playBreakEnd()
        window?.close()
    }

    private func handleAction(_ action: BreakAction) {
        switch action {
        case .snooze: delegate?.breakWindowDismissed(action: .snooze)
        case .skip:   delegate?.breakWindowDismissed(action: .skip)
        }
    }
}

// MARK: - View Model (pure Swift, no SwiftUI dependency for the dialog)
final class BreakViewModel: ObservableObject {
    @Published var isShowing = true
    let breakMessage = "Time to take a break!"
    let instructionText = "Look away from your screen and focus on something at least 20 feet away."

    /// Countdown timer display (seconds remaining until auto-dismiss)
    @Published var countdown: Int = 20 { didSet { secondsRemaining = countdown } }
    private(set) var secondsRemaining: Int = 20
    private var countdownTimer: Timer?

    func startCountdown() {
        stopCountdown(); countdown = 20
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 { self.countdown -= 1 } else { self.stopCountdown() }
        }
    }

    func stopCountdown() { countdownTimer?.invalidate(); countdownTimer = nil }
}

// MARK: - Sound Manager
final class BreakSoundManager: @unchecked Sendable {
    static let shared = BreakSoundManager()
    func playBreakStart() { play(soundNamed: "Glass") }
    func playBreakEnd() { play(soundNamed: "Purr") }
    private func play(soundNamed name: String) { if let sound = NSSound(named: name) { sound.play() } }
}

// MARK: - Break Dialog View (Pure AppKit — no NSHostingView/SwiftUI)
final class BreakDialogView: NSView {
    private let viewModel: BreakViewModel; private let onAction: (BreakAction) -> Void

    init(viewModel: BreakViewModel, onAction: @escaping (BreakAction) -> Void) {
        self.viewModel = viewModel; self.onAction = onAction
        super.init(frame: NSRect(x: 0, y: 0, width: 420, height: 320))
        setupView()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }

    private func setupView() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let titleAttr: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 28, weight: .bold)]
        let countAttr: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .medium)]
        let instrAttr: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 15)]

        let iconImageView = NSImageView()
        if #available(macOS 13.0, *) { iconImageView.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil) }
        iconImageView.imageScaling = .scaleAxesIndependently

        let titleLabel = NSTextField(labelWithAttributedString: NSAttributedString(string: viewModel.breakMessage, attributes: titleAttr))
        titleLabel.isBezeled = false; titleLabel.isEditable = false; titleLabel.drawsBackground = false; titleLabel.isSelectable = false

        let countdownLabel = NSTextField(labelWithAttributedString: NSAttributedString(string: "Auto-dismissing in \(viewModel.secondsRemaining)s", attributes: countAttr))
        countdownLabel.isBezeled = false; countdownLabel.isEditable = false; countdownLabel.drawsBackground = false; countdownLabel.isSelectable = false

        let instructionLabel = NSTextField(labelWithAttributedString: NSAttributedString(string: viewModel.instructionText, attributes: instrAttr))
        instructionLabel.isBezeled = false; instructionLabel.isEditable = false; instructionLabel.drawsBackground = false; instructionLabel.isSelectable = false

        let vStack = NSStackView(views: [iconImageView, titleLabel, countdownLabel, instructionLabel])
        vStack.alignment = .centerX; vStack.distribution = .fillProportionally; vStack.spacing = 20; vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)

        let skipButton = NSButton(title: "Skip Break", target: self, action: #selector(skipClicked))
        skipButton.bezelStyle = .rounded
        let snoozeButton = NSButton(title: "Snooze (5 min)", target: self, action: #selector(snoozeClicked))
        snoozeButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [snoozeButton, skipButton])
        buttonStack.alignment = .centerX; buttonStack.distribution = .fillEqually; buttonStack.spacing = 20; buttonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStack)

        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            vStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            vStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            buttonStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 30),
            buttonStack.widthAnchor.constraint(equalToConstant: 280)
        ])

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            countdownLabel.attributedStringValue = NSAttributedString(string: "Auto-dismissing in \(self.viewModel.secondsRemaining)s", attributes: countAttr)
        }
    }

    @objc private func skipClicked() { onAction(.skip) }
    @objc private func snoozeClicked() { onAction(.snooze) }
}


// MARK: - App Entry Point
let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate
print("🚀 iBreak starting up...")
app.activate(ignoringOtherApps: false); app.run()
