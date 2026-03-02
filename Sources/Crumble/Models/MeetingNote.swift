import Foundation

struct MeetingNote: Codable, Hashable {
    var summary: String
    var actionItems: [String]
    var keyPoints: [String]
    var decisions: [String]

    init(
        summary: String = "",
        actionItems: [String] = [],
        keyPoints: [String] = [],
        decisions: [String] = []
    ) {
        self.summary = summary
        self.actionItems = actionItems
        self.keyPoints = keyPoints
        self.decisions = decisions
    }
}
