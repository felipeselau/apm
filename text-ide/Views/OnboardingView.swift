import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                ProjectIconView(
                    initials: "APM",
                    colorHex: "#4A90D9",
                    size: 72
                )

                Text("Bem-vindo ao APM")
                    .font(.system(size: Typography.titleSize, weight: .bold))

                Text("Crie seu perfil para começar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xl)

            VStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Nome")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    TextField("Seu nome", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Email")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    TextField("seu@email.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(width: 280)

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(action: createAccount) {
                Text("Criar Perfil")
                    .fontWeight(.semibold)
                    .frame(width: 280)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, Spacing.xl)
        }
        .frame(width: 360)
    }

    private func createAccount() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Por favor, insira seu nome"
            showError = true
            return
        }

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Por favor, insira seu email"
            showError = true
            return
        }

        do {
            let account = AccountInfo(name: trimmedName, email: trimmedEmail)
            try APMFileManager.shared.saveAccount(account)
            appState.account = account
            appState.showingOnboarding = false
            dismiss()
        } catch {
            errorMessage = "Erro ao criar perfil: \(error.localizedDescription)"
            showError = true
        }
    }
}
