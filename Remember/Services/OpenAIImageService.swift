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

        // Extract distinctive features to exaggerate for caricature effect
        let distinctiveFeatures = extractDistinctiveFeatures(from: transcript, keywords: keywords)

        let prompt = """
        \(style.promptDescription) \
        Create a MEMORABLE CARICATURE based on this description: \(transcript).\(keywordString)\(originContext) \
        \(distinctiveFeatures) \
        CARICATURE INSTRUCTIONS: Exaggerate the most distinctive physical features to make this person instantly recognizable. \
        If they have a big nose, make it bigger. If they have curly hair, make it curlier. \
        Focus on what makes them UNIQUE and MEMORABLE - this is for remembering faces, not passport photos.
        """

        print("[OpenAIImageService] Using style: \(style.displayName)")
        print("[OpenAIImageService] Origin context: \(originContext)")
        print("[OpenAIImageService] Distinctive features: \(distinctiveFeatures)")
        return prompt
    }

    private func extractDistinctiveFeatures(from transcript: String, keywords: [String]) -> String {
        let lowercased = transcript.lowercased()
        var features: [String] = []

        // Physical features to look for and exaggerate
        let featurePatterns: [(pattern: String, exaggeration: String)] = [
            ("big nose", "EXAGGERATE: Make the nose prominently large and distinctive"),
            ("small nose", "EXAGGERATE: Make the nose petite and delicate"),
            ("long nose", "EXAGGERATE: Elongate the nose dramatically"),
            ("curly hair", "EXAGGERATE: Make the curls bouncy and voluminous"),
            ("straight hair", "EXAGGERATE: Make the hair sleek and flowing"),
            ("bald", "EXAGGERATE: Emphasize the smooth, shiny scalp"),
            ("beard", "EXAGGERATE: Make the beard fuller and more prominent"),
            ("glasses", "EXAGGERATE: Make the glasses a defining feature"),
            ("big eyes", "EXAGGERATE: Make the eyes large and expressive"),
            ("small eyes", "EXAGGERATE: Make the eyes narrow and distinctive"),
            ("tall", "EXAGGERATE: Emphasize height and elongated proportions"),
            ("short", "EXAGGERATE: Emphasize compact, condensed proportions"),
            ("muscular", "EXAGGERATE: Emphasize strength and defined muscles"),
            ("thin", "EXAGGERATE: Emphasize slender, angular features"),
            ("round face", "EXAGGERATE: Make the face rounder and fuller"),
            ("angular face", "EXAGGERATE: Sharpen the jawline and cheekbones"),
            ("freckles", "EXAGGERATE: Scatter more prominent freckles"),
            ("dimples", "EXAGGERATE: Make the dimples deep and charming"),
            ("gap teeth", "EXAGGERATE: Make the tooth gap distinctive and memorable"),
            ("bushy eyebrows", "EXAGGERATE: Make the eyebrows thick and expressive"),
            ("wrinkles", "EXAGGERATE: Emphasize character lines and wisdom"),
            ("young", "EXAGGERATE: Emphasize youthful, fresh features"),
            ("old", "EXAGGERATE: Emphasize mature, distinguished features")
        ]

        for (pattern, exaggeration) in featurePatterns {
            if lowercased.contains(pattern) {
                features.append(exaggeration)
            }
        }

        // Also check keywords for features
        for keyword in keywords {
            let lowerKeyword = keyword.lowercased()
            for (pattern, exaggeration) in featurePatterns {
                if lowerKeyword.contains(pattern) && !features.contains(exaggeration) {
                    features.append(exaggeration)
                }
            }
        }

        if features.isEmpty {
            return "Find and exaggerate the most distinctive feature mentioned in the description."
        }

        return features.joined(separator: ". ")
    }

    private func extractOriginContext(from transcript: String) -> String {
        let lowercased = transcript.lowercased()

        // Map of countries/regions to subtle visual hints - keep it light
        let originHints: [String: String] = [
            "colombia": " From Colombia.",
            "guatemala": " From Guatemala.",
            "mexico": " From Mexico.",
            "brazil": " From Brazil.",
            "argentina": " From Argentina.",
            "peru": " From Peru.",
            "chile": " From Chile.",
            "spain": " From Spain.",
            "france": " From France.",
            "germany": " From Germany.",
            "italy": " From Italy.",
            "ireland": " From Ireland.",
            "china": " From China.",
            "japan": " From Japan.",
            "korea": " From Korea.",
            "india": " From India.",
            "vietnam": " From Vietnam.",
            "thailand": " From Thailand.",
            "philippines": " From the Philippines.",
            "nigeria": " From Nigeria.",
            "kenya": " From Kenya.",
            "ethiopia": " From Ethiopia.",
            "egypt": " From Egypt.",
            "morocco": " From Morocco.",
            "iran": " From Iran.",
            "turkey": " From Turkey.",
            "russia": " From Russia.",
            "poland": " From Poland.",
            "ukraine": " From Ukraine."
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
