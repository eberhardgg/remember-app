import Foundation

enum DescriptionServiceError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No OpenAI API key configured."
        case .invalidResponse:
            return "Invalid response from API."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

protocol DescriptionServiceProtocol {
    func editDescription(rawTranscript: String, keywords: [String], personName: String) async throws -> String
}

final class DescriptionService: DescriptionServiceProtocol {
    private let apiKeyKey = "openai_api_key"
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: apiKeyKey)
    }

    var hasAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    func editDescription(rawTranscript: String, keywords: [String], personName: String) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw DescriptionServiceError.noAPIKey
        }

        let keywordList = keywords.joined(separator: ", ")

        let prompt = """
        You are helping someone remember a person they met. They recorded a voice memo describing this person, \
        but it's informal and may be incoherent or rambling. Your job is to turn it into a clean, \
        concise 1-2 sentence description.

        Person's name: \(personName)
        Keywords to preserve: \(keywordList)
        Raw voice memo transcript: "\(rawTranscript)"

        Rules:
        1. Write in third person (e.g., "He is..." or "She works...")
        2. Keep it to 1-2 sentences maximum
        3. Include the key details naturally (age, profession, location, distinguishing features)
        4. Make it read smoothly and naturally
        5. Do NOT add any information not in the transcript
        6. Do NOT use markdown or formatting - just plain text

        Respond with ONLY the edited description, nothing else.
        """

        guard let url = URL(string: baseURL) else {
            throw DescriptionServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DescriptionServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorResponse["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw DescriptionServiceError.apiError(message)
            }
            throw DescriptionServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DescriptionServiceError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
