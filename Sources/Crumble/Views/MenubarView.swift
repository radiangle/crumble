import SwiftUI

struct MenubarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 12) {
            // App title
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(.blue)
                Text("Crumble")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: "settings")
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Recording state
            if appState.isProcessing {
                processingView
            } else if appState.isRecording {
                RecordingView()
                    .environmentObject(appState)
            } else {
                idleView
            }

            // Error display
            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Recent meetings
            if !appState.meetings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(appState.meetings.prefix(3)) { meeting in
                        Button {
                            openWindow(id: "meetings")
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(meeting.title)
                                        .font(.caption.weight(.medium))
                                        .lineLimit(1)
                                    Text(meeting.formattedDate)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if meeting.notes != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .imageScale(.small)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            HStack {
                Button("All Meetings") {
                    openWindow(id: "meetings")
                }
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    private var idleView: some View {
        Button {
            Task { await appState.startRecording() }
        } label: {
            Label("Start Recording", systemImage: "mic.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .controlSize(.large)
    }

    private var processingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Processing recording…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
