//  BreakWindowController.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Window controller managing the on-top break reminder panel.
final class BreakWindowController: NSWindowController {
    
    // MARK: - Properties (Injected Dependencies)
    
    private weak var delegate: BreakDelegate?
    private let soundPlayer: SoundPlayer
    let viewModel = BreakViewModel()  // Public for testing access
    
    // MARK: - Initialization
    
    /// Initialize with injected dependencies for testability.
    /// - Parameters:
    ///   - delegate: Object conforming to BreakDelegate protocol (typically AppDelegate).
    ///   - soundPlayer: Sound playback service (defaults to SystemSoundPlayer.shared).
    init(delegate: BreakDelegate, soundPlayer: SoundPlayer = SystemSoundPlayer.shared) {
        self.delegate = delegate
        self.soundPlayer = soundPlayer
        super.init(window: nil)
        setupWindow()
        soundPlayer.playBreakStart()  // Entry sound cue via protocol
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        let panel = NSPanel(
            contentRect: NSMakeRect(0, 0, 420, 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel appearance and behavior
        panel.isOpaque = true
        panel.backgroundColor = NSColor.white
        panel.titleVisibility = .visible  // Keep title bar for window controls
        panel.isFloatingPanel = true      // Allow floating above other windows
        
        centerOnScreen(panel)
        attachDialogView(to: panel)
        configureWindowLevel(panel)
    }
    
    /// Center the panel on the main screen.
    private func centerOnScreen(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let windowSize = CGSize(width: 420, height: 350)
        
        panel.setFrame(
            NSRect(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2,
                width: windowSize.width,
                height: windowSize.height
            ),
            display: true
        )
    }
    
    /// Attach the BreakDialogView as content view with proper constraints.
    private func attachDialogView(to panel: NSPanel) {
        let breakDialogView = BreakDialogView(viewModel: viewModel) { [weak self] action in
            self?.handleAction(action)
        }
        
        panel.contentView = breakDialogView
        panel.title = "Eye Care Reminder"
        panel.isReleasedWhenClosed = false
    }
    
    /// Set window level above fullscreen apps.
    private func configureWindowLevel(_ panel: NSPanel) {
        panel.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1)
        self.window = panel
    }
    
    // MARK: - Public Methods
    
    override func showWindow(_ sender: Any?) {
        viewModel.isShowing = true
        viewModel.startCountdown()
        
        // Activate app so key window can receive focus (macOS 27 fix)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(sender)
        window?.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1)
    }
    
    func closeWindow() {
        viewModel.stopCountdown()
        viewModel.isShowing = false
        soundPlayer.playBreakEnd()  // Exit sound cue via protocol
        window?.close()
    }
    
    // MARK: - Private Helpers
    
    private func handleAction(_ action: BreakAction) {
        switch action {
        case .snooze:
            delegate?.breakWindowDismissed(action: .snooze)
        case .skip:
            delegate?.breakWindowDismissed(action: .skip)
        }
    }
}
