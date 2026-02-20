import SwiftUI
import AppKit

struct AppIconView: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let image = loadIcon() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "stopwatch")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.tint)
                    .frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
    }

    private func loadIcon() -> NSImage? {
        let name = colorScheme == .dark ? "icon_dark" : "icon_light"
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
}
