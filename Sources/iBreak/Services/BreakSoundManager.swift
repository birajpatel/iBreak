//  BreakSoundManager.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Simple system sound player using NSSound for audible break entry/exit cues.
final class BreakSoundManager: @unchecked Sendable {
    static let shared = BreakSoundManager()
    
    /// Play when the break dialog appears (attention-grabbing).
    func playBreakStart() {
        play(soundNamed: "Glass") // Sharp, attention-getting
    }
    
    /// Play when the break dialog auto-dismisses or is dismissed (gentle completion cue).
    func playBreakEnd() {
        play(soundNamed: "Purr") // Soft, non-intrusive
    }
    
    private func play(soundNamed name: String) {
        guard let sound = NSSound(named: name) else { return }
        sound.play()
    }
}
