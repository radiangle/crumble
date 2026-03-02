import Foundation

struct Meeting: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var notes: MeetingNote?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        duration: TimeInterval = 0,
        transcript: String = "",
        notes: MeetingNote? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.transcript = transcript
        self.notes = notes
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
