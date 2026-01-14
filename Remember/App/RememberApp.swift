import SwiftUI
import SwiftData

@main
struct RememberApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Person.self, PersonCategory.self)
            seedDefaultCategoriesIfNeeded()
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }

    private func seedDefaultCategoriesIfNeeded() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PersonCategory>()

        do {
            let existingCategories = try context.fetch(descriptor)
            if existingCategories.isEmpty {
                for (index, defaults) in PersonCategory.defaults.enumerated() {
                    let category = PersonCategory(
                        name: defaults.name,
                        systemImageName: defaults.icon,
                        sortOrder: index,
                        isDefault: true
                    )
                    context.insert(category)
                }
                try context.save()
            }
        } catch {
            print("Failed to seed default categories: \(error)")
        }
    }
}
