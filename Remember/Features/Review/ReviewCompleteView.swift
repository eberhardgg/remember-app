import SwiftUI

struct ReviewCompleteView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Nice work!")
                .font(.title)
                .fontWeight(.semibold)

            Text("You're done for now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    ReviewCompleteView(onDone: {})
}
