import SwiftUI

enum TimerColor: String, CaseIterable, Codable, Identifiable {
    case white
    case blue
    case green
    case orange
    case red
    case purple
    case pink
    case teal
    case yellow

    var id: String { rawValue }

    var next: TimerColor {
        let all = TimerColor.allCases
        let index = all.firstIndex(of: self)!
        return all[(index + 1) % all.count]
    }

    var color: Color {
        switch self {
        case .white: .white
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .red: .red
        case .purple: .purple
        case .pink: .pink
        case .teal: .teal
        case .yellow: .yellow
        }
    }
}
