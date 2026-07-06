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
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Configurar Projeto")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("A pasta '\(folderURL.lastPathComponent)' não possui configuração.\nCrie um arquivo .textide.json para continuar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Nome do Projeto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Nome", text: $projectName)
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
        .padding(24)
        .frame(width: 380)
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
