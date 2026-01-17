import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Sizing.Button.standard)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Continue") {}
        PrimaryButton(title: "Add Someone", icon: "plus") {}
        PrimaryButton(title: "Loading...", isLoading: true) {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding(Spacing.lg)
}
