import SwiftUI

struct ContentView: View {
    @Environment(TimerManager.self) private var manager
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var newTimerColor: TimerColor = .white
    @AppStorage("autoCycleColors") private var autoCycleColors = true

    var body: some View {
        if showAbout {
            aboutView
        } else if showSettings {
            SettingsView(isShowing: $showSettings)
        } else {
            mainView
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("EK Timer")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showAbout = true
                    }
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // Timer list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(manager.instances) { instance in
                        TimerRowView(instance: instance) {
                            withAnimation {
                                manager.remove(instance)
                            }
                        }
                    }

                    if manager.instances.isEmpty {
                        Text("No timers yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }

            Divider()

            // Bottom bar: color picker + add buttons + quit
            HStack(spacing: 8) {
                // Color picker for new timer
                Menu {
                    ForEach(TimerColor.allCases) { color in
                        Button {
                            newTimerColor = color
                        } label: {
                            Label(color.rawValue.capitalized, systemImage: newTimerColor == color ? "checkmark.circle.fill" : "circle.fill")
                        }
                        .tint(color.color)
                    }
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .tint(newTimerColor.color)
                .fixedSize()
                .help("Color for new timers")

                Button {
                    withAnimation {
                        _ = manager.addTimer(mode: .stopwatch, color: newTimerColor)
                        if autoCycleColors { newTimerColor = newTimerColor.next }
                    }
                } label: {
                    Label("Add Stopwatch", systemImage: "stopwatch")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    withAnimation {
                        _ = manager.addTimer(mode: .timer, color: newTimerColor)
                        if autoCycleColors { newTimerColor = newTimerColor.next }
                    }
                } label: {
                    Label("Add Timer", systemImage: "timer")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 360)
        .frame(minHeight: 320, maxHeight: 600)
    }

    private var aboutView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showAbout = false
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
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            VStack(spacing: 16) {
                Spacer()

                AppIconView(size: 96)

                Text("EKTimer")
                    .font(.title.bold())

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("A lightweight menu bar timer and stopwatch app for macOS.\nMultiple concurrent timers with custom colors and icons.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 40)

                Text("Created by Eniz K.")
                    .font(.subheadline.weight(.medium))

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 360)
        .frame(minHeight: 320, maxHeight: 600)
    }
}
