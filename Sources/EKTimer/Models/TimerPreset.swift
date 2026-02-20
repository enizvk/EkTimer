import Foundation

struct TimerPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var duration: TimeInterval

    init(id: UUID = UUID(), name: String, duration: TimeInterval) {
        self.id = id
        self.name = name
        self.duration = duration
    }

    static let defaults: [TimerPreset] = [
        TimerPreset(name: "5 min", duration: 300),
        TimerPreset(name: "10 min", duration: 600),
        TimerPreset(name: "20 min", duration: 1200),
        TimerPreset(name: "30 min", duration: 1800),
    ]

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    }
}
