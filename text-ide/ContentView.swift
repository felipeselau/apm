import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appStateBindable = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            if let project = appState.selectedProject {
                WorkspaceView(project: project)
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Selecione ou crie um projeto")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { appState.showNewProject() }) {
                    Label("Novo Projeto", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(action: { appState.showOpenProject() }) {
                    Label("Abrir Projeto", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)

                if appState.selectedProject != nil {
                    Button(action: {
                        if let project = appState.selectedProject {
                            appState.showEditProject(project)
                        }
                    }) {
                        Label("Editar Projeto", systemImage: "pencil")
                    }
                    .keyboardShortcut("e", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $appStateBindable.showingNewProjectSheet) {
            NewProjectSheet()
        }
        .sheet(isPresented: $appStateBindable.showingEditSheet) {
            if let project = appState.editingProject {
                EditProjectSheet(project: project)
            }
        }
        .sheet(isPresented: $appStateBindable.showingCreateConfigSheet) {
            if let folderURL = appState.folderNeedingConfig {
                CreateConfigSheet(folderURL: folderURL)
            }
        }
        .sheet(isPresented: $appStateBindable.showingOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $appStateBindable.showingAccountSheet) {
            AccountView()
        }
        .sheet(isPresented: $appStateBindable.showingSettingsSheet) {
            SettingsView()
        }
        .onChange(of: appState.showingOpenPanel) { _, newValue in
            if newValue {
                DispatchQueue.main.async {
                    openExistingProject()
                }
            }
        }
    }

    private func openExistingProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Selecione a pasta do projeto"

        if panel.runModal() == .OK, let url = panel.url {
            let service = ProjectService(modelContext: modelContext)
            do {
                let result = try service.openExistingProject(folderURL: url)
                switch result {
                case .success(let project):
                    appState.selectedProject = project
                case .needsConfigCreation(let folderURL):
                    appState.showCreateConfig(for: folderURL)
                }
            } catch {
                print("🔴 Erro ao abrir projeto: \(error)")
            }
        }
        appState.showingOpenPanel = false
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Project.self, inMemory: true)
        .environment(AppState())
}
