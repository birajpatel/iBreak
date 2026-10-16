//  SoundPlayer.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Protocol defining sound playback capabilities.
protocol SoundPlayer: AnyObject {
    /// Play a named system sound (e.g., "Glass", "Purr").
    func play(soundNamed name: String)
}

extension SoundPlayer {
    /// Convenience method to play break start sound.
    func playBreakStart() {
        play(soundNamed: "Glass") // Sharp, attention-getting
    }
    
    /// Convenience method to play break end sound.
    func playBreakEnd() {
        play(soundNamed: "Purr") // Soft, non-intrusive
    }
}

/// Concrete implementation using NSSound for system audio feedback.
final class SystemSoundPlayer: NSObject, SoundPlayer, @unchecked Sendable {
    static let shared = SystemSoundPlayer()
    
    func play(soundNamed name: String) {
        guard let sound = NSSound(named: name) else { return }
        sound.play()
    }
}
