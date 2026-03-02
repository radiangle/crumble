import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var appState: AppState?
    var meetingsWindow: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let state = AppState()
        appState = state

        // Status bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.autosaveName = "Crumble"
        statusItem?.isVisible = true

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Crumble")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Popover with SwiftUI content
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenubarView(
                openSettings: { [weak self] in self?.openSettings() },
                openMeetings: { [weak self] in self?.openMeetings() }
            ).environmentObject(state)
        )
        self.popover = popover
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let button = statusItem?.button else { return }
        if let popover, popover.isShown {
            popover.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func openMeetings() {
        popover?.performClose(nil)
        if let w = meetingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
        } else {
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            w.title = "Meetings"
            w.center()
            w.contentViewController = NSHostingController(
                rootView: MeetingsListView().environmentObject(appState!)
            )
            w.makeKeyAndOrderFront(nil)
            meetingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettings() {
        popover?.performClose(nil)
        if let w = settingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
        } else {
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            w.title = "Settings"
            w.center()
            w.contentViewController = NSHostingController(rootView: SettingsView())
            w.makeKeyAndOrderFront(nil)
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
