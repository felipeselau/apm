import SwiftUI
import SwiftData

@main
struct text_ideApp: App {
    @State private var appState = AppState()

    private var colorScheme: ColorScheme? {
        switch appState.settings.theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

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

    init() {
        APMFileManager.shared.ensureAPMDirectory()
        registerBundledFont()
    }

    private func registerBundledFont() {
        guard let fontURL = Bundle.main.url(forResource: "JetBrainsMonoNerdFontMono-Regular", withExtension: "ttf"),
              let provider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(provider) else { return }
        CTFontManagerRegisterGraphicsFont(font, nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    appState.settings = APMFileManager.shared.loadSettings()
                    appState.loadAccount()
                    if !appState.hasAccount() {
                        appState.showingOnboarding = true
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Novo Projeto") {
                    appState.showNewProject()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Abrir Projeto") {
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

            CommandMenu("Editar") {
                Button("Salvar") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
