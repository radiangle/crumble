import Foundation
import ScreenCaptureKit
import AVFoundation

@MainActor
class SystemAudioCapture: NSObject, SCStreamOutput, SCStreamDelegate {
    private var stream: SCStream?
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    func startCapture() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = false
        config.sampleRate = 16000
        config.channelCount = 1

        // Capture all displays (for system audio)
        guard let display = content.displays.first else {
            throw SystemAudioError.noDisplayFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        try await stream?.startCapture()
    }

    func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
    }

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let buffer = sampleBuffer.asPCMBuffer() else { return }
        Task { @MainActor in
            self.onAudioBuffer?(buffer)
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        // Stream stopped — no action needed, recording will clean up
    }
}

enum SystemAudioError: LocalizedError {
    case noDisplayFound

    var errorDescription: String? {
        "No display found for system audio capture."
    }
}

extension CMSampleBuffer {
    func asPCMBuffer() -> AVAudioPCMBuffer? {
        guard let description = CMSampleBufferGetFormatDescription(self),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description)
        else { return nil }

        let format = AVAudioFormat(streamDescription: asbd)!
        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(self))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return nil }
        var lengthAtOffset = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)

        if let channelData = buffer.floatChannelData, let src = dataPointer {
            memcpy(channelData[0], src, totalLength)
        }

        return buffer
    }
}
