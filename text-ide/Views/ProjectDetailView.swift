import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project

    @State private var config: ProjectConfig?

    var body: some View {
        VStack(spacing: 16) {
            ProjectIconView(
                initials: project.initials,
                colorHex: project.iconColorHex,
                size: 64
            )

            Text(project.name)
                .font(.title)
                .fontWeight(.semibold)

            if let config = config {
                VStack(spacing: 12) {
                    configRow(
                        icon: "paintpalette",
                        label: "Cor do Ícone",
                        value: config.iconColor,
                        colorPreview: config.iconColor
                    )

                    configRow(
                        icon: "calendar",
                        label: "Criado em",
                        value: config.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    configRow(
                        icon: "folder",
                        label: "Pasta",
                        value: project.folderPath
                    )

                    configRow(
                        icon: "clock.arrow.circlepath",
                        label: "Último acesso",
                        value: project.lastOpenedAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    Divider()
                        .padding(.vertical, 4)

                    Text(".textide.json")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("{")
                            .font(.system(.caption, design: .monospaced))
                        Text("  \"name\": \"\(config.name)\",")
                            .font(.system(.caption, design: .monospaced))
                        Text("  \"iconColor\": \"\(config.iconColor)\",")
                            .font(.system(.caption, design: .monospaced))
                        let createdAtString = config.createdAt.formatted(.iso8601)
                        Text("  \"createdAt\": \"\(createdAtString)\",")
                            .font(.system(.caption, design: .monospaced))
                        let recentFilesString = config.recentFiles.description
                        Text("  \"recentFiles\": \(recentFilesString)")
                            .font(.system(.caption, design: .monospaced))
                        Text("}")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Text("Não foi possível ler o arquivo de configuração")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadConfig()
        }
    }

    @ViewBuilder
    private func configRow(icon: String, label: String, value: String, colorPreview: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            if let colorHex = colorPreview {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 14, height: 14)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.primary)
            } else {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
    }

    private func loadConfig() {
        let service = ProjectService(modelContext: modelContext)
        config = service.readConfig(from: project)
    }
}
