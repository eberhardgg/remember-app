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
                        onTap()
                    }
                }

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
        VStack(spacing: 24) {
            // Visual
            visualImage
                .frame(width: 150, height: 150)
                .clipShape(Circle())

            if isRevealed {
                // Name
                Text(person.name)
                    .font(.title)
                    .fontWeight(.semibold)

                // Context
                if let context = person.context {
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Transcript excerpt
                if let transcript = person.transcriptText {
                    Text(excerptFrom(transcript))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Placeholder for name
                Text("?")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
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
