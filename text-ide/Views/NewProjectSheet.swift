import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var projectName: String = ""
    @State private var selectedColorHex: String = ProjectService.availableColors.first ?? "#4A90D9"
    @State private var folderURL: URL?
    @State private var errorMessage: String?

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
                TextField("Meu Projeto", text: $projectName)
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
                Button(action: selectFolder) {
                    HStack {
                        Image(systemName: "folder")
                        Text(folderURL?.lastPathComponent ?? "Selecionar pasta...")
                            .foregroundStyle(folderURL == nil ? .secondary : .primary)
                        Spacer()
                    }
                    .padding(Spacing.sm)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Radii.sm))
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

                Button("Criar") {
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty || folderURL == nil)
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

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Selecione a pasta do projeto"
        
        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url
        }
    }

    private func createProject() {
        guard let folderURL = folderURL, !projectName.isEmpty else { return }

        let service = ProjectService(modelContext: modelContext)
        do {
            _ = try service.createProject(
                name: projectName,
                folderURL: folderURL,
                iconColorHex: selectedColorHex
            )
            dismiss()
        } catch {
            print("Erro ao criar projeto em \(folderURL.path): \(error)")
            errorMessage = "Erro ao criar projeto: \(error.localizedDescription)"
        }
    }
}
