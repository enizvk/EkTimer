import SwiftUI

struct TimeDisplayView: View {
    let timeString: String
    let color: Color

    var body: some View {
        Text(timeString)
            .font(.system(size: 28, weight: .light, design: .monospaced))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}

/// Editable time display with clickable up/down buttons on each digit group.
struct EditableTimeDisplayView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let color: Color
    var onChange: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            digitColumn(value: $hours, range: 0...23, label: "h")
            colonView
            digitColumn(value: $minutes, range: 0...59, label: "m")
            colonView
            digitColumn(value: $seconds, range: 0...59, label: "s")
        }
    }

    private var colonView: some View {
        Text(":")
            .font(.system(size: 24, weight: .light, design: .monospaced))
            .foregroundStyle(color.opacity(0.4))
            .padding(.bottom, 14)
    }

    private func digitColumn(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        VStack(spacing: 1) {
            // Up button
            Button {
                increment(value: value, range: range)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color.opacity(0.6))
                    .frame(width: 44, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Digit display
            Text(String(format: "%02d", value.wrappedValue))
                .font(.system(size: 26, weight: .light, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 44)

            // Down button
            Button {
                decrement(value: value, range: range)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color.opacity(0.6))
                    .frame(width: 44, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Label
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(color.opacity(0.4))
        }
    }

    private func increment(value: Binding<Int>, range: ClosedRange<Int>) {
        if value.wrappedValue >= range.upperBound {
            value.wrappedValue = range.lowerBound
        } else {
            value.wrappedValue += 1
        }
        onChange()
    }

    private func decrement(value: Binding<Int>, range: ClosedRange<Int>) {
        if value.wrappedValue <= range.lowerBound {
            value.wrappedValue = range.upperBound
        } else {
            value.wrappedValue -= 1
        }
        onChange()
    }
}
