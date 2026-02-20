import SwiftUI
import AppKit

struct MenuBarLabel: View {
    let manager: TimerManager

    var body: some View {
        let active = manager.allActive
        if active.isEmpty {
            Image(systemName: "stopwatch")
        } else {
            Image(nsImage: renderTimers(Array(active.prefix(10))))
        }
    }

    /// Renders each active timer as [icon time] with its own color.
    private func renderTimers(_ timers: [TimerInstance]) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        let iconTextSpacing: CGFloat = 2
        let timerSpacing: CGFloat = 6

        // Pre-compute each segment
        var icons: [NSImage] = []
        var texts: [NSAttributedString] = []

        for timer in timers {
            let icon = NSImage(systemSymbolName: timer.icon.symbolName, accessibilityDescription: nil)?
                .withSymbolConfiguration(iconConfig) ?? NSImage()
            icons.append(icon)

            let color = NSColor(timer.timerColor.color)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: timer.state == .paused ? color.withAlphaComponent(0.5) : color
            ]
            texts.append(NSAttributedString(string: timer.menuBarString, attributes: attrs))
        }

        // Calculate total size
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        for i in timers.indices {
            let iconSize = icons[i].size
            let textSize = texts[i].size()
            let segmentWidth = iconSize.width + iconTextSpacing + textSize.width
            let segmentHeight = max(iconSize.height, textSize.height)
            totalWidth += segmentWidth
            totalHeight = max(totalHeight, segmentHeight)
            if i > 0 { totalWidth += timerSpacing }
        }

        let image = NSImage(size: NSSize(width: ceil(totalWidth), height: ceil(totalHeight)))
        image.lockFocus()

        var x: CGFloat = 0
        for i in timers.indices {
            let iconSize = icons[i].size
            let textSize = texts[i].size()
            let color = NSColor(timers[i].timerColor.color)
            let paused = timers[i].state == .paused

            // Draw tinted icon
            let tintedIcon = tintImage(icons[i], color: color, paused: paused)
            let iconY = (totalHeight - iconSize.height) / 2
            tintedIcon.draw(in: NSRect(x: x, y: iconY, width: iconSize.width, height: iconSize.height))

            // Draw text
            let textY = (totalHeight - textSize.height) / 2
            texts[i].draw(at: NSPoint(x: x + iconSize.width + iconTextSpacing, y: textY))

            x += iconSize.width + iconTextSpacing + textSize.width + timerSpacing
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func tintImage(_ source: NSImage, color: NSColor, paused: Bool) -> NSImage {
        let size = source.size
        let tinted = NSImage(size: size)
        tinted.lockFocus()
        source.draw(in: NSRect(origin: .zero, size: size))
        let tintColor = paused ? color.withAlphaComponent(0.5) : color
        tintColor.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        tinted.unlockFocus()
        tinted.isTemplate = false
        return tinted
    }
}
