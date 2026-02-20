import Foundation

enum NotificationStyle: String, CaseIterable, Codable {
    case banner
    case alert

    var displayName: String {
        switch self {
        case .banner: "Banner (auto-dismiss)"
        case .alert: "Alert (stays visible)"
        }
    }
}
