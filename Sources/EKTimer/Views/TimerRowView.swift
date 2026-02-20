import SwiftUI

struct TimerRowView: View {
    @Bindable var instance: TimerInstance
    var onRemove: () -> Void

    @State private var isExpanded = true
    @State private var editHours: Int = 0
    @State private var editMinutes: Int = 5
    @State private var editSeconds: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            // Header row: color dot + mode icon + label + collapse/remove
            HStack(spacing: 6) {
                Menu {
                    ForEach(TimerColor.allCases) { color in
                        Button {
                            instance.timerColor = color
                        } label: {
                            Label(color.rawValue.capitalized, systemImage: instance.timerColor == color ? "checkmark.circle.fill" : "circle.fill")
                        }
                        .tint(color.color)
                    }
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .tint(instance.timerColor.color)
                .fixedSize()
                .help("Change color")

                Menu {
                    ForEach(TimerIcon.allCases) { icon in
                        Button {
                            instance.icon = icon
                        } label: {
                            HStack {
                                Image(systemName: icon.symbolName)
                                    .frame(width: 20)
                                Text(icon.displayName)
                                if instance.icon == icon {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: instance.icon.symbolName)
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .tint(instance.timerColor.color)
                .fixedSize()
                .help("Change icon")

                if instance.state == .idle {
                    TextField("Label", text: $instance.name)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(instance.displayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

            }

            if isExpanded {
                // Timer-mode preset picker
                if instance.mode == .timer && instance.state == .idle {
                    presetPicker
                }

                // Time display — editable when timer is idle, read-only otherwise
                if instance.mode == .timer && instance.state == .idle {
                    EditableTimeDisplayView(
                        hours: $editHours,
                        minutes: $editMinutes,
                        seconds: $editSeconds,
                        color: instance.timerColor.color,
                        onChange: applyEditedDuration
                    )
                    .help("Click digits, then scroll or use arrow keys to adjust")
                } else {
                    TimeDisplayView(
                        timeString: instance.displayString,
                        color: instance.timerColor.color
                    )
                }

                // Finished label
                if instance.state == .finished {
                    Text("Time's up!")
                        .font(.caption)
                        .foregroundStyle(instance.timerColor.color)
                }

                // Controls
                ControlButtonsView(instance: instance, onRemove: onRemove)
            } else {
                // Collapsed: just show time inline
                HStack {
                    Text(instance.menuBarString)
                        .font(.system(.body, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(instance.timerColor.color)

                    Spacer()

                    if instance.state == .running {
                        Button { instance.pause() } label: {
                            Image(systemName: "pause.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    } else if instance.state == .paused {
                        Button { instance.resume() } label: {
                            Image(systemName: "play.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(instance.timerColor.color.opacity(0.05))
                .stroke(instance.timerColor.color.opacity(0.2), lineWidth: 1)
        )
    }

    private var presetPicker: some View {
        HStack(spacing: 6) {
            ForEach(loadPresets()) { preset in
                Button(preset.name) {
                    instance.selectedPreset = preset
                    instance.customDurationSeconds = 0
                    instance.remainingTimeInterval = preset.duration
                    syncEditFieldsFrom(preset.duration)
                }
                .buttonStyle(.bordered)
                .tint(instance.selectedPreset?.id == preset.id ? instance.timerColor.color : .secondary)
                .controlSize(.small)
            }
        }
    }

    private func applyEditedDuration() {
        let total = TimeInterval(editHours * 3600 + editMinutes * 60 + editSeconds)
        instance.selectedPreset = nil
        instance.customDurationSeconds = total
        instance.remainingTimeInterval = total
    }

    private func syncEditFieldsFrom(_ duration: TimeInterval) {
        let total = Int(duration)
        editHours = total / 3600
        editMinutes = (total % 3600) / 60
        editSeconds = total % 60
    }

    private func loadPresets() -> [TimerPreset] {
        if let data = UserDefaults.standard.data(forKey: "timerPresets"),
           let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) {
            return decoded
        }
        return TimerPreset.defaults
    }
}
