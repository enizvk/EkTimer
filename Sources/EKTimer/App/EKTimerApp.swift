import SwiftUI

@main
struct EKTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var manager = TimerManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(manager)
                .onAppear {
                    appDelegate.manager = manager
                }
        } label: {
            MenuBarLabel(manager: manager)
        }
        .menuBarExtraStyle(.window)
    }
}
