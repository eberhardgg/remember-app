import SwiftUI

/// A view that displays text with specified keywords highlighted in bold
struct HighlightedText: View {
    let text: String
    let keywords: [String]
    var font: Font = .subheadline
    var color: Color = .secondary

    var body: some View {
        highlightedText
            .font(font)
            .foregroundStyle(color)
    }

    private var highlightedText: Text {
        Self.buildHighlightedText(text: text, keywords: keywords)
    }

    /// Builds a Text view with keywords highlighted in bold
    /// - Parameters:
    ///   - text: The full text to display
    ///   - keywords: Keywords to highlight with bold styling
    /// - Returns: A Text view with bold highlights applied
    static func buildHighlightedText(text: String, keywords: [String]) -> Text {
        guard !text.isEmpty else { return Text("") }
        guard !keywords.isEmpty else { return Text(text) }

        var result = Text("")
        let lowercasedText = text.lowercased()

        // Find all keyword ranges
        var highlights: [(range: Range<String.Index>, keyword: String)] = []
        for keyword in keywords {
            let lowercasedKeyword = keyword.lowercased()
            var searchStart = lowercasedText.startIndex
            while let range = lowercasedText.range(of: lowercasedKeyword, range: searchStart..<lowercasedText.endIndex) {
                highlights.append((range, keyword))
                searchStart = range.upperBound
            }
        }

        // Sort by start position
        highlights.sort { $0.range.lowerBound < $1.range.lowerBound }

        // Remove overlapping highlights (keep first)
        var filteredHighlights: [(range: Range<String.Index>, keyword: String)] = []
        for highlight in highlights {
            if let last = filteredHighlights.last {
                if highlight.range.lowerBound >= last.range.upperBound {
                    filteredHighlights.append(highlight)
                }
            } else {
                filteredHighlights.append(highlight)
            }
        }

        // Build attributed text
        var currentIndex = text.startIndex
        for highlight in filteredHighlights {
            // Add non-highlighted text before this keyword
            if currentIndex < highlight.range.lowerBound {
                let normalText = String(text[currentIndex..<highlight.range.lowerBound])
                result = result + Text(normalText)
            }
            // Add highlighted keyword (use original case from text)
            let originalKeyword = String(text[highlight.range])
            result = result + Text(originalKeyword).bold()
            currentIndex = highlight.range.upperBound
        }

        // Add remaining text
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex..<text.endIndex])
            result = result + Text(remainingText)
        }

        return result
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        HighlightedText(
            text: "Tall guy with curly brown hair and glasses, works at the coffee shop",
            keywords: ["tall", "curly", "brown hair", "glasses"]
        )
        .multilineTextAlignment(.center)
        .padding()

        HighlightedText(
            text: "She had bright red lipstick and a warm smile",
            keywords: ["red lipstick", "warm smile"],
            font: .body,
            color: .primary
        )
        .padding()
    }
}
