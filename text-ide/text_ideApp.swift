import SwiftUI
import SwiftData

@main
struct text_ideApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Novo Projeto...") {
                    appState.showNewProject()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Abrir Projeto...") {
                    appState.showOpenProject()
                }
                .keyboardShortcut("o", modifiers: .command)

                if let project = appState.selectedProject {
                    Divider()
                    Button("Editar Projeto '\(project.name)'...") {
                        appState.showEditProject(project)
                    }
                    .keyboardShortcut("e", modifiers: .command)
                }
            }
        }
    }
}
