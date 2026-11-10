//  Notifications.swift
//  iBreak - Eye Care Reminder App for macOS

import AppKit
import Foundation

/// Extensions to Notification.Name providing custom notifications used throughout the app.
extension Notification.Name {
    /// Posted when the status bar display should be updated with new values.
    static let statusBarUpdate = Notification.Name("StatusBarUpdate")
    
    /// Posted whenever timeToNextBreak changes (every second during countdown).
    static let timeToNextBreakChanged = Notification.Name("TimeToNextBreakChanged")
    
    /// Posted when isBreakActive state toggles.
    static let breakStateChanged = Notification.Name("BreakStateChanged")
    
    /// System-level notification fired by macOS when display parameters change.
    static let didChangeScreenParameters = NSApplication.didChangeScreenParametersNotification
    
    /// Retained for backward compatibility.
    static let screenParametersChanged = NSApplication.didChangeScreenParametersNotification
}

/// Keys used in notification userInfo dictionaries for inter-component communication.
struct StatusBarUserInfoKey {
    static let timeToNextBreak = "timeToNextBreak"
    static let isBreakActive = "isBreakActive"
}
