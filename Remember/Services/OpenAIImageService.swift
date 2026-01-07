import Foundation
import UIKit

enum OpenAIImageError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case imageDownloadFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No OpenAI API key configured. Add your key in Settings."
        case .invalidResponse:
            return "Invalid response from OpenAI API."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .imageDownloadFailed:
            return "Failed to download generated image."
        }
    }
}

protocol OpenAIImageServiceProtocol {
    var hasAPIKey: Bool { get }
    func generateSketch(from transcript: String, keywords: [String]) async throws -> UIImage
    func setAPIKey(_ key: String)
    func clearAPIKey()
}

final class OpenAIImageService: OpenAIImageServiceProtocol {
    private let apiKeyKey = "openai_api_key"
    private let baseURL = "https://api.openai.com/v1/images/generations"

    var hasAPIKey: Bool {
        guard let key = UserDefaults.standard.string(forKey: apiKeyKey) else { return false }
        return !key.isEmpty
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
    }

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: apiKeyKey)
    }

    func generateSketch(from transcript: String, keywords: [String]) async throws -> UIImage {
        print("[OpenAIImageService] generateSketch called")
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            print("[OpenAIImageService] No API key!")
            throw OpenAIImageError.noAPIKey
        }
        print("[OpenAIImageService] API key present (length: \(apiKey.count))")

        let prompt = buildPrompt(from: transcript, keywords: keywords)
        print("[OpenAIImageService] Calling DALL-E 3 API...")
        let imageURL = try await callDALLE3API(prompt: prompt, apiKey: apiKey)
        print("[OpenAIImageService] Got image URL, downloading...")
        let image = try await downloadImage(from: imageURL)
        print("[OpenAIImageService] Image downloaded successfully")

        return image
    }

    private func buildPrompt(from transcript: String, keywords: [String]) -> String {
        // Build a courtroom sketch style prompt from the description
        let keywordString = keywords.isEmpty ? "" : " Key features: \(keywords.joined(separator: ", "))."

        let prompt = """
        Courtroom sketch style portrait. Drawn with charcoal and soft pastels on cream-colored paper. \
        Expressive, loose strokes characteristic of a skilled courtroom artist. \
        Capture the likeness based on this description: \(transcript).\(keywordString) \
        Head and shoulders view, dramatic lighting from the side, artistic and impressionistic but recognizable. \
        The style should look like authentic courtroom art from a high-profile trial.
        """

        return prompt
    }

    private func callDALLE3API(prompt: String, apiKey: String) async throws -> URL {
        guard let url = URL(string: baseURL) else {
            throw OpenAIImageError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIImageError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorResponse["error"] as? [String: Any] {
                let message = error["message"] as? String ?? "Unknown error"
                let type = error["type"] as? String ?? ""
                let code = error["code"] as? String ?? ""
                print("[OpenAI] Error - Type: \(type), Code: \(code), Message: \(message)")
                throw OpenAIImageError.apiError("\(message) (\(type))")
            }
            throw OpenAIImageError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstResult = dataArray.first,
              let urlString = firstResult["url"] as? String,
              let imageURL = URL(string: urlString) else {
            throw OpenAIImageError.invalidResponse
        }

        return imageURL
    }

    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw OpenAIImageError.imageDownloadFailed
        }

        return image
    }
}
