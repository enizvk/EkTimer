import UserNotifications
import AppKit

enum NotificationService {
    static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            print("[Notifications] Current status: \(settings.authorizationStatus.rawValue) (0=notDetermined, 1=denied, 2=authorized, 3=provisional)")
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error { print("[Notifications] Auth error: \(error)") }
                    print("[Notifications] Permission granted: \(granted)")
                }
            } else if settings.authorizationStatus == .denied {
                print("[Notifications] Permission denied. User must enable in System Settings > Notifications > EKTimer")
            }
        }
    }

    static func sendTimerComplete(name: String) {
        // Always play sound locally
        playSelectedSound()

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "\(name) has finished."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Notifications] Failed: \(error)")
            } else {
                print("[Notifications] Scheduled for '\(name)'")
            }
        }
    }

    /// Sends a test notification to verify the system is working.
    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "EKTimer"
        content.body = "Notifications are working!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[Notifications] Test failed: \(error)")
                DispatchQueue.main.async {
                    openNotificationSettings()
                }
            } else {
                print("[Notifications] Test notification sent")
            }
        }
    }

    /// Opens System Settings > Notifications for this app.
    static func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Plays the user-selected notification sound locally.
    private static func playSelectedSound() {
        let sound = NotificationSound(
            rawValue: UserDefaults.standard.string(forKey: "notificationSound") ?? "default"
        ) ?? .default
        previewSound(sound)
    }

    /// Plays a sound for preview in settings.
    static func previewSound(_ sound: NotificationSound) {
        guard let fileName = sound.soundFileName else {
            NSSound(named: "Tink")?.play()
            return
        }
        NSSound(named: NSSound.Name(fileName))?.play()
    }
}
