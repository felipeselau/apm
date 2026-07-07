import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var theme: String = ""
    @State private var fontSize: Int = 14
    @State private var showLineNumbers: Bool = true

    var body: some View {
        Form {
            Section("Aparência") {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tema")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Picker("Tema", selection: $theme) {
                        Text("Sistema").tag("system")
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Editor") {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tamanho da fonte")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    HStack {
                        Stepper(value: $fontSize, in: 10...24) {
                            Text("\(fontSize)pt")
                                .font(.system(size: Typography.bodySize, weight: .medium))
                                .monospacedDigit()
                        }
                    }
                }

                Toggle("Mostrar números de linha", isOn: $showLineNumbers)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320, height: 280)
        .padding(Spacing.lg)
        .onAppear {
            let settings = APMFileManager.shared.loadSettings()
            theme = settings.theme
            fontSize = settings.fontSize
            showLineNumbers = settings.showLineNumbers
        }
        .onChange(of: theme) { _, _ in saveSettings() }
        .onChange(of: fontSize) { _, _ in saveSettings() }
        .onChange(of: showLineNumbers) { _, _ in saveSettings() }
    }

    private func saveSettings() {
        let settings = AppSettings(theme: theme, fontSize: fontSize, showLineNumbers: showLineNumbers)
        do {
            try APMFileManager.shared.saveSettings(settings)
            appState.settings = settings
        } catch {
            print("Erro ao salvar ajustes: \(error)")
        }
    }
}
