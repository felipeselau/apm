import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var showingQuickOpen = false

    var body: some View {
        @Bindable var appStateBindable = appState

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            if let project = appState.selectedProject {
                WorkspaceView(project: project)
                    .navigationTitle(project.name)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Nenhum projeto aberto")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.md) {
                        Button(action: { appState.showNewProject() }) {
                            Label("Novo Projeto", systemImage: "plus")
                                .frame(width: 140)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { appState.showOpenProject() }) {
                            Label("Abrir Projeto", systemImage: "folder")
                                .frame(width: 140)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = appState.toast {
                ToastView(toast: toast) {
                    appState.toast = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: appState.toast?.id)
        .background(
            Button("") {
                appState.selectedProject = nil
            }
            .keyboardShortcut("w", modifiers: .command)
            .opacity(0)
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appState.showNewProject() }) {
                    Label("Novo Projeto", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(action: { appState.showOpenProject() }) {
                    Label("Abrir Projeto", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)
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
        .sheet(isPresented: $appStateBindable.showingTerminalConfigSheet) {
            if let project = appState.terminalConfigProject {
                TerminalConfigSheet(project: project)
            }
        }
        .sheet(isPresented: $appStateBindable.showingPreviewSettingsSheet) {
            if let project = appState.selectedProject {
                PreviewSettingsSheet(project: project)
            }
        }
        .onChange(of: appState.showingOpenPanel) { _, newValue in
            if newValue {
                DispatchQueue.main.async {
                    openExistingProject()
                }
            }
        }
        .background(
            Button("") {
                showingQuickOpen = true
            }
            .keyboardShortcut("p", modifiers: [.command])
            .opacity(0)
        )
        .sheet(isPresented: $showingQuickOpen) {
            if let project = appState.selectedProject {
                QuickOpenView(project: project) { url in
                    let service = FileBrowserService(project: project, modelContext: modelContext)
                    if let content = try? service.readFile(at: url) {
                        NotificationCenter.default.post(name: .openFile, object: url, userInfo: ["content": content])
                    }
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
