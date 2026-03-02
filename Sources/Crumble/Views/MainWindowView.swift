import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var selectedMeeting: Meeting? {
        appState.meetings.first { $0.id == appState.selectedMeetingID }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(appState)
        } detail: {
            if appState.isRecording {
                ActiveRecordingView()
                    .environmentObject(appState)
            } else if appState.isProcessing {
                TranscribingView()
            } else if let meeting = selectedMeeting {
                MeetingEditorView(meeting: meeting)
                    .environmentObject(appState)
                    .id(meeting.id)
            } else {
                EmptyEditorView()
                    .environmentObject(appState)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Empty state

struct EmptyEditorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No meeting selected")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Start a new recording or select a past meeting.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                Task { await appState.startRecording() }
            } label: {
                Label("New Recording", systemImage: "record.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Transcribing spinner

struct TranscribingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Transcribing audio…")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("This may take a moment.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
