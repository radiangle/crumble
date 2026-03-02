import SwiftUI

struct SettingsView: View {
    @State private var openAIKey: String = ""
    @State private var kimiKey: String = ""
    @State private var saveStatus: String = ""

    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Used for Whisper transcription")

                SecureField("Kimi API Key", text: $kimiKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Used for Kimi note generation (api.moonshot.ai)")
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
        kimiKey = (try? KeychainService.load(key: "kimi")) ?? ""
    }

    private func saveKeys() {
        do {
            try KeychainService.save(key: "openai", value: openAIKey)
            try KeychainService.save(key: "kimi", value: kimiKey)
            saveStatus = "Keys saved successfully."
        } catch {
            saveStatus = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
}
