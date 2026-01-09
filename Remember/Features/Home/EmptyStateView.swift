import SwiftUI

struct EmptyStateView: View {
    let onAddPerson: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Illustration
            illustration
                .frame(width: 120, height: 120)

            // Title
            Text("Remember People")
                .font(.title2)
                .fontWeight(.semibold)

            // Description
            VStack(spacing: 8) {
                Text("Describe someone you just met")
                Text("and never forget their name again.")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()

            // How it works
            howItWorks
                .padding(.horizontal, 32)

            Spacer()

            // CTA
            Button {
                onAddPerson()
            } label: {
                Label("Add Someone", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))

            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Describe them")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Record a quick voice note about what they look like")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "paintbrush.fill")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get a memory sketch")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("We create an abstract sketch from your description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Look them up")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Search by name, description, or use voice search")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    EmptyStateView(onAddPerson: {})
}
