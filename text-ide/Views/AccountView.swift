import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: 20) {
            if let account = appState.account {
                if isEditing {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nome")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            TextField("Nome", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 6) {
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
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)

                        VStack(spacing: 4) {
                            Text(account.name)
                                .font(.title2)
                                .fontWeight(.semibold)

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
        .padding(24)
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
