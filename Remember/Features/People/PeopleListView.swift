import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    @Query(sort: \PersonCategory.sortOrder) private var categories: [PersonCategory]

    @State private var showingAddPerson = false
    @State private var showingQuickAdd = false
    @State private var selectedPerson: Person?
    @State private var searchText = ""
    @State private var selectedCategoryFilter: PersonCategory?

    // Only show category filter when there are categories with people assigned
    private var categoriesWithPeople: [PersonCategory] {
        categories.filter { category in
            people.contains { $0.category?.id == category.id }
        }
    }

    private var shouldShowCategoryFilter: Bool {
        !categoriesWithPeople.isEmpty
    }

    var filteredPeople: [Person] {
        var result = people

        // Category filter
        if let category = selectedCategoryFilter {
            result = result.filter { $0.category?.id == category.id }
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText) ||
                (person.context?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (person.transcriptText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                person.descriptorKeywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if people.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        if shouldShowCategoryFilter {
                            categoryFilterBar
                        }
                        peopleList
                    }
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search names...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddPerson = true
                        } label: {
                            Label("Add with Voice", systemImage: "mic.fill")
                        }

                        Button {
                            showingQuickAdd = true
                        } label: {
                            Label("Quick Add", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonFlow(onComplete: {})
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView(onComplete: {})
            }
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person, onUpdate: {})
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "All",
                    isSelected: selectedCategoryFilter == nil,
                    action: { selectedCategoryFilter = nil }
                )

                ForEach(categoriesWithPeople) { category in
                    FilterChip(
                        label: category.name,
                        icon: category.systemImageName,
                        isSelected: selectedCategoryFilter?.id == category.id,
                        action: { selectedCategoryFilter = category }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var peopleList: some View {
        List {
            Section {
                ForEach(filteredPeople) { person in
                    PersonRowView(person: person)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPerson = person
                        }
                }
                .onDelete(perform: deletePeople)
            } header: {
                if selectedCategoryFilter != nil {
                    Text("\(filteredPeople.count) \(filteredPeople.count == 1 ? "person" : "people") in \(selectedCategoryFilter!.name)")
                        .textCase(nil)
                } else {
                    Text("\(people.count) \(people.count == 1 ? "person" : "people")")
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No People Yet", systemImage: "person.2")
        } description: {
            Text("Add someone you've met to start remembering names.")
        } actions: {
            Button {
                showingAddPerson = true
            } label: {
                Text("Add Someone")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets {
            let person = filteredPeople[index]
            modelContext.delete(person)
        }
        try? modelContext.save()
    }
}

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PeopleListView()
        .modelContainer(for: [Person.self, PersonCategory.self], inMemory: true)
}
