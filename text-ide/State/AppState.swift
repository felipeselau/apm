import SwiftUI

@Observable
final class AppState {
    var selectedProject: Project?
    var showingNewProjectSheet = false
    var showingOpenPanel = false
    var editingProject: Project?
    var showingEditSheet = false
    var folderNeedingConfig: URL?
    var showingCreateConfigSheet = false
    var account: AccountInfo?
    var showingOnboarding = false
    var showingAccountSheet = false
    var showingSettingsSheet = false
    var settings: AppSettings = AppSettings()
    var showingTerminalConfigSheet = false
    var terminalConfigProject: Project?
    var showingPreviewSettingsSheet = false

    // Toast
    var toast: ToastMessage?

    struct ToastMessage: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType

        enum ToastType {
            case error, success, info
        }
    }

    func showToast(_ message: String, type: ToastMessage.ToastType = .info) {
        toast = ToastMessage(message: message, type: type)
    }

    func showNewProject() {
        showingNewProjectSheet = true
    }

    func showOpenProject() {
        showingOpenPanel = true
    }

    func showEditProject(_ project: Project) {
        editingProject = project
        showingEditSheet = true
    }

    func showCreateConfig(for folderURL: URL) {
        folderNeedingConfig = folderURL
        showingCreateConfigSheet = true
    }

    func loadAccount() {
        account = APMFileManager.shared.loadAccount()
    }

    func hasAccount() -> Bool {
        account != nil
    }
}
