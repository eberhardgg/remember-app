import SwiftUI

/// Shown immediately after saving a person to prompt rehearsal
struct RehearsalPromptView: View {
    let person: Person
    let onDismiss: () -> Void

    @State private var hasRehearsed = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Visual
            if let url = person.preferredVisualURL,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Sizing.Avatar.xlarge, height: Sizing.Avatar.xlarge)
                    .clipShape(RoundedRectangle(cornerRadius: Sizing.Radius.xlarge))
                    .shadow(radius: Shadow.large)
            }

            // Instruction
            VStack(spacing: Spacing.sm) {
                Text("Say it out loud")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Repeating a name within 30 seconds helps lock it in memory")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            // The name to repeat
            VStack(spacing: Spacing.xs) {
                Text(person.name)
                    .font(Typography.rehearsalName)

                if let meaning = person.nameMeaning {
                    Text(meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, Spacing.md)

            Spacer()

            // Action button
            PrimaryButton(
                title: hasRehearsed ? "Great!" : "I've said it",
                icon: hasRehearsed ? "checkmark.circle.fill" : nil
            ) {
                HapticFeedback.success()
                hasRehearsed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            }
            .padding(.horizontal, Spacing.lg)

            Button("Skip") {
                onDismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, Spacing.lg)
        }
    }

}

#Preview {
    RehearsalPromptView(
        person: Person(name: "Carlos", context: "Tech Conference"),
        onDismiss: {}
    )
}
