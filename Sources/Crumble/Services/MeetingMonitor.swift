import Foundation
import EventKit
import UserNotifications
import AppKit

@MainActor
class MeetingMonitor: NSObject, UNUserNotificationCenterDelegate {

    // Meeting apps to watch for (nonisolated so it can be used from NSWorkspace observer)
    nonisolated(unsafe) private static let meetingBundleIDs: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.microsoft.teams2",
        "com.cisco.webex.meetings",
        "Cisco-Systems.Spark",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "com.apple.FaceTime",
        "com.loom.desktop",
    ]

    private let eventStore = EKEventStore()
    private var calendarTimer: Timer?
    private var notifiedEventIDs = Set<String>()
    private var detectedAppBundleIDs = Set<String>()

    func start() {
        setupNotifications()
        Task { await requestCalendarAccess() }
        startCalendarTimer()
        startAppMonitoring()
    }

    // MARK: - Notifications setup

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let openAction = UNNotificationAction(
            identifier: "OPEN_CRUMBLE",
            title: "Open Crumble",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "MEETING_ALERT",
            actions: [openAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Calendar

    private func requestCalendarAccess() async {
        do {
            if #available(macOS 14.0, *) {
                try await eventStore.requestFullAccessToEvents()
            } else {
                try await eventStore.requestAccess(to: .event)
            }
        } catch {}
    }

    private func startCalendarTimer() {
        checkCalendar()
        calendarTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkCalendar() }
        }
    }

    private func checkCalendar() {
        // Look 5 min ahead, also catch events that just started (up to 2 min ago)
        let start = Date().addingTimeInterval(-2 * 60)
        let end = Date().addingTimeInterval(5 * 60)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { $0.status != .canceled && !$0.isAllDay }

        for event in events {
            guard !notifiedEventIDs.contains(event.eventIdentifier) else { continue }
            notifiedEventIDs.insert(event.eventIdentifier)

            let secUntil = event.startDate.timeIntervalSinceNow
            let body: String
            if secUntil <= 0 {
                body = "Your meeting just started — open Crumble to record"
            } else {
                let mins = max(1, Int(secUntil / 60))
                body = "Starts in \(mins) min\(mins == 1 ? "" : "s") — open Crumble to record"
            }

            sendNotification(
                title: event.title ?? "Upcoming meeting",
                body: body,
                id: event.eventIdentifier
            )
        }
    }

    // MARK: - App monitoring

    private func startAppMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        // Also check already-running meeting apps at launch
        for app in NSWorkspace.shared.runningApplications {
            if let id = app.bundleIdentifier, Self.meetingBundleIDs.contains(id) {
                detectedAppBundleIDs.insert(id)
            }
        }
    }

    @objc private nonisolated func handleAppLaunch(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleID = app.bundleIdentifier,
            Self.meetingBundleIDs.contains(bundleID)
        else { return }

        let name = app.localizedName ?? "Meeting app"

        Task { @MainActor [weak self] in
            guard let self, !self.detectedAppBundleIDs.contains(bundleID) else { return }
            self.detectedAppBundleIDs.insert(bundleID)

            self.sendNotification(
                title: "\(name) opened",
                body: "Open Crumble to record your meeting",
                id: "app-\(bundleID)-\(Date().timeIntervalSince1970)"
            )

            // Allow re-detection after 2 hours
            try? await Task.sleep(for: .seconds(7200))
            self.detectedAppBundleIDs.remove(bundleID)
        }
    }

    // MARK: - Send notification

    private func sendNotification(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MEETING_ALERT"

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            (NSApp.delegate as? AppDelegate)?.openMainWindow()
        }
        completionHandler()
    }
}
