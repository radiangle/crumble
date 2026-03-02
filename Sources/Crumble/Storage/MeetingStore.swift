import Foundation

@MainActor
class MeetingStore: ObservableObject {
    @Published private(set) var meetings: [Meeting] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let crumbleDir = appSupport.appendingPathComponent("Crumble", isDirectory: true)
        try? FileManager.default.createDirectory(at: crumbleDir, withIntermediateDirectories: true)
        fileURL = crumbleDir.appendingPathComponent("meetings.json")
        load()
    }

    func save(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = meeting
        } else {
            meetings.insert(meeting, at: 0)
        }
        persist()
    }

    func delete(_ meeting: Meeting) {
        meetings.removeAll { $0.id == meeting.id }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        meetings = (try? JSONDecoder().decode([Meeting].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(meetings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
