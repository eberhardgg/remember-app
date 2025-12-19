import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
