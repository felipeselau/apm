import SwiftUI

struct EditProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let project: Project

    @State private var projectName: String
    @State private var selectedColorHex: String
    @State private var errorMessage: String?

    init(project: Project) {
        self.project = project
        _projectName = State(initialValue: project.name)
        _selectedColorHex = State(initialValue: project.iconColorHex)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ProjectIconView(
                initials: previewInitials,
                colorHex: selectedColorHex,
                size: 56
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Nome do Projeto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Nome do Projeto", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Cor do Ícone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: Spacing.sm) {
                    ForEach(ProjectService.availableColors, id: \.self) { colorHex in
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 2 : 0)
                            )
                            .onTapGesture {
                                selectedColorHex = colorHex
                            }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Pasta do Projeto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "folder")
                    Text(project.folderPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(Spacing.sm)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Radii.sm))
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Salvar") {
                    saveProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 360)
    }

    private var previewInitials: String {
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "?" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private func saveProject() {
        guard !projectName.isEmpty else { return }

        let service = ProjectService(modelContext: modelContext)
        do {
            try service.updateProject(project, name: projectName, iconColorHex: selectedColorHex)
            dismiss()
        } catch {
            errorMessage = "Erro ao atualizar projeto: \(error.localizedDescription)"
        }
    }
}
