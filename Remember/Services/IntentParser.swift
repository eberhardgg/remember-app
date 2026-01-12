import Foundation

enum VoiceIntent {
    case remember(name: String, description: String?)
    case search(query: String)
    case unknown
}

/// Parses voice transcripts to determine user intent
struct IntentParser {

    /// Parse a transcript to determine if user wants to save or search
    static func parse(_ transcript: String) -> VoiceIntent {
        let lowercased = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Search patterns: "who is...", "who's...", "who has...", "who wears..."
        if let searchQuery = extractSearchQuery(from: lowercased) {
            return .search(query: searchQuery)
        }

        // Remember patterns: "remember [name]...", "[name], [description]"
        if let (name, description) = extractRememberIntent(from: transcript) {
            return .remember(name: name, description: description)
        }

        // If it's a short phrase with a name-like word, assume it's a search
        if lowercased.split(separator: " ").count <= 6 {
            return .search(query: transcript)
        }

        return .unknown
    }

    // MARK: - Search Extraction

    private static func extractSearchQuery(from text: String) -> String? {
        let searchPrefixes = [
            "who is the ",
            "who's the ",
            "who is ",
            "who's ",
            "who has ",
            "who wears ",
            "who works ",
            "who was ",
            "find the ",
            "find ",
            "search for ",
            "look up ",
            "which person ",
            "what's the name of the ",
            "what is the name of the "
        ]

        for prefix in searchPrefixes {
            if text.hasPrefix(prefix) {
                var query = String(text.dropFirst(prefix.count))
                // Remove trailing question mark
                query = query.trimmingCharacters(in: CharacterSet(charactersIn: "?"))
                if !query.isEmpty {
                    return query
                }
            }
        }

        // Check for question pattern: "... ?"
        if text.hasSuffix("?") || text.contains("?") {
            // It's likely a question/search
            var query = text.replacingOccurrences(of: "?", with: "")
            // Remove common question words at the start
            let questionWords = ["who ", "what ", "which "]
            for word in questionWords {
                if query.hasPrefix(word) {
                    query = String(query.dropFirst(word.count))
                }
            }
            return query.trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    // MARK: - Remember Extraction

    private static func extractRememberIntent(from text: String) -> (name: String, description: String?)? {
        let lowercased = text.lowercased()

        // Pattern: "remember [name], [description]" or "remember [name] [description]"
        let rememberPrefixes = ["remember ", "save ", "add "]

        for prefix in rememberPrefixes {
            if lowercased.hasPrefix(prefix) {
                let remainder = String(text.dropFirst(prefix.count))
                return parseNameAndDescription(from: remainder)
            }
        }

        // Pattern: direct "[Name], [description]" - assume first capitalized word is name
        // This handles: "Sarah, red glasses, marketing"
        if let (name, desc) = parseNameAndDescription(from: text) {
            return (name, desc)
        }

        return nil
    }

    private static func parseNameAndDescription(from text: String) -> (name: String, description: String?)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try splitting by comma first: "Sarah, red glasses"
        if let commaIndex = trimmed.firstIndex(of: ",") {
            let name = String(trimmed[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            let description = String(trimmed[trimmed.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)

            if isValidName(name) {
                return (capitalizeName(name), description.isEmpty ? nil : description)
            }
        }

        // Try extracting first word as name if it looks like a name
        let words = trimmed.split(separator: " ", maxSplits: 1)
        if let firstWord = words.first {
            let potentialName = String(firstWord)
            if isValidName(potentialName) {
                let description = words.count > 1 ? String(words[1]) : nil
                return (capitalizeName(potentialName), description)
            }
        }

        return nil
    }

    private static func isValidName(_ text: String) -> Bool {
        // A name should be:
        // - 2-20 characters
        // - Mostly letters
        // - Start with a letter
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, trimmed.count <= 20 else { return false }
        guard let first = trimmed.first, first.isLetter else { return false }

        let letterCount = trimmed.filter { $0.isLetter }.count
        return Double(letterCount) / Double(trimmed.count) > 0.8
    }

    private static func capitalizeName(_ name: String) -> String {
        name.prefix(1).uppercased() + name.dropFirst().lowercased()
    }

    // MARK: - Context Extraction

    /// Extract meeting context from transcript (e.g., "at the conference" -> "Conference")
    static func extractContext(from transcript: String) -> String? {
        let lowercased = transcript.lowercased()

        // Patterns: "at the [place]", "from [place]", "met at [place]", "met them at [place]"
        let patterns: [(prefix: String, suffix: String?)] = [
            ("met them at ", nil),
            ("met her at ", nil),
            ("met him at ", nil),
            ("met at ", nil),
            ("i met at ", nil),
            ("from the ", nil),
            ("from ", nil),
            ("at the ", nil),
            ("at a ", nil),
            ("at ", nil),
            ("works at ", nil),
            ("working at ", nil),
            ("my ", " neighbor"),  // "my neighbor" -> "Neighbor"
            ("our ", nil),
        ]

        for (prefix, requiredSuffix) in patterns {
            if let range = lowercased.range(of: prefix) {
                let afterPrefix = String(lowercased[range.upperBound...])

                // Handle special case like "my neighbor"
                if let suffix = requiredSuffix {
                    if afterPrefix.hasPrefix(suffix.trimmingCharacters(in: .whitespaces)) {
                        return suffix.trimmingCharacters(in: .whitespaces).capitalized
                    }
                    continue
                }

                // Extract until end of phrase (comma, period, or common stop words)
                let stopWords = [",", ".", " and ", " who ", " she ", " he ", " they ", " with "]
                var contextEnd = afterPrefix.endIndex

                for stop in stopWords {
                    if let stopRange = afterPrefix.range(of: stop) {
                        if stopRange.lowerBound < contextEnd {
                            contextEnd = stopRange.lowerBound
                        }
                    }
                }

                let extracted = String(afterPrefix[..<contextEnd])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Validate: should be 2-40 chars, mostly letters/spaces
                if extracted.count >= 2, extracted.count <= 40 {
                    // Capitalize each word
                    let formatted = extracted.split(separator: " ")
                        .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                        .joined(separator: " ")
                    return formatted
                }
            }
        }

        return nil
    }
}
