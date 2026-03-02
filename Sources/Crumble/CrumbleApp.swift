import SwiftUI

@main
struct CrumbleApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menubar icon + popover
        MenuBarExtra("Crumble", systemImage: "waveform.circle") {
            MenubarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        // Meetings list window
        Window("Meetings", id: "meetings") {
            MeetingsListView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 800, height: 600)

        // Settings window
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)

        // Settings via Cmd+, (standard macOS convention)
        Settings {
            SettingsView()
        }
    }
}
