import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var mainWindow: NSWindow?
    var settingsWindow: NSWindow?
    var appState: AppState?
    private var meetingMonitor: MeetingMonitor?
    private var iconTimer: Timer?
    private var iconPhase = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let state = AppState()
        appState = state

        // Start meeting monitor (calendar + app detection)
        let monitor = MeetingMonitor()
        monitor.start()
        meetingMonitor = monitor

        // Observe recording state for icon animation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordingStateChanged),
            name: .recordingStateChanged,
            object: nil
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.autosaveName = "Crumble"
        statusItem?.isVisible = true

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Crumble")
            button.image?.isTemplate = true
            button.action = #selector(toggleMainWindow)
            button.target = self
        }
    }

    @objc func toggleMainWindow() {
        if let w = mainWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        openMainWindow()
    }

    func openMainWindow() {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 660),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.center()
        w.contentViewController = NSHostingController(
            rootView: MainWindowView()
                .environmentObject(appState!)
                .ignoresSafeArea()
        )
        w.minSize = NSSize(width: 700, height: 500)
        w.makeKeyAndOrderFront(nil)
        mainWindow = w
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettings() {
        if let w = settingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
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
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Animated icon during recording

    @objc private func recordingStateChanged() {
        Task { @MainActor in
            guard let isRecording = self.appState?.isRecording else { return }
            if isRecording {
                self.startIconAnimation()
            } else {
                self.stopIconAnimation()
            }
        }
    }

    private func startIconAnimation() {
        iconTimer?.invalidate()
        iconTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.iconPhase = (self.iconPhase + 1) % 2
            let name = self.iconPhase == 0 ? "waveform.circle.fill" : "waveform.circle"
            DispatchQueue.main.async {
                let img = NSImage(systemSymbolName: name, accessibilityDescription: "Recording")
                img?.isTemplate = false
                // Green tint during recording
                if let img {
                    let tinted = img.tinted(with: .systemGreen)
                    self.statusItem?.button?.image = tinted
                }
            }
        }
    }

    private func stopIconAnimation() {
        iconTimer?.invalidate()
        iconTimer = nil
        iconPhase = 0
        let img = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Crumble")
        img?.isTemplate = true
        statusItem?.button?.image = img
    }
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

extension Notification.Name {
    static let recordingStateChanged = Notification.Name("CrumbleRecordingStateChanged")
}
