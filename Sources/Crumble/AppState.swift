import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var isEnhancing = false
    @Published var errorMessage: String?
    @Published var currentMeeting: Meeting?
    @Published var selectedMeetingID: UUID?

    let meetingStore = MeetingStore()
    let captureManager = AudioCaptureManager()
    private let transcriptionService = TranscriptionService()
    private let noteService = NoteGenerationService()

    var meetings: [Meeting] { meetingStore.meetings }

    func startRecording() async {
        guard !isRecording else { return }
        errorMessage = nil
        do {
            try await captureManager.startCapture()
            isRecording = true
            NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
            let meeting = Meeting(title: formattedMeetingTitle())
            currentMeeting = meeting
            selectedMeetingID = meeting.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Stop recording: transcribe only, don't auto-enhance
    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false
        NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
        isProcessing = true
        errorMessage = nil

        guard let result = await captureManager.stopCapture() else {
            isProcessing = false
            return
        }

        do {
            let openAIKey = (try? KeychainService.load(key: "openai")) ?? ""
            guard !openAIKey.isEmpty else {
                throw AppError.missingAPIKey("OpenAI API key not set. Please add it in Settings.")
            }

            let transcript = try await transcriptionService.transcribe(audioURL: result.url, apiKey: openAIKey)

            var meeting = currentMeeting ?? Meeting(title: formattedMeetingTitle())
            meeting.transcript = transcript
            meeting.duration = result.duration
            meetingStore.save(meeting)
            currentMeeting = meeting
            selectedMeetingID = meeting.id
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
        try? FileManager.default.removeItem(at: result.url)
    }

    // Enhance: generate notes from transcript (user-triggered)
    func generateNotes(for meeting: Meeting) async {
        guard !meeting.transcript.isEmpty else { return }
        isEnhancing = true
        errorMessage = nil

        do {
            let kimiKey = (try? KeychainService.load(key: "kimi")) ?? ""
            guard !kimiKey.isEmpty else {
                throw AppError.missingAPIKey("Kimi API key not set. Please add it in Settings.")
            }

            let notes = try await noteService.generateNotes(transcript: meeting.transcript, apiKey: kimiKey)
            var updated = meeting
            updated.notes = notes
            meetingStore.save(updated)
            if currentMeeting?.id == meeting.id {
                currentMeeting = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isEnhancing = false
    }

    private func formattedMeetingTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "Meeting — \(formatter.string(from: Date()))"
    }
}

enum AppError: LocalizedError {
    case missingAPIKey(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let msg): return msg
        }
    }
}
