import AppKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var manager: TimerManager?
    private var localMonitor: Any?
    private var globalMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.requestAuthorization()
        setupMainMenu()
        setupRightClickMonitor()
    }

    // MARK: - Main menu (for Cmd+Q)

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit EKTimer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        NSApplication.shared.mainMenu = mainMenu
    }

    // MARK: - Right-click monitor

    private func setupRightClickMonitor() {
        // Local monitor — catches right-clicks when the app's panel is open
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp]) { [weak self] event in
            guard let self, self.isClickOnStatusItem(event: event) else { return event }
            MainActor.assumeIsolated { self.showContextMenuAtMouse() }
            return nil
        }

        // Global monitor — catches right-clicks when no app window is focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseUp]) { [weak self] event in
            guard let self, self.isClickOnStatusItem(event: event) else { return }
            DispatchQueue.main.async { self.showContextMenuAtMouse() }
        }
    }

    /// Check if the right-click happened on our status item by finding the status bar window.
    private func isClickOnStatusItem(event: NSEvent) -> Bool {
        let mouseLocation = NSEvent.mouseLocation

        // Check if click is in the menu bar area (top 24pt of any screen)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) else { return false }
        let menuBarMaxY = screen.frame.maxY
        let menuBarMinY = menuBarMaxY - 30
        guard mouseLocation.y >= menuBarMinY else { return false }

        // Check if click is near our status item by finding its window
        for window in NSApp.windows {
            let typeName = String(describing: type(of: window))
            if typeName.contains("StatusBar") || typeName.contains("StatusItem") {
                if window.frame.contains(mouseLocation) {
                    return true
                }
            }
        }

        // Fallback: check event's window type
        if let eventWindow = event.window {
            let name = String(describing: type(of: eventWindow))
            if name.contains("StatusBar") || name.contains("StatusItem") {
                return true
            }
        }

        return false
    }

    // MARK: - Dynamic context menu

    @MainActor private func showContextMenuAtMouse() {
        let menu = buildContextMenu()
        // Show at mouse location using a temporary view
        let mouseLocation = NSEvent.mouseLocation
        // Find the status bar button to anchor the menu
        for window in NSApp.windows {
            let typeName = String(describing: type(of: window))
            if typeName.contains("StatusBar") || typeName.contains("StatusItem") {
                if let contentView = window.contentView {
                    let localPoint = contentView.convert(
                        NSPoint(x: mouseLocation.x - window.frame.origin.x,
                                y: mouseLocation.y - window.frame.origin.y),
                        from: nil
                    )
                    menu.popUp(positioning: nil, at: localPoint, in: contentView)
                    return
                }
            }
        }
        // Fallback: pop up using a temporary invisible window at mouse location
        let tempWindow = NSWindow(
            contentRect: NSRect(x: mouseLocation.x - 1, y: mouseLocation.y - 1, width: 2, height: 2),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        tempWindow.isOpaque = false
        tempWindow.backgroundColor = .clear
        tempWindow.level = .statusBar
        tempWindow.orderFront(nil)
        if let view = tempWindow.contentView {
            menu.popUp(positioning: nil, at: .zero, in: view)
        }
        tempWindow.orderOut(nil)
    }

    @MainActor
    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()

        // Per-timer controls
        if let manager, !manager.instances.isEmpty {
            for timer in manager.instances {
                let timerMenu = NSMenu()

                // Start (for idle timers)
                if timer.state == .idle {
                    let startItem = NSMenuItem(title: "Start", action: #selector(startTimer(_:)), keyEquivalent: "")
                    startItem.target = self
                    startItem.representedObject = timer
                    timerMenu.addItem(startItem)
                }

                // Pause / Resume
                if timer.state == .running {
                    let pauseItem = NSMenuItem(title: "Pause", action: #selector(pauseTimer(_:)), keyEquivalent: "")
                    pauseItem.target = self
                    pauseItem.representedObject = timer
                    timerMenu.addItem(pauseItem)
                } else if timer.state == .paused {
                    let resumeItem = NSMenuItem(title: "Resume", action: #selector(resumeTimer(_:)), keyEquivalent: "")
                    resumeItem.target = self
                    resumeItem.representedObject = timer
                    timerMenu.addItem(resumeItem)
                }

                // Restart (for running, paused, finished)
                if timer.state != .idle {
                    let restartItem = NSMenuItem(title: "Restart", action: #selector(restartTimer(_:)), keyEquivalent: "")
                    restartItem.target = self
                    restartItem.representedObject = timer
                    timerMenu.addItem(restartItem)
                }

                timerMenu.addItem(.separator())

                // Color submenu
                let colorMenu = NSMenu()
                for timerColor in TimerColor.allCases {
                    let colorItem = NSMenuItem(title: timerColor.rawValue.capitalized, action: #selector(changeTimerColor(_:)), keyEquivalent: "")
                    colorItem.target = self
                    colorItem.representedObject = (timer, timerColor)
                    colorItem.image = colorDot(for: timerColor)
                    if timer.timerColor == timerColor {
                        colorItem.state = .on
                    }
                    colorMenu.addItem(colorItem)
                }
                let colorSubmenuItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
                colorSubmenuItem.submenu = colorMenu
                timerMenu.addItem(colorSubmenuItem)

                // Icon submenu
                let iconMenu = NSMenu()
                for timerIcon in TimerIcon.allCases {
                    let iconItem = NSMenuItem(title: timerIcon.displayName, action: #selector(changeTimerIcon(_:)), keyEquivalent: "")
                    iconItem.target = self
                    iconItem.image = NSImage(systemSymbolName: timerIcon.symbolName, accessibilityDescription: nil)
                    iconItem.representedObject = (timer, timerIcon)
                    if timer.icon == timerIcon {
                        iconItem.state = .on
                    }
                    iconMenu.addItem(iconItem)
                }
                let iconSubmenuItem = NSMenuItem(title: "Icon", action: nil, keyEquivalent: "")
                iconSubmenuItem.submenu = iconMenu
                timerMenu.addItem(iconSubmenuItem)

                timerMenu.addItem(.separator())

                // Remove
                let removeItem = NSMenuItem(title: "Remove", action: #selector(removeTimer(_:)), keyEquivalent: "")
                removeItem.target = self
                removeItem.representedObject = timer
                timerMenu.addItem(removeItem)

                // Timer entry with submenu
                let stateLabel: String
                switch timer.state {
                case .idle: stateLabel = "idle"
                case .running: stateLabel = timer.menuBarString
                case .paused: stateLabel = "\(timer.menuBarString) (paused)"
                case .finished: stateLabel = "finished"
                }
                let label = "\(timer.displayName) — \(stateLabel)"
                let timerItem = NSMenuItem(title: label, action: nil, keyEquivalent: "")
                timerItem.image = timerIconImage(for: timer)
                timerItem.submenu = timerMenu
                menu.addItem(timerItem)
            }

            menu.addItem(.separator())
        }

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    private func colorDot(for timerColor: TimerColor) -> NSImage {
        let size: CGFloat = 10
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        NSColor(timerColor.color).setFill()
        NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    @MainActor private func timerIconImage(for timer: TimerInstance) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        guard let symbol = NSImage(systemSymbolName: timer.icon.symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return NSImage()
        }
        let size = symbol.size
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor(timer.timerColor.color).set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        symbol.draw(in: NSRect(origin: .zero, size: size))
        // Tint: draw symbol, then overlay color using sourceAtop
        NSColor(timer.timerColor.color).set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    // MARK: - Actions

    @objc private func openApp() {
        // Click the status bar button to toggle the MenuBarExtra panel
        for window in NSApp.windows {
            let name = String(describing: type(of: window))
            if name.contains("StatusBar") {
                if let button = (window.value(forKey: "statusItem") as? NSStatusItem)?.button {
                    button.performClick(nil)
                    return
                }
            }
        }
    }

    @objc private func startTimer(_ sender: NSMenuItem) {
        guard let timer = sender.representedObject as? TimerInstance else { return }
        Task { @MainActor in timer.start() }
    }

    @objc private func pauseTimer(_ sender: NSMenuItem) {
        guard let timer = sender.representedObject as? TimerInstance else { return }
        Task { @MainActor in timer.pause() }
    }

    @objc private func resumeTimer(_ sender: NSMenuItem) {
        guard let timer = sender.representedObject as? TimerInstance else { return }
        Task { @MainActor in timer.resume() }
    }

    @objc private func restartTimer(_ sender: NSMenuItem) {
        guard let timer = sender.representedObject as? TimerInstance else { return }
        Task { @MainActor in
            timer.reset()
            timer.start()
        }
    }

    @objc private func changeTimerColor(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? (TimerInstance, TimerColor) else { return }
        Task { @MainActor in pair.0.timerColor = pair.1 }
    }

    @objc private func changeTimerIcon(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? (TimerInstance, TimerIcon) else { return }
        Task { @MainActor in pair.0.icon = pair.1 }
    }

    @objc private func removeTimer(_ sender: NSMenuItem) {
        guard let timer = sender.representedObject as? TimerInstance else { return }
        Task { @MainActor in self.manager?.remove(timer) }
    }

    // MARK: - Notifications

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
