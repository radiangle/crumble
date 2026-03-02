import SwiftUI

struct MeetingsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMeeting: Meeting?

    var body: some View {
        NavigationSplitView {
            List(appState.meetings, id: \.id, selection: $selectedMeeting) { meeting in
                MeetingRowView(meeting: meeting)
                    .tag(meeting)
            }
            .listStyle(.sidebar)
            .navigationTitle("Meetings")
            .overlay {
                if appState.meetings.isEmpty {
                    ContentUnavailableView(
                        "No Meetings Yet",
                        systemImage: "mic.slash",
                        description: Text("Start a recording from the menubar to create your first meeting notes.")
                    )
                }
            }
        } detail: {
            if let meeting = selectedMeeting {
                MeetingDetailView(meeting: meeting)
            } else {
                ContentUnavailableView("Select a Meeting", systemImage: "doc.text", description: Text("Choose a meeting from the list to view notes."))
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

struct MeetingRowView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(meeting.title)
                .font(.body.weight(.medium))
                .lineLimit(1)
            HStack {
                Text(meeting.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if meeting.notes != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.small)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
