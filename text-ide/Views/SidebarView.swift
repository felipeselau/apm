import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]
    @State private var projectToDelete: Project?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        let sortedProjects = projects.sorted { $0.effectiveSortOrder < $1.effectiveSortOrder }
        
        VStack(spacing: 0) {
            List(selection: Binding(
                get: { appState.selectedProject },
                set: { appState.selectedProject = $0 }
            )) {
                ForEach(sortedProjects) { project in
                    HStack(spacing: 10) {
                        ProjectIconView(
                            initials: project.initials,
                            colorHex: project.iconColorHex,
                            size: 28,
                            isSelected: false
                        )
                        Text(project.name)
                            .lineLimit(1)
                    }
                    .tag(project)
                    .contextMenu {
                        Button("Editar", systemImage: "pencil") {
                            appState.showEditProject(project)
                        }
                        Divider()
                        Button("Remover", systemImage: "trash", role: .destructive) {
                            projectToDelete = project
                            showingDeleteConfirmation = true
                        }
                    }
                }
                .onMove { source, destination in
                    moveProjects(from: source, to: destination)
                }
            }
            .listStyle(.sidebar)

            Divider()

            VStack(spacing: 4) {
                Button(action: {
                    if appState.hasAccount() {
                        appState.showingAccountSheet = true
                    } else {
                        appState.showingOnboarding = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 14))
                        if let account = appState.account {
                            Text(account.name)
                                .lineLimit(1)
                        } else {
                            Text("Configurar Conta")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.showingSettingsSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                        Text("Ajustes")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .alert("Remover Projeto", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {
                projectToDelete = nil
            }
            Button("Remover", role: .destructive) {
                if let project = projectToDelete {
                    removeProject(project)
                }
                projectToDelete = nil
            }
        } message: {
            if let project = projectToDelete {
                Text("Tem certeza que deseja remover o projeto '\(project.name)'? A pasta não será deletada.")
            }
        }
    }

    private func removeProject(_ project: Project) {
        let service = ProjectService(modelContext: modelContext)
        try? service.removeProject(project)
        if appState.selectedProject?.id == project.id {
            appState.selectedProject = nil
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        let sortedProjects = projects.sorted { $0.effectiveSortOrder < $1.effectiveSortOrder }
        var reordered = sortedProjects
        reordered.move(fromOffsets: source, toOffset: destination)
        let service = ProjectService(modelContext: modelContext)
        try? service.reorderProjects(reordered)
    }
}
