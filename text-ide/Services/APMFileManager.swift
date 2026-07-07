import Foundation

@MainActor
final class APMFileManager {
    static let shared = APMFileManager()

    private let fileManager = FileManager.default
    private let apmDirectoryName = ".apm"

    var apmDirectoryURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(apmDirectoryName)
    }

    var accountFileURL: URL {
        apmDirectoryURL.appendingPathComponent("account.json")
    }

    var settingsFileURL: URL {
        apmDirectoryURL.appendingPathComponent("settings.json")
    }

    var projectsFileURL: URL {
        apmDirectoryURL.appendingPathComponent("projects.json")
    }

    func ensureAPMDirectory() {
        let url = apmDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                print("🔵 Diretório ~/.apm/ criado")
            } catch {
                print("🔴 Erro ao criar ~/.apm/: \(error)")
            }
        }
    }

    func loadAccount() -> AccountInfo? {
        let url = accountFileURL
        guard AccountInfo.exists(at: url) else { return nil }
        do {
            return try AccountInfo.readFrom(url: url)
        } catch {
            print("🔴 Erro ao carregar conta: \(error)")
            return nil
        }
    }

    func saveAccount(_ account: AccountInfo) throws {
        try account.writeTo(url: accountFileURL)
    }

    func deleteAccount() throws {
        let url = accountFileURL
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func loadSettings() -> AppSettings {
        let url = settingsFileURL
        guard AppSettings.exists(at: url) else { return AppSettings() }
        do {
            return try AppSettings.readFrom(url: url)
        } catch {
            print("🔴 Erro ao carregar ajustes: \(error)")
            return AppSettings()
        }
    }

    func saveSettings(_ settings: AppSettings) throws {
        try settings.writeTo(url: settingsFileURL)
    }

    func loadProjectRelations() -> [ProjectRelation] {
        let url = projectsFileURL
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        do {
            return try ProjectRelation.readFrom(url: url)
        } catch {
            print("🔴 Erro ao carregar projetos: \(error)")
            return []
        }
    }

    func saveProjectRelations(_ relations: [ProjectRelation]) throws {
        try ProjectRelation.write(relations, to: projectsFileURL)
    }

    func addProjectRelation(_ project: Project) throws {
        var relations = loadProjectRelations()
        relations.removeAll { $0.id == project.id }
        relations.append(ProjectRelation(from: project))
        try saveProjectRelations(relations)
    }

    func removeProjectRelation(id: UUID) throws {
        var relations = loadProjectRelations()
        relations.removeAll { $0.id == id }
        try saveProjectRelations(relations)
    }

    func updateProjectRelation(_ project: Project) throws {
        try addProjectRelation(project)
    }
}
