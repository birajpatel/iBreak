//  BreakSoundManager.swift
//  iBreak - Eye Care Reminder App for macOS

import Cocoa

/// Simple system sound player using NSSound for audible break entry/exit cues.
final class BreakSoundManager: SoundPlayer, @unchecked Sendable {
    static let shared = BreakSoundManager()
    
    func play(soundNamed name: String) {
        guard let sound = NSSound(named: name) else { return }
        sound.play()
    }
}
