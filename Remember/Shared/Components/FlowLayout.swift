import SwiftUI

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            content()
                .fixedSize()
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > geometry.size.width {
                        width = 0
                        height -= dimension.height + spacing
                    }
                    let result = width
                    if dimension.width == 0 {
                        width = 0
                    } else {
                        width -= dimension.width + spacing
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if width == 0 {
                        height = 0
                    }
                    return result
                }
        }
    }
}

// Alternative simpler approach using ViewThatFits (iOS 16+)
struct KeywordTagsView: View {
    let keywords: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    KeywordTagsView(keywords: ["red hair", "glasses", "beard", "tall", "friendly smile"])
}
