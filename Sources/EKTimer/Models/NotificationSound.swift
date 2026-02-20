import Foundation

enum NotificationSound: String, CaseIterable, Codable, Identifiable {
    case `default` = "default"
    case glass = "Glass"
    case ping = "Ping"
    case hero = "Hero"
    case blow = "Blow"
    case bottle = "Bottle"
    case funk = "Funk"
    case morse = "Morse"
    case purr = "Purr"
    case submarine = "Submarine"
    case pop = "Pop"
    case sosumi = "Sosumi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: "Default"
        case .glass: "Glass"
        case .ping: "Ping"
        case .hero: "Hero"
        case .blow: "Blow"
        case .bottle: "Bottle"
        case .funk: "Funk"
        case .morse: "Morse"
        case .purr: "Purr"
        case .submarine: "Submarine"
        case .pop: "Pop"
        case .sosumi: "Sosumi"
        }
    }

    /// File name used by macOS system sounds (without extension).
    var soundFileName: String? {
        self == .default ? nil : rawValue
    }
}
