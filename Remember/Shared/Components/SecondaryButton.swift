import SwiftUI

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SecondaryButton(title: "Regenerate") {}
        SecondaryButton(title: "Add more details", icon: "mic.fill") {}
        SecondaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding(Spacing.lg)
}
