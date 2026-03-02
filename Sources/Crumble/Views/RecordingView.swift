import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var appState: AppState
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            // Animated waveform indicator
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 4, height: CGFloat.random(in: 8...32))
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(i) * 0.07),
                            value: pulse
                        )
                }
            }
            .frame(height: 40)

            Text("Recording")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(formattedDuration)
                .font(.system(.title2, design: .monospaced))
                .foregroundStyle(.red)

            Button("Stop Recording") {
                Task { await appState.stopRecording() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onAppear { pulse = true }
    }

    private var formattedDuration: String {
        let duration = appState.captureManager.recordingDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingView()
        .environmentObject(AppState())
}
