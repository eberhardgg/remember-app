import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]

    @State private var showingAddPerson = false
    @State private var showingQuickAdd = false
    @State private var selectedPerson: Person?
    @State private var searchText = ""

    var filteredPeople: [Person] {
        if searchText.isEmpty {
            return people
        }
        return people.filter { person in
            person.name.localizedCaseInsensitiveContains(searchText) ||
            (person.context?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (person.transcriptText?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            person.descriptorKeywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if people.isEmpty {
                    emptyState
                } else {
                    peopleList
                }
            }
            .navigationTitle("People")
            .searchable(text: $searchText, prompt: "Search names...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingQuickAdd = true
                        } label: {
                            Label("Quick Add", systemImage: "plus")
                        }

                        Button {
                            showingAddPerson = true
                        } label: {
                            Label("Add with Voice", systemImage: "mic.fill")
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
                Text("\(people.count) \(people.count == 1 ? "person" : "people")")
                    .textCase(nil)
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

#Preview {
    PeopleListView()
        .modelContainer(for: Person.self, inMemory: true)
}
