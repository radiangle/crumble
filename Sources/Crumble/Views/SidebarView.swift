import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    private var grouped: [(String, [Meeting])] {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let groups = Dictionary(grouping: appState.meetings) { fmt.string(from: $0.date) }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        List(selection: $appState.selectedMeetingID) {
            ForEach(grouped, id: \.0) { label, meetings in
                Section(label) {
                    ForEach(meetings) { meeting in
                        SidebarRow(meeting: meeting)
                            .tag(meeting.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Crumble")
                        .font(.title3.bold())
                    Spacer()
                    Button {
                        openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Button {
                    Task { await appState.startRecording() }
                } label: {
                    Label("New Recording", systemImage: "record.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.regular)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

                Divider()
            }
            .background(.bar)
        }
        .overlay {
            if appState.meetings.isEmpty {
                ContentUnavailableView(
                    "No Recordings",
                    systemImage: "mic.slash",
                    description: Text("Hit New Recording to get started.")
                )
            }
        }
    }

    private func openSettings() {
        let delegate = NSApp.delegate as? AppDelegate
        delegate?.openSettings()
    }
}

struct SidebarRow: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(meeting.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(meeting.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if meeting.notes != nil {
                    Image(systemName: "sparkles")
                        .imageScale(.small)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
