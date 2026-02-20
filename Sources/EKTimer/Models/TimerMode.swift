import Foundation

enum TimerMode: String, CaseIterable, Codable {
    case stopwatch
    case timer

    var displayName: String {
        switch self {
        case .stopwatch: "Stopwatch"
        case .timer: "Timer"
        }
    }
}
