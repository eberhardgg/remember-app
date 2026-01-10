import AppIntents

/// Registers Siri shortcuts for the app
struct RememberAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RememberPersonIntent(),
            phrases: [
                "Remember someone in \(.applicationName)",
                "Remember this person in \(.applicationName)",
                "Save someone in \(.applicationName)",
                "Add someone to \(.applicationName)",
                "Add a person to \(.applicationName)",
                "Remember a new person in \(.applicationName)"
            ],
            shortTitle: "Remember Someone",
            systemImageName: "person.badge.plus"
        )

        AppShortcut(
            intent: FindPersonIntent(),
            phrases: [
                "Find someone in \(.applicationName)",
                "Who is in \(.applicationName)",
                "Look up someone in \(.applicationName)",
                "Search \(.applicationName)",
                "Who did I meet in \(.applicationName)"
            ],
            shortTitle: "Find Someone",
            systemImageName: "magnifyingglass"
        )
    }
}
