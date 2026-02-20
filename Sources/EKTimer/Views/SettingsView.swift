import SwiftUI

struct SettingsView: View {
    @Binding var isShowing: Bool
    @AppStorage("notificationStyle") private var notificationStyle: String = "banner"
    @AppStorage("notificationSound") private var notificationSound: String = "default"
    @AppStorage("autoCycleColors") private var autoCycleColors = true
    @State private var launchAtLogin = LaunchAtLoginService.isEnabled

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowing = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // General
                    settingsSection("General") {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, newValue in
                                LaunchAtLoginService.setEnabled(newValue)
                            }
                            .onAppear {
                                launchAtLogin = LaunchAtLoginService.isEnabled
                            }
                        Toggle("Auto-cycle colors for new items", isOn: $autoCycleColors)
                    }

                    // Notifications
                    settingsSection("Notifications") {
                        ForEach(NotificationStyle.allCases, id: \.rawValue) { style in
                            HStack {
                                Image(systemName: notificationStyle == style.rawValue ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(notificationStyle == style.rawValue ? Color.accentColor : Color.secondary)
                                Text(style.displayName)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                notificationStyle = style.rawValue
                            }
                        }
                        Divider()

                        Button {
                            NotificationService.sendTestNotification()
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Send Test Notification")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            NotificationService.openNotificationSettings()
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Notification Settings")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Text("If banners don't appear, enable notifications for EKTimer in System Settings → Notifications.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Sound
                    settingsSection("Notification Sound") {
                        ForEach(NotificationSound.allCases) { sound in
                            HStack {
                                Image(systemName: notificationSound == sound.rawValue ? "speaker.wave.2.fill" : "speaker")
                                    .foregroundStyle(notificationSound == sound.rawValue ? Color.accentColor : Color.secondary)
                                    .frame(width: 20)
                                Text(sound.displayName)
                                    .font(.subheadline)
                                Spacer()
                                if notificationSound == sound.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                notificationSound = sound.rawValue
                                if let s = NotificationSound(rawValue: sound.rawValue) {
                                    NotificationService.previewSound(s)
                                }
                            }
                        }
                    }

                    // Timer Presets
                    settingsSection("Timer Presets") {
                        PresetEditorView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 360)
        .frame(minHeight: 320, maxHeight: 600)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.5))
            )
        }
    }
}
