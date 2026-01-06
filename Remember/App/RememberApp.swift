import SwiftUI
import SwiftData

@main
struct RememberApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Person.self)
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
}
