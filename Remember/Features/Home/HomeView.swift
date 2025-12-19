import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showingAddPerson = false
    @State private var showingReview = false
    @State private var selectedPerson: Person?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    content(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Remember")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPerson = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search people")
            .onChange(of: searchText) { _, newValue in
                viewModel?.searchText = newValue
                viewModel?.loadPeople()
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonFlow(onComplete: {
                    viewModel?.loadPeople()
                })
            }
            .sheet(isPresented: $showingReview) {
                if let viewModel = viewModel {
                    ReviewSessionView(reviewService: viewModel.reviewService)
                }
            }
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person, onUpdate: {
                    viewModel?.loadPeople()
                })
            }
        }
        .onAppear {
            if viewModel == nil {
                let fileService = FileService()
                let personService = PersonService(modelContext: modelContext, fileService: fileService)
                let reviewService = ReviewService(modelContext: modelContext)
                viewModel = HomeViewModel(personService: personService, reviewService: reviewService)
                viewModel?.loadPeople()
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: HomeViewModel) -> some View {
        if viewModel.people.isEmpty && searchText.isEmpty {
            emptyState
        } else {
            List {
                if viewModel.dueCount > 0 {
                    reviewButton(dueCount: viewModel.dueCount)
                }

                ForEach(viewModel.people) { person in
                    PersonRowView(person: person)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPerson = person
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let person = viewModel.people[index]
                        viewModel.deletePerson(person)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        EmptyStateView {
            showingAddPerson = true
        }
    }

    private func reviewButton(dueCount: Int) -> some View {
        Button {
            showingReview = true
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.tint)
                Text("Review \(dueCount) \(dueCount == 1 ? "card" : "cards")")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.accentColor.opacity(0.1))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Person.self, inMemory: true)
}
