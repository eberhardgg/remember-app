import SwiftUI

struct PersonRowView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail - larger for better face recognition
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            // Info - simplified to name + context only
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = person.preferredVisualURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // Placeholder
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .overlay {
                    Text(person.name.prefix(1).uppercased())
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
        }
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
