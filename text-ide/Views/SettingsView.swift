import SwiftUI

struct SettingsView: View {
    @State private var settings: AppSettings = APMFileManager.shared.loadSettings()

    var body: some View {
        VStack(spacing: 20) {
            Text("Ajustes")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tema")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Picker("Tema", selection: $settings.theme) {
                        Text("Sistema").tag("system")
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tamanho da fonte")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Stepper("\(settings.fontSize)pt", value: $settings.fontSize, in: 10...24)
                }

                Toggle("Mostrar números de linha", isOn: $settings.showLineNumbers)
            }
            .frame(width: 280)

            Divider()

            Button("Salvar") {
                do {
                    try APMFileManager.shared.saveSettings(settings)
                } catch {
                    print("Erro ao salvar ajustes: \(error)")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
