//  LaunchAtLoginManager.swift
//  iBreak - Eye Care Reminder App for macOS

import Foundation
import ServiceManagement

/// Manages registration of the app as a login item via SMAppService (macOS 13+).
@MainActor
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    /// Current status of the login item service.
    var status: SMAppService.Status {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status
        }
        return .notFound
    }
    
    /// Toggle launch at login state. Returns the new enabled state.
    @discardableResult
    func toggle() -> Bool {
        if isEnabled {
            disable()
        } else {
            enable()
        }
        return isEnabled
    }
    
    /// Register the app as a login item.
    func enable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("✅ iBreak: Registered launch at login via SMAppService")
            } catch {
                print("⚠️ iBreak: Failed to register launch at login: \(error.localizedDescription)")
            }
        }
    }
    
    /// Unregister the app from login items.
    func disable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                print("✅ iBreak: Unregistered launch at login via SMAppService")
            } catch {
                print("⚠️ iBreak: Failed to unregister launch at login: \(error.localizedDescription)")
            }
        }
    }
}
