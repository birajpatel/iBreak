//  TimeProvider.swift
//  iBreak - Eye Care Reminder App for macOS

import Foundation

/// Protocol abstracting access to break timing state.
/// Allows StatusItemController to observe countdown without direct AppDelegate dependency.
@MainActor
protocol TimeProvider: AnyObject {
    /// Seconds remaining until next scheduled break.
    var timeToNextBreak: TimeInterval { get }
    
    /// Whether a break dialog is currently active.
    var isBreakActive: Bool { get }
}
