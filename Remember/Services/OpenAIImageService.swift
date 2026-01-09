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
        print("[OpenAIImageService] transcript length: \(transcript.count)")
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            print("[OpenAIImageService] No API key!")
            throw OpenAIImageError.noAPIKey
        }
        print("[OpenAIImageService] API key present (length: \(apiKey.count))")
        print("[OpenAIImageService] API key prefix: \(apiKey.prefix(10))...")

        let prompt = buildPrompt(from: transcript, keywords: keywords)
        print("[OpenAIImageService] Calling DALL-E 3 API...")
        let imageURL = try await callDALLE3API(prompt: prompt, apiKey: apiKey)
        print("[OpenAIImageService] Got image URL, downloading...")
        let image = try await downloadImage(from: imageURL)
        print("[OpenAIImageService] Image downloaded successfully")

        return image
    }

    private func buildPrompt(from transcript: String, keywords: [String]) -> String {
        let style = IllustrationStyle.current
        let keywordString = keywords.isEmpty ? "" : " Key features: \(keywords.joined(separator: ", "))."

        // Extract origin/nationality for visual context
        let originContext = extractOriginContext(from: transcript)

        let prompt = """
        \(style.promptDescription) \
        Capture the likeness based on this description: \(transcript).\(keywordString)\(originContext) \
        IMPORTANT: Pay close attention to any mentioned nationality, ethnicity, or country of origin - \
        reflect this authentically in the person's appearance and optionally include subtle cultural or geographic elements in the background.
        """

        print("[OpenAIImageService] Using style: \(style.displayName)")
        print("[OpenAIImageService] Origin context: \(originContext)")
        return prompt
    }

    private func extractOriginContext(from transcript: String) -> String {
        let lowercased = transcript.lowercased()

        // Map of countries/regions to visual context hints
        let originHints: [String: String] = [
            "colombia": " Colombian person, South American features.",
            "guatemala": " Guatemalan person, Central American/Mayan heritage.",
            "mexico": " Mexican person, Latin American features.",
            "brazil": " Brazilian person, diverse Brazilian appearance.",
            "argentina": " Argentine person, South American features.",
            "peru": " Peruvian person, Andean heritage.",
            "chile": " Chilean person, South American features.",
            "spain": " Spanish person, Mediterranean features.",
            "france": " French person, European features.",
            "germany": " German person, Northern European features.",
            "italy": " Italian person, Mediterranean features.",
            "ireland": " Irish person, Celtic features.",
            "china": " Chinese person, East Asian features.",
            "japan": " Japanese person, East Asian features.",
            "korea": " Korean person, East Asian features.",
            "india": " Indian person, South Asian features.",
            "vietnam": " Vietnamese person, Southeast Asian features.",
            "thailand": " Thai person, Southeast Asian features.",
            "philippines": " Filipino person, Southeast Asian features.",
            "nigeria": " Nigerian person, West African features.",
            "kenya": " Kenyan person, East African features.",
            "ethiopia": " Ethiopian person, East African features.",
            "egypt": " Egyptian person, North African/Middle Eastern features.",
            "morocco": " Moroccan person, North African features.",
            "iran": " Iranian/Persian person, Middle Eastern features.",
            "turkey": " Turkish person, Mediterranean/Middle Eastern features.",
            "russia": " Russian person, Eastern European features.",
            "poland": " Polish person, Eastern European features.",
            "ukraine": " Ukrainian person, Eastern European features."
        ]

        for (country, hint) in originHints {
            if lowercased.contains(country) {
                return hint
            }
        }

        return ""
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
