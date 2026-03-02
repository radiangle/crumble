import Foundation

struct NoteGenerationService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"

    func generateNotes(transcript: String, apiKey: String) async throws -> MeetingNote {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = """
        You are a meeting notes assistant. Analyze the following meeting transcript and produce structured notes in JSON.

        Return ONLY a valid JSON object with this exact structure:
        {
          "summary": "2-3 sentence overview of the meeting",
          "actionItems": ["action item 1", "action item 2"],
          "keyPoints": ["key point 1", "key point 2"],
          "decisions": ["decision 1", "decision 2"]
        }

        Transcript:
        \(transcript)
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NoteGenerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw NoteGenerationError.apiError(httpResponse.statusCode, body)
        }

        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let text = anthropicResponse.content.first?.text else {
            throw NoteGenerationError.emptyResponse
        }

        // Extract JSON from the response text
        let jsonText = extractJSON(from: text)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw NoteGenerationError.parseError("Could not convert response to data")
        }

        return try JSONDecoder().decode(MeetingNote.self, from: jsonData)
    }

    private func extractJSON(from text: String) -> String {
        // Handle markdown code blocks
        if let start = text.range(of: "```json\n"),
           let end = text.range(of: "\n```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound])
        }
        if let start = text.range(of: "```\n"),
           let end = text.range(of: "\n```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound])
        }
        // Find raw JSON braces
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }
}

private struct AnthropicResponse: Codable {
    let content: [ContentBlock]

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
}

enum NoteGenerationError: LocalizedError {
    case invalidResponse
    case apiError(Int, String)
    case emptyResponse
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API."
        case .apiError(let code, let message):
            return "Claude API error \(code): \(message)"
        case .emptyResponse:
            return "Claude returned an empty response."
        case .parseError(let detail):
            return "Failed to parse Claude response: \(detail)"
        }
    }
}
