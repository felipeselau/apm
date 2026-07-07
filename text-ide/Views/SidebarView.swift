import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]
    @State private var projectToDelete: Project?
    @State private var showingDeleteConfirmation = false
    @State private var hoveredButton: String?

    var body: some View {
        let sortedProjects = projects.sorted { $0.effectiveSortOrder < $1.effectiveSortOrder }
        
        VStack(spacing: 0) {
            if let project = appState.selectedProject {
                HStack(spacing: Spacing.sm) {
                    ProjectIconView(initials: project.initials, colorHex: project.iconColorHex, size: 24, isSelected: false)
                    Text(project.name)
                        .font(.system(size: Typography.headingSize, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Menu {
                        Button("Editar Projeto", systemImage: "pencil") {
                            appState.showEditProject(project)
                        }
                        Button("Configuração do Terminal", systemImage: "terminal") {
                            appState.terminalConfigProject = project
                            appState.showingTerminalConfigSheet = true
                        }
                        Divider()
                        Button("Fechar Projeto", systemImage: "rectangle.portrait.and.arrow.right") {
                            appState.selectedProject = nil
                        }
                        Divider()
                        Button("Remover Projeto", systemImage: "trash", role: .destructive) {
                            projectToDelete = project
                            showingDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(nsColor: .controlBackgroundColor))
            }

            List(selection: Binding(
                get: { appState.selectedProject },
                set: { appState.selectedProject = $0 }
            )) {
                Section("Projetos") {
                    ForEach(sortedProjects) { project in
                        HStack(spacing: Spacing.sm) {
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
                        .listRowInsets(EdgeInsets(
                            top: Spacing.xs,
                            leading: Spacing.md,
                            bottom: Spacing.xs,
                            trailing: Spacing.md
                        ))
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
            }
            .listStyle(.sidebar)

            Divider()

            VStack(spacing: Spacing.xs) {
                Button(action: {
                    if appState.hasAccount() {
                        appState.showingAccountSheet = true
                    } else {
                        appState.showingOnboarding = true
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        if let account = appState.account {
                            AccountAvatar(name: account.name, size: 24)
                            Text(account.name)
                                .lineLimit(1)
                        } else {
                            Image(systemName: "person.circle")
                                .font(.system(size: 14))
                            Text("Configurar Conta")
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                    .background(hoveredButton == "account" ? Color.primary.opacity(0.06) : Color.clear)
                }
                .buttonStyle(.borderless)
                .onHover { hovering in
                    hoveredButton = hovering ? "account" : nil
                }

                Button(action: {
                    appState.showingSettingsSheet = true
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                        Text("Ajustes")
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                    .background(hoveredButton == "settings" ? Color.primary.opacity(0.06) : Color.clear)
                }
                .buttonStyle(.borderless)
                .onHover { hovering in
                    hoveredButton = hovering ? "settings" : nil
                }
            }
            .padding(.vertical, Spacing.sm)
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

struct AccountAvatar: View {
    let name: String
    var size: CGFloat = 24

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}
