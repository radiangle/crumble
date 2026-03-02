import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var currentMeeting: Meeting?

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
            currentMeeting = Meeting(title: formattedMeetingTitle())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false
        isProcessing = true
        errorMessage = nil

        guard let result = await captureManager.stopCapture() else {
            isProcessing = false
            return
        }

        do {
            let openAIKey = (try? KeychainService.load(key: "openai")) ?? ""
            let anthropicKey = (try? KeychainService.load(key: "anthropic")) ?? ""

            guard !openAIKey.isEmpty else {
                throw AppError.missingAPIKey("OpenAI API key not set. Please add it in Settings.")
            }
            guard !anthropicKey.isEmpty else {
                throw AppError.missingAPIKey("Anthropic API key not set. Please add it in Settings.")
            }

            let transcript = try await transcriptionService.transcribe(audioURL: result.url, apiKey: openAIKey)
            let notes = try await noteService.generateNotes(transcript: transcript, apiKey: anthropicKey)

            var meeting = currentMeeting ?? Meeting(title: formattedMeetingTitle())
            meeting.transcript = transcript
            meeting.notes = notes
            meeting.duration = result.duration

            meetingStore.save(meeting)
            currentMeeting = meeting
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
        try? FileManager.default.removeItem(at: result.url)
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
