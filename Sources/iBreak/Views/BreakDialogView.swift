//  BreakDialogView.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Custom NSView rendering the break reminder dialog using pure AppKit.
final class BreakDialogView: NSView {
    
    // MARK: - Properties
    
    private let viewModel: BreakViewModel
    private let onAction: (BreakAction) -> Void
    
    // MARK: - UI Elements (Lazy Initialized)
    
    private lazy var iconImageView: NSImageView = {
        let iv = NSImageView()
        if #available(macOS 13.0, *) {
            iv.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)
        } else {
            // Fallback for older systems - could use a bundled image
        }
        iv.imageScaling = .scaleAxesIndependently
        return iv
    }()
    
    private lazy var titleLabel: NSTextField = createStaticTextField()
    private lazy var countdownLabel: NSTextField = createStaticTextField()
    private lazy var instructionLabel: NSTextField = createStaticTextField()
    
    // MARK: - Initialization
    
    init(viewModel: BreakViewModel, onAction: @escaping (BreakAction) -> Void) {
        self.viewModel = viewModel
        self.onAction = onAction
        super.init(frame: NSRect(x: 0, y: 0, width: 420, height: 320))
        setupView()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override var isFlipped: Bool { true } // Modern auto-layout coordinate system
    
    // MARK: - Setup
    
    private func setupView() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        configureTextLabels()
        layoutUI()
        startCountdownUpdateTimer()
    }
    
    /// Configure attributed text for all labels.
    private func configureTextLabels() {
        titleLabel.attributedStringValue = NSAttributedString(
            string: viewModel.breakMessage,
            attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 28, weight: .bold)]
        )
        
        countdownLabel.attributedStringValue = NSAttributedString(
            string: "Auto-dismissing in \(viewModel.secondsRemaining)s",
            attributes: [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .medium)]
        )
        
        instructionLabel.attributedStringValue = NSAttributedString(
            string: viewModel.instructionText,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 15)]
        )
    }
    
    /// Layout all subviews using stack views and constraints.
    private func layoutUI() {
        let vStack = NSStackView(views: [iconImageView, titleLabel, countdownLabel, instructionLabel])
        vStack.alignment = .centerX
        vStack.distribution = .fillProportionally
        vStack.spacing = 20
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)
        
        let skipButton = NSButton(title: "Skip Break", target: self, action: #selector(skipClicked))
        skipButton.bezelStyle = .rounded
        
        let snoozeButton = NSButton(title: "Snooze (5 min)", target: self, action: #selector(snoozeClicked))
        snoozeButton.bezelStyle = .rounded
        
        let buttonStack = NSStackView(views: [snoozeButton, skipButton])
        buttonStack.alignment = .centerX
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 20
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
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
    }
    
    /// Update countdown label every second to reflect current time remaining.
    private func startCountdownUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdownLabel.attributedStringValue = NSAttributedString(
                string: "Auto-dismissing in \(self.viewModel.secondsRemaining)s",
                attributes: [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .medium)]
            )
        }
    }
    
    // MARK: - Actions
    
    @objc private func skipClicked() { onAction(.skip) }
    @objc private func snoozeClicked() { onAction(.snooze) }
    
    // MARK: - Helpers
    
    /// Create a static, non-editable text field suitable for labels.
    private func createStaticTextField() -> NSTextField {
        let tf = NSTextField(labelWithAttributedString: NSAttributedString())
        tf.isBezeled = false
        tf.isEditable = false
        tf.drawsBackground = false
        tf.isSelectable = false
        return tf
    }
}
