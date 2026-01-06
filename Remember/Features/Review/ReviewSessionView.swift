import SwiftUI
import SwiftData

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReviewViewModel

    init(reviewService: ReviewServiceProtocol) {
        _viewModel = State(initialValue: ReviewViewModel(reviewService: reviewService))
    }

    init(reviewService: ReviewServiceProtocol, singlePerson: Person) {
        _viewModel = State(initialValue: ReviewViewModel(reviewService: reviewService, singlePerson: singlePerson))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isComplete {
                    ReviewCompleteView {
                        dismiss()
                    }
                } else if let person = viewModel.currentPerson {
                    FlashcardView(
                        person: person,
                        isRevealed: viewModel.isRevealed,
                        onTap: {
                            viewModel.reveal()
                        },
                        onGotIt: {
                            viewModel.markGotIt()
                        },
                        onMissed: {
                            viewModel.markMissed()
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "No Cards Due",
                        systemImage: "checkmark.circle",
                        description: Text("You're all caught up!")
                    )
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !viewModel.isComplete && viewModel.currentPerson != nil {
                    ToolbarItem(placement: .principal) {
                        Text("\(viewModel.currentIndex + 1) of \(viewModel.totalCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadQueue()
        }
    }
}

#Preview {
    ReviewSessionView(
        reviewService: ReviewService(
            modelContext: try! ModelContainer(for: Person.self).mainContext
        )
    )
}
