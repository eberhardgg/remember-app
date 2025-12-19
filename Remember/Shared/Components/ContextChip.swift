import SwiftUI

struct ContextChip: View {
    let text: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        if let action = action {
            Button(action: action) {
                chipContent
            }
            .buttonStyle(.plain)
        } else {
            chipContent
        }
    }

    private var chipContent: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        ContextChip(text: "Work")
        ContextChip(text: "Neighborhood", isSelected: true)
        ContextChip(text: "Event", action: {})
    }
}
