import SwiftUI

struct MeetingDetailView: View {
    let meeting: Meeting
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.title2.bold())
                HStack {
                    Text(meeting.formattedDate)
                    Text("·")
                    Text(meeting.formattedDuration)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Notes").tag(0)
                Text("Transcript").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedTab == 0 {
                notesContent
            } else {
                transcriptContent
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Copy Notes") { copyNotes() }
            }
        }
    }

    @ViewBuilder
    private var notesContent: some View {
        if let notes = meeting.notes {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    noteSection(title: "Summary", items: [notes.summary], icon: "doc.text")
                    if !notes.keyPoints.isEmpty {
                        noteSection(title: "Key Points", items: notes.keyPoints, icon: "list.bullet")
                    }
                    if !notes.actionItems.isEmpty {
                        noteSection(title: "Action Items", items: notes.actionItems, icon: "checkmark.circle")
                    }
                    if !notes.decisions.isEmpty {
                        noteSection(title: "Decisions", items: notes.decisions, icon: "arrow.triangle.branch")
                    }
                }
                .padding()
            }
        } else {
            ContentUnavailableView("No Notes", systemImage: "doc.text", description: Text("Notes were not generated for this meeting."))
        }
    }

    private var transcriptContent: some View {
        ScrollView {
            Text(meeting.transcript.isEmpty ? "No transcript available." : meeting.transcript)
                .font(.body)
                .foregroundStyle(meeting.transcript.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }

    @ViewBuilder
    private func noteSection(title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        if items.count > 1 {
                            Text("•")
                                .foregroundStyle(.secondary)
                        }
                        Text(item)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func copyNotes() {
        guard let notes = meeting.notes else { return }
        let text = """
        # \(meeting.title)
        \(meeting.formattedDate) · \(meeting.formattedDuration)

        ## Summary
        \(notes.summary)

        ## Key Points
        \(notes.keyPoints.map { "• \($0)" }.joined(separator: "\n"))

        ## Action Items
        \(notes.actionItems.map { "• \($0)" }.joined(separator: "\n"))

        ## Decisions
        \(notes.decisions.map { "• \($0)" }.joined(separator: "\n"))
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
