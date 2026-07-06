import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Project.lastOpenedAt, order: .reverse) private var projects: [Project]
    @State private var projectToDelete: Project?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List(selection: Binding(
            get: { appState.selectedProject },
            set: { appState.selectedProject = $0 }
        )) {
            ForEach(projects) { project in
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
        }
        .listStyle(.sidebar)
        .onChange(of: appState.selectedProject) { _, newValue in
            if let project = newValue {
                try? ProjectService(modelContext: modelContext).updateLastOpened(project)
            }
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
}
