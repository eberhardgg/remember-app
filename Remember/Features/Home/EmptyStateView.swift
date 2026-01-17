import SwiftUI

struct EmptyStateView: View {
    let onAddPerson: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Illustration
            illustration
                .frame(width: 120, height: 120)

            // Title
            Text("Remember People")
                .font(.title2)
                .fontWeight(.semibold)

            // Description
            VStack(spacing: Spacing.xs) {
                Text("Describe someone you just met")
                Text("and never forget their name again.")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()

            // How it works
            howItWorks
                .padding(.horizontal, Spacing.xl)

            Spacer()

            // CTA
            PrimaryButton(title: "Add Someone", icon: "plus") {
                onAddPerson()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))

            Image(systemName: "person.2.fill")
                .font(Typography.placeholderIconSmall)
                .foregroundStyle(Color.accentColor)
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How it works")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            howItWorksRow(
                icon: "mic.fill",
                title: "Describe them",
                description: "Record a quick voice note about what they look like"
            )

            howItWorksRow(
                icon: "paintbrush.fill",
                title: "Get a memory sketch",
                description: "We create an abstract sketch from your description"
            )

            howItWorksRow(
                icon: "magnifyingglass",
                title: "Look them up",
                description: "Search by name, description, or use voice search"
            )
        }
        .padding(Spacing.md)
        .background(Color.rememberSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Sizing.Radius.medium))
    }

    private func howItWorksRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: Spacing.lg)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    EmptyStateView(onAddPerson: {})
}
