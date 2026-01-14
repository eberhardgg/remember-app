import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonCategory.sortOrder) private var categories: [PersonCategory]

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "person.2"
    @State private var editingCategory: PersonCategory?

    private let availableIcons = [
        "person.2", "person.2.fill", "briefcase.fill", "figure.2.and.child.holdinghands",
        "figure.child", "house.fill", "building.2.fill", "sportscourt.fill",
        "heart.fill", "star.fill", "graduationcap.fill", "cross.fill"
    ]

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: category.systemImageName)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(category.name)
                    Spacer()
                    Text("\(category.people.count)")
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !category.isDefault {
                        Button(role: .destructive) {
                            deleteCategory(category)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button {
                        editingCategory = category
                        newCategoryName = category.name
                        newCategoryIcon = category.systemImageName
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onMove(perform: moveCategories)

            Button {
                newCategoryName = ""
                newCategoryIcon = "person.2"
                showingAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddCategory) {
            categoryFormSheet(isEditing: false)
        }
        .sheet(item: $editingCategory) { _ in
            categoryFormSheet(isEditing: true)
        }
    }

    @ViewBuilder
    private func categoryFormSheet(isEditing: Bool) -> some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $newCategoryName)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                newCategoryIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(newCategoryIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddCategory = false
                        editingCategory = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isEditing, let category = editingCategory {
                            category.name = newCategoryName
                            category.systemImageName = newCategoryIcon
                        } else {
                            let category = PersonCategory(
                                name: newCategoryName,
                                systemImageName: newCategoryIcon,
                                sortOrder: categories.count,
                                isDefault: false
                            )
                            modelContext.insert(category)
                        }
                        showingAddCategory = false
                        editingCategory = nil
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var sortedCategories = categories
        sortedCategories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in sortedCategories.enumerated() {
            category.sortOrder = index
        }
    }

    private func deleteCategory(_ category: PersonCategory) {
        modelContext.delete(category)
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
    }
    .modelContainer(for: [Person.self, PersonCategory.self], inMemory: true)
}
