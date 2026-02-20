import SwiftUI

struct ControlButtonsView: View {
    @Bindable var instance: TimerInstance
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            switch instance.state {
            case .idle:
                startButton
            case .running:
                pauseButton
            case .paused:
                resumeButton
                resetButton
            case .finished:
                resetButton
            }

            Spacer()

            if let onRemove {
                Button {
                    onRemove()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    private var startButton: some View {
        Button {
            instance.start()
        } label: {
            Label("Start", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(instance.timerColor.color)
        .disabled(!instance.hasValidDuration)
    }

    private var pauseButton: some View {
        Button {
            instance.pause()
        } label: {
            Label("Pause", systemImage: "pause.fill")
        }
        .buttonStyle(.bordered)
    }

    private var resumeButton: some View {
        Button {
            instance.resume()
        } label: {
            Label("Resume", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(instance.timerColor.color)
    }

    private var resetButton: some View {
        Button {
            instance.reset()
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.bordered)
    }
}
