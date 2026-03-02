import SwiftUI

struct MeetingEditorView: View {
    let meeting: Meeting
    @EnvironmentObject var appState: AppState
    @State private var showTranscript = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(meeting.title)
                        .font(.title2.bold())
                    HStack(spacing: 12) {
                        Label(meeting.formattedDate, systemImage: "calendar")
                        if meeting.duration > 0 {
                            Label(meeting.formattedDuration, systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 32)

                // Notes or Enhance prompt
                if let notes = meeting.notes {
                    notesView(notes)
                } else if !meeting.transcript.isEmpty {
                    enhancePromptView
                } else {
                    emptyTranscriptView
                }

                // Transcript section
                if !meeting.transcript.isEmpty {
                    transcriptSection
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Notes view (gray AI text)

    private func notesView(_ notes: MeetingNote) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if !notes.summary.isEmpty {
                noteSection(icon: "text.alignleft", title: "Summary") {
                    Text(notes.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !notes.keyPoints.isEmpty {
                noteSection(icon: "list.bullet", title: "Key Points") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(notes.keyPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•").foregroundStyle(.tertiary)
                                Text(point).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            if !notes.actionItems.isEmpty {
                noteSection(icon: "checkmark.circle", title: "Action Items") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(notes.actionItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "square")
                                    .imageScale(.small)
                                    .foregroundStyle(.tertiary)
                                Text(item).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            if !notes.decisions.isEmpty {
                noteSection(icon: "arrow.triangle.branch", title: "Decisions") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(notes.decisions, id: \.self) { decision in
                            HStack(alignment: .top, spacing: 8) {
                                Text("→").foregroundStyle(.tertiary)
                                Text(decision).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private func noteSection<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            content()
        }
    }

    // MARK: - Enhance prompt (transcript ready, no notes yet)

    private var enhancePromptView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            VStack(spacing: 6) {
                Text("Transcript ready")
                    .font(.title3.bold())
                Text("Generate structured notes from your meeting.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if appState.isEnhancing {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.8)
                    Text("Generating notes…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Task { await appState.generateNotes(for: meeting) }
                } label: {
                    Label("Enhance Notes", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            }

            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    private var emptyTranscriptView: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 40)
            Text("No transcript available.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Transcript section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTranscript.toggle()
                }
            } label: {
                HStack {
                    Label("Transcript", systemImage: "text.quote")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showTranscript {
                Text(meeting.transcript)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .textSelection(.enabled)
            }
        }
    }
}
