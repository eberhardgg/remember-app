import SwiftUI

struct PersonRowView: View {
    let person: Person

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail - async loaded for better performance
            AsyncThumbnail(
                url: person.preferredVisualURL,
                placeholder: person.name,
                size: Sizing.Avatar.medium
            )

            // Info - simplified to name + context only
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(person.name)
                    .font(.headline)

                if let context = person.context, !context.isEmpty {
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    List {
        PersonRowView(person: Person(name: "Sarah Chen", context: "Tech Conference"))
        PersonRowView(person: Person(name: "Mike Johnson", context: "Neighbor"))
        PersonRowView(person: Person(name: "Emma Williams"))
    }
    .listStyle(.plain)
}
