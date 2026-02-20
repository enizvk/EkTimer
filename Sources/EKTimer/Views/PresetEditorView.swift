import SwiftUI

struct PresetEditorView: View {
    @State private var presets: [TimerPreset] = []
    @State private var newName: String = ""
    @State private var newMinutes: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(presets) { preset in
                HStack {
                    Text(preset.name)
                    Spacer()
                    Text(preset.formattedDuration)
                        .foregroundStyle(.secondary)
                    Button {
                        presets.removeAll { $0.id == preset.id }
                        savePresets()
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack {
                TextField("Name", text: $newName)
                    .frame(width: 80)
                Stepper("\(newMinutes) min", value: $newMinutes, in: 1...120)
                Button {
                    let preset = TimerPreset(
                        name: newName.isEmpty ? "\(newMinutes) min" : newName,
                        duration: TimeInterval(newMinutes * 60)
                    )
                    presets.append(preset)
                    savePresets()
                    newName = ""
                    newMinutes = 5
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.green)
            }
        }
        .onAppear { loadPresets() }
    }

    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "timerPresets"),
           let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data) {
            presets = decoded
        } else {
            presets = TimerPreset.defaults
        }
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "timerPresets")
        }
    }
}
