import SwiftUI

struct ActiveRecordingView: View {
    @EnvironmentObject var appState: AppState
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var bars: [CGFloat] = [0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.8]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(appState.currentMeeting?.title ?? "Recording…")
                    .font(.title2.bold())
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(elapsed.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: elapsed)
                    Text(formattedElapsed)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)

            Divider()

            // Waveform visualizer
            Spacer()
            VStack(spacing: 24) {
                HStack(alignment: .center, spacing: 5) {
                    ForEach(0..<7, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.green)
                            .frame(width: 5, height: bars[i] * 60 + 8)
                            .animation(
                                .easeInOut(duration: Double.random(in: 0.3...0.6))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.08),
                                value: bars[i]
                            )
                    }
                }

                Text("Listening…")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Crumble is capturing your meeting audio.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                Button {
                    Task { await appState.stopRecording() }
                } label: {
                    Label("Stop Recording", systemImage: "stop.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            animateBars()
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                elapsed = appState.captureManager.recordingDuration
                randomizeBars()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var formattedElapsed: String {
        let m = Int(elapsed) / 60
        let s = Int(elapsed) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func animateBars() {
        randomizeBars()
    }

    private func randomizeBars() {
        bars = bars.map { _ in CGFloat.random(in: 0.2...1.0) }
    }
}
