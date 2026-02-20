import Foundation
import SwiftUI

@MainActor
@Observable
final class TimerManager {
    var instances: [TimerInstance] = []

    var firstRunning: TimerInstance? {
        instances.first { $0.state == .running }
    }

    var allActive: [TimerInstance] {
        instances.filter { $0.state == .running || $0.state == .paused }
    }

    var hasAnyRunning: Bool {
        instances.contains { $0.state == .running }
    }

    func addTimer(mode: TimerMode = .stopwatch, color: TimerColor = .blue) -> TimerInstance {
        let label = nextLabel(for: mode)
        let instance = TimerInstance(name: label, mode: mode, timerColor: color)
        instances.append(instance)
        return instance
    }

    private func nextLabel(for mode: TimerMode) -> String {
        let prefix = mode == .stopwatch ? "Stopwatch" : "Timer"
        let existingNumbers = instances
            .filter { $0.mode == mode }
            .compactMap { name -> Int? in
                let parts = name.name.split(separator: " ")
                guard parts.count == 2, parts[0] == Substring(prefix), let num = Int(parts[1]) else { return nil }
                return num
            }
        let next = (existingNumbers.max() ?? 0) + 1
        return "\(prefix) \(next)"
    }

    func remove(_ instance: TimerInstance) {
        instance.reset()
        instances.removeAll { $0.id == instance.id }
    }

    func removeAll() {
        for instance in instances {
            instance.reset()
        }
        instances.removeAll()
    }
}
