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
