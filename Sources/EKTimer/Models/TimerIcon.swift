import SwiftUI

enum TimerIcon: String, CaseIterable, Codable, Identifiable {
    case stopwatch
    case timer
    case hourglass = "hourglass"
    case alarm = "alarm"
    case bell = "bell"
    case bolt = "bolt"
    case flame = "flame"
    case heart = "heart"
    case star = "star"
    case moon = "moon.fill"
    case sun = "sun.max"
    case cup = "cup.and.saucer"
    case dumbbell = "dumbbell"
    case figure = "figure.run"
    case book = "book"
    case music = "music.note"
    case gamecontroller = "gamecontroller"
    case briefcase = "briefcase"
    case graduationcap = "graduationcap"
    case leaf = "leaf"

    var id: String { rawValue }

    var symbolName: String { rawValue }

    var displayName: String {
        switch self {
        case .stopwatch: "Stopwatch"
        case .timer: "Timer"
        case .hourglass: "Hourglass"
        case .alarm: "Alarm"
        case .bell: "Bell"
        case .bolt: "Bolt"
        case .flame: "Flame"
        case .heart: "Heart"
        case .star: "Star"
        case .moon: "Moon"
        case .sun: "Sun"
        case .cup: "Coffee"
        case .dumbbell: "Workout"
        case .figure: "Running"
        case .book: "Reading"
        case .music: "Music"
        case .gamecontroller: "Gaming"
        case .briefcase: "Work"
        case .graduationcap: "Study"
        case .leaf: "Nature"
        }
    }

    static var defaultFor: (TimerMode) -> TimerIcon = { mode in
        mode == .stopwatch ? .stopwatch : .timer
    }
}
