import SwiftUI

/// Shown immediately after saving a person to prompt rehearsal
struct RehearsalPromptView: View {
    let person: Person
    let onDismiss: () -> Void

    @State private var hasRehearsed = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Visual
            if let url = person.preferredVisualURL,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
            }

            // Instruction
            VStack(spacing: 12) {
                Text("Say it out loud")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Repeating a name within 30 seconds helps lock it in memory")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // The name to repeat
            VStack(spacing: 8) {
                Text(person.name)
                    .font(.system(size: 36, weight: .bold))

                if let meaning = person.nameMeaning {
                    Text(meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 16)

            Spacer()

            // Action button
            Button {
                HapticFeedback.success()
                hasRehearsed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            } label: {
                HStack {
                    if hasRehearsed {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(hasRehearsed ? "Great!" : "I've said it")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)

            Button("Skip") {
                onDismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
    }

}

#Preview {
    RehearsalPromptView(
        person: Person(name: "Carlos", context: "Tech Conference"),
        onDismiss: {}
    )
}
