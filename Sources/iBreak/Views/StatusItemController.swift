//  StatusItemController.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Manages the NSStatusItem using modern button-based API.
@MainActor final class StatusItemController: NSObject {
    
    // MARK: - Properties
    
    private weak var delegate: (any BreakDelegate & AnyObject)?
    /// Holds reference to app's time state for display updates.
    private weak var timeSource: TimeProvider?
    private let statusItem: NSStatusItem
    
    // MARK: - Initialization
    
    init(delegate: BreakDelegate, timeSource: TimeProvider) {
        self.delegate = delegate
        self.timeSource = timeSource
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }
    
    // MARK: - Public Methods
    
    /// Update the status bar title with remaining time (MM:SS format).
    func updateTitle() {
        guard let button = statusItem.button else { return }
        if timeSource?.isBreakActive == true {
            button.title = "⏸️"
        } else {
            button.title = formatTime(timeSource?.timeToNextBreak ?? 0)
        }
    }
    
    // MARK: - Private Setup
    
    private func configureStatusItem() {
        statusItem.autosaveName = "iBreak"
        
        guard let button = statusItem.button else { return }
        
        // Set system image directly — NO custom NSView needed
        if let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "iBreak") {
            image.isTemplate = true
            button.image = image
        }
        
        // Modern API: set target/action on BUTTON (not deprecated NSStatusItem.target)
        button.target = self
        button.action = #selector(statusBarButtonClicked)
        // Explicitly request left-click events — critical for macOS 27 compatibility
        button.sendAction(on: [.leftMouseUp])
        
        statusItem.menu = buildMenu()
        statusItem.isVisible = true  // Force visibility override (fixes macOS 26/27 bug)
        updateTitle()  // Show initial time in status bar
    }
    
    /// Build the right-click context menu for the status item.
    private func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "iBreak")
        
        let takeBreakItem = NSMenuItem(
            title: "Take a Break Now",
            action: #selector(takeBreakNow),
            keyEquivalent: ""
        )
        takeBreakItem.target = self
        menu.addItem(takeBreakItem)
        menu.addItem(.separator())
        
        let skipItem = NSMenuItem(
            title: "Skip This Break",
            action: #selector(skipBreak),
            keyEquivalent: ""
        )
        skipItem.target = self
        menu.addItem(skipItem)
        menu.addItem(.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit iBreak",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    // MARK: - Formatting Helpers
    
    /// Format time interval as MM:SS string.
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // MARK: - Actions
    
    @objc private func statusBarButtonClicked() {
        // Handle right-click/control-click via menu automatically
        if NSApp.currentEvent?.type == .rightMouseUp || NSEvent.modifierFlags.contains(.control) {
            return
        }
        
        // Left-click: trigger immediate break
        guard let delegate = delegate else { return }
        delegate.takeImmediateBreak()
    }
    
    @objc private func takeBreakNow() {
        guard let delegate = delegate else { return }
        delegate.takeImmediateBreak()
    }
    @objc private func skipBreak() {
        guard let delegate = delegate else { return }
        delegate.skipBreak()
    }
    @objc private func quitApp() { NSApp.terminate(nil) }
}
