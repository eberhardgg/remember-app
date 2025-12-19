import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Regenerate", action: {})
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
