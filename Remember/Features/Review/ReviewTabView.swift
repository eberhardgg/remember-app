import SwiftUI
import SwiftData

struct ReviewTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPeople: [Person]

    private var duePeople: [Person] {
        let now = Date()
        return allPeople.filter { $0.nextDueAt <= now }
    }

    @State private var showingReviewSession = false
    @State private var reviewService: ReviewService?

    var body: some View {
        NavigationStack {
            Group {
                if duePeople.isEmpty {
                    allCaughtUp
                } else {
                    dueForReview
                }
            }
            .navigationTitle("Review")
            .onAppear {
                if reviewService == nil {
                    reviewService = ReviewService(modelContext: modelContext)
                }
            }
            .fullScreenCover(isPresented: $showingReviewSession) {
                if let reviewService = reviewService {
                    ReviewSessionView(reviewService: reviewService)
                }
            }
        }
    }

    private var dueForReview: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("\(duePeople.count) \(duePeople.count == 1 ? "person" : "people") to review")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Practice recalling their names to strengthen your memory.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Preview of who's due
            VStack(alignment: .leading, spacing: 12) {
                Text("Due for review")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ForEach(duePeople.prefix(3)) { person in
                    HStack(spacing: 12) {
                        thumbnail(for: person)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                        Text(person.name)
                            .font(.subheadline)

                        Spacer()

                        if person.daysUntilDue < 0 {
                            Text("\(abs(person.daysUntilDue))d overdue")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if duePeople.count > 3 {
                    Text("+ \(duePeople.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            Spacer()

            Button {
                showingReviewSession = true
            } label: {
                Label("Start Review", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var allCaughtUp: some View {
        ContentUnavailableView {
            Label("All Caught Up!", systemImage: "checkmark.circle")
        } description: {
            Text("No reviews due right now. Check back later!")
        }
    }

    @ViewBuilder
    private func thumbnail(for person: Person) -> some View {
        if let url = person.preferredVisualURL,
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .overlay {
                    Text(person.name.prefix(1).uppercased())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview {
    ReviewTabView()
        .modelContainer(for: Person.self, inMemory: true)
}
