import SwiftUI
import SwiftData

struct PreviewSettingsSheet: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var url: String = ""
    @State private var viewport: String = "desktop"
    @State private var autoRefresh: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Configurações do Preview")
                    .font(.system(size: Typography.headingSize, weight: .medium))
                Spacer()
            }
            .padding(Spacing.lg)

            Divider()

            Form {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("URL")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                        TextField("http://localhost:5173", text: $url)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: Typography.bodySize))
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Viewport")
                            .font(.system(size: Typography.bodySize, weight: .medium))
                        Picker("Viewport", selection: $viewport) {
                            Text("Desktop").tag("desktop")
                            Text("Tablet").tag("tablet")
                            Text("Mobile").tag("mobile")
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle("Auto-refresh", isOn: $autoRefresh)
                        .font(.system(size: Typography.bodySize))
                }
                .padding(Spacing.lg)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Salvar") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(Spacing.lg)
        }
        .frame(width: 400, height: 350)
        .onAppear {
            loadConfig()
        }
    }

    private func loadConfig() {
        let service = ProjectService(modelContext: modelContext)
        guard let config = service.readPreviewConfig(from: project) else { return }
        url = config.url ?? ""
        viewport = config.viewport ?? "desktop"
        autoRefresh = config.autoRefresh ?? false
    }

    private func save() {
        let config = PreviewConfig(
            url: url.isEmpty ? nil : url,
            viewport: viewport,
            autoRefresh: autoRefresh
        )

        let service = ProjectService(modelContext: modelContext)
        do {
            try service.updatePreviewConfig(for: project, preview: config)
            dismiss()
        } catch {
            appState.showToast("Erro ao salvar configuração", type: .error)
        }
    }
}
