import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PeopleListView()
                .tabItem {
                    Label("People", systemImage: "person.2")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
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
