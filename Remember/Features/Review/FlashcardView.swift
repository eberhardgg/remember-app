import SwiftUI

struct FlashcardView: View {
    let person: Person
    let isRevealed: Bool
    let onTap: () -> Void
    let onGotIt: () -> Void
    let onMissed: () -> Void

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack {
            Spacer()

            // Card
            cardContent
                .frame(maxWidth: 300)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .offset(x: offset)
                .opacity(opacity)
                .gesture(
                    isRevealed ? swipeGesture : nil
                )
                .onTapGesture {
                    if !isRevealed {
                        HapticFeedback.cardFlipped()
                        onTap()
                    }
                }
                .flashcardAccessibility(isRevealed: isRevealed, personName: person.name)

            Spacer()

            // Instructions
            if isRevealed {
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "arrow.left")
                        Text("Missed")
                            .font(.caption)
                    }
                    .foregroundStyle(.red)

                    VStack {
                        Image(systemName: "arrow.right")
                        Text("Got it")
                            .font(.caption)
                    }
                    .foregroundStyle(.green)
                }
                .padding()
            } else {
                Text("Tap to reveal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .animation(.spring(response: 0.3), value: offset)
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 20) {
            // Visual
            visualImage
                .frame(width: 120, height: 120)
                .clipShape(Circle())

            if isRevealed {
                // Name revealed
                Text(person.name)
                    .font(.title)
                    .fontWeight(.semibold)

                // Context
                if let context = person.context {
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Show description summary BEFORE reveal
                Text("Who is this?")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Bulleted summary of details
                descriptionSummary
            }
        }
        .padding(28)
    }

    @ViewBuilder
    private var descriptionSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Keywords as bullet points
            if !person.descriptorKeywords.isEmpty {
                ForEach(person.descriptorKeywords.prefix(5), id: \.self) { keyword in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(keyword.capitalized)
                            .font(.subheadline)
                    }
                }
            }

            // Context if available
            if let context = person.context, !context.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("Met at: \(context)")
                        .font(.subheadline)
                }
            }

            // Extract origin from transcript if mentioned
            if let origin = extractOrigin(from: person.transcriptText) {
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("From: \(origin)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private func extractOrigin(from transcript: String?) -> String? {
        guard let transcript = transcript?.lowercased() else { return nil }

        // Common patterns for mentioning origin
        let patterns = [
            "from ([a-zA-Z]+)",
            "originally from ([a-zA-Z]+)",
            "came from ([a-zA-Z]+)",
            "lives in ([a-zA-Z]+)",
            "born in ([a-zA-Z]+)"
        ]

        // List of countries/places to look for
        let places = [
            "colombia", "guatemala", "mexico", "brazil", "argentina", "peru", "chile",
            "spain", "france", "germany", "italy", "uk", "england", "ireland", "scotland",
            "china", "japan", "korea", "india", "vietnam", "thailand", "philippines",
            "nigeria", "kenya", "south africa", "egypt", "morocco",
            "canada", "australia", "new zealand",
            "california", "texas", "new york", "florida", "chicago"
        ]

        for place in places {
            if transcript.contains(place) {
                return place.capitalized
            }
        }

        return nil
    }

    @ViewBuilder
    private var visualImage: some View {
        if let url = person.preferredVisualURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 100

                if value.translation.width > threshold {
                    // Swipe right - Got it
                    HapticFeedback.cardSwiped()
                    AccessibilityAnnouncement.reviewCorrect()
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = 500
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onGotIt()
                        resetCard()
                    }
                } else if value.translation.width < -threshold {
                    // Swipe left - Missed
                    HapticFeedback.cardSwiped()
                    AccessibilityAnnouncement.reviewIncorrect()
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = -500
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onMissed()
                        resetCard()
                    }
                } else {
                    // Return to center
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
    }

    private func resetCard() {
        offset = 0
        opacity = 1
    }

    private func excerptFrom(_ text: String) -> String {
        let words = text.split(separator: " ")
        let excerpt = words.prefix(12).joined(separator: " ")
        return excerpt + (words.count > 12 ? "..." : "")
    }
}

#Preview {
    FlashcardView(
        person: Person(name: "Sarah Chen", context: "Tech Conference"),
        isRevealed: true,
        onTap: {},
        onGotIt: {},
        onMissed: {}
    )
}
