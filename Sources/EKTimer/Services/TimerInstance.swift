import Foundation
import Combine
import SwiftUI

@MainActor
@Observable
final class TimerInstance: Identifiable {
    let id: UUID
    var name: String
    var mode: TimerMode
    var state: TimerState = .idle
    var timerColor: TimerColor
    var icon: TimerIcon
    var selectedPreset: TimerPreset?
    var customDurationSeconds: TimeInterval = 0

    // Time tracking
    var elapsedTimeInterval: TimeInterval = 0
    var remainingTimeInterval: TimeInterval = 0

    private var cancellable: AnyCancellable?
    private var startDate: Date?
    private var accumulatedBeforePause: TimeInterval = 0

    init(
        id: UUID = UUID(),
        name: String = "",
        mode: TimerMode = .stopwatch,
        timerColor: TimerColor = .blue,
        icon: TimerIcon? = nil
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.timerColor = timerColor
        self.icon = icon ?? TimerIcon.defaultFor(mode)
        if mode == .timer {
            self.customDurationSeconds = 300 // 5 minutes default
            self.remainingTimeInterval = 300
        }
    }

    // MARK: - Controls

    func start() {
        if mode == .stopwatch {
            startStopwatch()
        } else {
            let duration = selectedPreset?.duration ?? customDurationSeconds
            guard duration > 0 else { return }
            startTimer(duration: duration)
        }
    }

    var hasValidDuration: Bool {
        if mode == .stopwatch { return true }
        return (selectedPreset?.duration ?? customDurationSeconds) > 0
    }

    func pause() {
        cancellable?.cancel()
        state = .paused
        if mode == .stopwatch {
            accumulatedBeforePause = elapsedTimeInterval
        } else {
            accumulatedBeforePause = remainingTimeInterval
        }
        startDate = nil
    }

    func resume() {
        state = .running
        startDate = Date()

        if mode == .stopwatch {
            cancellable = makeTickPublisher { [weak self] in
                guard let self, let startDate = self.startDate else { return }
                self.elapsedTimeInterval = self.accumulatedBeforePause + Date().timeIntervalSince(startDate)
            }
        } else {
            cancellable = makeTickPublisher { [weak self] in
                guard let self, let startDate = self.startDate else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                let remaining = self.accumulatedBeforePause - elapsed
                if remaining <= 0 {
                    self.remainingTimeInterval = 0
                    self.state = .finished
                    self.cancellable?.cancel()
                    NotificationService.sendTimerComplete(name: self.displayName)
                } else {
                    self.remainingTimeInterval = remaining
                }
            }
        }
    }

    func reset() {
        cancellable?.cancel()
        state = .idle
        elapsedTimeInterval = 0
        remainingTimeInterval = 0
        accumulatedBeforePause = 0
        startDate = nil
    }

    // MARK: - Display

    var displayName: String {
        name.isEmpty ? mode.displayName : name
    }

    var currentTimeInterval: TimeInterval {
        mode == .stopwatch ? elapsedTimeInterval : remainingTimeInterval
    }

    var displayString: String {
        formatTime(currentTimeInterval, includeCentiseconds: true)
    }

    var menuBarString: String {
        formatTime(currentTimeInterval, includeCentiseconds: false)
    }

    // MARK: - Private

    private func startStopwatch() {
        state = .running
        startDate = Date()
        accumulatedBeforePause = elapsedTimeInterval

        cancellable = makeTickPublisher { [weak self] in
            guard let self, let startDate = self.startDate else { return }
            self.elapsedTimeInterval = self.accumulatedBeforePause + Date().timeIntervalSince(startDate)
        }
    }

    private func startTimer(duration: TimeInterval) {
        state = .running
        remainingTimeInterval = duration
        startDate = Date()
        accumulatedBeforePause = duration

        cancellable = makeTickPublisher { [weak self] in
            guard let self, let startDate = self.startDate else { return }
            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = self.accumulatedBeforePause - elapsed
            if remaining <= 0 {
                self.remainingTimeInterval = 0
                self.state = .finished
                self.cancellable?.cancel()
                NotificationService.sendTimerComplete(name: self.displayName)
            } else {
                self.remainingTimeInterval = remaining
            }
        }
    }

    private func makeTickPublisher(onTick: @escaping () -> Void) -> AnyCancellable {
        Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in onTick() }
    }

    private func formatTime(_ interval: TimeInterval, includeCentiseconds: Bool) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if includeCentiseconds {
            let centiseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
            if hours > 0 {
                return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
            }
            return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
        } else {
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            }
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
