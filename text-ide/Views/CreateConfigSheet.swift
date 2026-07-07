import SwiftUI

struct CreateConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let folderURL: URL

    @State private var projectName: String
    @State private var selectedColorHex: String = ProjectService.defaultColorHex
    @State private var errorMessage: String?

    init(folderURL: URL) {
        self.folderURL = folderURL
        _projectName = State(initialValue: folderURL.lastPathComponent)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.sm) {
                ProjectIconView(
                    initials: previewInitials,
                    colorHex: selectedColorHex,
                    size: 56
                )

                Text("Configurar Projeto")
                    .font(.system(size: Typography.headingSize, weight: .semibold))

                Text("A pasta '\(folderURL.lastPathComponent)' não possui configuração.\nCrie um arquivo .textide.json para continuar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Nome do Projeto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Nome", text: $projectName)
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

                Button("Criar Configuração") {
                    createConfig()
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 380)
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

    private func createConfig() {
        guard !projectName.isEmpty else { return }

        let service = ProjectService(modelContext: modelContext)
        do {
            let project = try service.createConfigForExistingProject(
                name: projectName,
                folderURL: folderURL,
                iconColorHex: selectedColorHex
            )
            appState.selectedProject = project
            dismiss()
        } catch {
            errorMessage = "Erro ao criar configuração: \(error.localizedDescription)"
        }
    }
}
