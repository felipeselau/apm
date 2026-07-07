import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if let account = appState.account {
                if isEditing {
                    VStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Nome")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            TextField("Nome", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("Cancelar") {
                                isEditing = false
                                resetFields()
                            }

                            Spacer()

                            Button("Salvar") {
                                saveAccount()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(width: 280)
                } else {
                    VStack(spacing: Spacing.lg) {
                        AccountAvatar(name: account.name, size: 64)

                        VStack(spacing: Spacing.xs) {
                            Text(account.name)
                                .font(.system(size: Typography.headingSize, weight: .semibold))

                            Text(account.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("Membro desde \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Divider()

                        HStack {
                            Button("Editar") {
                                isEditing = true
                                name = account.name
                                email = account.email
                            }

                            Spacer()

                            Button("Sair", role: .destructive) {
                                deleteAccount()
                            }
                        }
                    }
                    .frame(width: 280)
                }
            } else {
                Text("Nenhuma conta configurada")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.xl)
    }

    private func resetFields() {
        if let account = appState.account {
            name = account.name
            email = account.email
        }
    }

    private func saveAccount() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }

        do {
            let updatedAccount = AccountInfo(
                name: trimmedName,
                email: trimmedEmail,
                createdAt: appState.account?.createdAt ?? Date()
            )
            try APMFileManager.shared.saveAccount(updatedAccount)
            appState.account = updatedAccount
            isEditing = false
        } catch {
            print("Erro ao salvar conta: \(error)")
        }
    }

    private func deleteAccount() {
        do {
            try APMFileManager.shared.deleteAccount()
            appState.account = nil
            appState.showingAccountSheet = false
            appState.showingOnboarding = true
            dismiss()
        } catch {
            print("Erro ao deletar conta: \(error)")
        }
    }
}
