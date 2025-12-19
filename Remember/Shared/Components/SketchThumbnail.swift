import SwiftUI

struct SketchThumbnail: View {
    let person: Person
    var size: CGFloat = 50

    var body: some View {
        Group {
            if let url = person.preferredVisualURL,
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.secondary.opacity(0.2))
            .overlay {
                Text(person.name.prefix(1).uppercased())
                    .font(size > 60 ? .title : .title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        SketchThumbnail(person: Person(name: "Sarah Chen"), size: 40)
        SketchThumbnail(person: Person(name: "Mike Johnson"), size: 60)
        SketchThumbnail(person: Person(name: "Emma Williams"), size: 80)
    }
}
