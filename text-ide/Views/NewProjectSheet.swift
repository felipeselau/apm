import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var projectName: String = ""
    @State private var selectedColorHex: String = ProjectService.availableColors.first ?? "#4A90D9"
    @State private var folderURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Novo Projeto")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Nome do Projeto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Meu Projeto", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Cor do Ícone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
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

            VStack(alignment: .leading, spacing: 8) {
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
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
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
        .padding(24)
        .frame(width: 360)
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
