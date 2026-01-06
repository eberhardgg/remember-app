import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPeople: [Person]

    private var duePeople: [Person] {
        let now = Date()
        return allPeople.filter { $0.nextDueAt <= now }
    }

    @State private var selectedTab = 0
    @State private var showingSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            PeopleListView()
                .tabItem {
                    Label("People", systemImage: "person.2")
                }
                .tag(0)

            ReviewTabView()
                .tabItem {
                    Label("Review", systemImage: "brain.head.profile")
                }
                .badge(duePeople.count > 0 ? duePeople.count : 0)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .onAppear {
            initializeServices()
        }
    }

    private func initializeServices() {
        let fileService = FileService()
        let transcriptService = TranscriptService()
        let personService = PersonService(modelContext: modelContext, fileService: fileService)
        let sketchService = SketchService(
            fileService: fileService,
            keywordParser: KeywordParser(),
            renderer: SketchRenderer()
        )

        WatchConnectivityService.shared.configure(
            modelContext: modelContext,
            transcriptService: transcriptService,
            personService: personService,
            fileService: fileService,
            sketchService: sketchService
        )
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Person.self, inMemory: true)
}
