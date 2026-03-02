import SwiftUI

struct SettingsView: View {
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var saveStatus: String = ""

    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Used for Whisper transcription")

                SecureField("Anthropic API Key", text: $anthropicKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Used for Claude note generation")
            }

            if !saveStatus.isEmpty {
                Text(saveStatus)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Button("Save Keys") {
                saveKeys()
            }
            .buttonStyle(.borderedProminent)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 260)
        .onAppear { loadKeys() }
    }

    private func loadKeys() {
        openAIKey = (try? KeychainService.load(key: "openai")) ?? ""
        anthropicKey = (try? KeychainService.load(key: "anthropic")) ?? ""
    }

    private func saveKeys() {
        do {
            try KeychainService.save(key: "openai", value: openAIKey)
            try KeychainService.save(key: "anthropic", value: anthropicKey)
            saveStatus = "Keys saved successfully."
        } catch {
            saveStatus = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
}
