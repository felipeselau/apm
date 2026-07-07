import SwiftUI
import SwiftData

struct TerminalConfigSheet: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var shell: String = "/bin/zsh"
    @State private var envVars: [EnvVar] = []
    @State private var envFiles: [String] = []
    @State private var fontFamily: String = ""
    @State private var initCommands: [String] = []
    @State private var scripts: [ScriptItem] = []
    @State private var aiProvider: String = ""
    @State private var aiCommand: String = ""
    @State private var aiArgs: String = ""
    @State private var aiAutoStart: Bool = false

    struct EnvVar: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    struct ScriptItem: Identifiable {
        let id = UUID()
        var name: String
        var command: String
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Configuração do Terminal")
                    .font(.system(size: Typography.headingSize, weight: .medium))
                Spacer()
                Button("Salvar") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(Spacing.lg)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    shellSection
                    envVarsSection
                    envFilesSection
                    fontSection
                    initCommandsSection
                    scriptsSection
                    aiSection
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 480, height: 600)
        .onAppear {
            loadConfig()
        }
    }

    // MARK: - Sections

    private var shellSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Shell")
            TextField("Caminho do shell (ex: /bin/zsh)", text: $shell)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: Typography.bodySize))
        }
    }

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Fonte")
            TextField("Família de Fonte", text: $fontFamily)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: Typography.bodySize))
        }
    }

    private var envVarsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Variáveis de Ambiente")
            ForEach($envVars) { $envVar in
                HStack(spacing: Spacing.sm) {
                    TextField("Chave", text: $envVar.key)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                    TextField("Valor", text: $envVar.value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                    Button(action: { envVars.removeAll { $0.id == envVar.id } }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: { envVars.append(EnvVar(key: "", value: "")) }) {
                Label("Adicionar", systemImage: "plus")
                    .font(.system(size: Typography.bodySize))
            }
        }
    }

    private var envFilesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Arquivos .env")
            ForEach(envFiles.indices, id: \.self) { index in
                HStack(spacing: Spacing.sm) {
                    TextField("Caminho (ex: .env.local)", text: $envFiles[index])
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                    Button(action: { envFiles.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: { envFiles.append("") }) {
                Label("Adicionar", systemImage: "plus")
                    .font(.system(size: Typography.bodySize))
            }
        }
    }

    private var initCommandsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Comandos de Inicialização")
            ForEach(initCommands.indices, id: \.self) { index in
                HStack(spacing: Spacing.sm) {
                    TextField("Comando", text: $initCommands[index])
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                    Button(action: { initCommands.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: { initCommands.append("") }) {
                Label("Adicionar", systemImage: "plus")
                    .font(.system(size: Typography.bodySize))
            }
        }
    }

    private var scriptsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Scripts")
            ForEach($scripts) { $script in
                HStack(spacing: Spacing.sm) {
                    TextField("Nome", text: $script.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                        .frame(width: 120)
                    TextField("Comando", text: $script.command)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: Typography.bodySize))
                    Button(action: { scripts.removeAll { $0.id == script.id } }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: { scripts.append(ScriptItem(name: "", command: "")) }) {
                Label("Adicionar", systemImage: "plus")
                    .font(.system(size: Typography.bodySize))
            }
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Configuração de IA")

            HStack {
                Text("Provedor")
                    .font(.system(size: Typography.bodySize))
                    .frame(width: 80, alignment: .leading)
                TextField("Ex: OpenAI", text: $aiProvider)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Typography.bodySize))
            }

            HStack {
                Text("Comando")
                    .font(.system(size: Typography.bodySize))
                    .frame(width: 80, alignment: .leading)
                TextField("Ex: aichat", text: $aiCommand)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Typography.bodySize))
            }

            HStack {
                Text("Argumentos")
                    .font(.system(size: Typography.bodySize))
                    .frame(width: 80, alignment: .leading)
                TextField("Separados por vírgula", text: $aiArgs)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Typography.bodySize))
            }

            Toggle("Iniciar automaticamente", isOn: $aiAutoStart)
                .font(.system(size: Typography.bodySize))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Typography.headingSize, weight: .medium))
    }

    // MARK: - Load & Save

    private func loadConfig() {
        let service = ProjectService(modelContext: modelContext)
        guard let config = service.readTerminalConfig(from: project) else { return }

        shell = config.shell ?? "/bin/zsh"
        envVars = config.env?.map { EnvVar(key: $0.key, value: $0.value) } ?? []
        envFiles = config.envFiles ?? []
        fontFamily = config.fontFamily ?? ""
        initCommands = config.initCommands ?? []
        scripts = config.scripts?.map { ScriptItem(name: $0.key, command: $0.value) } ?? []
        aiProvider = config.ai?.provider ?? ""
        aiCommand = config.ai?.command ?? ""
        aiArgs = config.ai?.args?.joined(separator: ", ") ?? ""
        aiAutoStart = config.ai?.autoStart ?? false
    }

    private func save() {
        let config = TerminalConfig(
            shell: shell.isEmpty ? nil : shell,
            env: envVars.isEmpty ? nil : Dictionary(
                uniqueKeysWithValues: envVars
                    .filter { !$0.key.isEmpty }
                    .map { ($0.key, $0.value) }
            ),
            envFiles: envFiles.isEmpty ? nil : envFiles.filter { !$0.isEmpty },
            scripts: scripts.isEmpty ? nil : Dictionary(
                uniqueKeysWithValues: scripts
                    .filter { !$0.name.isEmpty }
                    .map { ($0.name, $0.command) }
            ),
            ai: aiCommand.isEmpty ? nil : TerminalConfig.AIConfig(
                provider: aiProvider.isEmpty ? nil : aiProvider,
                command: aiCommand.isEmpty ? nil : aiCommand,
                args: aiArgs.isEmpty ? nil : aiArgs
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty },
                autoStart: aiAutoStart
            ),
            initCommands: initCommands.isEmpty ? nil : initCommands.filter { !$0.isEmpty },
            fontFamily: fontFamily.isEmpty ? nil : fontFamily
        )

        let service = ProjectService(modelContext: modelContext)
        do {
            try service.updateTerminalConfig(for: project, terminal: config)
            dismiss()
        } catch {
            print("🔴 Erro ao salvar configuração do terminal: \(error)")
        }
    }
}
