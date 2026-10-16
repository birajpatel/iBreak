//  BreakDelegate.swift
//  iBreak - Eye Care Reminder App for macOS

import Foundation

/// Protocol defining the interface between break UI components and application logic.
@MainActor
protocol BreakDelegate: AnyObject {
    /// Called when a break should start immediately (e.g., user clicks status item).
    func takeImmediateBreak()
    
    /// Called when user skips an active break.
    func skipBreak()
    
    /// Called by BreakWindowController when user interacts with Skip/Snooze buttons, or internally for auto-dismiss.
    /// - Parameter action: The type of dismissal (.skip, .snooze, or nil for auto-dismiss).
    func breakWindowDismissed(action: BreakAction?)
}

extension BreakDelegate {
    /// Default implementation allowing optional parameter for convenience.
    func breakWindowDismissed() {
        breakWindowDismissed(action: nil)
    }
}
