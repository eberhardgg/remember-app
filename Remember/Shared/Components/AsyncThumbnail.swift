import SwiftUI

/// Asynchronously loads and displays a thumbnail image from a file URL
struct AsyncThumbnail: View {
    let url: URL?
    let placeholder: String
    var size: CGFloat = Sizing.Avatar.medium

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: url) {
            await loadImage()
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(Color.rememberPlaceholder)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text(placeholder.prefix(1).uppercased())
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
    }

    private func loadImage() async {
        guard let url = url else { return }

        // Check if already loaded
        if image != nil { return }

        isLoading = true
        defer { isLoading = false }

        // Load on background thread
        let loadedImage = await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data) else {
                return nil as UIImage?
            }

            // Downscale for thumbnail performance
            let targetSize = CGSize(width: size * 2, height: size * 2) // 2x for retina
            return uiImage.preparingThumbnail(of: targetSize)
        }.value

        await MainActor.run {
            self.image = loadedImage
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AsyncThumbnail(url: nil, placeholder: "Sarah Chen")
        AsyncThumbnail(url: nil, placeholder: "Mike", size: Sizing.Avatar.large)
    }
    .padding()
}
