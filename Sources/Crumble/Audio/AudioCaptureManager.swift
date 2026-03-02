import Foundation
import AVFoundation
import ScreenCaptureKit

@MainActor
class AudioCaptureManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let systemCapture = SystemAudioCapture()
    private var mixerBuffer: [AVAudioPCMBuffer] = []
    private var outputURL: URL?
    private var startTime: Date?
    private var durationTimer: Timer?
    private var audioFile: AVAudioFile?

    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

    func startCapture() async throws {
        guard !isRecording else { return }

        errorMessage = nil
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("crumble_\(UUID().uuidString).wav")
        outputURL = url
        audioFile = try AVAudioFile(forWriting: url, settings: targetFormat.settings)

        // Microphone capture via AVAudioEngine
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioCaptureError.converterFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * self.targetFormat.sampleRate / inputFormat.sampleRate)
            guard let converted = AVAudioPCMBuffer(pcmFormat: self.targetFormat, frameCapacity: frameCount) else { return }
            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if error == nil {
                Task { @MainActor in self.writeBuffer(converted) }
            }
        }

        // System audio capture via ScreenCaptureKit
        systemCapture.onAudioBuffer = { [weak self] buffer in
            Task { @MainActor in self?.writeBuffer(buffer) }
        }

        try audioEngine.start()
        try await systemCapture.startCapture()

        startTime = Date()
        isRecording = true
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startTime else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }

    func stopCapture() async -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let url = outputURL else { return nil }

        durationTimer?.invalidate()
        durationTimer = nil

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        await systemCapture.stopCapture()

        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        audioFile = nil
        isRecording = false
        recordingDuration = 0
        startTime = nil

        return (url, duration)
    }

    private func writeBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let file = audioFile else { return }
        try? file.write(from: buffer)
    }
}

enum AudioCaptureError: LocalizedError {
    case converterFailed

    var errorDescription: String? {
        "Failed to create audio format converter."
    }
}
