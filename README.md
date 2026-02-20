# EKTimer

A lightweight menu bar timer and stopwatch app for macOS.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-green)

Download: https://github.com/user-attachments/files/25441202/EKTimer-1.0.0.dmg.zip

## Features

- **Menu bar app** — lives in the status bar, no dock icon
- **Multiple concurrent timers** — run as many stopwatches and countdown timers as you need
- **Custom colors** — 9 colors (white, blue, green, orange, red, purple, pink, teal, yellow) with auto-cycle option
- **Custom icons** — 20 icons to choose from (stopwatch, flame, heart, star, dumbbell, and more)
- **Editable labels** — auto-generated names (Timer 1, Stopwatch 2) that you can customize
- **Timer presets** — quick-start with 5, 10, 20, or 30 minute presets, plus custom time input
- **Colored menu bar** — each timer shows its icon and time in its assigned color directly in the menu bar
- **Right-click menu** — start, pause, restart, remove timers and change color/icon without opening the app
- **Notifications** — banner or alert style with 12 selectable sounds (Glass, Ping, Hero, and more)
- **Dark mode** — app icon adapts to light/dark appearance
- **Settings** — launch at login, auto-cycle colors, notification style/sound, editable presets
- **Keyboard shortcut** — Cmd+Q to quit

## Screenshots

Main panel showing multiple concurrent timers and stopwatches with colored menu bar icons:

![Main panel](Screeshots/image.png)

Settings view (general, notifications, sounds):

![Settings view](Screeshots/image-1.png)

Timer presets editor:

![Timer presets editor](Screeshots/image-2.png)

Menu bar:

![Menu bar](Screeshots/image-3.png)


## Installation

### Download

Download the latest `EKTimer-1.0.0.dmg` from [Releases](../../releases), open it, and drag **EKTimer** to **Applications**.

### Build from source

Requires macOS 14+ and Swift 6 (Xcode 16+).

```bash
git clone <repo-url>
cd ektimer

# Build and run
./Scripts/run.sh

# Build only (produces EKTimer.app)
./Scripts/build.sh

# Create DMG installer
./Scripts/create-dmg.sh
```

## Tech Stack

- **SwiftUI** with `MenuBarExtra` and `.menuBarExtraStyle(.window)`
- **Swift Observation** (`@Observable`) for reactive state
- **Combine** (`Timer.publish`) for tick updates
- **AppKit** for colored menu bar rendering (`NSImage` with `isTemplate = false`)
- **UNUserNotificationCenter** for timer completion alerts
- **SMAppService** for launch at login
- **Swift Package Manager** — no Xcode project needed

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6 / Xcode 16+ (for building from source)

## Author

Created by **Eniz K.**

## License

This project is open source and available under the [MIT License](LICENSE).
