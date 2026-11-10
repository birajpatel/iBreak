//  BreakDialogView.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa
import Combine

/// Custom NSView rendering the break reminder dialog using pure AppKit.
@MainActor
final class BreakDialogView: NSView {
    
    // MARK: - Properties
    
    private let viewModel: BreakViewModel
    private let onAction: (BreakAction) -> Void
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements (Lazy Initialized)
    
    private lazy var iconImageView: NSImageView = {
        let iv = NSImageView()
        if #available(macOS 13.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 44, weight: .regular)
            iv.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Eye icon")?.withSymbolConfiguration(config)
        }
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.translatesAutoresizingMaskIntoConstraints = false
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
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        configureTextLabels()
        layoutUI()
        bindViewModel()
    }
    
    /// Configure attributed text for all labels.
    private func configureTextLabels() {
        titleLabel.attributedStringValue = NSAttributedString(
            string: viewModel.breakMessage,
            attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 28, weight: .bold)]
        )
        
        updateCountdownLabel(seconds: viewModel.countdown)
        
        instructionLabel.attributedStringValue = NSAttributedString(
            string: viewModel.instructionText,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 15)]
        )
    }
    
    /// Update countdown display text.
    private func updateCountdownLabel(seconds: Int) {
        countdownLabel.attributedStringValue = NSAttributedString(
            string: "Auto-dismissing in \(seconds)s",
            attributes: [.foregroundColor: NSColor.systemBlue, .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .medium)]
        )
    }
    
    /// Bind to ViewModel properties reactively.
    private func bindViewModel() {
        viewModel.$countdown
            .receive(on: RunLoop.main)
            .sink { [weak self] seconds in
                self?.updateCountdownLabel(seconds: seconds)
            }
            .store(in: &cancellables)
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
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            vStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            vStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            vStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            buttonStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 30),
            buttonStack.widthAnchor.constraint(equalToConstant: 280)
        ])
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
