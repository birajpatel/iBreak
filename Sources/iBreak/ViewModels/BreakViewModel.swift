//  BreakViewModel.swift
//  iBreak - Eye Care Reminder App for macOS

import Foundation

/// ViewModel responsible for managing the break dialog's countdown state.
/// Handles all timer logic independently from UI components.
@MainActor
final class BreakViewModel: ObservableObject {
    
    // MARK: - Public Properties (Observable)
    
    /// Whether the break dialog is currently visible.
    @Published var isShowing = true
    
    /// The main message displayed to the user during a break.
    let breakMessage = "Time to take a break!"
    
    /// Instructional text guiding proper eye care technique.
    let instructionText = "Look away from your screen and focus on something at least 20 feet away."
    
    /// Countdown timer display (seconds remaining until auto-dismiss).
    @Published var countdown: Int = 20 {
        didSet { secondsRemaining = countdown }
    }
    
    /// Internal mirror of countdown for UI binding without triggering updates.
    private(set) var secondsRemaining: Int = 20
    
    // MARK: - Private Properties
    
    /// Timer driving the auto-dismiss countdown.
    private var countdownTimer: Timer?
    
    // MARK: - Public Methods
    
    /// Start (or restart) the countdown timer from 20 seconds.
    func startCountdown() {
        stopCountdown()
        countdown = 20
        
        countdownTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerTick),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func timerTick() {
        if countdown > 0 {
            countdown -= 1
        } else {
            stopCountdown()
        }
    }
    
    /// Stop the countdown timer immediately.
    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
