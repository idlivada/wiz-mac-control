import SwiftUI

@main
struct WizControlApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Wiz Control", systemImage: "lightbulb.fill") {
            PopoverView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
